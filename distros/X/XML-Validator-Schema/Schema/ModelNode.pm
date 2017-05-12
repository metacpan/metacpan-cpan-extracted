package XML::Validator::Schema::ModelNode;
use strict;
use warnings;
use base 'XML::Validator::Schema::Node';
use constant DEBUG => 0;

use Carp qw(croak);
use XML::Validator::Schema::Util qw(_err _attr);

=head1 NAME

XML:Validator::Schema::ModelNode

=head1 DESCRIPTION

Objects of this class represent the content models encountered while
parsing a schema.  After a model is completely parsed it is compiled
into a regular expression and a human-readbale description and
assigned to the element or complex type's 'model' attribute.

=cut

# parse a model based on a <sequence>, <choice>, <all> or <union> returning the
# appropriate subclass
sub parse {
    my ($pkg, $data) = @_;
    my $name = $data->{LocalName};
    croak("Unknown model type '$name'")
      unless $name eq 'sequence' or $name eq 'choice' or $name eq 'all'
             or $name eq 'union';    

    # construct as appropriate
    $pkg = "XML::Validator::Schema::" . ucfirst($name) . "ModelNode";
    my $self = $pkg->new();
   
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

    if ($name eq 'all') {
        _err("Found <all> with minOccurs neither 0 nor 1.")
          unless $self->{min} eq '1' or $self->{min} eq '0';
        _err("Found <all> with maxOccurs not 1.")
          unless $self->{max} eq '1';
    }

    return $self;
}

# compile a tree of elements and model nodes into a single model node
# attached to the containing element.  This results in a tree
# containing only elements and the element having a 'model' object
# with working check_model() and check_final_model() methods.
sub compile {
    my $self = shift;
    my $root = $self->mother;

    # the root will get assigned all the ElementNodes composing the model.
    $root->clear_daughters;

    # get two regular expressions, one for verifying the final
    # composition of the tree and the other for detecting problems
    # mid-model
    my ($final_re, $running_re, $desc) = $self->_compile($root);

    $self->{description} = $desc;

    # hold onto the strings if debugging
    $self->{final_re_string}   = $final_re if DEBUG;
    $self->{running_re_string} = $running_re if DEBUG;
    print STDERR "Compile <$root->{name}> content model to:\n\t/$self->{final_re_string}/\n\t/$self->{running_re_string}\n\t$self->{description}\n\n"
      if DEBUG;

    # compile the regular expressions
    eval {
        $self->{final_re} = qr/^$final_re$/;
        $self->{running_re} = qr/^$running_re$/;
    };
    croak("Problem compiling content model '<$root->{name}>' into regular expression: $@") if $@;

    # finished
    $self->clear_daughters;
    $root->{model} = $self;
}

# recursive worker for compilation of content models.  returns three
# text fragments - ($final_re, $running_re, $description)
sub _compile {
    my ($self, $root) = @_;
    my @final_parts;
    my @running_parts;
    my @desc_parts;

    foreach my $d ($self->daughters) {
        if ($d->isa('XML::Validator::Schema::ElementNode')) {
            my $re_name = quotemeta('<' . $d->{name} . '>');
            my $qual = _qual($d->{min}, $d->{max});
            my $re = length($qual) ? '(?:' . $re_name . ")$qual" : $re_name;
            push @final_parts, $re;

            my $running_qual = _qual($d->{min} eq '0' ? 0 : 1, $d->{max});
            my $running_re = length($running_qual) ? '(?:' . $re_name . ")$running_qual" : $re_name;
            push @running_parts, $running_re;

            push @desc_parts, $d->{name} . $qual;

            # push onto root's daughter list
            $root->add_daughter($d);

        } elsif ($d->isa('XML::Validator::Schema::ModelNode')) {
            # recurse    
            my ($final_part, $running_part, $desc) 
              = $d->_compile($root);
            push @final_parts, $final_part;
            push @running_parts, $running_part;
            push @desc_parts, $desc;
        } else {
            croak("What's a " . ref($d) . " doing here?");
        }
    }
    
    # combine parts into a regex matching the final and running contents
    my $final_re   = $self->_combine_final_parts(\@final_parts);
    my $running_re = $self->_combine_running_parts(\@running_parts);
    my $desc       = $self->_combine_desc_parts(\@desc_parts);

    return ($final_re, $running_re, $desc);
}

# assign a qualifier based on min/max
sub _qual {
    my ($min, $max) = @_;
    return ""        if $min eq '1' and $max eq '1';
    return "+"       if $min eq '1' and $max eq 'unbounded';
    return "?"       if $min eq '0' and $max eq '1';
    return "*"       if $min eq '0' and $max eq 'unbounded';
    return "{$min,}" if $max eq 'unbounded';
    return "{$min,$max}";
}

