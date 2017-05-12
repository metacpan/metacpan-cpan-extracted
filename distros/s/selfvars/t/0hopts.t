
use lib 't/lib';
use HOpts;
use Test::More tests => 2;

{
    my $o = HOpts->new;
    is($o->hopts( param => 2 ), '0 2');
    eval {
       $o->die_in_action;
	 };
    is($@, "Modification of a read-only %hopts attempted at t/lib/HOpts.pm line 16\n");
}

