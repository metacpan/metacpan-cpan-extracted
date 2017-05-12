package XML::SemanticCompare::SAX;
use base qw( XML::SAX::Base );
use XML::SAX::ParserFactory;

use Data::Dumper;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = 0.95;

#-----------------------------------------------------------------
# new
#-----------------------------------------------------------------
sub new {
	my ( $class, %options ) = @_;

	# create an object
	my $self = {};

	# stack of elements
	$self->{elements} = ();
	$self->{items}    = ();
	bless $self, $class;
	$self->select_parser($options{parser}) if defined $options{parser};
	return $self;
}

sub select_parser {
	my $self   = shift;
	my $parser = shift;
	$parser = 'XML::LibXML::SAX::Parser' unless defined $parser;
	$XML::SAX::ParserPackage = $parser;
}

#-----------------------------------------------------------------
# parse
#    args: method => 'string', data => direct XML
#            OR
#          method => 'file',   data => filename
#-----------------------------------------------------------------
sub parse {
	my ( $self, %args ) = @_;
	die("parse() needs arguments 'method' and 'data'.")
	  unless $args{method} and $args{data};
	my $parser = XML::SAX::ParserFactory->parser( Handler => $self );
	if ( $args{method} eq 'string' ) {
		$parser->parse_string( $args{data} );
	} elsif ( $args{method} eq 'file' ) {
		$parser->parse_file( $args{data} );
	} else {
		die("in parse(): 'method' is neither 'string' nor 'file'.");
	}

	return \@{$self->{items}};
}

sub start_element {
	my ( $self, $element ) = @_;
	# [namespace-uri()='http://foo.example.com']
	my $uri = $element->{NamespaceURI};
	my $e = $element->{LocalName} . "[namespace-uri() = '$uri']" if defined $uri and ($uri ne '' or $uri eq '#');
	$e = $element->{LocalName} unless defined $e;
	$e = $self->peek() . "$e/";
	push @{ $self->{elements} }, $e;
	push @{ $self->{items} }, $e;

	foreach my $key( keys %{ $element->{Attributes} } ) {
		# ignore xmlns declarations ...
		next if $element->{Attributes}->{$key}->{Prefix} =~ /^xmlns$/;
		next if $element->{Attributes}->{$key}->{LocalName} =~ /^xmlns$/;
		my $uri_ns = $element->{Attributes}->{$key}->{NamespaceURI};
		
		my $attr = $element->{Attributes}->{$key}->{LocalName};
		my $value = $element->{Attributes}->{$key}->{Value};
		my $string = "@" . "[$attr='$value' and namespace-uri() = '" . "$uri_ns']" if defined $uri_ns and $uri_ns ne '';
		$string =  "[\@$attr=$value]" unless defined $string;
		# @foo[namespace-uri()='http://foo.example.com']
		push @{ $self->{items} }, $e . $string;
	}
}

sub end_element {
	my ( $self, $element ) = @_;
	pop @{$self->{elements}};
}

sub characters {
	my ( $self, $characters ) = @_;
	return if $characters->{Data} =~ m/^\s*$/gi;
	my $text = $characters->{Data};
	# remove leading/trailing
	$text = $self->trim($text);
	push @{ $self->{items} }, $self->peek() . "text()=$text";
}

sub start_document {
	my ( $self, $document ) = @_;

	# initialize everything
	$self->{elements} = ();
	$self->{items}    = ();
	push @{$self->{elements}}, "/";
}

sub end_document {
	my ( $self, $document ) = @_;
}

sub ignorable_whitespace {
	my ( $self, $characters ) = @_;
}

#*********************************************************************
#
#       XML-SAX 2.0 error events
#
#********************************************************************
sub fatal_error {
	my ($self) = shift;
	my $msg = $self->_format_msg(@_);
	die("Parsing XML fatally failed: $msg");
}

sub error {
	my ($self) = shift;
	my $msg = $self->_format_msg(@_);
	die("Parsing XML failed: $msg");
}

sub warning {
	my ($self) = shift;
	my $msg = $self->_format_msg(@_);
	die($msg);
}

sub _format_msg {
	my ( $self, $message ) = @_;
	return $message unless ref($message) eq 'XML::SAX::Exception::Parse';
	my $pubId = $message->{PublicId}     || '';
	my $sysId = $message->{SystemId}     || '';
	my $linNo = $message->{LineNumber}   || '?';
	my $colNo = $message->{ColumnNumber} || '?';
	my $msg   = $message->{Message}      || '';
	return "$msg [line $linNo, column $colNo] $sysId $pubId";
}

sub peek {
    my ($self) = @_;
    # my version of peek
    my $obj = pop @{$self->{elements}};
    push @{$self->{elements}}, $obj;
    return $obj;
}

sub trim {
    my ( $self, $text ) = @_;
    return $text unless defined $text;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}


1;
__END__


=head1 SUBROUTINES

=head2 new

constructs a new XML::SemanticCompare::SAX reference.
parameters (all optional) include:

=over

=item parser - the L<parser|/select_parser> to use.

=back

=cut

=head2 parse

=cut

=head2 select_parser

This subroutine allows you to select the SAX implementation that is used by this SAX parser. Argument is a scalar string.

The following options are available, but are not limited to:

=over

=item XML::LibXML - not actually a SAX engine, but emits SAX events

=item XML::LibXML::SAX - a SAX parser provided by XML::LibXML

=item XML::LibXML::SAX::Parser - another SAX parser provided by XML::LibXML; the one used by default. Not sure how different it is from XML::LibXML::SAX

=item XML::SAX::PurePerl - pure perl implementation; not very efficient.

=back

=cut

=cut
