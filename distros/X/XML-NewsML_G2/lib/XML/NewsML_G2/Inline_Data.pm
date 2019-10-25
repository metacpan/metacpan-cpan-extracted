package XML::NewsML_G2::Inline_Data;

use Moose;
use namespace::autoclean;

has 'data',     isa => 'Str', is => 'rw', required => 1;
has 'mimetype', isa => 'Str', is => 'rw', default  => 'text/plain';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Inline_Data - inline data specification

=head1 SYNOPSIS

    my $data = XML::NewsML_G2::Inline_Data->new
        (mimetype => 'text/plain',
         data => 'Hello World'
        );

=head1 ATTRIBUTES

=over 4

=item data

The inline string data

=item mimetype

The MIME type of the data (e.g. text/plain)

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
