import ballerina/log;
import ballerinax/googleapis_sheets;
import ballerina/config;
import ballerina/http;

service on new http:Listener(8090) {
    resource function put inventory(http:Caller caller, http:Request req) {

        googleapis_sheets:Client googleapis_sheetsEndpoint = new ({oauth2Config: {
                accessToken: config:getAsString("ACCESS_TOKEN_replace_with_yours"),
                refreshConfig: {
                    clientId: config:getAsString("CLIENT_ID_replace_with_yours"),
                    clientSecret: config:getAsString("CLIENT_SECRET_replace_with_yours"),
                    refreshUrl: config:getAsString("TOKEN_ENDPOINT_replace_with_yours"),
                    refreshToken: config:getAsString("REFRESH_TOKEN_replace_with_yours")
                }
            }});

        json inventoryPayload = checkpanic req.getJsonPayload();
        log:print(inventoryPayload.toJsonString());
        var itemsToUpdate = <json[]>inventoryPayload?.items;
        log:print(itemsToUpdate.toJsonString());

        var openSpreadsheetByIdResponse = checkpanic googleapis_sheetsEndpoint->openSpreadsheetById(
        "1-XjYrDOZyXl-BsVgcNH19g8MMfe8rya8i3swSUkKU1U");

        googleapis_sheets:Sheet sheet = checkpanic openSpreadsheetByIdResponse.getSheetByName("sheet1");
        var itemIDs = checkpanic sheet->getColumn("A");
        string[] respondMessages = [];

        log:print(itemIDs.toJsonString());

        foreach var itemToUpdate in itemsToUpdate {
            string itemIDString = <string>itemToUpdate?.itemID;
            int quantity = <int>itemToUpdate?.quantity;
            int i = 1;
            int index = -1;
            foreach var itemID in itemIDs {
                string inventoryItemId = <string>itemID;
                if (itemIDString == inventoryItemId) {
                    index = i;
                    break;
                } else {

                }
                i = i + 1;
            }
            if (index > 0) {
                string cellName = "C" + index.toString();
                var cellValue = checkpanic sheet->getCell(cellName);
                log:print(cellValue.toJsonString());
                int intCellValue = checkpanic 'int:fromString(cellValue.toJsonString());
                if (intCellValue > quantity) {
                    int newStockValue = intCellValue - quantity;
                    checkpanic sheet->setCell(cellName, newStockValue);
                    var createSpreadsheetResponse = checkpanic googleapis_sheetsEndpoint->createSpreadsheet("");
                    respondMessages.push("Sucessfully updated the item: " + itemIDString);
                } else {
                    respondMessages.push("Stock is not enough for the Item: " + itemIDString);
                }
            } else {
                respondMessages.push("Cannot find the item: " + itemIDString);
            }
        }

        checkpanic caller->respond(respondMessages);

    }
}
