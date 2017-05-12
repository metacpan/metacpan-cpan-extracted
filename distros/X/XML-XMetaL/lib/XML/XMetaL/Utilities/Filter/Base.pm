package XML::XMetaL::Utilities::Filter::Base;

use strict;
use warnings;

use base 'XML::XMetaL::Utilities::Abstract';


use Carp;

use XML::XMetaL::Utilities qw(:dom_node_types);

use constant TRUE  => 1;
use constant FALSE => 0;

sub new {
    my ($class) = @_;
    return bless {}, ref($class) || $class;
}

sub accept {$_[0]->abstract}

1;


__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Utilities::Filter::Base - Node filter base class

=head1 SYNOPSIS

 use XML::XMetaL::Utilities::Filter::Element;

 my $filter = XML::XMetaL::Utilities::Filter::Element->new();
 ...
 if ($filter->accept($dom_node)) {
    # Do something with the DOM node
 }
 ...

=head1 DESCRIPTION

The C<XML::XMetaL::Utilities::Filter::Base> class is a base class for
node filters.

Node filters are used to determine whether a DOM node fullfills a certain
set of conditions or not.

For example, C<XML::XMetaL::Utilities::Iterator> objects use node
filters to determine whether a node in the node tree should be returned
by the C<next> method.


=head2 Constructor and initialization

 use XML::XMetaL::Utilities::Filter::Element;
 my $filter = XML::XMetaL::Utilities::Filter::Element->new();

=head2 Class Methods

None.

=head2 Public Methods

=over 4

=item C<accept>

 my $boolean = $filter->accept($dom_node);

The C<accept> method takes a DOM node as an argument. The method
returns a true value if the filter conditions are accepted. If the
filter conditions are not fulfilled, the method returns a false value.

=back

=head2 Private Methods

None.

=head2 Node Filter List

Currently, the following node filters are available in the C<XML::XMetaL>
framework:

=over 4

=item C<XML::XMetaL::Utilities::Filter::All>

The C<accept> method always returns a true value.

=item C<XML::XMetaL::Utilities::Filter::Element>

The C<accept> method returns a true value when the node passed as an
argument is an element node.

The C<accept> method returns a false value for all other node types.

=back

=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>, L<XML::XMetaL::Utilities::Iterator>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
