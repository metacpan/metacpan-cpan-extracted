#!/usr/bin/perl
################################################################################

  ############################################################################
  #                                                                          #
  #   Eureka Error System v1.1.7                                             #
  #   (C) 2020 OnEhIppY, Domero                                              #
  #   ALL RIGHTS RESERVED                                                    #
  #                                                                          #
  ############################################################################

################################################################################

package gerr;

use strict;
use warnings;
use Exporter;

our $VERSION = '1.1.7';
our @ISA = qw(Exporter);
our @EXPORT = qw(error Warn Die);
our @EXPORT_OK = qw(trace);

################################################################################

use utf8; # Enable UTF-8 support

sub error {
    my @msg = @_;
    my $return = 0;
    my $type = "FATAL ERROR";
    my $size = 80 - 2;
    my $trace = 2;
    my @lines;

    while (scalar(@msg)) {
        if (!defined $msg[0]) { 
            shift(@msg);
        }
        elsif ($msg[0] =~ /^return=(.+)$/s) { 
            $return = $1; 
            shift(@msg);
        }
        elsif ($msg[0] =~ /^type=(.+)$/s) { 
            $type = $1; 
            shift(@msg);
        }
        elsif ($msg[0] =~ /^size=(.+)$/s) { 
            $size = $1; 
            shift(@msg);
        }
        elsif ($msg[0] =~ /^trace=(.+)$/s) { 
            $trace = $1; 
            shift(@msg);
        }
        else { 
            push @lines, split(/\n/, shift(@msg)); 
        }
    }

    $type = " $type ";
    my $tsize = length("$type");
    push @lines, "";

    my $ls = ($size >> 1) - ($tsize >> 1);
    my $rs = $size - ($size >> 1) - ($tsize >> 1) - 1;
    my $tit = " " . ("#" x $ls) . $type . ("#" x $rs) . "\n";
    my $str = "\n$tit\n";

    foreach my $line (@lines) {
        while (length($line) > 0) {
            $str .= " # ";
            if (length($line) > $size) {
                $str .= substr($line, 0, $size - 6) . "..." . " #\n";
                $line = "..." . substr($line, $size - 6);
            } else {
                $str .= $line . (length(" " x ($size - length($line) - 3)) > 0 ? (" " x ($size - length($line) - 3)) : '') . " #\n";
                $line = "";
            }
        }
    }

    $str .= trace($trace,$size); # Include stack trace if enabled

     # Only exit if not in an eval block
    if (!$return && !$^S) {
        $| = 1; # Autoflush STDERR
        binmode STDERR, ":encoding(UTF-8)"; # Set UTF-8 encoding for STDERR
        print STDERR $str;
        exit 1;
    }

    return $str;
}

################################################################################

sub trace {
    my $depth = $_[0] || 1;
    my $size = $_[1] || 80-2;
    my @out = ();

    while ($depth > 0 && $depth < 20) {
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($depth);
        
        if (!$package) { 
            $depth = 0; 
        } else { 
            push @out, [$line, "$package($filename)", "Calling $subroutine" . ($hasargs ? "@DB::args" : ""), ($subroutine eq '(eval)' && $evaltext ? "[$evaltext]" : "")]; 
            $depth++;
        }
    }

    @out = reverse @out;

    if (@out) {
        for my $i (0 .. $#out) {
            my $dept = "# " . (" " x $i) . ($i > 0 ? "`[" : "-[");
            my ($ln, $pk, $cl, $ev) = @{$out[$i]};
            my $ll = (60 - length($dept . $cl));
            my $rr = (6 - length($ln));
            $out[$i] = "$dept $cl" . (" " x ($ll > 0 ? $ll : 0)) . " at line: " . (" " x ($rr > 0 ? $rr : 0)) . "$ln : $pk" . ($ev ? "\n$ev" : "");
        }
    }

    my $type = " Trace Stack ";
    my $tsize = length("$type");
    my $ls = ($size >> 1) - ($tsize >> 1);
    my $rs = $size - ($size >> 1) - ($tsize >> 1) - 1;
    my $tit = " " . ("#" x $ls) . $type . ("#" x $rs) . "\n";
    return "$tit\n".join("\n", @out)."\n" . ("#" x $size) . "\n";
}

################################################################################

sub Warn {
    my ($message) = @_;
    my $file = (caller)[1];
    my $line = (caller)[2];
    my $formatted_message = error("$message at $file line $line.", "return=1", "type=Warning", "trace=3");
    if (ref($SIG{__WARN__}) eq 'CODE') {
        $SIG{__WARN__}->($formatted_message);
    } else {
        binmode STDERR, ":encoding(UTF-8)"; # Set UTF-8 encoding for STDERR
        print STDERR $formatted_message;
    }
    return $formatted_message;
}

################################################################################

sub Die {
    my ($message) = @_;
    my $file = (caller)[1];
    my $line = (caller)[2];
    my $formatted_message = error("$message at $file line $line.", "return=1", "type=Fatal", "trace=3");
    if (ref($SIG{__DIE__}) eq 'CODE') {
        $SIG{__DIE__}->($formatted_message);
    } else {
        binmode STDERR, ":encoding(UTF-8)"; # Set UTF-8 encoding for STDERR
        print STDERR $formatted_message;
    }
    exit 1 unless $^S; # Only exit if not in an eval block
    return $formatted_message;
}

################################################################################

sub import {
    my ($class, @args) = @_;

    # Handle import arguments
    if (grep { $_ eq ':control' } @args) {
        # Override global warn and die
        no strict 'refs'; # Allow modifying symbolic references
        *CORE::GLOBAL::warn = \&Warn;
        *CORE::GLOBAL::die = \&Die;
    }

    # Export default functions
    $class->export_to_level(1, $class, @EXPORT);

    # Conditionally export functions based on import arguments
    if (grep { $_ eq ':control' } @args) {
        $class->export_to_level(1, $class, @EXPORT_OK);
    }
}

1;

################################################################################
# EOF gerr.pm (C) 2020 Domero
