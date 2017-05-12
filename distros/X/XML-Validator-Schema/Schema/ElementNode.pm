package XML::Validator::Schema::ElementNode;
use strict;
use warnings;

=head1 NAME

XML::Validator::Schema::ElementNode - an element node in a schema object

=head1 DESCRIPTION

This is an internal module used by XML::Validator::Schema to represent
element nodes derived from XML Schema documents.

=cut

use base qw(XML::Validator::Schema::Node);
use XML::Validator::Schema::Util qw(_attr _err);

# create a node based on the contents of an <element> found in the
# schema document
sub parse {
    my ($pkg, $data) = @_;
    my $self = $pkg->new();

    my $name = _attr($data, 'name');
    _err('Found element without a name.')
      unless $name;
    $self->name($name);

    my $type_name = _attr($data, 'type');
    if ($type_name) {
        $self->{unresolved_type} = 1;
        $self->{type_name} = $type_name;
    }

    my $min = _attr($data, 'minOccurs');
    $min = 1 unless defined $min;
    _err("Invalid value for minOccurs '$min' found in <$name>.")
      unless $min =~ /^\d+$/;
    $self->{min} = $min;

    my $max = _attr($data, 'maxOccurs');
    $max = 1 unless defined $max;
    _err("Invalid value for maxOccurs '$max' found in <$name>.")
      unless $max =~ /^\d+$/ or $max eq 'unbounded';
    $self->{max} = $max;

    return $self;
}

# override add_daughter to check parent-specific requirements
sub add_daughter {
    my ($self, $d) = @_;

    # check that min/mix are 0 or 1 for 'all' contents
    if ($self->{is_all} and $d->isa('XML::Validator::Schema::ElementNode')) {
        _err("Element '$d->{name}' must have minOccurs of 0 or 1 because it is within an <all>.")
          unless ($d->{min} eq '0' or $d->{min} eq '1');
        _err("Element '$d->{name}' must have maxOccurs of 0 or 1 because it is within an <all>.")
          unless ($d->{max} eq '0' or $d->{max} eq '1');
    }

    return $self->SUPER::add_daughter($d);
}

# check contents of an element against declared type
sub check_contents {
    my ($self, $contents) = @_;

    # do type check if a type is declared
    if ($self->{type}) {

        # Union isn't really a simple type. In a sense it isn't a type
        # at all,  if it is, it sure as hell isn't simple.  It's just
        # a rather laissez-faire view of what the type might be.
        # Hence I've not handled union in SimpleType::check.  As it's
        # not handled directly in SimpleType, I've bastardized the usage
        # of $self->{type} to just contain a string effectively indicating
        # that it is an exception

        my ( $ok, $msg);
        if ($self->{type} eq 'union' ) {
            # it only has to match one of the member types:
            if ( not defined($self->{members}) ){
                die "Internal error: I aint got no members\n";
            } else {
                if (@{$self->{members}} == 0 ) {
		    _err("Element '$self->{name}' is a union with no members.");
                }
            } 

            my $types = '';
	    $ok = 0;
	    foreach my $m ( @{$self->{members}} ) {
                if ( not my $x = ref($m) ) {
		    die ("Internal error, that isn't a reference\n");
                }
                ( $ok, $msg ) = $m->{type}->check($contents); 
		last if $ok;
                $types .= ' '.$m->{type}->{base}->{name};
            }

	    if ( not $ok ) {
                # Just giving the error for the last one checked isn't
                # really that helpful.  We need to make it explicit that
                # NONE of the tests succeeded.
                $msg = "content does not match any of the union base types".
                  " [ $types ]";
            }
        } else {
            ($ok, $msg) = $self->{type}->check($contents);
        }
        _err("Illegal value '$contents' in element <$self->{name}>, $msg")
          unless $ok;
    }

    # mixed content isn't supported, so all complex elements must be
    # element only or have nothing but whitespace between the elements
    elsif ($self->{is_complex} and $contents =~ /\S/) {
        _err("Illegal character data found in element <$self->{name}>.");
    }
}

# check if a given name is a legal child, and return it if it is
sub check_daughter {
    my ($self, $name) = @_;
    my ($daughter) = grep { $_->{name} eq $name } ($self->daughters);

    # doesn't even exist?
    _err("Found unexpected <$name> inside <$self->{name}>.  This is not a valid child element.")
      unless $daughter;

    # push on
    push @{$self->{memory} ||= []}, $name;

    # check model
    $self->{model}->check_model($self->{name}, $self->{memory})
      if $self->{model};

    # does this daughter have a valid type?  if not, attempt to elaborate
    if ($daughter->{unresolved_type}) {
        $self->root->complete_type($daughter);
        ($daughter) = grep { $_->{name} eq $name } ($self->daughters);
    }
    
    # is this daughter a dangling ref?  if so, complete it
    if ($daughter->{unresolved_ref}) {
        $self->root->complete_ref($daughter);
        ($daughter) = grep { $_->{name} eq $name } ($self->daughters);
    }

    return $daughter;
}

# check that attributes are kosher
sub check_attributes {
    my ($self, $data) = @_;

    # get lists required and allowed attributes
    my (@required, %allowed);
    foreach my $attr (@{$self->{attr} || []}) {
        $allowed{$attr->{name}} = $attr;
        push(@required, $attr->{name}) if $attr->{required};
    }

    # check attributes
    my %saw;
    foreach my $jcname (keys %$data) {
        my $attr = $data->{$jcname};

        # attributes in the http://www.w3.org/2001/XMLSchema-instance
        # namespace are processing instructions, not part of the
        # document to be validated
        next if $attr->{NamespaceURI} 
          eq 'http://www.w3.org/2001/XMLSchema-instance';

        # attributes in http://www.w3.org/2000/xmlns/ are namespace
        # declarations and don't concern us
        next if $attr->{NamespaceURI} eq 'http://www.w3.org/2000/xmlns/';

        my $name = $attr->{LocalName};
        my $obj = $allowed{$name}; 
        _err("Illegal attribute '$name' found in <$self->{name}>.")
          unless $obj;
        $saw{$name} = 1;
        
        # does this obj have an incomplete type?  complete it
        if ($obj->{unresolved_type}) {
            $self->root->complete_attr_type($obj);
        }

        # check value, if attribute is typed
        if ($obj->{type}) {           
            my ($ok, $msg) = $obj->{type}->check($attr->{Value});
            _err("Illegal value '$attr->{Value}' for attribute '$name' in <$self->{name}>, $msg")
              unless $ok;
        }
    }
    
    # make sure all required attributes are present
    foreach my $name (@required) {
        _err("Missing required attribute '$name' in <$self->{name}>.")
          unless $saw{$name};
    }
}

# finish
sub compile {
    my $self = shift;

    if ($self->daughters and 
        ($self->daughters)[0]->isa('XML::Validator::Schema::ModelNode')) {
        ($self->daughters)[0]->compile;
    }
}

# forget about the past
sub clear_memory {
    @{$_[0]->{memory}} = () if $_[0]->{memory};
}


1;
