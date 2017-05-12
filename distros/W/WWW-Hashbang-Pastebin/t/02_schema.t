use strict;
use warnings;
use Test::More tests => 8;
use Test::DBIx::Class qw(:resultsets);

fixtures_ok 'basic';

my $paste = Paste->find({paste_id => 1});
ok $paste, 'paste retrieved';
can_ok $paste, qw(id content date deleted);
is $paste->id, 1, 'correct ID';
is $paste->content, "test1\nline2", 'correct content';
isa_ok $paste->date, 'DateTime', 'date is inflated';
cmp_ok $paste->date->compare( DateTime->now( time_zone => 'UTC' ) ), '<', 0, 'Paste created in the past';
is $paste->deleted, 0, 'not deleted';
