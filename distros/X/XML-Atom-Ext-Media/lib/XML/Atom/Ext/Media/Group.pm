package XML::Atom::Ext::Media::Group;
our $VERSION = '0.092840';


#ABSTRACT: Represents <media:grouå> elements

use strict;
use warnings;

use base qw( XML::Atom::Ext::Media::Base );


__PACKAGE__->mk_object_list_accessor(
    content => 'XML::Atom::Ext::Media::Content', 'contents' 
);


sub default_content {
    my ($self) = @_;
    
    my @contents = $self->contents;
    foreach (@contents) {
        return $_ if $_->isDefault;
    }
    # Fallback to the first one
    return $contents[0];
}
sub element_name {
    return 'group';
}

1;


__END__

=pod

=head1 NAME

XML::Atom::Ext::Media::Group - Represents <media:grouå> elements

=head1 VERSION

version 0.092840

=head1 SEE ALSO

=over 

=item * L<XML::Atom::Ext::Media::Base>

=back 

 

=head1 ATTRIBUTES

=head2 content

Returns the first L<XML::Atom::Ext::Media::Content> object in SCALAR context,
or a list of them in LIST context.

=head2 contents

Returns a ARRAYREF in SCALAR context and otherwise behaves like L<content>



=head1 METHODS

=head2 default_content

Will look through L</contents> for any element that
returns true for isDefault. If no such element is found,
it will return the first element in L</contents>



=head1 AUTHOR

  Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 


