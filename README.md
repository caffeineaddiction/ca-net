ca-net
======

**Simple TCP/IP Communication Lib**

######
This lib creates a wrapper of sorts around the node.js's `net.createServer` and `net.connect`.  It sets up encrypted communication between a client and server using DiffieHellman Key Exchange, and `aes-256-cbc` encryption from node.js's `crypto`.  It also takes care of message compression and splitting.

##Install
`npm install ca-net`


##API

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
 
&nbsp;
 
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
 
&nbsp;
 
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
> &nbsp;
>
>> ca-net.objData.destruct() 
>> -----------------------------
>> *internal function*
>> called at the tail of a recursive `objData.combine`, `objData.unpack`, `objData.pack`
>> or when `objData` times out on `objData.ttl` *timeout*
> 
> &nbsp;
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
> &nbsp;
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
> &nbsp;
>
>> ca-net.objData.recieve() 
>> -----------------------------
>> *internal function*
>> Processes Prepended length and split `data` *Buffer* if longer than length
>> calls .unpack() on `data`
>> creates new `objData` for remaining `data` and calls .recieve() on new `objData`
> 
> &nbsp;
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
> &nbsp;
>
>> ca-net.objData.unpack() 
>> -----------------------------
>> *internal function*
>> process `objData.data` before passing `objData.data` to `objData.objCon.API`
>> join? > decrypt? > unzip?
 
&nbsp;
 
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
> &nbsp;
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
> &nbsp;
>
>> ca-net.objCon.destruct() 
>> -----------------------------
>> destroys objCon on time out
> 
> &nbsp;
>
>> ca-net.objCon.keepAlive() 
>> -----------------------------
>> updates `objCon.ttl` to keep connection from self destructing
> 
> &nbsp;
>
>> ca-net.objCon.send(msg, flg) 
>> -----------------------------
>> send messages to remote connection
>> 
>> **Parameters**
>> 
>> **msg**: Buffer, Message to send to remote connection
>> 
>> **flg**: bool, internal var for connection initilization

##TODO:
> **Coding:**
> - [x] ~~create objCon class for uniformity betwen Cli & Serv~~
> - [x] ~~create objData class for simulated low level exchange~~
> - [x] ~~objData Send/Recieve~~
> - [x] ~~objData Zipping~~
> - [x] ~~objData Encryption~~
> - [x] ~~objData pubKey Sync~~
> - [ ] add functionality for externaly checking if objCon.destruct() has been called
> - [ ] change .onError() so that host script is informed
> 
> **Testing / Doc:**
> - [x] ~~Test Send / Recieve~~
> - [x] ~~Test Zipping~~
> - [x] ~~Test Encryption~~
> - [x] ~~Test Splitting~~
> - [x] ~~remove cb from source & testing~~
> - [x] ~~update testing w/ random data~~
> - [x] ~~Test Zip > Encrypt > Split > Send\Recieve > Join > Decrypt > Unzip~~
> - [x] ~~Test objCon~~
> - [x] ~~Doc API~~
> - [ ] Add Example Code
> 
> **Eventualy:**
> - [ ] Rewrite objData.pack() and objData.unpack() to use a fixed length binnary header instead of dirty string manipulation

####Disclaimer:
This is a toy project, and should not be used for production grade anything ... use at your own risk
