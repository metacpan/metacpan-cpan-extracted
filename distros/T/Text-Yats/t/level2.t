use Text::Yats;

print "1..5\n";

print "ok 1\n";

my $tpl = Text::Yats->new(
		level => 2,
		file  => "templates/complex.html") or print "not ";

print "ok 2\n";

$tpl->section->[0]->replace(
		title      => "Yats",
		version    => "$Text::Yats::VERSION", ) or print "not ";

print "ok 3\n";

$tpl->section->[1]->section->[0]->replace(
		list       => ['hdias','anita','cubitos'],
		value      => [1,2,3],
		selected   => { value => "selected",
				array => "list",
				match => "anita", }) or print "not ";

$tpl->section->[1]->section->[1]->replace(
		list       => ['hdias','anita','cubitos'],
		value      => [1,2,3],
		selected   => { value => "selected",
				array => "list",
				match => "anita", }) or print "not ";

$tpl->section->[1]->section->[2]->replace(
		list       => ['hdias','anita','cubitos','cindy'],
		value      => [1,2,3,4],
		selected   => { value => "selected",
				array => "list",
				match => ["anita","cindy"], }) or print "not ";

print "ok 4\n";

$tpl->section->[2]->text or print "not ";

print "ok 5\n";

undef $tpl;
