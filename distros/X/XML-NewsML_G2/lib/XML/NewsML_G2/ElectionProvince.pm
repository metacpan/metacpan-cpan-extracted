package XML::NewsML_G2::ElectionProvince;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::ElectionProvince - a province region used during an election

=head1 SYNOPSIS

    my $at = XML::NewsML_G2::ElectionDistrict->new
        (name => 'Niederoesterreich', qcode => 'electionprovince:12345');

=head1 ATTRIBUTES

=over 4

=item name

Name of the Province the Election News Item is for

=back

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
