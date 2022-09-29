import com.sap.gateway.ip.core.customdev.util.Message;
import org.apache.camel.impl.DefaultAttachment;
import javax.mail.util.ByteArrayDataSource;
import java.util.HashMap;
import groovy.json.JsonSlurper;

def Message processData(Message message)
{

	def messageLog = messageLogFactory.getMessageLog(message);

	def result = getMappedObjects(message);

	messageLog.setStringProperty("Logging result.size(): ", result.size().toString());

	if (result.size() != 0)
	{
		def composedBody = generateCIFHeader(message, result.size()) + generateCIFBody(message, result);
		messageLog.addAttachmentAsString("composedBody", composedBody.toString(), "text/plain");

		// create new data handler and attachment Object
		def ds = new ByteArrayDataSource(composedBody.getBytes(), 'text/xml');
		def attachment = new DefaultAttachment(ds);
		// add headers
		attachment.setHeader("Content-Type", "text/xml; charset=UTF-8");
		attachment.setHeader("Content-ID", "index.cif");
		attachment.setHeader("Content-Description", "products");
		attachment.setHeader("Content-Disposition", "attachment;filename=" + "\"index.cif\"");
		// add attachment to message
		message.addAttachmentObject("index.cif", attachment);
		message.setProperty("queueIsEmpty", "false");
	}
	else
	{
		message.setProperty("queueIsEmpty", "true");
		message.setBody("queue is empty, do nothing")
	}

	return message;
}

def getMapping(message)
{
	def mappingStr = message.getProperty("fieldsMapping");
	def array = mappingStr.split(",")

	def map = new HashMap();
	for (def entry : array)
	{
		def mapKeyValue = entry.split(":");
		map.put(mapKeyValue[0].trim(), mapKeyValue[1].trim());
	}
	return map;
}

/*
    generate cif body from message and map array
*/

def String generateCIFBody(message, input)
{
	def fieldNames = message.getProperty("fieldNames");
	def sampleRows = message.getProperty("fieldSampleData");

	def mapping = getMapping(message);

	def fieldKeyArray = fieldNames.split(",");


	def result = "FIELDNAMES: " + fieldNames + "\n" + "DATA\n";

	for (record in input)
	{
		// item is a map
		def fieldValueArray = sampleRows.split(",")

		for (entry in record)
		{
			// the key is similar like "code"
			def key = entry.getKey();
			if (mapping.containsKey(key))
			{
				//newKey should be ariba key as "Supplier Part ID"
				def newKey = mapping.get(key);
				for (def index = 0; index < fieldKeyArray.length; index++)
				{
					if (fieldKeyArray[index].trim().equals(newKey))
					{
						fieldValueArray[index] = nomalizeCifColumn(entry.getValue().toString(), newKey);
						break;
					}
				}
			}
		}
		result += fieldValueArray.join(",");
		result += "\n"
	}
	result += "ENDOFDATA"
	return result;
}


// See https://jira.tools.sap/secure/RapidBoard.jspa?rapidView=28133&view=detail&selectedIssue=CXEC-14580&quickFilter=144969
def getMaxLengthByKey(String newKey)
{
    switch(newKey)
    {
        case "Short Name":
            return 50;
        case "Item Description":
            return 1000;
        case "SPSC Code":
            return 40;
        case "Unit of Measure":
            return 32;
        case "Language":
            return 128;
        case "Currency":
            return 32;
        default:
            return -1;
    }
}

/*
    truncate the string
    if we have both " and , we have to convert " to '
    if we have " only, or none of them,just return;
    if we have , only, need add quote before and after it;
*/
def nomalizeCifColumn(String s, String newKey)
{
    def maxLen = getMaxLengthByKey(newKey);
    
    // leave 5 for " and other possible Characters.
    def truncatedString = maxLen > 0 ? s.take(maxLen - 5): s;

    def containsComma = s.contains(","), containsQuote = s.contains("\"");
    if (containsComma) 
    {
        // have to add quote
        if (containsQuote)
        {
            // use "" if there is ", and retruncate it.
            truncatedString = truncatedString.replace("\"", "\"\"").take(maxLen - 5);
        }

        return "\"" + truncatedString + "\"";
        
    }
    // normal case
    return truncatedString;
}

/*
    Parse the json messages and get the info we needed.
    return an array of maps, each of the map is contains properties of one item need be map to
*/

def Object getMappedObjects(message)
{

	def body = message.getBody(java.lang.String.class);
	def selectedBody = new JsonSlurper().parseText(body);
	def result = [];

	def keyMapping = getMapping(message);

	if (selectedBody && selectedBody.messages)
	{
		/*class groovy.json.internal.LazyMap for selectedBody.messages,
		    returns [msg1(map), msg2(map), msg3(map) ] or msg if there is only one */
		def messages = selectedBody.messages.get("message");

		for (def singleMessage in messages)
		{

			// get the body of message, should be an array list of maps or mapEntry
			def payload; propertyMap = new HashMap();

			if (singleMessage instanceof java.util.Map)
			{
				if (singleMessage.containsKey("root"))
				{
					payload = singleMessage.get("root");
				}
			} 
			else
			{
				if ("root".equals(singleMessage.getKey()))
				{
					payload = singleMessage.getValue();
				} else
				{
					// let's check next mapEntry
					continue;
				}
			}


			for (entry in payload)
			{
				def key = entry.getKey();
				if (keyMapping.containsKey(key))
				{
					propertyMap.put(key, entry.getValue());
				}
			}
			result.add(propertyMap);
		}
	}
	return result;
}

/*
    Generate headder info via configurations
*/

def String generateCIFHeader(Message message, int itemcount)
{
	def loadMode = "FULL".equals(message.getProperty("loadMode")) ? "F" : "I";
	def currency = message.getProperty("currency"), itemCount = itemcount.toString(), timestamp = new Date();

	def header = "CIF_I_V3.0\n" + "CHARSET:UTF-8\n" + "LOADMODE:" + loadMode + "\n" + "CODEFORMAT:UNSPSC\n" + "CURRENCY:" + currency + "\n" + "SUPPLIERID_DOMAIN:networkid\n" + "ITEMCOUNT:" + itemCount + "\n" + "TIMESTAMP:" + timestamp + "\n" + "UNUOM:TRUE\n" + "COMMENTS:Uploaded By SCI.\n";
	return header;
}
