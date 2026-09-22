package Test2::Harness::UI::Controller::Sweeper;
use strict;
use warnings;

our $VERSION = '0.000148';

use Test2::Harness::UI::Sweeper;
use Test2::Harness::UI::Response qw/resp error/;
use Test2::Harness::Util::JSON qw/encode_json encode_pretty_json/;

use parent 'Test2::Harness::UI::Controller';
use Test2::Harness::UI::Util::HashBase;

sub title { 'Sweeper' }

sub handle {
    my $self = shift;
    my ($route) = @_;

    my $req = $self->{+REQUEST};
    my $res = resp(200);

    die error(401 => 'Login required') unless $req->user;
    die error(404 => 'Missing route') unless $route;
    my $count = $route->{count} or die error(404 => 'No count');
    my $units = $route->{units} or die error(404 => 'No units');

    my $interval = "$count $units";

    my $sweeper = Test2::Harness::UI::Sweeper->new(
        interval => $interval,
        config   => $self->{+CONFIG},
    );

    my $purged = $sweeper->sweep;

    my $ct = lc($req->parameters->{'content-type'} || $req->parameters->{'Content-Type'} || '');
    my $wants_json = $ct eq 'application/json';
    $res->content_type($wants_json ? 'application/json' : 'text/html; charset=utf-8');

    if ($wants_json) {
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

Test2::Harness::UI::Controller::Sweeper

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

Copyright 2019 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
