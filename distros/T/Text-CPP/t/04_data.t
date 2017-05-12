use strict;
eval { require warnings; };
use Test::More tests => 7;
use Text::CPP qw(:all);

my $reader = new Text::CPP(Language => CLK_GNUC99);
ok($reader->data, 'Text::CPP has user data');
ok(ref($reader->data) eq 'HASH', 'User data is a hashref');
ok($reader->data->{foo} = 1, 'Set an item of user data');
ok($reader->data->{foo} == 1, 'Retrieved the data');
ok($reader->data->{bar} = 2, 'Set another item of user data');
ok($reader->data->{bar} == 2, 'Retrieved the new data');
ok($reader->data->{foo} == 1, 'Retrieved the original data');
