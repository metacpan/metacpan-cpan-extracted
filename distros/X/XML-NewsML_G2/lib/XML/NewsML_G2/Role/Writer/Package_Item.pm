package XML::NewsML_G2::Role::Writer::Package_Item;

use Moose::Role;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::Writer';

around '_build_g2_catalog_schemes' => sub {
    my ( $orig, $self, @args ) = @_;
    my $result = $self->$orig(@args);
    $result->{group} = undef;
    return $result;
};


1;
__END__

=head1 NAME

XML::NewsML_G2::Role::Writer::Package_Item - Role for writing package items

=head1 DESCRIPTION

This module serves as a role for all NewsML-G2 writer classes and get automatically applied when the according news item type is written

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
