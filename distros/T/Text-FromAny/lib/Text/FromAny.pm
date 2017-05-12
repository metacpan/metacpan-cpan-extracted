# Text::FromAny
# A module to read pure text from a vareiety of formats
# Copyright Eskild Hustvedt 2010 <zerodogg@cpan.org>
# for Portu Media & Communications
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of either:
#
#    a) the GNU General Public License as published by the Free
#    Software Foundation; either version 3, or (at your option) any
#    later version, or
#    b) the "Artistic License" which comes with this Kit.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
# the GNU General Public License or the Artistic License for more details.
#
# You should have received a copy of the Artistic License
# in the file named "COPYING.artistic".  If not, I'll be glad to provide one.
#
# You should also have received a copy of the GNU General Public License
# along with this library in the file named "COPYING.gpl". If not,
# see <http://www.gnu.org/licenses/>.
package Text::FromAny;
use Any::Moose;
use Carp qw(carp croak);
use Try::Tiny;
use Text::Extract::Word qw(get_all_text);
use OpenOffice::OODoc 2.101;
use File::LibMagic;
use Archive::Zip;
use RTF::TEXT::Converter;
use HTML::FormatText::WithLinks;
use File::Spec::Functions;
use CAM::PDF;
use CAM::PDF::PageText;
use IPC::Open3 qw(open3);

our $VERSION = '0.21';

has 'file' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    );
has 'allowGuess' => (
    is => 'rw',
    isa => 'Str',
    default => 1,
    );
has 'allowExternal' => (
	is => 'rw',
	isa => 'Str',
	default => 0,
	);
has '_fileType' => (
    is => 'ro',
    isa => 'Maybe[Str]',
    builder => '_getType',
    lazy => 1,
    );
has '_pdfToText' => (
	is => 'ro',
	isa => 'Bool',
	builder => '_checkPdfToText',
	lazy => 1
	);
has '_content' => (
	is => 'rw',
	);
has '_readState' => (
	is => 'rw',
	isa => 'Maybe[Str]',
	);

# Ensure file exists during construction
sub BUILD
{
    my $self = shift;

    if(not -e $self->file)
    {
        croak($self->file.': does not exist');
    }
    elsif(not -r $self->file)
    {
        croak($self->file.': is not readable');
    }
    elsif(not -f $self->file)
    {
        croak($self->file.': is not a normal file');
    }
}

# Get the text string representing the contents of the file.
# Returns undef if the format is unknown or unsupported
sub text
{
    my $self = shift;
    my $ftype = $self->detectedType;
    my $text = $self->_getRead();
    
	if(defined $text)
	{
		return $text;
	}
    if(not defined $ftype)
    {
        return undef;
    }

    try
    {
        if ($ftype eq 'pdf')
        {
            $text = $self->_getFromPDF();
        }
        elsif($ftype eq 'doc')
        {
            $text = $self->_getFromDoc();
        }
        elsif($ftype eq 'odt')
        {
            $text = $self->_getFromODT();
        }
        elsif($ftype eq 'sxw')
        {
            $text = $self->_getFromSXW();
        }
        elsif($ftype eq 'txt')
        {
            $text = $self->_getFromRaw();
        }
        elsif($ftype eq 'rtf')
        {
            $text = $self->_getFromRTF();
        }
        elsif($ftype eq 'docx')
        {
            $text = $self->_getFromDocx();
        }
        elsif($ftype eq 'html')
        {
            $text = $self->_getFromHTML();
        }
        elsif(defined $ftype)
        {
            die("Text::FromAny: Unknown detected filetype: $ftype\n");
        }

        if(defined $text)
        {
            $text =~ s/(\r|\f)//g;
			$self->_content($text);
        }
    }
    catch
    {
        $text = undef;
    };

	$self->_setRead($text);

    return $text;
}

# Returns the detected filetype.
# This is defined as a method because it should not be accepted as a
# construction parameters.
sub detectedType
{
	my $self = shift;
	return $self->_fileType;
}

