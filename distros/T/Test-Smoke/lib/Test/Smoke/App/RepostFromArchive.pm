package Test::Smoke::App::RepostFromArchive;
use warnings;
use strict;

our $VERSION = '0.002';

use base 'Test::Smoke::App::Base';

use File::Spec::Functions qw(catfile curdir);
use Test::Smoke::Poster;
use POSIX qw(strftime);

=head1 NAME

Test::Smoke::App::RepostFromArchive - The tsrepostjsn.pl application.

=head1 SYNOPSIS

Interactive:

   $ tsrepostjsn.pl -c smokecurrent
    Show the last 10 reports:
      1 jsn7a29e8d2c80588346422b4b6b936e6f8b56a3af4.jsn (2022-09-04 05:16:49 +0200)
      2 jsn69bc7167fa24b1e8d3f810ce465d84bdddf413f6.jsn (2022-09-03 05:15:11 +0200)
      3 jsncd55125d69f5f698ef7cbdd650cda7d2e59fc388.jsn (2022-09-02 05:14:42 +0200)
      4 jsn0c33882a943825845dde164b60900bf224b131cc.jsn (2022-09-01 05:15:05 +0200)
      5 jsnb885e42dc2078e29df142cfcefaa86725199d15b.jsn (2022-08-31 05:15:16 +0200)
      6 jsne772cf349a3609ba583f441d10e1e92c5e338377.jsn (2022-08-30 05:15:01 +0200)
      7 jsnf603e191e0bea582034a16f05909a56bcc05a564.jsn (2022-08-29 05:15:14 +0200)
      8 jsn51634b463845a03d4f22b9d23f6c5e2fb98af9c8.jsn (2022-08-28 05:15:47 +0200)
      9 jsn305697f3995f7ddfba2e200c5deb2e274e1136c0.jsn (2022-08-27 05:15:34 +0200)
     10 jsn18fa8a6f818cbe2838cfe9b1bfa0c5d9c311930c.jsn (2022-08-26 05:15:41 +0200)
   Type the numbers (with white space inbetween): 1 2 3

Or direct:

    $ tsrepostjsn.pl -c smokecurrent --sha 7a29e8d2c8058 --sha 69bc7167fa2 --sha cd55125d69f5f698ef7cbdd6

=head1 OPTIONS

  --max-reports <cnt>     Number of reports to choose from (10)

  --sha <commit-sha>      Commit SHA for the smoke (repeat for more reports)

  --jsonreport <filename> The actual json-file to re-post

Override the config:

  --adir <dir>         Archive directory
  --smokedb_url <url>  Where to POST to for CoreSmokeDB
  --poster <poster>    Use another poster

=head1 DESCRIPTION

=head2 Test::Smoke::App::RepostFromArchive->new()

Creates a new attribute C<poster> of class L<Test::Smoke::Poster>.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{_poster} = Test::Smoke::Poster->new(
        $self->option('poster') => $self->options,

        # We will need to fake 'ddir' in order to get the reports from the
        # archive
        ddir => $self->option('adir'),
        v    => $self->option('verbose'),
    );

    return $self;
}

=head2 $reposter->run()

Get a list of C<< jsn<commit-sha>.jsn >> filenames from the C<adir> archive
directory an try to send them to the report server at C<smokedb_url> again.

=cut

sub run {
    my $self = shift;

    my @to_post = $self->pick_reports();
    for my $report (@to_post) {
        $self->log_info("Reposting '%s' to %s\n", $report, $self->option('smokedb_url'));
        $self->poster->jsnfile($report);
        my $id = $self->poster->post($report);
        $self->log_info("Report posted with id: %s", $id || "<error>");
    }
}

=head2 $reposter->pick_reports()

First checks for reports passed on the command line with C<< --sha <commit-sha>
>>.  If none were passed it fetches the latest reports C<--max-reports> from the
archive directory C<adir> and lets you pick 1 or more.

=head3 Returns

A list of filenames representing the json files from the archive.

=cut

sub pick_reports {
    my $self = shift;

    if (my $jsonreport = $self->option('jsonreport')) {
        die("Cannot find '$jsonreport'") unless -f $jsonreport;
        if ($jsonreport =~ m{^ / }x) {
            $self->poster->ddir('');
        }
        else {
            $self->poster->ddir(curdir());
        }
        return ($jsonreport);
    }

    my $entries = $self->fetch_jsn_from_archive;
    my $max_entries = scalar(keys %$entries);

    my $commits = $self->option('commit_sha');
    if (@$commits) {
        # tranlate (partial) sha into filenames
        my @reports;
        for my $commit (@$commits) {
            my @candidates = grep { $_ =~ m{^ jsn $commit [0-9a-f]* \.jsn $}x } keys %$entries;
            push @reports, $candidates[0] if @candidates;
        }
        return @reports;
    }

    my $max = $self->option('max_reports');
    $max > $max_entries and $max = $max_entries;

    my @short_list = (
        sort {
            $entries->{$b}{mtime} <=> $entries->{$a}{mtime}
        } keys %$entries
    )[0..$max - 1];

    $max = @short_list;
    my @reports;
    printf "Show the last %u reports:\n", $max;
    for my $cnt (1..$max) {
        printf
            "%3u %-35s (%s)\n",
            $cnt, $short_list[$cnt - 1],
            strftime(
                "%Y-%m-%d %H:%M:%S %z",
                localtime($entries->{ $short_list[$cnt - 1] }{mtime})
            );
    }
    print "Type the numbers (with white space inbetween): ";
    chomp(my $input = <STDIN>);
    my @picks = grep { m{^ [0-9]+ $}x && $_ >= 1 && $_ <= $max } split(" ", $input);
    for my $pick (@picks) {
        push @reports, $short_list[$pick - 1];
    }
    return @reports;
}

sub fetch_jsn_from_archive {
    my $self = shift;

    my %entries;
    my $adir = $self->option('adir');
    opendir(my $dh, $adir) or die "Cannot opendir($adir): $!";
    while (my $entry = readdir($dh)) {
        my $fn = catfile($adir, $entry);
        next unless -f $fn;
        next unless $entry =~ m{^ jsn [0-9a-f]+ \.jsn $}x;
        $entries{$entry} = {
            mtime     => (stat $fn)[9],
            fullname  => $fn,
        };
    }
    closedir($dh);

    return \%entries;
}

1;

=head1 COPYRIGHT

E<copy> 2002-2022, Abe Timmerman <abeltje@cpan.org> All rights reserved.

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

