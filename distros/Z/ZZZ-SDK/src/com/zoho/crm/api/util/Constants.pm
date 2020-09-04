package Constants;
use Moose;

our $REQUEST_METHOD_GET = "GET";

our $REQUEST_METHOD_POST = "POST";

our $REQUEST_METHOD_PUT = "PUT";

our $REQUEST_METHOD_DELETE = "DELETE";

our $REQUEST_CATEGORY_READ = "READ";

our $REQUEST_CATEGORY_CREATE = "CREATE";

our $REQUEST_CATEGORY_UPDATE = "UPDATE";

our $OAUTH_HEADER_PREFIX = "Zoho-oauthtoken ";

our $AUTHORIZATION = "Authorization";

our $GRANT_TYPE = "grant_type";

our $GRANT_TYPE_AUTH_CODE = "authorization_code";

our $ACCESS_TOKEN = "access_token";

our $EXPIRES_IN = "expires_in";

our $EXPIRES_IN_SEC = "expires_in_sec";

our $REFRESH_TOKEN = "refresh_token";

our $CLIENT_ID = "client_id";

our $CLIENT_SECRET = "client_secret";

our $REDIRECT_URI = "redirect_uri";

our $CODE = "code";

our $SDK_VERSION = "0.0.1";

our $ZOHO_SDK = "X-ZOHO-SDK";

our $FIELD = "field";

our $USER = "user";

our $ENVIRONMENT = "envionment";

our $EXPECTED_TYPE = "expected-type";

our $CLASS = "class";

our $INDEX = "index";

our $ACCEPTED_TYPE = "accepted_type";

our $TYPE = "type";

our $VALUES = "values";

our $KEYS = "keys";

our $NAME = "name";

our $STRUCTURE_NAME = "structure_name";

our $UNIQUE = "unique";

our $READ_ONLY = "read-only";

our $MIN_LENGTH = "min-length";

our $MAX_LENGTH = "max-length";

our $REQUIRED = "required";

our $REGEX = "regex";

our $CLASSES = "classes";

our $TYPE_ERROR = "TYPE_ERROR";

our $CONTENT_TYPE = "Content-Type";

our $INTERFACE = "interface";

our $STRING = "string";

our $INTEGER = "integer";

our $FLOAT = "float";

our $BOOLEAN = "Boolean";

our $STRING_NAMESPACE = "String";

our $DOUBLE_NAMESPACE = "Double";

our $INTEGER_NAMESPACE = "Integer";

our $LONG_NAMESPACE = "Long";

our $FILE_NAMESPACE = "com.zoho.crm.api.util.StreamWrapper";

our $DATE_NAMESPACE = "Date";

our $DATETIME_NAMESPACE = "DateTime";

our $RECORD_NAMESPACE = "com.zoho.crm.api.record.Record";

our $USER_NAMESPACE = "com.zoho.crm.api.users.User";

our $CHOICE_NAMESPACE = "com.zoho.crm.api.util.Choice";

our $MODULE_NAMESPACE = "com.zoho.crm.api.modules.Module";

our $FIELD_FILE_NAMESPACE = "com.zoho.crm.api.record.FileDetails";

our $REMINDAT_NAMESPACE = "com.zoho.crm.api.record.RemindAt";

our $INVENTORY_LINE_ITEMS = "com.zoho.crm.api.record.InventoryLineItems";

our $PRICINGDETAILS = "com.zoho.crm.api.record.PricingDetails";

our $LAYOUT_NAMESPACE = "com.zoho.crm.api.layouts.Layout";

our $LINETAX = "com.zoho.crm.api.record.LineTax";

our $PARTICIPANTS = "com.zoho.crm.api.record.Participants";

our $COMMENT_NAMESPACE = "com.zoho.crm.api.record.Comment";

our $REMINDER_NAMESPACE = "com.zoho.crm.api.record.Reminder";

our $RECURRING_ACTIVITY_NAMESPACE = "com.zoho.crm.api.record.RecurringActivity";

our $PRODUCT_DETAILS = "Product_Details";

our $PRICING_DETAILS = "Pricing_Details";

our $PRICE_BOOKS = "price_books";

our $PARTICIPANT_API_NAME = "Participants";

our $EVENTS = "events";

our $SOLUTIONS = "solutions";

our $CASES = "cases";

our $ACTIVITIES = "activities";

our $COMMENTS = "Comments";

our $LAYOUT = "Layout";

our $SUBFORM = "subform";

our $LOOKUP = "lookup";

our $SE_MODULE = "se_module";

our $LINE_TAX = "\$line_tax";

our @INVENTORY_MODULES = ("invoices", "sales_orders","purchase_orders","quotes");

our @KEYSTOSKIP = ("Created_Time", "Modified_Time", "Created_By", "Modified_By", "Tag");

our @SET_TO_CONTENT_TYPE = ("/crm/bulk/v2/read", "/crm/bulk/v2/write");

our $OAUTH_TOKEN = "OAuthToken";

our $STORE = "store";

our $TOKEN = "token";

