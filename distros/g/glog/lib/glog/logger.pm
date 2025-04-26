package glog::logger;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use POSIX qw(strftime);
use gerr qw(Die);

our $VERSION = '1.0.5';

my %LEVEL_NAMES = (
    1 => 'ERROR',
    2 => 'WARN',
    3 => 'INFO',
    5 => 'DEBUG',
);

sub new {
    my ($class) = @_;
    return bless {
        level => 3,
        fh => undef,
    }, $class;
}

sub LogLevel {
    my ($self, $new_level) = @_;
    if (defined $new_level) {
        if ($new_level < 0 || $new_level > 9) {
            Die "Log level must be between 0 and 9";
        }
        $self->{level} = $new_level;
    }
    return $self->{level};
}

sub Log {
    my ($self, $level, $message) = @_;
    return unless defined $level && defined $message;
    return unless $level <= $self->{level};
    my $level_name = $LEVEL_NAMES{$level} || 'UNKNOWN';
    my ($sec, $usec) = gettimeofday;
    my $timestamp = strftime("[%Y-%m-%d %H:%M:%S", localtime($sec)) . sprintf(".%03d]", $usec / 1000);
    my $log_line = sprintf("%s %s %s\n", $timestamp, $level_name, $message);
    my $fh = $self->{fh} || *STDERR;
    print {$fh} $log_line or Die "Failed to write to log: $!";
}

sub LogFormat {
    my ($self, $level, $format, @args) = @_;
    return unless defined $level && defined $format;
    return unless $level <= $self->{level};
    $self->Log($level, sprintf($format, @args));
}

sub LogFile {
    my ($self, $path) = @_;
    if (defined $path) {
        if ($self->{fh} && $self->{fh} ne *STDERR) {
            close $self->{fh} or Die "Failed to close log file: $!";
        }
        open my $fh, '>>', $path or Die "Failed to open log file '$path': $!";
        $self->{fh} = $fh;
    } else {
        if ($self->{fh} && $self->{fh} ne *STDERR) {
            close $self->{fh} or Die "Failed to close log file: $!";
        }
        $self->{fh} = undef;
    }
    return $self->{fh} ? 1 : 0;
}

sub LogDie {
    my ($self, $message) = @_;
    $message //= 'Died';
    $self->Log(1, $message);
    Die $message;
}

sub LogWarn {
    my ($self, $message) = @_;
    return unless defined $message;
    $self->Log(2, $message);
}

sub LogInfo {
    my ($self, $message) = @_;
    return unless defined $message;
    $self->Log(3, $message);
}

sub LogDebug {
    my ($self, $message) = @_;
    return unless defined $message;
    $self->Log(5, $message);
}

sub LogErr {
    my ($self, $message) = @_;
    return unless defined $message;
    $self->Log(1, $message);
}

1;