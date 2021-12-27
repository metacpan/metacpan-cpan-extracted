#!perl -T
use strict;
use warnings;
use Cwd qw(realpath);
use File::Spec;
use File::Temp qw(tempdir);
use List::MoreUtils qw(any);
use Test::Exception;
use Test::More tests => 4;

my %logdir_for;
BEGIN {
    %logdir_for = (
        default => tempdir(CLEANUP => 1),
        special => tempdir(CLEANUP => 1)
       );
}

use lib '.';
use t::make_ini {
    ini => [
        'TL' => [
            logdir => $logdir_for{default}
           ],
        'TL:special' => [
            logdir => $logdir_for{special}
           ]
       ]
};

BEGIN {
    use_ok('Tripletail', $t::make_ini::INI_FILE, 'special');
}

lives_ok { $TL->log('Abracadabra') } q{$TL->log() doesn't die};

sub tree {
    my $dir = shift;
    my %files;

    opendir my $dh, $dir
      or die "Failed to open directory $dir: $!";

    while (defined(my $file = readdir $dh)) {
        my $fpath = File::Spec->catfile($dir, $file);

        if (any {$file eq $_} File::Spec->curdir, File::Spec->updir) {
            next;
        }
        elsif (-d $fpath) {
            $files{$file} = { tree($fpath) };
        }
        else {
            $files{$file} = undef;
        }
    }

    return %files;
}

subtest 'Contents of the default logdir' => sub {
    plan tests => 1;

    my %contents = tree($logdir_for{default});

    is_deeply \%contents, {}, 'It must be empty'
      or diag explain \%contents;
};

subtest 'Contents of the special logdir' => sub {
    plan tests => 5;

    my %contents = tree($logdir_for{special});

    my @YYYYMM;
    while (my ($file, $dirContents) = each %contents) {
        if ($file =~ m/^\d{4}\d{2}$/ && defined $dirContents) {
            push @YYYYMM, $file;
        }
    }
    is scalar @YYYYMM, 1, 'Just one YYYYMM directory in the logdir';

    my @DD_hh_log;
    while (my ($file, $dirContents) = each %{ $contents{$YYYYMM[0]} }) {
        if ($file =~ m/^\d{2}-\d{2}\.log$/ && !defined $dirContents) {
            push @DD_hh_log, $file;
        }
    }
    is scalar @YYYYMM, 1, 'Just one DD-hh.log file in YYYYMM/';

    my $current = File::Spec->catfile($logdir_for{special}, 'current');
    my $logPath = File::Spec->catfile($logdir_for{special}, $YYYYMM[0], $DD_hh_log[0]);
    my $log     = $TL->readFile($logPath);

    like $log, qr/(^|\s)Abracadabra(\s|$)/, 'The content of log file looks sane'
      or diag $log;

    ok -r $current, 'There exists the "current" symlink in the logdir';
    is realpath($current), realpath($logPath), 'The "current" symlink is pointing to the correct file';
}