# Retrieve text from a PDF file
sub _getFromPDF
{
    my $self = shift;
	my $text = $self->_getFromPDF_CAMPDF();
	if ($text =~ /(\w|\d)/)
	{
		return $text;
	}
	my $pdftotext = $self->_getFromPDF_pdftotext;
	if ($pdftotext)
	{
		return $pdftotext;
	}
	return $text;
}

# Retrieve text from a PDF file using CAM::PDF
sub _getFromPDF_CAMPDF
{
	my $self = shift;
    my $f = CAM::PDF->new($self->file);
    my $text = '';
    foreach(1..$f->numPages())
    {
        my $page = $f->getPageContentTree($_);
        $text .= CAM::PDF::PageText->render($page);
    }
    return $text;
}

# Retrieve text from a PDF file using pdftotext (if we are allowed to, and it
# is available)
sub _getFromPDF_pdftotext
{
	my $self = shift;
	if(not $self->allowExternal or not $self->_pdfToText)
	{
		return;
	}
	my $content = '';
	try
	{
		my $pid = open3(my $in, my $out, my $err, 'pdftotext','-layout','-enc','UTF-8',$self->file,'-') or die("Failed to open3() pdftotext: $!\n");
		while(<$out>)
		{
			$content .= $_;
		}
		close($in) if $in;
		close($out) if $out;
		close($err) if $err;
		waitpid($pid,0);
		my $status = $? >> 8;
		if ($status != 0)
		{
			$content = '';
		}
	};
	return $content;
}

# Check if pdftotext is installed
sub _checkPdfToText
{
	foreach (split /:/, $ENV{PATH})
	{
		my $f = catfile($_,'pdftotext');
		if (-x $f and not -d $f)
		{
			return 1;
		}
	}
	return 0;
}

# Retrieve text from a msword .doc file
sub _getFromDoc
{
    my $self = shift;
    my $text = get_all_text($self->file);
    $text =~ s/(\r|\r\n)/\n/g;
    $text =~ s/\n$//;
    return $text;
}

# Retrieve text from an "Office Open XML" file
sub _getFromDocx
{
    my $self = shift;

    my $xml = $self->_readFileInZIP('word/document.xml');
    return if not defined $xml;

    # Strip formatting newlines in the XML
    $xml =~ s/\n//g;
    # Convert XML newlines to real ones
    if(not $xml =~ s/<w:p[^>]*w:rsidRDefault[^>]+>/\n/g)
    {
        $xml =~ s/<\/w:p>/\n/g;
    }
    # Remove tags
    $xml =~ s/<[^>]+>//g;

    return $xml;
}

# Retrieve text from an Open Document text file
sub _getFromODT
{
    my $self = shift;
    my $doc = odfText(file => $self->file);
    my $xml;
    open(my $out,'>',\$xml);
    $doc->getBody->print($out);
    close($out);

    return $self->_getFromODT_SXW_XML($xml);
}

# Retrieve text from a legacy OpenOffice.org writer text file
sub _getFromSXW
{
    my $self = shift;
    my $xml = $self->_readFileInZIP('content.xml');
    return $self->_getFromODT_SXW_XML($xml);
}

# Retrieve text from an RTF file
sub _getFromRTF
{
    my $self = shift;
    my $file = $self->file;
    my $text = '';

    # RTF::TEXT::Converter spews some errors to STDERR that we don't need,
    # so we silence it
    local *STDERR;
    open(STDERR,'>','/dev/null');
    try
    {
        my $p = RTF::TEXT::Converter->new( output => \$text );

        open(my $in, '<', $file);
        $p->parse_stream($in);
        close($in);
    };
    return $text;
}

# Get the contents of a cleartext file
sub _getFromRaw
{
    my $self = shift;
    open(my $in,'<',$self->file) or carp("Failed to open ".$self->file.": ".$!);
    return if not $in;
    local $/ = undef;
    my $text = <$in>;
    close($in);
    return $text;
}

