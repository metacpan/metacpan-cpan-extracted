package XML::NewsML_G2::Binary;

use XML::NewsML_G2::Types;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::Remote';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Binary - an arbitrary binary specification

=head1 SYNOPSIS

    my $blob = XML::NewsML_G2::Spec->new
        (size => 2231259,
         mimetype => 'application/pdf'
        );

=head1 ATTRIBUTES

=over 4

=item size

The size in bytes of the audio file

=item mimetype

The MIME type of the binary file (e.g. application/pdf)

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
