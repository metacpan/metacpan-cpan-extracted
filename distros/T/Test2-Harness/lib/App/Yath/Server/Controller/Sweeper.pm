package App::Yath::Server::Controller::Sweeper;
use strict;
use warnings;

our $VERSION = '2.000005';

use App::Yath::Schema::Sweeper;
use App::Yath::Server::Response qw/resp error/;
use Test2::Harness::Util::JSON qw/encode_json encode_pretty_json/;

use parent 'App::Yath::Server::Controller';
use Test2::Harness::Util::HashBase;

sub title { 'Sweeper' }

sub handle {
    my $self = shift;
    my ($route) = @_;

    my $req = $self->{+REQUEST};
    my $res = resp(200);

    die error(404 => 'Missing route') unless $route;
    my $count = $route->{count} or die error(404 => 'No count');
    my $units = $route->{units} or die error(404 => 'No units');

    my $interval = "$count $units";

    my $sweeper = App::Yath::Schema::Sweeper->new(
        interval => $interval,
        config   => $self->{+SCHEMA_CONFIG},
    );

    my $purged = $sweeper->sweep;

    my $ct ||= lc($req->headers->{'content-type'} || $req->parameters->{'Content-Type'} || $req->parameters->{'content-type'} || 'text/html; charset=utf-8');
    $res->content_type($ct);

    if ($ct eq 'application/json') {
        $res->raw_body($purged);
    }
    else {
        $res->raw_body("<pre>" . encode_pretty_json($purged) . "</pre>");
    }

    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Server::Controller::Sweeper - Controller for triggering database sweeps

=head1 DESCRIPTION

=head1 SYNOPSIS

TODO

=head1 SOURCE

The source code repository for Test2-Harness-UI can be found at
F<http://github.com/Test-More/Test2-Harness-UI/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

=pod

=cut POD NEEDS AUDIT

