# This tests that the add/remove singular accessors are not overridden if the
# package defines them but instead installs __add/__remove accessors similar to
# what is done with singular properties.

use strict;
use warnings;

use Test::More tests => 4;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use UR;

my %ran_package_method;
my $class_name = setup(\%ran_package_method);

my $roster = $class_name->create();

$roster->add_member('Bob');
is_deeply([$roster->members], ['Bob'], 'added Bob');
ok($ran_package_method{add_member}, qq(ran the package add_member));

$roster->remove_member('Bob');
is_deeply([$roster->members], [], 'removed Bob');
ok($ran_package_method{remove_member}, qq(ran the package remove_member));

sub setup {
    my $ran_package_method = shift;

    my $class_name = 'Roster';

    for my $type (qw(add remove)) {
        my $singular_accessor_name = $type . '_member';
        if ($class_name->can($singular_accessor_name)) {
            die qq($class_name shouldn't be able to $singular_accessor_name yet);
        }

        my $ur_singular_accessor_name = '__' . $singular_accessor_name;
        if ($class_name->can($ur_singular_accessor_name)) {
            die qq($class_name shouldn't be able to $ur_singular_accessor_name yet);
        }

        no strict 'refs';
        *{ $class_name . '::' . $singular_accessor_name } = sub {
            my $self = shift;
            $ran_package_method->{$singular_accessor_name} = 1;
            $self->$ur_singular_accessor_name(@_);
        };
        use strict 'refs';
    }

    my $class = UR::Object::Type->__define__(
        class_name => $class_name,
        has => [
            members => {
                is => 'Text',
                is_many => 1,
            },
        ],
    );

    return $class->class_name;
}
