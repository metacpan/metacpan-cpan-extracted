use Text::Yats;

print "1..5\n";

print "ok 1\n";

my $tpl = Text::Yats->new(
		level => 1,
		file  => "templates/inline.html") or print "not ";

print "ok 2\n";

$tpl->section->[0]->replace(
		title      => "Yats",
		version    => "$Text::Yats::VERSION", ) or print "not ";

print "ok 3\n";

$tpl->section->[1]->replace(
		selected   => { value => "selected",
				array => "list",
				match => "anita", }) or print "not ";

print "ok 4\n";

$tpl->section->[2]->text or print "not ";

print "ok 5\n";

undef $tpl;
