#
#   $Id: 08_test_export_ok.t,v 1.4 2007-01-23 16:05:12 erwan Exp $
#
#   test that using later a module that can't compile makes the code die
#

package main;

use strict;
use warnings;
use Test::More tests => 7;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 
use Data::Dumper;

use later "My::Module2", qw(foo bar); # a module doing EXPORT_OK

sub module_is_used {
    no strict 'refs';
    my %runtime = %{"My::Module2::"};
    delete $runtime{'AUTOLOAD'};
    delete $runtime{'foo'};
    delete $runtime{'oops'};
    use strict 'refs';

    return scalar keys %runtime;
}

ok(!module_is_used, "module is not used yet");

my $str = My::Module2::foo();

ok(module_is_used, "module is now used");

is($str,'foo', "foo says foo");
is(foo(),'foo', "foo says foo even when called directly");
is(bar(),'bar', "bar says bar");

eval { oops(); };
ok( $@ =~ /Undefined subroutine \&main::oops called at .*08_test_export_ok.t/, "non imported subs are indeed undefined" );

is(My::Module2::oops(),'oops', "but oops can be called with full path");
