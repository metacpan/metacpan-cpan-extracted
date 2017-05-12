use strict;
use  Test::More;

use constant TMPFILE => "./test_mappoint.ini";

unless( -f TMPFILE ) {
    
    plan tests => 7;	
    
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

} else {

  plan tests => 3;

}

use_ok( "WebService::Mappoint" );
use MIME::Base64;

my $render = new WebService::Mappoint::Render( TMPFILE );
my $map;

$map = $render->GetMap(
		       specification => [ 
					 DataSourceName => 'MapPoint.EU',
					 Options => [
						     Format => [
								Height => 320,
								Width => 320 
							       ],
						    ],
					 Views => [
						   'MapView:ViewByScale' => 
						   [
						    CenterPoint =>
						    [ Latitude => 37.7632, 
						      Longitude => -122.439702 ],
						    MapScale => 100000000
						   ],
						  ],	
					 Pushpins => [ 
						      Pushpin => 
						      [  
						       IconName => '176',
						       IconDataSource => 'MapPoint.Icons',
						       PinID => 'san_francisco',
						       Label => 'San Francisco',
						       ReturnsHotArea => 'false',
						       LatLong => [ Latitude => 37.7632, 
								    Longitude => -122.439702 ],
						      ]
						     ]			    
					] );

my $image = decode_base64($map->result->{MapImage}{MimeData}{Bits});
open( GIF, ">san_francisco.gif" );
print( GIF $image );

my $size = -s TMPFILE;
ok( $size > 100, "Fetched test map san_francisco.gif" ) ;

unlink "san_francisco.gif";
unlink TMPFILE;

ok( ! -f TMPFILE, "Removed temporary ini file" );
