package Util;

use strict;
use warnings;

use Carp        qw[];
use IO::File    qw[SEEK_SET SEEK_END];
use Test::Fatal qw[exception];

BEGIN {
    our @EXPORT_OK  = qw[ throws_ok warns_ok pack_utf8 pack_overlong_utf8 rewind slurp ];
    our %EXPORT_TAGS = (
        all => [ @EXPORT_OK ],
    );

    require Exporter;
    *import = \&Exporter::import;
}

my @UTF8_MIN = (0x80, 0x800, 0x10000, 0x200000, 0x4000000, 0x80000000);
sub pack_utf8 ($;$) {
    my ($cp, $len) = @_;
    ($cp >= 0 && $cp < 0x80000000)
      || Carp::confess(qq/Cannot pack '$cp'/);
    (@_ == 1 || ($len > 0 && $len <= 6 && $cp < $UTF8_MIN[$len - 1]))
      || Carp::confess(qq/Cannot pack '$cp' to sequence length '$len'/);
    my @c = (0) x ($len || ($cp < 0x80      ? 1 : $cp < 0x800    ? 2
                          : $cp < 0x10000   ? 3 : $cp < 0x200000 ? 4
                          : $cp < 0x4000000 ? 5 :                  6));
    for (reverse @c[1..$#c]) {
        $_ = ($cp & 0x3F) | 0x80;
        $cp >>= 6;
    }
    $c[0] = $cp | (0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC)[$#c];
    return pack('C*', @c);
}

sub pack_overlong_utf8 ($) {
    my ($cp) = @_;
    ($cp >= 0 && $cp < 0x4000000)
      || Carp::confess(qq/Cannot pack '$cp'/);
    my @enc;
    for (my $i = 0; $i < 5; $i++) {
        next unless $cp < $UTF8_MIN[$i];
        push @enc, pack_utf8($cp, $i + 2);
    }
    return wantarray ? @enc : $enc[0];
}


my $Tester;
sub throws_ok (&$;$) {
    my ($code, $regexp, $name) = @_;

    require Test::Builder;
    $Tester ||= Test::Builder->new;

    my $e  = exception(\&$code);
    my $ok = ($e && $e =~ m/$regexp/);

    $Tester->ok($ok, $name);

    unless ($ok) {
        if ($e) {
            $Tester->diag("expecting: " . $regexp);
            $Tester->diag("found: " . $e);
        }
        else {
            $Tester->diag("expected an exception but none was raised");
        }
    }
}

sub warns_ok (&$;$) {
    my ($code, $regexp, $name) = @_;

    require Test::Builder;
    $Tester ||= Test::Builder->new;

    my @warnings = ();
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $e  = exception(\&$code);
    my $ok = (!$e && @warnings == 1 && $warnings[0] =~ m/$regexp/);

    $Tester->ok($ok, $name);

    unless ($ok) {
        if ($e) {
            $Tester->diag("expected a warning but an exception was raised");
            $Tester->diag("exception: " . $e);
        }
        elsif (@warnings == 0) {
            $Tester->diag("expected a warning but none were issued");
        }
        elsif (@warnings >= 2) {
            $Tester->diag("expected a warning but several were issued");
            $Tester->diag("warnings: " . join '', @warnings);
        }
        else {
            $Tester->diag("expecting: " . $regexp);
            $Tester->diag("found: " . $warnings[0]);
        }
    }
}


sub rewind(*) {
    seek($_[0], 0, SEEK_SET)
      || die(qq/Couldn't rewind file handle: '$!'/);
}

sub slurp (*) {
    my ($fh) = @_;

    seek($fh, 0, SEEK_END)
      || die(qq/Couldn't navigate to EOF on file handle: '$!'/);

    my $exp = tell($fh);

    rewind($fh);

    binmode($fh)
      || die(qq/Couldn't binmode file handle: '$!'/);

    my $buf = do { local $/; <$fh> };
    my $got = length $buf;

    ($exp == $got)
      || die(qq[I/O read mismatch (expexted: $exp got: $got)]);

    return $buf;
}


1;

