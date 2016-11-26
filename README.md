# SwiftyWCO
A Swift-based Watson Conversation Orchestrator - augment Watson Conversation with additional data &amp; API calls.

This project is a basic Service Orchestrator for the Watson Conversation service. Use this if you want to do more than just call the basic Watson Conversation. Specifically, SwiftyWCO supports:
- Stores and retrieves Watson Conversation "context object" in a Cloudant database, so that context can be retained across calls to Watson Conversation.
- Enrich the input to Watson Conversation by making additional API calls that append their results to the Conversation Context Object. For example, call the AlchemyAPI Language service to extract entities, add those to the Context Object and then reference them in a Watson Conversation Dialog - such as when you ask for a bot user's name.
- Massage the results from the Watson Conversation service by post-processing the output. Use this to inspect the output from Watson Conversation and conditionally call an external API and change what is sent back to the user before it is sent. For example, maybe you are collecting information for a restaurant booking - once you've collected all the data items needed, this is how you then call the restaurant reservation system.

## Enriching the input to Watson Conversation
The EnrichIncoming function of the EnrichIncoming module is where you make API calls, etc and augment the Context Object with additional data that can then be referenced in your Dialog flow.

You can change/add data on the following objects:

   `enrichedMsgBody` - the body of the incoming message from the user,

   `enrichedContext` - the Watson Conversation Context Object,

Make sure to call `completionHandler(responseJSON)` after your work in order that the SwiftyWCO controller might continue with its good work and process the message through Watson Conversation.

## Post-process the output of Watson Conversation
A good pattern to adopt where you need conditional post-processing of the output of Watson Conversation (for example, where you need to call an API at a certain point in a Dialog) is as follows
 - Set a Watson Conversation Context Object from within the Advanced mode in Watson Conversation Dialog to a given value. This variable acts as a flag to SwiftyWCO indicating it should take a certain action. e.g. set Special_Action to "restaurantReservation".
 - In PostProcessOutgoing function of the PostProcessOutgoing module, inspect your Context Object variable (Special_Action) and take conditional actions. e.g. if Special_Action == "restaurantReservation" then call the restaurant reservation API.
 - Depending on the result of your conditional logic, you might change text of the response message e.g. set the response text to "Thank you, your restaurant was successfully booked."

Make sure to call `completionHandler(responseJSON)` after your work in order that the SwiftyWCO controller might continue with its good work and return the results to the user.

