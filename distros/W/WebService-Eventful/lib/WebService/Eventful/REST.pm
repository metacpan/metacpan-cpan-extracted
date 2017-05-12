package WebService::Eventful::REST;

use strict;
use warnings;

=head1 NAME

WebService::Eventful::REST - Use the REST flavor of the Eventful API

=head1 SYNOPSIS

    my $evdb    = WebService::Eventful->new(app_key => $app_key);
    my $results = $evdb->call('events/get', { id => 'E0-001-001336058-5' });

=head1 DESCRIPTION

Parses XML from the Eventful API.

=head1 VERSION

1.0 - September 2006
1.04 - August 2013
=cut

our $VERSION = 1.04;

=head1 METHODS

=head2 flavor

Return the flavor name.

=cut

sub flavor { 'rest' }

=head2 ctype

Return a checkstring for the expected return content type.

=cut

sub ctype { 'xml' }

=head2 parse

Parse XML data from the Eventful API using L<XML::Twig> or
L<XML::Simple>.

=cut

sub parse {
    my ($class, $data, $force_array) = @_;

    eval { require XML::Twig };
    if ($@) {
        require XML::Simple;

        my $xs = XML::Simple->new(
            KeyAttr       => [],
            SuppressEmpty => '',
        );

        return $xs->XMLin($data, ForceArray => $force_array);
    }
    else {
        my $twig = XML::Twig->new;
        $twig->parse($data);
        my $parsed = $twig->simplify(keyattr => [], forcearray => $force_array);
        $twig->purge;

        return $parsed;
    }
}

=head1 AUTHORS

=over 4 

=item * Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4 

=item * L<WebService::Eventful>

=item * L<XML::Twig>

=item * L<XML::Simple>

=back

=cut

1;
