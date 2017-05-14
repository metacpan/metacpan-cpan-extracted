package XML::Filter::Reindent;
use strict;
use XML::Filter::DetectWS;

use vars qw{ @ISA };
@ISA = qw{ XML::Filter::DetectWS };

sub MAYBE (%) { 2 }

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new (@_);

    # Use one space per indent level (by default)
    $self->{Tab} = " " unless defined $self->{Tab};

    # Note that this is a PerlSAX filter so we use the XML newline ("\x0A"),
    # not the Perl output newline ("\n"), by default.
    $self->{Newline} = "\x0A" unless defined $self->{Newline};

    $self;
}

# Indent the element if its parent element says so
sub indent_element
{
    my ($self, $event, $parent_says_indent) = @_;
    return $parent_says_indent;
}

# Always indent children unless element (or its ancestor) has 
# xml:space="preserve" attribute
sub indent_children
{
    my ($self, $event) = @_;
    return $event->{PreserveWS} ? 0 : MAYBE;
}

sub start_element
{
    my ($self, $event) = @_;

    my $parent = $self->{ParentStack}->[-1];
    my $level = $self->{Level}++;
    $self->SUPER::start_element ($event);

    my $parent_says_indent = $parent->{IndentChildren} ? 1 : 0;
    # init with 1 if parent says MAYBE
    $event->{Indent} = $self->indent_element ($event, $parent_says_indent) ?
			$level : undef;

    $event->{IndentChildren} = $self->indent_children ($event);
}

sub end_element
{
    my ($self, $event) = @_;
    my $start_element = $self->{ParentStack}->[-1];

    if ($start_element->{IndentChildren} == MAYBE)
    {
	my $q = $self->{EventQ};
	my $prev = $q->[-1];

	if ($prev == $start_element)
	{
	    # End tag follows start tag: compress tag
	    $start_element->{Compress} = 1;
	    $event->{Compress} = 1;
#?? could detect if it contains only ignorable_ws
	}
	elsif ($prev->{EventType} eq 'characters')
	{
	    if ($q->[-2] == $start_element)
	    {
		# Element has only one child, a text node.
		# Print element as: <a>text here</a>
		delete $prev->{Indent};
		$start_element->{IndentChildren} = 0;
	    }
	}
    }

    my $level = --$self->{Level};
    $event->{Indent} = $start_element->{IndentChildren} ? $level : undef;

    my $compress = $start_element->{Compress};
    if ($compress)
    {
	$event->{Compress} = $compress;
	delete $event->{Indent};
    }

    $self->SUPER::end_element ($event);
}

sub end_document
{
    my ($self, $event) = @_;

    $self->push_event ('end_document', $event || {});
    $self->flush (0);	# send remaining events
}

sub push_event
{
    my ($self, $type, $event) = @_;

    $event->{EventType} = $type;
    if ($type =~ /^(characters|comment|processing_instruction|entity_reference|cdata)$/)
    {
	my $indent_kids = $self->{ParentStack}->[-1]->{IndentChildren} ? 1 : 0;
	$event->{Indent} =  $indent_kids ? $self->{Level} : undef;
    }

    my $q = $self->{EventQ};
    push @$q, $event;

    $self->flush (4);	# keep 4 events on the stack (maybe 3 is enough)
}

sub flush
{
    my ($self, $keep) = @_;
    my $q = $self->{EventQ};

    while (@$q > $keep)
    {
	my $head = $q->[0];
#	print "head=" . $head->{EventType} . " indent=" . $head->{Indent} . "\n";

	if ($head->{EventType} =~ /ws|ignorable/)
	{
	    my $next = $q->[1];
	    my $indent = $next->{Indent};

	    if (defined $indent)	# fix existing indent
	    {
		$head->{Data} = $self->{Newline} . ($self->{Tab} x $indent);
		$self->send (2);
	    }
	    else		# remove existing indent
	    {
		shift @$q;
		$self->send (1);
	    }
#?? remove keys: Indent, ...
	}
	else
	{
	    my $indent = $head->{Indent};

	    if (defined $indent)	# insert indent
	    {
		unshift @$q, { EventType => 'ws', 
			       Data => $self->{Newline} . ($self->{Tab} x $indent) };
		$self->send (2);
	    }
	    else		# no indent - leave as is
	    {
		$self->send (1);
	    }
	}
    }
}

