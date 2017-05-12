package yEd::Node::GenericNode;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Node);
use Carp;

=head1 NAME

yEd::Node::GenericNode - Generic node type

=head1 DESCRIPTION

This is a very generic node type. 
Its shape is defined by its C<configuration> property.
Special configurations are defined by using java style properties.
This indeed makes the Node type very generic and versatile but also cumbersome to configure as you don't have a GUI.

For configuration of these java style properties use C<getJavaStyle()> and C<setJavaStyle()>.

Make sure to have a look at L<yEd::Node>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The GenericNode type are the nodes defined in the following yEd groups:

=over 4
    
=item *
    
Modern Nodes
    
=item *
    
Flowchart
    
=item *
    
BPMN
    
=item *
    
Entity Relationship
    
=back

However the node types defined in BPMN are not supported, yet.

The Entity Relationship Nodes are added with no Labels, you have to provide them yourself.

For basic Node type feature support and which Node types are supported see L<yEd::Node>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Node>

=head2 configuration

Type: descrete values ( see L</CONFIGURATIONS> section )

Default: 'com.yworks.flowchart.cloud'

The specialized type of GenericNode.

The cloud has been choosen as default because I think people may need it as basic shape even if not working on a flowchart and on the other hand it is one of the types with a rather long identifier. 

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Node>

=cut

 my %r = (
    'bool' => '^(?:true|false)$',
    'false' => '^false$',
 );
 # This one describes the known StyleProperties and how to handle them
 my %styleProperty = (
    'ModernNodeShadow' => {
        'class' => 'java.lang.Boolean',
        'match' => $r{'bool'},
        'default' => 'false',
        'hidevalues' => $r{'false'},
    },
    'ModernNodeRadius' => {
        'class' => 'java.lang.Double',
        'match' => $match{'ufloat'},
        'default' => '10.0',
    },
    'y.view.ShadowNodePainter.SHADOW_PAINTING' => {
        'class' => 'java.lang.Boolean',
        'match' => $r{'bool'},
        'default' => 'false',
    },
    'com.yworks.flowchart.style.orientation' => {
        'class' => 'java.lang.Byte',
        'match' => '^[01234]$',
        'default' => '0',
    },
    'doubleBorder' => {
        'class' => 'java.lang.Boolean',
        'match' => $r{'bool'},
        'default' => 'false',
        'hidevalues' => $r{'false'},
    },
 );
 # This one describes the known Configurations and which StyleProperties they support
 my %Configuration = (
    # Modern Nodes
    'BevelNode' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'BevelNode2' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'BevelNode3' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'BevelNodeWithShadow' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'ShinyPlateNode' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'ShinyPlateNode2' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'ShinyPlateNode3' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    'ShinyPlateNodeWithShadow' => {
        'ModernNodeRadius' => 1,
        'ModernNodeShadow' => 1,
    },
    # Flowchart
    'com.yworks.flowchart.start1' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.start2' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.terminator' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.process' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.predefinedProcess' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.decision' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.loopLimit' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.loopLimitEnd' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.document' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.data' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.directData' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.storedData' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.sequentialData' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.dataBase' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.internalStorage' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.manualInput' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.card' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.paperType' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.cloud' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.delay' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.display' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.manualOperation' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.preparation' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.onPageReference' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.offPageReference' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.userMessage' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.networkMessage' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.flowchart.annotation' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
        'com.yworks.flowchart.style.orientation' => 1,
    },
    # Entity Relationship
    'com.yworks.entityRelationship.big_entity' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
    },
    'com.yworks.entityRelationship.small_entity' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
        'doubleBorder' => 1,
    },
    'com.yworks.entityRelationship.relationship' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
        'doubleBorder' => 1,
    },
    'com.yworks.entityRelationship.attribute' => {
        'y.view.ShadowNodePainter.SHADOW_PAINTING' => 1,
        'doubleBorder' => 1,
    },
 );

my $confregex = '^(?:';
$confregex .=  join '|', keys %Configuration;
$confregex .= ')$'; 

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;
    $self->configuration('com.yworks.flowchart.cloud');
    $self->SUPER::_init(@args);
    return $self;
}

sub configuration {
    return _PROPERTY($confregex, @_);
}

=head2 setJavaStyle

Takes arguments of the form 'property1 => value, property2 => value2, ...' and sets the provided java style properties accordingly.

=head3 EXAMPLE

    $node->setJavaStyle('y.view.ShadowNodePainter.SHADOW_PAINTING' => 'true');

=cut

sub setJavaStyle {
    my $self = shift;
    confess 'properties must be supplied as key => value pairs (odd number supplied)' if(@_ % 2);
    my %props = @_;
    foreach my $key (keys %props) {
        confess "no such property: $key" unless (exists $styleProperty{$key});
        my $r = $styleProperty{$key}{'match'};
        my $v = $props{$key};
        confess "value for property $key doesn't match $r (given value: $v)" unless ($v =~ m/$r/);
        $self->{'java'}{$key} = $v;
    }
    return;
}

=head2 getJavaStyle

Takes a java style property name as parameter and returns its current value.

