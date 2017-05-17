package Test::Smoke::App::SmokePerl;
use warnings;
use strict;

our $VERSION = '0.001';

use base 'Test::Smoke::App::Base';

use Test::Smoke::App::Archiver;
use Test::Smoke::App::Reporter;
use Test::Smoke::App::RunSmoke;
use Test::Smoke::App::SendReport;
use Test::Smoke::App::SyncTree;

use Test::Smoke::App::Options;
my $opt = 'Test::Smoke::App::Options';

use Test::Smoke::Util 'get_patch';

=head1 NAME

Test::Smoke::App::SmokePerl - The tssmokeperl.pl application.

=head1 DESCRIPTION

=head2 $app->run();

Run all the parts:

=over

=item * synctree

=item * runsmoke

=item * report

=item * sendrpt

=item * archive

=back

=cut

sub run {
    my $self = shift;
    $self->log_debug("Read configuration from: %s", $self->option('configfile'));

    my $old_commit = get_patch($self->option('ddir'))->[0] || "";
    if ($self->option('smartsmoke') && $self->option('patchlevel')) {
        $old_commit = $self->option('patchlevel');
    }
    $self->log_debug("Commitlevel before sync: %s", $old_commit);

    my $current_commit;
    if ($self->option('sync')) {
        local @ARGV = @{$self->ARGV};
        $self->{_synctree} = Test::Smoke::App::SyncTree->new(
            $opt->synctree_config()
        );
        $self->log_info("==> Starting synctree");
        $current_commit = $self->synctree->run();
    }
    else {
        $self->log_warn("==> Skipping synctree");
        $current_commit = get_patch($self->option('ddir'))->[0];
    }
    $self->log_debug("Commitlevel after sync: %s", $current_commit);

    if ($self->option('smartsmoke') && ($current_commit eq $old_commit)) {
        $self->log_warn("Skipping this smoke, commit(%s) did not change.", $old_commit);
        return;
    }
    {
        local @ARGV = @{$self->ARGV};
        $self->{_runsmoke} = Test::Smoke::App::RunSmoke->new(
            $opt->runsmoke_config()
        );
        $self->log_info("==> Starting runsmoke");
        $self->runsmoke->run();
    }

    if ($self->option('report')) {
        local @ARGV = @{$self->ARGV};
        $self->{_reporter} = Test::Smoke::App::Reporter->new(
            $opt->reporter_config()
        );
        $self->log_info("==> Starting reporter");
        $self->reporter->run();
    }
    else {
        $self->log_warn("==> Skipping reporter");
    }

    if ($self->option('sendreport')) {
        local @ARGV = @{$self->ARGV};
        $self->{_sendreport} = Test::Smoke::App::SendReport->new(
            $opt->sendreport_config()
        );
        $self->log_info("==> Starting sendreport");
        $self->sendreport->run();
    }
    else {
        $self->log_warn("==> Skipping sendreport");
    }

    if ($self->option('archive')) {
        local @ARGV = @{$self->ARGV};
        $self->{_archiver} = Test::Smoke::App::Archiver->new(
            $opt->archiver_config()
        );
        $self->log_info("==> Starting archiver");
        $self->archiver->run();
    }
    else {
        $self->log_warn("==> Skipping archiver");
    }
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
