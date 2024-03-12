public with sharing class googleSheetsApiController {
    public googleSheetsApiController() {}
    private static final String fileId = '1HfGyrQO8tnVfKHdDik_xgFKVzH1x3sGDtlucTDDUkRY';

    public static List<List<Object>> getAccounts(){
        List<Account> accounts = [SELECT Id, Name, Industry, Type FROM Account]; //query to substitute
        List<List<Object>> data = new List<List<Object>>(); //instance of table
        data.add(new List<Object>{ 'Id', 'Code__c', 'Account.Name', 'DiscoveryCallDate__c', 'ProposalCallDate__c', 'ApprovedDate__c', 'DevelopmentStartDate__c', 'EstimatedDeliveryDay__c', 'DeliveryCallDate__c', 'DeployDate__c', 'WorkManager__r.EstimatedHours__c', 'WorkManager__r.Rate__c', 'WorkManager__r.RatePrice__c', 'WorkManager__r.Price__c', 'WorkManager__r.BillingType__c', 'RecordType.Name', 'Sprint__r.Name', 'Team__r.Name', 'WorkManager__r.TechProposalEmail__c' }); //header added in table

        for(Account acc : accounts){
            data.add(new List<Object>{ acc.Name, acc.Industry, acc.Type }); //data added in table
        }

        return data;
    }

    public static List<List<Object>> getContacts(){
        List<Contact> contactResults = new List<Contact>([SELECT Account.Name, Account.Phone, Name FROM Contact]); //query to substitute
        List<List<Object>> data = new List<List<Object>>(); //instance of table

        data.add(new List<Object>{ 'Name', 'Phone' }); //first header added in table

        for(Contact ctt : contactResults){
            data.add(new List<Object>{ctt.Account.Name, ctt.Account.Phone}); //data added in table
            data.add(new List<Object>{ 'Qtd Contatos' }); //second header added in table
            data.add(new List<Object>{ctt.Name}); //data added in table
            data.add(new List<Object>{ '', '' }); //empty line added in table
        }

        return data;
    }

    public static void insertTableStyleIntoGoogleSheets() {
        List<List<Object>> tableData =  getContacts();
        List<Map<String, Object>> requests = new List<Map<String, Object>>();

        for (Integer i = 1; i < tableData.size(); i++) {
            if (Math.mod(i, 4) == 2) {
                Map<String, Object> repeatCellRequest = new Map<String, Object>{
                    'repeatCell' => new Map<String, Object>{
                        'range' => new Map<String, Object>{
                            'sheetId' => 416085245,
                            'startRowIndex' => i,
                            'endRowIndex' => (i + 1)
                        },
                        'cell' => new Map<String, Object>{
                            'userEnteredFormat' => new Map<String, Object>{
                                'backgroundColor' => new Map<String, Object>{
                                    'red' => 64,
                                    'green' => 64,
                                    'blue' => 64
                                },
                                'horizontalAlignment' => 'CENTER',
                                'textFormat' => new Map<String, Object>{
                                    'bold' => true
                                }
                            }
                        },
                        'fields' => 'userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)'
                    }
                };
                requests.add(repeatCellRequest);
            }
        }

        Map<String, Object> repeatCellRequestHeaderSheet1 = new Map<String, Object>{
            'repeatCell' => new Map<String, Object>{
                'range' => new Map<String, Object>{
                    'sheetId' => 0,
                    'startRowIndex' => 0,
                    'endRowIndex' => 1
                },
                'cell' => new Map<String, Object>{
                    'userEnteredFormat' => new Map<String, Object>{
                        'horizontalAlignment' => 'CENTER',
                        'textFormat' => new Map<String, Object>{
                            'foregroundColor' => new Map<String, Object>{
                                'red' => 0,
                                'green' => 0,
                                'blue' => 0
                            },
                            'bold' => true
                        }
                    }
                },
                'fields' => 'userEnteredFormat(textFormat,horizontalAlignment)'
            }
        };
        requests.add(repeatCellRequestHeaderSheet1);

        Map<String, Object> repeatCellRequestHeaderSheet2 = new Map<String, Object>{
            'repeatCell' => new Map<String, Object>{
                'range' => new Map<String, Object>{
                    'sheetId' => 416085245,
                    'startRowIndex' => 0,
                    'endRowIndex' => 1
                },
                'cell' => new Map<String, Object>{
                    'userEnteredFormat' => new Map<String, Object>{
                        'horizontalAlignment' => 'CENTER',
                        'textFormat' => new Map<String, Object>{
                            'foregroundColor' => new Map<String, Object>{
                                'red' => 0,
                                'green' => 0,
                                'blue' => 0
                            },
                            'bold' => true
                        }
                    }
                },
                'fields' => 'userEnteredFormat(textFormat,horizontalAlignment)'
            }
        };
        requests.add(repeatCellRequestHeaderSheet2);

        Map<String, Object> batchUpdateRequest = new Map<String, Object>{
            'requests' => requests
        };
        
        String batchUpdateRequestJson = JSON.serialize(batchUpdateRequest);

        clearSheetStyle(fileId, 0);
        clearSheetStyle(fileId, 416085245);

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:GoogleSheetN/v4/spreadsheets/' + fileId + ':batchUpdate');

        //req.setHeader('Authorization', 'Bearer -------');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(batchUpdateRequestJson);
    
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Google Sheets API response: ' + res.getBody());
        } else {
            System.debug('API request failed: ' + res.getStatusCode() + ' ' + res.getStatus());
            System.debug('Error response: ' + res.getBody());
        }
    }

    public static void insertTableIntoGoogleSheets() {
        List<Map<String, Object>> data = new List<Map<String, Object>>();
        data.add(new Map<String, Object>{ 'range' => 'Página1', 'majorDimension' => 'ROWS', 'values' => getAccounts() });
        data.add(new Map<String, Object>{ 'range' => 'Página2', 'majorDimension' => 'ROWS', 'values' => getContacts() });
        System.debug(data);

        Map<String, Object> batchUpdateRequest = new Map<String, Object>{
            'valueInputOption' => 'RAW',
            'data' => data
        };

        clearSheet(fileId, 'Página1');
        clearSheet(fileId, 'Página2');
    
        String batchUpdateRequestJson = JSON.serialize(batchUpdateRequest);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GoogleSheetN/v4/spreadsheets/' + fileId + '/batchUpdate');
        req.setMethod('POST');

        req.setEndpoint('callout:GoogleSheetN/v4/spreadsheets/' + fileId + '/values:batchUpdate');

        //req.setHeader('Authorization', 'Bearer -------');        
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(batchUpdateRequestJson);
    
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Google Sheets API response: ' + res.getBody());
        } else {
            System.debug('API request failed: ' + res.getStatusCode() + ' ' + res.getStatus());
            System.debug('Error response: ' + res.getBody());
        }
    }

    public static void clearSheet(String fileId, String sheetName) {
        String baseUrl = 'https://sheets.googleapis.com/v4/spreadsheets/';
        String endpoint = 'callout:GoogleSheetN/v4/spreadsheets/' + fileId + '/values/' + sheetName + ':clear';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        //req.setHeader('Authorization', 'Bearer -------');        req.setHeader('Content-Length', '0');
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Sheet cleared successfully: ' + sheetName);
        } else {
            System.debug('Failed to clear sheet: ' + sheetName);
            System.debug('Error response: ' + res.getBody());
        }
    }

    public static void clearSheetStyle(String fileId, Integer sheetId) {
        String baseUrl = 'https://sheets.googleapis.com/v4/spreadsheets/';
        String endpoint = 'callout:GoogleSheetN/v4/spreadsheets/' + fileId + ':batchUpdate';

        String payload = JSON.serialize(new Map<String, Object>{
            'requests' => new List<Object>{
                new Map<String, Object>{
                    'repeatCell' => new Map<String, Object>{
                        'range' => new Map<String, Object>{
                            'sheetId' => sheetId
                        },
                        'cell' => new Map<String, Object>{
                            'userEnteredFormat' => new Map<String, Object>{
                                'backgroundColor' => null
                            }
                        },
                        'fields' => 'userEnteredFormat.backgroundColor'
                    }
                }
            }
        });

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        //req.setHeader('Authorization', 'Bearer -------');        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Sheet cleared successfully');
        } else {
            System.debug('Failed to clear sheet');
            System.debug('Error response: ' + res.getBody());
        }
    }

    public static void createGoogleSheetFile(){
        insertTableIntoGoogleSheets();
        insertTableStyleIntoGoogleSheets();
    }
}
