package XML::NewsML_G2::Inline_CData;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::Inline_Data';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Inline_CData - inline cdata specification

=head1 SYNOPSIS

    my $data = XML::NewsML_G2::Inline_CData->new
        (mimetype => 'text/xml',
         data => '<somexml>test</somexml>'
        );

=head1 ATTRIBUTES

=over 4

=item data

The inline string data

=item mimetype

The MIME type of the data (e.g. text/xml)

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015-2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
