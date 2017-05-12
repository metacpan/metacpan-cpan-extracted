package XML::Atom::Ext::Media::Content;
our $VERSION = '0.092840';


#ABSTRACT: Represents <media:content> elements

use strict;
use warnings;

use base qw( XML::Atom::Ext::Media::Base );


__PACKAGE__->mk_attr_accessors(
    qw/url fileSize type medium isDefault expression
    bitrate framerate samplingrate channels duration height
    width lang/
);

sub element_name {
    return 'content';
}

1;


__END__

=pod

=head1 NAME

XML::Atom::Ext::Media::Content - Represents <media:content> elements

=head1 VERSION

version 0.092840

=head1 SEE ALSO

=over 

=item * L<XML::Atom::Ext::Media::Base>

=back 

=cut
=head1 ATTRIBUTES

=head2 url

=head2 fileSize

=head2 type

=head2 medium

=head2 isDefault

=head2 expression

=head2 bitrate

=head2 framerate

=head2 samplingrate

=head2 channels

=head2 duration

=head2 height

=head2 width

=head2 lang



=head1 AUTHOR

  Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 


