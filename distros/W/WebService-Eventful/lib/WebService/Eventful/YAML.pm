package WebService::Eventful::YAML;

use strict;
use warnings;
use Carp;

=head1 NAME

WebService::Eventful::YAML - Use the YAML flavor of the Eventful API

=head1 SYNOPSIS

    my $evdb    = WebService::Eventful->new(app_key => $app_key, flavor => 'yaml');
    my $results = $evdb->call('events/get', { id => 'E0-001-001336058-5' });

=head1 DESCRIPTION

Parses YAML from the Eventful API.

=head1 VERSION

1.0 - September 2006
1.04 - August 2013

=cut

our $VERSION = 1.04;

=head1 METHODS

=head2 flavor

Return the flavor name.

=cut

sub flavor { 'yaml' }

=head2 ctype

Return a checkstring for the expected return content type.

=cut

sub ctype { 'yaml' }

=head2 parse

Parse YAML data from the Eventful API using L<YAML::Syck> or L<YAML>.

=cut

sub parse {
    my ($class, $data, $force_array) = @_;

    carp "Forcing arrays is not supported for API flavor " . $class->flavor
        if $force_array;

    eval { require YAML::Syck };
    if ($@) {
        require YAML;
        return YAML::Load($data);
    }
    else {
        return YAML::Syck::Load($data);
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

=item * L<YAML::Syck>

=item * L<YAML>

=back

=cut

1;
