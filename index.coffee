net     = require 'net'
crypto  = require 'crypto'
zlib    = require 'zlib'
moment  = require 'moment'

###*
 * @module ca-net
###
###*
 * Wrapper for net.connect
 * @function client
 * @param {string} Host Address of Server 
 * @param {int} Port Port of Server 
 * @param {function} API *[optional]* Called on('data') will pass arguments `objCon`,`Buffer` 
 * @param {function} callback *[optional]* Called on('connect') will pass arguments `net.Socket`,`objCon`
###
###*
 * Wrapper for net.createServer
 * @function server
 * @param {int} Port Port to listen on
 * @param {function} API *[optional]* Called on('data') will pass arguments `objCon`,`Buffer` 
 * @param {function} callback *[optional]* Called on('listening') will pass arguments `net.Server`,`{'token':objCon}`
###

## Const #####################################################
__$second = 1000
__$min = 60 * __$second
__$hr = 60 * __$min
__$day = 24 * __$hr

## Global ####################################################
__debug = true
__ttl_time = 15

## Functions #################################################
init_SocketServ = (aPort, aAPI, callback) ->
  tConns = {}
  tServ = net.createServer( (c) ->
    cli_address = c.remoteAddress
    cli_token = crypto.randomBytes(16).toString('base64')
    __logit "Client Connected #{cli_token.toString('base64')}" if __debug = false || not __debug?
    tConns[cli_token] = new objCon(c, cli_token, cli_address,aAPI)

    c.on('data', (data) =>
      tData = new objData(tConns[cli_token], data)
      tData.recieve()
      return
      )

    c.on('error', (e) =>
      __logit "[s-#{cli_address}] - #{e.code}"
      tConns[cli_token].destruct()
    )
  ).listen(aPort, () =>
    callback(tServ,tConns) if callback?
    )

init_SocketClient = (aHost, aPort, aAPI, callback) ->
  tConn = null
  c = net.connect( aPort, aHost, () -> 
    __logit "Connected [#{aHost}:#{aPort}]" if __debug = false || not __debug?
  ) 

  tCallback = () =>
    callback(c,tConn) if callback?
    return

  tConn = new objCon(c,null,null,aAPI)

  c.on('data', (data) =>
    tData = new objData(tConn, data)
    tData.recieve()
    return
    )

  c.on('error', (e) => 
    __logit "[c-#{aHost}] - #{e.code}"
    tConn.destruct()
    return
    )

  c.on('connect', tCallback )
  return 

__logit = (aMsg) ->
  console.log "[#{__tStamp()}] :: #{aMsg}"
  return

__tStamp = () ->
    # http://momentjs.com/docs/#/parsing/string-format/
    return moment().format('MM/DD/YYYY hh:mm:ss')

__Hash = (aValue,aKey,aSalt) ->
  tHash = crypto.createHmac('sha256', aKey )
  tHash.update(aValue) if aValue?
  tHash.update(aSalt) if aSalt?
  return tHash.digest('base64')

## Classes ###################################################
###*
 * *internal class*
 * @class objData
###

