package UTF8::R2;
######################################################################
#
# UTF8::R2 - makes UTF-8 scripting easy for enterprise use
#
# http://search.cpan.org/dist/UTF8-R2/
#
# Copyright (c) 2019, 2020, 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.22';
$VERSION = $VERSION;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 } use warnings; local $^W=1;
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
my $bare_backspace = '\x08';
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

    # $^X($EXECUTABLE_NAME) for execute MBCS Perl script
    $UTF8::R2::PERL = $^X;
    $UTF8::R2::PERL = $UTF8::R2::PERL; # to avoid: Name "UTF8::R2::PERL" used only once: possible typo at ...

    # original $0($PROGRAM_NAME)
    $UTF8::R2::ORIG_PROGRAM_NAME = $0;
    $UTF8::R2::ORIG_PROGRAM_NAME = $UTF8::R2::ORIG_PROGRAM_NAME; # to avoid: Name "UTF8::R2::ORIG_PROGRAM_NAME" used only once: possible typo at ...
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
# mb::do() like do(), mb.pm compatible
sub UTF8::R2::do ($) {

    # run as Perl script
    return CORE::eval sprintf(<<'END', (caller)[0,2,1]);
package %s;
#line %s "%s"
CORE::do "$_[0]";
END
}

#---------------------------------------------------------------------
# mb::dosglob() like glob(), mb.pm compatible
sub UTF8::R2::dosglob (;$) {
    my $expr = @_ ? $_[0] : $_;

    # returns globbing result
    my %glob = map { $_ => 1 } CORE::glob($expr);
    return sort { (UTF8::R2::uc($a) cmp UTF8::R2::uc($b)) || ($a cmp $b) } keys %glob;
}

#---------------------------------------------------------------------
# mb::eval() like eval(), mb.pm compatible
sub UTF8::R2::eval (;$) {
    local $_ = @_ ? $_[0] : $_;

    # run as Perl script in caller package
    return CORE::eval sprintf(<<'END', (caller)[0,2,1], $_);
package %s;
#line %s "%s"
%s
END
}

