import ballerinax/twilio;
import ballerinax/googleapis_gmail;
import ballerina/config;
import ballerina/log;
import ballerina/http;

service on new http:Listener(8090) {
    resource function post orders(http:Caller caller, http:Request req) {

        json orderPayload = checkpanic req.getJsonPayload();
        var orders = checkpanic orderPayload?.orders;
        var contactNo = checkpanic orderPayload?.contactNo;
        var email = checkpanic orderPayload?.email;
        var price = checkpanic orderPayload?.price;
        var inventoryURL = "https://inventoryservice-url.choreoapps.dev/inventory";

        http:Client inventoryEndpoint = new (inventoryURL);
        http:Response inventoryResponse = <http:Response>checkpanic inventoryEndpoint->put("/", orders);
        var jsonPayload = checkpanic inventoryResponse.getJsonPayload();

        log:print(jsonPayload.toJsonString());

        twilio:Client twilioEndpoint = new ({
            accountSId: "twilio-account-id",
            authToken: "twilio-auth-token",
            xAuthyKey: ""
        });
        var sendSmsResponse = checkpanic twilioEndpoint->sendSms("+19388882510", contactNo.toString(), 
        "Your order is successfull");

        googleapis_gmail:Client googleapis_gmailEndpoint = new ({oauthClientConfig: {
                accessToken: config:getAsString("ACCESS_TOKEN_replace_with_yours"),
                refreshConfig: {
                    clientId: config:getAsString("CLIENT_ID_replace_with_yours"),
                    clientSecret: config:getAsString("CLIENT_SECRET_replace_with_yours"),
                    refreshUrl: config:getAsString("TOKEN_ENDPOINT_replace_with_yours"),
                    refreshToken: config:getAsString("REFRESH_TOKEN_replace_with_yours")
                }
            }});
        
        var sendMessageResponse = checkpanic googleapis_gmailEndpoint->sendMessage("nuwan8612@gmail.com", {
            recipient: "nuwan8612@gmail.com",
            subject: "Successfully received order",
            messageBody: "Payment of " + price.toString() + " received.",
            contentType: "text/plain",
            sender: "nuwan8612@gmail.com",
            inlineImagePaths: [],
            attachmentPaths: []
        });
        
        checkpanic caller->respond("Order is Successful!"); 
        
    }
}
