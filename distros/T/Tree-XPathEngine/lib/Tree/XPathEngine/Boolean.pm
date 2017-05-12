# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Boolean.pm 17 2006-02-12T08:00:01.814064Z mrodrigu  $

package Tree::XPathEngine::Boolean;
use Tree::XPathEngine::Number;
use Tree::XPathEngine::Literal;
use strict;

use overload
		'""' => \&value,
		'<=>' => \&xpath_cmp;

sub _true {
	my $class = shift;
	my $val = 1;
	bless \$val, $class;
}

sub _false {
	my $class = shift;
	my $val = 0;
	bless \$val, $class;
}

sub value {
	my $self = shift;
	$$self;
}

sub xpath_cmp {
	my $self = shift;
	my ($other, $swap) = @_;
	if ($swap) {
		return $other <=> $$self;
	}
	return $$self <=> $other;
}

sub xpath_to_number { Tree::XPathEngine::Number->new($_[0]->value); }
sub xpath_to_boolean { $_[0]; }
sub xpath_to_literal { Tree::XPathEngine::Literal->new($_[0]->value ? "true" : "false"); }

sub xpath_string_value { return $_[0]->xpath_to_literal->value; }

1;
__END__

=head1 NAME

Tree::XPathEngine::Boolean - Boolean true/false values

=head1 DESCRIPTION

Tree::XPathEngine::Boolean objects implement simple boolean true/false objects.

=head1 API

=head2 Tree::XPathEngine::Boolean->_true

Creates a new Boolean object with a true value.

=head2 Tree::XPathEngine::Boolean->_false

Creates a new Boolean object with a false value.

=head2 value()

Returns true or false.

=head2 xpath_to_literal()

Returns the string "true" or "false".

=head2 xpath_string_value 

=head2 xpath_cmp

=head2 xpath_to_boolean

=head2 xpath_to_number

