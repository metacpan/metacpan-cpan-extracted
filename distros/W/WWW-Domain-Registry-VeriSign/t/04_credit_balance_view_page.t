use Test::More tests => 4;

use WWW::Domain::Registry::VeriSign;
use Data::Dumper;

my $reg = WWW::Domain::Registry::VeriSign->new;
my $res = $reg->parse_credit_balance_view_page(<<'EOD');





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
        <span class="breadcrumtitle">User&nbsp;livin-admin&nbsp;is currently logged in.</span>

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
    ['Home', 'home_page.do?MENU=Home&contextid=222']

/* --- menu Accounts READ-WRITE--- */
var MENU_ACCOUNTS_RW =
    ['Accounts', null,
            ['Create New Sub-Account', 'account_new_wizard_page.do?MENU=Accounts&contextid=222'],
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=222'],            
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=222'],
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=222'],
]

/* --- menu Accounts READ-ONLY--- */
var MENU_ACCOUNTS_RO =
    ['Accounts', null,
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=222'],            
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=222'],
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=222'],
]

/* --- menu Accounts READ-WRITE--- */
var MENU_ACCOUNTS_CHILD_RW =
    ['Accounts', null,
            ['Create New Sub-Account', 'account_new_wizard_page.do?MENU=Accounts&contextid=222'],
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=222'],
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=222'],
]

/* --- menu Accounts READ-ONLY--- */
var MENU_ACCOUNTS_CHILD_RO =
    ['Accounts', null,
            ['Search for a Sub-Account', 'account_query_page.do?MENU=Accounts&contextid=222'],
            ['List Sub-Accounts', 'account_list_page.do?MENU=Accounts&contextid=222'],
]

/* --- menu Accounts READ-ONLY VIEW--- */
var MENU_ACCOUNTS_RO_VIEW =
    ['Accounts', null,
            ['View Account Information', 'account_view_page.do?MENU=Accounts&contextid=222'],
]


/* --- menu Products --- */
var MENU_PRODUCTS =
    ['Manage Products', 'product_manage_page.do?MENU=Manage Products&contextid=222']


/* --- menu Users READ-WRITE--- */
var MENU_USERS_RW =
    ['Users', null,
            ['Create New User', 'user_new_page.do?MENU=Users&contextid=222'],
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=222'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=222'],            
]


/* --- menu Users Including Locked users READ-WRITE--- */
var MENU_USERS_INCLUDE_LOCKED_RW =
    ['Users', null,
            ['Create New User', 'user_new_page.do?MENU=Users&contextid=222'],
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=222'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=222'],
            ['List Locked Users', 'user_locked_list_page.do?MENU=Users&contextid=222'],
]


/* --- menu Users READ-ONLY--- */
var MENU_USERS_RO =
    ['Users', null,
            ['Search for a User', 'user_query_page.do?MENU=Users&contextid=222'],
            ['List Users', 'user_list_page.do?MENU=Users&contextid=222'],
]


/* --- menu Contacts READ-WRITE--- */
var MENU_CONTACTS_RW =
    ['Contacts', null,
            ['Create New Contact', 'contact_new_page.do?MENU=Contacts&contextid=222'],
            ['List Contacts', 'contact_list_page.do?MENU=Contacts&contextid=222'],
]

/* --- menu Contacts READ-ONLY--- */
var MENU_CONTACTS_RO =
    ['Contacts', null,
            ['List Contacts', 'contact_list_page.do?MENU=Contacts&contextid=222'],
]

/* --- menu Product Catalog READ-WRITE --- */
var MENU_PRODUCT_CATALOG_RW =
    ['Product Catalog', null,
            ['Create New Product', 'product_new_page.do?MENU=Product%20Catalog&contextid=222'],
            ['List Products', 'product_list_page.do?MENU=Product%20Catalog&contextid=222'],
]

/* --- menu Product Catalog READ-ONLY--- */
var MENU_PRODUCT_CATALOG_RO =
    ['Product Catalog', null,
            ['List Products', 'product_list_page.do?MENU=Product%20Catalog&contextid=222'],
]

/* --- menu Subscriptions READ-WRITE --- */
var MENU_SUBSCRIPTIONS_RW =
    ['Subscriptions', null,
            ['Add New Subscription', 'subscription_new_page.do?MENU=Subscriptions&contextid=222'],
            ['List Subscriptions', 'subscription_list_page.do?MENU=Subscriptions&contextid=222'],
]

/* --- menu Subscriptions READ-ONLY--- */
var MENU_SUBSCRIPTIONS_RO =
    ['Subscriptions', null,
            ['List Subscriptions', 'subscription_list_page.do?MENU=Subscriptions&contextid=222'],
]

