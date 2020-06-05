# lib-swift
Pryv's Swift library for iOS


|         |                       |
| ------- | --------------------- |
| Authors | Pierre-Mikael Legris, Ilia Kebets |
| Reviewers | Ilia Kebets |
| Date    | June 2nd 2020 |
| Version | 1                  |

## Motivation

Create a SDK that developers could use to connect and interact with the Pryv API.  
Currently, there is a [library](https://github.com/pryv/lib-cocoa), which is implemented in Objective-C. Therefore, the developer could either use this library, which is heavy as it uses caching to store the structures, or implement by himself the requests to the API as described on [https://api.pryv.com/](https://api.pryv.com/), which is tedious. 

## Proposition

We propose **an SDK** that will handle all the networking and interactions with the API for their iOS applications.  
  
This will allow the developers to interact with the API with simple structures.   
  
This framework will be structured as the [lib-js](https://github.com/pryv/lib-js) library, which is already available.  
  
An example of app using this framework can be found on [app-swift-example](https://github.com/pryv/app-swift-example).
  
## Deliverables

### API

- Button to connect to the user's Pryv account
- Generate the a token to grant the access to the user's data
- Connection object to interact with the API
- Call batches to create events 
- Get events streamed 
- High frequency events

### Docs

- API reference

  - authorizing the app 
  - callBatch
  - events.get
  - hfs.create
