package XML::Filter::Dispatcher ;

$VERSION = 0.52;

=head1 NAME

XML::Filter::Dispatcher - Path based event dispatching with DOM support

=head1 SYNOPSIS

    use XML::Filter::Dispatcher qw( :all );

    my $f = XML::Filter::Dispatcher->new(
        Rules => [
            'foo'               => \&handle_foo_start_tag,
            '@bar'              => \&handle_bar_attr,

            ## Send any <foo> elts and their contents to $handler
            'snarf//self::node()'  => $handler,

            ## Print the text of all <description> elements
            'description' 
                    => [ 'string()' => sub { push @out, xvalue } ],
        ],

        Vars => {
            "id" => [ string => "12a" ],
        },
    );

=head1 DESCRIPTION

B<WARNING>: Beta code alert.

A SAX2 filter that dispatches SAX events based on "EventPath" patterns
as the SAX events arrive.  The SAX events are not buffered or converted
to an in-memory document representation like a DOM tree.  This provides
for low lag operation because the actions associated with each pattern
are executed as soon as possible, usually in an element's
C<start_element()> event method.

This differs from traditional XML pattern matching tools like
XPath and XSLT (which is XPath-based) which require the entire
document to be built in memory (as a "DOM tree") before queries can be
executed.  In SAX terms, this means that they have to build a DOM tree
from SAX events and delay pattern matching until the C<end_document()>
event method is called.

=head2 Rules

A rule is composed of a pattern and an action.  Each
XML::Filter::Dispatcher instance has a list of rules.  As SAX events are
received, the rules are evaluated and one rule's action is executed.  If
more than one rule matches an event, the rule with the highest score
wins; by default a rule's score is its position in the rule list, so
the last matching rule the list will be acted on.

A simple rule list looks like:

    Rules => [
        'a' => \&handle_a,
        'b' => \&handle_b,
    ],

=head3 Actions

There are several types of actions:

=over

=item *

CODE reference

    Rules => [
        'a' => \&foo,
        'b' => sub { print "got a <b>!\n" },
    ],

=item *

SAX handler

    Handler => $h,  ## A downstream handler
    Rules => [
        'a' => "Handler",
        'b' => $h2,    ## Another handler
    ],

=item *

undef

    Rules => [
        '//node()' => $h,
        'b' => undef,
    ],

Useful for preventing other actions for some events

=item *

Perl code

    Rules => [
        'b' => \q{print "got a <b>!\n"},
    ],

Lower overhead than a CODE reference.

B<EXPERIMENTAL>.

=back


=head2 EventPath Patterns

Note: this section describes EventPath and discusses differences between
EventPath and XPath.  If you are not familiar with XPath you may want
to skim those bits; they're provided for the benefit of people coming
from an XPath background but hopefully don't hinder others.  A working
knowledge of SAX is necessary for the advanced bits.

EventPath patterns may match the document, elements, attributes, text
nodes, comments, processing instructions, and (not yet implemented)
namespace nodes.  Patterns like this are referred to as "location paths"
and resemble Unix file paths or URIs in appearance and functionality.

Location paths describe a location (or set of locations) in the document
much the same way a filespec describes a location in a filesystem.  The
path C</a/b/c> could refer to a directory named C<c> on a filesystem or
a set of C<e<lt>cE<gt>> elements in an XML document.  In either case,
the path indicates that C<c> must be a child of C<b>, C<b> must be
<a>'s, and <a> is a root level entity.  More examples later.

EventPath patterns may also extract strings, numbers and boolean values
from a document.  These are called "expression patterns" and are only
said to match when the values they extract are "true" according to XPath
semantics (XPath truth-ness differs from Perl truth-ness, see
EventPath Truth below).  Expression patterns look
like C<string( /a/b/c )> or C<number( part-number )>, and if the result
is true, the action will be executed and the result can be retrieved
using the L<xvalue|xvalue> method.

TODO: rename xvalue to be ep_result or something.

We cover patterns in more detail below, starting with some examples.

If you'd like to get some experience with pattern matching in an
interactive XPath web site, there's a really good XPath/XSLT based
tutorial and lab at
L<http://www.zvon.org/xxl/XPathTutorial/General/examples.html|http://www.zvon.org/xxl/XPathTutorial/General/examples.html>.

=head2 Actions

Two kinds of actions are supported: Perl subroutine calls and
dispatching events to other SAX processors.  When a pattern matches, the
associated action

=head2 Examples

This is perhaps best introduced by some examples.  Here's a routine that runs a
rather knuckleheaded document through a dispatcher:

    use XML::SAX::Machines qw( Pipeline );

    sub run { Pipeline( shift )->parse_string( <<XML_END ) }
      <stooges>
        <stooge name="Moe" hairstyle="bowl cut">
          <attitude>Bully</attitude>
        </stooge>
        <stooge name="Shemp" hairstyle="mop">
          <attitude>Klutz</attitude>
          <stooge name="Larry" hairstyle="bushy">
            <attitude>Middleman</attitude>
          </stooge>
        </stooge>
        <stooge name="Curly" hairstyle="bald">
          <attitude>Fool</attitude>
          <stooge name="Shemp" repeat="yes">
            <stooge name="Joe" hairstyle="bald">
              <stooge name="Curly Joe" hairstyle="bald" />
            </stooge>
          </stooge>
        </stooge>
      </stooges>
    XML_END

=over

=item Counting Stooges

Let's count the number of stooge characters in that document.  To do that, we'd
like a rule that fires on almost all C<E<lt>stoogeE<gt>> elements:

    my $count;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge' => sub { ++$count },
            ],
        )
    );

    print "$count\n";  ## 7

Hmmm, that's one too many: it's picking up on Shemp twice since the document
shows that Shemp had two periods of stoogedom.  The second node has a
convenient C<repeat="yes"> attribute we can use to ignore the duplicate.

We can ignore the duplicate element by adding a "predicate"
expression to the pattern to accept only those elements with no C<repeat>
attribute.  Changing that rule to

                'stooge[not(@repeat)]' => ...

or even the more pedantic

                'stooge[not(@repeat) or not(@repeat = "yes")]' => ...

yields the expected answer (6).

=item Hairstyles and Attitudes

Now let's try to figure out the hairstyles the stooges wore.  To extract 
just the names of hairstyles, we could do something like:

    my %styles;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge' => [
                    'string( @hairstyle )' => sub { $styles{xvalue()} = 1 },
                ],
            ],
        )
    );

    print join( ", ", sort keys %styles ), "\n";

which prints "bald, bowl cut, bushy, mop".  That rule extracts the text
of each C<hairstyle> attribute and the C<xvalue()> returns it.

The text contents of elements like C<E<lt>attitudesE<gt>> can also be
sussed out by using a rule like:

                'string( attitude )' => sub { $styles{xvalue()} = 1 },

which prints "Bully, Fool, Klutz, Middleman".

Finally, we might want to correlate hairstyles and attitudes by using
a rule like:

    my %styles;

    run(
        XML::Filter::Dispatcher->new(
            Rules => [
                'stooge' => [
                    'concat(@hairstyle,"=>",attitude)' => sub {
                        $styles{$1} = $2 if xvalue() =~ /(.+)=>(.+)/;
                    },
                ],
            ],
        )
    );

    print map "$_ => $styles{$_}\n", sort keys %styles;

which prints:

    bald => Fool
    bowl cut => Bully
    bushy => Middleman
    mop => Klutz

=back

=head3 Examples that need to be written

=over

=item * Examples for accumulating data

=item * Advanced pattern matching examples

=back

=cut

=head2 Sending Trees and Events to Other SAX Handlers

When a blessed object C<$handler> is provided as an action for a rule:

    my $foo = XML::Handler::Foo->new();
    my $d = XML::Filter::Dispatcher->new(
        Rules => [
           'foo' => $handler,
        ],
        Handler => $h,
    );

the selected SAX events are sent to C<$handler>.

=head3 Element Forwarding

If the event is selected is a C<start_document()> or C<start_element()>
event and it is selected without using the C<start-document::> or
C<start-element::> axes, then the handler (C<$foo>) replaces the
existing handler of the dispatcher (C<$h>) until after the corresponding
C<end_...()> event is received.

This causes the entire element (C<E<lt>fooE<gt>>) to be sent to the
temporary handler (C<$foo>).  In the example, each C<E<lt>fooE<gt>>
element will be sent to C<$foo> as a separate document, so if
(whitespace shown as underscores)

    <root>
    ____<foo>....</foo>
    ____<foo>....</foo>
    ____<foo>....</foo>
    </root>

is fed in to C<$d>, then C<$foo> will receive 3 separate

    <foo>...</foo>

documents (C<start_document()> and C<end_document()> events are emitted
as necessary) and C<$h> will receive a single document without any
C<E<lt>fooE<gt>> elements:

    <root>
    ____
    ____
    ____
    </root>

This can be useful for parsing large XML files in small chunks, often in
conjunction with L<XML::Simple|XML::Simple> or
L<XML::Filter::XSLT|XML::Filter::XSLT>.

