package XML::NewsML_G2::Provider;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';


__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Provider - the news provider (news agency)

=head1 SYNOPSIS

    my $apa = XML::NewsML_G2::Provider->new(name => 'APA', qcode => 'apa');

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
