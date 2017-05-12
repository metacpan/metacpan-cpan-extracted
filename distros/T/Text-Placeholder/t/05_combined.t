#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 1;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $os_unix_file_name = '::OS::Unix::File::Name',
	my $counter = '::Counter');
$placeholder->compile('#[=counter=] / [=file_name_base=]');

my @file_names = qw(file_name_A.txt FileNameB FilenameC.pl);
my @result = ();
foreach my $file_name (@file_names) {
	$os_unix_file_name->subject($file_name);
	push(@result, ${$placeholder->execute()});
}
my $result = join("\n", @result);

ok($result eq '#1 / file_name_A
#2 / FileNameB
#3 / FilenameC', 'T001: Listing generated.');

exit(0);
