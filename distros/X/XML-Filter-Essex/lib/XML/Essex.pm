package XML::Essex;

$VERSION = 0.000_1;

=head1 NAME

XML::Essex - Essex XML processing primitives

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

=head2 Result Value

The return value will be returned to the caller.  For handlers, this is
usually a "1" for success or some other value, such as a data
structure that has been built or the result of a query.

For generators and filters, it is important that the result of the next
filter's end_document() is returned at the end of your Essex script, so
that it may be used upstream of such modules as XML::Simple.

Errors should be reported using die().

=cut

#=head2 A short word on abbreviations
#
#A goal of essex is to allow code to be as terse or verbose as
#appropriate for the job at hand.  So almost every object may be
#abbreviated.  For instance, C<start_element> may be abbreviated as
#C<start_elt> when using L<C<isa()>|/isa> to check o.
#
#Most of the examples use the abbreviated form, though you can spell
#them out longhand if you like.  Here's a list of abbreviations:
#
#    document                 doc
#    element                  elt
#    characters               chars
#    processing instruction   pi
#    namespace                ns
#    attribute                attr
#
#Class names, functions, and parameters to the Essex C<isa()>
#function/method are all encouraged to use these abbreviations.

=head2 Result Values

=for Document maintainers: if you edit this section, copy and paste it
over the first section of lib/XML/Essex/ResultValues.pod.  Thanks.

Essex is designed to Do The Right Thing for the vast majority of
uses, so it manages result values automatically unless you take
control.  Below is a set of detailed rules for how it manages
the result value for a filter's processing run, but the overview is:

=over

=item *

Filters normally do not need to manage a result.  The result from the
next filter downstream will be returned automatically, or an exception
will be thrown if an incomplete document is sent downstream.

=item *

Generators act like filters mostly, except that if a generator decides
not to send any results downstream, it should either set a result value
by calling C<result()> with it, or C<return> that result normally, just
like a handler.

=item *

Handlers should either set a result value
by calling C<result()> with it, or C<return> that result normally.

=item *

Generators, filters and handlers should all die() on unexpected
conditions and most error conditions (a FALSE or undefined result is not
necessarily an error condition for a handler).

Generators and filters generally should not return a value of their own
because this will surprise calling code which is expecting a return
value of the type that the final SAX handler returns.

=for Document maintainers: if you edit this section, copy and paste it
over the first section of lib/XML/Essex/ResultValues.pod.  Thanks.

=cut

use Carp;
use Exporter;
use Filter::Util::Call;
use UNIVERSAL;

use strict;
use vars qw( %EXPORT_TAGS @EXPORT );  ## Set by the controlling process
use XML::Essex::Constants qw( EOD );

sub EOL() { "XML::Essex: End of last document" }

{
    %EXPORT_TAGS = (
        read   => [qw(
            get
            read_from
            parse_doc
            isa
            next_event
            path
            type
            xeof
        )],
        rules  => [qw(
            on
            xvalue

            xpush
            xpop
            xset
            xadd
        )],
        write  => [qw(
            put
            write_to
            push_output_filters

            characters
            chars

            end_document
            end_doc
            end_element
            end_elt
            start_document
            start_doc
            start_element
            start_elt
            xml_decl
        )],
    );

    my %seen;
    $EXPORT_TAGS{filter} = [
        grep !$seen{$_}++,
        map @$_,
        @EXPORT_TAGS{qw( read write )}
    ];

    %seen = ();

    @EXPORT = grep !$seen{$_}++, map @$_, values %EXPORT_TAGS;

    $EXPORT_TAGS{all} = \@EXPORT;
}


