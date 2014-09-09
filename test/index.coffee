crypto  = require 'crypto'
buftool = require 'buffertools'
should = require('chai').should()
_net = require('../index')


doEncrypt = true
doZip = true

class testCon
  constructor: (@con, @token, @address,@API) ->
    @Key1 = crypto.getDiffieHellman('modp5')
    @Key1.generateKeys()
    @Key2 = crypto.getDiffieHellman('modp5')
    @Key2.generateKeys()
    @pubkeylocal  = @Key1.getPublicKey()
    @pubkeyremote = @Key2.generateKeys()
    @secret = @Key1.computeSecret( @pubkeyremote )
    @toSend = {}
    @toJoin = {}
    @testRead = []
    @testWritten = []
    @con = {}
    @con['write'] = (aMsg) =>
      @testWritten.push(aMsg)
      return

describe( 'class: objData(objCon, data)', () ->
  it('Raw Data', (done) ->
    tData = new Buffer(5000)
    tAPI = (c,r) =>
      buftool.equals(tData,r).should.equal( true )
      done()
      return
    tCon = new testCon(null,'test-token', 'test.com', tAPI)
    tCon.con['write'] = (aData) =>
      aPkt = _net.create_objData(tCon,aData)
      aPkt.recieve()
      return
    tPkt = _net.create_objData(tCon, tData)
    tPkt.pack()
    )

  it('Zipped Data', (done) ->
    tData = new Buffer(5000)
    tAPI = (c,r) =>
      buftool.equals(tData,r).should.equal( true )
      done()
      return
    tCon = new testCon(null,'test-token', 'test.com', tAPI)
    tCon.con['write'] = (aData) =>
      aPkt = _net.create_objData(tCon,aData)
      aPkt.recieve()
      return
    tPkt = _net.create_objData(tCon, tData)
    tPkt.pack(null, doZip)
    )

  it('Encrypted Data', (done) ->
    tData = new Buffer(5000)
    tAPI = (c,r) =>
      buftool.equals(tData,r).should.equal( true )
      done()
      return
    tCon = new testCon(null,'test-token', 'test.com', tAPI)
    tCon.con['write'] = (aData) =>
      aPkt = _net.create_objData(tCon,aData)
      aPkt.recieve()
      return
    tPkt = _net.create_objData(tCon, tData)
    tPkt.pack(doEncrypt, null)
    )

  it('Split/Join Data', (done) ->
    tData = new Buffer(99999)
    tAPI = (c,aData) ->
      c.testRead.push(aData)
      buftool.equals(tData,aData).should.equal(true)
      return
    tCon = new testCon(null, 'test-token', 'test.com', tAPI )
    tEnd = () =>
      tCon.testRead[tCon.testRead.length - 1].length.should.equal(tData.length)
      done()
    setTimeout( tEnd , 15)
    tCon.con['write'] = (aData) =>
      aPkt = _net.create_objData(tCon,aData)
      aPkt.recieve()
      return
    tPkt = _net.create_objData(tCon, tData)
    tPkt.pack(false,false,false)
   )

  it('All the Things', (done) ->
    tData = new Buffer(99999)
    tAPI = (c,aData) ->
      c.testRead.push(aData)
      buftool.equals(tData,aData).should.equal(true)
      return
    tCon = new testCon(null, 'test-token', 'test.com', tAPI )
    tEnd = () =>
      tCon.testRead[tCon.testRead.length - 1].length.should.equal(tData.length)
      done()
    setTimeout( tEnd , 15)
    tCon.con['write'] = (aData) =>
      aPkt = _net.create_objData(tCon,aData)
      aPkt.recieve()
      return
    tPkt = _net.create_objData(tCon, tData)
    tPkt.pack(doEncrypt,doZip)
   )
  )

describe('class: objCon(con, token, address, sAPI)', () ->
  tData1 = new Buffer(99999)
  tData2 = new Buffer(99999)
  it('Init > sync > xfer', (done) ->
    __Server = null
    __Server_con = null
    __Server_API = (c,aData) ->
      buftool.equals(aData,tData1).should.equal(true)
      c.send(tData2)
      ##console.log "serv - #{aData}"
      return
    __Client = null
    __Client_con = null
    __Client_API = (c,aData) ->
      buftool.equals(aData,tData2).should.equal(true)
      #console.log "cli - #{aData}"
      done()
      return
    _net.server(9001,__Server_API, (c,nodes) ->
      __Server_con = c
      __Server = nodes
      _net.client( "localhost", 9001, __Client_API, (c,node) ->
        __Client_con = c
        __Client = node
        __Client.send(tData1)
      )
    )
  )
)