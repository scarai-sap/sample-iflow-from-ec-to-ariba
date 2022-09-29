import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
import groovy.json.*;

def Message processData(Message message)
{
	def messageLog = messageLogFactory.getMessageLog(message);

	def method = message.getHeader("CamelHttpMethod", String);

	def body = message.getBody(java.lang.String.class);

	def msgBody = new JsonSlurper().parseText(body);

	msgBody = updatePropertyWithTranslation(msgBody, message.getProperty("language"));

	msgBody = updatePriceWithConfig(msgBody, message.getProperty("currency"));

	def updatedMsg = new JsonBuilder(msgBody).toPrettyString();
	message.setBody(updatedMsg);

	messageLog.addAttachmentAsString("updatedMsg ", updatedMsg, "text/plain");


	return message; ;
}


/*
    return changed object for adding price
*/

def Object updatePriceWithConfig(msgBody, selectedCurrency)
{

	def priceList = msgBody.get("europe1Prices")

	msgBody.put("price", "0");

	if (priceList)
	{
		for (price in priceList)
		{
			if (price.get("currency") && price.get("currency").get("isocode") == selectedCurrency)
			{
				msgBody.put("price", price.get("price"));
				break;
			}
		}
	}

	return msgBody;
}

/*
    return changed object for use localized value
*/
def updatePropertyWithTranslation(msgBody, selectedLan)
{
	def localizedAttributes = msgBody.get("localizedAttributes");
	def selectedLanguageAttr;
	if (localizedAttributes)
	{
		for (attr in localizedAttributes)
		{
			if (attr.get("language") == selectedLan)
			{
				selectedLanguageAttr = attr;
				break;
			}
		}
		if (selectedLanguageAttr) 
		{
		    for (entry in msgBody)
    		{
    			def entryKey = entry.getKey();
    			if (selectedLanguageAttr.containsKey(entryKey))
    			{
    				entry.setValue(selectedLanguageAttr.get(entryKey))
    			}
    		}
		}

	}
	return msgBody;

}
