use Test::More tests => 1;

use WWW::Domain::Registry::VeriSign;
use Data::Dumper;

my $reg = WWW::Domain::Registry::VeriSign->new;
my $res = $reg->parse_login(<<'EOD');





<html lang="ja">
<head>
        <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
        <META HTTP-EQUIV="Expires" CONTENT="Mon, 22 Jul 2002 11:12:01 GMT">
        <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE"> 
    <title>Welcome to Namestore Customer Console</title>

     <base href="https://nsmanager.verisign-grs.com:443/ncc/">
</head>

<body bgcolor="#FFFFFF" >
    






<script language="JavaScript" src="tiles/common/browserdetect.js"></script>
<script language="JavaScript" src="tiles/common/calendar.js"></script>

<style>

</style>





<!-- This STARTS the GLOBAL NAV BAR  -->


<div class="headerlogo">
        <img src="images/logo.gif" alt="VeriSign NCC Manager Logo" title="VeriSign NCC Manager Logo" border="0"/>
</div>

<div class="headerlogon">
        <span class="breadcrumtitle">User&nbsp;registrar-id&nbsp;is currently logged in.</span>

</div>

<div class="headerlinks">       
        <a href="logged_user_modify_page.do?MENU=Homes&userid=4449" target="_top">View My Profile</a>&nbsp;&nbsp;&nbsp; | &nbsp;&nbsp;&nbsp;<a href="javascript: newWindow = openWindow(0, 'https://nsmanager.verisign-grs.com:443/nccPlugin', null, null); newWindow.focus()">Help</a>&nbsp;&nbsp;&nbsp; | &nbsp;&nbsp;&nbsp;<a href="logout.do" target="_top">Log Off</a>
</div>

<div class="headermenubackground">
        <img src="images/bk.gif" alt="background" title="" WIDTH="1000" height="25" border="0"/>
</div>


<script language="JavaScript" src="tiles/common/menu.js"></script>



<script language="JavaScript">
<!--//
/* --- menu Home --- */
var MENU_HOME =
    ['Home', 'home_page.do?MENU=Home&contextid=123']

/* --- menu Accounts READ-WRITE--- */
var MENU_ACCOUNTS_RW =
    ['Accounts', null,
            ['Create New Sub-Account', 'account_new_wizard_page.do?MENU=Accounts&contextid=123'],
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=123'],            
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=123'],
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=123'],
]

/* --- menu Accounts READ-ONLY--- */
var MENU_ACCOUNTS_RO =
    ['Accounts', null,
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=123'],            
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=123'],
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=123'],
]

/* --- menu Accounts READ-WRITE--- */
var MENU_ACCOUNTS_CHILD_RW =
    ['Accounts', null,
            ['Create New Sub-Account', 'account_new_wizard_page.do?MENU=Accounts&contextid=123'],
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=123'],
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=123'],
]

/* --- menu Accounts READ-ONLY--- */
var MENU_ACCOUNTS_CHILD_RO =
    ['Accounts', null,
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=123'],
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=123'],
]

/* --- menu Accounts READ-ONLY VIEW--- */
var MENU_ACCOUNTS_RO_VIEW =
    ['Accounts', null,
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=123'],
]


/* --- menu Products --- */
var MENU_PRODUCTS =
    ['Manage Products', 'product_manage_page.do?MENU=Manage Products&contextid=123']


/* --- menu Users READ-WRITE--- */
var MENU_USERS_RW =
    ['Users', null,
            ['Create New User', 'user_new_page.do?MENU=Users&contextid=123'],
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=123'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=123'],            
]


/* --- menu Users Including Locked users READ-WRITE--- */
var MENU_USERS_INCLUDE_LOCKED_RW =
    ['Users', null,
            ['Create New User', 'user_new_page.do?MENU=Users&contextid=123'],
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=123'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=123'],
            ['List Locked Users', 'user_locked_list_page.do?MENU=Users&contextid=123'],
]


