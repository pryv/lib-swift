# Swift library for Pryv.io 

This Swift library is meant to facilitate writing iOS apps for a Pryv.io platform, it follows the [Pryv.io App Guidelines](https://api.pryv.com/guides/app-guidelines/).

## Example

You will find a sample iOS app at [https://github.com/pryv/app-swift-example](https://github.com/pryv/app-swift-example)

## Requirements

iOS 10.0 is required to use this library.

## Usage
  
### Table of Contents
  
- [Import](#import)
- [Obtaining a Connection](#obtaining-a-connection)
  - [Using an API endpoint](#using-an-api-endpoint)
  - [Using a Username & Token (knowing the service information URL)](#using-a-username--token-knowing-the-service-information-url)
  - [Within a WebView](#within-a-webview)
  - [Using Service.login() *(trusted apps only)*](#using-servicelogin-trusted-apps-only)
- [API calls](#api-calls)
- [Advanced usage of API calls with optional individual result](#advanced-usage-of-api-calls-with-optional-individual-result)
- [Get Events Streamed](#get-events-streamed)
  - [Example:](#example-1)
  - [result:](#result)
  - [Example with Includes deletion:](#example-with-includes-deletion)
  - [result:](#result-1)
- [Events with Attachments](#events-with-attachments)
  - [Add attachment to existing event](#add-attachment-to-existing-event)
  - [Get a preview of an attached image](#get-a-preview-of-an-attached-image)
- [High Frequency Events](#high-frequency-events)
- [Connection with websockets](#connection-with-websockets)
  - [Connecting](#connecting)
  - [Lib-swift](#lib-swift)
- [Service Information](#service-information)
  - [Pryv.Service](#pryvservice)
    - [Initizalization with a service info URL](#initizalization-with-a-service-info-url)
    - [Initialization with the content of a service info configuration](#initialization-with-the-content-of-a-service-info-configuration)
    - [Usage of Pryv.Service.](#usage-of-pryvservice)
  
### Import

PryvSwiftKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/pryv/lib-swift.git'
source 'https://github.com/CocoaPods/Specs.git'
pod 'PryvSwiftKit', :git => 'https://github.com/pryv/lib-swift.git', :branch => 'master'
```

### Obtaining a Connection

A connection is an authenticated link to a Pryv.io account.

#### Using an API endpoint

The format of the API endpoint can be found in your platform's [service information](https://api.pryv.com/reference/#service-info) under the `api` property. The most frequent one has the following format: `https://{token}@{api-endpoint}`

```swift
let apiEndpoint = "https://ck6bwmcar00041ep87c8ujf90@drtom.pryv.me"
let connection = Connection(apiEndpoint: apiEndpoint)
```

#### Using a Username & Token (knowing the service information URL)

```swift
let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
service.apiEndpointFor(username: username, token: token).then { apiEndpoint in
    let connection = Connection(apiEndpoint: apiEndpoint)
}
```

#### Within a WebView

The following code is an implementation of the [Pryv.io Authentication process](https://api.pryv.com/reference/#authenticate-your-app). 

```swift
{
    let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
    let authPayload: Json = [ // See: https://api.pryv.com/reference/#auth-request
        "requestingAppId": "lib-swift-test",
        "requestedPermissions": [
            [
                "streamId": "test",
                "level": "manage"
            ]
        ],
        "languageCode": "fr" // optional (default english)
    ]

    service.setUpAuth(authSettings: authPayload, stateChangedCallback: stateChangedCallback).then { authUrl in
        // open a webview with URL(string: authUrl)!
    }
}

// event Listener for Authentication steps, called each time the authentication state changed
func stateChangedCallback(authResult: AuthResult) {
    switch authResult.state {
    case .need_signin: // do nothing if still needs to sign in
        return
        
    case .accepted: 
        // close webview
        let connection = Connection(apiEndpoint: authResult.apiEndpoint)
        print("Successfully authenticated: \(connection.getApiEndpoint())")
        
    case .refused: 
        // close webview
        
    case .timeout: 
        // close webview
        print("Authentication timed out")
    }
}
```

#### Using Service.login() *(trusted apps only)*

[auth.login reference](https://api.pryv.com/reference-full/#login-user)

```swift
import Promises

let pryvServiceInfoUrl = "https://reg.pryv.me/service/info"
let appId = "lib-swift-sample"
let service = Service(pryvServiceInfoUrl: pryvServiceInfoUrl)
service.login(username: username, password: password, appId: appId).then { connection in 
    // handle connection object
}
```

### API calls

Api calls are based on the `batch` call specifications: [Call batch API reference](https://api.pryv.com/reference/#call-batch)

```swift
let apiCalls: [APICall] = [
  [
    "method": "streams.create",
    "params": [
        "id": "heart", 
        "name": "Heart"
    ]
  ],
  [
    "method": "events.create",
    "params": [
        "time": 1385046854.282, 
        "streamId": "heart", 
        "type": "frequency/bpm", 
        "content": 90 
    ]
  ],
  [
    "method": "events.create",
    "params": [
        "time": 1385046854.283, 
        "streamId": "heart", 
        "type": "frequency/bpm", 
        "content": 120 
    ]
  ]
]

connection.api(APICalls: apiCalls).then { result in 
    // handle the result
}
```

### Advanced usage of API calls with optional individual result

```swift
var count = 0
// the following will be called on each API method result it was provided for
let handleResult: (Event) -> () = { result in 
    print("Got result \(count): \(String(describing: result))")
    count += 1
}

let apiCalls: [APICall] = [
  [
    "method": streams.create,
    "params": [
        "id": "heart", 
        "name": "Heart" 
    ]
  ],
  [
    "method": "events.create",
    "params": [
        "time": 1385046854.282, 
        "streamId": "heart", 
        "type": "frequency/bpm", 
        "content": 90 
    ]
  ],
  [
    "method": "events.create",
    "params": [
        "time": 1385046854.283, 
        "streamId": "heart",
        "type": "frequency/bpm",
        "content": 120 
    ]
  ]
]

let handleResults: [Int: (Event) -> ()] = [
    1: handleResult, 
    2: handleResult
]

connection.api(APICalls: apiCalls, handleResults: handleResults).catch { error in 
    // handle error
}
```

### Get Events Streamed

When `events.get` will provide a large result set, it is recommended to use a method that streams the result instead of the batch API call.

`Connection.getEventsStreamed()` parses the response JSON as soon as data is available and calls the `forEachEvent()` callback on each event object.

The callback is meant to store the events data, as the function does not return the API call result, which could overflow memory in case of JSON deserialization of a very large data set.
Instead, the function returns an events count and eventually event deletions count as well as the [common metadata](https://api.pryv.com/reference/#common-metadata).

#### Example:

``````  swift
let now = Date().timeIntervalSince1970
let queryParams: Json = ["fromTime": 0, "toTime": now, "limit": 10000]
var events = [Event]()
let forEachEvent: (Event) -> () = { event in 
    events.append(event)
}

connection.getEventsStreamed(queryParams: queryParams, forEachEvent: forEachEvent).then { result in 
    // handle the result 
}
``````

#### result:

```swift
[
  "eventsCount": 10000,
  "meta": [
      "apiVersion": "1.4.26",
      "serverTime": 1580728336.864,
      "serial": 2019061301
  ]
]
```

#### Example with Includes deletion:

``````  swift
let now = Date().timeIntervalSince1970
let queryParams: Json = ["fromTime": 0, "toTime": now, "includeDeletions": true, "modifiedSince": 0]
let events = []
var events = [Event]()
let forEachEvent: (Event) -> () = { event in 
    events.append(event)
    // events with .deleted or/and .trashed properties can be tracked here
}

connection.getEventsStreamed(queryParams: queryParams, forEachEvent: forEachEvent).then { result in 
    // handle the result 
}
``````

#### result:

```swift
[  
  "eventDeletionsCount": 150,
  "eventsCount": 10000,
  meta: [
      "apiVersion": "1.4.26",
      "serverTime": 1580728336.864,
      "serial": 2019061301
  ]
]
```

### Events with Attachments

This shortcut allows to create an event with an attachment in a single API call.

```swift
let payload: Event = ["streamId": "data", "type": "picture/attached"]
let filePath = "./test/my_image.png"
let mimeType = "image/png"

connection.createEventWithFile(event: payload, filePath: filePath, mimeType: mimeType).then { result in 
    // handle the result
}
```

#### Add attachment to existing event

```swift
let filePath = "./test/my_image.png"
let mimeType = "image/png"
if let eventId = event["id"] as? String {
    connection.addFileToEvent(eventId: eventId, filePath: filePath, mimeType: mimeType).then { result in
        // handle the result
    }
}
```

#### Get a preview of an attached image

This function allows to get raw data corresponding to a preview of the image attached to the event.

```swift
if let eventId = event["id"] as? String {
    let data = connection.getImagePreview(eventId: eventId) 
}
```
  
### High Frequency Events 

Reference: [https://api.pryv.com/reference/#hf-events](https://api.pryv.com/reference/#hf-events)

```swift
func generateSerie() -> [[Double]] {
  var serie = [[Double]]()
  for t in 0..<100000 { // t will be the deltatime in seconds
    serie.append([Double(t), sin(Double(t)/1000.0)])
  }
  return serie
}

{
    let pointsA = generateSerie()
    let pointsB = generateSerie()

    let postHFData: ([[Double]]) -> ((Event) -> ()) = { points in
        let internalFunction: (Event) -> () = { event in // will be called each time an HF event is created
            let eventId = event["id"] as! String
            connection.addPointsToHFEvent(eventId: eventId, fields: ["deltaTime", "value"], points: points).catch { error in
                print("add point to hf event error: \(error.localizedDescription)")
            }
        }
        return internalFunction
    }

    let pointsA = generateSerie()
    let pointsB = generateSerie()

    let apiCalls: [APICall] = [
      [
        "method": "streams.create",
        "params": [
            "id": "signal1",
            "name": "Signal1"
        ]
      ],
      [
        "method": "streams.create",
        "params": [
            "id": "signal2",
            "name": "Signal2"
        ]
      ],
      [
        "method": "hfs.create",
        "params": [
            "streamId": "signal1",
            "type": "serie:frequency/bpm"
        ]
      ],
      [
        "method": "hfs.create",
        "params": [
            "streamId": "signal2",
            "type": "serie:frequency/bpm"
        ]
      ]
    ]

    let handleResults: [Int: (Event) -> ()] = [
        0: postHFData(pointsA),
        1: postHFData(pointsB)
    ]

    connection.api(APICalls: apiCalls, handleResults: handleResults).catch { error in 
        // handle error
    }
}
```

### Connection with websockets

Pryv.io API supports real-time interaction by accepting websocket connections via Socket.io 2.0. 

#### Connecting

Reference: [https://api.pryv.com/reference/#call-with-websockets](https://api.pryv.com/reference/#call-with-websockets)  
*In an iOS app*

To get an authenticated link to a Pryv.io account, supporting Socket.io, 
* First, load and import a Swift Socket.IO client library, e.g. [socket.io-client-swift](https://github.com/socketio/socket.io-client-swift).  
* Then initialize the connection with the URL (see [https://api.pryv.com/reference/#connecting](https://api.pryv.com/reference/#connecting) for more details):  
  
Pryv.me:  
```swift
let manager = SocketManager(socketURL: URL(string: "https://{username}.pryv.me/")!, config: [.log(true), .connectParams(["auth": "{accessToken}"])])
let socket = manager.socket(forNamespace: "/{username}")
```
Own domain: 
```swift
let manager = SocketManager(socketURL: URL(string: "https://{username}.{domain}/")!, config: [.log(true), .connectParams(["auth": "{accessToken}"])])
let socket = manager.socket(forNamespace: "/{username}")
```
DNS-less:
```swift
let manager = SocketManager(socketURL: URL(string: "https://host.your-domain.io/")!, config: [.log(true), .connectParams(["auth": "{accessToken}"])])
let socket = manager.socket(forNamespace: "/{username}/{username}")
```

#### Lib-swift

This library offers connection, subscribtion to changes and call to methods using Socket.io for your iOS applications. 

```swift
let url = "https://chuangzi.pryv.me/chuangzi?auth=ckc1s4rxj00037cpv3tt39ceb"
let connection = ConnectionWebSocket(url: url) // initialize the connection 
connection.subscribe(message: .eventsChanged) { _, _ in // upon a notification that the events changed ...
    connection.emit(methodId: "events.get", params: ["sortAscending": true]) { result in // get the events changed
        let dataArray = result as NSArray
        let dictionary = dataArray[1] as! Json
        let events = (dictionary["events"] as! [Event])
        events.forEach. { event in 
          print(String(describing: event))
        }
    }
}
connection.connect()
```
  
### Service Information

A Pryv.io deployment is a unique "Service", as an example **Pryv Lab** is a service, deployed on the **pryv.me** domain name.

It relies on the content of a **service information** configuration, See: [Service Information API reference](https://api.pryv.com/reference/#service-info)

#### Pryv.Service 

Exposes tools to interact with Pryv.io at a "Platform" level. 

##### Initizalization with a service info URL

```swift
let service = Service(pryvServiceInfoUrl: "https://reg.pryv.me/service/info")
```

##### Initialization with the content of a service info configuration

Service information properties can be overriden with specific values. This might be useful to test new designs on production platforms.

```swift
let serviceInfoUrl = "https://reg.pryv.me/service/info"
let serviceCustomizations: Json = ["name": "Pryv Lab 2"]
let service = Service(pryvServiceInfoUrl: serviceInfoUrl, serviceCustomization: serviceCustomizations)
```

##### Usage of Pryv.Service.

See: [Pryv.Service](https://pryv.github.io/js-lib/docs/Pryv.Service.html) for more details

- `service.info()` - returns the content of the serviceInfo in a Promise 

  ```swift
  // example: get the name of the platform
  service.info().then { serviceInfo in 
    let serviceName = serviceInfo.name
  }
  ```
  
- `service.infoSync()`: returns the cached content of the serviceInfo, requires `service.info()` to be called first.

- `service.apiEndpointFor(username, token)` Will return the corresponding API endpoint for the provided credentials, `token` can be omitted.