sub import {
    my ( undef, @args ) = @_;

    ## Figure out whether to read, write, or do both.
    my %exports;
    $exports{$_} = 1 for
        @args
            ? map s/^://
                ? exists $EXPORT_TAGS{$_}
                    ? @{$EXPORT_TAGS{$_}}
                    : croak "Unkown export tag ':$_' for ", __PACKAGE__
                : $_, @args
            : @EXPORT;

    my $is_reader = exists $exports{get} || exists $exports{on} || exists $exports{parse_doc};
    my $is_writer = exists $exports{put};

    croak "XML::Essex not used as a reader (with :read, get(), :rules or on()) or a writer (with :write put())\n"
        unless $is_reader || $is_writer;

    my $sax_processor_type =
        ! $is_reader               ? "XML::Generator::Essex" :
        ! $is_writer               ? "XML::Handler::Essex"   :
                                     "XML::Filter::Essex";

    my $state = 0; # 0=init; 1=code; 2=pod; 3=EOF
    filter_add(
        sub {
            if ( $state == 0 ) {
                $_ = join '',
                    "XML::Essex::_init '",
                    $sax_processor_type,
                    "'; XML::Essex::_cleanup eval {";
                ++$state;
                return 1;
            }

            return 0 if $state > 2;
            my $status = filter_read;

            if ( $status > 0 && substr( $_, 0, 1 ) eq "=" ) {
                if ( $state == 1 ) {                     $state = 2 }
                elsif ( substr( $_, 0, 4 ) eq "=cut" ) { $state = 1 }
            }

            return $status if $status != 0;

            $_ .= "\n\n=cut\n" if $state == 2;
            $_ .= "\n;1};";

            $state = 3;

            return 1;
        },
    );

    goto \&Exporter::import;
}

my @self_stack;

sub _init_new {
    my ( $sax_processor_type ) = @_;

    push @self_stack, $XML::Essex::Base::self;
    my $self = $XML::Essex::Base::self = $sax_processor_type->new;
    $self->{NoExecute} = 1;

    ## The first part of XML::Essex::Base::execute();
    $self->reset;
}

sub _init {
    my ( $sax_processor_type ) = @_;
    eval "require $sax_processor_type" or croak $@;
    _init_new $sax_processor_type;
};


sub _cleanup {
    my ( $ok ) = @_;
    my $self = $XML::Essex::Base::self;

    my $x = $@;

    ## The last part of XML::Essex::Base::execute();
    my ( $ok2, $result, $result_set ) = eval {
        ( 1, $self->finish( $ok, $x ) );
    };
    $XML::Essex::Base::self = pop @self_stack;

    die $@ unless $ok2;
    return $result if $result_set;
    return 1;
}

sub _reinit {
    my $type = ref $XML::Essex::Base::self;
    _cleanup 1;
    _init_new $type;
}

=back

=head1 Exported Functions

These are exported by default, use the C<use XML::Essex ();> syntax to
avoid exporting any of these or export only the ones you want.

The following export tags are also defined:

    :read     get read_from parse_doc isa next_event path type xeof
    :rules    on
    :write    put write_to start_doc end_doc start_elt chars ...

so you can

    use XML::Essex qw( :read :rules );

for an Essex script that just handles input and uses some rules, or
even:

    use XML::Essex qw( parse_doc :rules );

for a purely rule-based script.

Importing only what you need is a little quicker and more memory
efficient, but it cal also allow XML::Essex to run more efficiently.  If
you don't import any output functions (see C<:write> above), it will not
load the output routines.  Same for the input and rule based APIs.

=over

=item get

    my $e = get;

Returns the next SAX event.  Sets $_ as an EXPERIMENTAL feature.

Throws an exception (which is silently caught outside the main code)
on end of input.

See C<isa()> and C<type()> functions and method (in
L<XML::Essex::Object>) for how to test what was just gotten.

=cut

sub get {
    my $self = $XML::Essex::Base::self;

    $self->_read_from_default unless $self->{Reader};

    $XML::Essex::Base::self->get( @_ );
}

