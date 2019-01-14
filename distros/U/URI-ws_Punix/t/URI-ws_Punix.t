use strict;
use warnings;
use Data::Dumper;

use Test::More tests=>12;

use URI;

# parse string
{
  my $url=q{ws+unix://unix%2F:%2Ftest%2Fsocket.sock/testing};
  my $u=new URI($url);

  $u->set_false_scheme('ws');
  cmp_ok($u->scheme,'eq','ws','unix - schema check');
  cmp_ok($u->host,'eq','unix/','unix - host check');
  cmp_ok($u->port,'eq','/test/socket.sock','unix - port check');
  cmp_ok($u->path,'eq','/testing','unix - path check');
  cmp_ok($u->secure,'==',0,'should show as insecure');
  cmp_ok($u->as_string,'eq',$url,'unix - input and output should match');
}

cmp_ok(keys(%URI::ws_Punix::KNOWN),'==',0,'make sure the code cleans up');

{
  my $u=new URI('','ws+unix');
  $u->scheme('ws+unix');
  cmp_ok($u->scheme,'eq','ws+unix','should return our real scheme');

  $u->host('unix/');
  cmp_ok($u->host,'eq','unix/','default host shold be "unix/"');

  $u->port('/some/local.sock');

  cmp_ok($u->port,'eq','/some/local.sock','make sure our port is valid when we set it');
  $u->path('/testing');
  cmp_ok($u->path,'eq','/testing','should now show our path as /testing');
}
cmp_ok(keys(%URI::ws_Punix::KNOWN),'==',0,'make sure the code cleans up');
