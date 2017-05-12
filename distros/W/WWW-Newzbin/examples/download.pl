#!/usr/bin/perl

use strict;
use warnings;

use WWW::Newzbin;
use WWW::Newzbin::Constants;

# log into newzbin using the username "joebloggs" and the password "secretpass123"
my $nzb = WWW::Newzbin->new(
	username => "joebloggs",
	password => "secretpass123"
);

# make an nzb file for binaries in newzbin report #12345678
my ($nzb_file, $report_name, $report_category) = $nzb->get_nzb(reportid => 12345678);
        
# make an nzb file for binaries in newzbin report #12345678, and leave the nzb file gzip-compressed
my ($nzb_file_gzipped, $report_name, $report_category) = $nzb->get_nzb(
	reportid => 12345678,
	leavegzip => 1
);
        
# make an nzb file for binaries with the newzbin file ids #123, #456 and #789, and don't compress it when downloading it
my $nzb_file = $nzb->get_nzb(
	fileid => [ 123, 456, 789 ],
	nogzip => 1
);
