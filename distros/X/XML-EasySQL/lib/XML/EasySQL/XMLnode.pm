=head1 NAME

XML::EasySQL::XMLnode - This is a child class of XML::EasySQL::XMLobj::Node.

=head1 VERSION

Version 1.2

=head1 DESCRIPTION

XML::EasySQL::XMLnode just overloads some methods it inherited from it's
base, XML::EasySQL::XMLobj::Node.

If you're making a child XML::EasySQL::XMLnode class for
XML::EasySQL, be sure and use this class as the base and not
XML::EasySQL::XMLobj::Node.

=head1 SEE ALSO

XML::EasySQL::XMLobj

XML::EasySQL::XMLobj::Node

=cut

package XML::EasySQL::XMLnode;
use XML::EasySQL::XMLobj::Node;
@ISA = ('XML::EasySQL::XMLobj::Node');

use strict;

use vars qw/$VERSION/;
$VERSION = '1.2';

sub new {
        my $proto = shift;
        my $params = shift;
        my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new({doc=>$params->{doc}, ptr=>$params->{ptr}, constructor_params=>$params->{constructor_params}});
	$self->{db_parent} = $params->{db_parent};
	$self->{base_name} = undef;
	bless $self, $class;
}

sub BaseName {
	my $self = shift;
	my $name = shift;
	if(defined $name) {
		$self->{base_name} = $name;
	}
	return $self->{base_name};
}

sub makeNewNode {
	my $self = shift;
	my $node = $self->XML::EasySQL::XMLobj::Node::makeNewNode(@_);
	my $base_name;
	if(!defined $self->{base_name}) {
		$base_name = $node->getTagName();
	} else {
		$base_name = $self->{base_name};
	}
	$node->BaseName($base_name);
	$self->{db_parent}->flagSync($base_name);
	return $node;
}

sub setString {
	my $self = shift;
	$self->{db_parent}->flagSync($self->{base_name});
	return $self->XML::EasySQL::XMLobj::Node::setString(@_);
}

sub addString {
	my $self = shift;
	$self->{db_parent}->flagSync($self->{base_name});
	return $self->XML::EasySQL::XMLobj::Node::addString(@_);
}

sub setAttr {
	my $self = shift;
	if(!defined $self->{base_name}) {
		$self->{db_parent}->flagAttribSync($_[0]);
	} else {
		$self->{db_parent}->flagSync($self->{base_name});
	}
	return $self->XML::EasySQL::XMLobj::Node::setAttr(@_);
}

sub remAttr {
	my $self = shift;
	if(!defined $self->{base_name}) {
		$self->{db_parent}->flagAttribSync($_[0]);
	} else {
		$self->{db_parent}->flagSync($self->{base_name});
	}
	return $self->XML::EasySQL::XMLobj::Node::remAttr(@_);
}

sub remElement {
	my $self = shift;
	if(defined $self->{base_name}) {
		$self->{db_parent}->flagSync($self->{base_name});
	}
	return $self->XML::EasySQL::XMLobj::Node::remElement(@_);
}

1;

