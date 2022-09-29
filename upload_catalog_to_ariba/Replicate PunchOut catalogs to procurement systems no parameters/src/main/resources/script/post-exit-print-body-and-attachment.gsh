/* Refer the link below to learn more about the use cases of script.
https://help.sap.com/viewer/368c481cd6954bdfa5d0435479fd4eaf/Cloud/en-US/148851bf8192412cba1f9d2c17f4bd25.html

If you want to know more about the SCRIPT APIs, refer the link below
https://help.sap.com/doc/a56f52e1a58e4e2bac7f7adbf45b2e26/Cloud/en-US/index.html */
import com.sap.gateway.ip.core.customdev.util.Message;
import java.util.HashMap;
import javax.activation.DataHandler;
import java.io.ByteArrayOutputStream;

def Message processData(Message message)
{
	def body = message.getBody(java.lang.String) as String;
	def messageLog = messageLogFactory.getMessageLog(message);
	if (messageLog != null)
	{
		messageLog.setStringProperty("Logging#1", "Printing Payload As Attachment")

		messageLog.addAttachmentAsString("post-exit body:", body.toString(), "text/plain");
		def attachments = message.getAttachments();
		for (attachment in attachments)
		{
            DataHandler dataHandler = attachment.getValue();
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            dataHandler.writeTo(baos);
            baos.flush();
			messageLog.addAttachmentAsString("post-exit attachment:", baos.toString(), , "text/plain");

		}
	}
	return message;
}