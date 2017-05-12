use strict;
use warnings;

use above 'UR';
use Test::More tests => 9;

UR::Object::Type->define(class_name => 'Sandwich');
UR::Object::Type->define(class_name => 'Drink');
UR::Object::Type->define(
    class_name => 'Combo',
    id_by => [
        sandwich => { is => 'Sandwich' },
        drink => { is => 'Drink' },
    ],
);

UR::Object::Type->define(
    class_name => 'Order',
    has => [
        sandwich => { is => 'Sandwich', id_by => 'sandwich_id' },
        drink => { is => 'Drink' },
    ],
);

UR::Object::Type->define(
    class_name => 'BuggedOrder',
    has => [
        # sandwich has to have the id_by here in order to trigger the bug
        sandwich => { is => 'Sandwich', id_by => 'sandwich_id' },
        drink => { is => 'Drink' },    # yes, drink_id is ommitted here
    ],
    has_optional => [
        combo => {
            is => 'Combo',
            id_by => ['sandwich_id', 'drink_id'],  # This drink_id is not related to 'drink' above
        },
    ],  
);


my $sandwich = Sandwich->create;
isa_ok($sandwich, 'Sandwich', 'sandwich');

my $drink = Drink->create;
isa_ok($drink, 'Drink', 'drink');

my $ok_order = Order->create(sandwich => $sandwich, drink => $drink);
isa_ok($ok_order, 'Order', 'ok_order');
is($ok_order->__meta__->property('sandwich')->is_optional, 0, 'sandwich is not optional');

my $order = BuggedOrder->create(sandwich => $sandwich, drink => $drink);
isa_ok($order, 'BuggedOrder', 'order');
my $order_meta = $order->__meta__;
is($order_meta->property('sandwich_id')->is_optional, 0, 'sandwich_id is not optional');
is($order_meta->property('sandwich')->is_optional, 0, 'sandwich is not optional');
is($order_meta->property('drink')->is_optional, 0, 'drink is not optional');
# because drink_id isn't mentioned in the definition of drink, but is for combo
is($order_meta->property('drink_id')->is_optional, 1, 'drink_id is optional');

