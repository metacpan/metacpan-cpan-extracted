# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Util::XmlMapper;

=pod

=head1 NAME

Wombat::Util::XmlMapper - xml file parser

=head1 SYNOPSIS

  my $mapper = Wombat::Util::XmlMapper->new();
  $mapper->setValidating(1);

  $mapper->addRule('Server', $mapper->objectCreate('Wombat::Core::Server'));
  $mapper->addRule('Server', $mapper->setProperties());

=head1 DESCRIPTION

Configures a set of actions to take while parsing an XML file.

=cut

use fields qw(attributes body elements objects rules);
use strict;
use warnings;

use XML::Parser::PerlSAX ();
use Wombat::Exception ();
use Wombat::Util::XmlAction ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Create and return an instance, initializing fields to default values.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{attributes} = [];
    $self->{body} = '';
    $self->{elements} = [];
    $self->{objects} = [];
    $self->{rules} = {};

    return $self;
}

=pod

=head1 PUBLIC METHODS

=over

=item addRule($xpath, $action)

Add a rule that specifies an action to be taken for each node with the
given xpath.

=cut

sub addRule {
    my $self = shift;
    my $xpath = shift;
    my $action = shift;

    return 1 unless $xpath && $action;

    $self->{rules}->{$xpath} ||= [];
    push @{ $self->{rules}->{$xpath} }, $action;

    return 1;
}

=pod

=item objectCreate($class, [$attribute])

Return an action that creates an object and adds it to the stack. If
an attribute is specified, that attribute's value will be used as the
class name; otherwise the specified class will be defaulted to.

=cut

sub objectCreate {
    my $self = shift;
    my $class = shift;
    my $attr = shift;

    return Wombat::Util::XmlMapper::ObjectCreateAction->new($class, $attr);
}

=pod

=item setProperties()

Return an action that calls a property setter method on the object at
the top of the stack for each attribute in the curent element.

=cut

sub setProperties {
    my $self = shift;

    return Wombat::Util::XmlMapper::SetPropertiesAction->new();
}

=pod

=item addChild($method)

Return an action that uses the named method to add the object at the
top the stack as a child of the object just below it in the stack.

=cut

sub addChild {
    my $self = shift;
    my $method = shift;

    return Wombat::Util::XmlMapper::AddChildAction->new($method);
}

=pod

=item methodSetter($method, [$num])

Return an action that calls the named method on the object at the top
of the stack. Method parameters are taken from the specified number of
sub-elements of the current element, or from the body of the current
element if 0 sub-elements are specified.

=cut

sub methodSetter {
    my $self = shift;
    my $method = shift;
    my $num = shift;

    return Wombat::Util::XmlMapper::MethodSetterAction->new($method, $num);
}

=pod

=item methodParam($index, [$attribute])

Return an action that extracts the value for the named attribute on
the current element, or the body of the current element if no
attribute is provided, and sets it in the array at the top of the
stack ath tindicated index. Use this method to accumulate parameter
values for a previously called C<methodSetter()> action.

=cut

sub methodParam {
    my $self = shift;
    my $index = shift;
    my $attribute = shift;

    return Wombat::Util::XmlMapper::MethodParamAction->new($index,
                                                           $attribute);
}

=pod

=item readXml($fh. [$root])

Read and parse an XML stream and perform all configured
actions. Return the root of the generated object hierarchy, optionally
using the provided root object.

=cut

sub readXml {
    my $self = shift;
    my $fh = shift;
    my $root = shift;

    push @{ $self->{objects} }, $root if $root;

    eval {
        my $parser = XML::Parser::PerlSAX->new(Handler => $self);
        $parser->parse(Source => {ByteStream => $fh});
    };
    Wombat::XmlException->throw($@) if $@;

    return $self->{objects}->[0];
}

=pod

=back

=cut

# private methods

sub match {
    my $self = shift;

    my $xpath = join '/', @{ $self->{elements} };
    my @matches = $self->{rules}->{$xpath} ?
        @{ $self->{rules}->{$xpath} } :
            ();

    return wantarray ? @matches : \@matches;
}

# private SAX handler methods

sub start_element {
    my $self = shift;
    my $props = shift;

    push @{ $self->{elements} }, $props->{Name};
    push @{ $self->{attributes} }, $props->{Attributes};

    my @matches = $self->match();
    for my $action (@matches) {
        $action->start($self);
    }

    $self->{body} = '';

    return 1;
}

sub end_element {
    my $self = shift;
    my $props = shift;

    my @matches = $self->match();
    for my $action (@matches) {
        $action->end($self);
    }
    for my $action (@matches) {
        $action->cleanup($self);
    }

    pop @{ $self->{elements} };
    pop @{ $self->{attributes} };

    return 1;
}

sub characters {
    my $self = shift;
    my $props = shift;

    $self->{body} .= $props->{Data};

    return 1;
}

package Wombat::Util::XmlMapper::ObjectCreateAction;

