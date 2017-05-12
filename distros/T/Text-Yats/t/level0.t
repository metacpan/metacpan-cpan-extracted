use Text::Yats;

print "1..3\n";

print "ok 1\n";

my $tpl = Text::Yats->new(file => "templates/mail.txt") or print "not ";

print "ok 2\n";

$tpl->replace(
	date      => "2001/11/29",
	from      => "hdias\@test.com",
	to        => "anita\@test.com",
	subject   => "This is a test subject",
	message   => "This is a test message",
	signature => "------\nHenrique Dias\n------", ) or print "not ";

print "ok 3\n";

undef $tpl;
