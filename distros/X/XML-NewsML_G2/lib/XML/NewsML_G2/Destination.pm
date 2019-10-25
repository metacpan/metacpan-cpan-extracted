package XML::NewsML_G2::Destination;

use Moose;
use namespace::autoclean;

# header elements
has 'name',
    isa      => 'Str',
    is       => 'ro',
    required => 1;
has 'role',
    isa => 'Str',
    is  => 'ro';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Destination - a container that can hold Destination Attributes

=head1 SYNOPSIS

    my $destination1 = XML::NewsML_G2::Destination->new(name => 'DEST1', role => 'dest:mailing');
    my $destination2 = 'DEST2';

    my $nm = XML::NewsML_G2::News_Message->new;
    $nm->add_destination($destination1);
    $nm->add_destination($destination2);

=head1 ATTRIBUTES

=over 4

=item name

Destination name

=item role

Optional role

=back

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