/* --- menu Users READ-ONLY--- */
var MENU_USERS_RO =
    ['Users', null,
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=123'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=123'],
]


/* --- menu Contacts READ-WRITE--- */
var MENU_CONTACTS_RW =
    ['Contacts', null,
            ['Create New Contact', 'contact_new_page.do?MENU=Contacts&contextid=123'],
            ['List Contacts', 'contact_list_page.do?MENU=Contacts&contextid=123'],
]

/* --- menu Contacts READ-ONLY--- */
var MENU_CONTACTS_RO =
    ['Contacts', null,
            ['List Contacts', 'contact_list_page.do?MENU=Contacts&contextid=123'],
]

/* --- menu Product Catalog READ-WRITE --- */
var MENU_PRODUCT_CATALOG_RW =
    ['Product Catalog', null,
            ['Create New Product', 'product_new_page.do?MENU=Product%20Catalog&contextid=123'],
            ['List Products', 'product_list_page.do?MENU=Product%20Catalog&contextid=123'],
]

/* --- menu Product Catalog READ-ONLY--- */
var MENU_PRODUCT_CATALOG_RO =
    ['Product Catalog', null,
            ['List Products', 'product_list_page.do?MENU=Product%20Catalog&contextid=123'],
]

/* --- menu Subscriptions READ-WRITE --- */
var MENU_SUBSCRIPTIONS_RW =
    ['Subscriptions', null,
            ['Add New Subscription', 'subscription_new_page.do?MENU=Subscriptions&contextid=123'],
            ['List Subscriptions', 'subscription_list_page.do?MENU=Subscriptions&contextid=123'],
]

/* --- menu Subscriptions READ-ONLY--- */
var MENU_SUBSCRIPTIONS_RO =
    ['Subscriptions', null,
            ['List Subscriptions', 'subscription_list_page.do?MENU=Subscriptions&contextid=123'],
]

/* --- menu Credit Info --- */
var MENU_FINANCE =
    ['Finance', null,
            ['View Balance Information', 'credit_balance_view_page.do?MENU=Finance&contextid=123'],
            ['View Credit Information', 'credit_limit_view_page.do?MENU=Finance&contextid=123'],
]
 //-->
</script>
<script language="JavaScript" src="tiles/common/menu_tpl1.js"></script>
<script language="JavaScript" src="tiles/common/utils.js"></script>

<!-- This STARTS the Header NAV BAR  -->
<script language="JavaScript">
    <!--//
    // Note where menu initialization block is located in HTML document.
    // Don't try to position menu locating menu initialization block in
    // some table cell or other HTML element. Always put it before </body>

    // each menu gets three parameters (see demo files)
    // 1. items structure
    // 2. geometry structure
    // 3. dynamic styles structure

    //new menu (MENU_ITEMS, MENU_POS1, MENU_STYLES1);
    //var MY_MENU = [MENU_HOME, MENU_PRODUCTS, MENU_ACCOUNTS, MENU_USERS, MENU_CONTACTS, MENU_PRODUCT_CATALOG, MENU_SUBSCRIPTIONS, MENU_FINANCE];
    var MY_MENU = [MENU_HOME, MENU_PRODUCTS, MENU_ACCOUNTS_RO_VIEW, MENU_USERS_INCLUDE_LOCKED_RW, MENU_CONTACTS_RW, MENU_SUBSCRIPTIONS_RO, MENU_FINANCE];
    new menu (MY_MENU, MENU_POS1, MENU_STYLES1, 'Home');

    //-->
</script>

<div class="headersessioninfo">
    <span class="breadcrumtitle">Current Session:&nbsp;&nbsp;Shortname:</span>REGISTRAR&nbsp;&nbsp;&nbsp;<span class="breadcrumtitle">Fullname:</span>example Co.,Ltd.
    
    <BR><span class="breadcrumtitle">Path:</span> <a href="context_change.do?MENU=Home&accountid=123&fMode=0&contextid=123" target="_top" class="breadcrum">REGISTRAR</a>
