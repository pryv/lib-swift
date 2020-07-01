# Connecting
  
**In an iOS app**
  
First, load and import a Swift Socket.IO client library, e.g. [socket.io-client-swift](https://github.com/socketio/socket.io-client-swift).  
Then initialize the connection with the URL (see [https://api.pryv.com/reference/#connecting](https://api.pryv.com/reference/#connecting) for more details):  
  
Pryv.me:  
```
let manager = SocketManager(socketURL: URL(string: "https://{username}.pryv.me/")!, config: [.log(true), .connectParams(["auth": "{accessToken}"])])
let socket = manager.socket(forNamespace: "/{username}")
```
Own domain: 
```
let manager = SocketManager(socketURL: URL(string: "https://{username}.{domain}/")!, config: [.log(true), .connectParams(["auth": "{accessToken}"])])
let socket = manager.socket(forNamespace: "/{username}")
```
DNS-less:
```
let manager = SocketManager(socketURL: URL(string: "https://host.your-domain.io/")!, config: [.log(true), .connectParams(["auth": "{accessToken}"])])
let socket = manager.socket(forNamespace: "/{username}/{username}")
```
