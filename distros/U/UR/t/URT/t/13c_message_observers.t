use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

use strict;
use warnings;

use Test::More;

plan tests => 8;

ok(UR::Object::Type->define( class_name => 'Parent', is_abstract => 1),
    'Define Parent class');
ok(UR::Object::Type->define( class_name => 'ChildA', is => 'Parent'),
    'Define class ChildA');
ok(UR::Object::Type->define( class_name => 'ChildB', is => 'Parent'),
    'Define class ChildB');

my $a = ChildA->create(id => 1);
ok($a, 'Create object a');

my $b = ChildB->create(id => 1);
ok($b, 'Create object b');

is(Parent->dump_status_messages(0), 0, 'Turn off dump_status_messages');

my %callbacks_fired;
foreach my $class (qw( Parent ChildA ChildB )) {
    $class->add_observer(aspect => 'status_message',
                            callback => sub {
                                $callbacks_fired{$class}++;
                            });
}
$a->add_observer(aspect => 'status_message',
                    callback => sub {
                        $callbacks_fired{'objecta'}++;
                    });
$b->add_observer(aspect => 'status_message',
                    callback => sub {
                        $callbacks_fired{'objectb'}++;
                    });

ok($a->status_message('Hi'), 'sent status message to object a');
is_deeply(\%callbacks_fired,
      { Parent => 1,
        ChildA => 1,
        objecta => 1 },
    'Callbacks fired correctly');

