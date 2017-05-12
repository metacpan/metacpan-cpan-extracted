#!/usr/bin/perl -w
use strict;

use lib qw(t/lib);

use Test::More;
use WWW::Scraper::ISBN;

# Can we create the object?

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');
my $scraper2 = $scraper->new();
isa_ok($scraper2,'WWW::Scraper::ISBN');

# can we handle drivers?

my @drivers = $scraper->drivers("Test");
is(@drivers,1);
is($drivers[0],'Test');
@drivers = $scraper->reset_drivers();
is(@drivers,0);

# Can we search for a valid ISBN, with no driver?

my $isbn = '9780571239566';
my $record;
eval { $record = $scraper->search($isbn) };
like($@,qr/No search drivers specified/);

# Can we search for a valid ISBN, with driver?

@drivers = $scraper->drivers("Test");
is(@drivers,1);
is($drivers[0],'Test');

eval { $record = $scraper->search($isbn) };
is($@,'');
isa_ok($record,'WWW::Scraper::ISBN::Record');
is($record->found,1);
my $b = $record->book;
is($b->{isbn},'9780571239566');
is($b->{title},'test title');
is($b->{author},'test author');

# Can we search for a valid ISBN, but not found?

$isbn = '9780987654328';
eval { $record = $scraper->search($isbn) };
is($@,'');
isa_ok($record,'WWW::Scraper::ISBN::Record');
is($record->found,0);
is($record->book,undef);
is($record->error,'');

# Can we handle errors?

$isbn = '9790571239589';
eval { $record = $scraper->search($isbn) };
is($@,'');
isa_ok($record,'WWW::Scraper::ISBN::Record');
is($record->found,0);
is($record->book,undef);
is($record->error,'Website unavailable');

# Can we search for a blank ISBN?
eval { $record = $scraper->search(); };
like($@,qr/Invalid ISBN specified/);

# Can we search for an invalid ISBN?

$isbn = '098765432X';
$record = undef;
eval { $record = $scraper->search($isbn) };

# Note: validation is different if Business::ISBN is installed

like($@,qr/Invalid ISBN specified/);
is($record,undef);

done_testing();
