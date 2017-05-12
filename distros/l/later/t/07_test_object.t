#
#   $Id: 07_test_object.t,v 1.1 2007-01-22 15:58:27 erwan Exp $
#
#   test that using later a module that can't compile makes the code die
#

package main;

use strict;
use warnings;
use Test::More tests => 5;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 
use Data::Dumper;

use later "My::Module1"; # an object oriented module

sub module_is_used {
    no strict 'refs';
    my %runtime = %{"My::Module1::"};
    delete $runtime{'AUTOLOAD'};
    use strict 'refs';

    return scalar keys %runtime;
}

ok(!module_is_used, "module is not used yet");

my $obj = new My::Module1();

ok(module_is_used, "module is used now");

is(ref $obj, "My::Module1", "object looks good");
is($obj->say,"something","object says something");

# now, what about a really undefined sub?
eval {
    $obj->bar();
};

ok( (defined $@ && $@ =~ /Undefined subroutine \&My::Module1::bar called at .*07_test_object.t/), 
    "undefined subroutines trigger error");

