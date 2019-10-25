package XML::NewsML_G2::Remote_Info;

use Moose;
use namespace::autoclean;

has 'reluri', isa => 'Str', is => 'ro';
has 'href',   isa => 'Str', is => 'ro';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Remote_Info - the news provider (news agency)

=head1 SYNOPSIS

    my $apa = XML::NewsML_G2::Remote_Info->new(reluri => 'http://www.iana.org/assignments/relation/icon', href => 'http://test.com/123.jpg');

=head1 ATTRIBUTES

=over 4

=item reluri

describing the concept

=item href

href to remote content

=back

=head1 AUTHOR

Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2016, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