#---------------------------------------------------------------------
# getc() for UTF-8 codepoint string
sub UTF8::R2::getc (;*) {
    my $fh = @_ ? Symbol::qualify_to_ref($_[0],caller()) : \*STDIN;
    my $getc = CORE::getc $fh;
    if ($getc =~ /\A [\x00-\x7F\x80-\xC1\xF5-\xFF] \z/xms) {
    }
    elsif ($getc =~ /\A [\xC2-\xDF] \z/xms) {
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
# JPerl like index() for UTF-8 codepoint string
sub UTF8::R2::index_byte ($$;$) {
    if (@_ == 3) {
        return CORE::index $_[0], $_[1], CORE::length(UTF8::R2::substr($_[0], 0, $_[2]));
    }
    else {
        return CORE::index $_[0], $_[1];
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

    my $modifiers = '';
    if (($modifiers) = $_[0] =~ /\A \( \? \^? (.*?) : /x) {
        $modifiers =~ s/-.*//;
    }

    my @after = ();
    while ($_[0] =~ s! \A (
        (?> \[ (?: \[:[^:]+?:\] | \\x\{[0123456789ABCDEFabcdef]+\} | \\c[\x00-\xFF] | (?>\\$x) | $x )+? \] ) |
                                  \\x\{[0123456789ABCDEFabcdef]+\} | \\c[\x00-\xFF] | (?>\\$x) | $x
    ) !!x) {
        my $before = $1;

        # [^...] or [...]
        if (my($negative,$class) = $before =~ /\A \[ (\^?) ((?>\\$x|$x)+?) \] \z/x) {
            my @classmate = $class =~ /\G (?: \[:.+?:\] | \\x\{[0123456789ABCDEFabcdef]+\} | (?>\\$x) | $x ) /xg;
            my @sbcs = ();
            my @xbcs = ();

            for (my $i=0; $i <= $#classmate; ) {
                my $classmate = $classmate[$i];

                # hyphen of [A-Z] or [^A-Z]
                if (($i < $#classmate) and ($classmate[$i+1] eq '-')) {
                    my $a = ($classmate[$i+0] =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) ? UTF8::R2::chr(hex $1) : $classmate[$i+0];
                    my $b = ($classmate[$i+2] =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) ? UTF8::R2::chr(hex $1) : $classmate[$i+2];
                    push @xbcs, list_all_by_hyphen_utf8_like($a, $b);
                    $i += 3;
                }

                # any "one"
                else {

                    # \x{UTF8hex}
                    if ($classmate =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) {
                        push @xbcs, UTF8::R2::chr(hex $1);
                    }

                    # \any
                    elsif ($classmate eq '\D'         ) { push @xbcs, "(?:(?![$bare_d])$x)"  }
                    elsif ($classmate eq '\H'         ) { push @xbcs, "(?:(?![$bare_h])$x)"  }
#                   elsif ($classmate eq '\N'         ) { push @xbcs, "(?:(?!\\n)$x)"        } # \N in a character class must be a named character: \N{...} in regex
#                   elsif ($classmate eq '\R'         ) { push @xbcs, "(?>\\r\\n|[$bare_v])" } # Unrecognized escape \R in character class passed through in regex
                    elsif ($classmate eq '\S'         ) { push @xbcs, "(?:(?![$bare_s])$x)"  }
                    elsif ($classmate eq '\V'         ) { push @xbcs, "(?:(?![$bare_v])$x)"  }
                    elsif ($classmate eq '\W'         ) { push @xbcs, "(?:(?![$bare_w])$x)"  }
                    elsif ($classmate eq '\b'         ) { push @sbcs, $bare_backspace        }
                    elsif ($classmate eq '\d'         ) { push @sbcs, $bare_d                }
                    elsif ($classmate eq '\h'         ) { push @sbcs, $bare_h                }
                    elsif ($classmate eq '\s'         ) { push @sbcs, $bare_s                }
                    elsif ($classmate eq '\v'         ) { push @sbcs, $bare_v                }
                    elsif ($classmate eq '\w'         ) { push @sbcs, $bare_w                }

                    # [:POSIX:]
                    elsif ($classmate eq '[:alnum:]'  ) { push @sbcs, '\x30-\x39\x41-\x5A\x61-\x7A';                  }
                    elsif ($classmate eq '[:alpha:]'  ) { push @sbcs, '\x41-\x5A\x61-\x7A';                           }
                    elsif ($classmate eq '[:ascii:]'  ) { push @sbcs, '\x00-\x7F';                                    }
                    elsif ($classmate eq '[:blank:]'  ) { push @sbcs, '\x09\x20';                                     }
                    elsif ($classmate eq '[:cntrl:]'  ) { push @sbcs, '\x00-\x1F\x7F';                                }
                    elsif ($classmate eq '[:digit:]'  ) { push @sbcs, '\x30-\x39';                                    }
                    elsif ($classmate eq '[:graph:]'  ) { push @sbcs, '\x21-\x7F';                                    }
                    elsif ($classmate eq '[:lower:]'  ) { push @sbcs, '\x61-\x7A';                                    } # /i modifier requires 'a' to 'z' literally
                    elsif ($classmate eq '[:print:]'  ) { push @sbcs, '\x20-\x7F';                                    }
                    elsif ($classmate eq '[:punct:]'  ) { push @sbcs, '\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E'; }
                    elsif ($classmate eq '[:space:]'  ) { push @sbcs, '\s\x0B';                                       } # "\s" and vertical tab ("\cK")
                    elsif ($classmate eq '[:upper:]'  ) { push @sbcs, '\x41-\x5A';                                    } # /i modifier requires 'A' to 'Z' literally
                    elsif ($classmate eq '[:word:]'   ) { push @sbcs, '\x30-\x39\x41-\x5A\x5F\x61-\x7A';              }
                    elsif ($classmate eq '[:xdigit:]' ) { push @sbcs, '\x30-\x39\x41-\x46\x61-\x66';                  }

                    # [:^POSIX:]
                    elsif ($classmate eq '[:^alnum:]' ) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x61-\\x7A])$x)";                      }
                    elsif ($classmate eq '[:^alpha:]' ) { push @xbcs, "(?:(?![\\x41-\\x5A\\x61-\\x7A])$x)";                                 }
                    elsif ($classmate eq '[:^ascii:]' ) { push @xbcs, "(?:(?![\\x00-\\x7F])$x)";                                            }
                    elsif ($classmate eq '[:^blank:]' ) { push @xbcs, "(?:(?![\\x09\\x20])$x)";                                             }
                    elsif ($classmate eq '[:^cntrl:]' ) { push @xbcs, "(?:(?![\\x00-\\x1F\\x7F])$x)";                                       }
                    elsif ($classmate eq '[:^digit:]' ) { push @xbcs, "(?:(?![\\x30-\\x39])$x)";                                            }
                    elsif ($classmate eq '[:^graph:]' ) { push @xbcs, "(?:(?![\\x21-\\x7F])$x)";                                            }
                    elsif ($classmate eq '[:^lower:]' ) { push @xbcs, "(?:(?![\\x61-\\x7A])$x)";                                            } # /i modifier requires 'a' to 'z' literally
                    elsif ($classmate eq '[:^print:]' ) { push @xbcs, "(?:(?![\\x20-\\x7F])$x)";                                            }
                    elsif ($classmate eq '[:^punct:]' ) { push @xbcs, "(?:(?![\\x21-\\x2F\\x3A-\\x3F\\x40\\x5B-\\x5F\\x60\\x7B-\\x7E])$x)"; }
                    elsif ($classmate eq '[:^space:]' ) { push @xbcs, "(?:(?![\\s\\x0B])$x)";                                               } # "\s" and vertical tab ("\cK")
                    elsif ($classmate eq '[:^upper:]' ) { push @xbcs, "(?:(?![\\x41-\\x5A])$x)";                                            } # /i modifier requires 'A' to 'Z' literally
                    elsif ($classmate eq '[:^word:]'  ) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x5F\\x61-\\x7A])$x)";                 }
                    elsif ($classmate eq '[:^xdigit:]') { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x46\\x61-\\x66])$x)";                      }

                    # other all
                    elsif (CORE::length($classmate)==1) { push @sbcs, $classmate }
                    else                                { push @xbcs, $classmate }
                    $i += 1;
                }
            }

            # [^...]
            if ($negative eq q[^]) {
                push @after,
                    ( @sbcs and  @xbcs) ? '(?:(?!' . join('|', @xbcs, '['.join('',@sbcs).']') . ")$x)" :
                    (!@sbcs and  @xbcs) ? '(?:(?!' . join('|', @xbcs                        ) . ")$x)" :
                    ( @sbcs and !@xbcs) ? '(?:(?!' .                  '['.join('',@sbcs).']'  . ")$x)" :
                    '';
            }

            # [...] on Perl 5.006
            elsif ($] =~ /\A5\.006/) {
                push @after,
                    ( @sbcs and  @xbcs) ? '(?:'    . join('|', @xbcs, '['.join('',@sbcs).']') .    ')' :
                    (!@sbcs and  @xbcs) ? '(?:'    . join('|', @xbcs                        ) .    ')' :
                    ( @sbcs and !@xbcs) ?                             '['.join('',@sbcs).']'           :
                    '';
            }

            # [...]
            else {
                push @after,
                    ( @sbcs and  @xbcs) ? '(?:(?=' . join('|', @xbcs, '['.join('',@sbcs).']') . ")$x)" :
                    (!@sbcs and  @xbcs) ? '(?:(?=' . join('|', @xbcs                        ) . ")$x)" :
                    ( @sbcs and !@xbcs) ?                             '['.join('',@sbcs).']'           :
                    '';
            }
        }

        # \any or /./
        elsif ($before eq '.' ) { push @after, ($modifiers =~ /s/) ? $x : "(?:(?!\\n)$x)"                    }
        elsif ($before eq '\B') { push @after, "(?:(?<![$bare_w])(?![$bare_w])|(?<=[$bare_w])(?=[$bare_w]))" }
        elsif ($before eq '\D') { push @after, "(?:(?![$bare_d])$x)"                                         }
        elsif ($before eq '\H') { push @after, "(?:(?![$bare_h])$x)"                                         }
        elsif ($before eq '\N') { push @after, "(?:(?!\\n)$x)"                                               }
        elsif ($before eq '\R') { push @after, "(?>\\r\\n|[$bare_v])"                                        }
        elsif ($before eq '\S') { push @after, "(?:(?![$bare_s])$x)"                                         }
        elsif ($before eq '\V') { push @after, "(?:(?![$bare_v])$x)"                                         }
        elsif ($before eq '\W') { push @after, "(?:(?![$bare_w])$x)"                                         }
        elsif ($before eq '\b') { push @after, "(?:(?<![$bare_w])(?=[$bare_w])|(?<=[$bare_w])(?![$bare_w]))" }
        elsif ($before eq '\d') { push @after, "[$bare_d]"                                                   }
        elsif ($before eq '\h') { push @after, "[$bare_h]"                                                   }
        elsif ($before eq '\s') { push @after, "[$bare_s]"                                                   }
        elsif ($before eq '\v') { push @after, "[$bare_v]"                                                   }
        elsif ($before eq '\w') { push @after, "[$bare_w]"                                                   }

        # quantifiers ? + * {n} {n,} {n,m}
        elsif ($before =~ /\A[?+*{]\z/) {
            if    (0)                                             { }
            elsif ($after[-1] =~ /\A \\c [\x00-\xFF]        \z/x) { } # \c) \c} \c] \cX
            elsif ($after[-1] =~ /\A \\  [\x00-\xFF]        \z/x) { } # \) \} \] \" \0 \1 \D \E \F \G \H \K \L \N \Q \R \S \U \V \W \\ \a \d \e \f \h \l \n \r \s \t \u \v \w
            elsif ($after[-1] =~ /\A     [\x00-\xFF]        \z/x) { } # (a) a{1} [a] a . \012 \x12 \o{12} \g{1}
            elsif ($after[-1] =~ /       [\x00-\xFF] [)}\]] \z/x) { } # (any) any{1} [any]
            else {                                                    # XBCS
                $after[-1] = '(?:' . $after[-1] . ')';
            }
            push @after, $before;
        }

        # \x{UTF8hex}
        elsif ($before =~ /\A \\x \{ ([0123456789ABCDEFabcdef]+) \} \z/x) {
            push @after, UTF8::R2::chr(hex $1);
        }

        # else
        else {
            push @after, $before;
        }
    }

    my $after = join '', @after;
    return qr/$after/;
}

