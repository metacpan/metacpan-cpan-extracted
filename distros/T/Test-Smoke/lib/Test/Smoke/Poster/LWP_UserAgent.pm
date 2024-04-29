package Test::Smoke::Poster::LWP_UserAgent;
use warnings;
use strict;

our $VERSION = '0.002';

use base 'Test::Smoke::Poster::Base';

=head1 NAME

Test::Smoke::Poster::LWP_UserAgent - Poster subclass using LWP::UserAgent.

=head1 DESCRIPTION

This is a subclass of L<Test::Smoke::Poster::Base>.

=head2 Test::Smoke::Poster::LWP_UserAgent->new(%arguments)

=head3 Extra Arguments

=over

=item ua_timeout => a timeout te feed to L<LWP::UserAgent>.

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    require LWP::UserAgent;
    my %extra_args;
    if (defined $self->ua_timeout) {
        $extra_args{timeout} = $self->ua_timeout;
    }
    $self->{_ua} = LWP::UserAgent->new(
        agent => $self->agent_string(),
        %extra_args
    );

    return $self;
}

=head2 $poster->_post_data()

Post the json to CoreSmokeDB using LWP::UserAgent.

=cut

sub _post_data {
    my $self = shift;

    $self->log_info("Posting to %s via %s.", $self->smokedb_url, $self->poster);
    $self->log_debug("Report data: %s", my $json = $self->get_json);

    my $response = $self->ua->post(
        $self->smokedb_url,
        { json => $json }
    );
    if ( !$response->is_success ) {
        $self->log_warn("POST failed: %s", $response->status_line);
        die sprintf(
            "POST to '%s' failed: %s%s\n",
            $self->smokedb_url,
            $response->status_line,
            ($response->content ? sprintf(" (%s)", $response->content) : ""),
        );
    }

    $self->log_debug("[CoreSmokeDB] %s", $response->content);

    return $response->content;
}

=head2 $poster->_post_data_api()

This uses the (newish) API function to post the data.

=cut

sub _post_data_api {
    my $self = shift;

    $self->log_info("Posting to %s via %s.", $self->smokedb_url, $self->poster);
    $self->log_debug("Report data: %s", my $json = $self->get_json);

    my $post_data = sprintf(qq/{"report_data": %s}/, $json);

    require HTTP::Request;
    require HTTP::Headers;
    my $request = HTTP::Request->new(
        POST => $self->smokedb_url,
        HTTP::Headers->new('Content-Type', 'application/json'),
        $post_data,
    );
    my $response = $self->ua->request($request);
    if (!$response->is_success) {
        $self->log_warn("POST failed: %s", $response->status_line);
        if (not $self->queue_this_report()) {
            die sprintf(
                "POST to '%s' failed: %s%s\n",
                $self->smokedb_url,
                $response->status_line,
                ($response->content ? sprintf(" (%s)", $response->content) : ""),
            );
        }
    }

    $self->log_debug("[CoreSmokeDB] %s", $response->content);

    return $response->content;
}

1;

=head1 COPYRIGHT

(c) 2002-2015, Abe Timmerman <abeltje@cpan.org> All rights reserved.

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
