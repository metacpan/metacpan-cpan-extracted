package XML::Atom::Ext::Media::Thumbnail;
our $VERSION = '0.092840';


#ABSTRACT: Represents <media:thumbnail> elements

use strict;
use warnings;

use base qw( XML::Atom::Base );


__PACKAGE__->mk_attr_accessors(qw/url height width time/);


sub element_ns {
    return XML::Atom::Ext::Media->element_ns;
}


sub element_name {
    return 'thumbnail';
}

1;



=pod

=head1 NAME

XML::Atom::Ext::Media::Thumbnail - Represents <media:thumbnail> elements

=head1 VERSION

version 0.092840

=head1 ATTRIBUTES

=head2 url

=head2 height

=head2 width

=head2 time



=head2 element_ns

Returns our L<XML::Atom::Namespace> object, akin to L<XML::Atom::Ext::Media/element_ns>



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
