use Test2::V0 -target => 'Test2::Harness::Schema';

use ok $CLASS;

for my $type (qw/run job event/) {
    for my $verb (qw/fetch insert poll list/) {
        my $meth = "${type}_${verb}";
        can_ok($CLASS, [$meth], "method '$meth' is defined") or next;
        like(dies { $CLASS->$meth }, qr/'$meth' not implemented/, "$meth is a Stub only");
    }
}

done_testing;
