https          = require 'https'
Log            = require 'log'
WebSocket      = require 'ws'
{EventEmitter} = require 'events'

Message = require './message'
User    = require './user'

class SlingClient extends EventEmitter
  apiHost: process.env.HUBOT_SLING_API_HOST or 'api.sling.is'
  socketUrl: process.env.HUBOT_SLING_WSS_URL or 'wss://socket.sling.is'

  # Construct a new instance of the Sling client.
  #
  # email_address - The email address of the bot's user account in Sling.
  # password      - The password of the bot's user account in Sling.
  constructor: (@email_address, @password) ->
    @connected     = false
    @self          = null
    @token         = null
    @ws            = null
    @logger        = new Log 'info'

  # Log the user into Sling.
  #
  # Returns nothing.
  login: ->
    @logger.info 'Logging in...'
    @_apiCall 'POST',
              'account/login',
              {'email': @email_address, 'password': @password},
              @_onLogin

  # Log the user out of Sling.
  #
  # Returns nothing.
  logout: ->
    @logger.info 'Logging out...'
    @_apiCall 'DELETE', 'account/session', null, @_onLogout

  # Completion handler for loggin into Sling.
  #
  # Returns nothing.
  _onLogin: (data) =>
    if data
      if not data.ok
        @emit 'error', data.error
      else
        if data.headers and data.headers.authorization
          # Store the authorization token
          @token = data.headers.authorization

          # Store information about the user and inform
          # listeners the bot has logged into Sling.
          @self = new User @, data.body.user
          @emit 'loggedIn', @self
          
          # Connect to the Sling web sockets server
          @connect()
        else
          @emit 'error', 'No authorization header returned.'
    else
      @emit 'error', data
  
  # Completion handler for logging out of Sling.
  #
  # Returns nothing.
  _onLogout: (data) ->
    if data
      if not data.ok and @logger
        @logger.error 'Unable to log out. ' + data.error
      else
        @token = null

  # Establish a connection to Sling via web sockets.
  #
  # Returns nothing.
  connect: ->
    @ws = new WebSocket @socketUrl

    @ws.on 'open', =>
      @connected = true
      @_send {'command': 'join', 'room': @token}
      @emit 'open'

    @ws.on 'message', (data, flags) =>
      @onMessage JSON.parse(data)

    @ws.on 'error', (error) =>
      @emit 'error', error

    @ws.on 'close', =>
      @emit 'close'
      @connected = false

    @ws.on 'ping', (data, flags) =>
      @ws.pong

  # Send a message to Sling via web sockets.
  #
  # message - The message to be sent.
  #
  # Returns nothing.
  _send: (message) ->
    if @connected
      @ws.send JSON.stringify(message)

  # Process a message received from a Sling conversation.
  #
  # message - The message envelope that was received.
  #
  # Returns nothing.
  onMessage: (message) ->
    switch message.command
      when "message:new"
        if message.msg.author.id isnt @self.id
          @emit 'message', new Message message

  # Send a message to a Sling conversation.
  #
  # message - The envelope containing the message to be sent
  #
  # Returns nothing.
  send: (message) ->
    @_apiCall 'POST',
              'conversations/' + message.room + '/messages',
              {'content': message.content},
              null

  # Submit a request to the Sling API.
  #
  # method   - The HTTP method for the request.
  # path     - The request path.
  # payload  - Data to be included in the request body.
  # callback - The function to call when a response is received.
  #
  # Returns nothing.
  _apiCall: (method, path, payload, callback) ->
    options =
      hostname: @apiHost,
      method: method,
      path: 'https://' + @apiHost + '/' + path

    post_data = JSON.stringify(payload)
    
    if post_data
      options.headers = 
        'Content-Type': 'application/json;charset=utf-8',
        'Content-Length': post_data.length

    # Add the authorization token to the request one exists
    if @token
      options.headers.Authorization = @token

    # Construct the request
    req = https.request(options)

    # Create the handler for receiving response data
    req.on 'response', (res) =>
      buffer = ''
      res.on 'data', (chunk) ->
        buffer += chunk

      res.on 'end', =>
        if callback?
          if res.statusCode is 200
            headers = res.headers
            body = JSON.parse(buffer)
            callback({'ok': true, 'headers': headers, 'body': body})
          else
            callback({'ok': false, 'error': 'API response: ' + res.statusCode})

    # Create the handler for errors with the request
    req.on 'error', (error) =>
      if callback? then callback({'ok': false, 'error': error.errno})

    # Add data to the request body if supplied
    if post_data
      req.write('' + post_data)

    req.end()

module.exports = SlingClient
