use Test::More 'no_plan';
use_ok("Text::Decorator::Node");

# Test constructor
my $object = Text::Decorator::Node->new( "foo" );
isa_ok($object, "Text::Decorator::Node");
# Do all data members have the right value?


is_deeply($object->{representations}, { text => "foo"}, 
    "Constructor set \$object->{representations} OK");

# Test the format_as method exists
ok($object->can("format_as"), "We can call format_as");

is($object->format_as("text"), "foo", "and it works");
is($object->format_as("html"), "foo", "HTML works too");

