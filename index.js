// Generated by CoffeeScript 1.7.1
(function() {
  var crypto, init_SocketClient, init_SocketServ, moment, net, objCon, objData, zlib, __$day, __$hr, __$min, __$second, __Hash, __debug, __logit, __tStamp, __ttl_time;

  net = require('net');

  crypto = require('crypto');

  zlib = require('zlib');

  moment = require('moment');


  /**
   * @module ca-net
   */


  /**
   * Wrapper for net.connect
   * @function client
   * @param {string} Host Address of Server 
   * @param {int} Port Port of Server 
   * @param {function} API *[optional]* Called on('data') will pass arguments `objCon`,`Buffer` 
   * @param {function} callback *[optional]* Called on('connect') will pass arguments `net.Socket`,`objCon`
   */


  /**
   * Wrapper for net.createServer
   * @function server
   * @param {int} Port Port to listen on
   * @param {function} API *[optional]* Called on('data') will pass arguments `objCon`,`Buffer` 
   * @param {function} callback *[optional]* Called on('listening') will pass arguments `net.Server`,`{'token':objCon}`
   */

  __$second = 1000;

  __$min = 60 * __$second;

  __$hr = 60 * __$min;

  __$day = 24 * __$hr;

  __debug = true;

  __ttl_time = 15;

  init_SocketServ = function(aPort, aAPI, callback) {
    var tConns, tServ;
    tConns = {};
    return tServ = net.createServer(function(c) {
      var cli_address, cli_token;
      cli_address = c.remoteAddress;
      cli_token = crypto.randomBytes(16).toString('base64');
      if (__debug = false || (__debug == null)) {
        __logit("Client Connected " + (cli_token.toString('base64')));
      }
      tConns[cli_token] = new objCon(c, cli_token, cli_address, aAPI);
      c.on('data', (function(_this) {
        return function(data) {
          var tData;
          tData = new objData(tConns[cli_token], data);
          tData.recieve();
        };
      })(this));
      return c.on('error', (function(_this) {
        return function(e) {
          __logit("[s-" + cli_address + "] - " + e.code);
          return tConns[cli_token].destruct();
        };
      })(this));
    }).listen(aPort, (function(_this) {
      return function() {
        if (callback != null) {
          return callback(tServ, tConns);
        }
      };
    })(this));
  };

  init_SocketClient = function(aHost, aPort, aAPI, callback) {
    var c, tCallback, tConn;
    tConn = null;
    c = net.connect(aPort, aHost, function() {
      if (__debug = false || (__debug == null)) {
        return __logit("Connected [" + aHost + ":" + aPort + "]");
      }
    });
    tCallback = (function(_this) {
      return function() {
        if (callback != null) {
          callback(c, tConn);
        }
      };
    })(this);
    tConn = new objCon(c, null, null, aAPI);
    c.on('data', (function(_this) {
      return function(data) {
        var tData;
        tData = new objData(tConn, data);
        tData.recieve();
      };
    })(this));
    c.on('error', (function(_this) {
      return function(e) {
        __logit("[c-" + aHost + "] - " + e.code);
        tConn.destruct();
      };
    })(this));
    c.on('connect', tCallback);
  };

  __logit = function(aMsg) {
    console.log("[" + (__tStamp()) + "] :: " + aMsg);
  };

  __tStamp = function() {
    return moment().format('MM/DD/YYYY hh:mm:ss');
  };

  __Hash = function(aValue, aKey, aSalt) {
    var tHash;
    tHash = crypto.createHmac('sha256', aKey);
    if (aValue != null) {
      tHash.update(aValue);
    }
    if (aSalt != null) {
      tHash.update(aSalt);
    }
    return tHash.digest('base64');
  };


  /**
   * *internal class*
   * @class objData
   */

  objData = (function() {

    /**
     * @constructor
     * @function
     * @param {objCon} objCon
     * @param {Buffer} data
     */
    function objData(objCon, data) {
      this.objCon = objCon;
      this.data = data;
      this.ttl = null;
      return;
    }


    /**
     * *internal function*
     * called at the tail of a recursive `objData.combine`, `objData.unpack`, `objData.pack`
     * or when `objData` times out on `objData.ttl` *timeout*
     * @function destruct
     */

    objData.prototype.destruct = function() {
      var pkt, _i, _len, _ref;
      clearTimeout(this.ttl);
      if (this.parts != null) {
        _ref = this.parts;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pkt = _ref[_i];
          pkt.destruct();
        }
      }
      delete this.objCon.toJoin[this.pid];
    };


    /**
     * *internal function*
     * called to join together data that has been split by `objData.pack`
     * @function combine
     * @param {objData} aObjData
     */

    objData.prototype.combine = function(aObjData) {
      var pkt, pkthead, pktpart, tData, tPacket, _i, _len, _ref;
      this.parts.push(aObjData);
      if (this.parts.length === this.total) {
        this.parts.sort(function(a, b) {
          return a['idx'] - b['idx'];
        });
        tData = [];
        _ref = this.parts;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pkt = _ref[_i];
          pkthead = new Buffer(pkt.data.toString().split('::')[0]);
          pktpart = pkt.data.slice(pkthead.length + 2, pkt.data.length);
          tData.push(pktpart);
        }
        tPacket = new objData(this.objCon, Buffer.concat(tData));
        tPacket.unpack();
        this.destruct();
      }
    };


    /**
     * *internal function*
     * Prepends `data` *Buffer* with length and writes it socket
     * @function send
     * @param {Buffer} data Data to send
     */

    objData.prototype.send = function(tData) {
      var tLen;
      tLen = new Buffer(2);
      tLen.writeUInt16BE(tData.length, 0);
      tData = Buffer.concat([tLen, tData]);
      this.objCon.con.write(tData);
    };


    /**
     * *internal function*
     * Processes Prepended length and split `data` *Buffer* if longer than length
     * calls .unpack() on `data`
     * creates new `objData` for remaining `data` and calls .recieve() on new `objData`
     * @function recieve
     */

    objData.prototype.recieve = function() {
      var tData, tLen, tPkt;
      tLen = this.data.readUInt16BE(0);
      if ((tLen + 2) !== this.data.length) {
        tData = this.data.slice(2 + tLen, this.data.length);
        tPkt = new objData(this.objCon, tData);
        this.data = this.data.slice(2, 2 + tLen);
        this.unpack();
        tPkt.recieve();
        return;
      } else {
        this.data = this.data.slice(2, 2 + tLen);
        this.unpack();
      }
    };


    /**
     * *internal function*
     * processes `objData.data` before calling `objData.send`
     * zip? > encrypt? > split?
     * @function pack 
     * @param {bool} c *[optional]* toEncrypt flag
     * @param {bool} z *[optional]* toZip flag
     * @param {bool} s *[optional]* Special Flag *used for pubKey syncing*
     */

    objData.prototype.pack = function(c, z, s) {
      var cipher, hash, i, ii, n, nn, pid, pktpart, step, tRet, _i;
      if ((s == null) || s === false) {
        this.data = Buffer.concat([new Buffer('x'), this.data]);
        s = true;
      }
      if ((z != null) && z === true) {
        zlib.deflate(this.data, (function(_this) {
          return function(e, r) {
            _this.data = Buffer.concat([new Buffer('z'), r]);
            return _this.pack(c, false, s);
          };
        })(this));
        return;
      }
      if ((c != null) && c === true) {
        if (this.objCon.secret != null) {
          cipher = crypto.createCipher('aes-256-cbc', this.objCon.secret);
          tRet = cipher.update(this.data);
          this.data = Buffer.concat([new Buffer('c'), tRet, cipher.final()]);
          this.pack(false, false, s);
          return;
        } else {
          if (__debug) {
            __logit("Error: Missing Secret");
          }
          return;
        }
        return;
      }
      if (this.data.length > 8000) {
        this.ttl = setTimeout(this.destruct, __$min);
        this.parts = [];
        step = 7500;
        ii = this.data.length;
        nn = parseInt((ii / step) + 1);
        pid = crypto.randomBytes(3).toString('base64');
        this.objCon.toSend[pid] = this;
        hash = __Hash(this.data, 'foo', 'bar');
        this.parts.push(new Buffer("p:" + pid + ":0:" + nn + "::" + hash));
        for (i = _i = 0; step > 0 ? _i <= ii : _i >= ii; i = _i += step) {
          n = (i / step) + 1;
          pktpart = this.data.slice(i, i + step);
          this.parts.push(Buffer.concat([new Buffer("p:" + pid + ":" + n + "::"), pktpart]));
        }
        this.send(this.parts[0]);
        return;
      }
      this.send(this.data);
      this.destruct();
    };


    /**
     * *internal function*
     * process `objData.data` before passing `objData.data` to `objData.objCon.API`
     * join? > decrypt? > unzip?
     * @function unpack
     */

    objData.prototype.unpack = function() {
      var cipher, idx, pid, tAck, tHead, tPkt, tRet;
      switch (this.data.slice(0, 1).toString()) {
        case 'a':
          tHead = this.data.slice(0, 50).toString().split(':');
          pid = tHead[1];
          idx = parseInt(tHead[2]);
          tPkt = this.objCon.toSend[pid];
          if ((idx + 1) < tPkt.parts.length) {
            this.send(tPkt.parts[idx + 1]);
          } else {
            this.destruct();
          }
          return;
        case 'e':
          if (__debug) {
            __logit("Error: " + (this.data.slice(1, this.data.length).toString));
          }
          return;
        case 'z':
          this.data = this.data.slice(1, this.data.length);
          zlib.unzip(this.data, (function(_this) {
            return function(e, r) {
              _this.data = r;
              return _this.unpack();
            };
          })(this));
          return;
        case 'c':
          this.data = this.data.slice(1, this.data.length);
          if (this.objCon.secret != null) {
            cipher = crypto.createDecipher('aes-256-cbc', this.objCon.secret);
            tRet = cipher.update(this.data);
            this.data = Buffer.concat([tRet, cipher.final()]);
            this.unpack();
            return;
          } else {
            if (__debug) {
              __logit("Error: Missing Secret");
            }
            return;
          }
          break;
        case 'p':
          tHead = this.data.slice(0, 50).toString().split('::')[0].split(':');
          this.pid = tHead[1];
          this.idx = tHead[2];
          if (this.idx === '0') {
            this.ttl = setTimeout(this.destruct, __$min);
            this.objCon.toJoin[this.pid] = this;
            this.parts = [];
            this.total = parseInt(tHead[3]);
            this.hash = this.data.toString().split('::')[1];
          } else {
            if (this.pid in this.objCon.toJoin) {
              this.objCon.toJoin[this.pid].combine(this);
            }
          }
          tAck = new objData(this.objCon, new Buffer("a:" + this.pid + ":" + this.idx));
          tAck.pack(false, false, true);
          return;
        case 'x':
          this.objCon.API(this.objCon, this.data.slice(1, this.data));
          this.destruct();
          return;
      }
    };

    return objData;

  })();


  /**
   * *internal class*
   * @class objCon
   */

  objCon = (function() {

    /**
     * @constructor
     * @function
     * @param {net.Socket} con
     * @param {string} token *[optional]*
     * @param {string} address *[optional]*
     * @param {function} API *[optional]*
     */
    function objCon(con, token, address, sAPI) {
      var f_loop;
      this.con = con;
      this.token = token;
      this.address = address;
      this.sAPI = sAPI;
      this.Keys = crypto.getDiffieHellman('modp5');
      this.Keys.generateKeys();
      this.keepAlive();
      this.pubkeylocal = this.Keys.getPublicKey();
      this.pubKeyremote = null;
      this.timeOffset = null;
      this.toSend = {};
      this.toJoin = {};
      this.doList = [];
      f_loop = (function(_this) {
        return function() {
          _this.ctrl_loop();
        };
      })(this);
      this.loop = setInterval(f_loop, 30 * __$second);
      this.send(Buffer.concat([new Buffer('s'), this.pubkeylocal]), true);
    }


    /**
     * Handles encryption setup on initial connection
     * @function API 
     * @param {objCon} c
     * @param {Buffer} r
     */

    objCon.prototype.API = function(c, r) {
      var flg;
      flg = r.slice(0, 1).toString();
      if (flg === '~') {
        if (this.sAPI != null) {
          this.sAPI(c, r.slice(1, r.length));
        }
        return;
      }
      if (flg === 's') {
        this.pubKeyremote = r.slice(1, r.length);
        this.secret = this.Keys.computeSecret(this.pubKeyremote);
        return;
      }
    };


    /**
     * destroys objCon on time out
     * @function destruct
     */

    objCon.prototype.destruct = function() {
      clearTimeout(this.TTL);
      if (this.loop != null) {
        clearInterval(this.loop);
      }
      if (this.con != null) {
        this.con.end();
      }
    };

    objCon.prototype.ctrl_loop = function() {
      var task, _i, _len, _ref;
      _ref = this.doList;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        task = _ref[_i];
        task();
      }
    };


    /**
     * updates `objCon.ttl` to keep connection from self destructing
     * @function keepAlive
     */

    objCon.prototype.keepAlive = function() {
      this.lastupdate = Date.now();
      clearTimeout(this.TTL);
      return this.TTL = setTimeout(this.destruct, __ttl_time * __$min);
    };


    /**
     * send messages to remote connection
     * @function send
     * @param {Buffer} msg Message to send to remote connection
     * @param {bool} flg internal var for connection initilization
     */

    objCon.prototype.send = function(aMsg, flg) {
      var doEncrypt, doZip, tPkt;
      if (typeof aMsg === 'string') {
        aMsg = new Buffer(aMsg);
      }
      if ((flg == null) || flg === false) {
        aMsg = Buffer.concat([new Buffer('~'), aMsg]);
      }
      if (this.secret != null) {
        doEncrypt = true;
      }
      if (doEncrypt == null) {
        doEncrypt = false;
      }
      if (aMsg.length > 250) {
        doZip = true;
      }
      doZip = false;
      tPkt = new objData(this, aMsg);
      tPkt.pack(doEncrypt, doZip);
    };

    return objCon;

  })();

  module.exports = {};

  module.exports['client'] = function(aHost, aPort, aAPI, callback) {
    init_SocketClient(aHost, aPort, aAPI, callback);
  };

  module.exports['server'] = function(aPort, aAPI, callback) {
    init_SocketServ(aPort, aAPI, callback);
  };


  /* for testing */

  module.exports['create_objData'] = function(aObjCon, aData) {
    return new objData(aObjCon, aData);
  };


  /* for testing */

  module.exports['objData'] = function(aObjCon, aData) {
    return new objData(aObjCon, aData);
  };


  /* for testing */

  module.exports['objCon'] = function(con, token, address, sAPI) {
    return new objCon(con, token, address, sAPI);
  };

}).call(this);
