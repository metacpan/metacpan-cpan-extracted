#
#   $Id: 02_test_no_args.t,v 1.6 2007-01-23 14:09:56 erwan Exp $
#
#   test using later a module with no import arguments
#

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 6;
use lib "../lib/",".";        # when run from t/
use lib "t/","lib/";          # when running from root 

sub module_is_used {
    no strict 'refs';
    my %runtime = %{"test1::"};
    delete $runtime{'AUTOLOAD'};
    delete $runtime{'foo'};
    use strict 'refs';

    return scalar keys %runtime;
}

ok(!module_is_used(),"module test1 has not been used yet");

use later 'test1';

ok(!module_is_used(),"module test1 has not been used yet");

my $res = foo();

# now test1 should have been used
ok(module_is_used(),"module test1 has been used now");

is($res,'foo',"foo() returned the expected value");

# it works even multiple times
is(test1::foo(),'foo',"checking with full name...");

# now, what about a really undefined sub?
eval {
    bar();
};

ok( (defined $@ && $@ =~ /Undefined subroutine \&main::bar called at .*02_test_no_args.t line 42/), 
    "other undefined subroutines trigger errors");
