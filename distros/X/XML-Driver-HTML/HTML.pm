# XML::Driver::HTML
#
# Copyright (c) 2000 Michael Koehne <kraehe@copyleft.de>
#
# XML::Driver::HTML is free software. You can use and redistribute
# this copy under terms of the GNU General Public License.

use 5.006;
no warnings 'utf8' ;

package XML::Driver::HTML;

use HTML::TreeBuilder;
use strict;
use vars qw($VERSION $METHODS);

$VERSION = '0.06';
$METHODS = {
	start_document => 1,
	end_document => 1,
	start_element => 1,
	end_element => 1,
	characters => 1,
	comment => 1
	};

$HTML::TreeBuilder::Debug = 0; # default debug level

sub new {
    my $proto = shift;
    my $self  = ($#_ == 0) ? { %{ (shift) } } : { @_ };
    my $class = ref($proto) || $proto;

    bless($self, $class);
}

sub parse {
    my $self = shift;
    my $args = ($#_ == 0) ? { %{ (shift) } } : { @_ };
    my $file;
    my $result = undef;

    $self->{'Source'} = $args->{'Source'} if $args->{'Source'};
    $self->{'Handler'} = $args->{'Handler'} if $args->{'Handler'};

    die "no Source defined" unless $self->{'Source'};
    die "no Handler defined" unless $self->{'Handler'};

    my $h = HTML::TreeBuilder->new;
    $h->ignore_unknown(1);
    $h->warn(0);
    $h->{'_store_comments'}=1;
    $h->{'_store_declarations'}=1;

    if ($self->{'Source'}{'ByteStream'}) {
    	$h->parse_file($self->{'Source'}{'ByteStream'});
    } elsif ($self->{'Source'}{'String'}) {
    	$h->parse($self->{'Source'}{'String'});
	$h->eof();
    } elsif ($self->{'Source'}{'SystemId'}) {
    	$h->parse_file($self->{'Source'}{'SystemId'});
    } else {
    	die "no Source defined";
    }

    $self->{'Methods'} = {};
    foreach (keys %$METHODS) {
	$self->{'Methods'}{$_} = 1 if $self->{'Handler'}->can($_);
    }

    delete $self->{'Recode'};
    $self->{'Recode'} = 1 if lc($self->{'Source'}{'Encoding'}) eq "iso-8859-1";
    $self->{'Recode'} = 1 if lc($self->{'Source'}{'Encoding'}) eq "iso88591";
    $self->{'Recode'} = 1 if lc($self->{'Source'}{'Encoding'}) eq "latin1";

    $self->{'Handler'}->start_document()
        if $self->{'Methods'}{'start_document'};
    $self->dumptree($h);
    $result = $self->{'Handler'}->end_document()
        if $self->{'Methods'}{'end_document'};

    $h = $h->delete(); # nuke it!

    return $result;
}

sub dumptree {
    my ($self,$element) = @_;

    my $tag = $element->{'_tag'};
    my $cont = $element->{'_content'};
    my $attr = {};
    my $value;

    return if $tag eq "style";

    if ($tag) {
    	if ($self->{'Recode'}) {
            foreach (keys %$element) {
                if ($_ !~ '^_') {
                    $value = $element->{$_};
                    $value =~
                        s/([\x80-\xFF])/chr(0xC0|ord($1)>>6).chr(0x80|ord($1)&0x3F)/eg;
                    $attr->{$_} = $value;
                }
            }
	} else {
	    foreach (keys %$element) {
	        $attr->{$_} = $element->{$_}
			if $_ !~ '^_';
	    }
	}

	if ($tag !~ /^\~/) {
	    $self->{'Handler'}->start_element( {
		    'Name' => $tag, 'Attributes' => $attr
		    } )
		if $self->{'Methods'}{'start_element'};

	    foreach (@$cont) {
		if (ref $_ eq 'HTML::Element') {
		    $self->dumptree($_)
		} else {
                    s/([\x80-\xFF])/chr(0xC0|ord($1)>>6).chr(0x80|ord($1)&0x3F)/eg
                        if $self->{'Recode'};
		    $self->{'Handler'}->characters( { 'Data' => $_ } )
			if ($self->{'Methods'}{'characters'} && (lc($_) !~ "^[ \t]*<!"));
		}
	    }

	    $self->{'Handler'}->end_element( { 'Name' => $tag } )
		if $self->{'Methods'}{'end_element'};
	}
	if ($tag eq "~comment") {
	    $self->{'Handler'}->comment( { 'Data' => $attr->{'text'} } )
	    	if $self->{'Methods'}{'comment'};
	}
    }
}

1;
__END__

=head1 NAME

XML::Driver::HTML - SAX Driver for non wellformed HTML.

=head1 SYNOPSIS

  use XML::Driver::HTML;

  $driver = new XML::Driver::HTML(
  	'Handler' => $some_sax_filter_or_handler,
	'Source' => $some_PerlSAX_like_hash
	);

  $driver->parse();

or

  use XML::Driver::HTML;

  $driver = new XML::Driver::HTML();

  $driver->parse(
  	'Handler' => $some_sax_filter_or_handler,
	'Source' => $some_PerlSAX_like_hash
	);

  $driver->parse(
  	'Handler' => $some_other_sax_filter_or_handler,
	'Source' => $some_other_source
	);
  
=head1 DESCRIPTION

XML::Driver::HTML is a SAX Driver for HTML. There is no need for the HTML
input to be weel formed, as XML::Driver::HTML is generating its SAX events
by walking a HTML::TreeBuilder object. The simplest kind of use, is a
filter from HTML to XHTML using XML::Handler::YAWriter as a SAX Handler.

    my $ya = new XML::Handler::YAWriter( 
	'Output' => new IO::File ( ">-" ),
	'Pretty' => {
	    'NoWhiteSpace'=>1,
	    'NoComments'=>1,
	    'AddHiddenNewline'=>1,
	    'AddHiddenAttrTab'=>1,
	    }
	);

    my $html = new XML::Driver::HTML(
	'Handler' => $ya,
	'Source' => { 'ByteStream' => new IO::File ( "<-" ) }
	);
    
    $html->parse();

=head2 METHODS

=over

=item new

Creates a new XML::Driver::HTML object. Default options
for parsing, described below, are passed as key-value
pairs or as a single hash.  Options may be changed
directly in the object.

=item parse

Parses a document.  Options, described below, are
passed as key-value pairs or as a single hash.
Options passed to B<parse()> override the default options
in the parser object for the duration of the parse.

=back

=head2 OPTIONS

The following options are supported by XML::Driver::HTML :

=over

=item Handler

Default SAX Handler to receive events

=item Source

Hash containing the input source for parsing.
The `Source' hash may contain the following parameters:

=over

=item ByteStream       

The raw byte stream (file handle) containing the document.

=item String           

A string containing the document.

=item SystemId         

The system identifier (URL) of the document.

=item Encoding

A string describing the character encoding.

=back

If more than one of `ByteStream', `String', or `SystemId',
then preference is given first to `ByteStream', then
`String', then `SystemId'.

=back

=head1 NOTES

XML::Driver::HTML requires Perl 5.6 to convert from ISO-8859-1 to UTF-8.

=head1 BUGS

not yet implemented:

    Interpretation of SystemId as being an URI
    XHTML document type

other bugs:

    HTML::Parser and HTML::TreeBuilder bugs concerning DOCTYPE and CSS.
    Perl handling of UFT8 is compatible between different versions. So
    you need exactly Perl 5.6.0, not lower not higher.

=head1 AUTHOR

  Michael Koehne, Kraehe@Copyleft.De
  (c) 2001 GNU General Public License

=head1 SEE ALSO

L<XML::Parser::PerlSAX> and L<HTML::TreeBuilder>

=cut