But what if you don't want C<$foo> to see three separate documents?
What if you're excerpting chunks of a document to create another
document?  This can be done by telling the dispatcher to emit the main
document to C<$foo> and using rules with an action of C<undef> to elide
the events that are not wanted.  This setup:

    my $foo = XML::Handler::Foo->new();
    my $d = XML::Filter::Dispatcher->new(
        Rules => [
           '/'   => $foo,
           'bar' => undef,
           'foo' => $foo,
        ],
        Handler => $h,
    );

, when fed this document:

    <root>
    __<bar>hork</bar>
    __<bar>
    __<foo>....</foo>
    __<foo>....</foo>
    __<foo>....</foo>
    __<hmph/>
    __</bar>
    __<hey/>
    </root>

results in C<$foo> receiving a single document of input looking like
this:

    <root>
    __
    __<foo>....</foo>
    __<foo>....</foo>
    __<foo>....</foo>
    __<hey/>
    </root>

XML::Filter::Dispatcher keeps track of each handler and sends
C<start_document()> and C<end_document()> at the appropriate times, so
the C<E<lt>fooE<gt>> elements are "hoisted" out of the C<E<lt>barE<gt>>
element in this example without any untoward C<..._document()> events.

B<TODO>: support forwarding to multiple documents at a time.  At the
present, using multiple handlers for the same event is not supported.

=head3 Discrete Event Forwarding

B<TODO>: At the moment, selecting and forwarding individual events is
not supported.  When it is, any events other than those covered above
will be forwarded individually

=head2 Tracing

XML::Filter::Dispatcher checks when it is first loaded to see if
L<Devel::TraceSAX|Devel::TraceSAX> is loaded.  If so, it will emit tracing
messages.  Typical use looks like

    perl -d:Devel::TraceSAX script_using_x_f_dispatcher

If you are C<use()>ing Devel::TraceSAX in source code, make sure that it is
loaded before XML::Filter::Dispatcher.

TODO: Allow tracing to be enabled/disabled independantly of Devel::TraceSAX.

=head2 Namespace Support

XML::Filter::Dispatcher offers namespace support in matching and by
providing functions like local-name().  If the documents you are
processing don't use namespaces, or you only care about elements and
attributes in the default namespace (ie without a "foo:" namespace
prefix), then you need not worry about engaging
XML::Filter::Dispatcher's namespace support.  You do need it if your
patterns contain the C<foo:*> construct (that C<*> is literal).

To specify the namespaces, pass in an option like

    Namespaces => {
       ""      => "uri0",   ## Default namespace
       prefix1 => "uri1",
       prefix2 => "uri2",
    },

Then use C<prefix1:> and C<prefix2:> whereever necessary in patterns.

A missing prefix on an element always maps to the default namespace URI,
which is "" by default.  Attributes are treated likewise, though this
is probably a bug.

If your patterns contain prefixes (like the C<foo:> in C<foo:bar>), and
you don't provide a Namespaces option, then the element names will
silently be matched literally as "foo:bar", whether or not the source
document declares namespaces.  B<This may change, as it may cause too
much user confusion>.

XML::Filter::Dispatcher follows the XPath specification rather literally
and does not allow C<:*>, which you might think would match all nodes in
the default namespace.  To do this, ass a prefixe for the default
namespace URI:

    Namespaces => {
       ""        => "uri0",   ## Default namespace
       "default" => "uri0",   ## Default namespace
       prefix1   => "uri1",
       prefix2   => "uri2",
    },

then use "default:*" to match it.

B<CURRENT LIMITAION>: Currently, all rules must exist in the same namespace
context.  This will be changed when I need to change it (contact me
if you need it changed).  The current idear is to allow a special
function "Namespaces( { .... }, @rules )" that enables a temporary
namespace context, although abbreviated forms might be possible.

=head2 EventPath Dialect

"EventPath" patterns are that large subset of XPath patterns that can be
run in a SAX environment without a DOM.  There are a few crucial
differences between the environments that EventPath and XPath each
operate in.

XPath operates on a tree of "nodes" where each entity in an XML document
has only one corresponding node.  The tree metaphor used in XPath has a
literal representation in memory.  For instance, an element
C<E<lt>fooE<gt>> is represented by a single node which contains other
nodes.

EventPath operates on a series of events instead of a tree of nodes.
For instance elements, which are represented by nodes in DOM trees, are
represented by two event method calls, C<start_element()> and
C<end_element()>.  This means that EventPath patterns may match in a
C<start_...()> method or an C<end_...()> method, or even both if you try
hard enough.

The only times an EventPath pattern will match in an
C<end_...()> method are when the pattern refers to an element's contents
or it uses the XXXX function (described below) to do so
intentionally.

The tree metaphor is used to arrange and describe the
relationships between events.  In the DOM trees an XPath engine operates
on, a document or an element is represented by a single entity, called a
node.  In the event streams that EventPath operates on, documents and
element

=head3 Why EventPath and not XPath?

EventPath is not a standard of any kind, but XPath can't cope with
situations where there is no DOM and there are some features that
EventPath need (start_element() vs. end_element() processing for
example) that are not compatible with XPath.

Some of the features of XPath require that the source document be fully
translated in to a DOM tree of nodes before the features can be evaluated.
(Nodes are things like elements, attributes, text, comments, processing
instructions, namespace mappings etc).

These features are not supported and are not likely to be, you might
want to use L<XML::Filter::XSLT|XML::Filter::XSLT> for "full" XPath
support (tho it be in an XSLT framework) or wait for
L<XML::TWIG|XML::TWIG> to grow SAX support.

Rather than build a DOM, XML::Filter::Dispatcher only keeps a bare
minimum of nodes: the current node and its parent, grandparent, and so
on, up to the document ("root") node (basically the /ancestor-or-self::
axis).  This is called the "context stack", although you may not need to
know that term unless you delve in to the guts.

=head3 EventPath Truth

EventPath borrows a lot from XPath including its notion of truth.
This is different from Perl's notion of truth; presumably to make
document processing easier.  Here's a table that may help, the
important differences are towards the end:

    Expression      EventPath  XPath    Perl
    ==========      =========  =====    ====
    false()         FALSE      FALSE    n/a (not applicable)
    true()          TRUE       TRUE     n/a
    0               FALSE      FALSE    FALSE
    -0              FALSE**    FALSE    n/a
    NaN             FALSE**    FALSE    n/a (not fully, anyway)
    1               TRUE       TRUE     TRUE
    ""              FALSE      FALSE    FALSE
    "1"             TRUE       TRUE     TRUE

    "0"             TRUE       TRUE     FALSE

 * To be regarded as a bug in this implementation
 ** Only partially implemented/supported in this implementation

Note: it looks like XPath 2.0 is defining a more workable concept
for document processing that uses something resembling Perl's empty
lists, C<()>, to indicate empty values, so C<""> and C<()> will be
distinct and C<"0"> can be interpreted as false like in Perl.  XPath2
is I<not> provided by this module yet and won't be for a long time 
(patches welcome ;).

=head3 EventPath Examples

All of this means that only a portion of XPath is available.  Luckily,
that portion is also quite useful.  Here are examples of working XPath
expressions, followed by known unimplemented features.

TODO: There is also an extension function available to differentiate between
C<start_...> and C<end_...> events.  By default

=head2 Examples

 Expression          Event Type      Description (event type)
 ==========          ==========      ========================
 /                   start_document  Selects the document node

 /a                  start_element   Root elt, if it's "<a ...>"

 a                   start_element   All "a" elements

 b//c                start_element   All "c" descendants of "b" elt.s

 @id                 start_element   All "id" attributes

 string( foo )       end_element     matches at the first </foo> or <foo/>
                                     in the current element;
                                     xvalue() returns the
                                     text contained in "<foo>...</foo>"

 string( @name )     start_element   the first "name" attributes;
                                     xvalue() returns the
                                     text of the attribute.

=head2 Methods and Functions

There are several APIs provided: general, xstack, and EventPath
variable handling.

The general API provides C<new()> and C<xvalue()>, C<xvalue_type()>, and
C<xrun_next_action()>.

The variables API provides C<xset_var()> and C<xget_var()>.

The xstack API provides C<xadd()>, C<xset()>, C<xoverwrite()>,
C<xpush()>, C<xpeek()> and C<xpop()>.

All of the "xfoo()" APIs may be called as a method or,
within rule handlers, called as a function:

    $d = XML::Filter::Dispatcher->new(
        Rules => [
            "/" => sub {
                xpush "foo\n";
                print xpeek;        ## Prints "foo\n"

                my $self = shift;
                print $self->xpeek; ## Also prints "foo\n"
            },
        ],
    );

    print $d->xpeek;                ## Yup, prints "foo\n" as well.

This dual nature allows you to import the APIs as functions and call them
using a concise function-call style, or to leave them as methods and
use object-oriented style.

Each call may be imported by name:

   use XML::Filter::Dispatcher qw( xpush xpeek );

or by one of three API category tags:

   use XML::Filter::Dispatcher ":general";    ## xvalue()
   use XML::Filter::Dispatcher ":variables";  ## xset_var(), xget_var()
   use XML::Filter::Dispatcher ":xstack";     ## xpush(), xpop(), and xpeek()

or en mass:

   use XML::Filter::Dispatcher ":all";

=cut

require Exporter;
*import = \&Exporter::import;

