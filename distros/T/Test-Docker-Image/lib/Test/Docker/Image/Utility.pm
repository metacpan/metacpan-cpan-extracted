package Test::Docker::Image::Utility;

use strict;
use warnings;

use parent 'Exporter';
use IPC::Run3;
use Time::HiRes;

use constant DEBUG => $ENV{DEBUG_TEST_DOCKER_IMAGE};

our @EXPORT = qw(docker);

our @EXPORT_OK = qw(run);

sub WARN {
    my $msg = join " ",  @_;
    chomp $msg;
    warn sprintf "[%s %.5f] %s\n", __PACKAGE__, Time::HiRes::time, $msg;
}

sub docker { run('docker', @_); }

sub run {
    my (@cmd) = @_;

    DEBUG && WARN sprintf "Run [ %s ]", join ' ', @cmd;
    my $is_success = run3 [ @cmd ], \my $in, \my $out, \my $err;
    if ($is_success) {
        chomp $out;
        return $out;
    } else {
        die $err;
    }
}

1;
