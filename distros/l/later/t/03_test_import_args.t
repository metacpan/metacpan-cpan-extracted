#
#   $Id: 03_test_import_args.t,v 1.2 2007-01-22 15:58:27 erwan Exp $
#
#   test using later a module with import arguments
#

package main;

use strict;
use warnings;
use Test::More tests => 7;
use lib "../lib/","."; # when run from t/
use lib "t/","lib/";          # when running from root 
use Data::Dumper;

sub module_is_used {
    no strict 'refs';
    my %runtime = %{"test2::"};
    delete $runtime{'AUTOLOAD'};
    use strict 'refs';

    return scalar keys %runtime;
}

ok(!module_is_used(),"module test2 has not been used yet");

use later 'test2', 'key' => 12, 'blob' => [ a => 1, { er => 0, df => ['ouf']}], a => sub { return $_[0]+4; };

ok(!module_is_used(),"module test2 has not been used yet");

my $res = foo();

ok(module_is_used(),"module test2 has been used now");

is($res,'test2',"foo() returned the expected value");

# check the import variables
my $struct = [
	      'test2','key' => 12, 'blob' => [ a => 1, { er => 0, df => ['ouf']}],'a',
	      ];

my @vars = variables();
my $subref = pop @vars;

is_deeply(\@vars, $struct, "import parameters are ok");

is(ref $subref,"CODE","anonymous subroutines are passed as coderefs");

# one day this test should pass:
SKIP: { 
    skip "use later does not keep code references in import arguments", 1;

    is(&$subref("bla"),"bla4","subroutine is still the same"); 
};