our $TOKEN_TYPE = "token_type";

our $REFRESH = "Refresh";

our $GRANT = "Grant";

our $TOKEN_ERROR = "TOKEN ERROR";

our $UNACCEPTED_VALUES_ERROR = "UNACCEPTED_VALUES_ERROR";

our $MINIMUM_LENGTH_ERROR = "MINIMUM-LENGTH-ERROR";

our $MAXIMUM_LENGTH_ERROR = "MAXIMUM-LENGTH-ERROR";

our $REGEX_MISMATCH_ERROR = "REGEX_MISMATCH_ERROR";

our $INITIALIZATION_ERROR = "INITIALIZATION ERROR";

our $REQUIRED_FIELD_ERROR = "REQUIRED_FIELD_ERROR";

our $MYSQL_HOST = "localhost";

our $MYSQL_DATABASE_NAME = "zohooauth";

our $MYSQL_USER_NAME = "root";

our $LIST_NAMESPACE = "List";

our $MAP_NAMESPACE = "Map";

our $MODULE = "module";

our $KEY_VALUES = "key_values";

our $IS_MODIFIED_METHOD = "is_key_modified";

our $SET_KEY_MODIFIED_METHOD = "set_key_modified";

our $MANDATORY_VALUE_MISSING_ERROR = "MANDATORY VALUE MISSING ERROR";

our $MANDATORY_KEY_MISSING_ERROR = "Value missing for mandatory key: ";

our $PACKAGE_NAMESPACE = "com.zoho.crm.api";

our $MODULEPACKAGENAME = "modulePackageName";

our $MODULEDETAILS = "moduleDetails";

our $RESOURCE_PATH_ERROR = "EMPTY_RESOURCE_PATH";

our $RESOURCE_PATH_ERROR_MESSAGE = "Resource Path MUST NOT be undef/empty.";

our $LOGFILE_NAME = "SDKLogs.log";

our $JSON_DETAILS_FILE_PATH = "src/JsonDetails.json";

our $INITIALIZATION_SUCCESSFUL = "Initialization successful ";

our $INITIALIZATION_SWITCHED = "Initialization switched ";

our $FOR_EMAIL_ID = "for Email Id : ";

our $IN_ENVIRONMENT = " in Environment : ";

our $FIELD_DETAILS_DIRECTORY = "resources";

our $NO_CONTENT_STATUS_CODE = 204;

our $NOT_MODIFIED_STATUS_CODE = 304;

our $FIELDS_LAST_MODIFIED_TIME = "FIELDS-LAST-MODIFIED-TIME";

our $CALLS = "calls";

our $CALL_DURATION = "call_duration";

our $UNDERSCORE = "_";

our $RELATED_LISTS = "Related_Lists";

our $API_NAME = "api_name";

our $HREF = "href";

our $STATUS = "status";

our $MESSAGE = "message";

our $API_EXCEPTION = "API_EXCEPTION";

our $HTTP = "http";

our $CONTENT_API_URL = "content.zohoapis.com";

our $AUTHENTICATION_EXCEPTION = "Exception in authenticating current request : ";

our $CANT_DISCLOSE = " ## can't disclose ## ";

our $URL = "URL";

our $HEADERS = "HEADERS";

our $PARAMS = "PARAMS";

our $PRIMARY = "primary";

our $MANDATORY_VALUE_NULL_ERROR = "MANDATORY VALUE NULL ERROR";

our $MANDATORY_KEY_NULL_ERROR = "Null Value for mandatory key : ";

our $ATTACHMENT_ID = "attachment_id";

our $FILE_ID = "file_id";

our $DATA_TYPE_ERROR = "DATA TYPE ERROR";

our $FILE_BODY_WRAPPER = 'FileBodyWrapper';

our $STREAM_WRAPPER_CLASS_PATH = "com.zoho.crm.api.util.StreamWrapper";

our %REF_TYPES = ('List' => 'ARRAY', 'HashMap' => 'HASH', 'Map' => 'HASH');

our %SPECIAL_TYPES = ('DateTime' => 'DateTime', 'Date' => 'DateTime');

our %DEFAULT_TYPES = ('String' => 'string', 'Integer' => "int", "Long" => "long", "Double" => "float", "Float" => "float");

our $ARRAY_KEY = "ARRAY";

our $GIVEN_TYPE = "given_type";

our $INVALID_URL_ERROR = "Invalid URL Error";

our $DELETE_FIELD_FILE_ERROR = "Exception in deleting Current User Fields file : ";

our $DELETE_FIELD_FILES_ERROR = "Exception in deleting all Fields files : ";

our $DELETE_MODULE_FROM_FIELDFILE_ERROR = "Exception in deleting module from Fields file : ";

our $GET_TOKEN_ERROR = "Exception in getting access token";

our $INVALID_CLIENT_ERROR = "INVALID CLIENT ERROR";

our $ERROR_KEY = 'error';

our $VERSION = "0.0.1";

=head1 NAME

com::zoho::crm::api::util::Constants - This class uses the SDK constants name reference.

=cut

1;