#---------------------------------------------------------------------
# mb::require() like require(), mb.pm compatible
sub UTF8::R2::require (;$) {
    local $_ = @_ ? $_[0] : $_;

    # require perl version
    if (/^[0-9]/) {
        if ($] < $_) {
            confess "Perl $_ required--this is only version $], stopped";
        }
        else {
            undef $@;
            return 1;
        }
    }

    # require expr
    else {

        # find expr in @INC
        my $file = $_;
        if (($file =~ s{::}{/}g) or ($file !~ m{[\./\\]})) {
            $file .= '.pm';
        }
        if (exists $INC{$file}) {
            undef $@;
            return 1 if $INC{$file};
            confess "Compilation failed in require";
        }
        for my $prefix_file ($file, map { "$_/$file" } @INC) {
            if (-f $prefix_file) {
                $INC{$_} = $prefix_file;

                # run as Perl script
                # must use CORE::do to use <DATA>, because CORE::eval cannot do it.
                local $@;
                my $result = CORE::eval sprintf(<<'END', (caller)[0,2,1]);
package %s;
#line %s "%s"
CORE::do "$prefix_file";
END

                # return result
                if ($@) {
                    $INC{$_} = undef;
                    confess $@;
                }
                elsif (not $result) {
                    delete $INC{$_};
                    confess "$_ did not return true value";
                }
                else {
                    return $result;
                }
            }
        }
        confess "Can't find $_ in \@INC";
    }
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
# JPerl like rindex() for UTF-8 codepoint string
sub UTF8::R2::rindex_byte ($$;$) {
    if (@_ == 3) {
        return CORE::rindex $_[0], $_[1], CORE::length(UTF8::R2::substr($_[0], 0, $_[2]));
    }
    else {
        return CORE::rindex $_[0], $_[1];
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
    my @x           = $_[0] =~ /\G($x)/xmsg;
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

UTF8::R2 - makes UTF-8 scripting easy for enterprise use

=head1 SYNOPSIS

  use UTF8::R2;
  use UTF8::R2 ver.sion;            # match or die
  use UTF8::R2 qw( RFC3629 );       # m/./ matches RFC3629 codepoint (default)
  use UTF8::R2 qw( RFC2279 );       # m/./ matches RFC2279 codepoint
  use UTF8::R2 qw( WTF8 );          # m/./ matches WTF-8 codepoint
  use UTF8::R2 qw( RFC3629.ja_JP ); # optimized RFC3629 for ja_JP
  use UTF8::R2 qw( WTF8.ja_JP );    # optimized WTF-8 for ja_JP
  use UTF8::R2 qw( %mb );           # multibyte regex by %mb

  UTF8::R2::length($_)
  UTF8::R2::qr(qr/ utf8_regex_here . \D \H \N \R \S \V \W \b \d \h \s \v \w \x{UTF8hex} [ \D \H \S \V \W \b \d \h \s \v \w \x{UTF8hex} \x{UTF8hex}-\x{UTF8hex} [:POSIX:] [:^POSIX:] ] ? + * {n} {n,} {n,m} /imsxo) # no /gc
  UTF8::R2::split(qr/$utf8regex/imsxo, $_, 3)
  UTF8::R2::substr($_, 0, 5)
  UTF8::R2::tr($_, 'ABC', 'XYZ', 'cdsr')
  use UTF8::R2 qw(%mb);
    $_ =~ $mb{qr/$utf8regex/imsxo} # no /gc
    $_ =~ m<\G$mb{qr/$utf8regex/imsxo}>gc
    $_ =~ s<$mb{qr/before/imsxo}><after>egr

  supported encodings:
    UTF-8(RFC3629), UTF-8(RFC2279), WTF8, RFC3629.ja_JP, and WTF8.ja_JP

  supported operating systems:
    Apple Inc. OS X,
    Hewlett-Packard Development Company, L.P. HP-UX,
    International Business Machines Corporation AIX,
    Microsoft Corporation Windows,
    Oracle Corporation Solaris,
    and Other Systems

  supported perl versions:
    perl version 5.005_03 to newest perl

=head1 INSTALLATION BY MAKE-COMMAND

To install this software by make, type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 INSTALLATION WITHOUT MAKE-COMMAND (for DOS-like system)

To install this software without make, type the following:

   pmake.bat test
   pmake.bat install

=head1 DESCRIPTION

It may sound a little ambitious, but UTF8::R2 module is aiming to replace utf8 pragma.

Perl is said to have been able to handle Unicode since version 5.8.
However, unlike JPerl, "Easy jobs must be easy" has been lost.

This software has the following features

=over 2

=item * supports UTF-8 literals of Perl scripts

=item * supports UTF-8(RFC3629), UTF-8(RFC2279), WTF8, RFC3629.ja_JP, and WTF8.ja_JP

=item * does not use the UTF8 flag to avoid MOJIBAKE

=item * handles raw encoding to support GAIJI

=item * supports codepoint classes in regular expressions to work as UTF-8 codepoint

=item * does not change features of octet-oriented built-in functions

=item * You have using UTF8::R2::* subroutines if you want codepoint semantics

=item * UTF8::R2::lc(), UTF8::R2::lcfirst(), UTF8::R2::uc(), and UTF8::R2::ucfirst() convert US-ASCII only

=item * codepoint range by hyphen of UTF8::R2::tr() supports US-ASCII only

=back

=head1 UTF-8 like Encodings supported by this software

The encodings supported by this software and their range of octets are as follows.

  ------------------------------------------------------------------------------
  UTF-8 (RFC2279)
             1st       2nd       3rd       4th
             C2..DF    80..BF
             E0..EF    80..BF    80..BF
             F0..F4    80..BF    80..BF    80..BF
             00..7F
             https://www.ietf.org/rfc/rfc2279.txt
             * needs no multibyte anchoring
             * needs no escaping meta char of 2nd-4th octets
             * safe US-ASCII casefolding of 2nd-4th octet
             * allows encoding surrogate codepoints even if it is not pair
  ------------------------------------------------------------------------------
  UTF-8 (RFC3629)
             1st       2nd       3rd       4th
             C2..DF    80..BF
             E0..E0    A0..BF    80..BF
             E1..EC    80..BF    80..BF
             ED..ED    80..9F    80..BF
             EE..EF    80..BF    80..BF
             F0..F0    90..BF    80..BF    80..BF
             F1..F3    80..BF    80..BF    80..BF
             F4..F4    80..8F    80..BF    80..BF
             00..7F
             https://en.wikipedia.org/wiki/UTF-8
             * needs no multibyte anchoring
             * needs no escaping meta char of 2nd-4th octets
             * safe US-ASCII casefolding of 2nd-4th octet
             * enforces surrogate codepoints must be paired
  ------------------------------------------------------------------------------
  WTF-8
             1st       2nd       3rd       4th
             C2..DF    80..BF
             E0..E0    A0..BF    80..BF
             E1..EF    80..BF    80..BF
             F0..F0    90..BF    80..BF    80..BF
             F1..F3    80..BF    80..BF    80..BF
             F4..F4    80..8F    80..BF    80..BF
             00..7F
             http://simonsapin.github.io/wtf-8/
             * superset of UTF-8 that encodes surrogate codepoints if they are not in a pair
             * needs no multibyte anchoring
             * needs no escaping meta char of 2nd-4th octets
             * safe US-ASCII casefolding of 2nd-4th octet
  ------------------------------------------------------------------------------
  UTF-8 (RFC3629.ja_JP)
             1st       2nd       3rd       4th
             E1..EC    80..BF    80..BF
             C2..DF    80..BF
             EE..EF    80..BF    80..BF
             F0..F0    90..BF    80..BF    80..BF
             E0..E0    A0..BF    80..BF
             ED..ED    80..9F    80..BF
             F1..F3    80..BF    80..BF    80..BF
             F4..F4    80..8F    80..BF    80..BF
             00..7F
             https://en.wikipedia.org/wiki/UTF-8
             * needs no multibyte anchoring
             * needs no escaping meta char of 2nd-4th octets
             * safe US-ASCII casefolding of 2nd-4th octet
             * enforces surrogate codepoints must be paired
             * optimized for ja_JP
  ------------------------------------------------------------------------------
  WTF-8.ja_JP
             1st       2nd       3rd       4th
             E1..EF    80..BF    80..BF
             C2..DF    80..BF
             E0..E0    A0..BF    80..BF
             F0..F0    90..BF    80..BF    80..BF
             F1..F3    80..BF    80..BF    80..BF
             F4..F4    80..8F    80..BF    80..BF
             00..7F
             http://simonsapin.github.io/wtf-8/
             * superset of UTF-8 that encodes surrogate codepoints if they are not in a pair
             * needs no multibyte anchoring
             * needs no escaping meta char of 2nd-4th octets
             * safe US-ASCII casefolding of 2nd-4th octet
             * optimized for ja_JP
  ------------------------------------------------------------------------------

=head1 UTF-8 subroutines provided by this software

This software provides traditional feature "as was."
The new UTF-8 features are provided by subroutines with new names.
If you like utf8 pragma, UTF8::R2::* subroutines will help you.
On other hand, If you love JPerl, those subroutines will not help you very much.
Traditional functions of Perl are useful still now in octet-oriented semantics.

  elder <<<---                                   age                                   --->>> younger
  ---------------------------------------------------------------------------------------------------
  bare Perl4       JPerl4           use utf8;        UTF8::R2                mb.pm
  bare Perl5       JPerl5           pragma           module                  modulino
  ---------------------------------------------------------------------------------------------------
  chop             ---              ---              chop                    chop
  chr              chr              bytes::chr       chr                     chr
  getc             getc             ---              getc                    getc
  index            ---              bytes::index     index                   index
  lc               ---              ---              lc                      CORE::lc (acts as tr/\x41-\x5A/\x61-\x7A/)
  lcfirst          ---              ---              lcfirst                 CORE::lcfirst (acts as tr/\x41-\x5A/\x61-\x7A/)
  length           length           bytes::length    length                  length
  ord              ord              bytes::ord       ord                     ord
  reverse          reverse          ---              reverse                 reverse
  rindex           ---              bytes::rindex    rindex                  rindex
  substr           substr           bytes::substr    substr                  substr
  uc               ---              ---              uc                      CORE::uc (acts as tr/\x61-\x7A/\x41-\x5A/)
  ucfirst          ---              ---              ucfirst                 CORE::ucfirst (acts as tr/\x61-\x7A/\x41-\x5A/)
  ---              chop             chop             UTF8::R2::chop          mb::chop
  ---              ---              chr              UTF8::R2::chr           mb::chr
  ---              ---              getc             UTF8::R2::getc          mb::getc
  ---              index            ---              UTF8::R2::index_byte    mb::index_byte
  ---              ---              index            UTF8::R2::index         mb::index
  ---              lc               ---              lc                      lc (also mb::lc)
  ---              lcfirst          ---              lcfirst                 lcfirst (also mb::lcfirst)
  ---              ---              length           UTF8::R2::length        mb::length
  ---              ---              ord              UTF8::R2::ord           mb::ord
  ---              ---              reverse          UTF8::R2::reverse       mb::reverse
  ---              rindex           ---              UTF8::R2::rindex_byte   mb::rindex_byte
  ---              ---              rindex           UTF8::R2::rindex        mb::rindex
  ---              ---              substr           UTF8::R2::substr        mb::substr
  ---              uc               ---              uc                      uc (also mb::uc)
  ---              ucfirst          ---              ucfirst                 ucfirst (also mb::ucfirst)
  ---              ---              lc               (mb::Casing::lc)        (mb::Casing::lc)
  ---              ---              lcfirst          (mb::Casing::lcfirst)   (mb::Casing::lcfirst)
  ---              ---              uc               (mb::Casing::uc)        (mb::Casing::uc)
  ---              ---              ucfirst          (mb::Casing::ucfirst)   (mb::Casing::ucfirst)
  ---------------------------------------------------------------------------------------------------
  do 'file'        ---              do 'file'        do 'file'               do 'file'
  eval 'string'    ---              eval 'string'    eval 'string'           eval 'string'
  require 'file'   ---              require 'file'   require 'file'          require 'file'
  use Module       ---              use Module       use Module              use Module
  no Module        ---              no Module        no Module               no Module
  ---              do 'file'        do 'file'        do 'file'               mb::do 'file'
  ---              eval 'string'    eval 'string'    eval 'string'           mb::eval 'string'
  ---              require 'file'   require 'file'   require 'file'          mb::require 'file'
  ---              use Module       use Module       use Module              mb::use Module
  ---              no Module        no Module        no Module               mb::no Module
  $^X              ---              $^X              $^X                     $^X
  ---              $^X              $^X              $^X                     $mb::PERL
  $0               $0               $0               $0                      $mb::ORIG_PROGRAM_NAME
  ---              ---              ---              ---                     $0
  ---------------------------------------------------------------------------------------------------

index brothers

  ------------------------------------------------------------------------------------------
  functions or subs       works as        returns as      considered
  ------------------------------------------------------------------------------------------
  index                   octet           octet           useful, bare Perl like
  rindex                  octet           octet           useful, bare Perl like
  UTF8::R2::index         codepoint       codepoint       not so useful, utf8 pragma like
  UTF8::R2::rindex        codepoint       codepoint       not so useful, utf8 pragma like
  UTF8::R2::index_byte    codepoint       octet           useful, JPerl like
  UTF8::R2::rindex_byte   codepoint       octet           useful, JPerl like
  ------------------------------------------------------------------------------------------

The most useful of the above are UTF8::R2::index_byte() and UTF8::R2::rindex_byte(), but it's more convenient to use regular expressions than those.
So you can forget about these subroutines.

=head1 mb.pm Modulino Compatible Routines, and Variables

The following subroutines and variables exist for compatibility with the mb.pm module.

  -------------------------------------------------------------------
  mb.pm Modulino            Compatible Routines, and Variables
  -------------------------------------------------------------------
  mb::do                    UTF8::R2::do($_)
  mb::dosglob($_)           UTF8::R2::dosglob($_)
  mb::eval                  UTF8::R2::eval($_)
  mb::index_byte            UTF8::R2::index_byte($_, 'ABC', 5)
  mb::require               UTF8::R2::require($_)
  mb::rindex_byte           UTF8::R2::rindex_byte($_, 'ABC', 5)
  $mb::PERL                 $UTF8::R2::PERL
  $mb::ORIG_PROGRAM_NAME    $UTF8::R2::ORIG_PROGRAM_NAME
  -------------------------------------------------------------------

=head1 Codepoint-Semantics Regular Expression

This software adds the ability to handle UTF-8 code points to bare Perl; it does not provide the ability to handle characters and graphene.
Because this module override nothing, the functions of bare Perl provide octet semantics continue.
UTF-8 codepoint semantics of regular expression is provided by new sintax.
"tr///" has nothing to do with regular expressions, but we listed here for convenience.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Octet-semantics         UTF-8 Codepoint-semantics
  by traditional sintax   by new sintax                              Note and Limitations
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
  s/before/after/imsxoegr s<@{[UTF8::R2::qr(qr/before/imsxo)]}><after>egr
                            or
                          use UTF8::R2 qw(%mb);
                          s<$mb{qr/before/imsxo}><after>egr
  ------------------------------------------------------------------------------------------------------------------------------------------
  split//                 UTF8::R2::split(qr/$utf8regex/imsxo, $_, 3)  *CAUTION* UTF8::R2::split(/re/,$_,3) means UTF8::R2::split($_ =~ /re/,$_,3)
  ------------------------------------------------------------------------------------------------------------------------------------------
  tr/// or y///           UTF8::R2::tr($_, 'A-C', 'X-Z', 'cdsr')     range of codepoint by hyphen supports ASCII only
  ------------------------------------------------------------------------------------------------------------------------------------------

=head1 Porting from script in bare Perl4, and bare Perl5

=head2 If you want to write US-ASCII scripts from now on, or port existing US-ASCII scripts to UTF8::R2 environment

Write scripts the usual way.
Running an US-ASCII script using UTF8::R2 allows you to treat UTF-8 codepoints as I/O data.

=head1 Porting from script in JPerl4, and JPerl5

=head2 If you want to port existing JPerl scripts to UTF8::R2 environment

There are only a few places that need to be rewritten.
If you write the functionality of "index()" and "rindex()" in regular expressions, the only difference left is "chop()".
If you want "chop()" that like JPerl, you need to write "UTF8::R2::chop()" when UTF8::R2 environment.

  -----------------------------------------------------------------
  original script in        script with
  JPerl4, JPerl5            UTF8::R2 module
  -----------------------------------------------------------------
  chop                      UTF8::R2::chop
  index                     UTF8::R2::index_byte
  rindex                    UTF8::R2::rindex_byte
  -----------------------------------------------------------------

However substantially is ...

  -----------------------------------------------------------------
  original script in        script with
  JPerl4, JPerl5            UTF8::R2 module
  -----------------------------------------------------------------
  chop                      95% to chomp, 4% to UTF8::R2::chop, 1% to chop
  index                     (already written in regular expression)
  rindex                    (already written in regular expression)
  -----------------------------------------------------------------

Substantially put, JPerl users can write programs the same way they used to.

=head1 Porting from script with utf8 pragma

=head2 If you want to port existing scripts that has utf8 pragma to UTF8::R2 environment

Like traditional style, Perl's built-in functions without package names provide octet-oriented functionality.
Thus, "length()" and "substr()" work on an octet basis, universally.
When you need multibyte functionally, you need to use subroutines in the "UTF8::R2" package, on every time.

  -----------------------------------------------------------------
  original script with      script with
  utf8 pragma               UTF8::R2 module
  -----------------------------------------------------------------
  chop                      UTF8::R2::chop
  chr                       UTF8::R2::chr
  getc                      UTF8::R2::getc
  index                     UTF8::R2::index
  lc                        ---
  lcfirst                   ---
  length                    UTF8::R2::length
  ord                       UTF8::R2::ord
  reverse                   UTF8::R2::reverse
  rindex                    UTF8::R2::rindex
  substr                    UTF8::R2::substr
  uc                        ---
  ucfirst                   ---
  -----------------------------------------------------------------

=head1 DEPENDENCIES

This UTF8::R2 module requires perl5.00503 or later to use. Also requires 'strict' module.
It requires the 'warnings' module, too if perl 5.6 or later.

=head1 Our Goals (and UTF8 Flag Considered Harmful)

P.401 See chapter 15: Unicode
of ISBN 0-596-00027-8 Programming Perl Third Edition.

Before the introduction of Unicode support in perl, The eq operator just compared the byte-strings represented by two scalars.
Beginning with perl 5.8, eq compares two byte-strings with simultaneous consideration of the UTF8 flag.

-- we have been taught so for a long time.

Perl is a powerful language for everyone, but UTF8 flag is a barrier for common beginners.
Calling Encode::encode() and Encode::decode() in application program is not good way.
Making one script for information processing, and other one for encoding conversion are better.

"That's a small bit for someone, but the giant  bug on the Perl for mankind."

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

  Confusion of Perl string model is made from double meanings of "Binary string."
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

Perl 5.8's string model will not be accepted by common people.

Information processing model of UNIX/C-ism, 
Information processing model of perl3 or later, and
Information processing model of this software.

    +--------------------------------------------+
    |    Text string as Digital octet string     |
    |    Digital octet string as Text string     |
    +--------------------------------------------+
    |       Not UTF8 Flagged, No MOJIBAKE        |
    +--------------------------------------------+

In UNIX Everything is a File

=over 2

=item * In UNIX everything is a stream of bytes

=item * In UNIX the filesystem is used as a universal name space

=back

Native Encoding Scripting is ...

=over 2

=item * native encoding of file contents

=item * native encoding of file name on filesystem

=item * native encoding of command line

=item * native encoding of environment variable

=item * native encoding of API

=item * native encoding of network packet

=item * native encoding of database

=back

Ideally, We'd like to achieve these five Goals:

=over 2

=item * Goal #1:

Old byte-oriented programs should not spontaneously break on the old byte-oriented data they used to work on.

This software attempts to achieve this goal by embedded functions work as traditional and stably.

=item * Goal #2:

Old byte-oriented programs should magically start working on the new character-oriented data when appropriate.

This software is not a magician, so cannot see your mind and run it.

You must decide and write octet semantics or codepoint semantics yourself in case by case.

figure of Goal #1 and Goal #2.

                               Goal #1 Goal #2
                        (a)     (b)     (c)     (d)     (e)
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New codepoint-oriented

There is a combination from (a) to (e) in data, script, and interpreter of old and new. Let's add JPerl, utf8 pragma, and this software.

                        (a)     (b)     (c)     (d)     (e)
                                      JPerl
                                      UTF8::R2         utf8
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New codepoint-oriented

The reason why JPerl is very excellent is that it is at the position of (c).
That is, it is almost not necessary to write a special code to process new codepoint oriented script.

=item * Goal #3:

Programs should run just as fast in the new character-oriented mode as in the old byte-oriented mode.

It is impossible. Because the following time is necessary.

(1) Time of processing class of codepoint in regular expression

=item * Goal #4:

Perl should remain one language, rather than forking into a byte-oriented Perl and a character-oriented Perl.

JPerl remains one Perl "language" by forking to two "interpreters."
However, the Perl core team did not desire fork of the "interpreter."
As a result, Perl "language" forked contrary to goal #4.

A codepoint oriented perl is not necessary to make it specially, because a byte-oriented perl can already treat the binary data.
This software is only Perl module of byte-oriented Perl.

And you will get support from the Perl community, when you solve the problem by the Perl script.

UTF8::R2 module remains one "language" and one "interpreter."

=item * Goal #5:

UTF8::R2 users will be able to maintain UTF8::R2 by Perl.

May the UTF8::R2 be with you, always.

=back

Back when Programming Perl, 3rd edition was written, UTF8 flag was not born and Perl is designed to make the easy jobs do easy.
This software provides programming environment like at that time.

=head1 Perl's Motto

Some computer scientists (the reductionists, in particular) would like to deny it, but people have funny-shaped minds.
Mental geography is not linear, and cannot be mapped onto a flat surface without severe distortion.
But for the last score years or so, computer reductionists have been first bowing down at the Temple of Orthogonality, then rising up to preach their ideas of ascetic rectitude to any who would listen.

Their fervent but misguided desire was simply to squash your mind to fit their mindset, to smush your patterns of thought into some sort of Hyperdimensional Flatland.
It's a joyless existence, being smushed.

--- Learning Perl on Win32 Systems

If you think this is a big headache, you're right.
No one likes this situation, but Perl does the best it can with the input and encodings it has to deal with.
If only we could reset history and not make so many mistakes next time.

--- Learning Perl 6th Edition

The most important thing for most people to know about handling Unicode data in Perl, however, is that if you don't ever use any Unicode data -- if none of your files are marked as UTF-8 and you don't use UTF-8 locales
-- then you can happily pretend that you're back in Perl 5.005_03 land;
the Unicode features will in no way interfere with your code unless you're explicitly using them.
Sometimes the twin goals of embracing Unicode but not disturbing old-style byte-oriented scripts has led to compromise and confusion, but it's the Perl way to silently do the right thing, which is what Perl ends up doing.

--- Advanced Perl Programming, 2nd Edition

However, the ability to have any character in a string means you can create, scan, and manipulate raw binary data as string
-- something with which many other utilities would have great difficulty.

--- Learning Perl 8th Edition

=head1 Combinations of UTF8::R2 Module and Other Modules

The following is a description of all the situations in this software is used in Japan.

  +-------------+--------------+---------------------------------------------------------------------+
  | OS encoding | I/O encoding |                           script encoding                           |
  |             |              |----------------------------------+----------------------------------+
  |             |              |              Sjis                |              UTF-8               |
  +-------------+--------------+----------------------------------+----------------------------------+
  |             |              |  > perl mb.pm script.pl          |                                  |
  |             |    Sjis      |                                  |                                  |
  |             |              |                                  |                                  |
  |    Sjis     +--------------+----------------------------------+----------------------------------+
  |             |              |                                  | use UTF8::R2;                    |
  |             |    UTF-8     |                                  |                                  |
  |             |              |                                  | use mb::Encode;  # file-path     |
  +-------------+--------------+----------------------------------+----------------------------------+
  |             |              |  $ perl mb.pm -e sjis script.pl  |                                  |
  |             |    Sjis      |                                  |                                  |
  |             |              |  use mb::Encode; # file-path     |                                  |
  |    UTF-8    +--------------+----------------------------------+----------------------------------+
  |             |              |                                  | use UTF8::R2;                    |
  |             |    UTF-8     |                                  |                                  |
  |             |              |                                  |                                  |
  +-------------+--------------+----------------------------------+----------------------------------+

Description of combinations

  ----------------------------------------------------------------------
  encoding
  O-I-S     description
  ----------------------------------------------------------------------
  S-S-S     Best choice when I/O is Sjis  encoding
  S-S-U     
  S-U-S     
  S-U-U     Better choice when I/O is UTF-8 encoding, since not so slow
  U-S-S     Better choice when I/O is Sjis  encoding, since not so slow
  U-S-U     
  U-U-S     
  U-U-U     Best choice when I/O is UTF-8 encoding
  ----------------------------------------------------------------------

Using Encode::decode and Encode::encode for file contents, *you* and operators lose two precious things.
One is the time.
Other one is the original data.
Generally speaking, data conversion lose information -- unless perfectly convert one to one.
Moreover, if you have made script's bug, you will know its bug on too late.
If you convert encoding of file path -- not file contents, you will know its bug on the time when you test it.

=head1 Using mb.pm Modulino vs. Using UTF8::R2 Module

CPAN shows us there are mb.pm modulino and UTF8::R2 module.
mb.pm modulino is a source code filter for MBCS encoding, and UTF8::R2 module is a utility for UTF-8 support.
We can use each advantages using following hints.

=head2 Advantages Of mb.pm Modulino

=over 2

=item * supports many MBCS encodings, Big5, Big5-HKSCS, EUC-JP, GB18030, GBK, Sjis(also CP932), UHC, UTF-8, and WTF-8

=item * JPerl-like syntax that supports "easy jobs must be easy"

=item * regexp ("m//", "qr//", and "s///") works as codepoint

=item * "split()" works as codepoint

=item * "tr///" works as codepoint

=back

=head2 Disadvantages Of mb.pm Modulino

=over 2

=item * have to type "perl mb.pm your_script.pl ..." on command line everytime

=item * have obtrusive files(your_script.oo.pl)

=back

=head2 Advantages Of UTF8::R2 Module

=over 2

=item * type only "perl your_script.pl ..." on command line

=item * no obtrusive files(your_script.oo.pl)

=back

=head2 Disadvantages Of UTF8::R2 Module

=over 2

=item * supports only UTF-8 encoding

=item * have to write "$mb{qr/regexp/imsxo}" to do "m/regexp/imsxo" that works as codepoint

=item * have to write "m<\G$mb{qr/regexp/imsxo}>gc" to do "m/regexp/imsxogc" that works as codepoint

=item * have to write "s<$mb{qr/before/imsxo}><after>egr" to do "s/before/after/imsxoegr" that works as codepoint

=item * have to write "UTF8::R2::split(qr/regexp/, $_, 3)" to do "split(/regexp/, $_, 3)" that works as codepoint

=item * have to write "UTF8::R2::tr($_, 'A-C', 'X-Z', 'cdsr')" to do "$_ =~ tr/A-C/X-Z/cdsr" that works as codepoint

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
See the LICENSE file for details.

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

 perlunicode, perlunifaq, perluniintro, perlunitut, utf8, bytes,

 PERL PUROGURAMINGU
 Larry Wall, Randal L.Schwartz, Yoshiyuki Kondo
 December 1997
 ISBN 4-89052-384-7
 http://www.context.co.jp/~cond/books/old-books.html

 Programming Perl, Second Edition
 By Larry Wall, Tom Christiansen, Randal L. Schwartz
 October 1996
 Pages: 670
 ISBN 10: 1-56592-149-6 | ISBN 13: 9781565921498
 http://shop.oreilly.com/product/9781565921498.do

 Programming Perl, Third Edition
 By Larry Wall, Tom Christiansen, Jon Orwant
 Third Edition  July 2000
 Pages: 1104
 ISBN 10: 0-596-00027-8 | ISBN 13: 9780596000271
 http://shop.oreilly.com/product/9780596000271.do

 The Perl Language Reference Manual (for Perl version 5.12.1)
 by Larry Wall and others
 Paperback (6"x9"), 724 pages
 Retail Price: $39.95 (pound 29.95 in UK)
 ISBN-13: 978-1-906966-02-7
 https://dl.acm.org/doi/book/10.5555/1893028

 Perl Pocket Reference, 5th Edition
 By Johan Vromans
 Publisher: O'Reilly Media
 Released: July 2011
 Pages: 102
 http://shop.oreilly.com/product/0636920018476.do

 Programming Perl, 4th Edition
 By: Tom Christiansen, brian d foy, Larry Wall, Jon Orwant
 Publisher: O'Reilly Media
 Formats: Print, Ebook, Safari Books Online
 Released: March 2012
 Pages: 1130
 Print ISBN: 978-0-596-00492-7 | ISBN 10: 0-596-00492-3
 Ebook ISBN: 978-1-4493-9890-3 | ISBN 10: 1-4493-9890-1
 http://shop.oreilly.com/product/9780596004927.do

 Perl Cookbook
 By Tom Christiansen, Nathan Torkington
 August 1998
 Pages: 800
 ISBN 10: 1-56592-243-3 | ISBN 13: 978-1-56592-243-3
 http://shop.oreilly.com/product/9781565922433.do

 Perl Cookbook, Second Edition
 By Tom Christiansen, Nathan Torkington
 Second Edition  August 2003
 Pages: 964
 ISBN 10: 0-596-00313-7 | ISBN 13: 9780596003135
 http://shop.oreilly.com/product/9780596003135.do

 Perl in a Nutshell, Second Edition
 By Stephen Spainhour, Ellen Siever, Nathan Patwardhan
 Second Edition  June 2002
 Pages: 760
 Series: In a Nutshell
 ISBN 10: 0-596-00241-6 | ISBN 13: 9780596002411
 http://shop.oreilly.com/product/9780596002411.do

 Learning Perl on Win32 Systems
 By Randal L. Schwartz, Erik Olson, Tom Christiansen
 August 1997
 Pages: 306
 ISBN 10: 1-56592-324-3 | ISBN 13: 9781565923249
 http://shop.oreilly.com/product/9781565923249.do

 Learning Perl, Fifth Edition
 By Randal L. Schwartz, Tom Phoenix, brian d foy
 June 2008
 Pages: 352
 Print ISBN:978-0-596-52010-6 | ISBN 10: 0-596-52010-7
 Ebook ISBN:978-0-596-10316-3 | ISBN 10: 0-596-10316-6
 http://shop.oreilly.com/product/9780596520113.do

 Learning Perl, 6th Edition
 By Randal L. Schwartz, brian d foy, Tom Phoenix
 June 2011
 Pages: 390
 ISBN-10: 1449303587 | ISBN-13: 978-1449303587
 http://shop.oreilly.com/product/0636920018452.do

 Learning Perl, 8th Edition
 by Randal L. Schwartz, brian d foy, Tom Phoenix
 Released August 2021
 Publisher(s): O'Reilly Media, Inc.
 ISBN: 9781492094951
 https://www.oreilly.com/library/view/learning-perl-8th/9781492094944/

 Advanced Perl Programming, 2nd Edition
 By Simon Cozens
 June 2005
 Pages: 300
 ISBN-10: 0-596-00456-7 | ISBN-13: 978-0-596-00456-9
 http://shop.oreilly.com/product/9780596004569.do

 Perl RESOURCE KIT UNIX EDITION
 Futato, Irving, Jepson, Patwardhan, Siever
 ISBN 10: 1-56592-370-7
 http://shop.oreilly.com/product/9781565923706.do

 Perl Resource Kit -- Win32 Edition
 Erik Olson, Brian Jepson, David Futato, Dick Hardt
 ISBN 10:1-56592-409-6
 http://shop.oreilly.com/product/9781565924093.do

 MODAN Perl NYUMON
 By Daisuke Maki
 2009/2/10
 Pages: 344
 ISBN 10: 4798119172 | ISBN 13: 978-4798119175
 https://www.seshop.com/product/detail/10250

 Understanding Japanese Information Processing
 By Ken Lunde
 January 1900
 Pages: 470
 ISBN 10: 1-56592-043-0 | ISBN 13: 9781565920439
 http://shop.oreilly.com/product/9781565920439.do

 CJKV Information Processing Chinese, Japanese, Korean & Vietnamese Computing
 By Ken Lunde
 O'Reilly Media
 Print: January 1999
 Ebook: June 2009
 Pages: 1128
 Print ISBN:978-1-56592-224-2 | ISBN 10:1-56592-224-7
 Ebook ISBN:978-0-596-55969-4 | ISBN 10:0-596-55969-0
 http://shop.oreilly.com/product/9781565922242.do

 CJKV Information Processing, 2nd Edition
 By Ken Lunde
 O'Reilly Media
 Print: December 2008
 Ebook: June 2009
 Pages: 912
 Print ISBN: 978-0-596-51447-1 | ISBN 10:0-596-51447-6
 Ebook ISBN: 978-0-596-15782-1 | ISBN 10:0-596-15782-7
 http://shop.oreilly.com/product/9780596514471.do

 DB2 GIJUTSU ZENSHO
 By BM Japan Systems Engineering Co.,Ltd. and IBM Japan, Ltd.
 2004/05
 Pages: 887
 ISBN-10: 4756144659 | ISBN-13: 978-4756144652
 https://iss.ndl.go.jp/books/R100000002-I000007400836-00

 Mastering Regular Expressions, Second Edition
 By Jeffrey E. F. Friedl
 Second Edition  July 2002
 Pages: 484
 ISBN 10: 0-596-00289-0 | ISBN 13: 9780596002893
 http://shop.oreilly.com/product/9780596002893.do

 Mastering Regular Expressions, Third Edition
 By Jeffrey E. F. Friedl
 Third Edition  August 2006
 Pages: 542
 ISBN 10: 0-596-52812-4 | ISBN 13:9780596528126
 http://shop.oreilly.com/product/9780596528126.do

 Regular Expressions Cookbook
 By Jan Goyvaerts, Steven Levithan
 May 2009
 Pages: 512
 ISBN 10:0-596-52068-9 | ISBN 13: 978-0-596-52068-7
 http://shop.oreilly.com/product/9780596520694.do

 Regular Expressions Cookbook, 2nd Edition
 By Steven Levithan, Jan Goyvaerts
 Released August 2012
 Pages: 612
 ISBN: 9781449327453
 https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/

 JIS KANJI JITEN
 By Kouji Shibano
 Pages: 1456
 ISBN 4-542-20129-5
 https://www.e-hon.ne.jp/bec/SA/Detail?refISBN=4542201295

 UNIX MAGAZINE
 1993 Aug
 Pages: 172
 T1008901080816 ZASSHI 08901-8

 Shell Script Magazine vol.41
 2016 September
 Pages: 64
 https://shell-mag.com/

 LINUX NIHONGO KANKYO
 By YAMAGATA Hiroo, Stephen J. Turnbull, Craig Oda, Robert J. Bickel
 June, 2000
 Pages: 376
 ISBN 4-87311-016-5
 https://www.oreilly.co.jp/books/4873110165/

 Windows NT Shell Scripting
 By Timothy Hill
 April 27, 1998
 Pages: 400
 ISBN 10: 1578700477 | ISBN 13: 9781578700479
 https://www.abebooks.com/9781578700479/Windows-NT-Scripting-Circle-Hill-1578700477/plp

 Windows(R) Command-Line Administrators Pocket Consultant, 2nd Edition
 By William R. Stanek
 February 2009
 Pages: 594
 ISBN 10: 0-7356-2262-0 | ISBN 13: 978-0-7356-2262-3
 https://www.abebooks.com/9780735622623/Windows-Command-Line-Administrators-Pocket-Consultant-0735622620/plp

 CPAN Directory INABA Hitoshi
 https://metacpan.org/author/INA
 http://backpan.cpantesters.org/authors/id/I/IN/INA/
 https://metacpan.org/release/Jacode4e-RoundTrip
 https://metacpan.org/release/Jacode4e
 https://metacpan.org/release/Jacode

 Recent Perl packages by "INABA Hitoshi"
 http://code.activestate.com/ppm/author:INABA-Hitoshi/

 Tokyo-pm archive
 https://mail.pm.org/pipermail/tokyo-pm/
 https://mail.pm.org/pipermail/tokyo-pm/1999-September/001844.html
 https://mail.pm.org/pipermail/tokyo-pm/1999-September/001854.html

 Error: Runtime exception on jperl 5.005_03
 http://www.rakunet.org/tsnet/TSperl/12/374.html
 http://www.rakunet.org/tsnet/TSperl/12/375.html
 http://www.rakunet.org/tsnet/TSperl/12/376.html
 http://www.rakunet.org/tsnet/TSperl/12/377.html
 http://www.rakunet.org/tsnet/TSperl/12/378.html
 http://www.rakunet.org/tsnet/TSperl/12/379.html
 http://www.rakunet.org/tsnet/TSperl/12/380.html
 http://www.rakunet.org/tsnet/TSperl/12/382.html

 TSNETWiki
 https://rakunet.org/wik/index.php
 https://rakunet.org/wik/index.php?TSperl
 https://rakunet.org/wik/index.php?Perl

 ruby-list
 http://blade.nagaokaut.ac.jp/ruby/ruby-list/index.shtml
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/2440
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/2446
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/2569
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/9427
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/9431
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/10500
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/10501
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/10502
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/12385
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/12392
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/12393
 http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-list/19156

 Announcing Perl 7
 https://www.perl.com/article/announcing-perl-7/

 Perl 7 is coming
 https://www.effectiveperlprogramming.com/2020/06/perl-7-is-coming/

 A vision for Perl 7 and beyond
 https://xdg.me/a-vision-for-perl-7-and-beyond/

 On Perl 7 and the Perl Steering Committee
 https://lwn.net/Articles/828384/
  
 Perl7 and the future of Perl
 http://www.softpanorama.org/Scripting/Language_wars/perl7_and_the_future_of_perl.shtml

 Perl 7: A Risk-Benefit Analysis
 http://blogs.perl.org/users/grinnz/2020/07/perl-7-a-risk-benefit-analysis.html

 Perl 7 By Default
 http://blogs.perl.org/users/grinnz/2020/08/perl-7-by-default.html

 Perl 7: A Modest Proposal
 https://dev.to/grinnz/perl-7-a-modest-proposal-434m

 Perl 7 FAQ
 https://gist.github.com/Grinnz/be5db6b1d54b22d8e21c975d68d7a54f

 Perl 7, not quite getting better yet
 http://blogs.perl.org/users/leon_timmermans/2020/06/not-quite-getting-better-yet.html

 Re: Announcing Perl 7
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/06/msg257566.html
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/06/msg257568.html
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/06/msg257572.html

 Changed defaults - Are they best for newbies?
 https://www.nntp.perl.org/group/perl.perl5.porters/2020/08/msg258221.html

 A vision for Perl 7 and beyond
 https://web.archive.org/web/20200927044106/https://xdg.me/archive/2020-a-vision-for-perl-7-and-beyond/

 Sys::Binmode - A fix for Perl's system call character encoding
 https://metacpan.org/pod/Sys::Binmode

 File::Glob::Windows - glob routine for Windows environment.
 https://metacpan.org/pod/File::Glob::Windows

 winja - dirty patch for handling pathname on MSWin32::Ja_JP.cp932
 https://metacpan.org/release/winja

 Win32::Symlink - Symlink support on Windows
 https://metacpan.org/pod/Win32::Symlink

 Win32::NTFS::Symlink - Support for NTFS symlinks and junctions on Microsoft Windows
 https://metacpan.org/pod/Win32::NTFS::Symlink

 Win32::Symlinks - A maintained, working implementation of Perl symlink built in features for Windows.
 https://metacpan.org/pod/Win32::Symlinks

 TANABATA - The Star Festival - common legend of east asia
 https://ja.wikipedia.org/wiki/%E4%B8%83%E5%A4%95
 https://ko.wikipedia.org/wiki/%EC%B9%A0%EC%84%9D
 https://zh-classical.wikipedia.org/wiki/%E4%B8%83%E5%A4%95
 https://zh-yue.wikipedia.org/wiki/%E4%B8%83%E5%A7%90%E8%AA%95
 https://zh.wikipedia.org/wiki/%E4%B8%83%E5%A4%95

=head1 ACKNOWLEDGEMENTS

This software was made referring to software and the document that the
following hackers or persons had made. 
I am thankful to all persons.

 Larry Wall, Perl
 http://www.perl.org/

 Jesse Vincent, Compatibility is a virtue
 https://www.nntp.perl.org/group/perl.perl5.porters/2010/05/msg159825.html

 Kazumasa Utashiro, jcode.pl: Perl library for Japanese character code conversion, Kazumasa Utashiro
 https://metacpan.org/author/UTASHIRO
 ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/
 http://web.archive.org/web/20090608090304/http://srekcah.org/jcode/
 ftp://ftp.oreilly.co.jp/pcjp98/utashiro/
 http://mail.pm.org/pipermail/tokyo-pm/2002-March/001319.html
 https://twitter.com/uta46/status/11578906320

 Jeffrey E. F. Friedl, Mastering Regular Expressions
 http://regex.info/

 SADAHIRO Tomoyuki, Handling of Shift-JIS text correctly using bare Perl
 http://nomenclator.la.coocan.jp/perl/shiftjis.htm
 https://metacpan.org/author/SADAHIRO

 Yukihiro "Matz" Matsumoto, YAPC::Asia2006 Ruby on Perl(s)
 https://archive.org/details/YAPCAsia2006TokyoRubyonPerls

 jscripter, For jperl users
 http://text.world.coocan.jp/jperl.html

 Bruce., Unicode in Perl
 http://www.rakunet.org/tsnet/TSabc/18/546.html

 Hiroaki Izumi, Cannot use Perl5.8/5.10 on Windows ?
 https://sites.google.com/site/hiroa63iz/perlwin

 Yuki Kimoto, Is it true that cannot use Perl5.8/5.10 on Windows ?
 https://philosophy.perlzemi.com/blog/20200122080040.html

 chaichanPaPa, Matching Shift_JIS file name
 http://chaipa.hateblo.jp/entry/20080802/1217660826

 SUZUKI Norio, Jperl
 http://www.dennougedougakkai-ndd.org/alte/3tte/jperl-5.005_03@ap522/homepage2.nifty.com..kipp..perl..jperl..index.html

 WATANABE Hirofumi, Jperl
 https://www.cpan.org/src/5.0/jperl/
 https://metacpan.org/author/WATANABE
 ftp://ftp.oreilly.co.jp/pcjp98/watanabe/jperlconf.ppt

 Chuck Houpt, Michiko Nozu, MacJPerl
 https://habilis.net/macjperl/index.j.html

 Kenichi Ishigaki, 31st about encoding; To JPerl users as old men
 https://gihyo.jp/dev/serial/01/modern-perl/0031

 Fuji, Goro (gfx), Perl Hackers Hub No.16
 http://gihyo.jp/dev/serial/01/perl-hackers-hub/001602

 Dan Kogai, Encode module
 https://metacpan.org/release/Encode
 https://archive.org/details/YAPCAsia2006TokyoPerl58andUnicodeMythsFactsandChanges
 http://yapc.g.hatena.ne.jp/jkondo/

 Takahashi Masatuyo, JPerl Wiki
 https://jperl.fandom.com/ja/wiki/JPerl_Wiki

 Juerd, Perl Unicode Advice
 https://juerd.nl/site.plp/perluniadvice

 daily dayflower, 2008-06-25 perluniadvice
 https://dayflower.hatenablog.com/entry/20080625/1214374293

 Unicode issues in Perl
 https://www.i-programmer.info/programming/other-languages/1973-unicode-issues-in-perl.html

 numa's Diary: CSI and UCS Normalization
 https://srad.jp/~numa/journal/580177/

 Unicode Processing on Windows with Perl
 http://blog.livedoor.jp/numa2666/archives/52344850.html
 http://blog.livedoor.jp/numa2666/archives/52344851.html
 http://blog.livedoor.jp/numa2666/archives/52344852.html
 http://blog.livedoor.jp/numa2666/archives/52344853.html
 http://blog.livedoor.jp/numa2666/archives/52344854.html
 http://blog.livedoor.jp/numa2666/archives/52344855.html
 http://blog.livedoor.jp/numa2666/archives/52344856.html

 Kaoru Maeda, Perl's history Perl 1,2,3,4
 https://www.slideshare.net/KaoruMaeda/perl-perl-1234

 nurse, What is "string"
 https://naruse.hateblo.jp/entries/2014/11/07#1415355181

 NISHIO Hirokazu, What's meant "string as a sequence of characters"?
 https://nishiohirokazu.hatenadiary.org/entry/20141107/1415286729

 Rick Yamashita, Shift_JIS
 https://shino.tumblr.com/post/116166805/%E5%B1%B1%E4%B8%8B%E8%89%AF%E8%94%B5%E3%81%A8%E7%94%B3%E3%81%97%E3%81%BE%E3%81%99-%E7%A7%81%E3%81%AF1981%E5%B9%B4%E5%BD%93%E6%99%82us%E3%81%AE%E3%83%9E%E3%82%A4%E3%82%AF%E3%83%AD%E3%82%BD%E3%83%95%E3%83%88%E3%81%A7%E3%82%B7%E3%83%95%E3%83%88jis%E3%81%AE%E3%83%87%E3%82%B6%E3%82%A4%E3%83%B3%E3%82%92%E6%8B%85%E5%BD%93
 http://www.wdic.org/w/WDIC/%E3%82%B7%E3%83%95%E3%83%88JIS

 nurse, History of Japanese EUC 22:00
 https://naruse.hateblo.jp/entries/2009/03/08

 Mike Whitaker, Perl And Unicode
 https://www.slideshare.net/Penfold/perl-and-unicode

 Ricardo Signes, Perl 5.14 for Pragmatists
 https://www.slideshare.net/rjbs/perl-514-8809465

 Ricardo Signes, What's New in Perl? v5.10 - v5.16 #'
 https://www.slideshare.net/rjbs/whats-new-in-perl-v510-v516

 YAP(achimon)C::Asia Hachioji 2016 mid in Shinagawa
 Kenichi Ishigaki (@charsbar) July 3, 2016 YAP(achimon)C::Asia Hachioji 2016mid
 https://www.slideshare.net/charsbar/cpan-63708689

 Causes and countermeasures for garbled Japanese characters in perl
 https://prozorec.hatenablog.com/entry/2018/03/19/080000

 Perl regular expression bug?
 http://moriyoshi.hatenablog.com/entry/20090315/1237103809
 http://moriyoshi.hatenablog.com/entry/20090320/1237562075

 Impressions of talking of Larry Wall at LL Future
 https://hnw.hatenablog.com/entry/20080903

 About Windows and Japanese text
 https://blogs.windows.com/japan/2020/02/20/about-windows-and-japanese-text/

 About Windows diagnostic data
 https://blogs.windows.com/japan/2019/12/05/about-windows-diagnostic-data/

=cut
