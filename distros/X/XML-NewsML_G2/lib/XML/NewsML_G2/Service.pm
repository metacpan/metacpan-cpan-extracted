package XML::NewsML_G2::Service;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Service - a service produced by the news agency

=head1 SYNOPSIS

    my $svc = XML::NewsML_G2::Service->new
        (name => 'Economic News', qcode => 'eco');

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
