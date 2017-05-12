use strict;
use Test::More tests => 5;

use_ok("WWW::Mechanize::FormFiller::Value");

# Check the API :
my $v = WWW::Mechanize::FormFiller::Value->new("foo");

# Now check our published API :
my $meth;
for $meth (qw(name value)) {
  can_ok($v,$meth);
};

# name is a read-only property :
is( $v->name, "foo", "The name was set correctly" );
$v->name("bar");
is( $v->name, "bar", "The name can be changed" );