# method to check a final content model
sub check_final_model {
    my ($self, $this_name, $names_ref) = @_;

    # prepare names for regex
    my $names = join('', map { '<' . $_ . '>' } @$names_ref);

    print STDERR "Checking element string: '$names' against ".
                 "'$self->{final_re_string}'\n" if DEBUG;

    # do the match and return an error if necessary
    if ($names !~ /$self->{final_re}/) {
        _err("Contents of element '$this_name' do not match content model '$self->{description}'.");
    }
}

# method to check content model in mid-parse.  will succeed if the set
# of names constitute at least a prefix of the required content model.
sub check_model {
    my ($self, $this_name, $names_ref) = @_;

    # prepare names for regex
    my $names = join('', map { '<' . $_ . '>' } @$names_ref);

    print STDERR "Checking element string: '$names' against ".
                 "'$self->{running_re_string}'\n" if DEBUG;

    # do the match and blame $names[-1] for failures
    if ($names !~ /$self->{running_re}/) {
        _err("Inside element '$this_name', element '$names_ref->[-1]' does not match content model '$self->{description}'.");
    }
}

package XML::Validator::Schema::SequenceModelNode;
use base 'XML::Validator::Schema::ModelNode';

sub _combine_final_parts {
    my ($self, $parts) = @_;

    # build final re
    my $re = '(?:' . join('', @$parts) . ')' . 
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $re;
}

sub _combine_running_parts {
    my ($self, $parts) = @_;

    # build running re
    my $re = join('', map { "(?:$_" } @$parts) . 
             ")?" x @$parts;
    $re =~ s!\?$!!;
    $re .= XML::Validator::Schema::ModelNode::_qual($self->{min},$self->{max});
    return $re;
}

sub _combine_desc_parts {
    my ($self, $parts) = @_;

    # build description
    my $desc = '(' . join(',', @$parts) . ')' 
      . XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $desc;
}

package XML::Validator::Schema::ChoiceModelNode;
use base 'XML::Validator::Schema::ModelNode';

sub _combine_final_parts {
    my ($self, $parts) = @_;

    # build final re
    my $re = '(?:' . join('|', map { '(?:'. $_ . ')' } @$parts) . ')' .
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $re;
}

sub _combine_running_parts {
    my ($self, $parts) = @_;

    # build running re
    my $re = '(?:' . $self->_combine_final_parts($parts) . ')' .
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $re;
}

sub _combine_desc_parts {
    my ($self, $parts) = @_;

    # build description
    my $desc = '(' . join('|', @$parts) . ')' .
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $desc;
}

package XML::Validator::Schema::UnionModelNode;
use base 'XML::Validator::Schema::ModelNode';

sub _combine_final_parts {
    my ($self, $parts) = @_;

    # build final re
    my $re = '(?:' . join('|', map { '(?:'. $_ . ')' } @$parts) . ')' .
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $re;
}

sub _combine_running_parts {
    my ($self, $parts) = @_;

    # build running re
    my $re = '(?:' . $self->_combine_final_parts($parts) . ')' .
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $re;
}

sub _combine_desc_parts {
    my ($self, $parts) = @_;

    # build description
    my $desc = '(' . join('|', @$parts) . ')' .
      XML::Validator::Schema::ModelNode::_qual($self->{min}, $self->{max});

    return $desc;
}


package XML::Validator::Schema::AllModelNode;
use base 'XML::Validator::Schema::SequenceModelNode';

# an all is just a sequence that doesn't care about ordering and only
# accepts min/max of 0/1

sub _combine_final_parts {
    my ($self, $parts) = @_;
    return $self->SUPER::_combine_final_parts([sort sort_parts @$parts]);
}

sub _combine_running_parts {
    my ($self, $parts) = @_;
    return $self->SUPER::_combine_running_parts([sort sort_parts @$parts]);
}

sub _combine_desc_parts {
    my ($self, $parts) = @_;

    # build description
    my $desc = '(' . join('&', @$parts) . ')';

    return $desc;
}

# running model check not possible for all, right?
sub check_model {}

sub check_final_model {
    my ($self, $this_name, $names_ref) = @_;
    $self->SUPER::check_final_model($this_name, [sort @$names_ref]);
}

sub sort_parts {
    my( $a_element ) = $a =~ /<(.*?)\\>/;
    my( $b_element ) = $b =~ /<(.*?)\\>/;
    $a_element cmp $b_element;
}

1;