class objData
  ###*
 * @constructor
 * @function
 * @param {objCon} objCon
 * @param {Buffer} data
  ###
  constructor: (@objCon, @data) ->
    @ttl = null
    #<e...> error string
    #<z...> zipped
    #<c...> encrypted
    #<p:id:idx::> part + id
    #<x...> clear
    return

  ###*
 * *internal function*
 * called at the tail of a recursive `objData.combine`, `objData.unpack`, `objData.pack`
 * or when `objData` times out on `objData.ttl` *timeout*
 * @function destruct
  ###
  destruct: () ->
    clearTimeout(@ttl)
    if @parts?
      for pkt in @parts
        pkt.destruct()
    delete @objCon.toJoin[@pid]
    return
  ###*
 * *internal function*
 * called to join together data that has been split by `objData.pack`
 * @function combine
 * @param {objData} aObjData
  ###
  combine: (aObjData) ->
    @parts.push(aObjData)
    if @parts.length == @total
      @parts.sort( (a,b) -> a['idx'] - b['idx'])
      tData = []
      for pkt in @parts
        pkthead = new Buffer(pkt.data.toString().split('::')[0])
        pktpart = pkt.data.slice(pkthead.length + 2,pkt.data.length)
        #console.log  " <<< #{pktpart.length} :: #{__Hash(pktpart,'foo','bar')}"
        tData.push(pktpart)
      tPacket = new objData(@objCon, Buffer.concat(tData))
      tPacket.unpack()
      @destruct()
    return

  ###*
 * *internal function*
 * Prepends `data` *Buffer* with length and writes it socket
 * @function send
 * @param {Buffer} data Data to send
  ###
  send: (tData) ->
    tLen = new Buffer(2)
    tLen.writeUInt16BE(tData.length,0)
    tData = Buffer.concat([tLen,tData])
    @objCon.con.write(tData)
    return

  ###*
 * *internal function*
 * Processes Prepended length and split `data` *Buffer* if longer than length
 * calls .unpack() on `data`
 * creates new `objData` for remaining `data` and calls .recieve() on new `objData`
 * @function recieve
  ###
  recieve: () ->
    tLen = @data.readUInt16BE(0)
    if (tLen + 2) != @data.length
      tData = @data.slice(2 + tLen, @data.length)
      tPkt = new objData(@objCon,tData)
      @data = @data.slice(2, 2 + tLen)
      @unpack()
      tPkt.recieve()
      return
    else
      @data = @data.slice(2, 2 + tLen)
      @unpack()
    return

  ###*
 * *internal function*
 * processes `objData.data` before calling `objData.send`
 * zip? > encrypt? > split?
 * @function pack 
 * @param {bool} c *[optional]* toEncrypt flag
 * @param {bool} z *[optional]* toZip flag
 * @param {bool} s *[optional]* Special Flag *used for pubKey syncing*
  ###
  pack: (c,z,s) ->
    if not s? || s == false
      @data = Buffer.concat([new Buffer('x'), @data])
      s = true
    if z? && z == true
      zlib.deflate(@data, (e,r) =>
        @data = Buffer.concat([new Buffer('z'), r])
        @pack(c,false,s)
      )
      return
    if c? && c == true
      if @objCon.secret?
        cipher = crypto.createCipher('aes-256-cbc', @objCon.secret)
        tRet = cipher.update(@data)
        @data = Buffer.concat([new Buffer('c'),tRet, cipher.final()])
        @pack(false,false,s)
        return
      else
        __logit "Error: Missing Secret" if __debug
        return
      return
    if @data.length > 8000
      @ttl = setTimeout( @destruct , __$min)
      @parts = []
      step = 7500
      ii = @data.length
      nn = parseInt( (ii/step)+1 )
      pid = crypto.randomBytes(3).toString('base64')
      @objCon.toSend[pid] = @
      hash = __Hash(@data,'foo','bar')
      # [p:pid:idx:total::hash]
      @parts.push( new Buffer("p:#{pid}:0:#{nn}::#{hash}"))
      for i in [0..ii] by step
        n = (i/step)+1
        # [p:pid:idx::data]
        pktpart = @data.slice(i,i + step)
        #console.log  " >>> #{pktpart.length} :: #{__Hash(pktpart,'foo','bar')}"
        @parts.push( Buffer.concat( [ new Buffer("p:#{pid}:#{n}::") , pktpart ]))
      @send( @parts[0] )
      return
    @send( @data )
    @destruct()
    return

  ###*
 * *internal function*
 * process `objData.data` before passing `objData.data` to `objData.objCon.API`
 * join? > decrypt? > unzip?
 * @function unpack
  ###
  unpack: () ->
    switch @data.slice(0,1).toString()
      when 'a'
        tHead = @data.slice(0,50).toString().split(':')
        pid = tHead[1]
        idx = parseInt(tHead[2])
        tPkt = @objCon.toSend[pid]
        if ( idx + 1 ) < tPkt.parts.length
          @send( tPkt.parts[idx + 1] )
        else
          @destruct()
        return
      when 'e'
        __logit "Error: #{@data.slice(1,@data.length).toString}" if __debug
        return
      when 'z'
        @data = @data.slice(1,@data.length)
        zlib.unzip(@data, (e,r) => 
          @data = r
          @unpack()
        )
        return
      when 'c'
        @data = @data.slice(1,@data.length)
        if @objCon.secret?
          cipher = crypto.createDecipher('aes-256-cbc', @objCon.secret)
          tRet = cipher.update(@data)
          @data = Buffer.concat([tRet, cipher.final()])
          @unpack()
          return
        else
          __logit "Error: Missing Secret" if __debug
          return
      when 'p'
        tHead = @data.slice(0,50).toString().split('::')[0].split(':')
        @pid = tHead[1]
        @idx = tHead[2]
        if @idx == '0'
          @ttl = setTimeout( @destruct , __$min)
          @objCon.toJoin[@pid] = @
          @parts = []
          @total = parseInt(tHead[3])
          @hash = @data.toString().split('::')[1]
        else
          @objCon.toJoin[@pid].combine(@) if @pid of @objCon.toJoin
        tAck = new objData(@objCon, new Buffer("a:#{@pid}:#{@idx}"))
        tAck.pack(false,false,true)
        return
      when 'x'
        @objCon.API( @objCon, @data.slice(1,@data) )
        @destruct()
        return
    return

