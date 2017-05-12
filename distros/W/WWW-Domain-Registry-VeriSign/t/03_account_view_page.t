use Test::More tests => 1;

use WWW::Domain::Registry::VeriSign;
use Data::Dumper;

my $reg = WWW::Domain::Registry::VeriSign->new;
my $res = $reg->parse_account_view_page(<<'EOD');





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
        <span class="breadcrumtitle">User&nbsp;user-admin&nbsp;is currently logged in.</span>

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
    ['Home', 'home_page.do?MENU=Home&contextid=449']

/* --- menu Accounts READ-WRITE--- */
var MENU_ACCOUNTS_RW =
    ['Accounts', null,
            ['Create New Sub-Account', 'account_new_wizard_page.do?MENU=Accounts&contextid=449'],
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=449'],            
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=449'],
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=449'],
]

/* --- menu Accounts READ-ONLY--- */
var MENU_ACCOUNTS_RO =
    ['Accounts', null,
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=449'],            
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=449'],
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=449'],
]

/* --- menu Accounts READ-WRITE--- */
var MENU_ACCOUNTS_CHILD_RW =
    ['Accounts', null,
            ['Create New Sub-Account', 'account_new_wizard_page.do?MENU=Accounts&contextid=449'],
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=449'],
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=449'],
]

/* --- menu Accounts READ-ONLY--- */
var MENU_ACCOUNTS_CHILD_RO =
    ['Accounts', null,
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=449'],
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=449'],
]

/* --- menu Accounts READ-ONLY VIEW--- */
var MENU_ACCOUNTS_RO_VIEW =
    ['Accounts', null,
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=449'],
]


/* --- menu Products --- */
var MENU_PRODUCTS =
    ['Manage Products', 'product_manage_page.do?MENU=Manage Products&contextid=449']


/* --- menu Users READ-WRITE--- */
var MENU_USERS_RW =
    ['Users', null,
            ['Create New User', 'user_new_page.do?MENU=Users&contextid=449'],
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=449'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=449'],            
]


/* --- menu Users Including Locked users READ-WRITE--- */
var MENU_USERS_INCLUDE_LOCKED_RW =
    ['Users', null,
            ['Create New User', 'user_new_page.do?MENU=Users&contextid=449'],
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=449'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=449'],
            ['List Locked Users', 'user_locked_list_page.do?MENU=Users&contextid=449'],
]


/* --- menu Users READ-ONLY--- */
var MENU_USERS_RO =
    ['Users', null,
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=449'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=449'],
]


/* --- menu Contacts READ-WRITE--- */
var MENU_CONTACTS_RW =
    ['Contacts', null,
            ['Create New Contact', 'contact_new_page.do?MENU=Contacts&contextid=449'],
            ['List Contacts', 'contact_list_page.do?MENU=Contacts&contextid=449'],
]

/* --- menu Contacts READ-ONLY--- */
var MENU_CONTACTS_RO =
    ['Contacts', null,
            ['List Contacts', 'contact_list_page.do?MENU=Contacts&contextid=449'],
]

/* --- menu Product Catalog READ-WRITE --- */
var MENU_PRODUCT_CATALOG_RW =
    ['Product Catalog', null,
            ['Create New Product', 'product_new_page.do?MENU=Product%20Catalog&contextid=449'],
            ['List Products', 'product_list_page.do?MENU=Product%20Catalog&contextid=449'],
]

/* --- menu Product Catalog READ-ONLY--- */
var MENU_PRODUCT_CATALOG_RO =
    ['Product Catalog', null,
            ['List Products', 'product_list_page.do?MENU=Product%20Catalog&contextid=449'],
]

/* --- menu Subscriptions READ-WRITE --- */
var MENU_SUBSCRIPTIONS_RW =
    ['Subscriptions', null,
            ['Add New Subscription', 'subscription_new_page.do?MENU=Subscriptions&contextid=449'],
            ['List Subscriptions', 'subscription_list_page.do?MENU=Subscriptions&contextid=449'],
]

/* --- menu Subscriptions READ-ONLY--- */
var MENU_SUBSCRIPTIONS_RO =
    ['Subscriptions', null,
            ['List Subscriptions', 'subscription_list_page.do?MENU=Subscriptions&contextid=449'],
]

