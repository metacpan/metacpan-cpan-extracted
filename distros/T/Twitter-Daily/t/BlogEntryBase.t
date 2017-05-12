use strict;
use warnings;

use Test::More tests => 5;
use Twitter::Daily::Blog::Entry::Base;


my $entry = Twitter::Daily::Blog::Entry::Base->new();

isa_ok($entry, 'Twitter::Daily::Blog::Entry::Base');

ok( $entry->getEntry() eq "\n", "Empty entry" );

my $entry2 = Twitter::Daily::Blog::Entry::Base->new();
$entry2->setTitle("Pepe");
ok( $entry2->getEntry() eq "Pepe\n", "Empty body" );

my $entry3 = Twitter::Daily::Blog::Entry::Base->new();
$entry3->setBody("Pepe");
is( $entry3->getEntry(), "\nPepe", "Empty Title" );

my $entry4 = Twitter::Daily::Blog::Entry::Base->new();
$entry4->setBody("Body");
$entry4->setTitle("Title");
is( $entry4->getEntry(), "Title\nBody", "Full entry" );

