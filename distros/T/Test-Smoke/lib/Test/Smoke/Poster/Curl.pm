package Test::Smoke::Poster::Curl;
use warnings;
use strict;

our $VERSION = '0.002';

use base 'Test::Smoke::Poster::Base';

use File::Temp qw(tempfile);
use URI::Escape qw(uri_escape);

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

    my $form_data = sprintf("json=%s", uri_escape($json));
    my ($fh, $filename) = tempfile('curl-tsrepostXXXXXX', TMPDIR => 1);
    print $fh $form_data;
    close($fh);

    my $response = $self->curl->run(
        '-A' => $self->agent_string(),
        '-d' => "\@$filename",
        ($self->ua_timeout    ? ('--max-time' => $self->ua_timeout) : ()),
        ($self->curl->verbose ? () : '--silent'),
        @{ $self->curlargs },
        $self->smokedb_url,
    );
    1 while unlink($filename);

    if ($self->curl->exitcode) {
        $self->log_warn("[POST] curl exitcode: %d %s", $self->curl->exitcode, $response || '');
        die sprintf(
            "POST to '%s' curl failed: %d\n",
            $self->smokedb_url,
            $self->curl->exitcode
        );
    }

    $self->log_debug("[CoreSmokeDB] %s", $response);

    return $response;
}

=head2 $poster->_post_data_api()

Post the json to CoreSmokeDB API-function using L<curl(1)>.

=cut

sub _post_data_api {
    my $self = shift;

    $self->log_info("Posting to %s via %s.", $self->smokedb_url, $self->poster);
    $self->log_debug("Report data: %s", my $json = $self->get_json);

    my $post_data = sprintf(qq/{"report_data": %s}/, $json);
    my ($fh, $filename) = tempfile('curl-tsrepostXXXXXX', TMPDIR => 1);
    print {$fh} $post_data;
    close($fh);

    my $response = $self->curl->run(
        '-H' => 'Content-Type: application/json',
        '-A' => $self->agent_string(),
        '-d' => "\@$filename",
        ($self->ua_timeout    ? ('--max-time' => $self->ua_timeout) : ()),
        ($self->curl->verbose ? () : '--silent'),
        @{ $self->curlargs },
        $self->smokedb_url,
    );
    1 while unlink($filename);

    if ($self->curl->exitcode) {
        $self->log_warn(
            "[POST] curl exitcode: %d %s",
            $self->curl->exitcode, $response || ''
        );
        if (not $self->queue_this_report()) {
            die sprintf(
                "POST to '%s' curl failed: %d\n",
                $self->smokedb_url,
                $self->curl->exitcode
            );
        }
    }

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
