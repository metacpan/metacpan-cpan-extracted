use strict;
use  Test::More;

plan tests => 4;

use constant TMPFILE => "./test_mappoint.ini";

diag("\n".
     "The Mappoint web service requires that you provide a user accout and password\n".
     "This account information is then passed with each request to the\nMappoint servers.\n".
     "If you do not already have a Mappoint account, you can get a trial one here:\n".
     "http://www.microsoft.com/mappoint/net/evaluation/\n".
     "\n");

diag("Please enter your Mappoint user id:");

my $id = <STDIN>;
chomp $id;

diag("Please enter your Mappoint password:");
my $pass = <STDIN>;
chomp $pass;
ok($id,"Got Mappoint user id");
ok($pass,"Got Mappoint password");

open KEY , ">" . TMPFILE;

my $file = -f TMPFILE;

ok($file, "Opened tmp file for writing");

my $ini_file = << "END_TOK";

[general]
xmlns=http://s.mappoint.net/mappoint-30/

[credentials]
user=$id
password=$pass

[proxy]
common=http://findv3.staging.mappoint.net/Find-30/Common.asmx
find=http://findv3.staging.mappoint.net/Find-30/FindService.asmx
route=http://routev3.staging.mappoint.net/Route-30/RouteService.asmx
render=http://renderv3.staging.mappoint.net/Render-30/RenderService.asmx

[UserInfoHeader]
DefaultDistanceUnit=km

[Culture]
Name=nl
LCID=19

[Debug]
;proxy=http://localhost/cgi-bin/soaptest.cgi
;readable=1

END_TOK

print KEY $ini_file;
close KEY;

my $size = -s TMPFILE;
ok($size,"Wrote temporary ini-file");
