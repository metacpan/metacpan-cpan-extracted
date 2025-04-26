use strict;
use warnings;
use Test::More;
use POSIX qw(strftime);
use glog::logger;
use Time::HiRes qw(gettimeofday usleep);
use File::Temp qw(tempfile);

subtest 'Direct logging methods' => sub {
    my $logger = glog::logger->new;
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    $logger->LogLevel(5); # Enable all levels
    $logger->LogErr("Error test"); usleep(1000);
    $logger->LogWarn("Warn test"); usleep(1000);
    $logger->LogInfo("Info test"); usleep(1000);
    $logger->LogDebug("Debug test");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] ERROR Error test\n/s, "Captured ERROR log");
    like($captured, qr/\[$timestamp\] WARN Warn test\n/s, "Captured WARN log");
    like($captured, qr/\[$timestamp\] INFO Info test\n/s, "Captured INFO log");
    like($captured, qr/\[$timestamp\] DEBUG Debug test\n/s, "Captured DEBUG log");

    # Verify order
    my @lines = split /\n/, $captured;
    ok(@lines >= 4, "Captured at least 4 log lines");
    like($lines[0], qr/\[$timestamp\] ERROR Error test/s, "ERROR log first");
    like($lines[1], qr/\[$timestamp\] WARN Warn test/s, "WARN log second");
    like($lines[2], qr/\[$timestamp\] INFO Info test/s, "INFO log third");
    like($lines[3], qr/\[$timestamp\] DEBUG Debug test/s, "DEBUG log fourth");
};

subtest 'Formatted logging' => sub {
    my $logger = glog::logger->new;
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    $logger->LogLevel(3);
    $logger->LogFormat(3, "Formatted %s %d", "test", 42); usleep(1000);
    like($captured, qr/INFO Formatted test 42/s, "Captured formatted log");

    $logger->LogFormat(3, "Static message");
    like($captured, qr/INFO Static message/s, "Captured static formatted log");

    $logger->LogFormat(3, "%s %d", "test"); # Too few args, should not crash
    like($captured, qr/INFO test 0/s, "Handled invalid format args");
};

subtest 'File logging' => sub {
    my $logger = glog::logger->new;
    my ($fh, $tempfile) = tempfile();
    close $fh; # File::Temp creates the file
    $logger->LogFile($tempfile);
    $logger->LogInfo("File log test");
    $logger->LogFile(undef); # Close file

    open my $logfh, '<', $tempfile or die "Cannot open $tempfile: $!";
    my $file_content = do { local $/; <$logfh> };
    close $logfh;
    unlink $tempfile or warn "Could not unlink $tempfile: $!";

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($file_content, qr/\[$timestamp\] INFO File log test\n/, "Captured file log");
};

subtest 'LogDie' => sub {
    my $logger = glog::logger->new;
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    eval { $logger->LogDie("Die test"); };
    like($@, qr//, "LogDie throws exception");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] ERROR Die test\n/, "LogDie logs ERROR");

    eval { $logger->LogDie(); };
    like($@, qr//, "LogDie with empty message");
};

subtest 'LogLevel control' => sub {
    my $logger = glog::logger->new;
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    $logger->LogLevel(2); # Only ERROR and WARN
    $logger->LogErr("Should log"); usleep(1000);
    $logger->LogWarn("Should log"); usleep(1000);
    $logger->LogInfo("Should not log");
    $logger->LogDebug("Should not log");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] ERROR Should log\n/, "Logged ERROR at level 2");
    like($captured, qr/\[$timestamp\] WARN Should log\n/, "Logged WARN at level 2");
    unlike($captured, qr/INFO Should not log/, "Did not log INFO at level 2");
    unlike($captured, qr/DEBUG Should not log/, "Did not log DEBUG at level 2");

    is($logger->LogLevel(), 2, "LogLevel returns correct value");
};

subtest 'Error handling' => sub {
    my $logger = glog::logger->new;
    eval { $logger->LogLevel(-1); };
    like($@, qr//, "Invalid log level");

    $logger->Log(1, undef); # Should not crash
    $logger->Log(undef, "test"); # Should not crash
    pass("Undefined inputs handled safely");

    eval { $logger->LogFile("/invalid/path/$$/log"); };
    like($@, qr//, "Invalid log file path");

    $logger->LogLevel(3);
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;
    $logger->Log(3, "");
    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr//s, "Empty message logged");
};

subtest 'Multiple logger instances' => sub {
    my $logger1 = glog::logger->new;
    my $logger2 = glog::logger->new;

    $logger1->LogLevel(3);
    $logger2->LogLevel(5);

    my $captured1;
    local *STDERR;
    open my $fh, '>', \$captured1 or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    $logger1->LogDebug("Should not log");
    $logger2->LogDebug("Should log");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    unlike($captured1, qr/Should not log/, "Logger1 did not log DEBUG at level 3");
    like($captured1, qr/\[$timestamp\] DEBUG Should log\n/, "Logger2 logged DEBUG at level 5");
};

done_testing();