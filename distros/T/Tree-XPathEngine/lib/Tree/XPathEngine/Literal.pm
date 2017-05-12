# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Literal.pm 17 2006-02-12T08:00:01.814064Z mrodrigu  $

package Tree::XPathEngine::Literal;
use Tree::XPathEngine::Boolean;
use Tree::XPathEngine::Number;
use strict;

use overload 
		'""' => \&value,
		'cmp' => \&xpath_cmp;

sub new {
	my $class = shift;
	my ($string) = @_;
	
#	$string =~ s/&quot;/"/g;
#	$string =~ s/&apos;/'/g;
	
	bless \$string, $class;
}

sub as_string {
	my $self = shift;
	my $string = $$self;
	$string =~ s/'/&apos;/g;
	return "'$string'";
}

sub as_xml {
    my $self = shift;
    my $string = $$self;
    return "<Literal>$string</Literal>\n";
}

sub value {
	my $self = shift;
	$$self;
}

sub xpath_cmp {
	my $self = shift;
	my ($cmp, $swap) = @_;
	if ($swap) {
		return $cmp cmp $$self;
	}
	return $$self cmp $cmp;
}

sub evaluate {
	my $self = shift;
	$self;
}

sub xpath_to_boolean {
	my $self = shift;
	return (length($$self) > 0) ? Tree::XPathEngine::Boolean->_true : Tree::XPathEngine::Boolean->_false;
}

sub xpath_to_number { return Tree::XPathEngine::Number->new($_[0]->value); }
sub xpath_to_literal { return $_[0]; }

sub xpath_string_value { return $_[0]->value; }

1;
__END__

=head1 NAME

Tree::XPathEngine::Literal - Simple string values.

=head1 DESCRIPTION

In XPath terms a Literal is what we know as a string.

=head1 API

=head2 new($string)

Create a new Literal object with the value in $string. Note that &quot; and
&apos; will be converted to " and ' respectively. That is not part of the XPath
specification, but I consider it useful. Note though that you have to go
to extraordinary lengths in an XML template file (be it XSLT or whatever) to
make use of this:

	<xsl:value-of select="&quot;I'm feeling &amp;quot;sad&amp;quot;&quot;"/>

Which produces a Literal of:

	I'm feeling "sad"

=head2 value()

Also overloaded as stringification, simply returns the literal string value.

=head2 xpath_cmp($literal)

Returns the equivalent of perl's cmp operator against the given $literal.

=head2 Other Methods

Those are needed so the objects can be properly processed in various contexts

=over 4

=item as_string 

=item as_xml 

=item value 

=item evaluate

=item xpath_to_boolean 

=item xpath_to_literal 

=item xpath_to_number 

=item xpath_string_value 

=back

=cut
