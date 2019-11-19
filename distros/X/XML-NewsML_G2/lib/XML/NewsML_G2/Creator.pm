package XML::NewsML_G2::Creator;

use Moose;
use namespace::autoclean;

has 'name', isa => 'Str', is => 'ro', required => 1;

has 'kind', isa => 'Str', is => 'ro';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Creator - creator of content

=head1 SYNOPSIS

    my $genre = XML::NewsML_G2::Creator->new(name => 'Max Mustermann', kind => 'staff');

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