use base qw(Wombat::Util::XmlAction);
use fields qw(attribute class);

sub new {
    my $self = shift;
    my $class = shift;
    my $attribute = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{attribute} = $attribute;
    $self->{class} = $class;

    return $self;
}

sub start {
    my $self = shift;
    my $mapper = shift;

    my $clazz;
    if ($self->{attribute}) {
        my $attrs = $mapper->{attributes};
        my $top = @$attrs - 1;
        $clazz = $attrs->[$top]->{$self->{attribute}} if $top >= 0;
    }
    $clazz ||= $self->{class};

    unless ($clazz) {
        my $elements = $mapper->{elements};
        my $eltop = (keys %$elements) - 1;
        my $msg =
            "no class found for object create action [$elements->[$eltop]]";
        Wombat::ConfigException->throw($msg);
    }

    eval "require $clazz";
    Wombat::ConfigException->throw($@) if $@;

    my $obj = eval { $clazz->new() };
    Wombat::ConfigException->throw($@) if $@;

    push @{ $mapper->{objects} }, $obj;

    return 1;
}

sub cleanup {
    my $self = shift;
    my $mapper = shift;

    # leave the "root" object on
    pop @{ $mapper->{objects} } unless @{ $mapper->{objects} } == 1;

    return 1;
}

package Wombat::Util::XmlMapper::SetPropertiesAction;

use base qw(Wombat::Util::XmlAction);

sub start {
    my $self = shift;
    my $mapper = shift;

    my $objtop = @{ $mapper->{objects} } - 1;
    my $obj = $mapper->{objects}->[$objtop];
    return 1 unless $obj;

    my $attrtop = @{ $mapper->{attributes} } - 1;
    my $attrs = $mapper->{attributes}->[$attrtop];
    return 1 unless $attrs;

    while (my ($name, $val) = each %$attrs) {
        my $setter = 'set' . ucfirst $name;
        $obj->$setter($self->trim($val)) if $obj->can($setter);
    }

    return 1;
}

package Wombat::Util::XmlMapper::AddChildAction;

use base qw(Wombat::Util::XmlAction);
use fields qw(method);

sub new {
    my $self = shift;
    my $method = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{method} = $method;

    return $self;
}

sub end {
    my $self = shift;
    my $mapper = shift;

    my $top = @{ $mapper->{objects} } - 1;
    my $obj = $mapper->{objects}->[$top];
    my $parent = $mapper->{objects}->[$top - 1];

    my $meth = $self->{method};
    $parent->can($meth) or
        Wombat::ConfigException->throw("no method $meth for parent $parent");
    $parent->$meth($obj);

    return 1;
}

package Wombat::Util::XmlMapper::MethodSetterAction;

use base qw(Wombat::Util::XmlAction);
use fields qw(method numParams);

sub new {
    my $self = shift;
    my $method = shift;
    my $numParams = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{method} = $method;
    $self->{numParams} = $numParams;

    return $self;
}

sub start {
    my $self = shift;
    my $mapper = shift;

    push @{ $mapper->{objects} }, [] if $self->{numParams};

    return 1;
}

sub end {
    my $self = shift;
    my $mapper = shift;

    my $params = $self->{numParams} ?
        pop @{ $mapper->{objects} } :
            [ $mapper->{body} ];

    my $top = @{ $mapper->{objects} } - 1;
    my $parent = $mapper->{objects}->[$top];
    return 1 unless $parent;

    my $meth = $self->{method};
    $parent->can($meth) or
        Wombat::ConfigException->throw("no method $meth for parent $parent");
    $parent->$meth(map { $self->trim($_) } @$params);

    return 1;
}

package Wombat::Util::XmlMapper::MethodParamAction;

use base qw(Wombat::Util::XmlAction);
use fields qw(attribute index);

sub new {
    my $self = shift;
    my $index = shift;
    my $attribute = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{attribute} = $attribute;
    $self->{index} = $index;

    return $self;
}

sub start {
    my $self = shift;
    my $mapper = shift;

    return 1 unless $self->{attribute};

    my $top = @{ $mapper->{objects} } - 1;
    my $array = $mapper->{objects}->[$top];
    return 1 unless $array && ref $array eq 'ARRAY';

    my $attrtop = @{ $mapper->{attributes} } - 1;
    my $attr = $mapper->{attributes}->[$attrtop];
    return 1 unless $attr;

    $array->[$self->{index}] = $self->trim($attr->{$self->{attribute}});

    return 1;
}

sub end {
    my $self = shift;
    my $mapper = shift;

    return 1 if $self->{attribute};

    my $top = @{ $mapper->{objects} } - 1;
    my $array = $mapper->{objects}->[$top];
    return 1 unless $array && ref $array eq 'ARRAY';

    $array->[$self->{index}] = $self->trim($mapper->{body});

    return 1;
}

1;
__END__

=pod

=head1 SEE ALSO

L<Wombat::Util::XmlAction>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
