import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
import groovy.json.JsonSlurper;

Message processData(Message message) {
    
    def body = message.getBody(java.lang.String.class);
	def responseXML = new JsonSlurper().parseText(body);
	def messageLog = messageLogFactory.getMessageLog(message);

	def code = responseXML.get("cXML").get("Response").get("Status").get("@code");
	messageLog.addAttachmentAsString("code from Ariba is " + code, body, "text/plain");

    message.setProperty("responseInXML",  code.toString());

    return message;
}

