# StandaloneTagNode -- 
# tag_type (scalar): type of tag
# pairs (hash): attribute-value pairs
package Text::PORE::Node::Standalone;

use Text::PORE::Node::Attr;
use Text::PORE::Group;
use strict;

@Text::PORE::Node::Standalone::ISA = qw(Text::PORE::Node::Attr);

my %StandaloneFunctions = (
				'render' => 'RenderTagFunc',
				'ref'    => 'RefTagFunc',
				'table'     => 'TableTagFunc',
				);

sub new {
    my $type = shift;
    my $lineno = shift;
    my $tag_type = shift;
    my $pairs = shift;

    my $self = bless {}, ref($type) || $type;

    $self = $self->SUPER::new($lineno, $tag_type, $pairs);

    bless $self, ref($type) || $type;
}

sub traverse {
    my $self = shift;
    my $globals = shift;

    $self->output("[$self->{'tag_type'}:$self->{'lineno'}]")
	if $self->getDebug();

    # lookup method
    my ($method) = $StandaloneFunctions{$self->{'tag_type'}};

    # execute that method
    if ($method) {
	$self->error($self->$method($globals));
    } else {
	$self->error("Unsupported tag [$self->{'tag_type'}]");
    }

    return $self->errorDump();
}

# RenderTagFunc: renders the attribute of the current object. Currently
# only prints that attribute out
sub RenderTagFunc {
    my $self = shift;
    my $globals = shift;

    my ($attr) = $self->retrieveSlot($globals, $self->{'attrs'}{'attr'});
    my ($tpl) = $self->retrieveSlot($globals, $self->{'attrs'}{'tpl'});


    if (ref($attr) =~ /ARRAY/) {
	$self->error("Cannot render array attribute '$self->{attrs}{attr}'");
    } elsif (ref($attr)) {
	$self->output($attr->ToHtml());   
	# TODO - Render according to default template 
    } else {
	$self->output($attr);
    }

    return $self->errorDump();
}

# RefTagFunc: returns a URL reference to the attribute of the current object.
# Returns an error if the attribute is not itself an object
sub RefTagFunc {
    my $self = shift;
    my $globals = shift;

    my (%attr) = %{$self->{'attrs'}};

    my ($attr_name) = $attr{'attr'};
    my ($attr) = $self->retrieveSlot($globals, $attr_name);

    # TODO - improve error test
    if (! $attr) {
	$self->error("Current object has no '$attr_name' attribute");
    }
    elsif (! ref($attr)) {
	$self->error("The attribute '$attr_name' of current " .
	      "object is not an object.");
    }
    else {
	$self->output($attr->ToLink());
    }

    return $self->errorDump();
}
    
# TableTagFunc: Formats contents of a list into a table. 
# tag: <PORE.table attr =... direction=(h|v) cols=... rows=... border=... 
#                  width=... cellspacing=... cellpadding=... align=.. 
#                  valign=...>
sub TableTagFunc {
    my $self = shift;
    my $globals = shift;

    my %attr = %{$self->{'attrs'}};

    my ($attr_name) = $attr{'attr'};
    my ($objects) = $self->retrieveSlot($globals, $attr_name);
    # TODO - probably should test isa()
    return unless $objects;

    # TODO - combine with previous statement
    if ($objects && ref($objects) !~ /ARRAY/) {
	$self->error("The attribute '$attr_name' of current object is not a list.");
	return $self->errorDump();
    }

    my ($strings);

    my ($object);
    foreach $object (@$objects) {
	my $string = ref($object) ? $object->ToHtml() : $object;
	push @$strings, $string;
    }
	
    delete $attr{'attr'};
    $attr{'table_items'} = $strings;
    my $table = new Table(%attr);
    $self->output($table->ToHtml);

    return $self->errorDump();
}

1;
