use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";

use URT;
use Test::More tests => 2;

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => 'thing_id',
);

sub run_test {
    my $use_transaction = shift;

    plan tests => 4;

    my $tx;
    if($use_transaction) {
        $tx = UR::Context::Transaction->begin();
    } else {
        $tx = 'UR::Context';
    }

    my $thing = URT::Thing->create(thing_id => '1');

    my $undo_call_count = 0;
    my $undo = sub {
        $undo_call_count++;
    };

    my $c = UR::Context::Transaction->log_change(
        $thing, $thing->class, $thing->id, 'external_change', $undo
    );
    isa_ok($c, 'UR::Change', 'created a change');
    is($c->undo_data, $undo, 'undo subrountine properly configured');

    $tx->rollback();
    is($undo_call_count, 1, 'undo fired');

    UR::Context->rollback(); #can't rollback a transaction twice
    is($undo_call_count, 1, 'undo did not fire again');
}

subtest 'undo outside transaction' => sub {
    run_test('0');
};

subtest 'undo within transaction' => sub {
    run_test('1');
};
