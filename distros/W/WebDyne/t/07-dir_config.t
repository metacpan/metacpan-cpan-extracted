use strict;
use warnings;
use Test::More;
use Test::Deep qw(eq_deeply);
use Data::Dumper;
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Indent=1;


#  Use specific webdyne.conf setup ENV vars for using different meta file
#
$ENV{'WEBDYNE_CONF'}='t/webdyne_dir-config.conf.pl';


#  Load WebDyne
#
require_ok('WebDyne::Request::Fake');


#  New fake request
#
my $r=WebDyne::Request::Fake->new(
    location => '/examples/'
);
ok(ref($r) eq 'WebDyne::Request::Fake');
ok($r->location() eq '/examples/');
ok($r->dir_config('a')==1);


#  Load ref data
#
my $hr;
{ local $/; $hr=eval(<DATA>) }
#diag(Dumper($hr));
#iag(Dumper($r->dir_config()));
ok(eq_deeply($hr, $r->dir_config())); 


#  Get for server
#
$ENV{'WebDyneServer'}='foobar.example';
$ENV{'WebDyneLocation'}='/';
$r=WebDyne::Request::Fake->new();
ok($r->dir_config('d')==4);
done_testing();

__DATA__
{
  '/' => {
    'b' => 2
  },
  'foobar.example' => {
    '/' => {
      'd' => 4
    }
  },
  '/examples/' => {
    'a' => 1
  },
  '' => {
    'c' => 3
  },
  'WEBDYNE_CONF' => 't/webdyne_dir-config.conf.pl'
};