=item read_from

    read_from \*STDIN;      ## From a filehandle
    read_from "-";          ## From \*STDIN
    read_from "foo.xml";    ## From a file or URI (URI support is parser dependant)
    read_from \$xml_string; ## From a string.
    read_from undef;        ## STDIN or files named in @ARGV, as appropriate

Tells the next get() or parse_doc() to read from the indicated source.

Calling read_from automatically disassembles the current processing chain
and builds a new one (just like Perl's open() closes an already open
filehandle).

=cut

sub XML::Essex::Base::_read_from_default {
    my $self = shift;

    if ( @ARGV || $self->{FromARGV} ) {
        $self->{FromARGV} = 1;
        die EOL."\n" unless @ARGV;
        read_from( shift @ARGV );
    }
    else {
        read_from( \*STDIN );
    }
}

## TODO: move this in to XML::Handler::Essex as a set of standard
## SAX parse_foo() APIs.
sub read_from {
    ## Shut down the old processing chain if it a Reader was already
    ## created.
    ## NOTE: This ASSumes that there is only one instance of the Essex
    ## scripting env. in play at once.  This is ok for now, but it does
    ## contradict the idea of @self_stack.  Perhaps having the source
    ## filter set a secretly named global to point us to the right
    ## $self would help.  The goal is to enable handling of multiple
    ## inputs at the same time: get from this, get from that.
    _reinit if $XML::Essex::Base::self->{Reader};

    my $self = $XML::Essex::Base::self;
    my ( $what ) = @_;

    if ( ! defined $what ) {
        return delete $self->{Reader};
    }

    $self->{Reader} = sub {
        require XML::SAX::PurePerl; ## ugh.  need XML::LibXMl to support SAX2
        my $p = XML::SAX::PurePerl->new( Handler => $self );

        my $type = ref $what;

        ## This is purely a non-threading implementation.
        ## TODO: build the parser and save the reference to be parsed, then
        ## use an appropriate driver for the parser that is called when
        ## there are no more events in @{$self->{Events}}.
        if ( ! $type ) {
            $what eq "-"
                ? $p->parse_file( \*STDIN )
                : $p->parse_uri( $what );
        }
        elsif ( $type eq "GLOB" || UNIVERSAL::isa( $what, "IO::Handle" ) ) {
            $p->parse_file( $what );
        }
        elsif ( $type eq "SCALAR" ) {
            $p->parse_string( $$what );
        }
        else {
            croak "Don't know how to read from a $type";
        }
    };
}

=item push_output_filters

Adds an output filter to the end of the current list (and before the
eventual writer).  Can be a class name (which will be C<require()>ed
unless the class can already new()) or a reference to a filter.

=cut

sub push_output_filters {
    my $self = $XML::Essex::Base::self;

    push @{$self->{OutputFilters}}, @_;
}

=item parse_doc

Parses a single document from the current input.  Morally equivalent to C<get()
while 1;> but exits normally (as opposed to throwing an exception) when the
end of document is reached.  Also slightly faster now and hopefully moreso
when optimizations can be made.

Used to read to the end of a document, primarily in rule-based processing
(L</on>).

TODO: Allow parse_doc to take rules.

=cut

sub parse_doc {
    my $self = $XML::Essex::Base::self;

    $self->_read_from_default unless $self->{Reader};

    write_to( \*STDOUT ) unless $self->{Writer};

    ## The result is undocumented; what should be returned is the
    ## normal XML::Filter::Dispatcher
    my $result;
    eval {
        $result = $self->get while 1;  ## I did say I<slightly> ;)
    };

    die $@ unless $@ eq EOD . "\n";

    return $result;
}

=item put

Output one or more events.  Usually these events are created by
constructors like C<start_elt()> (see
L<XML::Generator::Essex|XML::Generator::Essex> for details) or
are objects returned C<get()> method.

=cut

sub put {
    my $self = $XML::Essex::Base::self;

    write_to( \*STDOUT ) unless $self->{Writer};
    $self->put( @_ );
}

