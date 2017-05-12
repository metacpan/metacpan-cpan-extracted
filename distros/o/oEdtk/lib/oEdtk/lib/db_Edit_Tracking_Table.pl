#!/usr/bin/perl
use oEdtk::trackEdtk qw (prepare_Tracking_Env edit_Track_Table);

if (@ARGV < 1 or $ARGV[0] =~/-h/i) {
	die "Usage : $0 \"sql_request\"\n";
}
prepare_Tracking_Env();

print "Looking for DBI_DNS $ENV{EDTK_DBI_DSN}...\n"; 
my $sql_request = $ARGV[0];
edit_Track_Table($sql_request);
1;