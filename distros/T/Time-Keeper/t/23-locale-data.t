#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Config;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use Time::Keeper;
use Time::Keeper::Locale;

my $K = 'Time::Keeper';
my $L = 'Time::Keeper::Locale';
my $t = $K->new(year => 2026, month => 10, day => 15, hour => 21, minute => 5, second => 7,
                nanosecond => 123_000_000, zone => 'Europe/Paris');

# Every locale reads, and writes what it reads.
my (@bad, $n);
my @patterns = ('GGGG y MMMM d EEEE HH:mm:ss.SSS', 'y MMM d EEE hh:mm:ss a OOOO', 'y LLLL d cccc H:mm:ss zzzz',
                'Y w W e QQQQ q', 'y-MM-dd HH:mm:ss vvvv');
for my $code ($L->codes) {
    my $v = $t->in_locale($code);
    my $full = eval { $v->format_datetime('full') };
    push @bad, "$code: format_datetime: $@" unless defined $full && length $full;
    for my $p (@patterns[0 .. 2, 4]) {
        $n++;
        my $s = $v->format($p);
        my $back = eval { $K->parse_cldr($s, $p, locale => $code, zone => 'Europe/Paris') };
        push @bad, "$code '$p': '$s': " . ($back ? $back->rfc9557 : $@)
            unless $back && $back->epoch == $v->epoch && ($p !~ /S/ || $back->nanosecond == $v->nanosecond);
    }
    my $wk = $v->format($patterns[3]);
    push @bad, "$code: weeks '$wk'" unless length $wk;
    for my $k (qw(date time datetime)) {
        my @f = $L->formats($code, $k);
        push @bad, "$code: $k formats" unless @f == 4 && !grep { !length } @f;
    }
    my @m = $L->names($code, 'months');
    push @bad, "$code: months" unless @m == 12 && !grep { !length } @m;
}
is(scalar(@bad), 0, "every locale formats and reads back ($n patterns)") or diag(join "\n", @bad[0 .. 19]);

# The locale data file: where it is, and what happens when it is not right.
my $file;
for my $dir (map { File::Spec->catdir($_, 'Time', 'Keeper') } @INC) {
    my $f = File::Spec->catfile($dir, 'locales.tkd');
    if (!ref $dir && -f $f) { $file = $f; last }
}
ok($file, 'the locale data is installed beside Time/Keeper.pm');
cmp_ok(-s $file, '<', 8_000_000, 'and is under 8 MB');

SKIP: {
    skip 'no locale data file', 5 unless $file;
    open my $in, '<:raw', $file or die "$file: $!";
    my $data = do { local $/; <$in> };
    close $in;
    is(substr($data, 0, 4), 'TKD1', 'the file says what it is');

    my $dir = tempdir(CLEANUP => 1);
    my $run = sub {
        my ($bytes, $code) = @_;
        my $kd = File::Spec->catdir($dir, 'Time', 'Keeper');
        mkdir File::Spec->catdir($dir, 'Time');
        mkdir $kd;
        my $target = File::Spec->catfile($kd, 'locales.tkd');
        unlink $target;
        if (defined $bytes) {
            open my $out, '>:raw', $target or die "$target: $!";
            print $out $bytes;
            close $out;
        }
        my $pm = File::Spec->catfile($kd, '..', 'Keeper.pm');
        my $script = File::Spec->catfile($dir, 'try.pl');
        open my $sp, '>', $script or die "$script: $!";
        print $sp "use Time::Keeper;\n",
                   "\$INC{'Time/Keeper.pm'} = q{$pm};\n",
                   "\@INC = grep { ref || !-f qq{\$_/Time/Keeper/locales.tkd} } \@INC;\n",
                   "my \$r = eval { Time::Keeper->now(locale => q{$code})->format_date('full') };\n",
                   "print defined \$r ? qq{ok\\n} : \$@;\n";
        close $sp;
        my @inc = map { "-I$_" } grep { !ref } @INC;
        return scalar `"$^X" @inc "$script" 2>&1`;
    };
    SKIP: {
        skip 'the system shell quotes differently here', 4 if $^O eq 'MSWin32';
        like($run->($data, 'fr'), qr/^ok$/, 'a copy of the file reads');
        like($run->(undef, 'fr'), qr/cannot find its locale data/, 'no file is an error');
        my $other = $data;
        substr($other, 8, 4) = pack 'V', 1 + unpack 'V', substr($other, 8, 4);
        like($run->($other, 'fr'), qr/from a different build/, 'a file from another build is refused');
        like($run->(substr($data, 0, 5000), 'fr'), qr/cut short|corrupt/, 'and a short one');
        like($run->(undef, 'en'), qr/^ok$/, 'English needs no file');
    }
}

# Threads load locales at the same time. No :encoding layer is put on the test's
# handles in this file: perl 5.20 and older die making a thread while a
# handle has one (5.36 does not).
SKIP: {
    skip 'no threads', 1 unless $Config{useithreads} && eval { require threads; 1 };
    my @want = qw(de es it pt nl sv pl tr);
    my @thr = map {
        my $code = $_;
        threads->create(sub {
            my $s = '';
            $s .= $t->in_locale($code)->format('MMMM') for 1 .. 50;
            $s;
        })
    } @want;
    my @got = map { $_->join } @thr;
    my @expect = map { $t->in_locale($_)->format('MMMM') x 50 } @want;
    is_deeply(\@got, \@expect, 'eight threads read eight locales at once');
}

done_testing;