/* --- menu Credit Info --- */
var MENU_FINANCE =
    ['Finance', null,
            ['View Balance Information', 'credit_balance_view_page.do?MENU=Finance&contextid=222'],
            ['View Credit Information', 'credit_limit_view_page.do?MENU=Finance&contextid=222'],
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
    new menu (MY_MENU, MENU_POS1, MENU_STYLES1, 'Finance');

    //-->
</script>

<div class="headersessioninfo">
    <span class="breadcrumtitle">Current Session:&nbsp;&nbsp;Shortname:</span>USER&nbsp;&nbsp;&nbsp;<span class="breadcrumtitle">Fullname:</span>example Co.,Ltd.
    
    <BR><span class="breadcrumtitle">Path:</span> <a href="context_change.do?MENU=Home&accountid=222&fMode=0&contextid=222" target="_top" class="breadcrum">USER</a>
</div>

<BR><BR><BR><BR><BR><BR><BR><BR>

    
















<div class="main">



    <div class="content">
        <h4 class="pagetitle">Balance Information:</h4>
        <table class="2" cellspacing="0" cellpadding="0" border="0">
            <tr>
                <td class="alt3">Credit Limit:</td>
                <td class="alt4">$0</td>

            </tr>
            <tr>
                <td class="alt3">Outstanding Balance:</td>
                <td class="alt4">$-1234</td>
            </tr>
            <tr>
                <td class="alt3" width="160">Available Credit:</td>

                <td class="alt4" width="160">$1234</td>
            </tr>
            <tr>
                <td class="alt3" width="160">Lower Limit:</td>
                <td class="alt4" width="160">$2345.6</td>
            </tr>
            <tr>

                <td class="alt3bottom" width="160">Eligible for Emergency Credit:</td>
                <td class="alt4bottom" width="160"><input type=checkbox disabled="true"  ></td>
            </tr>
        </table>
        <br>
    </div>
</div>


    <!-- LIST ACCOUNT BALANCE  -->

    <br>
    <div class="content2">

        <h4 class="pagetitle">Balance Adjustment(s):</h4>
        The last 30 days of manual adjustments to the balance are displayed below:
        <BR><BR><B>3</B>&nbsp;record(s) found.


        <BR><BR>
        <table class="2" cellspacing="0" cellpadding="0" border="0" width="70%">
            <tr>

                <th class="icon">View</th>
                <th>Adjustment Reason</th>
                <th>&nbsp;&nbsp;&nbsp;&nbsp;Debits</th>
                <th>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Credits</th>
                <th>&nbsp;&nbsp;&nbsp;&nbsp;Transaction Date</th>
            </tr>

            
            <tr>
                <td class="icon"><a href="balance_view_page.do?contextid=222&billingtransactionid=2024027" target="_top"  class="tableicon"><img src="images/view.gif" class="icon" alt="View this item" /></a></td>
                <td class="alt">Payment By Wire</td>
                <td class="alt" align="right">&nbsp;&nbsp;&nbsp;</td>
                <td class="alt" align="right">$10,000.00&nbsp;&nbsp;</td>
                <td class="alt">&nbsp;&nbsp;&nbsp;&nbsp;2007-05-08 11:38:36</td>
            </tr>

            
            <tr>
                <td class="icon2"><a href="balance_view_page.do?contextid=222&billingtransactionid=579886" target="_top"  class="tableicon"><img src="images/view.gif" class="icon" alt="View this item" /></a></td>
                <td class="alt2">Transfer Funds In</td>
                <td class="alt2" align="right">&nbsp;&nbsp;&nbsp;</td>
                <td class="alt2" align="right">$3,800.50&nbsp;&nbsp;</td>
                <td class="alt2">&nbsp;&nbsp;&nbsp;&nbsp;2007-04-28 19:58:14</td>
            </tr>

            
            <tr>
                <td class="icon"><a href="balance_view_page.do?contextid=222&billingtransactionid=16830" target="_top"  class="tableicon"><img src="images/view.gif" class="icon" alt="View this item" /></a></td>
                <td class="alt">Transfer Funds In</td>
                <td class="alt" align="right">&nbsp;&nbsp;&nbsp;</td>
                <td class="alt" align="right">$1,000.00&nbsp;&nbsp;</td>
                <td class="alt">&nbsp;&nbsp;&nbsp;&nbsp;2005-01-19 18:25:54</td>
            </tr>

            
        </table>
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

is($res->{'credit limit'},        '$0',      'credit_balance_view_page');
is($res->{'outstanding balance'}, '$-1234',  'credit_balance_view_page');
is($res->{'available credit'},    '$1234',   'credit_balance_view_page');
is($res->{'lower limit'},         '$2345.6', 'credit_balance_view_page');

1
