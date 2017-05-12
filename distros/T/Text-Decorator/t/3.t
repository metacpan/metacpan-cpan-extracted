use Test::More 'no_plan';
use_ok("Text::Decorator::Group");

# Test constructor
my $object = Text::Decorator::Group->new();
isa_ok($object, "Text::Decorator::Group");
# Do all data members have the right value?


is_deeply($object->{nodes}, [], 
    "Constructor set \$object->{nodes} OK");


is_deeply($object->{representations}, {}, 
    "Constructor set \$object->{representations} OK");


# Test the format_as method exists
ok($object->can("format_as"), "We can call format_as");