BEGIN {
    my @general_API   = qw( xvalue xvaluetype xvalue_type xevent_type xrun_next_action );
    my @xstack_API = qw( xpeek xpop xadd xset xoverwrite xpush xstack_empty xstack_max );
    my @variables_API = qw( xset_var xget_var );
    @EXPORT_OK = ( @general_API, @variables_API, @xstack_API );
    %EXPORT_TAGS = (
        all       => \@EXPORT_OK,
        general   => \@general_API,
        xstack    => \@xstack_API,
        autostack => \@xstack_API,  # deprecated
        variables => \@variables_API,
    );
}


use strict ;

use Carp qw( confess );
sub croak { goto &Carp::confess }

#use XML::SAX::Base;
#use XML::NamespaceSupport;
use XML::SAX::EventMethodMaker qw( compile_missing_methods sax_event_names );

use constant is_tracing => defined $Devel::TraceSAX::VERSION;
# Devel::TraceSAX does not work under perl5.8.0
#use constant is_tracing => 1;
#sub emit_trace_SAX_message { warn @_ };

use constant show_buffer_highwater =>
    $ENV{XFDSHOWBUFFERHIGHWATER} || 0;

BEGIN {
    eval( is_tracing
        ? 'use Devel::TraceSAX qw( emit_trace_SAX_message ); 1'
        : 'sub emit_trace_SAX_message; 1'
    ) or die $@;
}


## TODO: Prefix all of the hash keys in $self with XFD_ to avoid
## conflict with X::S::B and subclasses / hander CODE.

## TODO: local $_ = xvalue before calling in to a sub

##
## $ctx->{Vars}  a HASH of variables passed in from the parent context
##               (or the Perl world in the doc root node context).  Set
##               in all child contexts.
##
## $ctx->{ChildVars} a HASH of variables set in by this node, passed
##                   on to all child contexts, but erased before this
##                   node's siblings can see it.
##

=head1 General API

=over

=item new

    my $f = XML::Filter::Dispatcher->new(
        Rules => [   ## Order is significant
            "/foo/bar" => sub {
                ## Code to execute
            },
        ],
    );

Must be called as a method, unlike other API calls provided.

=cut

my @every_names = qw(
    attribute
    characters
    comment
    processing_instruction
    start_element
    start_prefix_mapping
);


sub new {
    my $proto = shift ;
    my %handlers;
    my $self = bless {
        FoldContstants => 1,
        Handlers => {
            Handler => undef,  ## Setting this here always allows "Handler"
                               ## in actions, so that a call to
                               ## set_handler( $h ) can be used when the
                               ## handler is not set when new() is called.
        },
    }, ref $proto || $proto;

    while ( @_ ) {
        my ( $key, $value ) = ( shift, shift );

        if ( substr( $key, -7 ) eq "Handler" ) {
            $self->{Handlers}->{$key} = $value;
        }
        elsif ( $key eq "Handlers" ) {
            $self->{Handlers}->{$_} = $value->{$_}
                for keys %$value;
        }
        else {
            $self->{$key} = $value;
        }

    }

    $self->{Debug} ||= $ENV{XFDDEBUG} || 0;

    $self->{SortAttributes} = 1
        unless defined $self->{SortAttributes};
    $self->{SetXValue} = 1
        unless defined $self->{SetXValue};


    $self->{Rules} ||= [];
#    $self->{Rules} = [ %{$self->{Rules}} ]
#        if ref $self->{Rules} eq "HASH";

    my $doc_ctx = $self->{DocCtx} = $self->{CtxStack}->[0] = {};
    $doc_ctx->{ChildCtx} = {};
    
    for ( keys %{$self->{Vars}} ) {
        $self->xset_var( $_, @{$self->{Vars}->{$_}} );
    }

    if ( @{$self->{Rules}} ) {
        require XML::Filter::Dispatcher::Compiler;
        my $c = XML::Filter::Dispatcher::Compiler->new( %$self );

        my $code;
        
        ## Use the internal use only compiler internals.
        ( $code, $self->{Actions} ) = $c->_compile;

        $self->{DocSub} = eval $code;
        if ( ! $self->{DocSub} ) {
            my $c = $code;
            my $ln = 1;
            $c =~ s{^}{sprintf "%4d|", $ln++}gme;
            die $@, $c;
        }

    }

    return $self ;
}


=item xvalue

    "string( foo )" => sub { my $v = xvalue        }, # if imported
    "string( foo )" => sub { my $v = shift->xvalue }, # if not

Returns the result of the last EventPath expression evaluated; this is
the result that fired the current rule.  The example prints all text
node children of C<E<lt>fooE<gt>> elements, for instance.

For matching expressions, this is equivalent to $_[1] in action
subroutines.

=cut

sub xvalue() {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );

    return $XFD::cur_self->{XValue};
    exists $XFD::cur_self->{XValue}
        ? $XFD::cur_self->{XValue}
        : $XFD::ctx && $XFD::ctx->{Node};
}

=item xvalue_type

Returns the type of the result returned by xvalue.  This is either a SAX
event name or "attribute" for path rules ("//a"), or "" (for a string),
"HASH" for a hash (note that struct() also returns a hash; these types
are Perl data structure types, not EventPath types).

This is the same as xeventtype for all rules that don't evaluate
functions like "string()" as their top level expression.

=cut

sub xvalue_type() {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );

    return $XFD::cur_self->{XValue} == $XFD::ctx->{Node}
        ? $XFD::ctx->{EventType}
        : ref $XFD::ctx->{Node};
}
sub xvaluetype() { goto \&xvalue_type } ## deprecated syntax

=item xeventtype

Returns the type of the current SAX event.

=cut

sub xevent_type() {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );

    return $XFD::ctx->{EventType};
}

=item xrun_next_action

Runs the next action for the current node.  Ordinarily,
XML::Filter::Dispatcher runs only one action per node; this allows an
action to call down to the next action.

This is especially useful in filters that tweak a document on the way
by.  This tweaky sort of filter establishes a default "pass-through"
rule and then additional override rules to tweak the values being
passed through.

Let's suppose you want to convert some mtimes from seconds since the
epoch to a human readable format.  Here's a set of rules that might
do that:

    Rules => [
        'node()' => "Handler",  ## Pass everything through by default.

        'file[@mtime]' => sub { ## intercept and tweak the node.
            my $attr = $_[1]->{Attributes}->{"{}mtime"};

            ## Localize the changes: never assume that it is safe
            ## to alter SAX elements on the way by in a general purpose
            ## filter.  Some smart aleck might send the same events
            ## to another filter with a Tee fitting or even back
            ## through your filter multiple times from a cache.
            local $attr->{Value} = localtime $attr->{Value};

            ## Now that the changes are localised, fall through to
            ## the default rule.
            xrun_next_action;

            ## We could emit other events here as well, but need not
            ## in this example.
         },
    ],

=cut

sub xrun_next_action() {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    $XFD::cur_self->_execute_next_action;
}


=back

=head2 EventPath Variables

EventPath variables may be set in the current context using
C<xset_var()>, and accessed using C<xget_var()>.  Variables set in a
given context are visible to all child contexts.  If you want a variable
to be set in an enclosed context and later retrieved in an enclosing
context, you must set it in the enclosing context first, then alter it
in the enclosed context, then retrieve it.

EventPath variables are typed.

EventPath variables set in a context are visible within that context and
all enclosed contexts, but not outside of them.

=cut

=over

=item xset_var

    "foo" => sub { xset_var( bar => string => "bingo" ) }, # if imported
    "foo" => sub { shift->xset_var( bar => boolean => 1 ) },

Sets an XPath variables visible in the current context and all child
contexts.  Will not be visible in parent contexts or sibling contexts.

Legal types are C<boolean>, C<number>, and C<string>.  Node sets and
nodes are unsupported at this time, and "other" types are not useful
unless you work in your own functions that handle them.

Variables are visible as C<$bar> variable references in XPath expressions and
using xget_var in Perl code.  Setting a variable to a new value temporarily
overrides any existing value, somewhat like using Perl's C<local>.

=cut

sub xset_var {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ ) ? shift : $XFD::cur_self;
    croak
        "Wrong number of parameters (" . @_ . ") passed to xset_var, need 3.\n"
        if @_ != 3;

    my ( $name, $type, $value ) = @_;
    croak "undefined type passed to xset_var\n" unless defined $type;
    croak "undefined name passed to xset_var\n" unless defined $name;
    croak "undefined value passed to xset_var\n" unless defined $name;

    ## TODO: rename the type non-classes to st other than "string", etc.
    $self->{CtxStack}->[-1]->{Vars}->{$name} = bless \$value, $type;
}


## Used in compiled XPath exprs only; only minimal safeties engaged.
sub _look_up_var {
    my $self = shift;
    my ( $vname ) = @_;

    my $ctx = $self->{CtxStack}->[-1];
    return $ctx->{Vars}->{$vname} if exists $ctx->{Vars}->{$vname};

    die "Unknown variable '\$$vname' referenced in XPath expression\n";
}


=item xget_var

    "bar" => sub { print xget_var( "bar" ) }, # if imported
    "bar" => sub { print shift->xget_var( "bar" ) },

Retrieves a single variable from the current context.  This may have
been set by a parent or by a previous rule firing on this node, but
not by children or preceding siblings.

Returns C<undef> if the variable is not set (or if it was set to undef).

=cut