=head3 EXAMPLE

    if ($node->getJavaStyle('y.view.ShadowNodePainter.SHADOW_PAINTING') eq 'true') { ...

=cut

sub getJavaStyle {
    my ($self, $sp) = @_;
    if (exists $self->{'java'}{$sp}) {
        return $self->{'java'}{$sp};
    }
    return $styleProperty{$sp}{'default'};
}

sub _addTypeNode {
    my ($self, $node) = @_;
    my $gen = $node->addNewChild('', 'y:GenericNode');
    $gen->setAttribute('configuration', $self->configuration());
    return $gen;
}
sub _addAdditionalNodes {
    my ($self, $node) = @_;
    my $t = $self->configuration();
    my @props;
    foreach my $sp (keys %{$Configuration{$t}}) {
        if (exists $styleProperty{$sp}{'hidevalues'}) {
            push @props, $sp unless ($self->getJavaStyle($sp) =~ m/$styleProperty{$sp}{'hidevalues'}/);
        } else {
            push @props, $sp;
        }
    }
    if (@props) {
        my $styles = $node->addNewChild('', 'y:StyleProperties');
        foreach my $sp (@props) {
            my $p = $styles->addNewChild('', 'y:Property');
            $p->setAttribute('class', $styleProperty{$sp}{'class'});
            $p->setAttribute('name', $sp);
            $p->setAttribute('value', $self->getJavaStyle($sp));
        }
    }
}

=head1 KNOWN JAVA STYLE PROPERTIES

See L</CONFIGURATIONS> for which C<configuration> supports which style.

=head2 ModernNodeShadow

Type: java.lang.Boolean ('true'|'false')

Default: 'false'

use shadow

=head2 ModernNodeRadius

Type: java.lang.Double (ufloat, no negative values allowed here)

Default: 10.0

corner radius

=head2 y.view.ShadowNodePainter.SHADOW_PAINTING

Type: java.lang.Boolean ('true'|'false')

Default: 'false'

use shadow

=head2 com.yworks.flowchart.style.orientation

Type: java.lang.Byte (^[01234]$)

Default: 0

orientation of single side border (0 = auto, 1..4 = edges)

=head2 doubleBorder

Type: java.lang.Boolean ('true'|'false')

Default 'false'

draw a second border with a slight inset to the first

=head1 CONFIGURATIONS

=head2 yEd Group: Modern Nodes

Styles all: ModernNodeRadius , ModernNodeShadow

Configurations:

=over 4

=item * 

BevelNode

=item * 

BevelNode2

=item * 

BevelNode3

=item * 

BevelNodeWithShadow

=item * 

ShinyPlateNode

=item * 

ShinyPlateNode2

=item * 

ShinyPlateNode3

=item * 

ShinyPlateNodeWithShadow

=back

=head2 yEd Group: Flowchart

Styles all: y.view.ShadowNodePainter.SHADOW_PAINTING

Configurations:

=over 4

=item * 

com.yworks.flowchart.start1

=item * 

com.yworks.flowchart.start2

=item * 

com.yworks.flowchart.terminator

=item * 
    
com.yworks.flowchart.process

=item * 
    
com.yworks.flowchart.predefinedProcess

=item * 
    
com.yworks.flowchart.decision

=item * 
    
com.yworks.flowchart.loopLimit

=item * 
    
com.yworks.flowchart.loopLimitEnd

=item * 
    
com.yworks.flowchart.document

=item * 
    
com.yworks.flowchart.data

=item * 
    
com.yworks.flowchart.directData

=item * 
    
com.yworks.flowchart.storedData

=item * 
    
com.yworks.flowchart.sequentialData

=item * 
    
com.yworks.flowchart.dataBase 

=item * 
    
com.yworks.flowchart.internalStorage

=item * 
    
com.yworks.flowchart.manualInput

=item * 
    
com.yworks.flowchart.card

=item * 
    
com.yworks.flowchart.paperType

=item * 
    
com.yworks.flowchart.cloud

=item * 
    
com.yworks.flowchart.delay

=item * 
    
com.yworks.flowchart.display

=item * 
    
com.yworks.flowchart.manualOperation

=item * 
    
com.yworks.flowchart.preparation

=item * 
    
com.yworks.flowchart.onPageReference

=item * 
    
com.yworks.flowchart.offPageReference

=item * 
    
com.yworks.flowchart.userMessage

=item * 
    
com.yworks.flowchart.networkMessage

=item * 
    
com.yworks.flowchart.annotation

Styles: y.view.ShadowNodePainter.SHADOW_PAINTING , com.yworks.flowchart.style.orientation
    
=back

=head2 yEd Group: Entity Relationship

Configurations:

=over 4

=item * 

com.yworks.entityRelationship.big_entity

Styles: y.view.ShadowNodePainter.SHADOW_PAINTING

=item * 

com.yworks.entityRelationship.small_entity

Styles: y.view.ShadowNodePainter.SHADOW_PAINTING , doubleBorder

=item * 

com.yworks.entityRelationship.relationship

Styles: y.view.ShadowNodePainter.SHADOW_PAINTING , doubleBorder

=item * 

com.yworks.entityRelationship.attribute

Styles: y.view.ShadowNodePainter.SHADOW_PAINTING , doubleBorder

=back

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Node> for information about the Node base class and which other Node types are currently supported

=cut


1;
