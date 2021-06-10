package UTF8::R2;
######################################################################
#
# UTF8::R2 - makes UTF-8 scripting easy for enterprise use or LTS
#
# http://search.cpan.org/dist/UTF8-R2/
#
# Copyright (c) 2019, 2020, 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.19';
$VERSION = $VERSION;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use Symbol ();

my %utf8_codepoint = (

    # beautiful concept in young days, however disabled 5-6 octets for safety
    # https://www.ietf.org/rfc/rfc2279.txt
    'RFC2279' => qr{(?>@{[join('', qw(
        [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]       |
        [\xC2-\xDF][\x80-\xBF]                       |
        [\xE0-\xEF][\x80-\xBF][\x80-\xBF]            |
        [\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
        [\x00-\xFF]
    ))]})}x,

    # https://tools.ietf.org/rfc/rfc3629.txt
    'RFC3629' => qr{(?>@{[join('', qw(
        [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]       |
        [\xC2-\xDF][\x80-\xBF]                       |
        [\xE0-\xE0][\xA0-\xBF][\x80-\xBF]            |
        [\xE1-\xEC][\x80-\xBF][\x80-\xBF]            |
        [\xED-\xED][\x80-\x9F][\x80-\xBF]            |
        [\xEE-\xEF][\x80-\xBF][\x80-\xBF]            |
        [\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |
        [\x00-\xFF]
    ))]})}x,

    # http://simonsapin.github.io/wtf-8/
    'WTF8' => qr{(?>@{[join('', qw(
        [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]       |
        [\xC2-\xDF][\x80-\xBF]                       |
        [\xE0-\xE0][\xA0-\xBF][\x80-\xBF]            |
        [\xE1-\xEF][\x80-\xBF][\x80-\xBF]            |
        [\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |
        [\x00-\xFF]
    ))]})}x,

    # optimized RFC3629 for ja_JP
    'RFC3629.ja_JP' => qr{(?>@{[join('', qw(
        [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]       |
        [\xE1-\xEC][\x80-\xBF][\x80-\xBF]            |
        [\xC2-\xDF][\x80-\xBF]                       |
        [\xEE-\xEF][\x80-\xBF][\x80-\xBF]            |
        [\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xE0-\xE0][\xA0-\xBF][\x80-\xBF]            |
        [\xED-\xED][\x80-\x9F][\x80-\xBF]            |
        [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |
        [\x00-\xFF]
    ))]})}x,

    # optimized WTF-8 for ja_JP
    'WTF8.ja_JP' => qr{(?>@{[join('', qw(
        [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]       |
        [\xE1-\xEF][\x80-\xBF][\x80-\xBF]            |
        [\xC2-\xDF][\x80-\xBF]                       |
        [\xE0-\xE0][\xA0-\xBF][\x80-\xBF]            |
        [\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
        [\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |
        [\x00-\xFF]
    ))]})}x,
);

# supports /./
my $x =
    ($^X =~ /jperl(\.exe)?\z/i) && (`$^X -v` =~ /SJIS version/) ?
    q{(?>[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]|[\x00-\xFF])} : # debug tool using JPerl(SJIS version)
    $utf8_codepoint{'RFC3629'};

# supports [\b] \d \h \s \v \w
my $bare_b = '\x08';
my $bare_d = '0123456789';
my $bare_h = '\x09\x20';
my $bare_s = '\t\n\f\r\x20';
my $bare_v = '\x0A\x0B\x0C\x0D';
my $bare_w = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_';

#---------------------------------------------------------------------
# exports %mb
sub import {
    my $self = shift @_;

    # confirm version
    if (defined($_[0]) and ($_[0] =~ /\A [0-9] /xms)) {
        if ($_[0] ne $UTF8::R2::VERSION) {
            my($package,$filename,$line) = caller;
            die "$filename requires @{[__PACKAGE__]} $_[0], however @{[__FILE__]} am only $UTF8::R2::VERSION, stopped at $filename line $line.\n";
        }
        shift @_;
    }

    for (@_) {

        # export %mb
        if ($_ eq '%mb') {
            no strict qw(refs);
            # tie my %mb, __PACKAGE__; # makes: Parentheses missing around "my" list
            tie my %mb, 'UTF8::R2';
            *{caller().'::mb'} = \%mb;
        }

        # set script encoding
        elsif (defined $utf8_codepoint{$_}) {
            $x = $utf8_codepoint{$_};
        }
    }
}

#---------------------------------------------------------------------
# confess() for this module
sub confess {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $subroutine\n";
        $i++;
    }
    print STDERR "\n", @_, "\n";
    print STDERR CORE::reverse @confess;
    die;
}

#---------------------------------------------------------------------
# chop() for UTF-8 codepoint string
sub UTF8::R2::chop (@) {
    my $chop = '';
    for (@_ ? @_ : $_) {
        if (my @x = /\G$x/g) {
            $chop = pop @x;
            $_ = join '', @x;
        }
    }
    return $chop;
}

#---------------------------------------------------------------------
# chr() for UTF-8 codepoint string
sub UTF8::R2::chr (;$) {
    my $number = @_ ? $_[0] : $_;

# Negative values give the Unicode replacement character (chr(0xfffd)),
# except under the bytes pragma, where the low eight bits of the value
# (truncated to an integer) are used.

    my @octet = ();
    CORE::do {
        unshift @octet, ($number % 0x100);
        $number = int($number / 0x100);
    } while ($number > 0);
    return pack 'C*', @octet;
}

#---------------------------------------------------------------------
# getc() for UTF-8 codepoint string
sub UTF8::R2::getc (;*) {
    my $fh = @_ ? Symbol::qualify_to_ref($_[0],caller()) : \*STDIN;
    my $getc = CORE::getc $fh;
    if ($getc =~ /\A [\xC2-\xDF] \z/xms) {
        $getc .= CORE::getc $fh;
    }
    elsif ($getc =~ /\A [\xE0-\xEF] \z/xms) {
        $getc .= CORE::getc $fh;
        $getc .= CORE::getc $fh;
    }
    elsif ($getc =~ /\A [\xF0-\xF4] \z/xms) {
        $getc .= CORE::getc $fh;
        $getc .= CORE::getc $fh;
        $getc .= CORE::getc $fh;
    }
    return $getc;
}

#---------------------------------------------------------------------
# index() for UTF-8 codepoint string
sub UTF8::R2::index ($$;$) {
    my $index = 0;
    if (@_ == 3) {
        $index = CORE::index $_[0], $_[1], CORE::length(UTF8::R2::substr($_[0], 0, $_[2]));
    }
    else {
        $index = CORE::index $_[0], $_[1];
    }
    if ($index == -1) {
        return -1;
    }
    else {
        return UTF8::R2::length(CORE::substr $_[0], 0, $index);
    }
}

#---------------------------------------------------------------------
# universal lc() for UTF-8 codepoint string
sub UTF8::R2::lc (;$) {
    local $_ = @_ ? $_[0] : $_;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
    return join '', map { {qw( A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z )}->{$_}||$_ } /\G$x/g;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
}

#---------------------------------------------------------------------
# universal lcfirst() for UTF-8 codepoint string
sub UTF8::R2::lcfirst (;$) {
    local $_ = @_ ? $_[0] : $_;
    if (/\A($x)(.*)\z/s) {
        return UTF8::R2::lc($1) . $2;
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# length() for UTF-8 codepoint string
sub UTF8::R2::length (;$) {
    local $_ = @_ ? $_[0] : $_;
    return scalar(() = /\G$x/g);
}

#---------------------------------------------------------------------
# ord() for UTF-8 codepoint string
sub UTF8::R2::ord (;$) {
    local $_ = @_ ? $_[0] : $_;
    my $ord = 0;
    if (/\A($x)/) {
        for my $octet (unpack 'C*', $1) {
            $ord = $ord * 0x100 + $octet;
        }
    }
    return $ord;
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for UTF-8 codepoint string
sub list_all_by_hyphen_utf8_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]                                         )), $a[1],
                                                                                                 $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x80-\x%02x]                             )), $b[1], $b[2]),
0xC2 < $b[1] ?  sprintf(join('', qw( [\xC2-\x%02x] [\x80-\xBF  ]                             )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]       ),
            );
        }
        elsif (CORE::length($b) == 3) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x]               )), $b[1], $b[2], $b[3]),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ]               )), $b[1], $b[2]-1     ) : (),
