use strict;
use warnings;
use Test::More;
use POSIX qw(strftime);
use glog;
use Time::HiRes qw(gettimeofday usleep);
use File::Temp qw(tempfile);

subtest 'Direct logging functions' => sub {
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    LogLevel(5); # Enable all levels
    LogErr("Error test"); usleep(1000);
    LogWarn("Warn test"); usleep(1000);
    LogInfo("Info test"); usleep(1000);
    LogDebug("Debug test");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] ERROR Error test\n/, "Captured ERROR log");
    like($captured, qr/\[$timestamp\] WARN Warn test\n/, "Captured WARN log");
    like($captured, qr/\[$timestamp\] INFO Info test\n/, "Captured INFO log");
    like($captured, qr/\[$timestamp\] DEBUG Debug test\n/, "Captured DEBUG log");

    # Verify order
    my @lines = split /\n/, $captured;
    ok(@lines >= 4, "Captured at least 4 log lines");
    like($lines[0], qr/\[$timestamp\] ERROR Error test/, "ERROR log first");
    like($lines[1], qr/\[$timestamp\] WARN Warn test/, "WARN log second");
    like($lines[2], qr/\[$timestamp\] INFO Info test/, "INFO log third");
    like($lines[3], qr/\[$timestamp\] DEBUG Debug test/, "DEBUG log fourth");
};

subtest 'Formatted logging' => sub {
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    LogLevel(3);
    LogF(3, "Formatted %s %d", "test", 42); usleep(1000);
    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] INFO Formatted test 42\n/, "Captured formatted log");

    LogF(3, "Static message");
    like($captured, qr/\[$timestamp\] INFO Static message\n/, "Captured static formatted log");

    LogF(3, "%s %d", "test"); # Too few args, should not crash
    like($captured, qr/\[$timestamp\] INFO test 0\n/, "Handled invalid format args");
};

subtest 'File logging' => sub {
    my ($fh, $tempfile) = tempfile();
    close $fh; # File::Temp creates the file
    LogFile($tempfile);
    LogInfo("File log test");
    LogFile(undef); # Close file

    open my $logfh, '<', $tempfile or die "Cannot open $tempfile: $!";
    my $file_content = do { local $/; <$logfh> };
    close $logfh;
    unlink $tempfile or warn "Could not unlink $tempfile: $!";

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($file_content, qr/\[$timestamp\] INFO File log test\n/, "Captured file log");
};

subtest 'LogDie' => sub {
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    eval { LogDie("Die test"); };
    like($@, qr//, "LogDie throws exception");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] ERROR Die test\n/, "LogDie logs ERROR");

    eval { LogDie(); };
    like($@, qr//, "LogDie with empty message");
};

subtest 'LogLevel control' => sub {
    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;

    LogLevel(2); # Only ERROR and WARN
    LogErr("Should log"); usleep(1000);
    LogWarn("Should log"); usleep(1000);
    LogInfo("Should not log");
    LogDebug("Should not log");

    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr/\[$timestamp\] ERROR Should log\n/, "Logged ERROR at level 2");
    like($captured, qr/\[$timestamp\] WARN Should log\n/, "Logged WARN at level 2");
    unlike($captured, qr/INFO Should not log/, "Did not log INFO at level 2");
    unlike($captured, qr/DEBUG Should not log/, "Did not log DEBUG at level 2");

    is(LogLevel(), 2, "LogLevel returns correct value");
};

subtest 'Error handling' => sub {
    eval { LogLevel(-1); };
    like($@, qr//s, "Invalid log level");

    Log(1, undef); # Should not crash
    Log(undef, "test"); # Should not crash
    pass("Undefined inputs handled safely");

    eval { LogFile("/invalid/path/$$/log"); };
    like($@, qr//, "Invalid log file path");

    my $captured;
    local *STDERR;
    open my $fh, '>', \$captured or die "Cannot open scalar ref: $!";
    *STDERR = $fh;
    LogLevel(3);
    Log(3, "");
    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime($sec)) . '\.\d+';
    like($captured, qr//, "Empty message logged");
};

done_testing();