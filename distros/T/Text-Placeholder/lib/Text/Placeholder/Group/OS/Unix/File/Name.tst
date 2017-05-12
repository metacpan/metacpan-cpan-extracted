#!/usr/bin/perl -W -T

use strict;
use Data::Dumper;
#use Test::Simple tests => 0;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $os_unix_file = '::OS::Unix::File::Name');
$placeholder->compile('File base name: [=file_name_base=]');

$os_unix_file->subject('/tmp/test.dat');
print ${$placeholder->execute()}, "<-\n";

exit(0);
