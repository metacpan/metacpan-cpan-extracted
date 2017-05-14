package XML::Filter::DetectWS;
use strict;
use XML::Filter::SAXT;

#----------------------------------------------------------------------
#	CONSTANT DEFINITIONS
#----------------------------------------------------------------------

# Locations of whitespace
sub WS_START	(%) { 1 }	# just after <a>
sub WS_END	(%) { 2 }	# just before </a>
sub WS_INTER	(%) { 0 }	# not at the start or end (i.e. intermediate)
sub WS_ONLY	(%) { 3 }	# both START and END, i.e. between <a> and </a>

# The states of the WhiteSpace detection code
# for regular elements, i.e. elements that:
# 1) don't have xml:space="preserve"
# 2) have an ELEMENT model that allows text children (i.e. ANY or Mixed content)

sub START          (%) { 0 }	# just saw <elem>
sub ONLY_WS        (%) { 1 }	# saw <elem> followed by whitespace (only)
sub ENDS_IN_WS	   (%) { 2 }	# ends in whitespace (sofar)
sub ENDS_IN_NON_WS (%) { 3 }	# ends in non-ws text or non-text node (sofar)

# NO_TEXT States: when <!ELEMENT> model does not allow text
# (we assume that all text children are whitespace)
sub NO_TEXT_START	   (%) { 4 }	# just saw <elem>
sub NO_TEXT_ONLY_WS        (%) { 5 }	# saw <elem> followed by whitespace (only)
sub NO_TEXT_ENDS_IN_WS	   (%) { 6 }	# ends in whitespace (sofar)
sub NO_TEXT_ENDS_IN_NON_WS (%) { 7 }	# ends in non-text node (sofar)

# State for elements with xml:space="preserve" (all text is non-WS)
sub PRESERVE_WS    (%) { 8 }

#----------------------------------------------------------------------
#	METHOD DEFINITIONS
#----------------------------------------------------------------------

# Constructor options:
#
# SkipIgnorableWS	1 means: don't forward ignorable_whitespace events
# Handler		SAX Handler that will receive the resulting events
#

sub new
{
    my ($class, %options) = @_;

    my $self = bless \%options, $class;

    $self->init_handlers;

    $self;
}

# Does nothing
sub noop {}

sub init_handlers
{
    my ($self) = @_;
    my %handlers;
    
    my $handler = $self->{Handler};
    
    for my $cb (map { @{$_} } values %XML::Filter::SAXT::SAX_HANDLERS)
    {
	if (UNIVERSAL::can ($handler, $cb))
	{
	    $handlers{$cb} = eval "sub { \$handler->$cb (\@_) }";
	}
	else
	{
	    $handlers{$cb} = \&noop;
	}
    }

    if ($self->{SkipIgnorableWS})
    {
	delete $handlers{ignorable_whitespace};	# if it exists
    }
    elsif (UNIVERSAL::can ($handler, 'ignorable_whitespace'))
    {
	# Support ignorable_whitespace callback if it exists
	# (if not, just use characters callback)
	$handlers{ignorable_whitespace} = 
	    sub { $handler->ignorable_whitespace (@_) };
    }
    else
    {
	$handlers{ignorable_whitespace} = $handlers{characters};
    }

    $handlers{ws} = $handlers{characters};    
#?? were should whitespace go?

    # NOTE: 'cdata' is not a valid PerlSAX callback
    if (UNIVERSAL::can ($handler, 'start_cdata') &&
	UNIVERSAL::can ($handler, 'end_cdata'))
    {
	$handlers{cdata} = sub {
	    $handler->start_cdata;
	    $handler->characters (@_);
	    $handler->end_cdata;
	}
    }
    else	# pass CDATA as regular characters
    {
	$handlers{cdata} = $handlers{characters};
    }

    $self->{Callback} = \%handlers;
}

sub start_cdata
{
    my ($self, $event) = @_;

    $self->{InCDATA} = 1;
}

sub end_cdata
{
    my ($self, $event) = @_;

    $self->{InCDATA} = 0;
}

sub entity_reference
{
    my ($self, $event) = @_;
    
    $self->push_event ('entity_reference', $event);

    my $parent = $self->{ParentStack}->[-1];
    $parent->{State} |= ENDS_IN_NON_WS unless $parent->{State} == PRESERVE_WS;
}

