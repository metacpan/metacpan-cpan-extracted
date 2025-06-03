use strict;
use warnings;
use Test::More tests => 13;
use Test::Deep;

BEGIN {
	use_ok('Tk::ListBrowser::Entry');
	use_ok('Tk::ListBrowser::HashList');
};

my $l = Tk::ListBrowser::HashList->new;
ok(defined $l, 'Tk::ListBrowser::HashList created');

for (qw/inny miny mo/) {
	$l->add(Tk::ListBrowser::Entry->new(
		-name => $_,
		-listbrowser => 0,
	))
}
my @list = $l->getAll;
my @r;
for (@list) { push @r, $_->name }
cmp_deeply(\@r, [qw/inny miny mo/], 'add / getAll'); 

$l->add(Tk::ListBrowser::Entry->new(
	-name => 'minny',
	-listbrowser => 0,
), 1);
@list = $l->getAll;
@r = ();
for (@list) { push @r, $_->name }
cmp_deeply(\@r, [qw/inny minny miny mo/], 'add with index'); 

ok($l->exist('inny'), 'exist');
ok($l->first->name eq 'inny', 'first');

my $g = $l->get('minny');
ok($g->name eq 'minny', 'get');

$g = $l->getIndex(2);
ok($g->name eq 'miny', 'getIndex');

ok($l->index('miny') eq 2, 'index');
ok($l->indexLast eq 3, 'indexLast');
ok($l->last->name eq 'mo', 'last');
ok($l->size eq 4, 'index');