</div>

<BR><BR><BR><BR><BR><BR><BR><BR>

    <div class="main">

    <div class="content">
        <BR>
        <strong>Welcome! You have successfully logged in to the NameStore Customer Console Management Tool</strong>.

        <BR><BR>
        Below is a description of the various commands and functionality available in this tool.
        <BR>If you have any questions please contact Customer Support at <a href="mailto:info@verisign-grs.com">info@verisign-grs.com</a>.

        <BR><BR>
        If you have the ability to manage subaccounts, then the <span class="home"><b>Accounts</b></span> menu option will be displayed on the top of the page.
        <ul>

            <li>To add a subaccount, select <span class="home">Create New Sub-Account</span>.</li>
            <li>To find an account, select <span class="home">Search for a Sub-Account</span>.  Then select an account from the list returned.</li>
            <li>To view account details, select <span class="home">View Account Information</span>.  Then to edit the account information, select edit.</li>
            <li>To list subaccounts, select <span class="home">List Sub-Accounts</span>.</li>

        </ul>

        If you select a subaccount, then the "account context" will be displayed with the shortname and fullname of the account that you selected.
        <BR>Then you may manage the users, contacts, or products of that account or you may select a subaccount to manage.

        <BR><BR>
        If you have the ability to manage your users, then the <span class="home"><b>Users</b></span> menu option will be displayed on the top of the page.
        <ul>
            <li>To find a user, select <span class="home">Search for a User</span>.</li>

            <li>To add a new user, select <span class="home">Create New User</span>.</li>
            <li>To view a list of users, select <span class="home">List Users</span>.  Then select a user from the list returned and you will also have an option to edit the user information.</li>
            <li>To list locked users, select <span class="home">List Locked Users</span>.</li>
        </ul>

        If you have the ability to manage your contacts, then the <span class="home"><b>Contacts</b></span> menu option will be displayed on the top of the page.
        <ul>
            <li>To add a new contact, select <span class="home">Create New Contact</span>.</li>
            <li>To view a list of contacts, select <span class="home">List Contacts</span>.  Then select a contact from the list returned and you will also have the option to edit the contact.</li>

        </ul>

        If you have the ability to manage products, then the <span class="home"><b>Manage Products</b></span> menu option will be displayed on the top of the page.

        <BR><BR>
        If you have the ability to manage subscriptions, then the <span class="home"><b>Subscriptions</b></span> menu option will be displayed on the top of the page.
        <ul>
            <li>To add products for this account, select <span class="home">Add New Subscription</span>.</li>

            <li>To list products for this account, select <span class="home">List Subscriptions</span>.</li>
        </ul>

        If you have the ability to manage the product catalog, then the <span class="home"><b>Product Catalog</b></span> menu option will be displayed on the top of the page.
        <ul>
            <li>To add a new product, select <span class="home">Create New Product</span>.</li>

            <li>To view a list of products, select <span class="home">List Products</span>.</li>
        </ul>

        If you have the ability to manage credit information, then the <span class="home"><b>Finance</b></span> menu option will be displayed on the top of the page.
        <ul>
            <li>To view balance information, select <span class="home">View Balance Information</span>.</li>

            <li>To view credit information, select <span class="home">View Credit Information</span>.</li>
        </ul>

        All users will have the following options available on all pages.
        <ul>
            <li>To view your user information or change your password, select <span class="home">View My Profile</span>.</li>
            <li>For online help, select <span class="home">Help</span>.</li>

            <li>To logoff of the NCC tool, select <span class="home">Logoff</span>.</li>
        </ul>

    </div>
</div>
</body>
<head>
        <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
        <META HTTP-EQUIV="Expires" CONTENT="Mon, 22 Jul 2002 11:12:01 GMT">

        <META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">  
</head>
</html>
EOD
;
is($res, '1', 'login');
1
