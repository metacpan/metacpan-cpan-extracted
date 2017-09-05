#!/usr/bin/perl
use strict;
use warnings;

use Test2::Harness::Run;
use Test2::Harness::Config;
use File::Spec;

my $config = Test2::Harness::Config->new(
    jobs         => 1,
    event_stream => 1,
#    merge   => 1,
    libs    => ['../Test2/lib', 'lib'],
    tests   => [['../Test2/t', '../Test2/']],
    preload => ['Child'],
);

my $run = Test2::Harness::Run->spawn(
    dir => './delme',
    run_id => 'xyz',
    config => $config,
);

waitpid($run->pid, 0);
print "Exit: $?\n";

wait;

__END__
use autodie;
use IO::Handle;

sub _die {
    my ($fh, @messages);
    my @caller = caller();
    print $fh @messages, " at $caller[1] line $caller[2].\n";
    exit 255;
}

sub _redirect_script {
    my ($file) = @_;

    return <<"    EOT";
use Time::HiRes qw/time/;
open(my \$fh, '>', '$file') or die "Could not open output file: \$!";
while (my \$in = <>) { print \$fh time; print \$fh ":"; print \$fh \$in };
exit 0;
    EOT
}

sub _redirect_io {
    my ($path) = @_;

    open(my $stdout, '>&', *STDOUT) or die "Cannot duplicate STDERR: $!";
    open(my $stderr, '>&', *STDERR) or die "Cannot duplicate STDERR: $!";
    close(STDOUT) or _die $stderr => "Could not close STDOUT";
    close(STDERR) or _die $stderr => "Could not close STDERR";

    open( STDOUT, '|-', $^X, '-e', _redirect_script("${path}.stdout"))
        or _die $stderr => "Could not open new STDOUT: $!";

    open( STDERR, '|-', $^X, '-e', _redirect_script("${path}.stderr"))
        or _die $stderr => "Could not open new STDERR: $!";

    return ($stdout, $stderr);
}

my ($stdout, $stderr) = _redirect_io('xxx');

print $stdout "STDOUT: " . fileno(STDOUT) . "\n";
print $stdout "STDERR: " . fileno(STDERR) . "\n";
print $stdout "stdout: " . fileno($stdout) . "\n";
print $stderr "stderr: " . fileno($stderr) . "\n";

print "Hi There STDOUT!\n";
print STDERR "Hi There STDERR!\n";

__END__
open(my $fh, '|-', $^X, '-MTime::HiRes=time', '-e', 'while (my $in = <>) { print time; print ":"; print $in }; print "X\n"');

$fh->autoflush(1);

print $fh <<EOT;
foo
bar
baz
EOT

sleep 1;

print $fh <<EOT;
foo
bar
baz
EOT

close($fh);

exit 0