###*
 * *internal class*
 * @class objCon
###

class objCon
  ###*
 * @constructor
 * @function
 * @param {net.Socket} con
 * @param {string} token *[optional]*
 * @param {string} address *[optional]*
 * @param {function} API *[optional]* 
  ###
  constructor: (@con, @token, @address, @sAPI) ->
    @Keys = crypto.getDiffieHellman('modp5')
    @Keys.generateKeys()
    @keepAlive()
    #@secret = null
    @pubkeylocal = @Keys.getPublicKey()
    @pubKeyremote = null
    @timeOffset = null
    @toSend = {}
    @toJoin = {}
    @doList = []
    f_loop = () =>
      @ctrl_loop()
      return
    @loop = setInterval( f_loop , 30 * __$second )
    @send( Buffer.concat( [ new Buffer('s'), @pubkeylocal ] ), true)

  ###*
 * Handles encryption setup on initial connection
 * @function API 
 * @param {objCon} c
 * @param {Buffer} r
  ###
  API: (c,r) ->
    flg = r.slice(0,1).toString()
    if flg is '~'
      @sAPI(c,r.slice(1,r.length)) if @sAPI?
      return
    if flg is 's'
      @pubKeyremote = r.slice(1,r.length)
      @secret = @Keys.computeSecret(@pubKeyremote)
      #console.log "Secret Generated"
      return
    return

  ###*
 * destroys objCon on time out
 * @function destruct
  ###
  destruct: () ->
    clearTimeout(@TTL)
    if @loop?
      clearInterval(@loop)
    if @con?
      @con.end()
    delete tConns[@token] if @token?
    return

  ctrl_loop: () ->
    for task in @doList
      task()
    return

  ###*
 * updates `objCon.ttl` to keep connection from self destructing
 * @function keepAlive
  ###
  keepAlive: () ->
    @lastupdate = Date.now()
    clearTimeout(@TTL)
    @TTL = setTimeout( @destruct , __ttl_time * __$min)

  ###*
 * send messages to remote connection
 * @function send
 * @param {Buffer} msg Message to send to remote connection
 * @param {bool} flg internal var for connection initilization
  ###
  send: (aMsg,flg) ->
    if typeof aMsg == 'string'
      aMsg = new Buffer(aMsg)
    if not flg? or flg == false
      aMsg = Buffer.concat([new Buffer('~'),aMsg])
    doEncrypt = true if @secret?
    doEncrypt ?= false
    doZip = true if aMsg.length > 250
    doZip = false
    tPkt = new objData(@,aMsg)
    tPkt.pack(doEncrypt,doZip)
    return

## API #######################################################
## cLoop #####################################################
## INIT ######################################################
## Export ####################################################
module.exports = {}
module.exports['client'] = (aHost,aPort,aAPI, callback) ->
  init_SocketClient(aHost,aPort,aAPI, callback)
  return

module.exports['server'] = (aPort,aAPI, callback) ->
  init_SocketServ(aPort,aAPI, callback)
  return

### for testing ###
module.exports['create_objData'] = (aObjCon, aData) ->
  return new objData(aObjCon, aData)

### for testing ###
module.exports['objData'] = (aObjCon, aData) ->
  return new objData(aObjCon, aData)

### for testing ###
module.exports['objCon'] = (con, token, address, sAPI) ->
  return new objCon(con, token, address, sAPI)

