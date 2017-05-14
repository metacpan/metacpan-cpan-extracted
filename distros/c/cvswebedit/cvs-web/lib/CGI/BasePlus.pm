package CGI::BasePlus;

require 5.001;
use CGI::Base;
use URI::Escape  qw(uri_escape uri_unescape);
use CGI::Carp;
@ISA = qw(CGI::Base);

$revision='$Id: BasePlus.pm,v 2.76 1997/4/5 08:20:00 lstein Exp $';
($VERSION=$revision)=~s/.*(\d+\.\d+).*/$1/;

=head1 NAME

CGI::BasePlus - HTTP CGI Base Class with Handling of Multipart Forms

=head1 DESCRIPTION

This module implements a CGI::BasePlus object that is identical in
behavior to CGI::Base except that it provides special handling for
postings of MIME type multipart/form-data (which may get very long).
In the case of these types of postings, parts that are described
as being from a file upload are copied into a temporary file in
/usr/tmp, a filehandle is opened on the temporary files, and the name
of the filehandle is returned to the caller in the
$CGI::Base:QUERY_STRING variable.

Please see L<CGI::Base> for more information.

=head2 SEE ALSO

URI::URL, CGI::Request, CGI::MiniSvr, CGI::Base

=cut
    ;

############ SUPPORT ROUTINES FOR THE NEW MULTIPART ENCODING ##########
package MultipartBuffer;

# how many bytes to read at a time.  We use
# a 5K buffer by default.
$FILLUNIT = 1024 * 5;		
$TIMEOUT = 10*60;       # 10 minute timeout
$SPIN_LOOP_MAX = 1000;  # bug fix for some Netscape servers
$CRLF="\015\012";