=item write_to

    write_to \*STDOUT;     ## To a filehandle
    write_to "-";          ## To \*STDOUT
    write_to "foo.xml";    ## To a file or URI (URI support is parser dependant)
    write_to \$xml_string; ## To a string.

Tells the next put() to write the indicated source.

=cut

sub write_to {
    my $self = $XML::Essex::Base::self;
    my ( $what ) = @_;

    croak "Can't write to an undefined output" unless defined $what;

    require XML::SAX::Writer;
    $self->{Writer} = sub {
        my $h = XML::SAX::Writer->new( Output => $what );
        for ( reverse @{$self->{OutputFilters} || [] } ) {
            unless ( ref $_ ) {
                eval "require $_" or die $@ unless $_->can( "new" );
                $_ = $_->new( Handler => $h );
            }
            else {
                $_->set_handler( $h );
            }
            $h = $_;
        }
        return $h;
    };
}

=back

=head2 Miscellaneous

=over

=item isa

    get until isa "start_elt" and $_->name eq "foo";
    $r = get until isa $r, "start_elt" and $_->name eq "foo";

Returns true if the parameter is of the indicated object type.  Tests $_
unless more than one parameter is passed.

=cut

sub isa($) {
    local $_ = shift if @_ >= 2;
    UNIVERSAL::can( $_, "isa" )
        ? $_->isa( @_ )
        : UNIVERSAL::isa( $_, @_ );
}

=item next_event

Like C<get()> (see L<below|/get>), but does not remove the next event
from the input stream.

    get "start_document::*";
    get if next_event->isa( "xml_decl" );
    ...process remainder of document...

=cut

sub next_event {
    my $self = $XML::Essex::Base::self;
    die "No XML input defined\n" unless $self->{Reader};
    $self->{Reader}->peek;
}

=item path

   get "start_element::*" until path eq "/path/to/foo:bar"

Returns the path to the current element as a string.

=cut

sub path {
    my $self = $XML::Essex::Base::self;
    return join "/", "", map $_->name, @{$self->{Stack}};
}

=for import XML::Generator::Essex/put

=item type

    get until type eq "start_document";
    $r = get until type $r eq "start_document";


Return the type name of the object.  This is the class name with a
leading XML::Essex:: stripped off.  This is a wrapper around the
event's C<type()> method.

=cut

sub type {
    my $self = $XML::Essex::Base::self;
    $self->type( @_ );
}

=item xeof

Return TRUE if the last event has been read.

=cut

sub xeof {
    my $self = $XML::Essex::Base::self;
    die "No XML input defined\n" unless $self->{Reader};
    $self->{Reader}->eof;
}

=back

=head2 Namespaces

If this section doesn't make any sense, see
L<http://www.jclark.com/xml/xmlns.htm|http://www.jclark.com/xml/xmlns.htm>
for your next dose of XML koolaid.  If it still doesn't make any sense
then ding me for writing gibberish.

Element names, attribute names, and PI targets returned by Essex are
generated in one of three forms, depending on whether the named item
has a namespace URI associated with it and whether the filter program
has mapped that namespace URI to a prefix.  You may also use any of
these three forms when passing a name to Essex:

=over

=item "id"

If an attribute has no NamespaceURI or an empty string for a
NamespaceURI, it will be returned as a simple string.

TODO: Add an option to enable this for the default namespace or
for attrs in the element's namespace.

=item "foo:id"

If the attribute is in a namespace and there is a namespace -> prefix
mapping has been declared by the filter

=item "{http://foo/}id"

If the attribute is in a namespace with no prefix mapped to it by
the filter.

=back

Namespace prefixes from the source document are ignored; there's no
telling what prefix somebody might have used.  Intercept the
start_prefix_mapping and end_prefix_mapping events to follow the weave
of source document namespace mappings.

