ca-net
======

**Simple TCP/IP Communication Lib**

######
This lib creates a wrapper of sorts around the node.js's `net.createServer` and `net.connect`.  It sets up encrypted communication between a client and server using DiffieHellman Key Exchange, and `aes-256-cbc` encryption from node.js's `crypto`.  It also takes care of message compression and splitting.

#
Install
`npm install ca-net`


#
API

> ca-net.client(Host, Port, API, callback) 
> -----------------------------
> Wrapper for net.connect
> 
> **Parameters**
> 
> **Host**: string, Address of Server
> 
> **Port**: int, Port of Server
> 
> **API**: function, *[optional]* Called on('data') will pass arguments `objCon`,`Buffer`
> 
> **callback**: function, *[optional]* Called on('connect') will pass arguments `net.Socket`,`objCon`
 
 -----------------------------
 
> ca-net.server(Port, API, callback) 
> -----------------------------
> Wrapper for net.createServer
> 
> **Parameters**
> 
> **Port**: int, Port to listen on
> 
> **API**: function, *[optional]* Called on('data') will pass arguments `objCon`,`Buffer`
> 
> **callback**: function, *[optional]* Called on('listening') will pass arguments `net.Server`,`{'token':objCon}`
 
 -----------------------------
 
> objData
> ===
> *internal class*
> 
>> ca-net.objData.objData(objCon, data) 
>> -----------------------------
>> *internal class*
>> 
>> **Parameters**
>> 
>> **objCon**: objCon, *internal class*
>> 
>> **data**: Buffer, *internal class*
> 
> -----------------------------
>
>> ca-net.objData.destruct() 
>> -----------------------------
>> *internal function*
>> called at the tail of a recursive `objData.combine`, `objData.unpack`, `objData.pack`
>> or when `objData` times out on `objData.ttl` *timeout*
> 
> -----------------------------
>
>> ca-net.objData.combine(aObjData) 
>> -----------------------------
>> *internal function*
>> called to join together data that has been split by `objData.pack`
>> 
>> **Parameters**
>> 
>> **aObjData**: objData, *internal function*
>> called to join together data that has been split by `objData.pack`
> 
> -----------------------------
>
>> ca-net.objData.send(data) 
>> -----------------------------
>> *internal function*
>> Prepends `data` *Buffer* with length and writes it socket
>> 
>> **Parameters**
>> 
>> **data**: Buffer, Data to send
> 
> -----------------------------
>
>> ca-net.objData.recieve() 
>> -----------------------------
>> *internal function*
>> Processes Prepended length and split `data` *Buffer* if longer than length
>> calls .unpack() on `data`
>> creates new `objData` for remaining `data` and calls .recieve() on new `objData`
> 
> -----------------------------
>
>> ca-net.objData.pack(c, z, s) 
>> -----------------------------
>> *internal function*
>> processes `objData.data` before calling `objData.send`
>> zip? > encrypt? > split?
>> 
>> **Parameters**
>> 
>> **c**: bool, *[optional]* toEncrypt flag
>> 
>> **z**: bool, *[optional]* toZip flag
>> 
>> **s**: bool, *[optional]* Special Flag *used for pubKey syncing*
> 
> -----------------------------
>
>> ca-net.objData.unpack() 
>> -----------------------------
>> *internal function*
>> process `objData.data` before passing `objData.data` to `objData.objCon.API`
>> join? > decrypt? > unzip?
 
 -----------------------------
 
> objCon
> ===
> *internal class*
> 
>> ca-net.objCon.objCon(con, token, address, API) 
>> -----------------------------
>> *internal class*
>> 
>> **Parameters**
>> 
>> **con**: net.Socket, *internal class*
>> 
>> **token**: string, *[optional]*
>> 
>> **address**: string, *[optional]*
>> 
>> **API**: function, *[optional]*
> 
> -----------------------------
>
>> ca-net.objCon.API(c, r) 
>> -----------------------------
>> Handles encryption setup on initial connection
>> 
>> **Parameters**
>> 
>> **c**: objCon, Handles encryption setup on initial connection
>> 
>> **r**: Buffer, Handles encryption setup on initial connection
> 
> -----------------------------
>
>> ca-net.objCon.destruct() 
>> -----------------------------
>> destroys objCon on time out
> 
> -----------------------------
>
>> ca-net.objCon.keepAlive() 
>> -----------------------------
>> updates `objCon.ttl` to keep connection from self destructing
> 
> -----------------------------
>
> ca-net.objCon.send(msg, flg) 
> -----------------------------
> send messages to remote connection
> 
> **Parameters**
> 
> **msg**: Buffer, Message to send to remote connection
> 
> **flg**: bool, internal var for connection initilization

####
TODO:
> Coding 
> [x] - create objCon class for uniformity betwen Cli & Serv
> [x] - create objData class for simulated low level exchange
> [x] - objData Send/Recieve
> [x] - objData Zipping
> [x] - objData Encryption
> [x] - objData pubKey Sync
-----------------------------
> Testing 
>[x] - Test Send / Recieve
>[x] - Test Zipping
>[x] - Test Encryption
>[x] - Test Splitting
>[x] - remove cb from source & testing
>[x] - update testing w/ random data
>[x] - Test Zip > Encrypt > Split > Send\Recieve > Join > Decrypt > Unzip
>[x] - Test objCon
>[x] - Doc API
-----------------------------
> Eventualy
>[ ] Rewrite objData.pack() and objData.unpack() to use a fixed length binnary header instead of dirty string manipulation

-----------------------------

####
Disclaimer:
This is a toy project, and should not be used for production grade anything ... use at your own risk