0xE0 < $b[1] ?  sprintf(join('', qw( [\xE0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ]               )), $b[1]-1            ) : (),
                sprintf(join('', qw( [\xC2-\xDF  ] [\x80-\xBF  ]                             )),                    ),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]              ),
            );
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
                sprintf(join('', qw( [\xE0-\xEF  ] [\x80-\xBF  ] [\x80-\xBF  ]               )),                           ),
                sprintf(join('', qw( [\xC2-\xDF  ] [\x80-\xBF  ]                             )),                           ),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]                     ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xDF ?  sprintf(join('', qw( [\x%02x-\xDF] [\x80-\xBF  ]                             )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xBF]                             )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x80-\x%02x]                             )), $b[1], $b[2]),
0xC2 < $b[1] ?  sprintf(join('', qw( [\xC2-\x%02x] [\x80-\xBF  ]                             )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
        elsif (CORE::length($b) == 3) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x]               )), $b[1], $b[2], $b[3] ),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ]               )), $b[1], $b[2]-1      ) : (),
0xE0 < $b[1] ?  sprintf(join('', qw( [\xE0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ]               )), $b[1]-1             ) : (),
$a[1] < 0xDF ?  sprintf(join('', qw( [\x%02x-\xDF] [\x80-\xBF  ]                             )), $a[1]+1             ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xBF]                             )), $a[1], $a[2]        ),
            );
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
                sprintf(join('', qw( [\xE0-\xEF  ] [\x80-\xBF  ] [\x80-\xBF  ]               )),                           ),
