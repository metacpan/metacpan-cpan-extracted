use strict;
use warnings;
use Test::More;
use Test::Deep qw(eq_deeply);
use Data::Dumper;
use FindBin qw($RealBin);
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Indent=1;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request));
    plan skip_all => "Skipping PAGI tests: $skip" if $skip;
}

#  Use specific webdyne.conf setup ENV vars for using different meta file
#
$ENV{'WEBDYNE_CONF'}='t/webdyne_dir-config.conf.pl';


#  Load WebDyne
#
require_ok('WebDyne::Request::PAGI');


#  New fake request
#
my $r=WebDyne::Request::PAGI->new(
    location => '/examples/',
    filename => '.',
    scope    => {},
);
ok(ref($r) eq 'WebDyne::Request::PAGI');
ok($r->location() eq '/examples/');
ok($r->dir_config('a')==1);


#  Load ref data
#
my $hr;
{ local $/; $hr=eval(<DATA>) }
ok(eq_deeply($hr, $r->dir_config())); 


#  Get for server
#
$ENV{'WebDyneServer'}='foobar.example';
$ENV{'WebDyneLocation'}='/';
$r=WebDyne::Request::PAGI->new(filename => '.');
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