# Retrieve text from a HTML file
sub _getFromHTML
{
    my $self = shift;
    my $formatText = HTML::FormatText::WithLinks->new(
		before_link => '',
		after_link => '',
		unique_links => 1,
		footnote => '%l',
	);
	my $text = $formatText->parse_file($self->file);
	# Remove additional formatting added by HTML::FormatText::WithLinks
	my $result = '';

	# Remove whitespace prefix on each line
	foreach my $l (split(/\n/,$text))
	{
		$l =~ s/^ {1,4}//;
		$result .= $l."\n";
	}

	# Remove newline padding at the end
	$result =~ s/\n+$//g;
	return $result;
}

# Simple regex cleaner and formatted for ODT and SXW
sub _getFromODT_SXW_XML
{
    my $self = shift;
    my $xml  = shift;

    # Strip formatting newlines in the XML
    $xml =~ s/\n//g;
    # Strip first text:p
    $xml =~ s/<text:p[^>]*>//;
    # Convert XML newlines to real ones
    $xml =~ s/<text:p[^>]*>/\n/g;
    # Remove tags
    $xml =~ s/<[^>]*>//g;
    return $xml;
}

# Read a single file contained in a zipfile and return its contents (or undef)
sub _readFileInZIP
{
    my $self = shift;
    my $file = shift;

    my $contents;

    try
    {
        my $zip = Archive::Zip->new();
        $zip->read($self->file);
        $contents = $zip->contents($file);
    }
    catch
    {
        $contents = undef;
    };

    return $contents;
}

# Returns a filetype, one of:
# pdf => PDF
# odt => OpenDocument text
# sxw => Legacy OpenOffice.org Writer
# doc => msword
# docx => "Open XML"
# rtf => RTF
# txt => Cleartext
# 
# undef => Unable to detect/unsupported
sub _getType
{
    my $self = shift;

    my $type = $self->_getTypeFromMIME();
    if ($type)
    {
        return $type;
    }

    $type = $self->_getTypeFromMagicDesc();
    if ($type)
    {
        return $type;
    }

    $type = $self->_guessType();

    return $type;
}

# Get the filetype based upon the mimetype
sub _getTypeFromMIME
{
    my $self = shift;
    my $type;
    my %mimeMap = (
        'application/pdf' => 'pdf',
        'application/msword' => 'doc',
        'application/vnd.ms-office' => 'doc',
        'application/vnd.oasis.opendocument.text' => 'odt',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
        'application/vnd.sun.xml.writer' => 'sxw',
        'text/plain' => 'txt',
        'text/html' => 'html',
        'text/rtf' => 'rtf',
        'application/xhtml+xml' => 'html',
    );
    try
    {
        my $mime = File::LibMagic->new();
        $type = $mime->checktype_filename($self->file);
        if ($type)
        {
            chomp($type);
            $type =~ s/;.*//g;
        }
    };

    # Try to get mimetype from the zip
    if(defined $type && $type eq 'application/zip')
    {
        $type = $self->_readFileInZIP('mimetype');
        if ($type)
        {
            $type =~ s/;.*//g;
            chomp($type);
        }
    }

    if (defined $type && $mimeMap{$type})
    {
        return $mimeMap{$type};
    }
    return;
}

# Get the filetype based upon the magic file description
sub _getTypeFromMagicDesc
{
    my $self = shift;
    my $type;
    my %descrMap = (
        '^OpenOffice\.org.+Writer.+' => 'sxw',
        '^OpenDocument text$' => 'odt',
        '^PDF document.+$' => 'pdf',
    );
    try
    {
        my $mime = File::LibMagic->new();
        my $descr = $mime->describe_filename($self->file);
        if ($descr)
        {
            foreach my $r(keys(%descrMap))
            {
                if ($descr =~ /$r/)
                {
                    $type = $descrMap{$r};
                    last;
                }

            }
        }
    };
    return $type;
}

# Guess the file type
sub _guessType
{
    my $self = shift;

    return if not $self->allowGuess;

    my @guess = qw(sxw odt txt docx);

    foreach my $e (@guess)
    {
        if ($self->file =~ /\.$e$/)
        {
            return $e;
        }
    }
    return;
}