sub comment
{
    my ($self, $event) = @_;
    
    $self->push_event ('comment', $event);

    my $parent = $self->{ParentStack}->[-1];
    $parent->{State} |= ENDS_IN_NON_WS unless $parent->{State} == PRESERVE_WS;
}

sub processing_instruction
{
    my ($self, $event) = @_;
    
    $self->push_event ('processing_instruction', $event);

    my $parent = $self->{ParentStack}->[-1];
    $parent->{State} |= ENDS_IN_NON_WS unless $parent->{State} == PRESERVE_WS;
}

sub start_document
{
    my ($self, $event) = @_;

    # Initialize initial state
    $self->{ParentStack} = [];
    $self->{EventQ} = [];
    $self->{InCDATA} = 0;

    $self->init_handlers;

    $event = {} unless defined $event;
    # Don't preserve WS by default (unless specified by the user)
    $event->{PreserveWS} = defined ($self->{PreserveWS}) ? 
					$self->{PreserveWS} : 0;

    # We don't need whitespace detection at the document level
    $event->{State} = PRESERVE_WS;

    $self->push_event ('start_document', $event);
    push @{ $self->{ParentStack} }, $event;
}

sub end_document
{
    my ($self, $event) = @_;
    $event = {} unless defined $event;

    $self->push_event ('end_document', $event);

    $self->flush;
}

sub start_element
{
    my ($self, $event) = @_;

    my $pres = $event->{Attributes}->{'xml:space'};
    if (defined $pres)
    {
	$event->{PreserveWS} = $pres eq "preserve";
    }
    else
    {
	$event->{PreserveWS} = $self->{ParentStack}->[-1]->{PreserveWS};
    }

    if ($self->{NoText}->{ $event->{Name} })
    {
	$event->{NoText} = 1;
    }

    $event->{State} = $self->get_init_state ($event);

    $self->push_event ('start_element', $event);
    push @{ $self->{ParentStack} }, $event;
}

sub end_element
{
    my ($self, $event) = @_;

    # Mark previous whitespace event as the last event (WS_END)
    # (if it's there)
    my $prev = $self->{EventQ}->[-1];
    $prev->{Loc} |= WS_END if exists $prev->{Loc};

    $self->push_event ('end_element', $event);
    
    my $elem = pop @{ $self->{ParentStack} };
    delete $elem->{State};
}

sub characters
{
    my ($self, $event) = @_;

    if ($self->{InCDATA})
    {
	# NOTE: 'cdata' is not a valid PerlSAX callback
	$self->push_event ('cdata', $event);
	
	my $parent = $self->{ParentStack}->[-1];
	$parent->{State} |= ENDS_IN_NON_WS unless $parent->{State} == PRESERVE_WS;
	return;
    }

    my $text = $event->{Data};
    return unless length ($text);

    my $state = $self->{ParentStack}->[-1]->{State};
    if ($state == PRESERVE_WS)
    {
	$self->push_event ('characters', $event);
    }
    elsif ($state == NO_TEXT_START)
    {
	# ELEMENT model does not allow regular text.
	# All characters are whitespace.
	$self->push_event ('ignorable_whitespace', { Data => $text, Loc => WS_START });
	$state = NO_TEXT_ONLY_WS;
    }
    elsif ($state == NO_TEXT_ONLY_WS)
    {
	$self->merge_text ($text, 'ignorable_whitespace', WS_START );
    }
    elsif ($state == NO_TEXT_ENDS_IN_NON_WS)
    {
	$self->push_event ('ignorable_whitespace', { Data => $text, Loc => WS_INTER });
	$state = NO_TEXT_ENDS_IN_WS;
    }
    elsif ($state == NO_TEXT_ENDS_IN_WS)
    {
	$self->merge_text ($text, 'ignorable_whitespace', WS_INTER );
    }
    elsif ($state == START)
    {
#?? add support for full Unicode
	$text =~ /^(\s*)(\S(?:.*\S)?)?(\s*)$/;
	if (length $1)
	{
	    $self->push_event ('ws', { Data => $1, Loc => WS_START });
	    $state = ONLY_WS;
	}
	if (length $2)
	{
	    $self->push_event ('characters', { Data => $2 });
	    $state = ENDS_IN_NON_WS;
	}
	if (length $3)
	{
	    $self->push_event ('ws', { Data => $3, Loc => WS_INTER });
	    $state = ENDS_IN_WS;
	}
    }
    elsif ($state == ONLY_WS)
    {
	$text =~ /^(\s*)(\S(?:.*\S)?)?(\s*)$/;
	if (length $1)
	{
	    $self->merge_text ($1, 'ws', WS_START);
	}
	if (length $2)
	{
	    $self->push_event ('characters', { Data => $2 });
	    $state = ENDS_IN_NON_WS;	    
	}
	if (length $3)
	{
	    $self->push_event ('ws', { Data => $3, Loc => WS_INTER });
	    $state = ENDS_IN_WS;	    
	}
    }
    else # state == ENDS_IN_WS or ENDS_IN_NON_WS
    {
	$text =~ /^(.*\S)?(\s*)$/;
	if (length $1)
	{
	    if ($state == ENDS_IN_NON_WS)
	    {
		$self->merge_text ($1, 'characters');
	    }
	    else
	    {
		$self->push_event ('characters', { Data => $1 });
		$state = ENDS_IN_NON_WS;	    
	    }
	}
	if (length $2)
	{
	    if ($state == ENDS_IN_WS)
	    {
		$self->merge_text ($2, 'ws', WS_INTER);
	    }
	    else
	    {
		$self->push_event ('ws', { Data => $2, Loc => WS_INTER });
		$state = ENDS_IN_WS;
	    }
	}
    }

    $self->{ParentStack}->[-1]->{State} = $state;
}

