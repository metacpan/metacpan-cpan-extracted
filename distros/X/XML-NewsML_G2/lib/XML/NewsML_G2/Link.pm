package XML::NewsML_G2::Link;


use Moose;
use namespace::autoclean;

has 'residref', isa => 'Str', is => 'rw', required => 1;
has 'version', isa => 'Int', is => 'rw', default => 1;

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

XML::NewsML_G2::Link - a link specification

=head1 SYNOPSIS

    my $pic = XML::NewsML_G2::Link->new
        (idref => 'tag:acme.com,2015:123456',
         version => 2,
        );

=head1 ATTRIBUTES

=over 4

=item residref

A unique id as free text

=item version

The version of the item

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2015, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