sub xget_var {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ ) ? shift : $XFD::cur_self;
    croak "No variable name passed to xget_var.\n"
        unless @_;
    croak "More than one variable name passed to xget_var.\n"
        unless @_ == 1;

    my ( $vname ) = @_;

    croak "Undefined variable name passed to xget_var.\n"
        unless defined $vname;

    my $ctx = $self->{CtxStack}->[-1];
    return
        exists $ctx->{Vars}->{$vname}
            ? ${$ctx->{Vars}->{$vname}}
            : undef;
}


=item xget_var_type

    "bar" => sub { print xget_var_type( "bar" ) }, # if imported
    "bar" => sub { shift->xget_var_type( "bar" ) },

Retrieves the type of a variable from the current context. This may have
been set by a parent or by a previous rule firing on this node, but
not by children or preceding siblings.

Returns C<undef> if the variable is not set.

=cut

sub xget_var_type {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ ) ? shift : $XFD::cur_self;
    croak "No variable name passed to xget_var_type.\n"
        unless @_;
    croak "More than one variable name passed to xget_var_type.\n"
        unless @_ == 1;

    my ( $vname ) = @_;

    croak "Undefined variable name passed to xget_var.\n"
        unless defined $vname;

    my $ctx = $self->{CtxStack}->[-1];
    return
        exists $ctx->{Vars}->{$vname}
            ? ref $ctx->{Vars}->{$vname}
            : undef;
}

=back

=head2 Handlers

XML::Filter::Dispatcher allows you to register handlers using
C<set_handler()> and C<get_handler()>, and then to refer to them
by name in actions.  These are part of the "general API".

You may use any string for handler names that you like, including
strings with spaces.  It is wise to avoid those standard, rarely used
handlers recognized by parsers, such as:

    DTDHandler
    ContentHandler
    DocumentHandler
    DeclHandler
    ErrorHandler
    EntityResolver
    LexicalHandler

unless you are using them for the stated purpose.  (List taken from
L<XML::SAX::EventMethodMaker|XML::SAX::EventMethodMaker>).

Handlers may be set in the constructor in two ways: by using a name
ending in "Handler" and passing it as a top level option:

    my $f = XML::Filter::Dispatcher->new(
        Handler => $h,
        FooHandler => $foo,
        BarHandler => $bar,
        Rules => [
           ...
        ],
    );

Or, for oddly named handlers, by passing them in the Handlers hash:

    my $f = XML::Filter::Dispatcher->new(
        Handlers => {
            Manny => $foo,
            Moe   => $bar,
            Jack  => $bat,
        },
        Rules => [
           ...
        ],
    );

Once declared in new(), handler names can be 
used as actions.  The "well known" handler name "Handler" need not be
predeclared.

For exampled, this forwards all events except the C<start_element()>
and C<end_element()> events for the root element's children, thus
"hoisting" everything two levels below the root up a level:

    Rules => [
        '/*/*'   => undef,
        'node()' => "Handler",
    ],

By default, no events are forwarded to any handlers: you must send
individual events to an individual handlers.

Normally, when a handler is used in this manner, XML::Filter::Dispatcher
makes sure to send C<start_document()> and C<end_document()> events to
it just before the first event and just after the last event.  This
prevents sending the document events unless a handler actually receives
other events, which is what most people expect (the alternative would be
to preemptively always send a C<start_document()> to all handlers when
when the dispatcher receives its C<start_document()>: ugh).

To disable this for all handlers, pass the C<SuppressAutoStartDocument
=> 1> option.

=over

=item set_handler

    $self->set_handler( $handler );
    $self->set_handler( $name => $handler );

=cut

sub set_handler {
    my $self = shift;
    my $name = @_ > 1 ? shift : "Handler";
    $self->{Handlers}->{$name} = shift;
}

=item get_handler

    $self->set_handler( $handler );
    $self->set_handler( $name => $handler );

=cut

sub get_handler {
    my $self = shift;
    my $name = @_ > 1 ? shift : "Handler";
    return $self->{Handlers}->{$name}
        if exists $self->{Handlers}->{$name}
}

=back


=head2 The xstack

The xstack is a stack mechanism provided by XML::Filter::Dispatcher that
is automatically unwound after end_element, end_document, and all other
events other than start_element or start_document.  This sounds
limiting, but it's quite useful for building data structures that mimic
the structure of the XML input.  I've found this to be common when
dealing with data structures in XML and a creating nested hierarchies of
objects and/or Perl data structures.

Here's an example of how to build and return a graph:

    use Graph;

    my $d = XML::Filter::Dispatcher->new(
        Rules => [
            ## These two create and, later, return the Graph object.
            'graph'        => sub { xpush( Graph->new ) },
            'end::graph'   => \&xpop,

            ## Every vertex must have a name, so collect in and add it
            ## to the Graph object using its add_vertex( $name ) method.
            'vertex'       => [ 'string( @name )' => sub { xadd     } ],

            ## Edges are a little more complex: we need to collect the
            ## from and to attributes, which we do using a hash, then
            ## pop the hash and use it to add an edge.  You could
            ## also use a single rule, see below.
            'edge'         => [ 'string()'        => sub { xpush {} } ],
            'edge/@*'      => [ 'string()'        => sub { xset     } ],
            'end::edge'    => sub { 
                my $edge = xpop;
                xpeek->add_edge( @$edge{"from","to"} );
            },
        ],
    );

    my $graph = QB->new( "graph", <<END_XML )->playback( $d );
    <graph>
        <vertex name="0" />
        <edge from="1" to="2" />
        <edge from="2" to="1" />
    </graph>
    END_XML

    print $graph, $graph->is_sparse ? " is sparse!\n" : "\n";

should print "0,1-2,2-1 is sparse!\n".

This is good if you can tell what object to add to the stack before
seeing content.  Some XML parsing is more general than that: if you see
no child elements, you want to create one class to contain just
character content, otherwise you want to add a container class to
contain the child nodes.

An faster alternative to the 3 edge rules relies on the fact that
SAX's start_element events carry the attributes, so you can actually
do a single rule instead of the three we show above:

            'edge' => sub {
                xpeek->add_edge(
                    $_[1]->{Attributes}->{"{}from"}->{Value},
                    $_[1]->{Attributes}->{"{}to"  }->{Value},
                );
            },

=over

=item xpush

Push values on to the xstack.  These will be removed from the xstack at
the end of the current element.  The topmost item on the
xstack is available through the peek method.  Elements xpushed before
the first element (usually in the C<start_document()> event) remain on
the stack after the document has been parsed and a call like

   my $elt = $dispatcher->xpop;

can be used to retrieve them.

=cut

sub xpush {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    emit_trace_SAX_message "EventPath: xpush()ing ", @_ if is_tracing;
    push @{$XFD::cur_self->{XStack}}, map( { "#elt" => $_ }, @_ );
}

=item xadd

Tries to add a possibly named item to the element on the top of the
stack and push the item on to the stack.  It makes a guess about how to
add items depending on what the current top of the stack is.

    xadd $name, $new_item;

does this:

    Top of Stack    Action
    ============    ======
    scalar          xpeek                  .= $new_item;
    SCALAR ref      ${xpeek}               .= $new_item;
    ARRAY ref       push @{xpeek()},          $new_item;
    HASH ref        push @{xpeek->{$name}} =  $new_item;
    blessed object  xpeek->$method( $new_item );

The $method in the last item is one of (in order) "add_$name",
"push_$name", or "$name".

After the above action, an

    xpush $new_item;

is done.

$name defaults to the LocalName of the current node if it is an
attribute or element, so

    xadd $foo;

will DWYM.  TODO: search up the current node's ancestry for a LocalName
when handling other event types.

If no parameters are provided, xvalue is used.

If the stack is empty, it just xpush()es on the stack.

=cut

sub xadd {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my $name = @_ > 1
        ? shift
        : do {
            croak "$XFD::ctx->{EventType} has no LocalName"
                unless exists $XFD::ctx->{Node}->{LocalName}
                       && defined exists $XFD::ctx->{Node}->{LocalName};
            croak "$XFD::ctx->{EventType} a LocalName of ''"
                unless length $XFD::ctx->{Node}->{LocalName};
            $XFD::ctx->{Node}->{LocalName};
        };

    my $new_item = @_ ? shift : $XFD::cur_self->xvalue;

    emit_trace_SAX_message "EventPath: xadd()ing ", $name, " => ", $new_item if is_tracing;

    if ( @{$XFD::cur_self->{XStack}} ) {
        my $e = $XFD::cur_self->{XStack}->[-1];
        my $top = $e->{"#elt"};
        my $t = ref $top;
        my $meth;

        if ( $t eq "" ) {
            $XFD::cur_self->{XStack}->[-1]->{"#elt"} .= ""; 
            $e->{scalar}++;
        }
        elsif ( $t eq "SCALAR" ) {
            $e->{scalar}++;
            $$top .= ""; 
        }
        elsif ( $t eq "ARRAY" ) {
            $e->{scalar}++;
            push @$top, $new_item;
        }
        elsif ( $t eq "HASH" ) {
            croak
                "element '",
                $name,
                "' of the HASH on top of the xstack is a ",
                do {
                    my $t = ref $top->{$name};
                    ! $t ? "scalar" : "$t reference";
                },
                ", not an ARRAY ref"
                if defined $top->{$name} && ! ref $top->{$name};
            push @{$top->{$name}}, $new_item;
            $e->{$name}++;
        }
        ## See if it's a blessed object that can add thingamies"
        elsif ( $meth = ( 
               UNIVERSAL::can( $top, "add_$name" )
            || UNIVERSAL::can( $top, "push_$name" )
            || UNIVERSAL::can( $top, "add" )
        ) ) {
            $top->$meth( $new_item );
            $e->{$name}++;
        }
        else {
            croak "don't know how to xadd() a '",
                ref( $new_item ) || "scalar", 
                "' ",
                defined $name ? $name : "item",
                " to a '$t' (which is what is on the top of the xstack)";
        }

    }

    $XFD::cur_self->xpush( $new_item )
        if ref $new_item && ref $new_item ne "SCALAR";
    return $new_item;
}