$a[1] < 0xDF ?  sprintf(join('', qw( [\x%02x-\xDF] [\x80-\xBF  ]                             )), $a[1]+1                   ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xBF]                             )), $a[1], $a[2]              ),
            );
        }
    }
    elsif (CORE::length($a) == 3) {
        if (0) { }
        elsif (CORE::length($b) == 3) {
            my $lower_limit = join('|',
$a[1] < 0xEF ?  sprintf(join('', qw( [\x%02x-\xEF] [\x80-\xBF  ] [\x80-\xBF  ]               )), $a[1]+1            ) : (),
$a[2] < 0xBF ?  sprintf(join('', qw(  \x%02x       [\x%02x-\xBF] [\x80-\xBF  ]               )), $a[1], $a[2]+1     ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xBF]               )), $a[1], $a[2], $a[3]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x]               )), $b[1], $b[2], $b[3]),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ]               )), $b[1], $b[2]-1     ) : (),
0xE0 < $b[1] ?  sprintf(join('', qw( [\xE0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ]               )), $b[1]-1            ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
$a[1] < 0xEF ?  sprintf(join('', qw( [\x%02x-\xEF] [\x80-\xBF  ] [\x80-\xBF  ]               )), $a[1]+1                   ) : (),
$a[2] < 0xBF ?  sprintf(join('', qw(  \x%02x       [\x%02x-\xBF] [\x80-\xBF  ]               )), $a[1], $a[2]+1            ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xBF]               )), $a[1], $a[2], $a[3]       ),
            );
        }
    }
    elsif (CORE::length($a) == 4) {
        if (0) { }
        elsif (CORE::length($b) == 4) {
            my $lower_limit = join('|',
$a[1] < 0xF4 ?  sprintf(join('', qw( [\x%02x-\xF4] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $a[1]+1                   ) : (),
$a[2] < 0xBF ?  sprintf(join('', qw(  \x%02x       [\x%02x-\xBF] [\x80-\xBF  ] [\x80-\xBF  ] )), $a[1], $a[2]+1            ) : (),
$a[3] < 0xBF ?  sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xBF] [\x80-\xBF  ] )), $a[1], $a[2], $a[3]+1     ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x        \x%02x       [\x%02x-\xBF] )), $a[1], $a[2], $a[3], $a[4]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x80-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x80 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x80-\x%02x] [\x80-\xBF  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x80 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x80-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1], $b[2]-1            ) : (),
0xF0 < $b[1] ?  sprintf(join('', qw( [\xF0-\x%02x] [\x80-\xBF  ] [\x80-\xBF  ] [\x80-\xBF  ] )), $b[1]-1                   ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr// for UTF-8 codepoint string
sub UTF8::R2::qr ($) {
    my $before_regex = $_[0];
    my($package,$filename,$line) = caller;

    my $modifiers = '';
    if (($modifiers) = $before_regex =~ /\A \( \? \^? (.*?) : /x) {
        $modifiers =~ s/-.*//;
    }

    my @after_subregex = ();
    while ($before_regex =~ s! \A
        (?> \[ (?: \[:[^:]+?:\] | \\x\{[0123456789ABCDEFabcdef]+\} | \\c[\x00-\xFF] | (?>\\$x) | $x )+? \] ) |
                                  \\x\{[0123456789ABCDEFabcdef]+\} | \\c[\x00-\xFF] | (?>\\$x) | $x
    !!x) {
        my $before_subregex = $&;

        # [^...] or [...]
        if (my($negative,$before_class) = $before_subregex =~ /\A \[ (\^?) ((?>\\$x|$x)+?) \] \z/x) {
            my @before_subclass = $before_class =~ /\G (?: \[:.+?:\] | \\x\{[0123456789ABCDEFabcdef]+\} | (?>\\$x) | $x ) /xg;
            my @sbcs = ();
            my @mbcs = ();

            for (my $i=0; $i <= $#before_subclass; ) {
                my $before_subclass = $before_subclass[$i];

                # hyphen of [A-Z] or [^A-Z]
                if (($i < $#before_subclass) and ($before_subclass[$i+1] eq '-')) {
                    my $a = ($before_subclass[$i+0] =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) ? UTF8::R2::chr(hex $1) : $before_subclass[$i+0];
                    my $b = ($before_subclass[$i+2] =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) ? UTF8::R2::chr(hex $1) : $before_subclass[$i+2];
                    push @mbcs, list_all_by_hyphen_utf8_like($a, $b);
                    $i += 3;
                }

                # any "one"
                else {

                    # \x{UTF8hex}
                    if ($before_subclass =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) {
                        push @mbcs, UTF8::R2::chr(hex $1);
                    }

                    # \any
                    elsif ($before_subclass eq '\D'         ) { push @mbcs, "(?:(?![$bare_d])$x)"  }
                    elsif ($before_subclass eq '\H'         ) { push @mbcs, "(?:(?![$bare_h])$x)"  }
#                   elsif ($before_subclass eq '\N'         ) { push @mbcs, "(?:(?!\\n)$x)"        } # \N in a character class must be a named character: \N{...} in regex
#                   elsif ($before_subclass eq '\R'         ) { push @mbcs, "(?>\\r\\n|[$bare_v])" } # Unrecognized escape \R in character class passed through in regex
                    elsif ($before_subclass eq '\S'         ) { push @mbcs, "(?:(?![$bare_s])$x)"  }
                    elsif ($before_subclass eq '\V'         ) { push @mbcs, "(?:(?![$bare_v])$x)"  }
                    elsif ($before_subclass eq '\W'         ) { push @mbcs, "(?:(?![$bare_w])$x)"  }
                    elsif ($before_subclass eq '\b'         ) { push @sbcs, $bare_b                }
                    elsif ($before_subclass eq '\d'         ) { push @sbcs, $bare_d                }
                    elsif ($before_subclass eq '\h'         ) { push @sbcs, $bare_h                }
                    elsif ($before_subclass eq '\s'         ) { push @sbcs, $bare_s                }
                    elsif ($before_subclass eq '\v'         ) { push @sbcs, $bare_v                }
                    elsif ($before_subclass eq '\w'         ) { push @sbcs, $bare_w                }

                    # [:POSIX:]
                    elsif ($before_subclass eq '[:alnum:]'  ) { push @sbcs, '\x30-\x39\x41-\x5A\x61-\x7A';                  }
                    elsif ($before_subclass eq '[:alpha:]'  ) { push @sbcs, '\x41-\x5A\x61-\x7A';                           }
                    elsif ($before_subclass eq '[:ascii:]'  ) { push @sbcs, '\x00-\x7F';                                    }
                    elsif ($before_subclass eq '[:blank:]'  ) { push @sbcs, '\x09\x20';                                     }
                    elsif ($before_subclass eq '[:cntrl:]'  ) { push @sbcs, '\x00-\x1F\x7F';                                }
                    elsif ($before_subclass eq '[:digit:]'  ) { push @sbcs, '\x30-\x39';                                    }
                    elsif ($before_subclass eq '[:graph:]'  ) { push @sbcs, '\x21-\x7F';                                    }
                    elsif ($before_subclass eq '[:lower:]'  ) { push @sbcs, '\x61-\x7A';                                    } # /i modifier requires 'a' to 'z' literally
                    elsif ($before_subclass eq '[:print:]'  ) { push @sbcs, '\x20-\x7F';                                    }
                    elsif ($before_subclass eq '[:punct:]'  ) { push @sbcs, '\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E'; }
                    elsif ($before_subclass eq '[:space:]'  ) { push @sbcs, '\s\x0B';                                       } # "\s" and vertical tab ("\cK")
                    elsif ($before_subclass eq '[:upper:]'  ) { push @sbcs, '\x41-\x5A';                                    } # /i modifier requires 'A' to 'Z' literally
                    elsif ($before_subclass eq '[:word:]'   ) { push @sbcs, '\x30-\x39\x41-\x5A\x5F\x61-\x7A';              }
                    elsif ($before_subclass eq '[:xdigit:]' ) { push @sbcs, '\x30-\x39\x41-\x46\x61-\x66';                  }

                    # [:^POSIX:]
                    elsif ($before_subclass eq '[:^alnum:]' ) { push @mbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x61-\\x7A])$x)";                      }
                    elsif ($before_subclass eq '[:^alpha:]' ) { push @mbcs, "(?:(?![\\x41-\\x5A\\x61-\\x7A])$x)";                                 }
                    elsif ($before_subclass eq '[:^ascii:]' ) { push @mbcs, "(?:(?![\\x00-\\x7F])$x)";                                            }
                    elsif ($before_subclass eq '[:^blank:]' ) { push @mbcs, "(?:(?![\\x09\\x20])$x)";                                             }
                    elsif ($before_subclass eq '[:^cntrl:]' ) { push @mbcs, "(?:(?![\\x00-\\x1F\\x7F])$x)";                                       }
                    elsif ($before_subclass eq '[:^digit:]' ) { push @mbcs, "(?:(?![\\x30-\\x39])$x)";                                            }
                    elsif ($before_subclass eq '[:^graph:]' ) { push @mbcs, "(?:(?![\\x21-\\x7F])$x)";                                            }
                    elsif ($before_subclass eq '[:^lower:]' ) { push @mbcs, "(?:(?![\\x61-\\x7A])$x)";                                            } # /i modifier requires 'a' to 'z' literally
                    elsif ($before_subclass eq '[:^print:]' ) { push @mbcs, "(?:(?![\\x20-\\x7F])$x)";                                            }
                    elsif ($before_subclass eq '[:^punct:]' ) { push @mbcs, "(?:(?![\\x21-\\x2F\\x3A-\\x3F\\x40\\x5B-\\x5F\\x60\\x7B-\\x7E])$x)"; }
                    elsif ($before_subclass eq '[:^space:]' ) { push @mbcs, "(?:(?![\\s\\x0B])$x)";                                               } # "\s" and vertical tab ("\cK")
                    elsif ($before_subclass eq '[:^upper:]' ) { push @mbcs, "(?:(?![\\x41-\\x5A])$x)";                                            } # /i modifier requires 'A' to 'Z' literally
                    elsif ($before_subclass eq '[:^word:]'  ) { push @mbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x5F\\x61-\\x7A])$x)";                 }
                    elsif ($before_subclass eq '[:^xdigit:]') { push @mbcs, "(?:(?![\\x30-\\x39\\x41-\\x46\\x61-\\x66])$x)";                      }

                    # other all
                    elsif (CORE::length($before_subclass)==1) { push @sbcs, $before_subclass }
                    else                                      { push @mbcs, $before_subclass }
                    $i += 1;
                }
            }

            # [^...]
            if ($negative eq q[^]) {
                push @after_subregex,
                    ( @sbcs and  @mbcs) ? '(?:(?!' . join('|', @mbcs, '['.join('',@sbcs).']') . ")$x)" :
                    (!@sbcs and  @mbcs) ? '(?:(?!' . join('|', @mbcs                        ) . ")$x)" :
                    ( @sbcs and !@mbcs) ? '(?:(?!' .                  '['.join('',@sbcs).']'  . ")$x)" :
                    '';
            }

            # [...] on Perl 5.006
            elsif ($] =~ /\A5\.006/) {
                push @after_subregex,
                    ( @sbcs and  @mbcs) ? '(?:'    . join('|', @mbcs, '['.join('',@sbcs).']') .    ')' :
                    (!@sbcs and  @mbcs) ? '(?:'    . join('|', @mbcs                        ) .    ')' :
                    ( @sbcs and !@mbcs) ?                             '['.join('',@sbcs).']'           :
                    '';
            }

            # [...]
            else {
                push @after_subregex,
                    ( @sbcs and  @mbcs) ? '(?:(?=' . join('|', @mbcs, '['.join('',@sbcs).']') . ")$x)" :
                    (!@sbcs and  @mbcs) ? '(?:(?=' . join('|', @mbcs                        ) . ")$x)" :
                    ( @sbcs and !@mbcs) ?                             '['.join('',@sbcs).']'           :
                    '';
            }
        }

        # \any or /./
        elsif ($before_subregex eq '.' ) { push @after_subregex, ($modifiers =~ /s/) ? $x : "(?:(?!\\n)$x)"                    }
        elsif ($before_subregex eq '\B') { push @after_subregex, "(?:(?<![$bare_w])(?![$bare_w])|(?<=[$bare_w])(?=[$bare_w]))" }
        elsif ($before_subregex eq '\D') { push @after_subregex, "(?:(?![$bare_d])$x)"                                         }
        elsif ($before_subregex eq '\H') { push @after_subregex, "(?:(?![$bare_h])$x)"                                         }
        elsif ($before_subregex eq '\N') { push @after_subregex, "(?:(?!\\n)$x)"                                               }
        elsif ($before_subregex eq '\R') { push @after_subregex, "(?>\\r\\n|[$bare_v])"                                        }
        elsif ($before_subregex eq '\S') { push @after_subregex, "(?:(?![$bare_s])$x)"                                         }
        elsif ($before_subregex eq '\V') { push @after_subregex, "(?:(?![$bare_v])$x)"                                         }
        elsif ($before_subregex eq '\W') { push @after_subregex, "(?:(?![$bare_w])$x)"                                         }
        elsif ($before_subregex eq '\b') { push @after_subregex, "(?:(?<![$bare_w])(?=[$bare_w])|(?<=[$bare_w])(?![$bare_w]))" }
        elsif ($before_subregex eq '\d') { push @after_subregex, "[$bare_d]"                                                   }
        elsif ($before_subregex eq '\h') { push @after_subregex, "[$bare_h]"                                                   }
        elsif ($before_subregex eq '\s') { push @after_subregex, "[$bare_s]"                                                   }
        elsif ($before_subregex eq '\v') { push @after_subregex, "[$bare_v]"                                                   }
        elsif ($before_subregex eq '\w') { push @after_subregex, "[$bare_w]"                                                   }

        # quantifiers ? + * {n} {n,} {n,m}
        elsif ($before_subregex =~ /\A[?+*{]\z/) {
            if    (0)                                                      { }
            elsif ($after_subregex[-1] =~ /\A \\c [\x00-\xFF]        \z/x) { } # \c) \c} \c] \cX
            elsif ($after_subregex[-1] =~ /\A \\  [\x00-\xFF]        \z/x) { } # \) \} \] \" \0 \1 \D \E \F \G \H \K \L \N \Q \R \S \U \V \W \\ \a \d \e \f \h \l \n \r \s \t \u \v \w
            elsif ($after_subregex[-1] =~ /\A     [\x00-\xFF]        \z/x) { } # (a) a{1} [a] a . \012 \x12 \o{12} \g{1}
            elsif ($after_subregex[-1] =~ /       [\x00-\xFF] [)}\]] \z/x) { } # (any) any{1} [any]
            else {                                                             # MBCS
                $after_subregex[-1] = '(?:' . $after_subregex[-1] . ')';
            }
            push @after_subregex, $before_subregex;
        }

        # \x{UTF8hex}
        elsif ($before_subregex =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) {
            push @after_subregex, UTF8::R2::chr(hex $1);
        }

        # else
        else {
            push @after_subregex, $before_subregex;
        }
    }

    my $after_regex = join '', @after_subregex;
    return qr/$after_regex/;
}