When outputting events that belong to a namespace not in the source
document, you need to C<put()> the start_prefix_mapping and
end_prefix_mapping events manually, and be careful avoid existing
prefixes from the document if need be while doing so.  Future additions
to Essex should make this easier and perhaps automatic.

Essex lets you manage namespace mappings by mapping, hiding, and
destroying ( $namespace => $prefix ) pairs using the functions:

=over

=cut

=item namespace_map

aka: ns_map

    my $map = ns_map(
        $ns1 => $prefix1,
        $ns2 => $prefix2,
        ...
    );

Creates a new set of mappings in addition to any that are already in
effect.  If a namespace is mapped to multiple prefixes, the last one
created is used.  The mappings stay in effect until the map objected
referred to by C<$map> is destroyed.

=cut

sub ns_map {
    my $self = $XML::Essex::Base::self;
    return $self->new( @_ );
}


=back

=head2 Rule Based Processing

It is often advantageous to declare exceptional events that should
be processed as they occur in the stream rather than testing for them
explicitly everywhere they might occur in the script.  This is done
using the "on" function.

=cut

=over

=item on

    on(
        "start_document::*" => sub { warn "start of document reached" },
        "end_document::*"   => sub { warn "end of document reached"   },
    );

=for TODO
    my $rule = on $pat1 => sub { ... }, ...;
        ...time passes with rules in effect...
    disable_rule $rule;
        ...time passes with rules I<not> in effect...
    enable_rule $rule;
        ...time passes with rules in effect again...

This declares that a rule should be in effect until the end of the
document

=for TODO or it is disabled.

=for TODO Returns a handle that may be used to enable or disable all
rules passed in.

For now, this must be called before the first get() for predictable
results.

Rules remain in effect after the main() routine has exited to facilitate
pure rule based processing.

=cut

sub on {
    my $self = $XML::Essex::Base::self;
    $self->on( @_ );
}

=item xvalue

Returns the result of the expression that fired an action.  Valid only
within rules.

=cut

sub xvalue {
    my $self = $XML::Essex::Base::self;
    $self->xvalue;
}

=item xpush

Returns the result of the expression that fired an action.  Valid only
within rules.

=item xpop

Returns the result of the expression that fired an action.  Valid only
within rules.

=item xset

Returns the result of the expression that fired an action.  Valid only
within rules.

=item xadd

Returns the result of the expression that fired an action.  Valid only
within rules.

=cut

sub xpush { XML::Filter::Dispatcher::xpush( @_ ) }
sub xpop  { XML::Filter::Dispatcher::xpop( @_ ) }
sub xadd  { XML::Filter::Dispatcher::xadd( @_ ) }
sub xset  { XML::Filter::Dispatcher::xset( @_ ) }

=back

=head2 Event Constructors

These are exported by :write (in addition to being available individually).

=over

=cut

no warnings "once";

=item chars

aka: characters

=cut

sub characters {
    XML::Essex::Event::characters->new( @_ );
}

*chars = \&characters;


=item end_doc

aka: end_document

=cut

sub end_document {
    XML::Essex::Event::end_doc->new( @_ );
}

*end_doc = \&end_document;

=item end_elt

aka: end_element

=cut

sub end_element {
    XML::Essex::Event::end_element->new( @_ );
}

*end_elt = \&end_element;


=item start_doc

aka: start_document

=cut

sub start_document {
    XML::Essex::Event::start_document->new( @_ );
}


*start_doc = \&start_document;


=item start_elt

aka: start_element

=cut

sub start_element {
    XML::Essex::Event::start_element->new( @_ );
}


*start_elt = \&start_element;

=item xml_decl

=cut

sub xml_decl {
    XML::Essex::Event::xml_decl->new( @_ );
}


=back

=head1 IMPLEMENTATION NOTES

XML::Essex is a source filter that wraps from the C<use> line to the
end of the file in an eval { ... } block.

=head1 LIMITATIONS

Stay tuned.

=head1 COPYRIGHT

Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