=item xset

Like C<xadd()>, but tries to set a named value.  Dies if the value is
already defined (so duplicate values aren't silently ignored).

    xset $name, $new_item;

does this:

    Top of Stack    Action
    ============    ======
    scalar          xpeek                  = $new_item;
    SCALAR ref      ${xpeek}               = $new_item;
    HASH ref        xpeek->{$name}         = $new_item;
    blessed object  xpeek->$name( $new_item );

Trying to xset any other types results in an exception.

After the above action (except when the top is a scalar or SCALAR ref), an

    xpush $new_item;

is done so that more may be added to the item.

$name defaults to the LocalName of the current node if it is an
attribute or element, so

    xset $foo;

will DWYM.  TODO: search up the current node's ancestry for a LocalName
when handling other event types.

If no parameters are provided, xvalue is used.

=cut

sub xset {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my $name = @_ > 1
        ? shift
        : do {
            croak "$XFD::ctx->{EventType} has no LocalName"
                unless exists $XFD::ctx->{Node}->{LocalName}
                       && defined exists $XFD::ctx->{Node}->{LocalName};
            croak "$XFD::ctx->{EventType} has a LocalName of ''"
                unless length $XFD::ctx->{Node}->{LocalName};
            $XFD::ctx->{Node}->{LocalName};
        };


    my $new_item = @_ ? shift : $XFD::cur_self->xvalue;
    emit_trace_SAX_message "EventPath: xset()ing ", $name, " => ", $new_item if is_tracing;

    unless ( @{$XFD::cur_self->{XStack}} ) {
        $XFD::cur_self->xpush( $new_item );
    }
    else {
        my $e = $XFD::cur_self->{XStack}->[-1];
        my $top = $e->{"#elt"};
        my $t = ref $top;
        my $meth;

        if ( $t eq "" ) {
            croak "already xset() scalar on top of xstack"
                if $e->{scalar}++;
            $e->{"#elt"} = $new_item; 
        }
        elsif ( $t eq "SCALAR" ) {
            croak "already xset() SCALAR reference on top of xstack"
                if $e->{scalar}++;
            $$top = $new_item; 
        }
        elsif ( $t eq "HASH" ) {
            croak "already xset() element '$name' of HASH on top of xstack"
                if $e->{$name}++;
            $top->{$name} = $new_item;
        }
        ## See if it's a blessed object that can add thingamies"
        elsif (
            ( $meth = UNIVERSAL::can( $top, $name ) )
            || ( $meth = UNIVERSAL::can( $top, "set_$name" ) )
        ) {
            croak "already xset() accessor $name() of ", ref $top, " on top of xstack"
                if $e->{$name}++;
            $top->$meth( $new_item );
        }
        else {
            croak "don't know how to xset() $name for a '$t' (which is what is on the top of the xstack)";
        }

        $XFD::cur_self->xpush( $new_item )
            if ref $new_item && ref $new_item ne "SCALAR";
    }

    return $new_item;
}



=item xoverwrite

Exactly like xset but does not complain if the value has already been
xadd(), xset() or xoverwrite().

=cut

sub xoverwrite {
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my $name = @_ > 1
        ? shift
        : do {
            croak "$XFD::ctx->{EventType} has no LocalName"
                unless exists $XFD::ctx->{Node}->{LocalName}
                       && defined exists $XFD::ctx->{Node}->{LocalName};
            croak "$XFD::ctx->{EventType} a LocalName of ''"
                unless length $XFD::ctx->{Node}->{LocalName};
            $XFD::ctx->{Node}->{LocalName};
        };


    my $new_item = @_ ? shift : $XFD::cur_self->xvalue;
    emit_trace_SAX_message "EventPath: xoverwrite()ing ", $name, " => ", $new_item if is_tracing;

    unless ( @{$XFD::cur_self->{XStack}} ) {
        $XFD::cur_self->xpush( $new_item );
    }
    else {
        my $e = $XFD::cur_self->{XStack}->[-1];
        my $top = $e->{"#elt"};

        my $t = ref $top;
        my $meth;
        if ( $t eq "" ) {
            $XFD::cur_self->{XStack}->[-1]->{"#elt"} = $new_item; 
            $e->{scalar}++;
        }
        elsif ( $t eq "SCALAR" ) {
            $$top = $new_item; 
            $e->{scalar}++;
        }
        elsif ( $t eq "HASH" ) {
            $top->{$name} = $new_item;
            $e->{$name}++;
        }
        ## See if it's a blessed object that can add thingamies"
        elsif ( 
            ( $meth = UNIVERSAL::can( $top, $name ) )
            || ( $meth = UNIVERSAL::can( $top, "set_$name" ) )
        ) {
            $top->$meth( $new_item );
            $e->{$name}++;
        }
        else {
            croak "don't know how to xoverwrite $name for a '$t' (which is what is on the top of the xstack)";
        }
        $XFD::cur_self->xpush( $new_item )
            if ref $new_item && ref $new_item ne "SCALAR";
    }

    return $new_item;
}



=item xpeek

    Rules => [
        "foo" => sub {
            my $elt = $_[1];
            xpeek->set_name( $elt->{Attributes}->{"{}name"} );
        },
        "/end::*" => sub {
            my $self = shift;
            XXXXXXXXXXXXXXXXXXXX
        }
    ],


Returns the top element on the xstack, which was the last thing
pushed in the current context.  Throws an exception if the xstack is
empty.  To check for an empty stack, use eval:

    my $stack_not_empty = eval { xpeek };

To peek down the xstack, use a Perlish index value.  The most
recently pushed element is index number -1:

    $xpeek( -1 );    ## Same as $self->peek

The first element pushed on the xstack is element 0:

    $xpeek( 0 );

An exception is thrown if the index is off either end of the stack.

=cut

sub xpeek { 
    unless ( @_ ) {
        croak "xpeek() called on empty stack"
            unless @{$XFD::cur_self->{XStack}};

        return $XFD::cur_self->{XStack}->[-1]->{"#elt"};
    }

    local $XFD::cur_self = shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );

    my $index = shift;
    $index = -1 unless defined $index;

    croak "xpeek( $index ) off the end of the stack"
        if     $index >      $#{$XFD::cur_self->{XStack}}
            || $index < -1 - $#{$XFD::cur_self->{XStack}};

    return $XFD::cur_self->{XStack}->[$index]->{"#elt"};
}

=item xpop


    my $d = XML::Filter::Dispatcher->new(
        Rules => [
            ....rules to build an object hierarchy...
        ],
    );

    my $result = $d->xpop

Removes an element from the xstack and returns it.  Usually
called in a end_document handler or after the document returns to
retrieve a "root" object placed on the stack before the root element
was started.

=cut

sub xpop { 
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );

    croak "xpop() called on empty stack"
        unless @{$XFD::cur_self->{XStack}};

    emit_trace_SAX_message "EventPath: xpop()ing ", $XFD::cur_self->{XStack}->[-1]->{"#elt"} if is_tracing;
    return (pop @{$XFD::cur_self->{XStack}})->{"#elt"};
}

=item xstack_empty

Handy for detecting a nonempty stack:

    warn xpeek unless xstack_empty;

Because C<xpeek> and C<xpop> throw exceptions on an empty stack,
C<xstack_empty> is needed to detect whether it's safe to call them.

=cut

sub xstack_empty { 
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    return ! @{$XFD::cur_self->{XStack}};
}

=item xstack_max

Handy for walking the stack:

    for my $i ( reverse 0 .. xstack_max ) {  ## from top to bottom
        use BFD;d xpeek( $i );
    }

Because C<xpeek> and C<xpop> throw exceptions on an empty stack,
C<xstack_max> may be used to walk the stack safely.

=cut

sub xstack_max { 
    local $XFD::cur_self = shift if @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ );
    return $#{$XFD::cur_self->{XStack}};
}

=back

=cut

##
## A little help for debugging
##
{
    ## This allows us to number events as the arrive and then
    ## look those numbers up using their memory addresses
    ## This is a 1..N numbering system: the left hand side of the
    ## ||= preallocates the key, so there's already 1 key in the
    ## hash when this is first called.
    ## We also hold on to the events to keep them from reusing numbers.
    my %events;
    sub _ev($) {
        return (
            $events{int $_[0]} ||=
                { ctx => $_, ev => 0+keys %events }
        )->{ev};
    }
}

