# XML::Filter::Digest
# 
# Copyright (c) 2000 Michael Koehne <kraehe@copyleft.de>
# 
# XML::Filter::Digest is free software. You can use and redistribute
# this copy under terms of GNU General Public license.

use strict;

#------------------------------------------------------------------------------#

package XML::Filter::Digest;

use XML::XPath;
use XML::XPath::Builder;
use XML::XPath::Node;
use XML::XPath::Node::Element;
use XML::Parser::PerlSAX;

use vars qw($VERSION @ISA $METHODS $DEBUG);

$VERSION="0.06";
@ISA = qw( XML::XPath::Builder );
$METHODS = {
    start_document => 1,
    end_document => 1,
    start_element => 1,
    end_element => 1,
    characters => 1
};
$DEBUG = 0;

sub new {
    my $proto = shift;
    my $self  = ($#_ == 0) ? { %{ (shift) } } : { @_ };
    my $class = ref($proto) || $proto;

    bless $self, $class;

    die "no Handler defined" unless $self->{'Handler'};

    return $self;
}

sub parse {
    my $self = shift;

    die "no Source defined" unless $self->{'Source'};
    
    my $parser = new XML::Parser::PerlSAX(
	    'Handler' => $self,
	    'Source'  => $self->{'Source'}
	    );
    $parser->parse();

    return $self;
}

sub start_document {
    my $self = shift;

    $self->{'Methods'} = {};
    foreach (keys %$METHODS) {
	$self->{'Methods'}{$_} = 1 if $self->{'Handler'}->can($_);
    }

    $self->{'Handler'}->start_document()
        if $self->{'Methods'}{'start_document'};

    XML::XPath::Builder::start_document($self);
}

sub end_document {
    my $self = shift;
    my $result;

    my $xp = XML::XPath->new( context => $self->{DOC_Node} );
    $self->{'xp'} = $xp;
    $self->recurse( $self->{'Script'}, $self->{DOC_Node} );
    $self->{'xp'} = undef;
    $xp->cleanup();

    delete $self->{Last};
    delete $self->{Current};

    $result = $self->{'Handler'}->end_document()
    	if $self->{'Methods'}{'end_document'};
    return $result;
}

sub recurse {
    my ($self,$script,$root) = @_;

    print STDERR "script ".$script->{'name'}."=".$script->{'node'}."\n"
        if $DEBUG;

    $self->{'Handler'}->start_element( { 'Name' => $script->{'name'} } )
	if $self->{'Methods'}{'start_element'} && $script->{'name'};

    foreach my $collect (@{$script->{'_'}}) {
        print STDERR "collect ".$collect->{'name'}."=".$collect->{'node'}."\n"
            if $DEBUG;
	foreach ($self->{'xp'}->findnodes($collect->{'node'},$root)) {
	    if ($#{$collect->{'_'}}>=0) {
		$self->recurse($collect,$_);
	    } else {
		$self->{'Handler'}->start_element( { 'Name' => $collect->{'name'} } )
		    if $self->{'Methods'}{'start_element'};

#		$self->{'Handler'}->characters( { 'Data' => XML::XPath::XMLParser::string_value($_) } )
#		    if $self->{'Methods'}{'characters'};

                print STDERR "node : ",ref($_),"\n"
                    if $DEBUG;

		$self->{'Handler'}->characters( { 'Data' => $_->string_value } )
		    if $self->{'Methods'}{'characters'};

		$self->{'Handler'}->end_element( { 'Name' => $collect->{'name'} } )
		    if $self->{'Methods'}{'end_element'};
	    }
	}
    }

    $self->{'Handler'}->end_element( { 'Name' => $script->{'name'} } )
	if $self->{'Methods'}{'start_element'} && $script->{'name'};
}

#------------------------------------------------------------------------------#

package XML::Script::Digest;

use XML::Parser::PerlSAX;

sub new {
    my $proto = shift;
    my $self  = ($#_ == 0) ? { %{ (shift) } } : { @_ };
    my $class = ref($proto) || $proto;

    bless $self, $class;

    return $self;
}

sub parse {
    my $self = shift;

    die "no Source defined" unless $self->{'Source'};

    my $parser = new XML::Parser::PerlSAX(
	    'Handler' => $self,
	    'Source'  => $self->{'Source'}
	    );
    $parser->parse;

    return $self;
}

sub start_document {
    my ($self, $element) = @_;

    $self->{'!'}       = [];
    $self->{'_'}       = [];
}

sub end_document {
    my ($self, $element) = @_;

    die "non wellformed".$#{$self->{'!'}} if $#{$self->{'!'}}>=0;
    
    delete $self->{'!'};
    return $self;
}

sub start_element {
    my ($self, $element) = @_;

    if ($element->{Name} eq "collect") {
	my $name = $element->{Attributes}{'name'};
	my $node = $element->{Attributes}{'node'};

        die "collect element requires node attribute" unless $node;
#       die "collect element requires name attribute" unless $name;

	my $coll = {};

    	$coll->{'name'}=$name;
    	$coll->{'node'}=$node;
    	$coll->{'_'}=[];

	push @{$self->{'_'}}, $coll;
	push @{$self->{'!'}}, $self->{'_'};

	$self->{'_'} = $coll->{'_'};
    }
    if ($element->{Name} eq "digest") {
	my $name = $element->{Attributes}{'name'};
        die "digest element requires name attribute" unless $name;
    	$self->{'name'}=$name;
    }
}

sub end_element {
    my ($self, $element) = @_;

    if ($element->{Name} eq "collect") {
	$self->{'_'} = pop @{$self->{'!'}};
    }
}

1;

__END__

=head1 NAME

XML::Filter::Digest

=head1 SYNOPSIS

    use strict;
    use XML::Filter::Digest;
    use XML::Handler::YAWriter;
    use IO::File;

    my $digest = new XML::Filter::Digest(
	'Handler'=>
	    new XML::Handler::YAWriter(
	    'Output' => new IO::File( ">-" ),
	    'Pretty' => {
		'AddHiddenNewLine' => 1
		}
	    ),

	'Script' =>
	    new XML::Script::Digest(
	    'Source' => { 'SystemId' => $ARGV[0] }
	    )->parse(),

	'Source' => { 'SystemId' => $ARGV[1] }
	)->parse();

    0;

=head1 DESCRIPTION

Most XML tools aim to parse some simple XML and to produce some
formatted output. B<XML::Filter::Digest> aims to do the opposite.

Many formats can now be parsed by a SAX Driver. XPath offers a smart
way to write queries to XML. XML::Filter::Digest is a PerlSAX Filter
to query XML and to provide a simpler digest as a result.

XML::Filter::Digest uses its own script language that can be parsed
by B<XML::Script::Digest> to formulate these digest queries.

In fact, a digest script is well-formed XML.

The following script defines that the result XML should have a root
element called I<extract>, containing several elements called
I<section> starting from the 4th HTML header. Those section
elements contain I<id>, I<title> and I<intro> elements, which in
turn contain the XPath I<string-value> of their nodes as character
data.

    <digest name="extract">
    <collect
        name="section"
        node="//html//h2[position()&gt;3]"
        >
        <collect
            name="id"
        node="child::a/attribute::name"
        />
        <collect
            name="title"
        node="."
        />
        <collect
            name="intro"
        node="following-sibling::p[position()=1]"
        />
    </collect>
    </digest>

The digest script parser silently ignores anything other than
I<digest> elements and I<collect> elements. The I<digest>
element needs a I<name> attribute defining the name of the root
element, while the I<collect> element needs an additional
I<node> attribute defining XPath queries for nested elements.

Only a single digest element should exist within a script document,
but there is no need that the digest script be the root element of
the document. Nested within the digest element should be collect
elements. They may contain several other collect elements recursivly.

=head2 METHODS

The XML::Filter::Digest object may act as a I<Filter> to receive SAX events,
or directly as a I<Driver> if you provide a I<Source> option to the parse
method. The filter is reusable, if you arrange that the chain of I<Handler>s
is also reusable to handle multiple documents in batches. The filter requires
a Handler and a Script option before the start_document method is called.

The XML::Script::Digest object may act as a I<Handler> to receive SAX events,
or directly if you provide a Source option to the parse method. The script
object is reusable and a single script object can be used for several filter
objects.

=over

=item new

Creates a new XML::Driver::HTML object. Default options for parsing,
described below, are passed as key-value pairs or as a single hash.
Options may be changed directly in the object.

=item parse

Parses a document by embedding XML::Parser::PerlSAX. This allows you
to use XML::Filter::Digest directly as a Driver and simplifies
generating a ready-to-use XML::Script::Object.

Options, described below, are passed as key-value pairs or as a single hash.
Options passed to I<parse()> override the default options in the object for
the duration of the parse.

=item start_document

Notifies the object about the start of a new document. The object will
do its cleanup if it's reused.

=item end_document

Notifies the object about the end of the document.  Return value of
XML::Script::Digest is I<$self>, to be used as the return value of
the parse method.

XML::Filter::Digest will walk through the script object to generate
a stream of SAX events for its Handler. Return value of XML::Filter::Digest
is the return value of the end_document method of the I<Handler> object.

=back

=head2 OPTIONS

=over

=item Script

XML::Script::Digest objects can be used for several XML::Filter::Digest
objects.

=item Handler

Default SAX Handler to receive events from XML::Filter::Digest objects.

=item Source

XML::Filter::Digest and XML::Script can be used on raw XML directly, by
calling the I<parse()> method. To do this, the Source option is required
for embedding the PerlSAX parser.

The `Source' hash may contain the following parameters:

=over

=item ByteStream

The raw byte stream (file handle) containing the document.

=item String

A string containing the document.

=item SystemId

The system identifier (URI) of the document.

=item Encoding

A string describing the character encoding.

=back

If more than one of `ByteStream', `String', or `SystemId' are
present, preference is given first to `ByteStream', then
`String', then `SystemId'.

=back

=head1 NOTES

The XML::Filter::Digest is not a streaming filter, but a buffering
filter, as any processing is done by the end_document method. This
could cause the Perl interpreter to run out of memory on large XML
files. Ideally, define a I<ulimit>, to prevent the system going
offline for several minutes, till it detects that there is really
no memory to seize somewhere in the network. Adding network
swapspace ad infinitum only make things worse, so I have the
following line in my I<.bashrc>. Other operating systems offer
similar constraints.

    ulimit -v 98304 -d 98304 -m 98304

This line is ok on a single user machine with 32M ram and 128MB
swap. I can raise this value, if I know that I wanna walk the dog.

=head1 BUGS

not yet implemented:

    reuse of XML::Filter::Digest objects.

XML::XPath::Builder bug:

    XML::Filter::Digest 0.06 has been tested with XML::XPath version 1.10.
    Prior versions of XML::XPath::Builder wont work.

=head1 AUTHOR

  Michael Koehne, Kraehe@Copyleft.De
  (c) 2001 GNU General Public License

=head1 SEE ALSO

L<XML::Parser::PerlSAX> and L<XML::XPath>

=cut
