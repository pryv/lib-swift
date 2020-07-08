# lib-swift
Pryv's Swift library for iOS


|         |                       |
| ------- | --------------------- |
| Authors | Sara Alemanno |
| Reviewers | Pierre-Mikael Legris, Ilia Kebets |
| Date    | July 7th 2020 |
| Version | 1                  |

## Motivation

Create a SDK that developers could use to connect and interact with the Pryv API.  
Currently, the iOS developers should implement by themselves the requests to the API as described on [https://api.pryv.com/](https://api.pryv.com/). This SDK is meant to facilitate writing iOS apps for a Pryv.io platform.

## Proposition

We propose **an SDK** that will handle all the networking and interactions with the API for their iOS applications.  
  
This will allow the developers to interact with the API with simple structures.   
  
This framework will be structured as the [lib-js](https://github.com/pryv/lib-js) library, which is already available.  
  
An example of app using this framework can be found on [app-swift-example](https://github.com/pryv/app-swift-example).
  
## Deliverables

### API

- Generate a token to grant the access to the user's data
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
