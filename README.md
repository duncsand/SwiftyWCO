# SwiftyWCO
A Swift-based Watson Conversation Orchestrator - augment Watson Conversation with additional data &amp; API calls.

This project is a basic Service Orchestrator for the Watson Conversation service. Use this if you want to do more than just call the basic Watson Conversation. Specifically, SwiftyWCO supports:
- Stores and retrieves Watson Conversation "context object" in a Cloudant database, so that context can be retained across call to Conversation.
- Enrich the input to Watson Conversation by making additional API calls that append their results to the Conversation Context Object. For example, call the AlchemyAPI Language service to extract entities and then reference those in Watson Conversation - such as when you ask for a bot user's name.
- Massage the results from the Watson Conversation service by post-processing the output. Use this inspect the output from Watson Conversation and conditionally call an external API. For example, maybe you are collecting information for a restaurant booking - this capability allows your code to identify when you have all the data items ready and should call the restaurant booking API.

## Enriching the input to Watson Conversation
The EnrichIncoming function of the EnrichIncoming module is where you make API calls, etc and augment the context object with additional data that you can then reference in your conversational flow.

You can change/add data on the following objects:

   enrichedMsgBody - the body of the incoming message from the user,

   enrichedContext - the Conversation Context object,

   enrichedMsg - the text of the incoming message from the user.

## Post-process the output of Watson Conversation
You can set a Converstion Context Object variable as a flag to SwiftyWCO, informing it of conversational events or when it needs to take action. For example, you might set the variable "special_action" on the Conversation Context object to "callRestaurantBookingAPI" in your conversational flow once you have all the data items ready. This flag would then be inspected in the PostProcessOutgoing function of the PostProcessOutgoing module, where appropriate calls to the restaurant booking API service might be made. Make sure to call completionHandler(responseJSON) after your work in order that the SwiftyWCO controller might continue with its good work and return the results to the user.

