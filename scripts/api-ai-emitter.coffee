# Description
#   Talks with api.ai back-end to create smart bots with
#   conversational user experience
#
# Configuration:
#   API_AI_CLIENT_ACCESS_TOKEN
#
# Commands:
#   None
#
# Notes:
#   This script listens to everything and get a dialog
#   going with api.ai. Once the intent is fully resolved,
#   it will use robot.emit to trigger additional scripts
#   It essentially act as an intelligent router for your
#   scripts.
#   NOTE: this script should be the only one listening to
#         chat conversations or you will get conflicts
#
# Author:
#   Olivier Jacques
#   Inspired by WIT bot from Adriano Godoy

apiai = require('apiai')
util = require('util')

ai = apiai(process.env.API_AI_CLIENT_ACCESS_TOKEN)

module.exports = (robot) ->
  robot.respond /(.*)/i, (msg) ->
    query = msg.match[1]
    console.log "respond query: #{query} thread #{getSession(msg)}"
    askAI(query, msg, getSession(msg))

  #robot.hear ///#{robot.name}(,\s+|\s+)(.*)///i, (msg) ->
  #  query = msg.match[1]
  #  console.log "hear query: #{query} thread #{getSession(msg)}"
  #  askAI(query, msg, getSession(msg))

  # WHAT WORKS:
  #  - Can start a conversation, and within that conversation, bot continues the discussion
  #    without using @bot
  #  - TO FIX: 
  #    - Prevent the bot from answering when outside of a thread directed to the bot
  #      (TITLE contains bot name?)
  #      AND this is a user talking (not the bot to itself)
  robot.hear ///(.*)///i, (msg) ->
    if msg.message.metadata.internal_comments > 2
      console.log("2+ internal comments")
    console.log("****CATCHALL msg: " + util.inspect(msg))
    query = msg.match[1]
    console.log "hear query: #{query} thread #{getSession(msg)}"
    askAI(query, msg, getSession(msg))

  getSession = (msg) ->
    # Get an existing or create new session for a user
    return msg.message.metadata.thread_id
    
    

  askAI = (query, msg, session) ->
    unless process.env.API_AI_CLIENT_ACCESS_TOKEN?
      msg.send "I need a token to be smart :grin:"
      console.log "API_AI_CLIENT_ACCESS_TOKEN not set"
      return

    request = ai.textRequest(query, {sessionId: session})
    request.on('response', (response) ->
      console.log(response)
      if (response.result.actionIncomplete is true)
        # Still refining...
        msg.send(response.result.fulfillment.speech)
      else if (response.result.metadata? && 
               response.result.metadata.intentId? &&
               response.result.action isnt "input.unknown")
        # API.AI has determined the intent
        console.log "Understood! Action complete: " + 
                    response.result.metadata.intentName + ", " + 
                    response.result.parameters
        msg.send("Executing " + 
                 response.result.metadata.intentName + ", " + 
                 response.result.parameters + "...")
      else
        # Default or small talk
        if (response.result.fulfillment.speech?)
          msg.send(response.result.fulfillment.speech)
    )
    request.on('error', (error) ->
      console.log(error)
    )
    request.end()

