Log = require 'log'

SlingClient = require '..'

# Construct a logger and a Sling client
@logger = new Log 'info'
client = new SlingClient 'bot@sling.is', 'badf00d'

# Wire up the event handlers
client.on 'open', ->
  @logger.info "ws:open"

client.on 'close', ->
  @logger.info "ws:closed"

client.on 'message', (message) ->
  @logger.info "ws:message :: #{JSON.stringify(message)}"

client.on 'error', (error) ->
  @logger.info "ws:error :: #{error}"

# Log the bot user into Sling
client.login()
