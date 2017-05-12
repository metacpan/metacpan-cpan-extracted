# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Number.pm 17 2006-02-12T08:00:01.814064Z mrodrigu  $

package Tree::XPathEngine::Number;
use Tree::XPathEngine::Boolean;
use Tree::XPathEngine::Literal;
use strict;

use overload
        '""' => \&value,
        '0+' => \&value,
        '<=>' => \&xpath_cmp;

sub new {
    my $class = shift;
    my $number = shift;
    if ($number !~ /^\s*[+-]?(\d+(\.\d*)?|\.\d+)\s*$/) {
        $number = undef;
    }
    else {
        $number =~ s/^\s*(.*)\s*$/$1/;
    }
    bless \$number, $class;
}

sub as_string {
    my $self = shift;
    defined $$self ? $$self : 'NaN';
}

sub as_xml {
    my $self = shift;
    return "<Number>" . (defined($$self) ? $$self : 'NaN') . "</Number>\n";
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

sub evaluate {
    my $self = shift;
    $self;
}

sub xpath_to_boolean {
    my $self = shift;
    return $$self ? Tree::XPathEngine::Boolean->_true : Tree::XPathEngine::Boolean->_false;
}

sub xpath_to_literal { Tree::XPathEngine::Literal->new($_[0]->as_string); }
sub xpath_to_number { $_[0]; }

sub xpath_string_value { return $_[0]->value }

1;
__END__

=head1 NAME

Tree::XPathEngine::Number - Simple numeric values.

=head1 DESCRIPTION

This class holds simple numeric values. It doesn't support -0, +/- Infinity,
or NaN, as the XPath spec says it should, but I'm not hurting anyone I don't think.

=head1 API

=head2 new($num)

Creates a new Tree::XPathEngine::Number object, with the value in $num. Does some
rudimentary numeric checking on $num to ensure it actually is a number.

=head2 value()

Also as overloaded stringification. Returns the numeric value held.

=head2 Other Methods

Those are needed so the objects can be properly processed in various contexts

=over 4

=item as_string 

=item as_xml 

=item value 

=item xpath_cmp

=item evaluate

=item xpath_to_boolean 

=item xpath_to_literal 

=item xpath_to_number 

=item xpath_string_value 

=back

=cut