#---------------------------------------------------------------------
# reverse() for UTF-8 codepoint string
sub UTF8::R2::reverse (@) {

    # in list context,
    if (wantarray) {

        # returns a list value consisting of the elements of @_ in the opposite order
        return CORE::reverse @_;
    }

    # in scalar context,
    else {

        # returns a string value with all characters in the opposite order of
        return (join '',
            CORE::reverse(
                @_ ?
                join('',@_) =~ /\G$x/g : # concatenates the elements of @_
                /\G$x/g                  # $_ when without arguments
            )
        );
    }
}

#---------------------------------------------------------------------
# rindex() for UTF-8 codepoint string
sub UTF8::R2::rindex ($$;$) {
    my $rindex = 0;
    if (@_ == 3) {
        $rindex = CORE::rindex $_[0], $_[1], CORE::length(UTF8::R2::substr($_[0], 0, $_[2]));
    }
    else {
        $rindex = CORE::rindex $_[0], $_[1];
    }
    if ($rindex == -1) {
        return -1;
    }
    else {
        return UTF8::R2::length(CORE::substr $_[0], 0, $rindex);
    }
}

#---------------------------------------------------------------------
# split() for UTF-8 codepoint string
sub UTF8::R2::split (;$$$) {
    if (defined($_[0]) and (($_[0] eq '') or ($_[0] =~ /\A \( \? \^? [-a-z]* : \) \z/x))) {
        my @x = (defined($_[1]) ? $_[1] : $_) =~ /\G$x/g;
        if (defined($_[2]) and ($_[2] > 0) and (scalar(@x) > $_[2])) {
            @x = (@x[0..$_[2]-1-1], join('', @x[$_[2]-1..$#x]));
        }
        if (wantarray) {
            return @x;
        }
        else {
            if ($] < 5.012) {
                warn "Use of implicit split to \@_ is deprecated" if $^W;
                @_ = @x; # unlike camel book and perldoc saying, can return only scalar(@_), cannot @_
            }
            return scalar @x;
        }
    }
    elsif (@_ == 3) {
        return CORE::split UTF8::R2::qr($_[0]), $_[1], $_[2];
    }
    elsif (@_ == 2) {
        return CORE::split UTF8::R2::qr($_[0]), $_[1];
    }
    elsif (@_ == 1) {
        return CORE::split UTF8::R2::qr($_[0]);
    }
    else {
        return CORE::split;
    }
}

#---------------------------------------------------------------------
# substr() for UTF-8 codepoint string
CORE::eval sprintf <<'END', ($] >= 5.014) ? ':lvalue' : '';
#                            vv--------------*******
sub UTF8::R2::substr ($$;$$) %s {
    my @x = $_[0] =~ /\G$x/g;

    # If the substring is beyond either end of the string, substr() returns the undefined
    # value and produces a warning. When used as an lvalue, specifying a substring that
    # is entirely outside the string raises an exception.
    # http://perldoc.perl.org/functions/substr.html

    # A return with no argument returns the scalar value undef in scalar context,
    # an empty list () in list context, and (naturally) nothing at all in void
    # context.

    if (($_[1] < (-1 * scalar(@x))) or (+1 * scalar(@x) < $_[1])) {
        return;
    }

    # substr($string,$offset,$length,$replacement)
    if (@_ == 4) {
        my $substr = join '', splice @x, $_[1], $_[2], $_[3];
        $_[0] = join '', @x;
        $substr; # "return $substr" doesn't work, don't write "return"
    }

    # substr($string,$offset,$length)
    elsif (@_ == 3) {
        local $SIG{__WARN__} = sub {}; # avoid: Use of uninitialized value in join or string at here
        my $octet_offset =
            ($_[1] < 0) ? -1 * CORE::length(join '', @x[$#x+$_[1]+1 .. $#x])     :
            ($_[1] > 0) ?      CORE::length(join '', @x[0           .. $_[1]-1]) :
            0;
        my $octet_length =
            ($_[2] < 0) ? -1 * CORE::length(join '', @x[$#x+$_[2]+1 .. $#x])           :
            ($_[2] > 0) ?      CORE::length(join '', @x[$_[1]       .. $_[1]+$_[2]-1]) :
            0;
        CORE::substr($_[0], $octet_offset, $octet_length);
    }

    # substr($string,$offset)
    else {
        my $octet_offset =
            ($_[1] < 0) ? -1 * CORE::length(join '', @x[$#x+$_[1]+1 .. $#x])     :
            ($_[1] > 0) ?      CORE::length(join '', @x[0           .. $_[1]-1]) :
            0;
        CORE::substr($_[0], $octet_offset);
    }
}
END

#---------------------------------------------------------------------
# tr/A-C/1-3/ for UTF-8 codepoint
sub list_all_ASCII_by_hyphen {
    my @hyphened = @_;
    my @list_all = ();
    for (my $i=0; $i <= $#hyphened; ) {
        if (
            ($i+1 < $#hyphened)      and
            ($hyphened[$i+1] eq '-') and
        1) {
            $hyphened[$i+0] = ($hyphened[$i+0] eq '\\-') ? '-' : $hyphened[$i+0];
            $hyphened[$i+2] = ($hyphened[$i+2] eq '\\-') ? '-' : $hyphened[$i+2];
            if (0) { }
            elsif ($hyphened[$i+0] !~ m/\A [\x00-\x7F] \z/oxms) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not ASCII});
            }
            elsif ($hyphened[$i+2] !~ m/\A [\x00-\x7F] \z/oxms) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not ASCII});
            }
            elsif ($hyphened[$i+0] gt $hyphened[$i+2]) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not "$hyphened[$i+0]" le "$hyphened[$i+2]"});
            }
            else {
                push @list_all, map { CORE::chr($_) } (CORE::ord($hyphened[$i+0]) .. CORE::ord($hyphened[$i+2]));
                $i += 3;
            }
        }
        else {
            if ($hyphened[$i] eq '\\-') {
                push @list_all, '-';
            }
            else {
                push @list_all, $hyphened[$i];
            }
            $i++;
        }
    }
    return @list_all;
}

