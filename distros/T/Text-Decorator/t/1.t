use Test::More 'no_plan';
use_ok("Text::Decorator");

my $object = Text::Decorator->new("foo bar");
isa_ok($object, "Text::Decorator");
is($object->format_as("text"), "foo bar", "Round trip OK with no filters");

$object->add_filter("Test");
is($object->format_as("html"), "xxx xxx", "Test filter works");
