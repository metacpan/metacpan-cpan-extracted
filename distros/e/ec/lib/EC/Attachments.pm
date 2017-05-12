package EC::Attachments;

$VERSION=0.10;

use MIME::Base64;

my $outgoing_mime_boundary = "_----------------------------------";

my @default_mime_headers = ('MIME-Version: 1.0',
                            'Content-Type: text/plain; charset="us-ascii"',
                            'Content-Transfer-Encoding: 7bit');

my @base64_headers = ('MIME-Version: 1.0',
                      'Content-Type: multipart/mixed; boundary="'.
                         $outgoing_mime_boundary.'"', 
                      'Content-Transfer-Encoding: base64');

sub attachment_filenames {
    my ($msg) = @_;
    my (@filenames, $name);
    my $boundary = mime_boundary ($msg);
    my @msglines = split /\n/, $msg;
    foreach my $l (@msglines) {
	if ($l =~ /filename\=/si) {
	    ($name) = ($l =~ /filename=(.+)/si);
	    # In case the file name is in quotes.
	    $name =~ s/\"//g;
	    push @filenames, ($name);
	}
    }
    return @filenames;
}

sub mime_boundary {
    my ($msg) = @_;
    my ($boundary) = ($msg =~ /boundary=(.*?)\n/si);
    $boundary =~ s/\"//g;
    return $boundary;
}

sub save_attachment {
    my ($msg, $attachmentfilename, $ofilename) = @_;
    my $boundary = &mime_boundary ($msg);
    # RFC 2046 - attachment body separated from preceding boundary
    # and attachment headers by two CRLFs - translated to Unix line
    # endings here.  Boundary at the end of the attachment is preceded
    # in practice by two newlines.
    my ($cstr) = ($msg =~ 
      m"filename=\"?$attachmentfilename\"?.*?\n\n(.*?)\n+--$boundary"smi);
    $line = MIME::Base64::decode_base64 ($cstr);
    open FILE, ">$ofilename" or 
	warn "Could not save $ofilename: $!\n";
    print FILE $line;
    close FILE;
}

### Required plain and base64 message header fields.

sub default_mime_headers { return @default_mime_headers }

sub base64_headers { return @base64_headers }


### Headers for each attachment

#
# This gets inserted before the message text so no 
# additional formatting is necessary.
#
sub text_attachment_header {
    return ( "",
	     "This is a multi-part message in MIME format.",
	     '--'.$outgoing_mime_boundary,
	     "Content-Type: text/plain; charset=us-ascii",
	     "Content-Transfer-Encoding: 7bit",
	     "");
}

sub format_attachment {
    my ($filepath) = @_;
    my (@formatted,$basename);
    ($basename) = ($filepath =~ /.*\/(.*)/si);
    push @formatted, ('--'.$outgoing_mime_boundary,
		  "Content-Type: application/octet-stream; name=\"$basename\"",
		  "Content-Transfer-Encoding: base64",
		  "Content-Disposition: attachment; filename=\"$basename\"");
    push @formatted, ('');

    open FILE, "$filepath" or
	warn "Could not encode $filepath: $!\n";
    my $s = '';
    while (defined ($line = <FILE>)) {
	$s .= $line;
    }
    close FILE;
    my $encoded = MIME::Base64::encode_base64 ($s);
    my @lines = split /\n/, $encoded;
    push @formatted, @lines;
    push @formatted, ('');
    return @formatted;
}

sub outgoing_mime_boundary {
    return $outgoing_mime_boundary;
}

1;
