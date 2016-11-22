# SwiftyWCO
A Swift-based Watson Conversation Orchestrator - augment Watson Conversation with additional data &amp; API calls.

This project is a basic Service Orchestrator for the Watson Conversation service. Use this if you want to do more that just call the basic Watson Conversation. Specifically, SwiftyWCO supports:
- Stores and retrieves Watson Conversation "context object" in a Cloudant database, so that context can be retained across call to Conversation.
- Enrich the input to Watson Conversation by making additional API calls that append their results to the Conversation Context Object. For example, call the AlchemyAPI Language service to extract entities and then reference those in Watson Conversation - such as when you ask for a bot user's name.
- Massage the results from the Watson Conversation service by post-processing the output. Use this inspect the output from Watson Conversation and conditionally call an external API. For example, maybe you are collecting information for a restaurant booking - this capability allows your code to identify when you have all the data items ready and should call the restaurant booking API.

