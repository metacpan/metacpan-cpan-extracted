use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal qw(exception);

use UR;

# This is a regression test to reveal that changes were being recorded in the
# wrong order under certain conditions.  The observer causes the creation of a
# Part via 'first_part_name' to trigger the Machine object to have a property
# change on 'part_count'.  Since the change of 'part_count' would get logged
# before the 'create' of the Machine when the transaction rolled back the undo
# for the 'part_count' change would crash due to running after the 'create' was
# undone.

setup();

Part->add_observer(
    aspect => 'create',
    callback => sub {
        my ($object, $aspect) = @_;
        my $machine = $object->machine;
        my $count = $machine->part_count || 0;
        $machine->part_count($count + 1);
    },
);

my $tx = UR::Context::Transaction->begin();
my $m = Machine->create(first_part_name => 'King');

my @changes = $tx->get_changes;
my $machine_create_change = (grep { $_->changed_class_name eq 'Machine' && $_->changed_aspect eq 'create' } @changes)[0];
my $part_create_change = (grep { $_->changed_class_name eq 'Part' && $_->changed_aspect eq 'create' } @changes)[0];
ok($machine_create_change->id < $part_create_change->id, 'machine should be created before part');

ok(!exception { $tx->rollback }, 'rollback should not throw an exception');

sub setup {
    my $machine_class = UR::Object::Type->define(
        class_name => 'Machine',
        id_generator => '-uuid',
        id_by => [
            serial => { is => 'Text' },
        ],
        has => [
            part_count => { is => 'Number' },
            first_part_name => {
                is => 'Part',
                via => 'parts',
                to => 'name',
                where => [ 'serial' => 1 ],
                is_delegated => 1,
                is_mutable => 1,
            },
            parts => {
                is => 'Part',
                is_many => 1,
                reverse_as => 'machine',
            },
        ],
    );

    my $part_class = UR::Object::Type->define(
        class_name => 'Part',
        id_generator => '-uuid',
        id_by => [
            machine => {
                is => 'Machine',
                id_by => 'machine_serial',
            },
            serial => { is => 'Text' },
        ],
        has => [
            name => { is => 'Text' },
        ],
    );
}
