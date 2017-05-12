#!/usr/bin/perl

use Text::Yats;

my $tpl = Text::Yats->new(file => "../templates/mail.txt");

print $tpl->replace(
	date      => "2001/11/29",
	from      => "hdias\@test.com",
	to        => "anita\@test.com",
	subject   => "This is a test subject",
	message   => "This is a test message",
	signature => "------\nHenrique Dias\n------", );

undef $tpl;

exit(0);