/* --- menu Credit Info --- */
var MENU_FINANCE =
    ['Finance', null,
            ['View Balance Information', 'credit_balance_view_page.do?MENU=Finance&contextid=449'],
            ['View Credit Information', 'credit_limit_view_page.do?MENU=Finance&contextid=449'],
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
    new menu (MY_MENU, MENU_POS1, MENU_STYLES1, 'Accounts');

    //-->
</script>

<div class="headersessioninfo">
    <span class="breadcrumtitle">Current Session:&nbsp;&nbsp;Shortname:</span>USER&nbsp;&nbsp;&nbsp;<span class="breadcrumtitle">Fullname:</span>example Co.,Ltd.
    
    <BR><span class="breadcrumtitle">Path:</span> <a href="context_change.do?MENU=Home&accountid=449&fMode=0&contextid=449" target="_top" class="breadcrum">USER</a>
</div>

<BR><BR><BR><BR><BR><BR><BR><BR>

    















<div class="main">      

                                        <div class="secondarynav">
                                                <div class="secondarynavline"> </div>
                                                
                                                <div class="secondarynavbttn"><a href="/ncc/account_modify_page.do?contextid=449" target="_top" class="secondarynav">Edit this Account</a></div>
                                        </div>


    <div class="content">
        <h4 class="pagetitle">Account Information:</h4>

        <h5 class="pagetitle">Account Name Information:</h5>
        <table class="2" cellspacing="0" cellpadding="0" border="0">
            <tr>
                <td class="alt3">Short Name:</td>
                <td class="alt4">USER</td>
            </tr>
            <tr>

                <td class="alt3" width="160">Full Name:</td>
                <td class="alt4" width="300">example Co.,Ltd.</td>
            </tr>
            <tr>
                <td class="alt3">Account Type:</td>
                <td class="alt4">DIRECT CUSTOMER</td>
            </tr>

            <tr>
                <td class="alt3">Status:</td>
        
                <td class="alt4">ACTIVE</td>
        
            </tr>
            <tr>
                <td class="alt3">Reason:</td>
                <td class="alt4">&nbsp;</td>

            </tr>
            <tr>
                <td class="alt3">Security Phrase:</td>
                <td class="alt4">Security Phrase</td>
            </tr>
            <tr>
                <td class="alt3">Doing Business As:</td>

                <td class="alt4">&nbsp</td>
            </tr>
            <tr>
                <td class="alt3">WhoIs Server URL:</td>
                <td class="alt4">whois.example.com</td>
            </tr>
            <tr>
                <td class="alt3bottom">Company URL:</td>

                <td class="alt4bottom">www.example.com</td>
            </tr>
            
        </table>

        <BR>
        <h5 class="pagetitle">Account Identification:</h5>
        <table class="2" cellspacing="0" cellpadding="0" border="0">
            
            <tr>

                <td class="alt3">Client Account ID:</td>
                <td class="alt4">&nbsp</td>
            </tr>           
            <tr>
                <td class="alt3bottom">GURID:</td>
                <td class="alt4bottom">222</td>
            </tr>
           
        </table>

        
        
                <BR>
                <h5 class="pagetitle">Account SSL Common Names:</h5>
                <table class="2" cellspacing="0" cellpadding="0" border="0">
                        <tr>
                                <td class="alt3bottom" >SSL Common Names:</td>
                                <td class="alt4bottom" >&nbsp;ssl0.example.com<BR>&nbsp;ssl.example.com<BR>
                                        &nbsp;

                                </td>
                        </tr>
           
                </table>
                
                <BR>
                <h5 class="pagetitle">Account IP Ranges:</h5>
                <table class="2" cellspacing="0" cellpadding="0" border="0">
                        <tr>
                                <td class="alt3bottom">IP Ranges:</td>

                                <td class="alt4bottom" >
                                        &nbsp;192.2.0.0/26<BR>
                                        &nbsp;
                                </td>
                        </tr>
           
                </table>
        
        

        <BR>
        <h5 class="pagetitle">Account Contact Information:</h5>

        <table class="2" cellspacing="0" cellpadding="0" border="0">
            <tr>
                <td class="alt3">Address Line 1:</td>
                <td class="alt4">Example Bldg.</td>
            </tr>
            <tr>
                <td class="alt3" width="160">Address Line 2:</td>

                <td class="alt4" width="300">55-11-22</td>
            </tr>
            <tr>
                <td class="alt3">Address Line 3:</td>
                <td class="alt4">Shinjuku</td>
            </tr>
            <tr>

                <td class="alt3">City:</td>
                <td class="alt4">Shinjuku-ku</td>
            </tr>
            <tr>
                <td class="alt3">State:</td>
                <td class="alt4">Tokyo</td>
            </tr>

            <tr>
                <td class="alt3">Postal Code:</td>
                  <td class="alt4">160-0001</td>
            </tr>
            <tr>
                <td class="alt3">Country:</td>
                <td class="alt4">JAPAN</td>

            </tr>
            <tr>
                <td class="alt3">Phone Number:</td>
                <td class="alt4">81 3 5555 2000</td>
            </tr>
            <tr>
                <td class="alt3">Alternate Phone Number:</td>

                <td class="alt4">81 3 5555 2004</td>
            </tr>
            <tr>
                <td class="alt3bottom">Fax Number:</td>
                <td class="alt4bottom">81 3 5555 2008</td>
            </tr>
        </table>

        <BR>
        <h5 class="pagetitle">Notifications:</h5>
        <table class="2" cellspacing="0" cellpadding="0" border="0">
                <tr>
                <td class="alt3">Notification Method:</td>
                <td class="alt4">
                                
                                        Email
                                
                </td>

            </tr>
            <tr>
                <td class="alt3" title="System-generated transfer and restore emails are sent to this address.">Admin Email:</td>
                <td class="alt4">registry@domain.example.com</td>
            </tr>
            <tr>
                <td class="alt3" width="160" title="This email address will be used for any technical notifications.">Technical Email:</td>

                <td class="alt4" width="300">registry@domain.example.com</td>
            </tr>
            <tr>
                <td class="alt3bottom" title="System-generated low balance messages will be sent to this address.">Finance Email:</td>
                <td class="alt4bottom">registry@domain.example.com</td>
            </tr>
        </table>

        <BR>
        <h5 class="pagetitle">Miscellaneous:</h5>
        <table class="2" cellspacing="0" cellpadding="0" border="0">
            <tr>
                <td class="alt3">Created By:</td>
                <td class="alt4">migrationuser</td>
            </tr>

            <tr>
                <td class="alt3" width="160">Creation Date:</td>
                <td class="alt4" width="300">2003-01-02 12:34:56</td>
            </tr>
            <tr>
                <td class="alt3">Last Updated By:</td>
                <td class="alt4">user-admin</td>

            </tr>
            <tr>
                <td class="alt3bottom">Last Updated Date:</td>
                <td class="alt4bottom">2007-03-03 03:04:05</td>
            </tr>
        </table>
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

is($res->{'whois server url'}, 'whois.example.com', 'account_view_page');
1