sub element_decl
{
    my ($self, $event) = @_;
    my $tag = $event->{Name};
    my $model = $event->{Model};

    # Check the model to see if the elements may contain regular text
    $self->{NoText}->{$tag} = ($model eq 'EMPTY' || $model !~ /\#PCDATA/);

    $self->push_event ('element_decl', $event);
}

sub attlist_decl
{
    my ($self, $event) = @_;
    
    my $prev = $self->{EventQ}->[-1];
    if ($prev->{EventType} eq 'attlist_decl' && 
	$prev->{ElementName} eq $event->{ElementName})
    {
	$prev->{MoreFollow} = 1;
	$event->{First} = 0;
    }
    else
    {
	$event->{First} = 1;
    }

    $self->push_event ('attlist_decl', $event);
}

sub notation_decl
{
    my ($self, $event) = @_;
    $self->push_event ('notation_decl', $event);
}

sub unparsed_entity_decl
{
    my ($self, $event) = @_;
    $self->push_event ('unparsed_entity_decl', $event);
}

sub entity_decl
{
    my ($self, $event) = @_;
    $self->push_event ('entity_decl', $event);
}

sub doctype_decl
{
    my ($self, $event) = @_;
    $self->push_event ('doctype_decl', $event);
}

sub xml_decl
{
    my ($self, $event) = @_;
    $self->push_event ('xml_decl', $event);
}

#?? what about set_document_locator, resolve_entity

#
# Determine the initial State for the current Element.
# By default, we look at the PreserveWS property (i.e. value of xml:space.)
# The user can override this to force xml:space="preserve" for a particular
# element with e.g.
#
# sub get_init_state
# {
#    my ($self, $event) = @_;
#    ($event->{Name} eq 'foo' || $event->{PreserveWS}) ? PRESERVE_WS : START;
# }
#
sub get_init_state
{
    my ($self, $event) = @_;
    my $tag = $event->{Name};

    if ($self->{NoText}->{$tag})	# ELEMENT model does not allow text
    {
	return NO_TEXT_START;
    }
    $event->{PreserveWS} ? PRESERVE_WS : START;
}

sub push_event
{
    my ($self, $type, $event) = @_;

    $event->{EventType} = $type;

    $self->flush;
    push @{ $self->{EventQ} }, $event;
}

# Merge text with previous event (if it has the same EventType)
# or push a new text event
sub merge_text
{
    my ($self, $str, $eventType, $wsLocation) = @_;
    my $q = $self->{EventQ};

    my $prev = $q->[-1];
    if (defined $prev && $prev->{EventType} eq $eventType)
    {
	$prev->{Data} .= $str;
    }
    else
    {
	my $event = { Data => $str };
	$event->{Loc} = $wsLocation if defined $wsLocation;
	$self->push_event ($eventType, $event);
    }
}

# Forward all events on the EventQ
sub flush
{
    my ($self) = @_;

    my $q = $self->{EventQ};
    while (@$q)
    {
	my $event = shift @$q;
	my $type = $event->{EventType};
	delete $event->{EventType};

	$self->{Callback}->{$type}->($event);
    }
}

1; # package return code

__END__

=head1 NAME

XML::Filter::DetectWS - A PerlSAX filter that detects ignorable whitespace

=head1 SYNOPSIS

 use XML::Filter::DetectWS;

 my $detect = new XML::Filter::DetectWS (Handler => $handler,
					 SkipIgnorableWS => 1);

=head1 DESCRIPTION

This a PerlSAX filter that detects which character data contains 
ignorable whitespace and optionally filters it.

Note that this is just a first stab at the implementation and it may
change completely in the near future. Please provide feedback whether
you like it or not, so I know whether I should change it.

The XML spec defines ignorable whitespace as the character data found in elements
that were defined in an <!ELEMENT> declaration with a model of 'EMPTY' or
'Children' (Children is the rule that does not contain '#PCDATA'.)

In addition, XML::Filter::DetectWS allows the user to define other whitespace to 
be I<ignorable>. The ignorable whitespace is passed to the PerlSAX Handler with
the B<ignorable_whitespace> handler, provided that the Handler implements this 
method. (Otherwise it is passed to the characters handler.)
If the B<SkipIgnorableWS> is set, the ignorable whitespace is simply
discarded.

XML::Filter::DetectWS also takes xml:space attributes into account. See below
for details.

CDATA sections are passed in the standard PerlSAX way (i.e. with surrounding
start_cdata and end_cdata events), unless the Handler does not implement these
methods. In that case, the CDATA section is simply passed to the characters 
method.

=head1 Constructor Options

=over 4

=item * SkipIgnorableWS (Default: 0)

When set, detected ignorable whitespace is discarded.

=item * Handler

The PerlSAX handler (or filter) that will receive the PerlSAX events from this 
filter.

=back

=head1 Current Implementation

When determining which whitespace is ignorable, it first looks at the
xml:space attribute of the parent element node (and its ancestors.) 
If the attribute value is "preserve", then it is *NOT* ignorable.
(If someone took the trouble of adding xml:space="preserve", then that is
the final answer...)

If xml:space="default", then we look at the <!ELEMENT> definition of the parent
element. If the model is 'EMPTY' or follows the 'Children' rule (i.e. does not
contain '#PCDATA') then we know that the whitespace is ignorable.
Otherwise we need input from the user somehow.

The idea is that the API of DetectWS will be extended, so that you can
specify/override e.g. which elements should behave as if xml:space="preserve" 
were set, and/or which elements should behave as if the <!ELEMENT> model was
defined a certain way, etc.

Please send feedback!

The current implementation also detects whitespace after an element-start tag,
whitespace before an element-end tag. 
It also detects whitespace before an element-start and after an element-end tag
and before or after comments, processing instruction, cdata sections etc.,
but this needs to be reimplemented.
In either case, the detected whitespace is split off into its own PerlSAX
characters event and an extra property 'Loc' is added. It can have 4 possible
values:

=over 4

=item * 1 (WS_START) - whitespace immediately after element-start tag

=item * 2 (WS_END) - whitespace just before element-end tag

=item * 3 (WS_ONLY) - both WS_START and WS_END, i.e. it's the only text found between the start and end tag and it's all whitespace

=item * 0 (WS_INTER) - none of the above, probably before an element-start tag,
after an element-end tag, or before or after a comment, PI, cdata section etc.

=back

Note that WS_INTER may not be that useful, so this may change.

=head1 xml:space attribute

The XML spec states that: A special attribute
named xml:space may be attached to an element
to signal an intention that in that element,
white space should be preserved by applications.
In valid documents, this attribute, like any other, must be 
declared if it is used.
When declared, it must be given as an 
enumerated type whose only
possible values are "default" and "preserve".
For example:

 <!ATTLIST poem   xml:space (default|preserve) 'preserve'>

The value "default" signals that applications'
default white-space processing modes are acceptable for this element; the
value "preserve" indicates the intent that applications preserve
all the white space.
This declared intent is considered to apply to all elements within the content
of the element where it is specified, unless overriden with another instance
of the xml:space attribute.

The root element of any document
is considered to have signaled no intentions as regards application space
handling, unless it provides a value for 
this attribute or the attribute is declared with a default value.

[... end of excerpt ...]

=head1 CAVEATS

This code is highly experimental! 
It has not been tested well and the API may change.

The code that detects of blocks of whitespace at potential indent positions
may need some work. See 

=head1 AUTHOR

Send bug reports, hints, tips, suggestions to Enno Derksen at
<F<enno@att.com>>. 

=cut
