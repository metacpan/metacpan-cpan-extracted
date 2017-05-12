use strict;
use warnings;
use t::Utils;
use TheSchwartz::Simple;

plan tests => 14;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh1 = shift;
    run_test {
        my $dbh2 = shift;

        my $sch = TheSchwartz::Simple->new([$dbh1, $dbh2]);
        $sch->prefix($::prefix) if $::prefix;
        isa_ok $sch, 'TheSchwartz::Simple';
        is $sch->funcname_to_id($dbh1, 'foo'), 1;
        is $sch->funcname_to_id($dbh1, 'bar'), 2;
        is $sch->funcname_to_id($dbh1, 'foo'), 1;
        is $sch->funcname_to_id($dbh1, 'baz'), 3;
        is $sch->funcname_to_id($dbh2, 'bar'), 1, 'other dbh';

        my $job_id = $sch->insert('foo', { bar => 1 });
        ok $job_id;
    };
};

}
