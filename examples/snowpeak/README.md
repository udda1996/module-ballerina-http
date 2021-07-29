# Going Back to Writing True REST APIs with Ballerina

“REST” APIs are so pervasive these days. Almost all the APIs out there in the internet are described as REST APIs. Those APIs include different HTTP verbs and resources unlike traditional RPC like APIs or SOAP based web services. But what if someone says, those are not RESP APIs would you agree or disagree ? Actually most of the REST APIs out there are sort of the semi-REST APIs and at times doesn’t even reap the full benefits of REST tenets. This article is an attempt to revive the original REST tenets in pragmatic terms.

This article will be using a reverse order in the sense that it starts with a well written REST API which is based on the tenets Roy Fielding originally proposed and then ends with the server side discussion on how to implement it. This would help us to focus more on the interface of the API than the internal implementation details. 

# User Challenge 

Snowpeak REST API is used for this challenge. Snowpeak is a fake holiday resort which lets users make reservations for rooms. Now here is the challenge: say you’ve been asked to complete the goal of making a reservation for rooms using the given API. Following two things will be given to you to work with overcoming the challenge. 

Disclaimer: Please note that some of the nitty gritty details of the API are dropped intentionally to keep it simple. Here, the goal is to discuss REST principles but not to discuss how to write a proper room reservation API.

1. The only well-know of the REST API: http://localhost:9090/snowpeak/locations
2. Relation semantics as explained in the below table

| Reations      | Description |
| ----------- | ----------- |
| room      | Refers to a resource that provides information about snowpeak rooms       |
| reservation   | Indicates a resource where reservation is accepted        |
| cancel| Refers to a resource that can be used to cancel the link's context |
|edit| Refers to a resource that can be used to edit the link's context |
|payment | Indicates a resource where payment is accepted|