#---------------------------------------------------------------------
# tr/// for UTF-8 codepoint string
sub UTF8::R2::tr ($$$;$) {
    my @x           = $_[0] =~ /\G$x/g;
    my @search      = list_all_ASCII_by_hyphen($_[1] =~ /\G(\\-|$x)/xmsg);
    my @replacement = list_all_ASCII_by_hyphen($_[2] =~ /\G(\\-|$x)/xmsg);
    my %modifier    = (defined $_[3]) ? (map { $_ => 1 } CORE::split //, $_[3]) : ();

    my %tr = ();
    for (my $i=0; $i <= $#search; $i++) {

        # tr/AAA/123/ works as tr/A/1/
        if (not exists $tr{$search[$i]}) {

            # tr/ABC/123/ makes %tr = ('A'=>'1','B'=>'2','C'=>'3',);
            if (defined $replacement[$i] and ($replacement[$i] ne '')) {
                $tr{$search[$i]} = $replacement[$i];
            }

            # tr/ABC/12/d makes %tr = ('A'=>'1','B'=>'2','C'=>'',);
            elsif (exists $modifier{d}) {
                $tr{$search[$i]} = '';
            }

            # tr/ABC/12/ makes %tr = ('A'=>'1','B'=>'2','C'=>'2',);
            elsif (defined $replacement[-1] and ($replacement[-1] ne '')) {
                $tr{$search[$i]} = $replacement[-1];
            }

            # tr/ABC// makes %tr = ('A'=>'A','B'=>'B','C'=>'C',);
            else {
                $tr{$search[$i]} = $search[$i];
            }
        }
    }

    my $tr = 0;
    my $replaced = '';

    # has /c modifier
    if (exists $modifier{c}) {

        # has /s modifier
        if (exists $modifier{s}) {
            my $last_transliterated = undef;
            while (defined(my $x = shift @x)) {

                # /c modifier works here
                if (exists $tr{$x}) {
                    $replaced .= $x;
                    $last_transliterated = undef;
                }
                else {

                    # /d modifier works here
                    if (exists $modifier{d}) {
                    }

                    elsif (defined $replacement[-1]) {

                        # /s modifier works here
                        if (defined($last_transliterated) and ($replacement[-1] eq $last_transliterated)) {
                        }

                        # tr/// works here
                        else {
                            $replaced .= ($last_transliterated = $replacement[-1]);
                        }
                    }
                    $tr++;
                }
            }
        }

        # has no /s modifier
        else {
            while (defined(my $x = shift @x)) {

                # /c modifier works here
                if (exists $tr{$x}) {
                    $replaced .= $x;
                }
                else {

                    # /d modifier works here
                    if (exists $modifier{d}) {
                    }

                    # tr/// works here
                    elsif (defined $replacement[-1]) {
                        $replaced .= $replacement[-1];
                    }
                    $tr++;
                }
            }
        }
    }

    # has no /c modifier
    else {

        # has /s modifier
        if (exists $modifier{s}) {
            my $last_transliterated = undef;
            while (defined(my $x = shift @x)) {
                if (exists $tr{$x}) {

                    # /d modifier works here
                    if ($tr{$x} eq '') {
                    }

                    # /s modifier works here
                    elsif (defined($last_transliterated) and ($tr{$x} eq $last_transliterated)) {
                    }

                    # tr/// works here
                    else {
                        $replaced .= ($last_transliterated = $tr{$x});
                    }
                    $tr++;
                }
                else {
                    $replaced .= $x;
                    $last_transliterated = undef;
                }
            }
        }

        # has no /s modifier
        else {
            while (defined(my $x = shift @x)) {
                if (exists $tr{$x}) {
                    $replaced .= $tr{$x};
                    $tr++;
                }
                else {
                    $replaced .= $x;
                }
            }
        }
    }

    # /r modifier works here
    if (exists $modifier{r}) {
        return $replaced;
    }

    # has no /r modifier
    else {
        $_[0] = $replaced;
        return $tr;
    }
}

#---------------------------------------------------------------------
# universal uc() for UTF-8 codepoint string
sub UTF8::R2::uc (;$) {
    local $_ = @_ ? $_[0] : $_;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
    return join '', map { {qw( a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z )}->{$_}||$_ } /\G$x/g;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
}

#---------------------------------------------------------------------
# universal ucfirst() for UTF-8 codepoint string
sub UTF8::R2::ucfirst (;$) {
    local $_ = @_ ? $_[0] : $_;
    if (/\A($x)(.*)\z/s) {
        return UTF8::R2::uc($1) . $2;
    }
    else {
        return '';
    }
}

# syntax sugar for UTF-8 codepoint regex
#
# tie my %mb, 'UTF8::R2';
# $result = $_ =~ $mb{qr/$utf8regex/imsxo}
# $result = $_ =~ m<\G$mb{qr/$utf8regex/imsxo}>gc
# $result = $_ =~ s<$mb{qr/before/imsxo}><after>egr

sub TIEHASH  { bless { }, $_[0] }
sub FETCH    { UTF8::R2::qr $_[1] }
sub STORE    { }
sub FIRSTKEY { }
sub NEXTKEY  { }
sub EXISTS   { }
sub DELETE   { }
sub CLEAR    { }
sub UNTIE    { }
sub DESTROY  { }
sub SCALAR   { }

1;

__END__

=pod

=head1 NAME

UTF8::R2 - makes UTF-8 scripting easy for enterprise use or LTS

=head1 SYNOPSIS

  use UTF8::R2;
  use UTF8::R2 ver.sion;            # match or die
  use UTF8::R2 qw( RFC3629 );       # m/./ matches RFC3629 codepoint (default)
  use UTF8::R2 qw( RFC2279 );       # m/./ matches RFC2279 codepoint
  use UTF8::R2 qw( WTF8 );          # m/./ matches WTF-8 codepoint
  use UTF8::R2 qw( RFC3629.ja_JP ); # optimized RFC3629 for ja_JP
  use UTF8::R2 qw( WTF8.ja_JP );    # optimized WTF-8 for ja_JP
  use UTF8::R2 qw( %mb );           # multibyte regex by %mb

    $result = UTF8::R2::chop(@_)
    $result = UTF8::R2::chr($utf8octet_not_unicode)
    $result = UTF8::R2::getc(FILEHANDLE)
    $result = UTF8::R2::index($_, 'ABC', 5)
    $result = UTF8::R2::lc($_)
    $result = UTF8::R2::lcfirst($_)
    $result = UTF8::R2::length($_)
    $result = UTF8::R2::ord($_)
    $result = UTF8::R2::qr(qr/$utf8regex/imsxo) # no /gc
    @result = UTF8::R2::reverse(@_)
    $result = UTF8::R2::reverse(@_)
    $result = UTF8::R2::reverse()
    $result = UTF8::R2::rindex($_, 'ABC', 5)
    @result = UTF8::R2::split(qr/$utf8regex/, $_, 3)
    $result = UTF8::R2::substr($_, 0, 5)
    $result = UTF8::R2::tr($_, 'A-C', 'X-Z', 'cdsr')
    $result = UTF8::R2::uc($_)
    $result = UTF8::R2::ucfirst($_)

    use UTF8::R2 qw(%mb);
    $result = $_ =~ $mb{qr/$utf8regex/imsxo}
    $result = $_ =~ m<\G$mb{qr/$utf8regex/imsxo}>gc
    $result = $_ =~ s<$mb{qr/before/imsxo}><after>egr

=head1 Octet-Semantics Functions vs. Codepoint-Semantics Subroutines

This software adds the ability to handle UTF-8 code points to bare Perl; it does
not provide the ability to handle characters and graphene with UTF-8.
(Time is on our side, so let's all be excited for the day when code points
represent graphene.)
Because this module override nothing, the functions of bare Perl provide octet
semantics continue. UTF-8 codepoint semantics is provided by the new subroutine
name.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Octet-semantics         UTF-8 Codepoint-semantics
  by traditional name     by new name                                Note and Limitations
  ------------------------------------------------------------------------------------------------------------------------------------------
  chop                    UTF8::R2::chop(@_)                         usually chomp() is useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  chr                     UTF8::R2::chr($_)                          returns UTF-8 codepoint octets by UTF-8 hex number (not by Unicode number)
  ------------------------------------------------------------------------------------------------------------------------------------------
  getc                    UTF8::R2::getc(FILEHANDLE)                 get UTF-8 codepoint octets
  ------------------------------------------------------------------------------------------------------------------------------------------
  index                   UTF8::R2::index($_, 'ABC', 5)              index() is compatible and usually useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  lc                      UTF8::R2::lc($_)                           works as tr/A-Z/a-z/, universally
  ------------------------------------------------------------------------------------------------------------------------------------------
  lcfirst                 UTF8::R2::lcfirst($_)                      see UTF8::R2::lc()
  ------------------------------------------------------------------------------------------------------------------------------------------
  length                  UTF8::R2::length($_)                       length() is compatible and usually useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  // or m// or qr//       UTF8::R2::qr(qr/$utf8regex/imsxo)          not supports metasymbol \X that match grapheme
                          m<@{[UTF8::R2::qr(qr/$utf8regex/imsxo)]}>gc
                            or                                       not supports named character (such as \N{GREEK SMALL LETTER EPSILON}, \N{greek:epsilon}, or \N{epsilon})
                          use UTF8::R2 qw(%mb);                      not supports character properties (like \p{PROP} and \P{PROP})
                          $mb{qr/$utf8regex/imsxo}                   modifier i, m, s, x, o work on compile time
                          m<\G$mb{qr/$utf8regex/imsxo}>gc            modifier g,c work on run time

                          Special Escapes in Regex                   Support Perl Version
                          --------------------------------------------------------------------------------------------------
                          $mb{qr/ \x{UTF8hex} /}                     since perl 5.005
                          $mb{qr/ [\x{UTF8hex}] /}                   since perl 5.005
                          $mb{qr/ [[:POSIX:]] /}                     since perl 5.005
                          $mb{qr/ [[:^POSIX:]] /}                    since perl 5.005
                          $mb{qr/ [^ ... ] /}                        ** CAUTION ** perl 5.006 cannot this
                          $mb{qr/ [\x{UTF8hex}-\x{UTF8hex}] /}       since perl 5.008
                          $mb{qr/ \h /}                              since perl 5.010
                          $mb{qr/ \v /}                              since perl 5.010
                          $mb{qr/ \H /}                              since perl 5.010
                          $mb{qr/ \V /}                              since perl 5.010
                          $mb{qr/ \R /}                              since perl 5.010
                          $mb{qr/ \N /}                              since perl 5.012
                          (max \x{UTF8hex} is \x{7FFFFFFF}, so cannot 4 octet codepoints, pardon me please!)
  ------------------------------------------------------------------------------------------------------------------------------------------
  ?? or m??                 (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------
  ord                     UTF8::R2::ord($_)                          returns UTF-8 number (not Unicode number) by UTF-8 codepoint octets
  ------------------------------------------------------------------------------------------------------------------------------------------
  pos                       (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------
  reverse                 UTF8::R2::reverse(@_)
  ------------------------------------------------------------------------------------------------------------------------------------------
  rindex                  UTF8::R2::rindex($_, 'ABC', 5)             rindex() is compatible and usually useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  s/before/after/imsxoegr s<@{[UTF8::R2::qr(qr/before/imsxo)]}><after>egr
                            or
                          use UTF8::R2 qw(%mb);
                          s<$mb{qr/before/imsxo}><after>egr
  ------------------------------------------------------------------------------------------------------------------------------------------
  split//                 UTF8::R2::split(qr/$utf8regex/imsxo, $_, 3)  *CAUTION* UTF8::R2::split(/re/,$_,3) means UTF8::R2::split($_ =~ /re/,$_,3)
  ------------------------------------------------------------------------------------------------------------------------------------------
  sprintf                   (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------
  substr                  UTF8::R2::substr($_, 0, 5)                 substr() is compatible and usually useful
                                                                     :lvalue feature needs perl 5.014 or later
  ------------------------------------------------------------------------------------------------------------------------------------------
  tr/// or y///           UTF8::R2::tr($_, 'A-C', 'X-Z', 'cdsr')     range of codepoint by hyphen supports ASCII only
  ------------------------------------------------------------------------------------------------------------------------------------------
  uc                      UTF8::R2::uc($_)                           works as tr/a-z/A-Z/, universally
  ------------------------------------------------------------------------------------------------------------------------------------------
  ucfirst                 UTF8::R2::ucfirst($_)                      see UTF8::R2::uc()
  ------------------------------------------------------------------------------------------------------------------------------------------
  write                     (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------

=head1 UTF8 Flag Considered Harmful, and Our Goals

P.401 See chapter 15: Unicode
of ISBN 0-596-00027-8 Programming Perl Third Edition.

Before the introduction of Unicode support in perl, The eq operator
just compared the byte-strings represented by two scalars. Beginning
with perl 5.8, eq compares two byte-strings with simultaneous
consideration of the UTF8 flag.

-- we have been taught so for a long time.

Perl is a powerful language for everyone, but UTF8 flag is a barrier
for common beginners. Because everyone can only one task on one time.
So calling Encode::encode() and Encode::decode() in application program
is not better way. Making two scripts for information processing and
encoding conversion may be better. Please trust me.

 /*
  * You are not expected to understand this.
  */
 
  Information processing model beginning with perl 5.8
 
    +----------------------+---------------------+
    |     Text strings     |                     |
    +----------+-----------|    Binary strings   |
    |  UTF-8   |  Latin-1  |                     |
    +----------+-----------+---------------------+
    | UTF8     |            Not UTF8             |
    | Flagged  |            Flagged              |
    +--------------------------------------------+
    http://perl-users.jp/articles/advent-calendar/2010/casual/4

  Confusion of Perl string model is made from double meanings of
  "Binary string."
  Meanings of "Binary string" are
  1. Non-Text string
  2. Digital octet string

  Let's draw again using those term.
 
    +----------------------+---------------------+
    |     Text strings     |                     |
    +----------+-----------|   Non-Text strings  |
    |  UTF-8   |  Latin-1  |                     |
    +----------+-----------+---------------------+
    | UTF8     |            Not UTF8             |
    | Flagged  |            Flagged              |
    +--------------------------------------------+
    |            Digital octet string            |
    +--------------------------------------------+

There are people who don't agree to change in the character string
processing model of Perl 5.8. It is impossible to get to agree it to
majority of Perl user who hardly ever use Perl.
How to solve it by returning to an original method, let's drag out
page 402 of the Programming Perl, 3rd ed. again.

  Information processing model beginning with perl3 or this software
  of UNIX/C-ism.

    +--------------------------------------------+
    |    Text string as Digital octet string     |
    |    Digital octet string as Text string     |
    +--------------------------------------------+
    |       Not UTF8 Flagged, No MOJIBAKE        |
    +--------------------------------------------+

  In UNIX Everything is a File
  - In UNIX everything is a stream of bytes
  - In UNIX the filesystem is used as a universal name space

Ideally, We'd like to achieve these five Goals:

=over 2

=item * Goal #1:

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

This goal has been achieved by that this software is additional code
for perl like utf8 pragma. Perl should work same as past Perl if added
nothing.

=item * Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

Not "magically."
You must decide and write octet semantics or UTF-8 codepoint semantics yourself
in case by case. Perhaps almost all regular expressions should have UTF-8
codepoint semantics. And other all should have octet semantics.

=item * Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is almost possible.
Because UTF-8 encoding doesn't need multibyte anchoring in regular expression.

=item * Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

UTF8::R2 module remains one language and one interpreter by providing
codepoint semantics subroutines.

=item * Goal #5:

UTF8::R2 module users will be able to maintain it by Perl.

May the UTF8::R2 be with you, always.

=back

Back when Programming Perl, 3rd ed. was written, UTF8 flag was not born
and Perl is designed to make the easy jobs easy. This software provides
programming environment like at that time.

=head1 Perl's Motto

   Some computer scientists (the reductionists, in particular) would
  like to deny it, but people have funny-shaped minds. Mental geography
  is not linear, and cannot be mapped onto a flat surface without
  severe distortion. But for the last score years or so, computer
  reductionists have been first bowing down at the Temple of Orthogonality,
  then rising up to preach their ideas of ascetic rectitude to any who
  would listen.
 
   Their fervent but misguided desire was simply to squash your mind to
  fit their mindset, to smush your patterns of thought into some sort of
  Hyperdimensional Flatland. It's a joyless existence, being smushed.
  --- Learning Perl on Win32 Systems

  If you think this is a big headache, you're right. No one likes
  this situation, but Perl does the best it can with the input and
  encodings it has to deal with. If only we could reset history and
  not make so many mistakes next time.
  --- Learning Perl 6th Edition

   The most important thing for most people to know about handling
  Unicode data in Perl, however, is that if you don't ever use any Uni-
  code data -- if none of your files are marked as UTF-8 and you don't
  use UTF-8 locales -- then you can happily pretend that you're back in
  Perl 5.005_03 land; the Unicode features will in no way interfere with
  your code unless you're explicitly using them. Sometimes the twin
  goals of embracing Unicode but not disturbing old-style byte-oriented
  scripts has led to compromise and confusion, but it's the Perl way to
  silently do the right thing, which is what Perl ends up doing.
  --- Advanced Perl Programming, 2nd Edition

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE and COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See the LICENSE
file for details.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
