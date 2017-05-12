package XML::NewsML_G2::Desk;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

XML::NewsML_G2::Desk - an editorial desk in a news agency

=head1 SYNOPSIS

    my $desk = XML::NewsML_G2::Desk->new
        (name => 'Sports', qcode => 'spo');

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
