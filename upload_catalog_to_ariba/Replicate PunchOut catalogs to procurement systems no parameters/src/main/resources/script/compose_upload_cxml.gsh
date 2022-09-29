/* Refer the link below to learn more about the use cases of script.
https://help.sap.com/viewer/368c481cd6954bdfa5d0435479fd4eaf/Cloud/en-US/148851bf8192412cba1f9d2c17f4bd25.html

If you want to know more about the SCRIPT APIs, refer the link below
https://help.sap.com/doc/a56f52e1a58e4e2bac7f7adbf45b2e26/Cloud/en-US/index.html */
import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;

def Message processData(Message message)
{
	def messageLog = messageLogFactory.getMessageLog(message);
	def result = generateUploadRequestBody(message);

	message.setHeader("Content-Type", "text/xml; charset=UTF-8");
	message.setHeader("Content-ID", "uploadRequest.cxml");
	message.setHeader("Content-Description", "products");
	message.setHeader("Content-Disposition", "attachment;filename=" + "\"uploadRequest.cxml\"");
	messageLog.addAttachmentAsString("uploadRequest.cxml", result.toString(), "text/plain");

	message.setBody(result);
	return message;
}

def generateUploadRequestBody(Message message)
{
	def senderId = message.getProperty("senderId"), senderSecret = message.getProperty("senderSecret"), userAgent = message.getProperty("userAgent"),
		toId = message.getProperty("toId"), fromId = message.getProperty("fromId"), catalogName = message.getProperty("catalogName");
	def payloadId = UUID.randomUUID().toString(), date = new Date();
	
    return "<!DOCTYPE cXML SYSTEM \"http://xml.cxml.org/schemas/cXML/1.2.023/cXML.dtd\">\n" +
			"<cXML timestamp=\"" + date.toString() + "\"\n" +
			"payloadID=\"" + payloadId + "\">" +
			"                                                          \n" +
			"    <Header>\n" +
			"        <From>\n" +
			"            <Credential domain=\"NetworkID\">\n" +
			"                <Identity>" + fromId + "</Identity>\n" +
			"            </Credential>\n" +
			"        </From>\n" +
			"        <To>\n" +
			"            <Credential domain=\"NetworkID\">\n" +
			"                <Identity>" + toId + "</Identity>\n" +
			"            </Credential>\n" +
			"        </To>\n" +
			"        <Sender>\n" +
			"            <Credential domain=\"NetworkID\">\n" +
			"                <Identity>" + senderId + "</Identity>\n" +
			"                <SharedSecret>" + senderSecret + "</SharedSecret>\n" +
			"            </Credential>\n" +
			"            <UserAgent>" + userAgent + "</UserAgent>\n" +
			"        </Sender>\n" +
			"    </Header>\n" +
			"    <Request>\n" +
			"        <CatalogUploadRequest operation=\"" + "update" + "\">\n" +
			"            <CatalogName xml:lang=\"en\">" + catalogName + "</CatalogName>\n" +
			"            <Description xml:lang=\"en\">upload via SCI tenant </Description>\n" +
			"            <Attachment>\n" +
			"                <URL>cid:example_cxml.xml</URL>\n" +
			"            </Attachment>\n" +
			"            <Commodities>\n" +
			"                <CommodityCode>15121502</CommodityCode>\n" +
			"            </Commodities>\n" +
			"            <AutoPublish enabled=\"false\"/>\n" +
			"            <Notification>\n" +
			"                <Email>judy@non-existing.com</Email>\n" +
			"                <URLPost enabled=\"true\"/>\n" +
			"            </Notification>\n" +
			"        </CatalogUploadRequest>\n" +
			"    </Request>\n" +
			"</cXML>";

}