# Saves "read" status in the object, so that we know for later reference
# if we need to re-read the file.
sub _setRead
{
	my $self = shift;
	my $text = shift;
	if(defined $text)
	{
		$self->_content($text);
	}
	$self->_readState($self->_getStateString);
}

# Retrieves the read file content as long as the read state equals the
# previous read state, otherwise returns undef
sub _getRead
{
	my $self = shift;
	
	if ($self->_readState && $self->_readState eq $self->_getStateString)
	{
		return $self->_content;
	}
	return;
}

# Retrieves the 'state string'. This is a string representation of
# the internal state in the object that might have some effect on how
# text gets read.
#
# Ie. if allowExternal or allowGuess has changed since we last read
# a file, we read it again.
sub _getStateString
{
	my $self = shift;
	my $readState = join('-',$self->allowExternal,$self->allowGuess);
	return $readState;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Text::FromAny - a module to read pure text from a vareiety of formats

=head1 SYNOPSIS

    my $tFromAny = Text::FromAny->new(file => '/some/text/file');
    my $text = $tFromAny->text;

=head1 SUPPORTED FORMATS

Text::FromAny can currently read the following formats:

    Portable Document format - PDF
    Legacy/binary MSWord .doc
    OpenDocument Text
    Legacy OpenOffice.org writer
    "Office Open XML" text
    Rich text format - RTF
    (X)HTML
    Plaintext

=head1 ATTRIBUTES

Attributes can be supplied to the new constructor, as well as set by running
object->attribute(value). The "file" attribute B<MUST> be supplied during
construction.

=over

=item B<file>

The file to read. B<MUST> be supplied during construction time (and can not be
changed later). Can be any of the supported formats. If it is not of any
supported format, or an unknown format, the object will still work, though
->text will return undef.

=item B<allowGuess>

This is a boolean, defaulting to true. If Text::FromAny is unable to properly
detect the filetype it will fall back to guessing the filetype based upon
the file extension. Set this to false to disable this.

The default for I<allowGuess> is subject to change in later versions, so if
you depend on it being either on or off, you are best off explicitly requesting
that behaviour, rather than relying on the defaults.

=item B<allowExternal>

This is a boolean, defaulting to false. If the perl-based PDF reading method
fails (L<PDF::CAM>), then Text::FromAny will fall back to calling the system
L<pdftotext(1)> to get the text. L<PDF::CAM> reads most PDFs, but has troubles
with a select few, and those can be handled by L<pdftotext(1)> from the
Poppler library.

The default for I<allowExternal> is subject to change in later versions, so if
you depend on it being either on or off, you are best off explicitly requesting
that behaviour, rather than relying on the defaults.

=back

=head1 METHODS

=over

=item B<text>

Returns the text contained in the file, or undef if the file format is unknown
or unsupported.

Normally Text::FromAny will only read the file once, and then cache the text.
However if you change the value of either the allowGuess or allowExternal
attributes, Text::FromAny will re-read the file, as those can affect how a file
is read.

=item B<detectedType>

Returns the detected filetype (or undef if unknown or unsupported).
The filetype is returned as a string, and can be any of the following:

	pdf  => PDF
	odt  => OpenDocument text
	sxw  => Legacy OpenOffice.org Writer
	doc  => msword
	docx => "Open XML"
	rtf  => RTF
	txt  => Cleartext
	html => HTML (or XHTML)

=back

=head1 BUGS AND LIMITATIONS

None known.

Please report any bugs or feature requests to
L<http://github.com/portu/Text-FromAny/issues>.

=head1 AUTHOR

Eskild Hustvedt, E<lt>zerodogg@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 by Eskild Hustvedt

This library is free software; you can redistribute it and/or modify
it under the terms of either:

    a) the GNU General Public License as published by the Free
    Software Foundation; either version 3, or (at your option) any
    later version, or
    b) the "Artistic License" which comes with this Kit.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License
in the file named "COPYING.artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this library in the file named "COPYING.gpl". If not,
see <http://www.gnu.org/licenses/>.
