package Test::Smoke::Poster::Curl;
use warnings;
use strict;

use base 'Test::Smoke::Poster::Base';

use CGI::Util ();                # escape() for HTML
use Test::Smoke::Util::Execute;

=head1 NAME

Test::Smoke::Poster::Curl - Poster subclass using curl.

=head1 DESCRIPTION

This is a subclass of L<Test::Smoke::Poster::Base>.

=head2 Test::Smoke::Poster::Curl->new(%arguments)

=head3 Extra Arguments

=over

=item curlbin => $fq_path_to_curl

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_curl} = Test::Smoke::Util::Execute->new(
        command => ($self->curlbin || 'curl'),
        verbose => $self->v
    );

    return $self;
}

=head2 $poster->_post_data()

Post the json to CoreSmokeDB using L<curl(1)>.

=cut

sub _post_data {
    my $self = shift;

    $self->log_info("Posting to %s via %s.", $self->smokedb_url, $self->poster);
    $self->log_debug("Report data: %s", my $json = $self->get_json);

    my $form_data = sprintf("json=%s", CGI::Util::escape($json));
    my $response = $self->curl->run(
        ($self->v ? () : '--silent'),
        '-A' => $self->agent_string(),
        '-d' => $form_data,
        $self->smokedb_url,
    );
    $self->log_debug("[CoreSmokeDB] %s", $response);

    return $response;
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