{
    ## This allows us to number events as the arrive and then
    ## look those numbers up using their memory addresses
    ## This is a 1..N numbering system: the left hand side of the
    ## ||= preallocates the key, so there's already 1 key in the
    ## hash when this is first called.
    my %postponements;
    sub _po($) {
        return (
            $postponements{int $_[0]} ||=
                { ctx => $_, po => 0+keys %postponements}
        )->{po};
    }
}

##
## SAX handlers
##

## a helper called by the handlers...
## TODO: optimize most of this away for all events except start_document and
## start_ element, since these are the only two events that can have
## child events.  The others should be able to get away with much simpler logic.

sub _call_queued_subs {
    my $self = shift ;
    my $event_type = shift;

    local $XFD::cur_self = $self;

    $XFD::ctx->{EventType} = $event_type;
    $XFD::ctx->{Node}      = $_[0];
    $XFD::ctx->{HighScore} = -1;

    for ( @{$XFD::ctx->{$event_type}} ) {
        $_->[0]->( @{$_}[1..$#$_], @_ );
    }

    $self->_queue_pending_event( $XFD::ctx );
}


sub _call_queued_end_subs {
    my $self = shift ;
    my $event_type = shift;
    my $start_ctx = shift;

    local $XFD::cur_self = $self;

    local $XFD::ctx = $self->_build_end_ctx_from_start_ctx( $start_ctx );
    $XFD::ctx->{EventType} = $event_type;
    $XFD::ctx->{Node}      = $_[0];
    $XFD::ctx->{HighScore} = -1;

    my $i = 0;
    if ( exists $start_ctx->{EndSubs} ) {
        ## EndSubs are subroutines that are placed in a start_ context
        ## to be run when the matching end_ event is reached.  Their
        ## purpose is usually to evaluate some postponement and queue
        ## an action for that postponement if need be.
        my $end_subs = $start_ctx->{EndSubs};
        while ( @$end_subs ) {
            local $_ = pop @$end_subs;
            emit_trace_SAX_message "EventPath: *** calling EndSub ", $i++, " for event ", _ev $start_ctx, " ***" if is_tracing;

            $_->[0]->( @{$_}[1..$#$_], @_ )
        }
    }

#    $start_ctx->{EndContext} = $XFD::ctx;

    $self->_queue_pending_event( $XFD::ctx );
}

sub _execute_next_action {
    my $self = shift;

    my $actions = $XFD::ctx->{PendingActions};
    my $key = ( sort { $a <=> $b } keys %$actions)[-1];
    return unless defined $key;

    emit_trace_SAX_message "EventPath: *** executing action $key for event ", _ev $XFD::ctx, " ***" if is_tracing;
    my $sub = shift @{$actions->{$key}};
    delete $actions->{$key} unless @{$actions->{$key}};

    $self->{LastHandlerResult} = $sub->( $self, $XFD::ctx->{Node} );

    emit_trace_SAX_message "EventPath: result set to ", defined $self->{LastHandlerResult} ? "'$self->{LastHandlerResult}'" : "undef" if is_tracing;

#    if ( exists $XFD::ctx->{EndContext} && exists $XFD::ctx->{EndSubs} ) {
#    my $i = 0;
#    while ( @{$XFD::ctx->{EndSubs}} ) {
#        local $_ = shift @{$XFD::ctx->{EndSubs}};
#        emit_trace_SAX_message "EventPath: *** calling delayed (due to postponed start_) EndSub ", $i++, " for event ", _ev $XFD::ctx, " ***" if is_tracing;
#        local $XFD::ctx = $XFD::ctx->{EndContext};
#
#        $_->[0]->( @{$_}[1..$#$_], @_ )
#    }
#    }

}


sub _queue_pending_event {
    my $self = shift;
    local $XFD::cur_self = $self;

    my ( $ctx ) = @_;

#    if ( exists $ctx->{PendingActions}
#        || ( $ctx->{Postponements} && @{$ctx->{Postponements}} )
#    ) {
#        emit_trace_SAX_message "EventPath: queuing pending event ", _ev $ctx if is_tracing;
       push @{$self->{PendingEvents}}, $ctx;
#    }
#    else {
#        emit_trace_SAX_message "EventPath: not queuing event ", _ev $ctx if is_tracing;
#    }

    while ( @{$self->{PendingEvents}}
        && ! $self->{PendingEvents}->[0]->{PostponementCount}
    ) {
        my $c = shift @{$self->{PendingEvents}};

        if ( show_buffer_highwater
            && @{$self->{PendingEvents}}
            && @{$self->{PendingEvents}} >= $self->{BufferHighwater}
        ) {
            $self->{BufferHighwater} = @{$self->{PendingEvents}};
            if ( @{$self->{PendingEvents}} > $self->{BufferHighwater} ) {
                @{$self->{BufferHighwaterEvents}} = ( $c );
            }
            else {
                push @{$self->{BufferHighwaterEvents}}, $c;
            }
        }

        if (
            substr( $c->{EventType}, 0, 4 ) ne "end_"
#            substr( $c->{EventType}, 0, 6 ) eq "start_"
#            || $c->{EventType} eq "attribute"
        ) {
            push @{$self->{XStackMarks}}, scalar @{$self->{XStack}};
        }

        if ( exists $c->{PendingActions} ) {
            ## The "-1" here implements the "last match wins" logic.
            ## All rules are evaluated in order; the last rule to evaluate
            ## queues its action last.  TODO: test this in the face of
            ## precursors; actions may need to be set based on action
            ## numbers or something.
            local $XFD::ctx = $c;
            $self->_execute_next_action;
        }
        else {
            emit_trace_SAX_message "EventPath: discarding event ", _ev $c if is_tracing;
        }

        if (
#             $c->{EventType} eq "end_element"
            ## Note that we don't unwind on end_document.  Perhaps we should.
#            || $c->{EventType} eq "attribute"
            substr( $c->{EventType}, 0, 6 ) ne "start_"
        ) {
            my $level = pop  @{$self->{XStackMarks}};
            if ( $level < @{$self->{XStack}} ) {
                emit_trace_SAX_message "EventPath: unwinding from xstack: ", splice @{$self->{XStack}}, $level if is_tracing;
                splice @{$self->{XStack}}, $level;
            }
        }
    }

    emit_trace_SAX_message
        "EventPath: ",
        @{$self->{PendingEvents}} . " events pending (",
        join( ", ",
            map
                $_->{PostponementCount}
                    ? _ev( $_ ).":$_->{PostponementCount}:".(
                        exists $_->{PendingActions}
                            ? "action"  ## TODO: dump actions?
                            : "<No action>"
                    )
                    : (),
                @{$self->{PendingEvents}}
        ),
        ")"  if is_tracing;
}


sub _build_ctx {
    my $self = shift;

    my $parent_ctx = $self->{CtxStack}->[-1];
    my $ctx = { %{$parent_ctx->{ChildCtx}} };
    $ctx->{Vars} = { %{$parent_ctx->{Vars}} }
        if exists $parent_ctx->{Vars};

    if ( exists $ctx->{EndSubs} ) {
        ## When descendant-or-self:: queues up cloned postponements
        ## for the child contexts, the child contexts don't exist yet
        ## so it puts undef where they should be.  This loop replaces
        ## those undefs with the freshly minted context.  Only
        ## descendant-or-self:: does this, so we can assume those are
        ## the only kind of EndSubs we'll find.
        $ctx->{EndSubs} = [ map [ @$_ ], @{$ctx->{EndSubs}} ];
        for ( @{$ctx->{EndSubs}} ) {
            die "The first param to the child's EndSubs should be undef not $_->[1]"
                if defined $_->[1];
            $_->[1] = $ctx;
        }
    }
    emit_trace_SAX_message "EventPath: built event ", _ev $ctx, " (from event ", _ev $parent_ctx, ")" if is_tracing;
    return $ctx;
}


sub _build_end_ctx_from_start_ctx {
    my $self = shift;

    my ( $start_ctx ) = @_;

    ## The $start_ctx's actions have yet to run.  They may
    ## add actions to the end event.
    $start_ctx->{PendingEndActions} ||= {};

    my $end_ctx = {
        PendingActions => $start_ctx->{PendingEndActions},
    };
    emit_trace_SAX_message "EventPath: built end_ event ", _ev $end_ctx, " (from event ", _ev $start_ctx, ")" if is_tracing;
    return $end_ctx;
}


sub start_document {
    my $self = shift ;

    $self->{XStack}        = [];
    $self->{XStackMarks}   = [];
    delete $self->{DocStartedFlags};
    $self->{PendingEvents} = [];

    if ( $self->{DocSub} ) {
        ## The "[]" is the postponement record to pass in.
        @{$self->{DocCtx}->{start_document}} = [ $self->{DocSub}, $self, [] ];
    }


    if ( show_buffer_highwater ) {
        $self->{BufferHighwater} = 0;
        $self->{BufferHighwaterEvents} = [];
    }

    local $XFD::ctx = $self->{DocCtx};
    emit_trace_SAX_message "EventPath: using doc event ", _ev $XFD::ctx if is_tracing;
    $self->{CtxStack} = [ $XFD::ctx ];
    $self->_call_queued_subs( "start_document", @_ );

    return;
}


sub end_document {
    my $self = shift ;
    my ( $doc ) = @_;

    confess "Bug: context stack should not be empty!"
        unless @{$self->{CtxStack}};

    my $start_ctx = pop @{$self->{CtxStack}};
    die "end_document() mismatch: ",
        defined $start_ctx ? $start_ctx->{EventType} : "undef", 
        " from the context stack\n"
        unless $start_ctx->{EventType} eq "start_document";

    confess "Bug: context stack should be empty!"
        unless ! @{$self->{CtxStack}};

    $self->_call_queued_end_subs( end_document => $start_ctx, @_ );

    if ( exists $self->{AutoStartedHandlers} ) {
        for ( reverse @{$self->{AutoStartedHandlers}} ) {
            $self->{LastHandlerResult} = $_->end_document( {} );
        }
    }

    @{$self->{XStack}} = ();

    if ( show_buffer_highwater ) {
        warn ref $self,
            " buffer highwater mark was ",
            $self->{BufferHighwater} + 1,
            $self->{BufferHighwater}
                ? (
                " for event",
                @{$self->{BufferHighwaterEvents}} > 1
                    ? "s"
                    : (),
                ":\n",
                map {
                    my $n = $_->{Node};
                    join( "",
                        "    $_->{EventType}",
                        defined $n->{Name}
                            ? ( " ", $n->{Name} )
                            : (),
                        defined $n->{Data}
                            ? ( " \"", 
                                length $n->{Data} > 40
                                    ? ( substr( $n->{Data}, 0, 40 ), "..." )
                                    : $n->{Data},
                                "\""
                            )
                            : (),
                        "\n"
                    );
                } @{$self->{BufferHighwaterEvents}}
                )
                : ( " (no events were buffered)\n" );
        @{$self->{BufferHighwaterEvents}} = ();
    }

    return $self->{LastHandlerResult};
}


sub start_element {
    my $self = shift ;
    my ( $elt ) = @_ ;

    push @{$self->{CtxStack}}, local $XFD::ctx = $self->_build_ctx;

    {
        local $XFD::cur_self = $self;

        $XFD::ctx->{EventType} = "start_element";
        $XFD::ctx->{Node}      = $_[0];
        $XFD::ctx->{HighScore} = -1;

        for ( @{$XFD::ctx->{start_element}} ) {
            $_->[0]->( @{$_}[1..$#$_], @_ );
        }

        $self->{start_elementSub}->( $self, [] )
            if $self->{start_elementSub};

        $self->_queue_pending_event( $XFD::ctx );
    }

    if (
        (
            $self->{attributeSub}
            || exists $XFD::ctx->{ChildCtx}->{attribute}  ## Any attr handlers?
        )
        && exists $elt->{Attributes}           ## Any attrs?
    ) {
        $XFD::ctx->{ChildCtx} ||= {};

        ## Put attrs in a reproducible order.  perl5.6.1 and perl5.8.0
        ## use different hashing algs, this helps keep code stable
        ## across versions.
        my @attrs = values %{$elt->{Attributes}};
        @attrs = sort {
            ( $a->{Name} || "" ) cmp ( $b->{Name} || "" )
        } @attrs if $self->{SortAttributes};

        for my $attr ( @attrs ) {
            local $XFD::ctx = $self->_build_ctx;

            $XFD::ctx->{EventType} = "attribute";
            $XFD::ctx->{Node}      = $attr;
            $XFD::ctx->{HighScore} = -1;

            for ( @{$XFD::ctx->{attribute}} ) {
                $_->[0]->( @{$_}[1..$#$_], @_ );
            }

            $self->{attributeSub}->( $self, [] )
                if $self->{attributeSub};

            $self->_queue_pending_event( $XFD::ctx );
        }
    }

    return;
}


sub end_element {
    my $self = shift ;
    my ( $elt ) = @_ ;

    my $start_ctx = pop @{$self->{CtxStack}}; # Remove the child context

    $self->_call_queued_end_subs( end_element => $start_ctx, @_ );

    return;
}


sub start_prefix_mapping {
    my $self = shift ;
    my ( $elt ) = @_ ;

    ## Prefix mappings aren't containers, but they need to
    ## have contexts saved and restored in order like containers.
    ## So we have a stack within a stack to take care of them.
    push @{$self->{CtxStack}->[-1]->{PrefixContexts}},
        local $XFD::ctx = $self->_build_ctx;

    {
        local $XFD::cur_self = $self;

        $XFD::ctx->{EventType} = "start_prefix_mapping";
        $XFD::ctx->{Node}      = $_[0];
        $XFD::ctx->{HighScore} = -1;

        for ( @{$XFD::ctx->{start_prefix_mapping}} ) {
            $_->[0]->( @{$_}[1..$#$_], @_ );
        }

        $self->{start_prefix_mappingSub}->( $self, [] )
            if $self->{start_prefix_mappingSub};

        $self->_queue_pending_event( $XFD::ctx );
    }

    return;
}


sub end_prefix_mapping {
    my $self = shift ;
    my ( $elt ) = @_ ;

    my $start_ctx = pop @{$self->{CtxStack}->[-1]->{PrefixContexts}};

    $self->_call_queued_end_subs( end_prefix_mapping => $start_ctx, @_ );

    return;
}


compile_missing_methods __PACKAGE__, <<'CODE_END', sax_event_names;
#line 1 XML::Filter::Dispatcher::<EVENT>()
sub <EVENT> {
    my $self = shift ;
    return unless (
        @{$self->{CtxStack}}
        && $self->{CtxStack}->[-1]->{ChildCtx}->{<EVENT>}
        )
        || $self->{<EVENT>Sub};

    my ( $data ) = @_;

    local $XFD::cur_self = $self;

    local $XFD::ctx = $self->_build_ctx;

    $XFD::ctx->{EventType} = "<EVENT>";
    $XFD::ctx->{Node}      = $data;
    $XFD::ctx->{HighScore} = -1;

    for ( @{$XFD::ctx->{<EVENT>}} ) {
        $_->[0]->( @{$_}[1..$#$_], @_ );
    }

    $self->{<EVENT>Sub}->( $self, [] )
        if $self->{<EVENT>Sub};

    $self->_queue_pending_event( $XFD::ctx );

    $self->_call_queued_end_subs( @_ ) if $XFD::ctx->{EndSubs};

    return undef;
}
CODE_END

=head2 Notes for XPath Afficianados

This section assumes familiarity with XPath in order to explain some of
the particulars and side effects of the incremental XPath engine.

=over

=item *

Much of XPath's power comes from the concept of a "node set".  A node
set is a set of nodes returned by many XPath expressions.
Event XPath fires a rule once for each node the rule applies to.  If there
is a location path in the expression, the rule will fire once for each
matching event (perhaps twice if both start and end SAX events are
trapped, see XXXX below.

Expressions like C<0>, C<false()>, C<1>, and C<'a'> have no location
path and apply to all nodes (including namespace nodes and processing
instructions).

=item *

The XPath parser catches some simple mistakes Perlers might make in typing
XPath expressions, such as using C<&&> or C<==> instead of C<and> or C<=>.

=item *

SAX does not define events for attributes; these are passed in to the
start_element (but not end_element) methods as part of the element node.
XML::Filter::Dispatcher emulates an event for each attribute in order to
allow selecting attribute nodes.

=item *

Axes in path steps (/foo::...)

Only some axes can be reasonably supported within a SAX framework without
building a DOM and/or queueing SAX events for in-document-order delivery.

On the other hand, lots of SAX-specific Axes are supported.

=item *

text node aggregation

SAX does not guarantee that C<characters> events will be aggregated as
much as possible, as text() nodes do in XPath.  Generally, however,
this is not a problem; instead of writing

    "quotation/text()" => sub {
        ## BUG: may be called several times within each quotation elt.
        my $self = shift;
        print "He said '", $self->current_node->{Data}, "'\n'";
    },

write

    "string( quotation )" => sub {
        my $self = shift;
        print "He said '", xvalue, "'\n'";
    },

The former is unsafe; consider the XML:

    <quotation>I am <!-- bs -->GREAT!<!-- bs --></quotation>

Rules like C<.../text()> will fire twice, which is not what is needed
here.

Rules like C<string( ... )> will fire once, at the end_element event,
with all descendant text of quotation as the expression result.

You can also place an L<XML::Filter::BufferText|XML::Filter::BufferText>
instance upstream of XML::Filter::Dispatcher if you really want to use
the former syntax (but the C<GREAT!> example will still generate more
than one event due to the comment).

=item *

Axes

All axes are implemented except for those noted below as "todo" or "not
soon".

Also except where noted, axes have a principal event type of
C<start_element>.  This node type is used by the C<*> node type test.

Note: XML::Filter::Dispatcher tries to die() on nonsensical paths like
C</a/start-document::*> or C<//start-cdata::*>, but it may miss some.
This is meant to help in debugging user code; the eventual goal is to
catch all such nonsense.

=over

=item *

ancestor:: (XPath, todo, will be limited)

=item *

ancestor-or-self:: (XPath, todo, will be limited)

=item *

C<attribute::> (XPath, C<attribute>)

=item *

C<child::> (XPath)

Selects start_element, end_element, start_prefix_mapping,
end_prefix_mapping, characters, comment, and
processing_instruction events that are direct "children" of the context
element or document.

=item *

C<descendant::> (XPath)

=item *

C<descendant-or-self::> (XPath)

=item *

C<end::> (SAX, C<end_element>)

Like C<child::>, but selects the C<end_element> event of the
element context node.

This is usually used in preference to C<end-element::> due to its
brevity.

Because this selects the end element event, most of the path tests that
may follow other axes are not valid following this axis.  self:: and
attribute:: are the only legal axes that may occur to the right of this
axis.

=item *

C<end-document::> (SAX, C<end_document>)

Like C<self::>, but selects the C<end_document> event of the document
context node.

Note: Because this selects the end document event, most of the path tests
that may follow other axes are not valid following this axis.
self:: are the only legal axes that may occur to the
right of this axis.

=item *

C<end-element::> (SAX, C<end_element>)

B<EXPERIMENTAL>.  This axis is not necessary given C<end::>.

Like C<child::>, but selects the C<end_element> event of the element
context node.  This is like C<end::>, but different from
C<end-document::>.

Note: Because this selects the end element event, most of the path tests
that may follow other axes are not valid following this axis.
attribute:: and self:: are the only legal axes that may occur to the
right of this axis.

=item *

C<following::> (XPath, B<not soon>)

=item *

C<following-sibling::> (XPath, B<not soon>)

Implementing following axes will take some fucky postponement logic and
are likely to wait until I have time.  Until then, setting a flag in
$self in one handler and checking in another should suffice for most
uses.

=item *

C<namespace::> (XPath, C<namespace>, B<todo>)

=item *

C<parent::> (XPath, B<todo (will be limited)>)

parent/ancestor paths will not allow you to descend the tree, that would
require DOM building and SAX event queueing.

=item *

C<preceding::> (XPath, B<not soon>)

=item *

C<preceding-sibling::> (XPath, B<not soon>)

Implementing reverse axes will take some fucky postponement logic and
are likely to wait until I have time.  Until then, setting a flag in
$self in one handler and checking in another should suffice for most
uses.

=item *

C<self::> (XPath)

=item *

C<start::> (SAX, C<start_element> )

This is like child::, but selects the C<start_element> events.  This is
usually used in preference to C<start-element::> due to its brevity.

C<start::> is rarely used to drive code handlers because rules that
match document or element events already only fire code handlers on the
C<start_element> event and not the C<end_element> event (however, when a
SAX handler is used, such expressions send both start and end events to
the downstream handler, so start:: has utility there).

=item *

C<start-document::> (SAX, C<start_document>)

B<EXPERIMENTAL>.  This axis is confusing compared to and
C<start-element::>, and is not necessary given C<start::>.

This is like C<self::>, but selects only the C<start_document> events.

=item *

C<start-element::> (SAX, C<start_element>)

B<EXPERIMENTAL>.  This axis is not necessary given C<start::>.

This is like C<child::>, but selects only the C<start_element> events.

=back

=item *

Implemented XPath Features

Anything not on this list or listed as unimplemented is a TODO.  Ring me
up if you need it.

=over

=item *

String Functions

=over

=item *

concat( string, string, string* )

=item *

contains( string, string )

=item *

normalize-space( string? )

C<normalize-space()> is equivalent to C<normalize-space(.)>.

=item *

starts-with( string, string )

=item *

string(), string( object )

Object may be a number, boolean, string, or the result of a location path:

    string( 10 );
    string( /a/b/c );
    string( @id );

C<string()> is equivalent to C<string(.)>.

=item *

string-length( string? )

string-length() not supported; can't stringify the context node without
keeping all of the context node's children in mempory.  Could enable it
for leaf nodes, I suppose, like attrs and #PCDATA containing elts.  Drop
me a line if you need this (it's not totally trivial or I'd have done it).

=item *

substring( string, number, number? )

=item *

substring-after( string, string )

=item *

substring-before( string, string )

=item *

translate( string, string, string )

=back

=item *

Boolean Functions, Operators

=over

=item *

boolean( object )

See notes about node sets for the string() function above.

=item *

false()

=item *

lang( string ) B<TODO>.

=item *

not( boolean )

=item *

true()

=back

=item *

Number Functions, Operators

=over

=item *

ceil( number )

=item *

floor( number )

=item *

number( object? )

Converts strings, numbers, booleans, or the result of a location path
(C<number( /a/b/c )>).

Unlike real XPath, this dies if the object cannot be cleanly converted
in to a number.  This is due to Perl's varying level of support for NaN,
and may change in the future.

C<number()> is equivalent to C<number(.)>.

=item *

round ( number )

=item * sum( node-set ) B<TODO>.

=back

=item *

Node Set Functions

Many of these cannot be fully implemented in an event oriented
environment.

=over

=item *

last() B<TODO>.

=item *

position() B<TODO>.

=item *

count( node-set ) B<TODO>.

=back

=item *

id( object ) B<TODO>.

=item *

local-name( node-set? )

=item *

namespace-uri( node-set? )

=item *

name( node-set? )

=item *

All relational operators

No support for nodesets, though.

=item *

All logical operators

Supports limited nodesets, see the string() function description for details.

=back

=item *

Missing Features

Some features are entirely or just currently missing due to the lack of
nodesets or the time needed to work around their lack.  This is an
incomplete list; it's growing as I find new things not to implement.

=over

=item *

count()

No nodesets => no count() of nodes in a node set.

=item *

last()

With SAX, you can't tell when you are at the end of what would be a node set
in XPath.

=item *

position()

I will implement pieces of this as I can.  None are implemented as yet.

=back

=item *

Todo features

=over

=item *

id()

=item *

lang()

=item *

sum( node-set )

=back

=item *

Extensions

=over

=item *

is-start-event(), is-end-event()

XPath has no concept of time; it's meant to operate on a tree of nodes.  SAX
has C<start_element> and C<end_element> events and C<start_document> and
C<end_document> events.

By default, XML::Filter::Dispatcher acts on start events and not end events
(note that all rules are evaluated on both, but the actions are not run on end_
events by default).

By including a call to the C<is-start-event()> or C<is-end-event()> functions in a
predicate the rule may be forced to fire only on end events or on both start
and end events (using a C<[is-start-event() or is-end-event()]> idiom).

=back

=back

=head1 TODO

=over

=item *

Namespace support.

=item *

Text node aggregation so C<text()> handlers fire once per text node
instead of once per C<characters()> event.

=item *

Nice messages on legitimate but unsupported axes.

=item *

/../ (parent node)

=item *

C<add_rule()>, C<remove_rule()>, C<set_rules()> methods.

=back

=head1 OPTIMIZING

Pass Assume_xvalue => 0 flag to tell X::F::D not to support xvalue
and xvalue_type, which lets it skip some instructions and run faster.

Pass SortAttributes => 0 flag to prevent calling sort() for each
element's attributes (note that Perl changes hashing algorithms
occasionally, so setting this to 0 may expose ordering dependancies
in your code).

=head1 DEBUGGING

NOTE: this section describes things that may change from version to
version as I need different views in to the internals.

Set the option Debug => 1 to see the Perl code for the compiled ruleset.
If you have GraphViz.pm and ee installed and working, set Debug => 2 to
see a graph diagram of the intermediate tree generated by the compiler.

Set the env. var XFDSHOWBUFFERHIGHWATER=1 to see what events were
postponed the most (in terms of how many events had to pile up behind
them).  This can be of some help if you experience lots of buffering or
high latency through the filter.  Latency meaning the lag between when
an event arrives at this filter and when it is dispatched to its
actions.  This will only report events that were actually postponed.  If
you have a 0 latency filter, the report will list no events.

Set the env. var XFDOPTIMIZE=0 to prevent all sorts of optimizations.

=head1 LIMITATIONS

=over

=item *

NaN is not handled properly due to mediocre support in C<perl>,
especially across some platforms that it apparently isn't easily supported on.

=item *

-0 (negative zero) is not provided or handled properly

=item *

+/- Infinity is not handled properly due to mediocre support in C<perl>,
especially across some platforms that it apparently isn't easily supported on.

=back

This is more of a frustration than a limitation, but this class requires that
you pass in a type when setting variables (in the C<Vars> ctor parameter or
when calling C<xset_var>).  This is so that the engine can tell what type a
variable is, since string(), number() and boolean() all treat the Perlian C<0>
differently depending on its type.  In Perl the digit C<0> means C<false>,
C<0> or C<'0'>, depending on context, but it's a consistent semantic.  When
passing a C<0> from Perl lands to XPath-land, we need to give it a type so that
C<string()> can, for instance, decide whether to convert it to C<'0'> or
C<'false'>.

=head1 THANKS

...to Kip Hampton, Robin Berjon and Matt Sergeant for sanity checks and
to James Clark (of Expat fame) for posting a Yacc XPath grammar where
I could snarf it years later and add lots of Perl code to it.

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of the Artistic or GNU Pulic
licenses your choice.  Also, a portion of XML::Filter::Dispatcher::Parser
is covered by:

        The Parse::Yapp module and its related modules and shell scripts are
        copyright (c) 1998-1999 Francois Desarmenien, France. All rights
        reserved.

        You may use and distribute them under the terms of either the GNU
        General Public License or the Artistic License, as specified in the
        Perl README file.

Note: Parse::Yapp is only needed if you want to modify
lib/XML/Filter/Dispatcher/Grammar.pm

=cut

1 ;
