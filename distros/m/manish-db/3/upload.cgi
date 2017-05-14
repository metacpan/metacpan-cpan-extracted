#!/usr/bin/perl -wT
use CGI qw(:standard);
use Fcntl qw(:flock);
use strict;

print header;
print start_html("Upload Results");
print h2("Upload Results");

my $file = param('upfile');
unless ( $file ) {
    print "Nothing uploaded?<p>\n";
} else {
    print "Filename: $file<br>\n";
    my $ctype = uploadInfo($file)->{'Content-Type'};
    print "MIME Type: $ctype<br>\n";
    open( OUT, ">/tmp/outfile" )
      or &dienice("Can't open outfile for writing: $!");
    flock( OUT, LOCK_EX );
    my $file_len = 0;
    while ( read( $file, my $i, 1024 ) ) {
        print OUT $i;
        $file_len = $file_len + 1024;
        if ( $file_len > 1024000 ) {
            close(OUT);
            &dienice("Error - file is too large. Save aborted.<p>");
        }
    }
    close(OUT);
    print "File Size: ", $file_len / 1024, "KB<p>\n";
    print "File saved!<p>\n";
}

print end_html;

sub dienice {
    my ($msg) = @_;
    print "<h2>Error</h2>\n";
    print "$msg<p>\n";
    exit;
}



