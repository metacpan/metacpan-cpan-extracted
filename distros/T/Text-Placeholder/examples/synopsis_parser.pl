#!/usr/bin/perl -W

use strict;

use Text::Placeholder;
my $parser = Text::Placeholder::build_parser('^(.*?)<\%\s+([^\%\>]+)\s\%>');
my $placeholder = Text::Placeholder->new(
	$parser,
	my $counter = '::Counter',
	my $os_unix_file_name = '::OS::Unix::File::Name');
$placeholder->compile('#<% counter %>. <% file_name_base %>');

my @file_names = qw(/etc/hosts nonexisting.txt /etc/passwd);
foreach my $file_name (@file_names) {
	$os_unix_file_name->subject($file_name);
	print ${$placeholder->execute()}, "\n";
}

exit(0);