sub send
{
    my ($self, $i) = @_;
    
    my $q = $self->{EventQ};

    while ($i--)
    {
	my $event = shift @$q;
	my $type = $event->{EventType};
	delete $event->{EventType};

#print "TYPE=$type " . join(",", map { "$_=" . $event->{$_} } keys %$event) . "\n";
	$self->{Callback}->{$type}->($event);
    }
}

1;	# package return code

=head1 NAME

XML::Filter::Reindent - Reformats whitespace for pretty printing XML

=head1 SYNOPSIS

 use XML::Handler::Composer;
 use XML::Filter::Reindent;

 my $composer = new XML::Handler::Composer (%OPTIONS);
 my $indent = new XML::Filter::Reindent (Handler => $composer, %OPTIONS);

=head1 DESCRIPTION

XML::Filter::Reindent is a sub class of L<XML::Filter::DetectWS>.

XML::Filter::Reindent can be used as a PerlSAX filter to reformat an
XML document before sending it to a PerlSAX handler that prints it
(like L<XML::Handler::Composer>.)

Like L<XML::Filter::DetectWS>, it detects ignorable whitespace and blocks of
whitespace characters in certain places. It uses this information and
information supplied by the user to determine where whitespace may be
modified, deleted or inserted. 
Based on the indent settings, it then modifies, inserts and deletes characters
and ignorable_whitespace events accordingly.

This is just a first stab at the implementation.
It may be buggy and may change completely!

=head1 Constructor Options

=over 4

=item * Handler

The PerlSAX handler (or filter) that will receive the PerlSAX events from this 
filter.

=item * Tab (Default: one space)

The number of spaces per indent level for elements etc. in document content.

=item * Newline (Default: "\x0A")

The newline to use when re-indenting. 
The default is the internal newline used by L<XML::Parser>, L<XML::DOM> etc.,
and should be fine when used in combination with L<XML::Handler::Composer>.

=back

=head1 $self->indent_children ($start_element_event)

This method determines whether children of a certain element
may be reformatted. 
The default implementation checks the PreserveWS parameter of the specified
start_element event and returns 0 if it is set or MAYBE otherwise.
The value MAYBE (2) indicates that further investigation is needed, e.g.
by examining the element contents. A value of 1 means yes, indent the
child nodes, no further investigation is needed.

NOTE: the PreserveWS parameter is set by the parent class, 
L<XML::Filter::DetectWS>, when the element or one of its ancestors has
the attribute xml:space="preserve".

Override this method to tweak the behavior of this class.

=head1 $self->indent_element ($start_element_event, $parent_says_indent)

This method determines whether a certain element may be re-indented. 
The default implementation returns the value of the $parent_says_indent
parameter, which was set to the value returned by indent_children for the
parent element. In other words, the element will be re-indented if the
parent element allows it.

Override this method to tweak the behavior of this class.
I'm not sure how useful this hook is. Please provide feedback!

=head1 Current Implementation

The current implementation puts all incoming Perl SAX events in a queue for
further processing. When determining which nodes should be re-indented,
it sometimes needs information from previous events, hence the use of the 
queue.

The parameter (Compress => 1) is added to 
matching start_element and end_element events with no events in between
This indicates to an XML printer that a compressed notation can be used, 
e.g <foo/>.

If an element allows reformatting of its contents (xml:space="preserve" was 
not active and indent_children returned MAYBE), the element
contents will be reformatted unless it only has one child node and that
child is a regular text node (characters event.) 
In that case, the element will be printed as <foo>text contents</foo>.

If you want element nodes with just one text child to be reindented as well,
simply override indent_children to return 1 instead of MAYBE (2.)

This behavior may be changed or extended in the future.

=head1 CAVEATS

This code is highly experimental! 
It has not been tested well and the API may change.

The code that detects blocks of whitespace at potential indent positions
may need some work.

=head1 AUTHOR

Send bug reports, hints, tips, suggestions to Enno Derksen at
<F<enno@att.com>>. 

=cut