Note that *edit* and *payment* are [IANA registered relations](https://www.iana.org/assignments/link-relations/link-relations.xhtml)

## HTTP Idioms
Before solving the challenge, it is expected that as a REST API user, you would understand the basic HTTP verbs such as GET, POST, PUT, DELETE, PATCH and HTTP response status codes such as 200 (OK), 201 (Created), 401 (Conflict), etc. 

# Solving the Challenge 

Solving the challenge would require you to complete a certain workflow which has multiple steps. Each step will reveal the possible next steps you can take. At each step you will have to decide which step to take next based on the application semantics.

Before we start anything let's get the openAPI documentation from the given URL and import it to postman. It is much easier to understand the application semantics via postman than reading the raw openAPI documentation. Besides, it is fair to say that, postman is the de-facto client for trying out REST APIs. To get the openAPI documentation, first we need to send an OPTIONS request to the well known URL, which results in the below response.

```
HTTP/1.1 204 No Content
allow: OPTIONS, GET, HEAD, POST
date: Thu, 13 Oct 2016 11:45:00 GMT
server: ballerina
link: </snowpeak/openapi-doc-dygixywsw>;rel="service-desc"
```
Now, to get the openAPI documentation, we need to send a GET request to the URL in the `link` header. In this case, we need to import the openAPI documentation to postman by giving the discovered URL for the service description. 

All set, before we start, remember our goal is to make a room reservation. Let’s start with the well-known URL and see what it has to offer. Doing a get request to that results in the below response. 

```json
{
   "collection": [
       {
           "name": "Alps",
           "id": "l1000",
           "address": "NC 29384, some place, switzerland",
           "links": [
               {
                   "rel": "room",
                   "href": "/snowpeak/locations/l1000/rooms",
                   "mediaTypes": [
                       "applicaion/vnd.snowpeak.resort+json"
                   ],
                   "actions": [
                       "GET"
                   ]
               }
           ]
       },
       {
           "name": "Pilatus",
           "id": "l2000",
           "address": "NC 29444, some place, switzerland",
           "links": [
               {
                   "rel": "room",
                   "href": "/snowpeak/locations/l2000/rooms",
                   "mediaTypes": [
                       "applicaion/vnd.snowpeak.resort+json"
                   ],
                   "actions": [
                       "GET"
                   ]
               }
           ]
       }
   ]
}
```
It seems as per the response Snowpeak offers two locations. Say we are interested in taking the first option. As per the link section in the response, the next possible request is again a GET request to the given URL. The relation of the target URL is `room` which basically hints that this is a link to GET room(s).

That sounds like the next step to take or the link to activate/follow to reach our goal. But what are the application semantics related to this request? To figure out this look for the request with matching target URL in postman. You will see all the application semantic details to activate the target URL. Once you activate the target URL with relation `room`, you should get the below response. 

```json
{
   "rooms": [
       {
           "id": "r1000",
           "category": "DELUXE",
           "capacity": 5,
           "wifi": true,
           "status": "AVAILABLE",
           "currency": "USD",
           "price": 200.00,
           "count": 3
       }
   ],
   "links": [
       {
           "rel": "reservation",
           "href": "/snowpeak/rooms/reservation",
           "mediaTypes": [
               "applicaion/vnd.snowpeak.resort+json"
           ],
           "actions": [
               "POST"
           ]
       }
   ]
}
```
It seems only DELUXE rooms are available but that is fine. Our goal is to make a reservation for any room. This time the decision is quite straightforward as there is on target URL with relation `reservation` which probably indicates that we should follow that link to achieve our goal. Unlike the previous two requests in this case the server is suggesting that we need to send a POST request. Again for application semantics let’s look for that target URL in postman.  

You will see that you have all the application semantic information to activate the target URL. In response you should get the below,
```json
{
   "id": "re1000",
   "expiryDate": "2021-07-01",
   "lastUpdated": "2021-06-29T13:01:30Z",
   "currency": "USD",
   "total": 400.00,
   "reservation": {
       "reserveRooms": [
           {
               "id": "r1000",
               "count": 2
           }
       ],
       "startDate": "2021-08-01",
       "endDate": "2021-08-03"
   },
   "links": [
       {
           "rel": "cancel",
           "href": "/snowpeak/reservation/re1000",
           "mediaTypes": [
               "applicaion/vnd.snowpeak.resort+json"
           ],
           "actions": [
               "DELETE"
           ]
       },
       {
           "rel": "edit",
           "href": "/snowpeak/reservation/re1000",
           "mediaTypes": [
               "applicaion/vnd.snowpeak.resort+json"
           ],
           "actions": [
               "PUT"
           ]
       },
       {
           "rel": "payment",
           "href": "/snowpeak/payment/re1000",
           "mediaTypes": [
               "applicaion/vnd.snowpeak.resort+json"
           ],
           "actions": [
               "POST"
           ]
       }
   ]
}
```
As in representation now you have a reservation ID. As the next step server sends back an array of possible steps we can take. As the next step you can take `cancel`, `edit` or `payment` options. In this case following the `payment` seems to be the right option as our goal is to reserve a room. So as the next step lets activate the `payment` link. Again, semantic details of the target URL can be found in postman. 

Doing so should result in the below response. 

```json
{
   "id": "p1000",
   "currency": "USD",
   "total": 400.00,
   "lastUpdated": "2021-06-29T13:01:30Z",
   "rooms": [
       {
           "id": "r1000",
           "category": "DELUXE",
           "capacity": 5,
           "wifi": true,
           "status": "RESERVED",
           "currency": "USD",
           "price": 200.00,
           "count": 1
       }
   ]
}
```
Above 200 - OK response with room status RESERVED, basically let us know that the room is reserved. Also as in the previous representation server has not sent it links to follow which basically means we have completed the business workflow. In other words we have successfully achieved our goal.  

If you look back at the whole experience, it was all about resource representations and a possible set of future state transitions that the user might take. We started with the well-known URL and then at each step we discovered the possible set of next steps. Server kept on guiding us with a self-descriptive set of messages until we reached the goal. What you experienced is a true REST API. 

The experience is quite similar to what you experience when reserving a room via booking.com, agoda.com or any other similar site. None of the staff members of those sites had to explain to you how to make the reservation. It was self-descriptive and all information needed to make right decisions was made available.

Only difference is in the first case we used JSON form for resource representation whereas in the second case they have used HTML form for resource representation. 

In the next section we will look into the implementation of this REST API while looking into all the details of REST principles and its benefits. At the end of the article you will have all the knowledge to implement proper REST APIs.

# Developer Challenge 
## Origin of REST
In the early 1990s the foundation of the World Wide Web was introduced to share documents in an easy-to-use, distributed, loosely coupled way. Within years it grew from research and academic sites to fully fledged commercial sites. But have you ever wondered why the Web is so ubiquitous? What enabled it to grow so fast ? Why is it so successful ? 

Roy Fielding did ask those questions in his dissertation “Architectural Styles and the Design of Network-based Software Architectures”. He came up with six constraints to help us build loosely coupled, highly scalable, self-descriptive and unified distributed systems. 

As you noticed in the previous section there are a lot of similarities between REST APIs and World Wide Web. I think now you know why. Following are key principles one need to keep in mind when designing REST APIs.

- Addressable resources 
- Representation oriented 
- A uniform constrained interface 
- Stateless communication
- Hypermedia As The Engine Of Application State (HATEOAS)

Also it is good to remind ourselves of the technology stack of the Web as REST API implementations strongly depend on the same stack.

![image](_resources/web-tech-stack.png)

URL is used to uniquely identify and address a resource. HTTP is used to describe how to interact with a resource. Hypemedia is used to present what comes next.

## Evaluation of REST

Ever since the REST architecture pattern was introduced by Roy Fielding in 2000, there has been a massive adaptation. People started with RPC and then moved on to use vendor neutral SOAP based web services. Many of those SOAP based web services converted into RESTFul APIs. Single URL SOAP based web services with multiple SOAP actions were converted into RESTful APIs with multiple URLs and multiple verbs. However, people didn’t go altherway and finish off their RESTful APIs with HATEOAS. A key constraint that is often ignored. Therefore many REST APIs out there are not actually REST APIs. In fact, over time people started using the term “REST” to describe all the none-SOAP services.

Roy Fielding noticed that many are actually calling those types of APIs as REST APIs. [Here](https://roy.gbiv.com/untangled/2008/rest-apis-must-be-hypertext-driven) is what he had to say about it. Therefore, most APIs out there are actually not REST APIs, we are better off calling them maybe Web APIs. Anyway, maybe this is what happens when you come up with a good set of principles but don't bother to enforce them.

## Richardson Maturity Model (RMM)

Richardson came with a nice classification in 2008 to understand the relationship between the Web API and REST constraints. This classification includes four levels. Each level is built on top of the other. 

- Level 0 - Web APIs with one URL and only use POST method
- Level 1 - Web APIs with multiple resources (URLs) but only use POST method
- Level 2 - Web APIs with multiple resources (URLs) and multiple methods such as GET, PUT, POST, DELETE
- Level 3 -  Web APIs with hypermedia as the engine of application state 

As you can see, many Web APIs out there stop at level 2 and that has a profound impact on the API you design. We will get to that in a later section. For more information on RMM check this article. 

## Designing Snowpeak API

First thing you need to do when designing REST APIs is coming up with a good state machine. It helps you understand the resources, representations and state transitions. This definitely requires a good understanding of the business context. In this case, the workflow related to making a reservation. As you noticed in the first section users only see representations and a set of next possible requests or state transitions. They don’t actually see the resource itself. Therefore, when drawing the state diagram start with filling in the resource representations and state transitions. State transitions do not need to have the exact HTTP verbs but it is better to note down if the state transition is safe, unsafe and idempotent, unsafe and non-idempotent. Following is the state diagram for Snowpeak reservation API.

![image](_resources/snowpeak-state-diagram.png)

Please note that the fields in each representation are not listed in each box for brevity. As you can see there are five representations and multiple state transitions. On each state transition you can see the relation which helps us understand why we need to activate a particular state transition.  

If you really think about it, it is just a breakdown of hierarchical data linked by relations. 

## Developing Snowpeak API

For the development of this API as you might have rightly guessed Ballerina is used. Each representation in the state diagram can be mapped to record types in Ballerina. For example, representations related to location can be mapped as below.

```ballerina
# Represents locations
type Location record {|
   *Links;
   # Name of the location
   string name;
   # Unique identification
   string id;
   # Address of the location
   string address;
|};
```

Location has three fields: name, id and address. Each field is documented along with the Location record. Documentation is very important because it helps readers of the code to understand the code better and at the same time it helps API users understand the API as this documentation is mapped into OpenAPI documentation as descriptions. Many developers tend to think of documentation as a second class thing but it is not.

`*Links` syntax basically copies fields in the Links record to Location record. Links record is simply an array of Link records that basically have all the fields related to hyperlinks. 

Likewise for each representation which goes back and forth between the client and server, there is a defined record. Check the representation module for more information.

## Domain Specific Media Type

Once all the resource representations are mapped into records, you could see that these representations are specific to the domain of room reservation. To represent the collection of these resource representations we can define a media type. This media type can be used to understand the application semantics of the API. `application/vnd.snowpeak.resort+json` is the media type we have chosen for this domain. Then for the media type usually a media type specification is written to bridge the application semantic gap. Further, the media type could be registered under IANA if needed. 

Users of the API can look up media type and locate the media type specification for application semantics. Here is a [link](http://amundsen.com/media-types/maze/) for a good example of media type specification.

However, the purpose of a media type is to provide application semantics. Application semantics could be also understood using a well-written openAPI documentation. In Ballerina this openAPI documentation is automatically generated from the code itself. Hence, eliminating the need for writing a media type specification.

### JSON is Not a Hypermedia Format

First of all, what is hypermedia? hypermedia is a way for the server to tell the client what HTTP requests the client might want to make in the future. It’s a menu, provided by the server, from which the client is free to choose. 

Ballerina records are by default serialized into JSON and it is not a hypermedia format such as HTML, HAL, Siren, etc. Ballerina has introduced its own semantics to include hypermedia links in JSON. Even though client tools may not understand those as hyperlinks, humans do which is good enough. Besides those semantics are based on top of the well-known concepts such as `rel`, `href`, `mediatype`, `actions`, which makes it self-descriptive. 

## Implementing Resources

Now that we have representations of resources we can start writing down the resources itself. For this in Ballerina we can use `resource` functions. Resource functions can only be inside a service object. Following is the Snowpeak API signatures required to implement the aforementioned state diagram. 

```ballerina
service /snowpeak on new http:Listener(9090) {

    resource function get locations() returns rep:Locations {}

    resource function get locations/[string id]/rooms(string startDate, string endDate) returns rep:Rooms {}

    resource function post reservation(@http:Payload rep:Reservation reservation) returns rep:ReservationCreated|rep:ReservationConflict {}

    resource function put reservation(@http:Payload rep:Reservation reservation) returns rep:ReservationUpdated|rep:ReservationConflict {}

    resource function post payment/[string id](@http:Payload rep:Payment payment) returns rep:PaymentCreated|rep:PaymentConflict {}
}
```
### Resource and URL
REST resources are mapped into resource functions in Ballerina. Unlike in other languages Ballerina supports hierarchical resource paths. In other words resource paths can be specified directly without having to use any annotations. This makes the code concise and readable. Also as part of the URL, it is possible to define path params as well. Path params automatically become variables of resource functions. Again making the code concise and readable. During runtime path param values are populated by the listener. Usually the last part of the URL denotes the name of a resource such as room, reservation, payment, locations, etc.

### URL Design Doesn’t Really Matter
There is a popular fallacy that URLs need to be meaningful and well-designed. But as far as REST is concerned URL is just a unique string used to uniquely identify and address a resource. That is its only job. Therefore URLs can be opaque to humans. That being said, there is no harm in having well-designed meaningful URLs. In fact, as REST API designers our job is to make the REST API as self-descriptive as possible. But it is better to keep in mind that nice looking URLs are great but they are cosmetics.  

## Adding Protocol Semantics to Resources
Now that we have defined resource representations, resources and URLs as the next step we can add protocol semantics. Since HTTP is the de facto transport protocol for REST, protocol semantics are tightly coupled to HTTP idioms. For any given REST API the operations are fixed. However, those fixed number of operations can be used to implement an infinite number of REST APIs. Basic CRUD (Create, Read, Update, Delete) operations are mapped into HTTP verbs. Following are the HTTP verbs and it is protocol semantics.

- GET - Lets you retrieve a resource representation. GET requests are always safe and subject to caching. Since it is safe it is idempotent as well.
- POST - Lets you create a new resource or append a new resource to a collection of resources. 
- PUT - Lets you create a new resource or update an existing resource
- PATCH - Lets you partially update an existing resource whereas PUT update the entire resource
- DELETE - Lets you delete a resource

HEAD and OPTIONS verbs are used to introspect resources. Also note that LINK and UNLINK verbs are no longer used officially. 

At the same it is expected to make sense of HTTP response status codes such as,

Success - 200 (OK), 201 (Created), 202 (Accepted), etc
Client Failure - 401 (Unauthorized), 409 (Conflict), 405 (Method not allowed), etc 
Server Failure - 500 (Internal server error), 502 (Gateway timeout), etc

This is what uniform interface constraint means. It basically means we should only have a small number of operations(verbs) with well defined and widely accepted semantics. These operations can be used to build any type of distributed application.

All right now that you have some idea about protocol semantics, let’s see how it is added in Ballerina. Ballerina lets you add operations/accessors just before the resource path. For example, consider the following,

```ballerina
resource function get locations() returns Locations{}
```
If you remember the state diagram, you know that retrieving location is a safe operation. Therefore, we have set the GET accessor for it. For the response, we have returned Locations which basically means a 200 OK response with a JSON object. 

Let's look at something more interesting,
```ballerina
resource function post reservation(@http:Payload Reservation reservation) returns ReservationCreated|ReservationConflict
```
If you can remember the state diagram, it was depicting that unsafe but idempotent state transition is possible from rooms to reservation. As a result of this transition we need to create a new reservation resource. By now you know that the POST verb is used to create a resource. Therefore post is used as the action/operation in front of the resource. There are two possible responses, one is `ReservationCreated` and the other is `ReservationConflict`, these responses are mapped in Ballerina as follows,

```ballerina
type ReservationCreated record {|
   *http:Created;
   ReservationReceipt body;
|};
type ReservationConflict record {|
   *http:Conflict;
   string body = "Error occurred while updating the reservation";
|};
```
For each status code Ballerina provides a predefined type which can be used to create more specific subtypes. In this case we have created two new subtypes using http:Created and http:Conflict. Not only doing so improves the readability of the code but also helps generate a meaningful openAPI documentation out of the code.

## Adding HATEOAS (Hypermedia As the Engine of Application State)

Alright, we are almost done. The last but not the least. This is one of the core tenets in REST but often neglected. Could be because of the name, it sounds intimidating and complex. But it is all about the connectedness in other words the links that were there in responses of Snowpeak API. Therefore, we are better off calling this constraint simply Hypermedia constraint.

There is no big difference between an application state engine and an ordinary state machine. Only difference is unlike an ordinary state machine, in this case possible next states and transitions are discovered at each state. User has no knowledge of those states and transitions in advance. 

However, implementing this simple constraint has a profound impact on the RESP API outcome.

1. Significantly reduces the well-known URLs users need to know when working with a given REST API. In fact, ideally you only need to know one URL which is the well-known URL to get started. Using the well-known URL you should be able to complete any business workflow.
2. REST API becomes more self-descriptive. Imagine the user challenge explained above without the connected links. You would only see a bunch of disconnected resource endpoints. Then to bridge the gap the API developer must write human readable documentation and then sync it every time there is a change. On the other hand the API user has to find the documentation, find the right workflow and read it from start to finish before doing anything.
3. Decouples interaction details because most URLs are pre-constructed by the server for you, you don’t need to know how to build the URLs to do the next state transition. 
4. Give flexibility to evolve the API. Adding new resources and state transitions automatically reflects on the client side. While existing users can continue to function, the addition can be discovered and used by new users.

The experience you would have with a well-written REST API is very similar to the experience you have with any website. You just use the standard client in this case the browser and then enter the well known URL. Then the server sends back a HTML page with more links to activate. Any average user with some sense about the business context can navigate the website and complete a given task. The Web is self-describing. Therefore, you don’t need someone else's help to complete the task. The same thing is applicable for REST APIs and that is what you experienced the under user challenge. Of course there could be gaps in application semantics which you will have to cover up with writing human readable documentation. But that documentation will be minimal.

Now going back to the implementation of Snowpeak API. By now you know that links in the response are simply the arrows in the state diagram. That is why it is very important to draw a state machine for your REST API.

In Ballerina to implement the Hypermedia constraint you need to do two things. As you already know when defining representations you need to include the Links record to your representations.

```ballerina
# Represents locations
type Location record {|
   *Links;
   # Name of the location
   string name;
   # Unique identification
   string id;
   # Address of the location
   string address;
|};
```
The Links record definition is as below,
```ballerina
type Link record {|
   string rel;
   string href;
   string[] mediaTypes?;
   Action[] actions?;
|};
type Links record {|
   Link[] links;
|};
```
Therefore, when creating the value for Location record during runtime, you need to fill the rel and href fields. mediaTypes and actions fields are optional and the reason is because those information could be retrieved from openAPI documentation as well. It is important to choose the right values for `rel` field. It basically means why one should activate a given link. For IANA registered relations check [here](https://www.iana.org/assignments/link-relations/link-relations.xhtml). When extending this list it is usually a good practise to extend it under your domain. That way there won't be any conflicts of extended relations.

# Caching and Statelessness 

## Caching
Alright now you know how to design and implement a good REST API using Ballerina. But we haven’t still discussed Caching and Statelessness which play a key role in REST APIs. Safe (which is also idempotent) requests can be cached by proxy-servers, CDNs, clients, etc. This is possible mainly because of the well-defined verbs that are there in HTTP. In other words any response for GET requests can be instructed to cache on the client side. This allows the REST APIs to scale well just like the web does. Here is how you can configure caching in Ballerina.

```ballerina
resource function get locations() returns @CacheControl Location[]{}
```

There are things you configure in @CachControl annotation. For more information see the API docs.

## Statelessness 
When it comes to REST APIs stateless means, API implementation should not maintain client state. In other words, all the client state is with the client. Client needs to send the state back and forth as needed. Therefore, each client request does not depend on the previous client request. This again helps the RESP APIs to scale. 

# Summary
Writing good REST APIs isn’t hard. A well-written REST API has the  characteristics of scalability, uniformity, performance and encapsulation. The experience you have with the REST APIs isn’t much different from the Web. After all, REST tenets derived by studying the Web. Users of the REST API aren’t expected to be friends or colleagues of the REST API developers. Therefore, REST APIs must be as self-descriptive as possible. Rest of the application semantics must be covered by writing standard human readable documentation. Any average user with a standard HTTP client should be able to interact with any REST API with the same development process. The only difference is the business context. Remember REST APIs may be old but not obsolete. 




