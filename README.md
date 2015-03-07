# sling-client-node

A Node.js client for [Sling](http://getsling.com)

## Installation

In order to run this Sling client you will need [Node.js](http://nodejs.org/) and [npm](https://www.npmjs.com/).

Once you have Node.js and npm you can clone this repository.

```
> git clone git@github.com:gangverk/sling-client-node.git
```

Then it's just a matter of installing the dependencies.

```
> cd sling-client-node
> npm install
```

## Running the client

From the `sling-client-node` directory run the following command. You will need to use valid credentials in the `basic.coffee` example script.

```
> ./node_modules/coffee-script/bin/coffee examples/basic.coffee
```

By default the client will use the production environment for the Sling API and web sockets. This behaviour can be overridden by setting `SLING_NODE_API_HOST` and `SLING_NODE_WSS_URL` environment variables.
