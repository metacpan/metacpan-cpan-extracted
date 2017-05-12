#!/does/not/exist/but/fools/vim/perl
# WeSQL application configuration file
# Do not edit unless you know what you are doing!

# This file is part of the Sample Addressbook application
# shipped with WeSQL v0.53
# For more information see http://wesql.org

# You will need to restart the web server after changing
# this file.

@commandlist = ( 
      'dolayouttags($body)',
      'dolanguages($body)',
      'dosubst($body,"PR_",%params)',
      'dosubst($body,"ENV_",%ENV)',
      'dosubst($body,"COOKIE_",%cookies)',
      'doeval($body,"PRE")',
      'doinsert($body)',
      'doeval($body,"POSTINSERT")',
      'doparamcheck($body)',
      'docutcheck($body)',
      'doeval($body,"PRELIST")',
      'dolist($body,$dbh)',
      'doeval($body,"POST")',
      'docutcheck($body)'
      );

# For MySQL:
$dbtype = 0;
$dsn = "DBI:mysql:database=addressbook;host=localhost";

# For PostgreSQL:
#$dbtype = 1;
#$dsn = "DBI:Pg:dbname=addressbook;host=localhost";

$dbuser = "root";
$dbpass = "test";

# Set this to zero to disable authentication. 
# Note that from v0.51, jform.wsql and jdeleteform.wsql WILL work, as sessions are now not dependant
# on logging in anymore (however they are still dependant on cookies being enabled in the client!).
$authenticate = 1;

# $authsuperuserdir MUST start and end with a / !!
# $authsuperuserdir MUST be defined before $noauthurls!
$authsuperuserdir = "/admin/";
# Add urls that need no authentication, separate them with a pipe-symbol, and make sure they start with a forward slash!
# Note that you need not to worry about language extenstions, that is index.wsql will match all index.xx.wsql calls with xx any 2 characters [a-z_A-Z]
$noauthurls = "\/jlogin.wsql|\/jloginform.wsql|\/jlogout.wsql|$authsuperuserdir\Ljlogout.wsql|$authsuperuserdir\Ljloginform.wsql|$authsuperuserdir\Ljlogin.wsql";
# Set $authsuperuser to 1 if you want a superuser directory
$authsuperuser = 1;

$defaultlanguage = 'en';