sub new {
    my($package,$boundary,$length,$filehandle) = @_;
    my $IN;
    if ($filehandle) {
	my($package) = caller;
	# force into caller's package if necessary
	$IN = $filehandle=~/[':]/ ? $filehandle : "$package\:\:$filehandle"; 
    }
    $IN = "main::STDIN" unless $IN;
    binmode($IN);

    # Netscape seems to be a little bit unreliable
    # about providing boundary strings.
    if ($boundary) {
	# Under the MIME spec, the boundary consists of the 
	# characters "--" PLUS the Boundary string
	$boundary = "--$boundary";
	# Read the topmost (boundary) line plus the CRLF
	my($null) = '';
	$length -= read($IN,$null,length($boundary)+2,0);
    } else { # otherwise we find it ourselves
	my($old);
	($old,$/) = ($/,$CRLF); # read a CRLF-delimited line
	$boundary = <$IN>;      # BUG: This won't work correctly under mod_perl
	$length -= length($boundary);
	chomp($boundary);               # remove the CRLF
	$/ = $old;                      # restore old line separator
    }

    my $self = {LENGTH=>$length,
		BOUNDARY=>$boundary,
		IN=>$IN,
		BUFFER=>'',
	    };

    $FILLUNIT = length($boundary) if length($boundary) > $FILLUNIT;

    return bless $self,$package;
}

# This reads and returns the header as an associative array.
# It looks for the pattern CRLF/CRLF to terminate the header.
sub readHeader {
    my($self) = @_;
    my($end);
    my($ok) = 0;
    do {
	$self->fillBuffer($FILLUNIT);
	$ok++ if ($end = index($self->{BUFFER},"${CRLF}${CRLF}")) >= 0;
	$ok++ if $self->{BUFFER} eq '';
	$FILLUNIT *= 2 if length($self->{BUFFER}) >= $FILLUNIT; 
    } until $ok;

    my($header) = substr($self->{BUFFER},0,$end+2);
    substr($self->{BUFFER},0,$end+4) = '';
    my %return;
    while ($header=~/^([\w-]+): (.*)$CRLF/mog) {
	$return{$1}=$2;
    }
    return %return;
}

# This reads and returns the body as a single scalar value.
sub readBody {
    my($self) = @_;
    my($data);
    my($returnval)='';
    while (defined($data = $self->read)) {
	$returnval .= $data;
    }
    return $returnval;
}

# This will read $bytes or until the boundary is hit, whichever happens
# first.  After the boundary is hit, we return undef.  The next read will
# skip over the boundary and begin reading again;
sub read {
    my($self,$bytes) = @_;

    # default number of bytes to read
    $bytes = $bytes || $FILLUNIT;       

    # Fill up our internal buffer in such a way that the boundary
    # is never split between reads.
    $self->fillBuffer($bytes);

    # Find the boundary in the buffer (it may not be there).
    my $start = index($self->{BUFFER},$self->{BOUNDARY});

    # If the boundary begins the data, then skip past it
    # and return undef.  The +2 here is a fiendish plot to
    # remove the CR/LF pair at the end of the boundary.
    if ($start == 0) {

	# clear us out completely if we've hit the last boundary.
	if (index($self->{BUFFER},"$self->{BOUNDARY}--")==0) {
	    $self->{BUFFER}='';
	    $self->{LENGTH}=0;
	    return undef;
	}

	# just remove the boundary.
	substr($self->{BUFFER},0,length($self->{BOUNDARY})+2)='';
	return undef;
    }

    my $bytesToReturn;    
    if ($start > 0) {           # read up to the boundary
	$bytesToReturn = $start > $bytes ? $bytes : $start;
    } else {    # read the requested number of bytes
	# leave enough bytes in the buffer to allow us to read
	# the boundary.  Thanks to Kevin Hendrick for finding
	# this one.
	$bytesToReturn = $bytes - (length($self->{BOUNDARY})+1);
    }

    my $returnval=substr($self->{BUFFER},0,$bytesToReturn);
    substr($self->{BUFFER},0,$bytesToReturn)='';
    
    # If we hit the boundary, remove the CRLF from the end.
    return ($start > 0) ? substr($returnval,0,-2) : $returnval;
}

# This fills up our internal buffer in such a way that the
# boundary is never split between reads
sub fillBuffer {
    my($self,$bytes) = @_;
    return unless $self->{LENGTH};

    my($boundaryLength) = length($self->{BOUNDARY});
    my($bufferLength) = length($self->{BUFFER});
    my($bytesToRead) = $bytes - $bufferLength + $boundaryLength + 2;
    $bytesToRead = $self->{LENGTH} if $self->{LENGTH} < $bytesToRead;

    # Try to read some data.  We may hang here if the browser is screwed up.  
    my $bytesRead = read($self->{IN},$self->{BUFFER},$bytesToRead,$bufferLength);

    # An apparent bug in the Netscape Commerce server causes the read()
    # to return zero bytes repeatedly without blocking if the
    # remote user aborts during a file transfer.  I don't know how
    # they manage this, but the workaround is to abort if we get
    # more than SPIN_LOOP_MAX consecutive zero reads.
    if ($bytesRead == 0) {
	die  "CGI::BasePlus: Server closed socket during multipart read (client aborted?).\n"
	    if ($self->{ZERO_LOOP_COUNTER}++ >= $SPIN_LOOP_MAX);
    } else {
	$self->{ZERO_LOOP_COUNTER}=0;
    }

    $self->{LENGTH} -= $bytesRead;
}

# Return true when we've finished reading
sub eof {
    my($self) = @_;
    return 1 if (length($self->{BUFFER}) == 0)
		 && ($self->{LENGTH} <= 0);
}

package TempFile;

@TEMP=('/usr/tmp','/var/tmp','/tmp',);
unshift(@TEMP,$ENV{TMPDIR}) if defined($ENV{TMPDIR});

foreach (@TEMP) {
    do {$TMPDIRECTORY = $_; last} if -w $_;
}
$TMPDIRECTORY  = "." unless $TMPDIRECTORY;
$SEQUENCE="CGItemp${$}0000";

# cute feature, but no longer supported
# %OVERLOAD = ('""'=>'as_string');

# Create a temporary file that will be automatically
# unlinked when finished.
sub new {
    my($package) = @_;
    $SEQUENCE++;
    my $directory = "${TMPDIRECTORY}/${SEQUENCE}";
    return bless \$directory;
}

sub DESTROY {
    my($self) = @_;
    unlink $$self;		# get rid of the file
}

sub as_string {
    my($self) = @_;
    return $$self;
}

############ OVERRIDDEN ROUTINES IN CGI::Base ##########
package CGI::BasePlus;

# Read entity body in such a way that file uploads are stored
# to temporary disk files.  See below.
sub read_post_body {
    my $self = shift;

    # Use parent's read_post_body() method unless we have a
    # new multipart/form-data type of body to deal with.
    return &CGI::Base::read_post_body($self)
	unless $CGI::Base::CONTENT_TYPE =~ m|^multipart/form-data|;

    # Handle multipart/form-data postings.  For compatability
    # with the Request.pm module, the name/value pairs are
    # converted into canonical (URL-encoded) form and stored
    # into $CGI::Base::QUERY_STRING.
    my($boundary) = $ENV{'CONTENT_TYPE'}=~/boundary=(\S+)/;
    $self->read_multipart($boundary,$ENV{'CONTENT_LENGTH'});
}

sub read_multipart {
    my($self,$boundary,$length) = @_;
    my($buffer) = new MultipartBuffer($boundary,$length);
    my(%header,$body);
    while (!$buffer->eof) {
	%header = $buffer->readHeader;
	# In beta1 it was "Content-disposition".  In beta2 it's "Content-Disposition"
	# Sheesh.
	my($key) = $header{'Content-disposition'} ? 'Content-disposition' : 'Content-Disposition';
	my($param) = $header{$key}=~/ name="(.*?)"/;
	my($filename) = $header{$key}=~/ filename="(.*?)"/;

	my($value);

	if ($filename) {
	    # If we get here, then we are dealing with a potentially large
	    # uploaded file.  Save the data to a temporary file, then open
	    # the file for reading, and stash the filehandle name inside
	    # the query string.
	    my($tmpfile) = new TempFile;
	    my $tmp = $tmpfile->as_string;

	    open (OUT,">$tmp") || croak "CGI open of $tmpfile: $!\n";
	    chmod 0666,$tmp;	# make sure anyone can delete it.
	    binmode(OUT);

	    my $data;
	    while ($data = $buffer->read) {
		print OUT $data;
	    }
	    close OUT;

	    # Now create a new filehandle in the caller's namespace.
	    # The name of this filehandle just happens to be identical
	    # to the original filename (NOT the name of the temporary
	    # file, which is hidden!)
	    my($filehandle);
	    if ($filename=~/^[a-zA-Z_]/) {
		my($frame,$cp) = (1);
		do { $cp = caller($frame++); } until $cp!~/^CGI/;
		$filehandle = "$cp\:\:$filename";
	    } else {
		$filehandle = "\:\:$filename";
	    }
	    warn "Filehandle = $filehandle tmpfile = $tmp";

	    open($filehandle,$tmp) || croak "CGI open of $tmpfile: $!\n";
	    binmode($filehandle);
	    $value = $filename;

	    # Under Unix, it is safe to let the temporary file be deleted
	    # when it goes out of scope.  The storage is not deallocated
	    # until the last file descriptor is closed.  So we do nothing
	    # special here.
	}

	# If we get here then we're dealing a non-file form field, which we
	# will assume can fit into memory OK.
	else {
	    $value = $buffer->readBody;
	}

	# Now we store the parameter name and the value into our
	# query string for later retrieval
	$CGI::Base::QUERY_STRING .= '&' if $CGI::Base::QUERY_STRING;
	$CGI::Base::QUERY_STRING .= uri_escape($param) . '=' . uri_escape($value);
    }
    1;
}

$VERSION;			# prevent spurious warning message
