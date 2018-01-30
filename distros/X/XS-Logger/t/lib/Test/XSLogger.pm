package Test::XSLogger;

use strict;
use warnings;

require Exporter;

# to improve to extend test
use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use File::Slurp qw{read_file};

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(logfile_last_line_like count_lines get_logfile_last_line);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

our $TIMESTAMP = qr{[0-9]{4}-[0-9]{2}-[0-9]{2}\s+[0-9]{1,2}:[0-9]{2}:[0-9]{2}};
our $TIMEZONE  = qr{[+-][0-9]{4}};
our $PID       = qr{[0-9]+};

sub count_lines {
    my ($f) = @_;
    return 0 unless -e $f;
    my @lines = read_file($f);
    return scalar @lines;
}

sub get_logfile_last_line {
    my ($f) = @_;
    return unless -e $f;
    my @lines = read_file($f);
    return $lines[-1];
}

sub logfile_last_line_like {
    my ( $f, %opts ) = @_;

    my $last_line = get_logfile_last_line($f);
    note $last_line;

    my $prefix = qr{^\[$TIMESTAMP $TIMEZONE\]\s$PID\s};
    $last_line =~ $prefix or fail("[timestamp tz] pid");
    my $content = $last_line;
    $content =~ s{$prefix}{};

    my ( $front, $end ) = split( ':', $content, 2 );
    $end =~ s{^\s}{};    # remove the first space after :
    if ( my $level = $opts{level} ) {
        if ( $opts{color} ) {
            $front =~ qr{^\x1b\[(1;)?[0-9]{2}m$level\s*\x1b\[0m$} or fail "colored level should be $level - got '$front'";
        }
        else {
            $front =~ qr{^$level\s*$} or fail "level should be $level - got '$front'";
        }

    }
    chomp($end) or fail 'line ends with a \n';
    if ( defined $opts{msg} ) {
        my $msg = $opts{msg};
        is $end, $msg, $opts{test} // $opts{msg} // "message";
    }

    return;
}

1;
