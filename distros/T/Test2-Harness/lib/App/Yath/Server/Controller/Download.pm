package App::Yath::Server::Controller::Download;
use strict;
use warnings;

our $VERSION = '2.000005';

use List::Util qw/max/;
use Text::Xslate(qw/mark_raw/);
use App::Yath::Util qw/share_dir/;
use App::Yath::Server::Response qw/resp error/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;


use parent 'App::Yath::Server::Controller';
use Test2::Harness::Util::HashBase qw/-title/;

sub handle {
    my $self = shift;
    my ($route) = @_;

    my $req = $self->{+REQUEST};

    my $res = resp(200);

    my $user = $req->user;

    die error(404 => 'Missing route') unless $route;

    my $run;

    if ($self->single_run) {
        $run = $user->runs->first or die error(404 => 'Invalid run');
    }
    else {
        my $it = $route->{id} or die error(404 => 'No id');
        my $schema = $self->schema;
        $run = $schema->resultset('Run')->find({run_id => $it}) or die error(404 => 'Invalid Run');
    }

    my $log = $run->log_file;
    my $type = $log->name =~ m/\.bz2/ ? 'application/x-bzip2' : 'application/gzip';

    $res->content_type($type);
    $res->header('Content-Disposition' => "attachment; filename=" . $log->name);
    $res->body($log->data);
    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Server::Controller::Download - Controller for downloading log files

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

