# ContainerTagNode -- 
# tag_type (scalar): type of tag
# pairs (hash): attribute-value pairs
# body (array ref): template enclosed within tags (Node stack)
package Text::PORE::Node::Container;

use Text::PORE::Node::Attr;
use Text::PORE::Table;
use strict;

@Text::PORE::Node::Container::ISA = qw(Text::PORE::Node::Attr);

my %ContainerFunctions = (
			  'list'      => 'ListTagFunc',
			  'context'   => 'ContextTagFunc',
			  'link'      => 'LinkTagFunc',
			  );
		       
sub new {
    my $type = shift;
    my $lineno = shift;
    my $tag_type = shift;
    my $pairs = shift;
    my $body = shift;

    my $self = bless {}, ref($type) || $type;

    $self = $self->SUPER::new($lineno, $tag_type, $pairs);
   
    $self->{'body'} = $body;
 
    bless $self, ref($type) || $type;
}

sub setBody {
    my $self = shift;
    my $body = shift;

    $self->{'body'} = $body;
}

sub traverse {
    my $self = shift;
    my $globals = shift;

    $self->output("[$self->{'tag_type'}:$self->{'lineno'}]")
	if $self->getDebug;
    
    # lookup method name
    my ($method) = $ContainerFunctions{$self->{'tag_type'}};
    
    # execute that method, collect it's errors
    if ($method) {
	$self->error($self->$method($globals));
    } else {
	$self->error("Unsupported tag [$self->{'tag_type'}]");
    }
    
    $self->errorDump();
}

sub ListTagFunc {
    my $self = shift;
    my $globals = shift;
    
    my $body = $self->{'body'};
    
    my ($attr) = $self->{'attrs'}{'attr'};
    my (@range) = $self->DetermineRange();;
    my ($objects) = $self->retrieveSlot($globals, $attr);
    
    my ($index_name) = $self->{'attrs'}{'index'};
    my ($index_tmp);
    my ($index);
    
    my ($context_tmp);
    
    if (ref($objects) !~ /ARRAY/) {
	$self->error("The attribute '$attr' of current object " .
		     "is not a list.");
	return $self->errorDump();
    }
    
    # quit if we don't have a list of objects
    unless (scalar @$objects) {
	$self->error("Attempt to loop over empty list");
	return $self->errorDump();
    }
    
    # set up the range over which to loop, default is everything
    unless (scalar @range) {
	@range = 0 .. $#$objects;
    }
    
    # if they want to use an index variable, set it up
    if (defined $index_name) {
	# inform them if they will have a naming conflict
	#  note that they can redefine index variables as many times as
	#  they want, and this code will store them all due to the call
	#  stack
	if (defined $globals->{'_index'}->GetAttribute($index_name)) {
	    $self->error("Temporary redefinition of index variable ".
			 "'$index_name'");
	}
	$index_tmp = $globals->{'_index'}->GetAttribute($index_name);
    }
    
    # store the current context to be restored later
    $context_tmp = $globals->GetAttribute('_context');
    
    # loop over each index specified
    foreach $index (@range) {
	
	# complain about indexes that are out of range, and skip them
	if ($index > $#$objects) {
	    $self->error("Subscript ". $index + 1 ." out of range, ".
			 $#$objects + 1 . " max");
	    next;
	}
	
	# update their index variable, if they have one
	#  note that we have to add 1 to it
	if (defined $index_name) {
	    $globals->{'_index'}->LoadAttributes($index_name, $index + 1);
	}
	
	# process the body of the tag
	#  note that this passes all previously defined indicies
	# TODO - should check $objects[$index]->isa(Text::PORE::Object)
	$globals->LoadAttributes('_context' => $objects->[$index]);
	$self->error($body->traverse($globals));
	# TODO - should check for errors on return
    }
    
    # restore the original context
    $globals->LoadAttributes('_context', $context_tmp);
    
    # restore any previously held value of their index variable.
    #  note that if it was not defined before, this will not define it
    #  (which is what we want)
    if (defined $index_name) {
	$globals->{'_index'}->LoadAttributes($index_name, $index_tmp);
    }

    return $self->errorDump();
}

# ContextTagFunc: changes context of object to given attribute of current 
# context object
# tag: <PORE.context attr=...>
sub ContextTagFunc {
    my $self = shift;
    my $globals = shift;

    my $body = $self->{'body'};
    my %attr = %{$self->{'attrs'}};

    my $context;
    my $context_tmp;

    my ($attr_name) = $attr{'attr'};
    $context = $self->retrieveSlot($globals, $attr_name);

    # TODO - same as in ListTagFunc
    if (! $context) {
	$self->error("Current object [$context] has no '$attr_name' attribute");
	return $self->errorDump();
    }
    # TODO - same as in ListTagFunc
    if (! ref($context)) {
	$self->error("The attribute '$attr_name' of object $context is not an object.");
	return $self->errorDump();
    }

    $context_tmp = $globals->GetAttribute('_context');
    $globals->LoadAttributes('_context' => $context);
    $self->error($body->traverse($globals));
    $globals->LoadAttributes('_context' => $context_tmp);

    return $self->errorDump();
}

# LinkTagFunc: outputs an HREF link to the attribute of the current object.
# Returns an error if this attribute is not itself an object.
# tag: <PORE.link attr=...>
sub LinkTagFunc {
    my $self = shift;
    my $globals = shift;
    
    my $body = $self->{'body'};
    my %attr = $self->{'attrs'};

    my ($attr_name) = $attr{'attr'};
    my ($object) = $self->retrieveSlot($globals, $attr_name);
    
    if (! $object) {
	$self->error("Current object has no '$attr_name' attribute");
    }
    elsif (! ref($object)) {
	$self->error("The attribute '$attr_name' of current object ".
		     "is not an object.");
    }
    else {
	$self->output('<A HREF="' . $object->ToLink() . '">');
	
	$self->error($body->traverse($globals));
	
	$self->output('</A>');
    }
    
    return $self->errorDump();
}

sub DetermineRange {
    my $self = shift;
    my $tmp = $self->{'attrs'}{'range'};
    my @list;
    
    $_ = $tmp;
    while ($_) {
	s/^\s*,?\s*//;

	# Note: we must subtract from indecies to compensate for
	#  differences in array first element (0 or 1)
	s/^(\d+)\s*-\s*(\d+)// && do {
	    push (@list, ($1<$2) ? $1-1..$2-1 : reverse $2-1..$1-1);
	    redo;
	};
	s/^(\d+)// && do {
	    push (@list, $1-1);
	    redo;
	};
	s/^(\D+)// && do {
	    $self->error("Bad range spec '$1'");
	};
    }

    @list;
}

1;
