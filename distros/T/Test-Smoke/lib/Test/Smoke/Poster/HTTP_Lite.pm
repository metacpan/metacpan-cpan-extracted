package Test::Smoke::Poster::HTTP_Lite;
use warnings;
use strict;
use Carp;

use base 'Test::Smoke::Poster::Base';

=head1 NAME

Test::Smoke::Poster::HTTP_Lite - Poster subclass using HTTP::Lite.

=head1 DESCRIPTION

This is a subclass of L<Test::Smoke::Poster::Base>.

=head2 Test::Smoke::Poster::HTTP::Lite->new(%arguments)

=head3 Extra Arguments

None.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    require HTTP::Lite;
    $self->{_ua} = HTTP::Lite->new();

    return $self;
}

=head2 $poster->_post_data()

Post the json to CoreSmokeDB using L<HTTP::Lite>.

=cut

sub _post_data {
    my $self = shift;

    $self->log_info("Posting to %s via %s.", $self->smokedb_url, $self->poster);
    $self->log_debug("Report data: %s", my $json = $self->get_json);

    $self->ua->prepare_post({ json => $json });
    $self->ua->add_req_header('User-Agent', $self->agent_string);
    $self->ua->request($self->smokedb_url) or croak("CoreSmokeDB: $!");

    return $self->ua->body;
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
