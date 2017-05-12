use strict;
use lib 't', 'inc';
use Test::More tests => 11;
use onlyTest;
use File::Spec;

require only;

my $o = only->new;
$o->module('_Foo::Bar');
$o->condition('0.55');
my $incs = @INC;
$o->include;
$o->include;
$o->include;
is(scalar(@INC), $incs + 1);

require _Foo::Bar;
only->fix_INC;
is($_Foo::Bar::VERSION, '0.50');
ok(defined $INC{'_Foo/Bar.pm'});
like($INC{'_Foo/Bar.pm'}, qr'version');
ok(defined $INC{'_Foo/Baz.pm'});
like($INC{'_Foo/Baz.pm'}, qr'version');

my $lib = File::Spec->rel2abs(File::Spec->catdir(qw(t alternate)));
only->new->include->module('_Boom')->versionlib($lib)->condition('0.10-0.20');
require _Boom;
only->fix_INC;
is($_Boom::VERSION, '0.77');
ok(defined $INC{'_Boom.pm'});
like($INC{'_Boom.pm'}, qr'alternate');
like($INC{'_Boom.pm'}, qr'0\.11');

$o->remove;
is(scalar(@INC), $incs + 1);
