# Node -- generic parse tree node ("abstract class")
# lineno (scalar): corresponding line number in source code (for debugging)
package Text::PORE::Node;

use strict;
use Exporter;

@Text::PORE::Node::ISA = qw(Exporter);

$Text::PORE::Node::debug = 0;

use Text::PORE::Node::Attr;
use Text::PORE::Node::Container;
use Text::PORE::Node::Freetext;
use Text::PORE::Node::If;
use Text::PORE::Node::Standalone;
use Text::PORE::Node::Queue;

sub new {
    my $type = shift;
    my $lineno = shift;

    my ($self) = { };

    bless $self, ref($type) || $type;

    $self->setLineNo($lineno);

    $self->{'errors'} = [ ];

    $self;
}

sub setLineNo {
    my $self = shift;
    my $lineno = shift;

    $self->{'lineno'} = $lineno;
}

# a 'final' method
sub setDebug {
    my $self = shift;
    my $value = shift;

    $Node::debug = $value;
}

# a 'final' method
sub getDebug {
    my $self = shift;

    $Node::debug;
}

# a 'final' method
sub setOutput {
    my $self = shift;
    my $output = shift;

    $Node::output = $output;
}

# a 'final' method
sub output {
    my $self = shift;
    my $output = shift;

    $Node::output->print($output);
}


# A "virtual" method
sub traverse {
    my $self = shift;
    my $context = shift;
    my $globals = shift;

    # need to return an empty list of error messages
    [ ];
}

sub error {
    my $self = shift;
    my $text = join('',@_); # not always needed, but it's easy enough to do

    # push onto the error list; if it's an array ref, push the array,
    #  else push the string prepended by the line number
    # note - we would rather just use push, but it won't work on anon arrays
    $self->{'errors'} =
	[
	 @{$self->{'errors'}} , 
	 (ref $_[0] eq 'ARRAY' ? @{$_[0]} : "$self->{'lineno'}: $text\n"),
	 ];
}

sub errorDump {
    my $self = shift;

    my $errors = $self->{'errors'};

    $self->{'errors'} = [ ];

    $errors;
}

sub retrieveSlot {
    my $self = shift;    # operating node
    my $globals = shift; # global objects to assist in lookup
    my $slot = shift;    # name of slot to lookup

    my ($lineno) = $self->{'lineno'};
    my ($obj);
    my (@attr_list);
    
    unless (defined($slot)) {
	return undef;
    }
    
    @attr_list = split(/\./, $slot);

    # if it's explicitly a global object, start from there,
    #  else default to _context
    if ($attr_list[0] =~ m/^_/) {
	$obj = $globals->GetAttribute($attr_list[0]);
	unless (ref($obj)) {
	    $self->error("'$attr_list[0] is not a defined global object");
	    return undef;
	}
	shift @attr_list;
    } else {
	$obj = $globals->GetAttribute('_context');
    }
	    
    # Get attribute by parsing dot-notation
    while (@attr_list) {
	my $attr = shift @attr_list;
	
	if (! ref($obj) || ref($obj) =~ /(ARRAY|HASH)/) {
	    $self->error("Attempt to take attribute '$attr' from non-object");
	    return "";
	}
	
	$obj = $obj->GetAttribute($attr);
    }
    
    return $obj;
}

1;
