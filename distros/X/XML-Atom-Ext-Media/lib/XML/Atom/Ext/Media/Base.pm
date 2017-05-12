package XML::Atom::Ext::Media::Base;
our $VERSION = '0.092840';


#ABSTRACT: Stuff shared between group and content

use strict;
use warnings;

use base qw( XML::Atom::Base );


__PACKAGE__->mk_elem_accessors(qw(title description keywords));


__PACKAGE__->mk_object_list_accessor(
    thumbnail => 'XML::Atom::Ext::Media::Thumbnail', 'thumbnails',
);


__PACKAGE__->mk_object_list_accessor(
    'category' => 'XML::Atom::Category', 'categories'
);


sub element_ns {
    return XML::Atom::Ext::Media->element_ns;
}


1;



=pod

=head1 NAME

XML::Atom::Ext::Media::Base - Stuff shared between group and content

=head1 VERSION

version 0.092840

=head1 CLASSES THAT INHERIT US

=over 

=item * L<XML::Atom::Ext::Media::Group>

=item * L<XML::Atom::Ext::Media::Content>

=back 

=cut
=head1 ATTRIBUTES

=head2 title

Returns the title for a <media:group> or <media:content>

=head2 description

Returns the description for a <media:group> or <media:content>

=head2 keywords

Returns the keywords string for a <media:group> or <media:content>



=head2 thumbnail

In SCALAR context it returns the first <media:thumbnail> we find in
this <media:group> or <media:content>.

In LIST context it will return all of them.

=head2 thumbnails

Like L<thumbnail>, but will in SCALAR context return an arrayref.



=head2 category

Will in SCALAR context return the first <media:category> as an
L<XML::Atom::Category>, and will in LIST context return an array
of all such objects.

=head2 categories

Will return an ARRAYREF in SCALAR context, otherwise like L<category>



=head2 element_ns

Returns the namescpare for this node, the same as for
L<XML::Atom::Ext::Media/element_ns>.

=head2 element_name

Implemented in the subclasses.

Returns the name of the namespaced element we represent, like group for <media:group>



=head1 AUTHOR

  Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

