
package XML::ED;

our $VERSION = 'v0.0.2';

=head1 NAME

XML::ED - A process to impliemtent editing of xml files.

=head1 VERSION

v0.0.2

=over 4

=item new

   new

=cut

sub new 
{
    my $class = shift;

    bless { @_ }, $class;
}

=item parse

my $xml = $ed->parse(text => <<XML);

=cut

sub parse
{
    require XML::ED::Bare;
    require XML::ED::Node;
    require XML::ED::NodeSet;
    my $self = shift;
    my %p = @_;

    my $text = delete $p{text};

    my ($a, $b) = XML::ED::Bare->new(text => $text);
    return $b;
}



1;

__END__

=back

=head1 AUTHOR

G. Allen Morris III <gam3@gam3.net>

=head1 COPYRIGHT

Copyright (C) 2010 G. Allen Morris III.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<XML::ED::Bare>, L<XML::Node>, L<XML::NodeSet>,
L<XML::Bare>, L<XML::XPath>

F<META.yml> Specification:

L<http://www.gam3.org/>

=cut


[30]    	ForwardAxis 	   ::=    	("child" "::")
| ("descendant" "::")
| ("attribute" "::")
| ("self" "::")
| ("descendant-or-self" "::")
| ("following-sibling" "::")
| ("following" "::")
| ("namespace" "::")
[33]    	ReverseAxis 	   ::=    	("parent" "::")
| ("ancestor" "::")
| ("preceding-sibling" "::")
| ("preceding" "::")
| ("ancestor-or-self" "::")

