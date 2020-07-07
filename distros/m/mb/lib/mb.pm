package mb;
######################################################################
#
# mb - run Perl script written in MBCS
#
# https://metacpan.org/release/mb
#
# Copyright (c) 2020 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.01';
$VERSION = $VERSION;

# internal use
$mb::last_s_passed = 0; # last s/// status (1 if s/// passed)

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 } use warnings; local $^W=1;
use Carp ();
use Symbol ();

# set OSNAME
my $OSNAME = $^O;

# encoding name of MBCS script
my $script_encoding = undef;

# over US-ASCII
${mb::over_ascii} = undef;

# supports qr/./ in MBCS script
${mb::x} = undef;

# supports [\b] \d \h \s \v \w in MBCS script
${mb::bare_backspace} = '\x08';
${mb::bare_d} = '0123456789';
${mb::bare_h} = '\x09\x20';
${mb::bare_s} = '\t\n\f\r\x20';
${mb::bare_v} = '\x0A\x0B\x0C\x0D';
${mb::bare_w} = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_';

# as many escapes as possible to avoid perl's feature
my $escapee_in_qq_like = join('', map {"\\$_"} grep( ! /[A-Za-z0-9_]/, map { CORE::chr } 0x21..0x7E));

# as less escapes as possible to avoid over-escaping
my $escapee_in_q__like = '\\' . "\x5C";

# check running perl interpreter
if ($^X =~ /jperl/i) {
    die "script '@{[__FILE__]}' can run on only perl, not JPerl\n";
}

# prototypes
sub main ();
sub detect_system_encoding ();
sub parse (;$);
sub parse_expr ();
sub parse_expr_balanced ($);
sub parse_heredocument_as_q_endswith ($);
sub parse_heredocument_as_qq_endswith ($);
sub parse_q__like_balanced ($);
sub parse_q__like_endswith ($);
sub parse_q__like ($);
sub parse_qq_like_balanced ($);
sub parse_qq_like_endswith ($);
sub parse_qq_like ($);
sub parse_re_codepoint_class ($);
sub parse_re_as_q_endswith ($$);
sub parse_re_balanced ($$);
sub parse_re_endswith ($$);
sub parse_re ($$);
sub parse_re_modifier ();
sub parse_tr_modifier ();
sub codepoint_tr ($$);
sub quotee_of ($);
sub escape_q ($$);
sub escape_qq ($$);
sub escape_to_hex ($$);

# this file is used as command on command line
if ($0 eq __FILE__) {
    main();
}

######################################################################
# main program
######################################################################

#---------------------------------------------------------------------
# running as module, runtime routines
sub import {
    my $self = shift @_;

    # confirm version
    if (defined($_[0]) and ($_[0] =~ /\A [0-9] /xms)) {
        if ($_[0] ne $mb::VERSION) {
            die "@{[__FILE__]} just $_[0] required--but this is version $mb::VERSION, stopped";
        }
        shift @_;
    }

    # set script encoding
    if (defined $_[0]) {
        my $encoding = $_[0];
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | sjis | uhc | utf8 ) \z/xms) {
            set_script_encoding($encoding);
        }
        else {
            die "@{[__FILE__]} script_encoding '$encoding' not supported.\n";
        }
    }
    else {
        set_script_encoding(detect_system_encoding());
    }
}

#---------------------------------------------------------------------
# running as command
sub main () {

    # usage
    if (scalar(@ARGV) == 0) {
        die <<END;
usage:

perl mb.pm              MBCS_Perl_script.pl
perl mb.pm -e big5      MBCS_Perl_script.pl
perl mb.pm -e big5hkscs MBCS_Perl_script.pl
perl mb.pm -e eucjp     MBCS_Perl_script.pl
perl mb.pm -e gb18030   MBCS_Perl_script.pl
perl mb.pm -e gbk       MBCS_Perl_script.pl
perl mb.pm -e sjis      MBCS_Perl_script.pl
perl mb.pm -e uhc       MBCS_Perl_script.pl
perl mb.pm -e utf8      MBCS_Perl_script.pl

END
    }

    # set script encoding from command line
    my $encoding = '';
    if (($encoding) = $ARGV[0] =~ /\A -e ( .+ ) \z/xms) {
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | sjis | uhc | utf8 ) \z/xms) {
            set_script_encoding($encoding);
            shift @ARGV;
        }
        else {
            die "script_encoding '$encoding' not supported.\n";
        }
    }
    elsif ($ARGV[0] =~ /\A -e \z/xms) {
        $encoding = $ARGV[1];
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | sjis | uhc | utf8 ) \z/xms) {
            set_script_encoding($encoding);
            shift @ARGV;
            shift @ARGV;
        }
        else {
            die "script_encoding '$encoding' not supported.\n";
        }
    }
    else {
        set_script_encoding(detect_system_encoding());
    }

    # poor "make"
    (my $script_oo = $ARGV[0]) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
    if (
        (not -e $script_oo)            or
        (-M $script_oo <= -M $ARGV[0]) or
        (-M $script_oo <= -M __FILE__)
    ) {

        # read application script
        mb::_open_r(my $fh, $ARGV[0]) or die "$0(@{[__LINE__]}): cant't open file: $ARGV[0]\n";
        local $_ = CORE::do { local $/; <$fh> };
        close $fh;

        # poor file locking
        local $SIG{__DIE__} = sub { rmdir("$ARGV[0].lock"); };
        if (mkdir("$ARGV[0].lock", 0755)) {
            mb::_open_w($fh, ">$script_oo") or die "$0(@{[__LINE__]}): cant't open file: $script_oo\n";
            print {$fh} mb::parse();
            close $fh;
            rmdir("$ARGV[0].lock");
        }
        else {
            die "$0(@{[__LINE__]}): cant't mkdir: $ARGV[0].lock\n";
        }
    }

    # run octet-oriented script
    my $module_path = '';
    my $module_name = '';
    my $quote = '';
    if ($OSNAME =~ /MSWin32/) {
        if ($0 =~ m{ ([^\/\\]+)\.pm \z}xmsi) {
            ($module_path, $module_name) = ($`, $1);
            $module_path ||= '.';
            $module_path =~ s{ [\/\\] \z}{}xms;
        }
        else {
            die "$0(@{[__LINE__]}): can't run as module.\n";
        }
        $quote = q{"};
    }
    else {
        if ($0 =~ m{ ([^\/]+)\.pm \z}xmsi) {
            ($module_path, $module_name) = ($`, $1);
            $module_path ||= '.';
            $module_path =~ s{ / \z}{}xms;
        }
        else {
            die "$0(@{[__LINE__]}): can't run as module.\n";
        }
        $quote = q{'};
    }

    # run octet-oriented script
    $| = 1;
    system($^X, "-I$module_path", "-M$module_name=$mb::VERSION,$script_encoding", map { / / ? "$quote$_$quote" : $_ } $script_oo, @ARGV[1..$#ARGV]);
    exit($? >> 8);
}

######################################################################
# subroutines for MBCS application programmers
######################################################################

#---------------------------------------------------------------------
# chop() for MBCS encoding
sub mb::chop (@) {
    my $chop = '';
    for (@_ ? @_ : $_) {
        if (my @x = /\G${mb::x}/g) {
            $chop = pop @x;
            $_ = join '', @x;
        }
    }
    return $chop;
}

#---------------------------------------------------------------------
# chr() for MBCS encoding
sub mb::chr (;$) {
    local $_ = shift if @_;
    my @octet = ();
    CORE::do {
        unshift @octet, ($_ % 0x100);
        $_ = int($_ / 0x100);
    } while ($_ > 0);
    return pack 'C*', @octet;
}

#---------------------------------------------------------------------
# do FILE for MBCS encoding
sub mb::do ($) {
    my($file) = @_;
    for my $prefix (@INC) {
        my $prefix_file = "$prefix/$file";
        if (mb::_f($prefix_file)) {

            # poor "make"
            (my $prefix_file_oo = $prefix_file) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
            if (
                (not -e $prefix_file_oo)                or
                (-M $prefix_file_oo <= -M $prefix_file) or
                (-M $prefix_file_oo <= -M __FILE__)
            ) {
                mb::_open_r(my $fh, $prefix_file) or Carp::confess "$0(@{[__LINE__]}): cant't open file: $prefix_file\n";
                local $_ = CORE::do { local $/; <$fh> };
                close $fh;

                # poor file locking
                local $SIG{__DIE__} = sub { rmdir("$prefix_file.lock"); };
                if (mkdir("$prefix_file.lock", 0755)) {
                    mb::_open_w(my $fh, ">$prefix_file_oo") or Carp::confess "$0(@{[__LINE__]}): cant't open file: $prefix_file_oo\n";
                    print {$fh} mb::parse();
                    close $fh;
                    rmdir("$prefix_file.lock");
                }
                else {
                    Carp::confess "$0(@{[__LINE__]}): cant't mkdir: $prefix_file.lock\n";
                }
            }
            $INC{$file} = $prefix_file_oo;

            # run as Perl script
            # must use CORE::do to use <DATA>, because CORE::eval cannot do it
            # moreover "goto &CORE::do" doesn't work
            return CORE::eval sprintf(<<'END', (caller)[0]);
package %s;
CORE::do "$prefix_file_oo";
END
        }
    }
    Carp::confess "Can't find $file in \@INC";
}

#---------------------------------------------------------------------
# DOS-like glob() for MBCS encoding
sub mb::dosglob (;$) {
    my $expr = @_ ? $_[0] : $_;
    my @glob = ();

    # works on not MSWin32
    if ($OSNAME !~ /MSWin32/) {
        @glob = CORE::glob($expr);
    }

    # works on MSWin32
    else {

        # gets pattern
        while ($expr =~ s{\A [\x20]* ( "(?:${mb::x})+?" | (?:(?!["\x20])${mb::x})+ ) }{}xms) {
            my $pattern = $1;

            # avoids command injection
            next if $pattern =~ /\G${mb::_anchor} \& /xms;
            next if $pattern =~ /\G${mb::_anchor} \( /xms;
            next if $pattern =~ /\G${mb::_anchor} \) /xms;
            next if $pattern =~ /\G${mb::_anchor} \< /xms;
            next if $pattern =~ /\G${mb::_anchor} \> /xms;
            next if $pattern =~ /\G${mb::_anchor} \^ /xms;
            next if $pattern =~ /\G${mb::_anchor} \| /xms;

            # makes globbing result
            mb::tr($pattern, '/', "\x5C");
            if (my($dir) = $pattern =~ m{\A (${mb::x}*) \\ }xms) {
                push @glob, map { "$dir\\$_" } CORE::split /\n/, `DIR /B $pattern 2>NUL`;
            }
            else {
                push @glob,                    CORE::split /\n/, `DIR /B $pattern 2>NUL`;
            }
        }
    }

    # returns globbing result
    my %glob = map { $_ => 1 } @glob;
    return sort { (mb::uc($a) cmp mb::uc($b)) || ($a cmp $b) } keys %glob;
}

#---------------------------------------------------------------------
# eval STRING for MBCS encoding
sub mb::eval (;$) {
    local $_ = shift if @_;

    # run as Perl script
    return CORE::eval mb::parse();
}

#---------------------------------------------------------------------
# getc() for MBCS encoding
sub mb::getc (;*@) {
    my $fh = @_ ? Symbol::qualify_to_ref(shift @_,caller()) : \*STDIN;
    Carp::confess 'Too many arguments for mb::getc' if @_ and not wantarray;
    my $getc = CORE::getc $fh;
    if ($script_encoding =~ /\A (?: sjis ) \z/xms) {
        if ($getc =~ /\A [\x81-\x9F\xE0-\xFC] \z/xms) {
            $getc .= CORE::getc $fh;
        }
    }
    elsif ($script_encoding =~ /\A (?: eucjp ) \z/xms) {
        if ($getc =~ /\A [\xA1-\xFE] \z/xms) {
            $getc .= CORE::getc $fh;
        }
    }
    elsif ($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs ) \z/xms) {
        if ($getc =~ /\A [\x81-\xFE] \z/xms) {
            $getc .= CORE::getc $fh;
        }
    }
    elsif ($script_encoding =~ /\A (?: gb18030 ) \z/xms) {
        if ($getc =~ /\A [\x81-\xFE] \z/xms) {
            $getc .= CORE::getc $fh;
            if ($getc =~ /\A [\x81-\xFE] [\x30-\x39] \z/xms) {
                $getc .= CORE::getc $fh;
                $getc .= CORE::getc $fh;
            }
        }
    }
    elsif ($script_encoding =~ /\A (?: utf8 ) \z/xms) {
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
    }
    return wantarray ? ($getc,@_) : $getc;
}

#---------------------------------------------------------------------
# index() for MBCS encoding
sub mb::index ($$;$) {
    my $index = 0;
    if (@_ == 3) {
        $index = mb::index_byte($_[0], $_[1], CORE::length(mb::substr($_[0], 0, $_[2])));
    }
    else {
        $index = mb::index_byte($_[0], $_[1]);
    }
    if ($index == -1) {
        return -1;
    }
    else {
        return mb::length(CORE::substr $_[0], 0, $index);
    }
}

#---------------------------------------------------------------------
# JPerl like index() for MBCS encoding
sub mb::index_byte ($$;$) {
    my($str,$substr,$position) = @_;
    $position ||= 0;
    my $pos = 0;
    while ($pos < CORE::length($str)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            if ($pos >= $position) {
                return $pos;
            }
        }
        if (CORE::substr($str,$pos) =~ /\A(${mb::x})/oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return -1;
}

#---------------------------------------------------------------------
# universal lc() for MBCS encoding
sub mb::lc (;$) {
    local $_ = shift if @_;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
    return join '', map { {qw( A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z )}->{$_}||$_ } /\G${mb::x}/g;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
}

#---------------------------------------------------------------------
# universal lcfirst() for MBCS encoding
sub mb::lcfirst (;$) {
    local $_ = shift if @_;
    if (/\A(${mb::x})(.*)\z/s) {
        return mb::lc($1) . $2;
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# length() for MBCS encoding
sub mb::length (;$) {
    local $_ = shift if @_;
    return scalar(() = /\G${mb::x}/g);
}

#---------------------------------------------------------------------
# ord() for MBCS encoding
sub mb::ord (;$) {
    local $_ = shift if @_;
    my $ord = 0;
    if (/\A(${mb::x})/) {
        for my $octet (unpack 'C*', $1) {
            $ord = $ord * 0x100 + $octet;
        }
    }
    return $ord;
}

#---------------------------------------------------------------------
# require for MBCS encoding
sub mb::require (;$) {
    local $_ = shift if @_;

    # require perl version
    if (/^[0-9]/) {
        if ($] < $_) {
            Carp::confess "Perl $_ required--this is only version $], stopped";
        }
        else {
            return 1;
        }
    }

    # require expr
    else {
        if (exists $INC{$_}) {
            return 1 if $INC{$_};
            Carp::confess "Compilation failed in require";
        }

        # find expr in @INC
        for my $prefix (@INC) {
            my $prefix_file = "$prefix/$_";
            if (mb::_f($prefix_file)) {

                # poor "make"
                (my $prefix_file_oo = $prefix_file) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
                if (
                    (not -e $prefix_file_oo)                or
                    (-M $prefix_file_oo <= -M $prefix_file) or
                    (-M $prefix_file_oo <= -M __FILE__)
                ) {
                    mb::_open_r(my $fh, $prefix_file) or Carp::confess "$0(@{[__LINE__]}): cant't open file: $prefix_file\n";
                    local $_ = CORE::do { local $/; <$fh> };
                    close $fh;

                    # poor file locking
                    local $SIG{__DIE__} = sub { rmdir("$prefix_file.lock"); };
                    if (mkdir("$prefix_file.lock", 0755)) {
                        mb::_open_w(my $fh, ">$prefix_file_oo") or Carp::confess "$0(@{[__LINE__]}): cant't open file: $prefix_file_oo\n";
                        print {$fh} mb::parse();
                        close $fh;
                        rmdir("$prefix_file.lock");
                    }
                    else {
                        Carp::confess "$0(@{[__LINE__]}): cant't mkdir: $prefix_file.lock\n";
                    }
                }
                $INC{$_} = $prefix_file_oo;

                # run as Perl script
                # must use CORE::do to use <DATA>, because CORE::eval cannot do it.
                local $@;
                my $result = CORE::eval sprintf(<<'END', (caller)[0]);
package %s;
CORE::do "$prefix_file_oo";
END

                # return result
                if ($@) {
                    $INC{$_} = undef;
                    Carp::confess $@;
                }
                elsif (not $result) {
                    delete $INC{$_};
                    Carp::confess "$_ did not return true value";
                }
                else {
                    return $result;
                }
            }
        }
        Carp::confess "Can't find $_ in \@INC";
    }
}

#---------------------------------------------------------------------
# reverse() for MBCS encoding
sub mb::reverse (@) {
    if (wantarray) {
        return CORE::reverse @_;
    }
    else {
        return join '', CORE::reverse(join('',@_) =~ /\G${mb::x}/g);
    }
}

#---------------------------------------------------------------------
# rindex() for MBCS encoding
sub mb::rindex ($$;$) {
    my $rindex = 0;
    if (@_ == 3) {
        $rindex = mb::rindex_byte($_[0], $_[1], CORE::length(mb::substr($_[0], 0, $_[2])));
    }
    else {
        $rindex = mb::rindex_byte($_[0], $_[1]);
    }
    if ($rindex == -1) {
        return -1;
    }
    else {
        return mb::length(CORE::substr $_[0], 0, $rindex);
    }
}

#---------------------------------------------------------------------
# JPerl like rindex() for MBCS encoding
sub mb::rindex_byte ($$;$) {
    my($str,$substr,$position) = @_;
    $position ||= CORE::length($str) - 1;
    my $pos = 0;
    my $rindex = -1;
    while (($pos < CORE::length($str)) and ($pos <= $position)) {
        if (CORE::substr($str,$pos,CORE::length($substr)) eq $substr) {
            $rindex = $pos;
        }
        if (CORE::substr($str,$pos) =~ /\A(${mb::x})/oxms) {
            $pos += CORE::length($1);
        }
        else {
            $pos += 1;
        }
    }
    return $rindex;
}

#---------------------------------------------------------------------
# set OSNAME
sub mb::set_OSNAME ($) {
    $OSNAME = $_[0];
}

#---------------------------------------------------------------------
# set script encoding name and more
sub mb::set_script_encoding ($) {
    $script_encoding = $_[0];

    # over US-ASCII
    ${mb::over_ascii} = {
        'sjis'      => '(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])',                         # shift_jis ANSI/OEM Japanese; Japanese (Shift-JIS)
        'gbk'       => '(?>[\x81-\xFE][\x00-\xFF])',                                              # gb2312 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
        'uhc'       => '(?>[\x81-\xFE][\x00-\xFF])',                                              # ks_c_5601-1987 ANSI/OEM Korean (Unified Hangul Code)
        'big5'      => '(?>[\x81-\xFE][\x00-\xFF])',                                              # big5 ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)
        'big5hkscs' => '(?>[\x81-\xFE][\x00-\xFF])',                                              # HKSCS support on top of traditional Chinese Windows
        'eucjp'     => '(?>[\xA1-\xFE][\x00-\xFF])',                                              # EUC-JP Japanese (JIS 0208-1990 and 0121-1990)
        'gb18030'   => '(?>[\x81-\xFE][\x30-\x39][\x81-\xFE][\x30-\x39]|[\x81-\xFE][\x00-\xFF])', # GB18030 Windows XP and later: GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)
    #   'utf8'      => '(?>[\xC2-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF][\x80-\xBF]|[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF])', # utf-8 Unicode (UTF-8) RFC2279
        'utf8'      => '(?>[\xE1-\xEC][\x80-\xBF][\x80-\xBF]|[\xC2-\xDF][\x80-\xBF]|[\xEE-\xEF][\x80-\xBF][\x80-\xBF]|[\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]|[\xE0-\xE0][\xA0-\xBF][\x80-\xBF]|[\xED-\xED][\x80-\x9F][\x80-\xBF]|[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]|[\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF])', # utf-8 Unicode (UTF-8) optimized RFC3629 for ja_JP
    }->{$script_encoding} || '[\x80-\xFF]';

    # supports qr/./ in MBCS script
    ${mb::x} = qr/(?>${mb::over_ascii}|[\x00-\x7F])/;

    # regexp of multi-byte anchoring

    # Quantifiers
    #   {n,m}  ---  Match at least n but not more than m times
    #
    # n and m are limited to non-negative integral values less than a
    # preset limit defined when perl is built. This is usually 32766 on
    # the most common platforms.
    #
    # The following code is an attempt to solve the above limitations
    # in a multi-byte anchoring.
    #
    # avoid "Segmentation fault" and "Error: Parse exception"
    #
    # perl5101delta
    # http://perldoc.perl.org/perl5101delta.html
    # In 5.10.0, the * quantifier in patterns was sometimes treated as {0,32767}
    # [RT #60034, #60464]. For example, this match would fail:
    #   ("ab" x 32768) =~ /^(ab)*$/
    #
    # SEE ALSO
    #
    # Complex regular subexpression recursion limit
    # http://www.perlmonks.org/?node_id=810857
    #
    # regexp iteration limits
    # http://www.nntp.perl.org/group/perl.perl5.porters/2009/02/msg144065.html
    #
    # latest Perl won't match certain regexes more than 32768 characters long
    # http://stackoverflow.com/questions/26226630/latest-perl-wont-match-certain-regexes-more-than-32768-characters-long
    #
    # Break through the limitations of regular expressions of Perl
    # http://d.hatena.ne.jp/gfx/20110212/1297512479

    if ($script_encoding =~ /\A (?: utf8 ) \z/xms) {
        ${mb::_anchor} = qr{.*?}xms;
    }
    elsif ($] >= 5.030000) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,65534}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    elsif ($] >= 5.010001) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,32766}\z)(?:${mb::x})*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    else {
        ${mb::_anchor} = qr{(?:${mb::x})*?}xms;
    }

    # codepoint class shortcuts in qq-like regular expression
    @{mb::_dot} = "(?>${mb::over_ascii}|.)";
    @{mb::_B} = "(?:(?<![$mb::bare_w])(?![$mb::bare_w])|(?<=[$mb::bare_w])(?=[$mb::bare_w]))";
    @{mb::_D} = "(?:(?![0-9])${mb::x})";
    @{mb::_H} = "(?:(?![\\x09\\x20])${mb::x})";
    @{mb::_N} = "(?:(?!\\n)${mb::x})";
    @{mb::_R} = "(?>\\r\\n|[\\x0A\\x0B\\x0C\\x0D])";
    @{mb::_S} = "(?:(?![\\t\\n\\f\\r\\x20])${mb::x})";
    @{mb::_V} = "(?:(?![\\x0A\\x0B\\x0C\\x0D])${mb::x})";
    @{mb::_W} = "(?:(?![A-Za-z0-9_])${mb::x})";
    @{mb::_b} = "(?:(?<![$mb::bare_w])(?=[$mb::bare_w])|(?<=[$mb::bare_w])(?![$mb::bare_w]))";
    @{mb::_d} = "[0-9]";
    @{mb::_h} = "[\\x09\\x20]";
    @{mb::_s} = "[\\t\\n\\f\\r\\x20]";
    @{mb::_v} = "[\\x0A\\x0B\\x0C\\x0D]";
    @{mb::_w} = "[A-Za-z0-9_]";
}

#---------------------------------------------------------------------
# substr() for MBCS encoding
BEGIN {
    CORE::eval sprintf <<'END', ($] >= 5.014) ? ':lvalue' : '';
#                      VV------------------------AAAAAAA
sub mb::substr ($$;$$) %s {
    my @x = $_[0] =~ /\G${mb::x}/g;

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
}

#---------------------------------------------------------------------
# tr/// and y/// for MBCS encoding
sub mb::tr ($$$;$) {
    my @x           = $_[0] =~ /\G${mb::x}/g;
    my @search      = $_[1] =~ /\G${mb::x}/g;
    my @replacement = $_[2] =~ /\G${mb::x}/g;
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
# universal uc() for MBCS encoding
sub mb::uc (;$) {
    local $_ = shift if @_;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
    return join '', map { {qw( a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z )}->{$_}||$_ } /\G${mb::x}/g;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
}

#---------------------------------------------------------------------
# universal ucfirst() for MBCS encoding
sub mb::ucfirst (;$) {
    local $_ = shift if @_;
    if (/\A(${mb::x})(.*)\z/s) {
        return mb::uc($1) . $2;
    }
    else {
        return '';
    }
}

######################################################################
# runtime routines on all operating systems (used automatically)
######################################################################

#---------------------------------------------------------------------
# implement of special variable $1,$2,$3,...
sub mb::_CAPTURE (;$) {
    if ($mb::last_s_passed) {
        if (defined $_[0]) {

            # $1 is used for multi-byte anchoring
            return CORE::eval '$' . ($_[0] + 1);
        }
        else {
            my @capture = ();
            if ($] >= 5.006) {

                # $1 is used for multi-byte anchoring in s///
                push @capture, map { CORE::eval('$'.$_) } 2 .. CORE::eval('$#-');
            }
            else {

                # @{^CAPTURE} doesn't work enough in perl 5.005
                for (my $n_th=2; defined(CORE::eval('$'.$n_th)); $n_th++) {
                    push @capture, CORE::eval('$'.$n_th);
                }
            }
            return @capture;
        }
    }
    else {
        if (defined $_[0]) {
            return CORE::eval '$' . $_[0];
        }
        else {
            my @capture = ();
            if ($] >= 5.006) {
                push @capture, map { CORE::eval('$'.$_) } 1 .. CORE::eval('$#-');
            }
            else {

                # @{^CAPTURE} doesn't work enough in perl 5.005
                for (my $n_th=1; defined(CORE::eval('$'.$n_th)); $n_th++) {
                    push @capture, CORE::eval('$'.$n_th);
                }
            }
            return @capture;
        }
    }
}

#---------------------------------------------------------------------
# implement of special variable @+
sub mb::_LAST_MATCH_END (@) {

    # perl 5.005 does not support @+, so it need CORE::eval

    if ($mb::last_s_passed) {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ ($+[0], @+[2..$#-])[ @_ ] };
        }
        else {
            return CORE::eval q{ ($+[0], @+[2..$#-]) };
        }
    }
    else {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ @+[ @_ ] };
        }
        else {
            return CORE::eval q{ @+ };
        }
    }
}

#---------------------------------------------------------------------
# implement of special variable @-
sub mb::_LAST_MATCH_START (@) {

    # perl 5.005 does not support @-, so it need CORE::eval

    if ($mb::last_s_passed) {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ ($-[2], @-[2..$#-])[ @_ ] };
        }
        else {
            return CORE::eval q{ ($-[2], @-[2..$#-]) };
        }
    }
    else {
        if (scalar(@_) >= 1) {
            return CORE::eval q{ @-[ @_ ] };
        }
        else {
            return CORE::eval q{ @- };
        }
    }
}

#---------------------------------------------------------------------
# implement of special variable $&
sub mb::_MATCH () {
    if (defined($&)) {
        if ($mb::last_s_passed) {
            if (defined($1) and (CORE::substr($&, 0, CORE::length($1)) eq $1)) {
                return CORE::substr($&, CORE::length($1));
            }
            else {
                Carp::confess 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
            }
        }
        else {
            if (defined($1) and (CORE::substr($&, -CORE::length($1)) eq $1)) {
                return $1;
            }
            else {
                Carp::confess 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
            }
        }
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# implement of special variable $`
sub mb::_PREMATCH () {
    if (defined($&)) {
        if ($mb::last_s_passed) {
            return $1;
        }
        else {
            if (defined($1) and (CORE::substr($&,-CORE::length($1)) eq $1)) {
                return CORE::substr($&, 0, -CORE::length($1));
            }
            else {
                Carp::confess 'Use of "$`", $PREMATCH, and ${^PREMATCH} need to /( capture all )/ in regexp';
            }
        }
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# flag off if last m// was pass
sub mb::_m_passed () {
    $mb::last_s_passed = 0;
    return '';
}

#---------------------------------------------------------------------
# flag on if last s/// was pass
sub mb::_s_passed () {
    $mb::last_s_passed = 1;
    return '';
}

#---------------------------------------------------------------------
# ignore case of m//i, qr//i, s///i
sub mb::_ignorecase ($) {
    local($_) = @_;
    my $regexp = '';

    # parse into elements
    while (/\G (
        \(\? \^? [a-z]*        [:\)]          | # cloister (?^x) (?^x: ...
        \(\? \^? [a-z]*-[a-z]+ [:\)]          | # cloister (?^x-y) (?^x-y: ...
        \[ ((?: \\${mb::x} | ${mb::x} )+?) \] |
        \\x\{ [0-9A-Fa-f]{2} \}               |
        \\o\{ [0-7]{3}       \}               |
        \\x   [0-9A-Fa-f]{2}                  |
        \\    [0-7]{3}                        |
        \\@{mb::_dot}                         |
        @{mb::_dot}
    ) /xmsgc) {
        my($element, $classmate) = ($1, $2);

        # in codepoint class
        if (defined $classmate) {
            $regexp .= '[';
            while ($classmate =~ /\G (
                \\x\{ [0-9A-Fa-f]{2} \} |
                \\o\{ [0-7]{3}       \} |
                \\x   [0-9A-Fa-f]{2}    |
                \\    [0-7]{3}          |
                \\@{mb::_dot}           |
                @{mb::_dot}
            ) /xmsgc) {
                my $element = $1;
                $regexp .= {qw(
                    A Aa a Aa
                    B Bb b Bb
                    C Cc c Cc
                    D Dd d Dd
                    E Ee e Ee
                    F Ff f Ff
                    G Gg g Gg
                    H Hh h Hh
                    I Ii i Ii
                    J Jj j Jj
                    K Kk k Kk
                    L Ll l Ll
                    M Mm m Mm
                    N Nn n Nn
                    O Oo o Oo
                    P Pp p Pp
                    Q Qq q Qq
                    R Rr r Rr
                    S Ss s Ss
                    T Tt t Tt
                    U Uu u Uu
                    V Vv v Vv
                    W Ww w Ww
                    X Xx x Xx
                    Y Yy y Yy
                    Z Zz z Zz
                )}->{$element} || $element;
            }
            $regexp .= ']';
        }

        # out of codepoint class
        else {
            $regexp .= {qw(
                A [Aa] a [Aa]
                B [Bb] b [Bb]
                C [Cc] c [Cc]
                D [Dd] d [Dd]
                E [Ee] e [Ee]
                F [Ff] f [Ff]
                G [Gg] g [Gg]
                H [Hh] h [Hh]
                I [Ii] i [Ii]
                J [Jj] j [Jj]
                K [Kk] k [Kk]
                L [Ll] l [Ll]
                M [Mm] m [Mm]
                N [Nn] n [Nn]
                O [Oo] o [Oo]
                P [Pp] p [Pp]
                Q [Qq] q [Qq]
                R [Rr] r [Rr]
                S [Ss] s [Ss]
                T [Tt] t [Tt]
                U [Uu] u [Uu]
                V [Vv] v [Vv]
                W [Ww] w [Ww]
                X [Xx] x [Xx]
                Y [Yy] y [Yy]
                Z [Zz] z [Zz]
            )}->{$element} || $element;
        }
    }
    return qr{$regexp};
}

#---------------------------------------------------------------------
# custom codepoint class in qq-like regular expression
sub mb::_cc ($) {
    my($classmate) = @_;
    if ($classmate =~ s{\A \^ }{}xms) {
        return '(?:(?!' . parse_re_codepoint_class($classmate) . ")${mb::x})";
    }
    else {
        return '(?:(?=' . parse_re_codepoint_class($classmate) . ")${mb::x})";
    }
}

#---------------------------------------------------------------------
# makes clustered code point from string
sub mb::_clustered_codepoint ($) {
    if (my @codepoint = $_[0] =~ /\G(${mb::x})/xmsgc) {
        if (CORE::length($codepoint[$#codepoint]) == 1) {
            return $_[0];
        }
        else {
            return join '', @codepoint[ 0 .. $#codepoint-1 ], "(?:$codepoint[$#codepoint])";
        }
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# open for append by undefined filehandle
sub mb::_open_a ($$) {
    $_[0] = Symbol::gensym();
    return open($_[0], ">>$_[1]");
}

#---------------------------------------------------------------------
# open for read by undefined filehandle
sub mb::_open_r ($$) {
    $_[0] = Symbol::gensym();
    return open($_[0], $_[1]);
}

#---------------------------------------------------------------------
# open for write by undefined filehandle
sub mb::_open_w ($$) {
    $_[0] = Symbol::gensym();
    return open($_[0], $_[1]);
}

#---------------------------------------------------------------------
# split() for MBCS encoding
# sub mb::_split (;$$$) {
sub mb::_split {
    my $pattern = defined($_[0]) ? $_[0] : ' ';
    my $string  = defined($_[1]) ? $_[1] : $_;
    my @split = ();

    # split's first argument is more consistently interpreted
    #
    # After some changes earlier in v5.17, split's behavior has been simplified:
    # if the PATTERN argument evaluates to a string containing one space, it is
    # treated the way that a literal string containing one space once was.
    # http://search.cpan.org/dist/perl-5.18.0/pod/perldelta.pod#split's_first_argument_is_more_consistently_interpreted
    # if $pattern is also omitted or is the literal space, " ", the function splits
    # on whitespace, /\s+/, after skipping any leading whitespace

    if ($pattern eq ' ') {
        $pattern = qr/\s+/;
        $string =~ s{\A \s+ }{}xms;
    }

    # count '(' in pattern
    my @parsed = ();
    my $modifier = '';
    if ((($modifier) = $pattern =~ /\A \(\?\^? (.+?) [\)\-\:] /xms) and ($modifier =~ /x/xms)) {
        @parsed = $pattern =~ m{ \G (
            \\ ${mb::x}              |
            \# .*? $                 | # comment on /x modifier
            \(\?\# (?:${mb::x})*? \) |
            \[ (?:${mb::x})+? \]     |
            \(\?                     |
            \(\+                     |
            \(\*                     |
            ${mb::x}                 |
            [\x00-\xFF]
        ) }xgc;
    }
    else {
        @parsed = $pattern =~ m{ \G (
            \\ ${mb::x}              |
            \(\?\# (?:${mb::x})*? \) |
            \[ (?:${mb::x})+? \]     |
            \(\?                     |
            \(\+                     |
            \(\*                     |
            ${mb::x}                 |
            [\x00-\xFF]
        ) }xgc;
    }
    my $last_match_no =
        1 +                                 # first '(' is for substring
        scalar(grep { $_ eq '(' } @parsed); # other '(' are for pattern of split()

    # Repeated Patterns Matching a Zero-length Substring
    # https://perldoc.perl.org/perlre.html#Repeated-Patterns-Matching-a-Zero-length-Substring
    my $substring_quantifier = ('' =~ / \A $pattern \z /xms) ? '+?' : '*?';

    # if $_[2] specified and positive
    if (defined($_[2]) and ($_[2] >= 1)) {
        my $limit = $_[2];

        CORE::eval q{ no warnings }; # avoid: Complex regular subexpression recursion limit (nnnnn) exceeded at ...

        # gets substrings by repeat chopping by pattern
        while ((--$limit > 0) and ($string =~ s<\A((?:${mb::x})$substring_quantifier)$pattern><>)) {
            for (my $n_th=1; $n_th <= $last_match_no; $n_th++) {
                push @split, CORE::eval('$'.$n_th);
            }
        }
    }

    # if $_[2] is omitted or zero or negative
    else {
        CORE::eval q{ no warnings }; # avoid: Complex regular subexpression recursion limit (nnnnn) exceeded at ...

        # gets substrings by repeat chopping by pattern
        while ($string =~ s<\A((?:${mb::x})$substring_quantifier)$pattern><>) {
            for (my $n_th=1; $n_th <= $last_match_no; $n_th++) {
                push @split, CORE::eval('$'.$n_th);
            }
        }
    }

    # get last substring
    if (CORE::length($string) > 0) {
        push @split, $string;
    }
    elsif (defined($_[2]) and ($_[2] >= 1)) {
        if (scalar(@split) < $_[2]) {
            push @split, ('') x ($_[2] - scalar(@split));
        }
    }

    # if $_[2] is omitted or zero, trailing null fields are stripped from the result
    if ((not defined $_[2]) or ($_[2] == 0)) {
        while ((scalar(@split) >= 1) and ($split[-1] eq '')) {
            pop @split;
        }
    }

    # old days, split had write its result to @_ on scalar context,
    # but this usage is no longer supported

    if (wantarray) {
        return @split;
    }
    else {
        return scalar @split;
    }
}

######################################################################
# runtime routines for MSWin32 (used automatically)
######################################################################

#---------------------------------------------------------------------
# filetest -B for MSWin32
sub mb::_B (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -B (mb::_B)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-B _,@_) : -B _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-B $fh,@_) : -B $fh;
    }
    elsif (-B $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-B qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -C for MSWin32
sub mb::_C (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -C (mb::_C)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-C _,@_) : -C _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-C $fh,@_) : -C $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-C $_,@_) : -C $_;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return wantarray ? (-C qq{$_.},@_) : -C qq{$_.};
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -M for MSWin32
sub mb::_M (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -M (mb::_M)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-M _,@_) : -M _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-M $fh,@_) : -M $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-M $_,@_) : -M $_;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return wantarray ? (-M qq{$_.},@_) : -M qq{$_.};
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -T for MSWin32
sub mb::_T (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -T (mb::_T)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-T _,@_) : -T _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-T $fh,@_) : -T $fh;
    }
    elsif (-T $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-T qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# chdir() for MSWin32
sub mb::_chdir (;$) {

    # works on MSWin32 only
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        return CORE::chdir $_[0];
    }

    if (@_ == 0) {
        return CORE::chdir;
    }
    elsif (($script_encoding =~ /\A (?: sjis ) \z/xms) and ($_[0] =~ /\A ${mb::x}* [\x81-\x9F\xE0-\xFC][\x5C] \z/xms)) {
        if (defined wantarray) {
            return 0;
        }
        else {
            Carp::confess "mb::_chdir: Can't chdir '$_[0]'\n";
        }
    }
    elsif (($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and ($_[0] =~ /\A ${mb::x}* [\x81-\xFE][\x5C] \z/xms)) {
        if (defined wantarray) {
            return 0;
        }
        else {
            Carp::confess "mb::_chdir: Can't chdir '$_[0]'\n";
        }
    }
    else {
        return CORE::chdir $_[0];
    }
}

#---------------------------------------------------------------------
# filetest -d for MSWin32
sub mb::_d (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -d (mb::_d)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-d _,@_) : -d _;
    }
    elsif (-d $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-d qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -e for MSWin32
sub mb::_e (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -e (mb::_e)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-e _,@_) : -e _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-e $fh,@_) : -e $fh;
    }
    elsif (-e $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -f for MSWin32
sub mb::_f (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -f (mb::_f)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-f _,@_) : -f _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-f $fh,@_) : -f $fh;
    }
    elsif (-f $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-f qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# lstat() for MSWin32
sub mb::_lstat (;*) {
    local $_ = shift if @_;
    if ($_ eq '_') {
        Carp::confess qq{lstat doesn't support '_'\n};
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return CORE::stat $fh; # not CORE::lstat
    }
    elsif (-e $_) {
        return CORE::stat _; # not CORE::lstat
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return CORE::stat _; # not CORE::lstat
        }
    }
    return wantarray ? () : undef;
}

#---------------------------------------------------------------------
# opendir() for MSWin32
sub mb::_opendir (*$) {
    my $dh;
    if (defined $_[0]) {
        $dh = Symbol::qualify_to_ref($_[0], caller());
    }
    else {
        $dh = $_[0] = \do { local *_ };
    }

    # works on MSWin32 only
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        return CORE::opendir $dh, $_[1];
    }
    elsif (-d $_[1]) {
        return CORE::opendir $dh, $_[1];
    }
    elsif (-d qq{$_[1].}) {
        return CORE::opendir $dh, qq{$_[1].};
    }
    return undef;
}

#---------------------------------------------------------------------
# filetest -r for MSWin32
sub mb::_r (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -r (mb::_r)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-r _,@_) : -r _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-r $fh,@_) : -r $fh;
    }
    elsif (-r $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-r qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -s for MSWin32
sub mb::_s (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -s (mb::_s)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-s _,@_) : -s _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-s $fh,@_) : -s $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-s $_,@_) : -s $_;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return wantarray ? (-s qq{$_.},@_) : -s qq{$_.};
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# stat() for MSWin32
sub mb::_stat (;*) {
    local $_ = shift if @_;
    if ($_ eq '_') {
        if (-e _) {
            return CORE::stat _;
        }
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return CORE::stat $fh;
    }
    elsif (-e $_) {
        return CORE::stat _;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return CORE::stat _;
        }
    }
    return wantarray ? () : undef;
}

#---------------------------------------------------------------------
# unlink() for MSWin32
sub mb::_unlink (@) {

    # works on MSWin32 only
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        return CORE::unlink(@_ ? @_ : $_);
    }

    my $unlink = 0;
    for (@_ ? @_ : $_) {
        if (CORE::unlink) {
            $unlink++;
        }
        elsif (CORE::unlink qq{$_.}) {
            $unlink++;
        }
    }
    return $unlink;
}

#---------------------------------------------------------------------
# filetest -w for MSWin32
sub mb::_w (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -w (mb::_w)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-w _,@_) : -w _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-w $fh,@_) : -w $fh;
    }
    elsif (-w $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-w qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -x for MSWin32
sub mb::_x (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -x (mb::_x)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-x _,@_) : -x _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-x $fh,@_) : -x $fh;
    }
    elsif (-x $_) {
        return wantarray ? (1,@_) : 1;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-x qq{$_.}) {
            return wantarray ? (1,@_) : 1;
        }
    }
    return wantarray ? (undef,@_) : undef;
}

#---------------------------------------------------------------------
# filetest -z for MSWin32
sub mb::_z (;*@) {
    local $_ = shift if @_;
    Carp::confess 'Too many arguments for -z (mb::_z)' if @_ and not wantarray;
    if ($_ eq '_') {
        return wantarray ? (-z _,@_) : -z _;
    }
    elsif (defined fileno(my $fh = Symbol::qualify_to_ref $_)) {
        return wantarray ? (-z $fh,@_) : -z $fh;
    }
    elsif (-e $_) {
        return wantarray ? (-z $_,@_) : -z $_;
    }
    elsif (($OSNAME =~ /MSWin32/) and ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (-e qq{$_.}) {
            return wantarray ? (-z qq{$_.},@_) : -z qq{$_.};
        }
    }
    return wantarray ? (undef,@_) : undef;
}

######################################################################
# source code filter
######################################################################

#---------------------------------------------------------------------
# detect system encoding any of big5, big5hkscs, eucjp, gb18030, gbk, sjis, uhc, utf8
sub detect_system_encoding () {

    # running on Microsoft Windows
    if ($OSNAME =~ /MSWin32/) {
        my($codepage) = qx{chcp} =~ m/([0-9]{3,5})\Z/;
        return {qw(
            932   sjis
            936   gbk
            949   uhc
            950   big5
            951   big5hkscs
            20932 eucjp
            54936 gb18030
        )}->{$codepage} || 'utf8';
    }

    # running on Oracle Solaris
    elsif ($OSNAME =~ /solaris/) {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            ja_JP.PCK     sjis
            ja            eucjp
            japanese      eucjp
            ja_JP.eucJP   eucjp
            zh            gbk
            zh.GBK        gbk
            zh_CN.GBK     gbk
            zh_CN.EUC     gbk
            zh_CN.GB18030 gb18030
            ko            uhc
            ko_KR.EUC     uhc
            zh_TW.BIG5    big5
            zh_HK.BIG5HK  big5hkscs
        )}->{$LANG} || 'utf8';
    }

    # running on HP HP-UX
    elsif ($OSNAME =~ /hpux/) {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            japanese      sjis
            ja_JP.SJIS    sjis
            japanese.euc  eucjp
            ja_JP.eucJP   eucjp
            zh_CN.hp15CN  gbk
            zh_CN.gb18030 gb18030
            ko_KR.eucKR   uhc
            zh_TW.big5    big5
            zh_HK.big5    big5hkscs
            zh_HK.hkbig5  big5hkscs
        )}->{$LANG} || 'utf8';
    }

    # running on IBM AIX
    elsif ($OSNAME =~ /aix/) {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            Ja_JP            sjis
            Ja_JP.IBM-943    sjis
            ja_JP            eucjp
            ja_JP.IBM-eucJP  eucjp
            zh_CN            gbk
            zh_CN.IBM-eucCN  gbk
            Zh_CN            gb18030
            Zh_CN.GB18030    gb18030
            ko_KR            uhc
            ko_KR.IBM-eucKR  uhc
            Zh_TW            big5
            Zh_TW.big-5      big5
            Zh_HK            big5hkscs
            Zh_HK.BIG5-HKSCS big5hkscs
        )}->{$LANG} || 'utf8';
    }

    # running on Other Systems
    else {
        my $LANG =
            defined($ENV{'LC_ALL'})   ? $ENV{'LC_ALL'}   :
            defined($ENV{'LC_CTYPE'}) ? $ENV{'LC_CTYPE'} :
            defined($ENV{'LANG'})     ? $ENV{'LANG'}     :
            '';
        return {qw(
            japanese      sjis
            ja_JP.SJIS    sjis
            ja_JP.mscode  sjis
            ja            eucjp
            japan         eucjp
            japanese.euc  eucjp
            Japanese-EUC  eucjp
            ja_JP         eucjp
            ja_JP.ujis    eucjp
            ja_JP.eucJP   eucjp
            ja_JP.AJEC    eucjp
            ja_JP.EUC     eucjp
            Jp_JP         eucjp
            zh_CN.EUC     gbk
            zh_CN.GB2312  gbk
            zh_CN.hp15CN  gbk
            zh_CN.gb18030 gb18030
            ko_KR.eucKR   uhc
            zh_TW.Big5    big5
            zh_TW.big5    big5
            zh_HK.big5    big5hkscs
        )}->{$LANG} || 'utf8';
    }
}

my $term = 0;
my @here_document_delimiter = ();

#---------------------------------------------------------------------
# parse script
sub parse (;$) {
    local $_ = shift if @_;

    $term = 0;
    @here_document_delimiter = ();

    # transpile JPerl script to Perl script
    my $parsed_script = '';
    while (not /\G \z /xmsgc) {
        $parsed_script .= parse_expr();
    }

    # return octet-oriented Perl script
    return $parsed_script;
}

#---------------------------------------------------------------------
# parse expression in script
sub parse_expr () {
    my $parsed = '';
    my $R = '(?>\\r\\n|\\r|\\n)';

    # __END__ or __DATA__
    if (/\G ^ ( (?: __END__ | __DATA__ ) $R .* ) \z/xmsgc) {
        $parsed .= $1;
    }

    # =pod ... =cut
    elsif (/\G ^ ( = [A-Za-z_][A-Za-z_0-9]* [\x00-\xFF]*? $R =cut \b [^\n]* $R ) /xmsgc) {
        $parsed .= $1;
    }

    # \r\n, \r, \n
    elsif (/\G ( $R ) /xmsgc) {
        $parsed .= $1;
        while (my $here_document_delimiter = shift @here_document_delimiter) {
            my($delimiter, $quote_type) = @{$here_document_delimiter};
            if ($quote_type eq 'qq') {
                $parsed .= parse_heredocument_as_qq_endswith($delimiter);
            }
            elsif ($quote_type eq 'q') {

                # perlop > Quote-Like Operators > <<EOF > Single Quotes
                #
                # Single quotes indicate the text is to be treated literally
                # with no interpolation of its content. This is similar to
                # single quoted strings except that backslashes have no special
                # meaning, with \\ being treated as two backslashes and not
                # one as they would in every other quoting construct.
                # https://perldoc.perl.org/perlop.html#Quote-Like-Operators

                $parsed .= parse_heredocument_as_q_endswith($delimiter);
            }
            else {
                die "$0(@{[__LINE__]}): $ARGV[0] here document delimiter '$delimiter' not found.\n";
            }
        }
    }

    # \t
    # "\x20" [ ] SPACE (U+0020)
    elsif (/\G ( [\t ]+ ) /xmsgc) {
        $parsed .= $1;
    }

    # "\x3B" [;] SEMICOLON (U+003B)
    elsif (/\G ( ; ) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # balanced bracket
    # "\x28" [(] LEFT PARENTHESIS (U+0028)
    # "\x7B" [{] LEFT CURLY BRACKET (U+007B)
    # "\x5B" [[] LEFT SQUARE BRACKET (U+005B)
    elsif (/\G ( [(\{\[] ) /xmsgc) {
        $parsed .= parse_expr_balanced($1);
        $term = 1;
    }

    # number
    # "\x30" [0] DIGIT ZERO (U+0030)
    # "\x31" [1] DIGIT ONE (U+0031)
    # "\x32" [2] DIGIT TWO (U+0032)
    # "\x33" [3] DIGIT THREE (U+0033)
    # "\x34" [4] DIGIT FOUR (U+0034)
    # "\x35" [5] DIGIT FIVE (U+0035)
    # "\x36" [6] DIGIT SIX (U+0036)
    # "\x37" [7] DIGIT SEVEN (U+0037)
    # "\x38" [8] DIGIT EIGHT (U+0038)
    # "\x39" [9] DIGIT NINE (U+0039)
    elsif (/\G ( 
        0x    [0-9A-Fa-f_]+ |
        0b    [01_]+        |
        0     [0-7_]*       |
        [1-9] [0-9_]* (?: \.[0-9_]* )? (?: [Ee] [0-9_]+ )?
    ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # any term then operator
    # "\x25" [%] PERCENT SIGN (U+0025)
    # "\x26" [&] AMPERSAND (U+0026)
    # "\x2A" [*] ASTERISK (U+002A)
    # "\x2E" [.] FULL STOP (U+002E)
    # "\x2F" [/] SOLIDUS (U+002F)
    # "\x3C" [<] LESS-THAN SIGN (U+003C)
    # "\x3F" [?] QUESTION MARK (U+003F)
    elsif ($term and /\G ( %= | % | &&= | && | &\.= | &\. | &= | & | \*\*= | \*\* | \*= | \* | \.\.\. | \.\. | \.= | \. | \/\/= | \/\/ | \/= | \/ | <=> | << | <= | < | \? ) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # unimplemented file test operator on MSWin32
    # "\x2D" [-] HYPHEN-MINUS (U+002D)
    elsif (/\G ( -[ASORWXbcgkloptu] ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # implemented file test operator on MSWin32
    # implements run on any systems by transpiling once
    elsif (/\G -([BCMTdefrswxz]) \b /xmsgc) {
        $parsed .= "mb::_$1";
        $term = 1;
    }

    # yada-yada or triple-dot operator
    elsif (/\G ( \.\.\. ) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # any operator
    # "\x21" [!] EXCLAMATION MARK (U+0021)
    # "\x2B" [+] PLUS SIGN (U+002B)
    # "\x2C" [,] COMMA (U+002C)
    # "\x3D" [=] EQUALS SIGN (U+003D)
    # "\x3E" [>] GREATER-THAN SIGN (U+003E)
    # "\x5C" [\] REVERSE SOLIDUS (U+005C)
    # "\x5E" [^] CIRCUMFLEX ACCENT (U+005E)
    # "\x7C" [|] VERTICAL LINE (U+007C)
    # "\x7E" [~] TILDE (U+007E)
    elsif (/\G ( != | !~ | ! | \+\+ | \+= | \+ | , | -- | -= | -> | - | == | => | =~ | = | >> | >= | > | \\ | \^\.= | \^\. | \^= | \^ | (?: and | cmp | eq | ge | gt | isa | le | lt | ne | not | or | x | x= | xor ) \b | \|\|= | \|\| | \|\.= | \|\. | \|= | \| | ~~ | ~\. | ~= | ~ ) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # $`           --> mb::_PREMATCH()
    # ${`}         --> mb::_PREMATCH()
    # $PREMATCH    --> mb::_PREMATCH()
    # ${PREMATCH}  --> mb::_PREMATCH()
    # ${^PREMATCH} --> mb::_PREMATCH()
    elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed .= 'mb::_PREMATCH()';
        $term = 1;
    }

    # $&        --> mb::_MATCH()
    # ${&}      --> mb::_MATCH()
    # $MATCH    --> mb::_MATCH()
    # ${MATCH}  --> mb::_MATCH()
    # ${^MATCH} --> mb::_MATCH()
    elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed .= 'mb::_MATCH()';
        $term = 1;
    }

    # $1 --> mb::_CAPTURE(1)
    # $2 --> mb::_CAPTURE(2)
    # $3 --> mb::_CAPTURE(3)
    elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
        $parsed .= "mb::_CAPTURE($1)";
        $term = 1;
    }

    # @{^CAPTURE} --> mb::_CAPTURE()
    elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
        $parsed .= 'mb::_CAPTURE()';
        $term = 1;
    }

    # ${^CAPTURE}[0] --> mb::_CAPTURE(1)
    # ${^CAPTURE}[1] --> mb::_CAPTURE(2)
    # ${^CAPTURE}[2] --> mb::_CAPTURE(3)
    elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_CAPTURE($n_th+1)";
        $term = 1;
    }

    # @-                   --> mb::_LAST_MATCH_START()
    # @LAST_MATCH_START    --> mb::_LAST_MATCH_START()
    # @{LAST_MATCH_START}  --> mb::_LAST_MATCH_START()
    # @{^LAST_MATCH_START} --> mb::_LAST_MATCH_START()
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed .= 'mb::_LAST_MATCH_START()';
        $term = 1;
    }

    # $-[1]                   --> mb::_LAST_MATCH_START(1)
    # $LAST_MATCH_START[1]    --> mb::_LAST_MATCH_START(1)
    # ${LAST_MATCH_START}[1]  --> mb::_LAST_MATCH_START(1)
    # ${^LAST_MATCH_START}[1] --> mb::_LAST_MATCH_START(1)
    elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_LAST_MATCH_START($n_th)";
        $term = 1;
    }

    # @+                 --> mb::_LAST_MATCH_END()
    # @LAST_MATCH_END    --> mb::_LAST_MATCH_END()
    # @{LAST_MATCH_END}  --> mb::_LAST_MATCH_END()
    # @{^LAST_MATCH_END} --> mb::_LAST_MATCH_END()
    elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed .= 'mb::_LAST_MATCH_END()';
        $term = 1;
    }

    # $+[1]                 --> mb::_LAST_MATCH_END(1)
    # $LAST_MATCH_END[1]    --> mb::_LAST_MATCH_END(1)
    # ${LAST_MATCH_END}[1]  --> mb::_LAST_MATCH_END(1)
    # ${^LAST_MATCH_END}[1] --> mb::_LAST_MATCH_END(1)
    elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_LAST_MATCH_END($n_th)";
        $term = 1;
    }

    # mb::do { block }   --> do { block }
    # mb::eval { block } --> eval { block }
    # do { block }       --> do { block }
    # eval { block }     --> eval { block }
    elsif (/\G (?: mb:: )? ( (?: do | eval ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $term = 1;
    }

    # $#{}, ${}, @{}, %{}, &{}, *{}, do {}, eval {}, sub {}
    # "\x24" [$] DOLLAR SIGN (U+0024)
    elsif (/\G ((?: \$[#] | [\$\@%&*] | (?:CORE::)? do | (?:CORE::)? eval | sub ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $term = 1;
    }

    # mb::do   --> mb::do
    # mb::eval --> mb::eval
    # do       --> mb::do
    # eval     --> mb::eval
    elsif (/\G (?: mb:: )? ( do | eval ) \b /xmsgc) {
        $parsed .= "mb::$1";
        $term = 1;
    }

    # CORE::do   --> CORE::do
    # CORE::eval --> CORE::eval
    elsif (/\G ( CORE:: (?: do | eval ) ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # last index of array
    elsif (/\G ( [\$] [#] (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # scalar variable
    elsif (/\G (     [\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | ^\{[A-Za-z_][A-Za-z_0-9]*\} | [0-9]+ | [!"#\$%&'()+,\-.\/:;<=>?\@\[\\\]\^_`|~] ) (?: \s* (?: \+\+ | -- ) )? ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # array variable
    # "\x40" [@] COMMERCIAL AT (U+0040)
    elsif (/\G (   [\@\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | [_] ) ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # hash variable
    elsif (/\G ( [\%\@\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | [!+\-] ) ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # user subroutine call
    # type glob
    elsif (/\G (     [&*] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # comment
    # "\x23" [#] NUMBER SIGN (U+0023)
    elsif (/\G ( [#] [^\n]* ) /xmsgc) {
        $parsed .= $1;
    }

    # 2-quotes

    # '...'
    # "\x27" ['] APOSTROPHE (U+0027)
    elsif (m{\G ( ' )    }xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }

    # "...", `...`
    # "\x22" ["] QUOTATION MARK (U+0022)
    # "\x60" [`] GRAVE ACCENT (U+0060)
    elsif (m{\G ( ["`] ) }xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }

    # /.../
    elsif (m{\G ( [/] )  }xmsgc) {
        my $regexp = parse_re_endswith('m',$1);
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();
        if ($modifier_i) {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $term = 1;
    }

    # ?...?
    elsif (m{\G ( [?] )  }xmsgc) {
        my $regexp = parse_re_endswith('m',$1);
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();
        if ($modifier_i) {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $term = 1;
    }

    # <<>> double-diamond operator
    elsif (/\G ( <<>> ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # <FILE> diamond operator
    # <${file}>
    # <$file>
    # <fileglob>
    elsif (/\G (<) ((?:(?!\s)${mb::x})*?) (>) /xmsgc) {
        my($open_bracket, $quotee, $close_bracket) = ($1, $2, $3);
        $parsed .= $open_bracket;
        while ($quotee =~ /\G (${mb::x}) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $term = 1;
    }

    # qw/.../, q/.../
    elsif (/\G ( qw | q ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_q__like_balanced($1); $term = 1; }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_q__like_balanced($1); $term = 1; }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
    }

    # qq/.../
    elsif (/\G ( qq ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; } # qq'...' works as "..."
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_qq_like_balanced($1); $term = 1; }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; } # qq'...' works as "..."
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_qq_like_balanced($1); $term = 1; }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
    }

    # qx/.../
    elsif (/\G ( qx ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_qq_like_balanced($1); $term = 1; }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_q__like_endswith($1); $term = 1; }
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_qq_like_balanced($1); $term = 1; }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_qq_like_endswith($1); $term = 1; }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
    }

    # m/.../, qr/.../
    elsif (/\G ( m | qr ) \b /xmsgc) {
        $parsed .= $1;
        my $regexp = '';
        if    (/\G ( [#] )        /xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr#...#
        elsif (/\G ( ['] )        /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); }       # qr'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp .= parse_re_balanced('m',$1);      }       # qr{...}
        elsif (m{\G( [/] )        }xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr/.../
        elsif (/\G ( [:\@] )      /xmsgc) { $regexp .= '`' . quotee_of(parse_re_endswith('m',$1)) . '`'; } # qr@...@
        elsif (/\G ( [\S] )       /xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp .= $1;                      # qr SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE A...A
            elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); } # qr SPACE '...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('m',$1);      } # qr SPACE {...}
            elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE /.../
            elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= '`' . quotee_of(parse_re_endswith('m',$1)) . '`'; } # qr SPACE @...@
            elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE ?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        # /i modifier
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();
        if ($modifier_i) {
            $parsed .= sprintf('{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $term = 1; 
    }

    # 3-quotes

    # s/.../.../
    elsif (/\G ( s ) \b /xmsgc) {
        $parsed .= $1;
        my $regexp = '';
        my $comment = '';
        my @replacement = ();
        if    (/\G ( [#] )        /xmsgc) { $regexp .= parse_re_endswith('s',$1);      @replacement = parse_qq_like_endswith($1); }       # s#...#...#
        elsif (/\G ( ['] )        /xmsgc) { $regexp .= parse_re_as_q_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }       # s'...'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp .= parse_re_balanced('s',$1);                                                         # s{...}...
            if    (/\G ( [#] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}#...#
            elsif (/\G ( ['] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                              # s{}{...}
            elsif (m{\G( [/] )        }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}/.../
            elsif (/\G ( [\S] )       /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                              # s{}?...?
            elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                           # s{} SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $comment .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                        # s{} SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE /.../
                elsif (/\G ( [\S] )         /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                        # s{} SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        elsif (m{\G( [/] )        }xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }            # s/.../.../
        elsif (/\G ( [:\@] )      /xmsgc) { $regexp .= '`' . quotee_of(parse_re_endswith('s',$1)) . '`';
                                                                                  @replacement = parse_qq_like_endswith($1); }            # s@...@...@
        elsif (/\G ( [\S] )       /xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }            # s?...?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp .= $1;                                                                 # s SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('s',$1);      @replacement = parse_qq_like_endswith($1); } # s SPACE A...A...A
            elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('s',$1); @replacement = parse_qq_like_endswith($1); } # s SPACE '...'...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('s',$1);                                                   # s SPACE {...}...
                if    (/\G ( [#] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}#...#
                elsif (/\G ( ['] )        /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}'...'
                elsif (/\G ( [\(\{\[\<] ) /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                          # s SPACE {}{...}
                elsif (m{\G( [/] )        }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}/.../
                elsif (/\G ( [\S] )       /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                          # s SPACE {}?...?
                elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                       # s SPACE {} SPACE ...
                    while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                        $comment .= $1;
                    }
                    if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE A...A
                    elsif (/\G ( ['] )          /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE '...'
                    elsif (/\G ( [\(\{\[\<] )   /xmsgc) { @replacement = parse_qq_like_balanced($1); }                                    # s SPACE {} SPACE {...}
                    elsif (m{\G( [/] )          }xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE /.../
                    elsif (/\G ( [\S] )         /xmsgc) { @replacement = parse_qq_like_endswith($1); }                                    # s SPACE {} SPACE ?...?
                    else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
                }
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }      # s SPACE /.../.../
            elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= '`' . quotee_of(parse_re_endswith('s',$1)) . '`';
                                                                                        @replacement = parse_qq_like_endswith($1); }      # s SPACE @...@...@
            elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('s',$1); @replacement = parse_qq_like_endswith($1); }      # s SPACE ?...?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();
        my $replacement = '';
        my $eval = '';

        # has /e modifier
        if (my $e = $modifier_cegr =~ tr/e//d) {
            $replacement = 'q'. $replacement[1]; # q-type quotee
            $eval = 'mb::eval ' x $e;
        }

        # s''q-quotee'
        elsif ($replacement[0] =~ /\A ' /xms) {
            $replacement = $replacement[1]; # q-type quotee
        }

        # s//qq-quotee/
        else {
            $replacement = 'qq ' . $replacement[0]; # qq-type quotee
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('{(\\G${mb::_anchor})@{[mb::_ignorecase(qr%s%s)]}@{[mb::_s_passed()]}}%s{$1 . %s%s}e%s', $regexp, $modifier_not_cegir, $comment, $eval, $replacement, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('{(\\G${mb::_anchor})@{[' .            'qr%s%s ]}@{[mb::_s_passed()]}}%s{$1 . %s%s}e%s', $regexp, $modifier_not_cegir, $comment, $eval, $replacement, $modifier_cegr);
        }
        $term = 1;
    }

    # tr/.../.../, y/.../.../
    elsif (/\G (?: tr | y ) \b /xmsgc) {
        $parsed .= 's'; # not 'tr'
        my $search = '';
        my $comment = '';
        my $replacement = '';
        if    (/\G ( [#] )        /xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); }       # tr#...#...#
        elsif (/\G ( ['] )        /xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); }       # tr'...'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $search .= parse_q__like_balanced($1);                                                     # tr{...}...
            if    (/\G ( [#] )        /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                          # tr{}#...#
            elsif (/\G ( ['] )        /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                          # tr{}'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $replacement .= parse_q__like_balanced($1); }                                          # tr{}{...}
            elsif (m{\G( [/] )        }xmsgc) { $replacement .= parse_q__like_endswith($1); }                                          # tr{}/.../
            elsif (/\G ( [\S] )       /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                          # tr{}?...?
            elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                        # tr{} SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $comment .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                    # tr{} SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                    # tr{} SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $replacement .= parse_q__like_balanced($1); }                                    # tr{} SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { $replacement .= parse_q__like_endswith($1); }                                    # tr{} SPACE /.../
                elsif (/\G ( [\S] )         /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                    # tr{} SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        elsif (m{\G( [/] )        }xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); }       # tr/.../.../
        elsif (/\G ( [\S] )       /xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); }       # tr?...?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;                                                                             # tr SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); } # tr SPACE A...A...A
            elsif (/\G ( ['] )          /xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); } # tr SPACE '...'...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $search .= parse_q__like_balanced($1);                                               # tr SPACE {...}...
                if    (/\G ( [#] )        /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                      # tr SPACE {}#...#
                elsif (/\G ( ['] )        /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                      # tr SPACE {}'...'
                elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $replacement .= parse_q__like_balanced($1); }                                      # tr SPACE {}{...}
                elsif (m{\G( [/] )        }xmsgc) { $replacement .= parse_q__like_endswith($1); }                                      # tr SPACE {}/.../
                elsif (/\G ( [\S] )       /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                      # tr SPACE {}?...?
                elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                    # tr SPACE {} SPACE ...
                    while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                        $comment .= $1;
                    }
                    if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                # tr SPACE {} SPACE A...A
                    elsif (/\G ( ['] )          /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                # tr SPACE {} SPACE '...'
                    elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $replacement .= parse_q__like_balanced($1); }                                # tr SPACE {} SPACE {...}
                    elsif (m{\G( [/] )          }xmsgc) { $replacement .= parse_q__like_endswith($1); }                                # tr SPACE {} SPACE /.../
                    elsif (/\G ( [\S] )         /xmsgc) { $replacement .= parse_q__like_endswith($1); }                                # tr SPACE {} SPACE ?...?
                    else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
                }
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            elsif (m{\G( [/] )          }xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); } # tr SPACE /.../.../
            elsif (/\G ( [\S] )         /xmsgc) { $search .= parse_q__like_endswith($1); $replacement .= parse_q__like_endswith($1); } # tr SPACE ?...?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        # modifier
        my($modifier_not_r, $modifier_r) = parse_tr_modifier();
        if ($modifier_r) {
            $parsed .= sprintf(q<{[\x00-\xFF]*> .         q<}%s{mb::tr($&,q%s,q%s,'%sr')}er>,                                          $comment, $search, $replacement, $modifier_not_r);
        }
        elsif ($modifier_not_r =~ /s/) {
            # these implementations cannot return right number of codepoints replaced. if you want number, you can use mb::tr().
            $parsed .= sprintf(q<{[\x00-\xFF]*> .         q<}%s{mb::tr($&,q%s,q%s,'%sr')}e>,                                           $comment, $search, $replacement, $modifier_not_r);
#           $parsed .= sprintf(q<{(\\G${mb::_anchor})(%s+)}%s{$1.mb::tr($2,q%s,q%s,'%sr')}eg>, codepoint_tr($search, $modifier_not_r), $comment, $search, $replacement, $modifier_not_r);
        }
        else {
            $parsed .= sprintf(q<{(\\G${mb::_anchor})(%s)}%s{$1.mb::tr($2,q%s,q%s,'%sr')}eg>, codepoint_tr($search, $modifier_not_r),  $comment, $search, $replacement, $modifier_not_r);
        }
        $term = 1;
    }

    # indented here document
    elsif (/\G ( <<~         ([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; $term = 1; }
    elsif (/\G ( <<~       \\([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'q' ]; $term = 1; }
    elsif (/\G ( <<~ [\t ]* '([A-Za-z_][A-Za-z_0-9]*)' ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'q' ]; $term = 1; }
    elsif (/\G ( <<~ [\t ]* "([A-Za-z_][A-Za-z_0-9]*)" ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; $term = 1; }
    elsif (/\G ( <<~ [\t ]* `([A-Za-z_][A-Za-z_0-9]*)` ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; $term = 1; }

    # here document
    elsif (/\G ( <<          ([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; $term = 1; }
    elsif (/\G ( <<        \\([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'q' ]; $term = 1; }
    elsif (/\G ( <<  [\t ]* '([A-Za-z_][A-Za-z_0-9]*)' ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'q' ]; $term = 1; }
    elsif (/\G ( <<  [\t ]* "([A-Za-z_][A-Za-z_0-9]*)" ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; $term = 1; }
    elsif (/\G ( <<  [\t ]* `([A-Za-z_][A-Za-z_0-9]*)` ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; $term = 1; }

    # sub subroutine();
    elsif (/\G ( sub \s+ [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* \s* ) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # while (<<>>)
    elsif (/\G ( while \s* \( \s* ) ( <<>> ) ( \s* \) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
        $parsed .= $3;
        $term = 0;
    }

    # while (<${file}>)
    # while (<$file>)
    # while (<FILE>)
    # while (<fileglob>)
    elsif (/\G ( while \s* \( \s* ) (<) ((?:(?!\s)${mb::x})*?) (>) ( \s* \) ) /xmsgc) {
        $parsed .= $1;
        my($open_bracket, $quotee, $close_bracket) = ($2, $3, $4);
        my $close_bracket2 = $5;
        $parsed .= $open_bracket;
        while ($quotee =~ /\G (${mb::x}) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $parsed .= $close_bracket2;
        $term = 0;
    }

    # while <<>>
    elsif (/\G ( while \s* ) ( <<>> ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
        $term = 0;
    }

    # while <${file}>
    # while <$file>
    # while <FILE>
    # while <fileglob>
    elsif (/\G ( while \s* ) (<) ((?:(?!\s)${mb::x})*?) (>) /xmsgc) {
        $parsed .= $1;
        my($open_bracket, $quotee, $close_bracket) = ($2, $3, $4);
        $parsed .= $open_bracket;
        while ($quotee =~ /\G (${mb::x}) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $term = 0;
    }

    # if     (expr)
    # elsif  (expr)
    # unless (expr)
    # while  (expr)
    # until  (expr)
    # given  (expr)
    # when   (expr)
    elsif (/\G ( (?: if | elsif | unless | while | until | given | when ) \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;

        # outputs expr
        my $expr = parse_expr_balanced($2);
        $parsed .= $expr;
        $term = 0;
    }

    # else
    elsif (/\G ( else ) \b /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # ... if     expr;
    # ... unless expr;
    # ... while  expr;
    # ... until  expr;
    elsif (/\G ( if | unless | while | until ) \b /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # foreach my $var (expr) --> foreach my $var (expr)
    # for     my $var (expr) --> for     my $var (expr)
    elsif (/\G ( (?: foreach | for ) \s+ my \s* [\$] [A-Za-z_][A-Za-z_0-9]* ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $term = 0;
    }

    # foreach $var (expr) --> foreach $var (expr)
    # for     $var (expr) --> for     $var (expr)
    elsif (/\G ( (?: foreach | for ) \s* [\$] [\$]* (?: \{[A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)*\} | [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]* ) ) ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $term = 0;
    }

    # foreach (expr1; expr2; expr3) --> foreach (expr1; expr2; expr3)
    # foreach (expr)                --> foreach (expr)
    # for     (expr1; expr2; expr3) --> for     (expr1; expr2; expr3)
    # for     (expr)                --> for     (expr)
    elsif (/\G ( (?: foreach | for ) \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $term = 0;
    }

    # CORE::split --> CORE::split
    elsif (/\G ( CORE::split ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # split --> mb::_split by default
    elsif (/\G (?: mb:: )? ( split ) \b /xmsgc) {
        $parsed .= "mb::_split";

        # parse \s and '('
        while (1) {
            if (/\G ( \s+ ) /xmsgc) {
                $parsed .= $1;
            }
            elsif (/\G ( \( ) /xmsgc) {
                $parsed .= $1;
            }
            elsif (/\G ( \# .* \n ) /xmgc) {
                $parsed .= $1;
                last;
            }
            else {
                last;
            }
        }
        my $regexp = '';

        # split /^/   --> mb::split qr/^/m
        # split /.../ --> mb::split qr/.../
        if (m{\G ( [/] )  }xmsgc) {
            $parsed .= "qr";
            $regexp = parse_re_endswith('m',$1);                                                   # split /.../
            my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

            # P.794 29.2.161. split
            # in Chapter 29: Functions
            # of ISBN 0-596-00027-8 Programming Perl Third Edition.

            # P.951 split
            # in Chapter 27: Functions
            # of ISBN 978-0-596-00492-7 Programming Perl 4th Edition.

            # said "The //m modifier is assumed when you split on the pattern /^/",
            # but perl5.008 is not so. Therefore, this software adds //m.
            # (and so on)

            if ($modifier_not_cegir !~ /m/xms) {
                $modifier_not_cegir .= 'm';
            }

            # /i modifier
            if ($modifier_i) {
                $parsed .= sprintf('{@{[mb::_ignorecase(qr%s%s)]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
            else {
                $parsed .= sprintf('{@{[' .            'qr%s%s ]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
        }

        # split m/^/   --> mb::split qr/^/m
        # split m/.../ --> mb::split qr/.../
        elsif (/\G ( m | qr ) \b /xmsgc) {
            $parsed .= "qr";

            if    (/\G ( [#] )        /xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr#...#
            elsif (/\G ( ['] )        /xmsgc) { $regexp = parse_re_as_q_endswith('m',$1); }        # split qr'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp = parse_re_balanced('m',$1);      }        # split qr{...}
            elsif (m{\G( [/] )        }xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr/.../
            elsif (/\G ( [:\@] )      /xmsgc) { $regexp = '`' . quotee_of(parse_re_endswith('m',$1)) . '`'; } # split qr@...@
            elsif (/\G ( [\S] )       /xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr?...?
            elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp = $1;                       # split qr SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $parsed .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); } # split qr SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('m',$1);      } # split qr SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE /.../
                elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= '`' . quotee_of(parse_re_endswith('m',$1)) . '`'; } # split qr SPACE @...@
                elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

            my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

            if ($modifier_not_cegir !~ /m/xms) {
                $modifier_not_cegir .= 'm';
            }

            # /i modifier
            if ($modifier_i) {
                $parsed .= sprintf('{@{[mb::_ignorecase(qr%s%s)]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
            else {
                $parsed .= sprintf('{@{[' .            'qr%s%s ]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
        }

        $term = 1;
    }

    # provides bare Perl and JPerl compatible functions
    elsif (/\G ( (?: lc | lcfirst | uc | ucfirst ) ) \b /xmsgc) {
        $parsed .= "mb::$1";
        $term = 1;
    }

    # CORE::function, mb::subroutine, function
    elsif (/\G (?: mb:: )? ( require ) (?= \s+ [0-9] ) /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }
    elsif (/\G (?: mb:: )? ( require ) \b /xmsgc) {
        $parsed .= "mb::$1";
        $term = 1;
    }
    elsif (/\G ( CORE::require ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }
    elsif (/\G ( (?: CORE:: | mb:: )? (?: chop | chr | getc | index | lc | lcfirst | length | ord | reverse | rindex | substr | uc | ucfirst ) ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # mb::subroutine
    elsif (/\G ( mb:: (?: index_byte | rindex_byte ) ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # CORE::function, function
    elsif (/\G ( (?: CORE:: )? (?: _ | abs | chomp | cos | exp | fc | hex | int | __LINE__ | log | oct | pop | pos | quotemeta | rand | rmdir | shift | sin | sqrt | tell | time | umask | wantarray ) ) \b /xmsgc) {
        $parsed .= $1;
        $term = 1;
    }

    # function --> mb::subroutine on MSWin32
    # implements run on any systems by transpiling once
    elsif (/\G ( chdir | lstat | opendir | stat | unlink ) \b /xmsgc) {
        $parsed .= "mb::_$1";
        $term = 1;
    }

    # any word
    # "\x5F" [_] LOW LINE (U+005F)
    # "\x41" [A] LATIN CAPITAL LETTER A (U+0041)
    # "\x42" [B] LATIN CAPITAL LETTER B (U+0042)
    # "\x43" [C] LATIN CAPITAL LETTER C (U+0043)
    # "\x44" [D] LATIN CAPITAL LETTER D (U+0044)
    # "\x45" [E] LATIN CAPITAL LETTER E (U+0045)
    # "\x46" [F] LATIN CAPITAL LETTER F (U+0046)
    # "\x47" [G] LATIN CAPITAL LETTER G (U+0047)
    # "\x48" [H] LATIN CAPITAL LETTER H (U+0048)
    # "\x49" [I] LATIN CAPITAL LETTER I (U+0049)
    # "\x4A" [J] LATIN CAPITAL LETTER J (U+004A)
    # "\x4B" [K] LATIN CAPITAL LETTER K (U+004B)
    # "\x4C" [L] LATIN CAPITAL LETTER L (U+004C)
    # "\x4D" [M] LATIN CAPITAL LETTER M (U+004D)
    # "\x4E" [N] LATIN CAPITAL LETTER N (U+004E)
    # "\x4F" [O] LATIN CAPITAL LETTER O (U+004F)
    # "\x50" [P] LATIN CAPITAL LETTER P (U+0050)
    # "\x51" [Q] LATIN CAPITAL LETTER Q (U+0051)
    # "\x52" [R] LATIN CAPITAL LETTER R (U+0052)
    # "\x53" [S] LATIN CAPITAL LETTER S (U+0053)
    # "\x54" [T] LATIN CAPITAL LETTER T (U+0054)
    # "\x55" [U] LATIN CAPITAL LETTER U (U+0055)
    # "\x56" [V] LATIN CAPITAL LETTER V (U+0056)
    # "\x57" [W] LATIN CAPITAL LETTER W (U+0057)
    # "\x58" [X] LATIN CAPITAL LETTER X (U+0058)
    # "\x59" [Y] LATIN CAPITAL LETTER Y (U+0059)
    # "\x5A" [Z] LATIN CAPITAL LETTER Z (U+005A)
    # "\x61" [a] LATIN SMALL LETTER A (U+0061)
    # "\x62" [b] LATIN SMALL LETTER B (U+0062)
    # "\x63" [c] LATIN SMALL LETTER C (U+0063)
    # "\x64" [d] LATIN SMALL LETTER D (U+0064)
    # "\x65" [e] LATIN SMALL LETTER E (U+0065)
    # "\x66" [f] LATIN SMALL LETTER F (U+0066)
    # "\x67" [g] LATIN SMALL LETTER G (U+0067)
    # "\x68" [h] LATIN SMALL LETTER H (U+0068)
    # "\x69" [i] LATIN SMALL LETTER I (U+0069)
    # "\x6A" [j] LATIN SMALL LETTER J (U+006A)
    # "\x6B" [k] LATIN SMALL LETTER K (U+006B)
    # "\x6C" [l] LATIN SMALL LETTER L (U+006C)
    # "\x6D" [m] LATIN SMALL LETTER M (U+006D)
    # "\x6E" [n] LATIN SMALL LETTER N (U+006E)
    # "\x6F" [o] LATIN SMALL LETTER O (U+006F)
    # "\x70" [p] LATIN SMALL LETTER P (U+0070)
    # "\x71" [q] LATIN SMALL LETTER Q (U+0071)
    # "\x72" [r] LATIN SMALL LETTER R (U+0072)
    # "\x73" [s] LATIN SMALL LETTER S (U+0073)
    # "\x74" [t] LATIN SMALL LETTER T (U+0074)
    # "\x75" [u] LATIN SMALL LETTER U (U+0075)
    # "\x76" [v] LATIN SMALL LETTER V (U+0076)
    # "\x77" [w] LATIN SMALL LETTER W (U+0077)
    # "\x78" [x] LATIN SMALL LETTER X (U+0078)
    # "\x79" [y] LATIN SMALL LETTER Y (U+0079)
    # "\x7A" [z] LATIN SMALL LETTER Z (U+007A)
    elsif (/\G ( [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # any US-ASCII
    # "\x3A" [:] COLON (U+003A)
    # "\x29" [)] RIGHT PARENTHESIS (U+0029)
    # "\x7D" [}] RIGHT CURLY BRACKET (U+007D)
    # "\x5D" []] RIGHT SQUARE BRACKET (U+005D)
    elsif (/\G ([\x00-\x7F]) /xmsgc) {
        $parsed .= $1;
        $term = 0;
    }

    # otherwise
    elsif (/\G (${mb::x}) /xmsgc) {
        die "$0(@{[__LINE__]}): can't parse not US-ASCII '$1'.\n";
    }

    return $parsed;
}

#---------------------------------------------------------------------
# parse expression in balanced blackets
sub parse_expr_balanced ($) {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    $term = 0;
    while (1) {

        # open bracket
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $term = 0;
            $nest_bracket++;
        }

        # close bracket
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
            $term = 1;
            if (--$nest_bracket <= 0) {
                last;
            }
        }

        # otherwise
        else {
            $parsed .= parse_expr();
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse <<'HERE_DOCUMENT' as q-like
sub parse_heredocument_as_q_endswith ($) {
    my($endswith) = @_;
    my $parsed = '';
    while (1) {
        if (/\G ($endswith) /xmsgc) {
            $parsed .= $1;
            last;
        }
        elsif (/\G (${mb::x}) /xmsgc) {
            $parsed .= $1;
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse <<"HERE_DOCUMENT" as qq-like
sub parse_heredocument_as_qq_endswith ($) {
    my($endswith) = @_;
    my $parsed = '';
    my $nest_escape = 0;
    while (1) {
        if (/\G ($endswith) /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $parsed .= "\n" if CORE::length($1) >= 2; # here document
            $parsed .= $1;
            last;
        }

        # \L\u --> \u\L
        elsif (/\G \\L \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G \\U \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G \\L /xmsgc) {
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G \\U /xmsgc) {
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G \\Q /xmsgc) {
            $parsed .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G \\E /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        # \o{...}
        elsif (/\G \\o\{ (.*?) \} /xmsgc) {
            $parsed .= escape_to_hex(mb::chr(oct $1), '\\');
        }

        # \x{...}
        elsif (/\G \\x\{ (.*?) \} /xmsgc) {
            $parsed .= escape_to_hex(mb::chr(hex $1), '\\');
        }

        # \any
        elsif (/\G (\\) (${mb::x}) /xmsgc) {
            $parsed .= ($1 . escape_qq($2, '\\'));
        }

        # $`           --> @{[mb::_PREMATCH()]}
        # ${`}         --> @{[mb::_PREMATCH()]}
        # $PREMATCH    --> @{[mb::_PREMATCH()]}
        # ${PREMATCH}  --> @{[mb::_PREMATCH()]}
        # ${^PREMATCH} --> @{[mb::_PREMATCH()]}
        elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
            $parsed .= '@{[mb::_PREMATCH()]}';
        }

        # $&        --> @{[mb::_MATCH()]}
        # ${&}      --> @{[mb::_MATCH()]}
        # $MATCH    --> @{[mb::_MATCH()]}
        # ${MATCH}  --> @{[mb::_MATCH()]}
        # ${^MATCH} --> @{[mb::_MATCH()]}
        elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
            $parsed .= '@{[mb::_MATCH()]}';
        }

        # $1 --> @{[mb::_CAPTURE(1)]}
        # $2 --> @{[mb::_CAPTURE(2)]}
        # $3 --> @{[mb::_CAPTURE(3)]}
        elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
            $parsed .= "\@{[mb::_CAPTURE($1)]}";
        }

        # @{^CAPTURE} --> @{[join $", mb::_CAPTURE()]}
        elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
            $parsed .= '@{[join $", mb::_CAPTURE()]}';
        }

        # ${^CAPTURE}[0] --> @{[mb::_CAPTURE(1)]}
        # ${^CAPTURE}[1] --> @{[mb::_CAPTURE(2)]}
        # ${^CAPTURE}[2] --> @{[mb::_CAPTURE(3)]}
        elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
            my $n_th = quotee_of(parse_expr_balanced($1));
            $parsed .= "\@{[mb::_CAPTURE($n_th+1)]}";
        }

        # @-                   --> @{[mb::_LAST_MATCH_START()]}
        # @LAST_MATCH_START    --> @{[mb::_LAST_MATCH_START()]}
        # @{LAST_MATCH_START}  --> @{[mb::_LAST_MATCH_START()]}
        # @{^LAST_MATCH_START} --> @{[mb::_LAST_MATCH_START()]}
        elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
            $parsed .= '@{[mb::_LAST_MATCH_START()]}';
        }

        # $-[1]                   --> @{[mb::_LAST_MATCH_START(1)]}
        # $LAST_MATCH_START[1]    --> @{[mb::_LAST_MATCH_START(1)]}
        # ${LAST_MATCH_START}[1]  --> @{[mb::_LAST_MATCH_START(1)]}
        # ${^LAST_MATCH_START}[1] --> @{[mb::_LAST_MATCH_START(1)]}
        elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
            my $n_th = quotee_of(parse_expr_balanced($1));
            $parsed .= "\@{[mb::_LAST_MATCH_START($n_th)]}";
        }

        # @+                 --> @{[mb::_LAST_MATCH_END()]}
        # @LAST_MATCH_END    --> @{[mb::_LAST_MATCH_END()]}
        # @{LAST_MATCH_END}  --> @{[mb::_LAST_MATCH_END()]}
        # @{^LAST_MATCH_END} --> @{[mb::_LAST_MATCH_END()]}
        elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
            $parsed .= '@{[mb::_LAST_MATCH_END()]}';
        }

        # $+[1]                 --> @{[mb::_LAST_MATCH_END(1)]}
        # $LAST_MATCH_END[1]    --> @{[mb::_LAST_MATCH_END(1)]}
        # ${LAST_MATCH_END}[1]  --> @{[mb::_LAST_MATCH_END(1)]}
        # ${^LAST_MATCH_END}[1] --> @{[mb::_LAST_MATCH_END(1)]}
        elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
            my $n_th = quotee_of(parse_expr_balanced($1));
            $parsed .= "\@{[mb::_LAST_MATCH_END($n_th)]}";
        }

        # any
        elsif (/\G (${mb::x}) /xmsgc) {
            $parsed .= escape_qq($1, '\\');
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse q{string} in balanced blackets
sub parse_q__like_balanced ($) {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    while (1) {
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
            if (--$nest_bracket <= 0) {
                last;
            }
        }
        elsif (/\G (\\ \Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
        }
        else {
            $parsed .= parse_q__like($close_bracket);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse q/string/ that ends with a character
sub parse_q__like_endswith ($) {
    my($endswith) = @_;
    my $parsed = $endswith;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed .= $1;
            last;
        }
        elsif (/\G (\\ \Q$endswith\E) /xmsgc) {
            $parsed .= $1;
        }
        else {
            $parsed .= parse_q__like($endswith);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse q/string/ common routine
sub parse_q__like ($) {
    my($closewith) = @_;
    if (/\G (\\\\) /xmsgc) {
        return $1;
    }
    elsif (/\G (${mb::x}) /xmsgc) {
        return escape_q($1, $closewith);
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }
}

#---------------------------------------------------------------------
# parse qq{string} in balanced blackets
sub parse_qq_like_balanced ($) {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed_as_q  = $open_bracket;
    my $parsed_as_qq = $open_bracket;
    my $nest_bracket = 1;
    my $nest_escape = 0;
    while (1) {
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            if (--$nest_bracket <= 0) {
                $parsed_as_q  .= $1;
                $parsed_as_qq .= ('>)]}' x $nest_escape);
                $parsed_as_qq .= $1;
                last;
            }
            else {
                $parsed_as_q  .= $1;
                $parsed_as_qq .= $1;
            }
        }

        # \L\u --> \u\L
        elsif (/\G (\\L \\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G (\\U \\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G (\\L) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G (\\U) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G (\\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G (\\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G (\\Q) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G (\\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            my($as_qq, $as_q) = parse_qq_like($close_bracket);
            $parsed_as_q  .= $as_q;
            $parsed_as_qq .= $as_qq;
        }
    }

    # return qq-like and q-like quotee
    if (wantarray) {
        return ($parsed_as_qq, $parsed_as_q);
    }
    else {
        return $parsed_as_qq;
    }
}

#---------------------------------------------------------------------
# parse qq/string/ that ends with a character
sub parse_qq_like_endswith ($) {
    my($endswith) = @_;
    my $parsed_as_q  = $endswith;
    my $parsed_as_qq = $endswith;
    my $nest_escape = 0;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= ('>)]}' x $nest_escape);
            $parsed_as_qq .= "\n" if CORE::length($1) >= 2; # here document
            $parsed_as_qq .= $1;
            last;
        }

        # \L\u --> \u\L
        elsif (/\G (\\L \\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G (\\U \\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G (\\L) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G (\\U) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G (\\l) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G (\\u) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G (\\Q) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G (\\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            my($as_qq, $as_q) = parse_qq_like($endswith);
            $parsed_as_q  .= $as_q;
            $parsed_as_qq .= $as_qq;
        }
    }

    # return qq-like and q-like quotee
    if (wantarray) {
        return ($parsed_as_qq, $parsed_as_q);
    }
    else {
        return $parsed_as_qq;
    }
}

#---------------------------------------------------------------------
# parse qq/string/ common routine
sub parse_qq_like ($) {
    my($closewith) = @_;
    my $parsed_as_q  = '';
    my $parsed_as_qq = '';

    # \o{...}
    if (/\G ( \\o\{ (.*?) \} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= escape_to_hex(mb::chr(oct $2), $closewith);
    }

    # \x{...}
    elsif (/\G ( \\x\{ (.*?) \} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= escape_to_hex(mb::chr(hex $2), $closewith);
    }

    # \any
    elsif (/\G ( (\\) (${mb::x}) ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= ($2 . escape_qq($3, $closewith));
    }

    # $`           --> @{[mb::_PREMATCH()]}
    # ${`}         --> @{[mb::_PREMATCH()]}
    # $PREMATCH    --> @{[mb::_PREMATCH()]}
    # ${PREMATCH}  --> @{[mb::_PREMATCH()]}
    # ${^PREMATCH} --> @{[mb::_PREMATCH()]}
    elsif (/\G ( \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_PREMATCH()]}';
    }

    # $&        --> @{[mb::_MATCH()]}
    # ${&}      --> @{[mb::_MATCH()]}
    # $MATCH    --> @{[mb::_MATCH()]}
    # ${MATCH}  --> @{[mb::_MATCH()]}
    # ${^MATCH} --> @{[mb::_MATCH()]}
    elsif (/\G ( \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_MATCH()]}';
    }

    # $1 --> @{[mb::_CAPTURE(1)]}
    # $2 --> @{[mb::_CAPTURE(2)]}
    # $3 --> @{[mb::_CAPTURE(3)]}
    elsif (/\G ( \$ ([1-9][0-9]*) ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= "\@{[mb::_CAPTURE($2)]}";
    }

    # @{^CAPTURE} --> @{[join $", mb::_CAPTURE()]}
    elsif (/\G ( \@\{\^CAPTURE\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[join $", mb::_CAPTURE()]}';
    }

    # ${^CAPTURE}[0] --> @{[mb::_CAPTURE(1)]}
    # ${^CAPTURE}[1] --> @{[mb::_CAPTURE(2)]}
    # ${^CAPTURE}[2] --> @{[mb::_CAPTURE(3)]}
    elsif (/\G (\$\{\^CAPTURE\}) \s* (\[) /xmsgc) {
        my $indexing = parse_expr_balanced($2);
        $parsed_as_q  .= ($1 . $indexing);
        my $n_th = quotee_of($indexing);
        $parsed_as_qq .= "\@{[mb::_CAPTURE($n_th)]}";
    }

    # @-                   --> @{[mb::_LAST_MATCH_START()]}
    # @LAST_MATCH_START    --> @{[mb::_LAST_MATCH_START()]}
    # @{LAST_MATCH_START}  --> @{[mb::_LAST_MATCH_START()]}
    # @{^LAST_MATCH_START} --> @{[mb::_LAST_MATCH_START()]}
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed_as_q  .= $&;
        $parsed_as_qq .= '@{[mb::_LAST_MATCH_START()]}';
    }

    # $-[1]                   --> @{[mb::_LAST_MATCH_START(1)]}
    # $LAST_MATCH_START[1]    --> @{[mb::_LAST_MATCH_START(1)]}
    # ${LAST_MATCH_START}[1]  --> @{[mb::_LAST_MATCH_START(1)]}
    # ${^LAST_MATCH_START}[1] --> @{[mb::_LAST_MATCH_START(1)]}
    elsif (/\G ( \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $indexing = parse_expr_balanced($2);
        $parsed_as_q  .= ($1 . $indexing);
        my $n_th = quotee_of($indexing);
        $parsed_as_qq .= "\@{[mb::_LAST_MATCH_START($n_th)]}";
    }

    # @+                 --> @{[mb::_LAST_MATCH_END()]}
    # @LAST_MATCH_END    --> @{[mb::_LAST_MATCH_END()]}
    # @{LAST_MATCH_END}  --> @{[mb::_LAST_MATCH_END()]}
    # @{^LAST_MATCH_END} --> @{[mb::_LAST_MATCH_END()]}
    elsif (/\G ( \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_LAST_MATCH_END()]}';
    }

    # $+[1]                 --> @{[mb::_LAST_MATCH_END(1)]}
    # $LAST_MATCH_END[1]    --> @{[mb::_LAST_MATCH_END(1)]}
    # ${LAST_MATCH_END}[1]  --> @{[mb::_LAST_MATCH_END(1)]}
    # ${^LAST_MATCH_END}[1] --> @{[mb::_LAST_MATCH_END(1)]}
    elsif (/\G ( \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $indexing = parse_expr_balanced($2);
        $parsed_as_q  .= ($1 . $indexing);
        my $n_th = quotee_of($indexing);
        $parsed_as_qq .= "\@{[mb::_LAST_MATCH_END($n_th)]}";
    }

    # any
    elsif (/\G (${mb::x}) /xmsgc) {
        $parsed_as_q  .= escape_q ($1, $closewith);
        $parsed_as_qq .= escape_qq($1, $closewith);
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }

    # return qq-like and q-like quotee
    if (wantarray) {
        return ($parsed_as_qq, $parsed_as_q);
    }
    else {
        return $parsed_as_qq;
    }
}

#---------------------------------------------------------------------
# parse code point class
sub parse_re_codepoint_class ($) {
    my($classmate) = @_;
    my $parsed = '';
    my @sbcs = ();
    my @xbcs = (); # "xbcs" means DBCS, TBCS, QBCS, ...
    while (1) {
        if ($classmate =~ /\G \z /xmsgc) {
            $parsed =
                ( @sbcs and  @xbcs) ? join('|', @xbcs, '['.join('',@sbcs).']') :
                (!@sbcs and  @xbcs) ? join('|', @xbcs                        ) :
                ( @sbcs and !@xbcs) ?                  '['.join('',@sbcs).']'  :
                die;
            last;
        }
        elsif ($classmate =~ /\G (\\ \]) /xmsgc) {
            push @sbcs, $1;
        }
        elsif ($classmate =~ /\G (\\\\) /xmsgc) {
            push @sbcs, $1;
        }

        # classic perl codepoint class shortcuts
        elsif ($classmate =~ /\G \\D /xmsgc) { push @xbcs, "(?:(?![$mb::bare_d])${mb::x})"; }
        elsif ($classmate =~ /\G \\H /xmsgc) { push @xbcs, "(?:(?![$mb::bare_h])${mb::x})"; }
#       elsif ($classmate =~ /\G \\N /xmsgc) { push @xbcs, "(?:(?!\\n)${mb::x})";           } # \N in a codepoint class must be a named character: \N{...} in regex
#       elsif ($classmate =~ /\G \\R /xmsgc) { push @xbcs, "(?>\\r\\n|[$mb::bare_v])";      } # Unrecognized escape \R in codepoint class passed through in regex
        elsif ($classmate =~ /\G \\S /xmsgc) { push @xbcs, "(?:(?![$mb::bare_s])${mb::x})"; }
        elsif ($classmate =~ /\G \\V /xmsgc) { push @xbcs, "(?:(?![$mb::bare_v])${mb::x})"; }
        elsif ($classmate =~ /\G \\W /xmsgc) { push @xbcs, "(?:(?![$mb::bare_w])${mb::x})"; }
        elsif ($classmate =~ /\G \\b /xmsgc) { push @sbcs, $mb::bare_backspace;             }
        elsif ($classmate =~ /\G \\d /xmsgc) { push @sbcs, $mb::bare_d;                     }
        elsif ($classmate =~ /\G \\h /xmsgc) { push @sbcs, $mb::bare_h;                     }
        elsif ($classmate =~ /\G \\s /xmsgc) { push @sbcs, $mb::bare_s;                     }
        elsif ($classmate =~ /\G \\v /xmsgc) { push @sbcs, $mb::bare_v;                     }
        elsif ($classmate =~ /\G \\w /xmsgc) { push @sbcs, $mb::bare_w;                     }

        # [:POSIX:]
        elsif ($classmate =~ /\G \[:alnum:\]  /xmsgc) { push @sbcs, '\x30-\x39\x41-\x5A\x61-\x7A';                  }
        elsif ($classmate =~ /\G \[:alpha:\]  /xmsgc) { push @sbcs, '\x41-\x5A\x61-\x7A';                           }
        elsif ($classmate =~ /\G \[:ascii:\]  /xmsgc) { push @sbcs, '\x00-\x7F';                                    }
        elsif ($classmate =~ /\G \[:blank:\]  /xmsgc) { push @sbcs, '\x09\x20';                                     }
        elsif ($classmate =~ /\G \[:cntrl:\]  /xmsgc) { push @sbcs, '\x00-\x1F\x7F';                                }
        elsif ($classmate =~ /\G \[:digit:\]  /xmsgc) { push @sbcs, '\x30-\x39';                                    }
        elsif ($classmate =~ /\G \[:graph:\]  /xmsgc) { push @sbcs, '\x21-\x7F';                                    }
        elsif ($classmate =~ /\G \[:lower:\]  /xmsgc) { push @sbcs, 'abcdefghijklmnopqrstuvwxyz';                   } # /i modifier requires 'a' to 'z' literally
        elsif ($classmate =~ /\G \[:print:\]  /xmsgc) { push @sbcs, '\x20-\x7F';                                    }
        elsif ($classmate =~ /\G \[:punct:\]  /xmsgc) { push @sbcs, '\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E'; }
        elsif ($classmate =~ /\G \[:space:\]  /xmsgc) { push @sbcs, '\s\x0B';                                       } # "\s" and vertical tab ("\cK")
        elsif ($classmate =~ /\G \[:upper:\]  /xmsgc) { push @sbcs, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';                   } # /i modifier requires 'A' to 'Z' literally
        elsif ($classmate =~ /\G \[:word:\]   /xmsgc) { push @sbcs, '\x30-\x39\x41-\x5A\x5F\x61-\x7A';              }
        elsif ($classmate =~ /\G \[:xdigit:\] /xmsgc) { push @sbcs, '\x30-\x39\x41-\x46\x61-\x66';                  }

        # [:^POSIX:]
        elsif ($classmate =~ /\G \[:\^alnum:\]  /xmsgc) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x61-\\x7A])${mb::x})";                      }
        elsif ($classmate =~ /\G \[:\^alpha:\]  /xmsgc) { push @xbcs, "(?:(?![\\x41-\\x5A\\x61-\\x7A])${mb::x})";                                 }
        elsif ($classmate =~ /\G \[:\^ascii:\]  /xmsgc) { push @xbcs, "(?:(?![\\x00-\\x7F])${mb::x})";                                            }
        elsif ($classmate =~ /\G \[:\^blank:\]  /xmsgc) { push @xbcs, "(?:(?![\\x09\\x20])${mb::x})";                                             }
        elsif ($classmate =~ /\G \[:\^cntrl:\]  /xmsgc) { push @xbcs, "(?:(?![\\x00-\\x1F\\x7F])${mb::x})";                                       }
        elsif ($classmate =~ /\G \[:\^digit:\]  /xmsgc) { push @xbcs, "(?:(?![\\x30-\\x39])${mb::x})";                                            }
        elsif ($classmate =~ /\G \[:\^graph:\]  /xmsgc) { push @xbcs, "(?:(?![\\x21-\\x7F])${mb::x})";                                            }
        elsif ($classmate =~ /\G \[:\^lower:\]  /xmsgc) { push @xbcs, "(?:(?![abcdefghijklmnopqrstuvwxyz])${mb::x})";                             } # /i modifier requires 'a' to 'z' literally
        elsif ($classmate =~ /\G \[:\^print:\]  /xmsgc) { push @xbcs, "(?:(?![\\x20-\\x7F])${mb::x})";                                            }
        elsif ($classmate =~ /\G \[:\^punct:\]  /xmsgc) { push @xbcs, "(?:(?![\\x21-\\x2F\\x3A-\\x3F\\x40\\x5B-\\x5F\\x60\\x7B-\\x7E])${mb::x})"; }
        elsif ($classmate =~ /\G \[:\^space:\]  /xmsgc) { push @xbcs, "(?:(?![\\s\\x0B])${mb::x})";                                               } # "\s" and vertical tab ("\cK")
        elsif ($classmate =~ /\G \[:\^upper:\]  /xmsgc) { push @xbcs, "(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZ])${mb::x})";                             } # /i modifier requires 'A' to 'Z' literally
        elsif ($classmate =~ /\G \[:\^word:\]   /xmsgc) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x5F\\x61-\\x7A])${mb::x})";                 }
        elsif ($classmate =~ /\G \[:\^xdigit:\] /xmsgc) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x46\\x61-\\x66])${mb::x})";                      }

        # \o{...}
        elsif ($classmate =~ /\G \\o\{ (.*?) \} /xmsgc) {
            push @xbcs, '(?:' . escape_to_hex(mb::chr(oct $1), ']') . ')';
        }

        # \x{...}
        elsif ($classmate =~ /\G \\x\{ (.*?) \} /xmsgc) {
            push @xbcs, '(?:' . escape_to_hex(mb::chr(hex $1), ']') . ')';
        }

        # \any
        elsif ($classmate =~ /\G (\\) (${mb::x}) /xmsgc) {
            if (CORE::length($2) == 1) {
                push @sbcs, ($1 . $2);
            }
            else {
                push @xbcs, '(?:' . $1 . escape_to_hex($2, ']') . ')';
            }
        }

        # supported character ranges
        elsif ($classmate =~ /\G ((?:[\x20-\x7E]|\\[0-3][0-7][0-7]|\\x[0-9A-Fa-f][0-9A-Fa-f])-(?:[\x20-\x7E]|\\[0-3][0-7][0-7]|\\x[0-9A-Fa-f][0-9A-Fa-f])) /xmsgc) {
            push @sbcs, $1;
        }

        # other character ranges are no longer supported
        # range specification by '-' in codepoint class of regular expression supports US-ASCII only
        # this limitation makes it easier to change the script encoding
        elsif ($classmate =~ /\G (-) /xmsgc) {
            if ($^W) {
                Carp::carp <<END;
[$parsed...] in regular expression

range specification by '-' in codepoint class of regular expression supports US-ASCII only.
this limitation makes it easier to change the script encoding.
END
            }
            push @sbcs, '\\x2D';
        }

        # any
        elsif ($classmate =~ /\G (${mb::x}) /xmsgc) {
            if (CORE::length($1) == 1) {
                push @sbcs, $1;
            }
            else {
                push @xbcs, '(?:' . escape_to_hex($1, ']') . ')';
            }
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr'regexp' as q-like
sub parse_re_as_q_endswith ($$) {
    my($operator, $endswith) = @_;
    my $parsed = $endswith;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed .= $1;
            last;
        }

        # get codepoint class
        elsif (/\G \[ /xmsgc) {
            my $classmate = '';
            while (1) {
                if (/\G \] /xmsgc) {
                    last;
                }
                elsif (/\G (\[:\^[a-z]*:\]) /xmsgc) {
                    $classmate .= $1;
                }
                elsif (/\G (\[:[a-z]*:\]) /xmsgc) {
                    $classmate .= $1;
                }
                elsif (/\G (${mb::x}) /xmsgc) {
                    $classmate .= $1;
                }

                # something wrong happened
                else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
                }
            }

            # parse codepoint class
            if ($classmate =~ s{\A \^ }{}xms) {
                $parsed .= '(?:(?!';
                $parsed .= parse_re_codepoint_class($classmate);
                $parsed .= ")${mb::x})";
            }
            else {
                $parsed .= '(?:(?=';
                $parsed .= parse_re_codepoint_class($classmate);
                $parsed .= ")${mb::x})";
            }
        }

        # /./ or \any
        elsif (/\G \.  /xmsgc) { $parsed .= "(?:${mb::over_ascii}|.)";       } # after ${mb::over_ascii}, /s modifier wants "." (not [\x00-\xFF])
        elsif (/\G \\B /xmsgc) { $parsed .= "(?:(?<![$mb::bare_w])(?![$mb::bare_w])|(?<=[$mb::bare_w])(?=[$mb::bare_w]))"; }
        elsif (/\G \\D /xmsgc) { $parsed .= "(?:(?![$mb::bare_d])${mb::x})"; }
        elsif (/\G \\H /xmsgc) { $parsed .= "(?:(?![$mb::bare_h])${mb::x})"; }
        elsif (/\G \\N /xmsgc) { $parsed .= "(?:(?!\\n)${mb::x})";           }
        elsif (/\G \\R /xmsgc) { $parsed .= "(?>\\r\\n|[$mb::bare_v])";      }
        elsif (/\G \\S /xmsgc) { $parsed .= "(?:(?![$mb::bare_s])${mb::x})"; }
        elsif (/\G \\V /xmsgc) { $parsed .= "(?:(?![$mb::bare_v])${mb::x})"; }
        elsif (/\G \\W /xmsgc) { $parsed .= "(?:(?![$mb::bare_w])${mb::x})"; }
        elsif (/\G \\b /xmsgc) { $parsed .= "(?:(?<![$mb::bare_w])(?=[$mb::bare_w])|(?<=[$mb::bare_w])(?![$mb::bare_w]))"; }
        elsif (/\G \\d /xmsgc) { $parsed .= "[$mb::bare_d]";                 }
        elsif (/\G \\h /xmsgc) { $parsed .= "[$mb::bare_h]";                 }
        elsif (/\G \\s /xmsgc) { $parsed .= "[$mb::bare_s]";                 }
        elsif (/\G \\v /xmsgc) { $parsed .= "[$mb::bare_v]";                 }
        elsif (/\G \\w /xmsgc) { $parsed .= "[$mb::bare_w]";                 }

        # \o{...}
        elsif (/\G \\o\{ (.*?) \} /xmsgc) {
            $parsed .= '(?:';
            $parsed .= escape_to_hex(mb::chr(oct $1), $endswith);
            $parsed .= ')';
        }

        # \x{...}
        elsif (/\G \\x\{ (.*?) \} /xmsgc) {
            $parsed .= '(?:';
            $parsed .= escape_to_hex(mb::chr(hex $1), $endswith);
            $parsed .= ')';
        }

        # \0... octal escape
        elsif (/\G (\\ 0[1-7]*) /xmsgc) {
            $parsed .= $1;
        }

        # \100...\x377 octal escape
        elsif (/\G (\\ [1-3][0-7][0-7]) /xmsgc) {
            $parsed .= $1;
        }

        # \1...\99, ... n-th previously captured string (decimal)
        elsif (/\G (\\) ([1-9][0-9]*) /xmsgc) {
            $parsed .= $1;
            if ($operator eq 's') {
                $parsed .= ($2 + 1);
            }
            else {
                $parsed .= $2;
            }
        }

        # any
        elsif (/\G (${mb::x}) /xmsgc) {
            if (CORE::length($1) == 1) {
                $parsed .= $1;
            }
            else {
                $parsed .= '(?:';
                $parsed .= escape_to_hex($1, $endswith);
                $parsed .= ')';
            }
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr{regexp} in balanced blackets
sub parse_re_balanced ($$) {
    my($operator, $open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    my $nest_escape = 0;
    while (1) {
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            if (--$nest_bracket <= 0) {
                $parsed .= ('>)]}' x $nest_escape);
                $parsed .= $1;
                last;
            }
            else {
                $parsed .= $1;
            }
        }

        # \L\u --> \u\L
        elsif (/\G \\L \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G \\U \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G \\L /xmsgc) {
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G \\U /xmsgc) {
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G \\Q /xmsgc) {
            $parsed .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G \\E /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            $parsed .= parse_re($operator, $open_bracket);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr/regexp/ that ends with a character
sub parse_re_endswith ($$) {
    my($operator, $endswith) = @_;
    my $parsed = $endswith;
    my $nest_escape = 0;
    while (1) {
        if (/\G (\Q$endswith\E) /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $parsed .= $1;
            last;
        }

        # \L\u --> \u\L
        elsif (/\G \\L \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \U\l --> \l\U
        elsif (/\G \\U \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
            $nest_escape++;
        }

        # \L
        elsif (/\G \\L /xmsgc) {
            $parsed .= '@{[mb::lc(qq<';
            $nest_escape++;
        }

        # \U
        elsif (/\G \\U /xmsgc) {
            $parsed .= '@{[mb::uc(qq<';
            $nest_escape++;
        }

        # \l
        elsif (/\G \\l /xmsgc) {
            $parsed .= '@{[mb::lcfirst(qq<';
            $nest_escape++;
        }

        # \u
        elsif (/\G \\u /xmsgc) {
            $parsed .= '@{[mb::ucfirst(qq<';
            $nest_escape++;
        }

        # \Q
        elsif (/\G \\Q /xmsgc) {
            $parsed .= '@{[quotemeta(qq<';
            $nest_escape++;
        }

        # \E
        elsif (/\G \\E /xmsgc) {
            $parsed .= ('>)]}' x $nest_escape);
            $nest_escape = 0;
        }

        else {
            $parsed .= parse_re($operator, $endswith);
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr/regexp/ common routine
sub parse_re ($$) {
    my($operator, $closewith) = @_;
    my $parsed = '';

    # codepoint class
    if (/\G \[ /xmsgc) {
        my $classmate = '';
        while (1) {
            if (/\G \] /xmsgc) {
                last;
            }
            elsif (/\G (\\) /xmsgc) {
                $classmate .= "\\$1";
            }
            elsif (/\G (\[:\^[a-z]*:\]) /xmsgc) {
                $classmate .= $1;
            }
            elsif (/\G (\[:[a-z]*:\]) /xmsgc) {
                $classmate .= $1;
            }
            elsif (/\G (${mb::x}) /xmsgc) {
                $classmate .= escape_qq($1, ']');
            }

            # something wrong happened
            else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
            }
        }
        $parsed .= "\@{[mb::_cc(qq[$classmate])]}";
    }

    # /./ or \any
    elsif (/\G \.  /xmsgc) { $parsed .= '(?:@{mb::_dot})'; }
    elsif (/\G \\B /xmsgc) { $parsed .= '(?:@{mb::_B})';   }
    elsif (/\G \\D /xmsgc) { $parsed .= '(?:@{mb::_D})';   }
    elsif (/\G \\H /xmsgc) { $parsed .= '(?:@{mb::_H})';   }
    elsif (/\G \\N /xmsgc) { $parsed .= '(?:@{mb::_N})';   }
    elsif (/\G \\R /xmsgc) { $parsed .= '(?:@{mb::_R})';   }
    elsif (/\G \\S /xmsgc) { $parsed .= '(?:@{mb::_S})';   }
    elsif (/\G \\V /xmsgc) { $parsed .= '(?:@{mb::_V})';   }
    elsif (/\G \\W /xmsgc) { $parsed .= '(?:@{mb::_W})';   }
    elsif (/\G \\b /xmsgc) { $parsed .= '(?:@{mb::_b})';   }
    elsif (/\G \\d /xmsgc) { $parsed .= '(?:@{mb::_d})';   }
    elsif (/\G \\h /xmsgc) { $parsed .= '(?:@{mb::_h})';   }
    elsif (/\G \\s /xmsgc) { $parsed .= '(?:@{mb::_s})';   }
    elsif (/\G \\v /xmsgc) { $parsed .= '(?:@{mb::_v})';   }
    elsif (/\G \\w /xmsgc) { $parsed .= '(?:@{mb::_w})';   }

    # \o{...}
    elsif (/\G \\o\{ (.*?) \} /xmsgc) {
        $parsed .= '(?:';
        $parsed .= escape_to_hex(mb::chr(oct $1), $closewith);
        $parsed .= ')';
    }

    # \x{...}
    elsif (/\G \\x\{ (.*?) \} /xmsgc) {
        $parsed .= '(?:';
        $parsed .= escape_to_hex(mb::chr(hex $1), $closewith);
        $parsed .= ')';
    }

    # \0... octal escape
    elsif (/\G (\\ 0[1-7]*) /xmsgc) {
        $parsed .= $1;
    }

    # \100...\x377 octal escape
    elsif (/\G (\\ [1-3][0-7][0-7]) /xmsgc) {
        $parsed .= $1;
    }

    # \1...\99, ... n-th previously captured string (decimal)
    elsif (/\G (\\) ([1-9][0-9]*) /xmsgc) {
        $parsed .= $1;
        if ($operator eq 's') {
            $parsed .= ($2 + 1);
        }
        else {
            $parsed .= $2;
        }
    }

    # \any
    elsif (/\G (\\) (${mb::x}) /xmsgc) {
        if (CORE::length($2) == 1) {
            $parsed .= ($1 . $2);
        }
        else {
            $parsed .= ('(?:' . $1 . escape_qq($2, $closewith) . ')');
        }
    }

    # $`           --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # ${`}         --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # $PREMATCH    --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # ${PREMATCH}  --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    # ${^PREMATCH} --> @{[mb::_clustered_codepoint(mb::_PREMATCH())]}
    elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed .= '@{[mb::_clustered_codepoint(mb::_PREMATCH())]}';
    }

    # $&        --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # ${&}      --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # $MATCH    --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # ${MATCH}  --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    # ${^MATCH} --> @{[mb::_clustered_codepoint(mb::_MATCH())]}
    elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed .= '@{[mb::_clustered_codepoint(mb::_MATCH())]}';
    }

    # $1 --> @{[mb::_clustered_codepoint(mb::_CAPTURE(1))]}
    # $2 --> @{[mb::_clustered_codepoint(mb::_CAPTURE(2))]}
    # $3 --> @{[mb::_clustered_codepoint(mb::_CAPTURE(3))]}
    elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
        $parsed .= "\@{[mb::_clustered_codepoint(mb::_CAPTURE($1))]}";
    }

    # @{^CAPTURE} --> @{[mb::_clustered_codepoint(join $", mb::_CAPTURE())]}
    elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
        $parsed .= '@{[mb::_clustered_codepoint(join $", mb::_CAPTURE())]}';
    }

    # ${^CAPTURE}[0] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(1))]}
    # ${^CAPTURE}[1] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(2))]}
    # ${^CAPTURE}[2] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(3))]}
    elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_clustered_codepoint(mb::_CAPTURE($n_th+1))]}";
    }

    # @-                   --> @{[join $", mb::_LAST_MATCH_START()]}
    # @LAST_MATCH_START    --> @{[join $", mb::_LAST_MATCH_START()]}
    # @{LAST_MATCH_START}  --> @{[join $", mb::_LAST_MATCH_START()]}
    # @{^LAST_MATCH_START} --> @{[join $", mb::_LAST_MATCH_START()]}
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed .= '@{[join $", mb::_LAST_MATCH_START()]}';
    }

    # $-[1]                   --> @{[mb::_LAST_MATCH_START(1)]}
    # $LAST_MATCH_START[1]    --> @{[mb::_LAST_MATCH_START(1)]}
    # ${LAST_MATCH_START}[1]  --> @{[mb::_LAST_MATCH_START(1)]}
    # ${^LAST_MATCH_START}[1] --> @{[mb::_LAST_MATCH_START(1)]}
    elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_LAST_MATCH_START($n_th)]}";
    }

    # @+                 --> @{[join $", mb::_LAST_MATCH_END()]}
    # @LAST_MATCH_END    --> @{[join $", mb::_LAST_MATCH_END()]}
    # @{LAST_MATCH_END}  --> @{[join $", mb::_LAST_MATCH_END()]}
    # @{^LAST_MATCH_END} --> @{[join $", mb::_LAST_MATCH_END()]}
    elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed .= '@{[join $", mb::_LAST_MATCH_END()]}';
    }

    # $+[1]                 --> @{[mb::_LAST_MATCH_END(1)]}
    # $LAST_MATCH_END[1]    --> @{[mb::_LAST_MATCH_END(1)]}
    # ${LAST_MATCH_END}[1]  --> @{[mb::_LAST_MATCH_END(1)]}
    # ${^LAST_MATCH_END}[1] --> @{[mb::_LAST_MATCH_END(1)]}
    elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_LAST_MATCH_END($n_th)]}";
    }

    # any
    elsif (/\G (${mb::x}) /xmsgc) {
        if (CORE::length($1) == 1) {
            $parsed .= $1;
        }
        else {
            $parsed .= ('(?:' . escape_qq($1, $closewith) . ')');
        }
    }

    # something wrong happened
    else {
        die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse modifiers of qr///here
sub parse_re_modifier () {
    my $modifier_i = '';
    my $modifier_not_cegir = '';
    my $modifier_cegr = '';
    while (1) {
        if (/\G [adlpu] /xmsgc) {
            # drop modifiers
        }
        elsif (/\G ([i]) /xmsgc) {
            $modifier_i .= $1;
        }
        elsif (/\G ([cegr]) /xmsgc) {
            $modifier_cegr .= $1;
        }
        elsif (/\G ([a-z]) /xmsgc) {
            $modifier_not_cegir .= $1;
        }
        else {
            last;
        }
    }
    return ($modifier_i, $modifier_not_cegir, $modifier_cegr);
}

#---------------------------------------------------------------------
# parse modifiers of tr///here
sub parse_tr_modifier () {
    my $modifier_not_r = '';
    my $modifier_r = '';
    while (1) {
        if (/\G ([r]) /xmsgc) {
            $modifier_r .= $1;
        }
        elsif (/\G ([a-z]) /xmsgc) {
            $modifier_not_r .= $1;
        }
        else {
            last;
        }
    }
    return ($modifier_not_r, $modifier_r);
}

#---------------------------------------------------------------------
# makes code point class from string
sub codepoint_tr ($$) {
    my($searchlist) = $_[0] =~ /\A [\x00-\xFF] (.*) [\x00-\xFF] \z/xms;
    my $look_ahead = ($_[1] =~ /c/) ? '(?:(?!' : '(?:(?=';
    my $charclass = '';
    my @sbcs = ();
    my @xbcs = (); # "xbcs" means DBCS, TBCS, QBCS, ...
    while (1) {
        if ($searchlist =~ /\G \z /xmsgc) {
            $charclass =
                ( @sbcs and  @xbcs) ? $look_ahead . join('|', @xbcs, '['.join('',@sbcs).']') . ")${mb::x})" :
                (!@sbcs and  @xbcs) ? $look_ahead . join('|', @xbcs                        ) . ")${mb::x})" :
                ( @sbcs and !@xbcs) ? $look_ahead .                  '['.join('',@sbcs).']'  . ")${mb::x})" :
                die;
            last;
        }

        # range specification by '-' in tr/// is not supported
        # this limitation makes it easier to change the script encoding
        elsif ($searchlist =~ /\G (-) /xmsgc) {
            if ($^W) {
                Carp::carp <<END;
"$searchlist" in tr///

range specification by '-' in tr/// is not supported.
this limitation makes it easier to change the script encoding.
END
            }
            push @sbcs, '\\x2D';
        }

        # any
        elsif ($searchlist =~ /\G (${mb::x}) /xmsgc) {
            if (CORE::length($1) == 1) {
                push @sbcs, $1;
            }
            else {
                push @xbcs, '(?:' . escape_to_hex($1, ']') . ')';
            }
        }

        # something wrong happened
        else {
            die sprintf(<<END, pos($_), CORE::substr($_,pos($_)));
$0(@{[__LINE__]}): something wrong happened in script at pos=%s
------------------------------------------------------------------------------
%s
------------------------------------------------------------------------------
END
        }
    }
    return $charclass;
}

#---------------------------------------------------------------------
# get quotee from quoted "quotee"
sub quotee_of ($) {
    if (CORE::length($_[0]) >= 2) {
        return CORE::substr($_[0],1,-1);
    }
    else {
        die;
    }
}

#---------------------------------------------------------------------
# escape q/string/ as q-like quote
sub escape_q ($$) {
    my($codepoint, $endswith) = @_;
    if ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return "$1\\$2";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ($escapee_in_q__like) \z/xms) {
        return "$1\\$2";
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------
# escape qq/string/ as qq-like quote
sub escape_qq ($$) {
    my($codepoint, $endswith) = @_;

    # m@`@    --> m`\x60`
    # qr@`@   --> qr`\x60`
    # s@`@``@ --> s`\x60`\x60\x60`
    # m:`:    --> m`\x60`
    # qr:`:   --> qr`\x60`
    # s:`:``: --> s`\x60`\x60\x60`
    if ($codepoint eq '`') {
        return '\\x60';
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return "$1\\$2";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ([$escapee_in_qq_like]) \z/xms) {
        return "$1\\$2";
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------
# escape qq/string/ or qr/regexp/ to hex
sub escape_to_hex ($$) {
    my($codepoint, $endswith) = @_;
    if ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
        return sprintf('\x%02X\x%02X', CORE::ord($1), CORE::ord($2));
    }

    # in qr'...', $escapee_in_qq_like is right, not $escapee_in_q__like
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) ([$escapee_in_qq_like]) \z/xms) {
        return sprintf('\x%02X\x%02X', CORE::ord($1), CORE::ord($2));
    }
    else {
        return $codepoint;
    }
}

#---------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

mb - run Perl script written in MBCS

=head1 SYNOPSIS

  $ perl mb.pm              MBCS_Perl_script.pl
  $ perl mb.pm -e big5      MBCS_Perl_script.pl
  $ perl mb.pm -e big5hkscs MBCS_Perl_script.pl
  $ perl mb.pm -e eucjp     MBCS_Perl_script.pl
  $ perl mb.pm -e gb18030   MBCS_Perl_script.pl
  $ perl mb.pm -e gbk       MBCS_Perl_script.pl
  $ perl mb.pm -e sjis      MBCS_Perl_script.pl
  $ perl mb.pm -e uhc       MBCS_Perl_script.pl
  $ perl mb.pm -e utf8      MBCS_Perl_script.pl

  MBCS subroutines:
    mb::chop(...);
    mb::chr(...);
    mb::dosglob(...);
    mb::getc(...);
    mb::index(...);
    mb::index_byte(...);
    mb::length(...);
    mb::ord(...);
    mb::reverse(...);
    mb::rindex(...);
    mb::rindex_byte(...);
    mb::substr(...);

  supported encodings:
    Big5, Big5-HKSCS, EUC-JP, GB18030, GBK, Sjis, UHC, UTF-8

  supported operating systems:
    Apple Inc. OS X,
    Hewlett-Packard Development Company, L.P. HP-UX,
    International Business Machines Corporation AIX,
    Microsoft Corporation Windows,
    Oracle Corporation Solaris,
    and Other Systems

  supported perl versions:
    perl version 5.005_03 to newest perl

=head1 INSTALLATION BY MAKE (for UNIX-like system)

To install this software by make, type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 INSTALLATION WITHOUT MAKE (for DOS-like system)

To install this software without make, type the following:

   pmake.bat test
   pmake.bat install

=head1 DESCRIPTION

  This software is a source code filter, transpiler-modulino.

  Perl is said to have been able to handle Unicode since version 5.8. However,
  unlike JPerl, "Easy jobs easy" has been lost. (but we have got it again :-D)

  In Shift_JIS and similar encodings(Big5, Big5HKSCS, GB18030, GBK, Sjis, UHC)
  have any DAMEMOJI at second octet in double-byte codepoint. DAMEMOJI are
  metacharacters. Which octets are DAMEMOJI depends on whether the enclosing
  delimiter is single quote or double quote. This software escapes DAMEMOJI in
  your script, generate a new script and run it.

  There are some MBCS encodings in the world.
  in Japan since 1978, JIS C 6226-1978,
  in China since 1980, GB 2312-80,
  in Taiwan since 1984, Big5,
  in South Korea since 1991, KS X 1002:1991, and more.
  Even if you are an avid Unicode proponent, you cannot change this fact. These
  encodings are still used today in most areas except the world wide web.

  This software ...
  * supports MBCS literals in Perl scripts
  * supports Big5, Big5HKSCS, EUC-JP, GB18030, GBK, Sjis, UHC, and UTF-8
  * does not use the UTF8 flag to avoid MOJIBAKE
  * escapes DAMEMOJI in scripts
  * handles raw encoding to support GAIJI
  * adds multibyte anchoring to regular expressions
  * rewrites character classes in regular expressions to work as MBCS codepoint
  * supports special variables $`, $&, and $'
  * does not change features of octet-oriented built-in functions
  * lc(), lcfirst(), uc(), and ucfirst() convert US-ASCII only
  * character ranges by hyphen of regular expression supports US-ASCII only
  * tr/// and y/// doesn't support ranges by hyphen
  * You have to write mb::* subroutines if you want codepoint semantics

  Let's enjoy MBSC scripting in Perl, together!!

=head1 TERMINOLOGY

  To understand and use this software, you must know some terminologies.
  But now I have no time for write them. So today is July 7th, I have to go to
  meet Juliet.
  The necessary terms are listed below. Maybe world wide web will help you.

=over 2

=item * byte

=item * octet

=item * encoding

=item * decode

=item * character

=item * code point

=item * grapheme

=item * SBCS(Single Byte Character Set)

=item * DBCS(Double Byte Character Set)

=item * MBCS(Multibyte Character Set)

=item * multibyte anchoring

=item * character class

=item * MOJIBAKE

=item * DAMEMOJI

=item * GAIJI

=item * GETA, GETA-MOJI, GETA-MARK

=back

=head1 MBCS Encodings supported by this software

  The encodings supported by this software and their range of octets are as
  follows.

  ------------------------------------------------------------------------------
  big5
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Big5
  ------------------------------------------------------------------------------
  big5hkscs
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Hong_Kong_Supplementary_Character_Set
  ------------------------------------------------------------------------------
  eucjp
             1st       2nd
             A1..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Extended_Unix_Code#EUC-JP
  ------------------------------------------------------------------------------
  gb18030
             1st       2nd
             81..FE    30..39    81..FE    30..39
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/GB_18030
  ------------------------------------------------------------------------------
  gbk
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/GBK_(character_encoding)
  ------------------------------------------------------------------------------
  sjis
             1st       2nd
             81..9F    00..FF
             E0..FC    00..FF
             80..FF
             00..7F
             https://en.wikipedia.org/wiki/Shift_JIS
  ------------------------------------------------------------------------------
  uhc
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Unified_Hangul_Code
  ------------------------------------------------------------------------------
  utf8
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
  ------------------------------------------------------------------------------

=head1 MBCS subroutines provided by this software

  This software provides traditional feature "as was." The new MBCS features
  are provided by subroutines with new names. If you like utf8 pragma, mb::*
  subroutines will help you. On other hand, If you love JPerl, those
  subroutines will not help you very much. Traditional functions of Perl are
  useful still now in octet-oriented semantics.

  -----------------------------------------------------------------
  bare Perl4     JPerl4                                            
  bare Perl5     JPerl5         use utf8;          mb.pm           
  bare Perl7                    pragma             modulino        
  -----------------------------------------------------------------
  chop           ---            ---                chop            
  chr            chr            bytes::chr         chr             
  getc           getc           ---                getc            
  index          ---            bytes::index       index           
  lc             lc             ---                lc              
  lcfirst        lcfirst        ---                lcfirst         
  length         length         bytes::length      length          
  ord            ord            bytes::ord         ord             
  reverse        reverse        ---                reverse         
  rindex         ---            bytes::rindex      rindex          
  substr         substr         bytes::substr      substr          
  uc             uc             ---                uc              
  ucfirst        ucfirst        ---                ucfirst         
  ---            chop           chop               mb::chop        
  ---            index          ---                mb::index_byte  
  ---            rindex         ---                mb::rindex_byte 
  ---            ---            chr                mb::chr         
  ---            ---            getc               mb::getc        
  ---            ---            index              mb::index       
  ---            ---            lc                 ---             
  ---            ---            lcfirst            ---             
  ---            ---            length             mb::length      
  ---            ---            ord                mb::ord         
  ---            ---            reverse            mb::reverse     
  ---            ---            rindex             mb::rindex      
  ---            ---            substr             mb::substr      
  ---            ---            uc                 ---             
  ---            ---            ucfirst            ---             
  -----------------------------------------------------------------

  DOS-like glob() as MBCS subroutine
  -----------------------------------------------------------------
  MBCS semantics          broken function, not so useful
  -----------------------------------------------------------------
  mb::dosglob             glob, and <globbing*>
  -----------------------------------------------------------------

  index brothers
  ------------------------------------------------------------------------------------------
  functions or subs       works           returns         considered
  ------------------------------------------------------------------------------------------
  index                   as octet        as octet        useful, bare Perl like
  rindex                  as octet        as octet        useful, bare Perl like
  mb::index               as codepoint    as codepoint    not so useful, utf8 pragma like
  mb::rindex              as codepoint    as codepoint    not so useful, utf8 pragma like
  mb::index_byte          as codepoint    as octet        useful, JPerl like
  mb::rindex_byte         as codepoint    as octet        useful, JPerl like
  ------------------------------------------------------------------------------------------

=head1 Porting from script in bare Perl4, bare Perl5, and bare Perl7

  -----------------------------------------------------------------
  original script in        script with
  Perl4, Perl5, Perl7       mb.pm modulino
  -----------------------------------------------------------------
  chop                      chop
  chr                       chr
  getc                      getc
  index                     index
  lc                        lc
  lcfirst                   lcfirst
  length                    length
  no Your::Module;          no  Your::Module;
  ord                       ord
  reverse                   reverse
  rindex                    rindex
  substr                    substr
  uc                        uc
  ucfirst                   ucfirst
  use Your::Module;         use  Your::Module;
  -----------------------------------------------------------------

=head1 Porting from script in JPerl4, and JPerl5

  -----------------------------------------------------------------
  original script in        script with
  JPerl4, JPerl5            mb.pm modulino
  -----------------------------------------------------------------
  chop                      mb::chop
  index                     mb::index_byte
  no Your::MBCS::Module;    no mb::mode Your::MBCS::Module; *1
  rindex                    mb::rindex_byte
  use Your::MBCS::Module;   use mb::mode Your::MBCS::Module; *1
  -----------------------------------------------------------------
  *1 mb::mode module comes later

=head1 Porting from script with utf8 pragma

  -----------------------------------------------------------------
  original script with      script with
  utf8 pragma               mb.pm modulino
  -----------------------------------------------------------------
  chop                      mb::chop
  chr                       mb::chr
  getc                      mb::getc
  index                     mb::index
  lc                        ---
  lcfirst                   ---
  length                    mb::length
  no Your::MBCS::Module;    no mb::mode Your::MBCS::Module; *2
  ord                       mb::ord
  reverse                   mb::reverse
  rindex                    mb::rindex
  substr                    mb::substr
  uc                        ---
  ucfirst                   ---
  use Your::MBCS::Module;   use mb::mode Your::MBCS::Module; *2
  -----------------------------------------------------------------
  *2 mb::mode module comes later, and module must be without utf8 pragma.

=head1 What are DAMEMOJI

  In single quote, DAMEMOJI are double-byte characters that include the
  following metacharacters ('', q{}, <<'END', qw{}, m'', s''', split(''),
  split(m''), and qr'')
  ------------------------------------------------------------------
  hex   character
  ------------------------------------------------------------------
  5C    [\]    backslashed escapes
  ------------------------------------------------------------------

  In double quote, DAMEMOJI are double-byte characters that include the
  following metacharacters ("", qq{}, <<END, <<"END", ``, qx{}, <<`END`, //,
  m//, ??, s///, split(//), split(m//), and qr//)
  ------------------------------------------------------------------
  hex   character
  ------------------------------------------------------------------
  21    [!]
  22    ["]
  23    [#]
  24    [$]
  25    [%]
  26    [&]
  27    [']
  28    [(]
  29    [)]
  2A    [*]
  2B    [+]
  2C    [,]
  2D    [-]
  2E    [.]
  2F    [/]
  3A    [:]
  3B    [;]
  3C    [<]
  3D    [=]
  3E    [>]
  3F    [?]
  40    [@]    sigil of array variable
  5B    [[]    regexp bracketed character class
  5C    [\]    backslashed escapes
  5D    []]    regexp bracketed character class
  5E    [^]    regexp true at beginning of string
  60    [`]    command execution
  7B    [{]    regexp quantifier
  7C    [|]    regexp alternation
  7D    [}]    regexp quantifier
  7E    [~]
  ------------------------------------------------------------------

=head1 How to escape DAMEMOJI

  ex. Japanese KATAKANA "SO" like [ `/ ] code is "\x83\x5C" in Sjis
 
                  see     hex dump
  -----------------------------------------
  source script   "`/"    [83 5c]
  -----------------------------------------
 
  using mb.pm,
                          hex dump
  -----------------------------------------
  escaped script  "`\/"   [83 [5c] 5c]
  -----------------------------------------
                    ^--- escape by mb.pm
 
  by the by       see     hex dump
  -----------------------------------------
  your eye's      "`/\"   [83 5c] [5c]
  -----------------------------------------
  perl eye's      "`\/"   [83] \[5c]
  -----------------------------------------
 
                          hex dump
  -----------------------------------------
  in the perl     "`/"    [83] [5c]
  -----------------------------------------

=head1 What converts to what by this software?

  This software automatically converts MBCS literal strings in scripts to
  octet-oriented strings(OO-quotee).

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  in your script                             script transpiled by this software
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  do "string";                               mb::do "string";
  mb::do { block }                           do { block }
  eval "string";                             mb::eval "string";
  mb::eval { block }                         eval { block }
  require                                    mb::require
  mb::require                                mb::require
  chop                                       chop
  lc                                         mb::lc
  lcfirst                                    mb::lcfirst
  uc                                         mb::uc
  ucfirst                                    mb::ucfirst
  index                                      index
  rindex                                     rindex
  'MBCS-quotee'                              'OO-quotee'
  "MBCS-quotee"                              "OO-quotee"
  `MBCS-quotee`                              `OO-quotee`
  /MBCS-quotee/cgimosx                       m{\G${mb::_anchor}@{[mb::_ignorecase(qr/OO-quotee/mosx)]}@{[mb::_m_passed()]}}cg
  /MBCS-quotee/cgmosx                        m{\G${mb::_anchor}@{[qr/OO-quotee/mosx ]}@{[mb::_m_passed()]}}cg
  ?MBCS-quotee?cgimosx                       m{\G${mb::_anchor}@{[mb::_ignorecase(qr?OO-quotee?mosx)]}@{[mb::_m_passed()]}}cg
  ?MBCS-quotee?cgmosx                        m{\G${mb::_anchor}@{[qr?OO-quotee?mosx ]}@{[mb::_m_passed()]}}cg
  <MBCS-quotee>                              <OO-quotee>
  q/MBCS-quotee/                             q/OO-quotee/
  qx'MBCS-quotee'                            qx'OO-quotee'
  qw/MBCS-quotee/                            qw/OO-quotee/
  m'MBCS-quotee'cgimosx                      m{\G${mb::_anchor}@{[mb::_ignorecase(qr'OO-quotee'mosx)]}@{[mb::_m_passed()]}}cg
  m'MBCS-quotee'cgmosx                       m{\G${mb::_anchor}@{[qr'OO-quotee'mosx ]}@{[mb::_m_passed()]}}cg
  s'MBCS-regexp'MBCS-replacement'eegimosxr   s{(\G${mb::_anchor})@{[mb::_ignorecase(qr'OO-regexp'mosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q'OO-replacement'}egr
  s'MBCS-regexp'MBCS-replacement'eegmosxr    s{(\G${mb::_anchor})@{[qr'OO-regexp'mosx ]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q'OO-replacement'}egr
  tr/MBCS-search/MBCS-replacement/cdsr       s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}er
  tr/MBCS-search/MBCS-replacement/cds        s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}e
  tr/MBCS-search/MBCS-replacement/ds         s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'dsr')}e
  y/MBCS-search/MBCS-replacement/cdsr        s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}er
  y/MBCS-search/MBCS-replacement/cds         s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}e
  y/MBCS-search/MBCS-replacement/ds          s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'dsr')}e
  qr'MBCS-quotee'cgimosx                     qr{\G${mb::_anchor}@{[mb::_ignorecase(qr'OO-quotee'mosx)]}@{[mb::_m_passed()]}}cg
  qr'MBCS-quotee'cgmosx                      qr{\G${mb::_anchor}@{[qr'OO-quotee'mosx ]}@{[mb::_m_passed()]}}cg
  split m'^'                                 mb::_split qr{@{[qr'^'m ]}}
  split m'MBCS-quotee'cgimosx                mb::_split qr{@{[mb::_ignorecase(qr'OO-quotee'mosx)]}}cg
  split m'MBCS-quotee'cgmosx                 mb::_split qr{@{[qr'OO-quotee'mosx ]}}cg
  split qr'^'                                mb::_split qr{@{[qr'^'m ]}}
  split qr'MBCS-quotee'cgimosx               mb::_split qr{@{[mb::_ignorecase(qr'OO-quotee'mosx)]}}cg
  split qr'MBCS-quotee'cgmosx                mb::_split qr{@{[qr'OO-quotee'mosx ]}}cg
  qq/MBCS-quotee/                            qq/OO-quotee/
  qq'MBCS-quotee'                            qq'OO-quotee'
  qx/MBCS-quotee/                            qx/OO-quotee/
  m/MBCS-quotee/cgimosx                      m{\G${mb::_anchor}@{[mb::_ignorecase(qr/OO-quotee/mosx)]}@{[mb::_m_passed()]}}cg
  m/MBCS-quotee/cgmosx                       m{\G${mb::_anchor}@{[qr/OO-quotee/mosx ]}@{[mb::_m_passed()]}}cg
  s/MBCS-regexp/MBCS-replacement/eegimosxr   s{(\G${mb::_anchor})@{[mb::_ignorecase(qr/OO-regexp/mosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q/OO-replacement/}egr
  s/MBCS-regexp/MBCS-replacement/eegmosxr    s{(\G${mb::_anchor})@{[qr/OO-regexp/mosx ]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q/OO-replacement/}egr
  qr/MBCS-quotee/cgimosx                     qr{\G${mb::_anchor}@{[mb::_ignorecase(qr/OO-quotee/mosx)]}@{[mb::_m_passed()]}}cg
  qr/MBCS-quotee/cgmosx                      qr{\G${mb::_anchor}@{[qr/OO-quotee/mosx ]}@{[mb::_m_passed()]}}cg
  split /^/                                  mb::_split qr{@{[qr/^/m ]}}
  split /MBCS-quotee/cgimosx                 mb::_split qr{@{[mb::_ignorecase(qr/OO-quotee/mosx)]}}cg
  split /MBCS-quotee/cgmosx                  mb::_split qr{@{[qr/OO-quotee/mosx ]}}cg
  split m/^/                                 mb::_split qr{@{[qr/^/m ]}}
  split m/MBCS-quotee/cgimosx                mb::_split qr{@{[mb::_ignorecase(qr/OO-quotee/mosx)]}}cg
  split m/MBCS-quotee/cgmosx                 mb::_split qr{@{[qr/OO-quotee/mosx ]}}cg
  split qr/^/                                mb::_split qr{@{[qr/^/m ]}}
  split qr/MBCS-quotee/cgimosx               mb::_split qr{@{[mb::_ignorecase(qr/OO-quotee/mosx)]}}cg
  split qr/MBCS-quotee/cgmosx                mb::_split qr{@{[qr/OO-quotee/mosx ]}}cg
  m:MBCS-quotee:cgimosx                      m{\G${mb::_anchor}@{[mb::_ignorecase(qr`OO-quotee`mosx)]}@{[mb::_m_passed()]}}cg
  m:MBCS-quotee:cgmosx                       m{\G${mb::_anchor}@{[qr`OO-quotee`mosx ]}@{[mb::_m_passed()]}}cg
  s:MBCS-regexp:MBCS-replacement:eegimosxr   s{(\G${mb::_anchor})@{[mb::_ignorecase(qr`OO-regexp`mosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q:OO-replacement:}egr
  s:MBCS-regexp:MBCS-replacement:eegmosxr    s{(\G${mb::_anchor})@{[qr`OO-regexp`mosx ]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q:OO-replacement:}egr
  qr:MBCS-quotee:cgimosx                     qr{\G${mb::_anchor}@{[mb::_ignorecase(qr`OO-quotee`mosx)]}@{[mb::_m_passed()]}}cg
  qr:MBCS-quotee:cgmosx                      qr{\G${mb::_anchor}@{[qr`OO-quotee`mosx ]}@{[mb::_m_passed()]}}cg
  split m:^:                                 mb::_split qr{@{[qr`^`m ]}}
  split m:MBCS-quotee:cgimosx                mb::_split qr{@{[mb::_ignorecase(qr`OO-quotee`mosx)]}}cg
  split m:MBCS-quotee:cgmosx                 mb::_split qr{@{[qr`OO-quotee`mosx ]}}cg
  split qr:^:                                mb::_split qr{@{[qr`^`m ]}}
  split qr:MBCS-quotee:cgimosx               mb::_split qr{@{[mb::_ignorecase(qr`OO-quotee`mosx)]}}cg
  split qr:MBCS-quotee:cgmosx                mb::_split qr{@{[qr`OO-quotee`mosx ]}}cg
  m@MBCS-quotee@cgimosx                      m{\G${mb::_anchor}@{[mb::_ignorecase(qr`OO-quotee`mosx)]}@{[mb::_m_passed()]}}cg
  m@MBCS-quotee@cgmosx                       m{\G${mb::_anchor}@{[qr`OO-quotee`mosx ]}@{[mb::_m_passed()]}}cg
  s@MBCS-regexp@MBCS-replacement@eegimosxr   s{(\G${mb::_anchor})@{[mb::_ignorecase(qr`OO-regexp`mosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q@OO-replacement@}egr
  s@MBCS-regexp@MBCS-replacement@eegmosxr    s{(\G${mb::_anchor})@{[qr`OO-regexp`mosx ]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q@OO-replacement@}egr
  qr@MBCS-quotee@cgimosx                     qr{\G${mb::_anchor}@{[mb::_ignorecase(qr`OO-quotee`mosx)]}@{[mb::_m_passed()]}}cg
  qr@MBCS-quotee@cgmosx                      qr{\G${mb::_anchor}@{[qr`OO-quotee`mosx ]}@{[mb::_m_passed()]}}cg
  split m@^@                                 mb::_split qr{@{[qr`^`m ]}}
  split m@MBCS-quotee@cgimosx                mb::_split qr{@{[mb::_ignorecase(qr`OO-quotee`mosx)]}}cg
  split m@MBCS-quotee@cgmosx                 mb::_split qr{@{[qr`OO-quotee`mosx ]}}cg
  split qr@^@                                mb::_split qr{@{[qr`^`m ]}}
  split qr@MBCS-quotee@cgimosx               mb::_split qr{@{[mb::_ignorecase(qr`OO-quotee`mosx)]}}cg
  split qr@MBCS-quotee@cgmosx                mb::_split qr{@{[qr`OO-quotee`mosx ]}}cg
  $`                                         mb::_PREMATCH()
  ${`}                                       mb::_PREMATCH()
  $PREMATCH                                  mb::_PREMATCH()
  ${PREMATCH}                                mb::_PREMATCH()
  ${^PREMATCH}                               mb::_PREMATCH()
  $&                                         mb::_MATCH()
  ${&}                                       mb::_MATCH()
  $MATCH                                     mb::_MATCH()
  ${MATCH}                                   mb::_MATCH()
  ${^MATCH}                                  mb::_MATCH()
  $1                                         mb::_CAPTURE(1)
  $2                                         mb::_CAPTURE(2)
  $3                                         mb::_CAPTURE(3)
  @{^CAPTURE}                                mb::_CAPTURE()
  ${^CAPTURE}[0]                             mb::_CAPTURE(0+1)
  ${^CAPTURE}[1]                             mb::_CAPTURE(1+1)
  ${^CAPTURE}[2]                             mb::_CAPTURE(2+1)
  @-                                         mb::_LAST_MATCH_START()
  @LAST_MATCH_START                          mb::_LAST_MATCH_START()
  @{LAST_MATCH_START}                        mb::_LAST_MATCH_START()
  @{^LAST_MATCH_START}                       mb::_LAST_MATCH_START()
  $-[1]                                      mb::_LAST_MATCH_START(1)
  $LAST_MATCH_START[1]                       mb::_LAST_MATCH_START(1)
  ${LAST_MATCH_START}[1]                     mb::_LAST_MATCH_START(1)
  ${^LAST_MATCH_START}[1]                    mb::_LAST_MATCH_START(1)
  @+                                         mb::_LAST_MATCH_END()
  @LAST_MATCH_END                            mb::_LAST_MATCH_END()
  @{LAST_MATCH_END}                          mb::_LAST_MATCH_END()
  @{^LAST_MATCH_END}                         mb::_LAST_MATCH_END()
  $+[1]                                      mb::_LAST_MATCH_END(1)
  $LAST_MATCH_END[1]                         mb::_LAST_MATCH_END(1)
  ${LAST_MATCH_END}[1]                       mb::_LAST_MATCH_END(1)
  ${^LAST_MATCH_END}[1]                      mb::_LAST_MATCH_END(1)
  "$`"                                       "@{[mb::_PREMATCH()]}"
  "${`}"                                     "@{[mb::_PREMATCH()]}"
  "$PREMATCH"                                "@{[mb::_PREMATCH()]}"
  "${PREMATCH}"                              "@{[mb::_PREMATCH()]}"
  "${^PREMATCH}"                             "@{[mb::_PREMATCH()]}"
  "$&"                                       "@{[mb::_MATCH()]}"
  "${&}"                                     "@{[mb::_MATCH()]}"
  "$MATCH"                                   "@{[mb::_MATCH()]}"
  "${MATCH}"                                 "@{[mb::_MATCH()]}"
  "${^MATCH}"                                "@{[mb::_MATCH()]}"
  "$1"                                       "@{[mb::_CAPTURE(1)]}"
  "$2"                                       "@{[mb::_CAPTURE(2)]}"
  "$3"                                       "@{[mb::_CAPTURE(3)]}"
  "@{^CAPTURE}"                              "@{[join $", mb::_CAPTURE()]}"
  "${^CAPTURE}[0]"                           "@{[mb::_CAPTURE(0)]}"
  "${^CAPTURE}[1]"                           "@{[mb::_CAPTURE(1)]}"
  "${^CAPTURE}[2]"                           "@{[mb::_CAPTURE(2)]}"
  "@-"                                       "@{[mb::_LAST_MATCH_START()]}"
  "@LAST_MATCH_START"                        "@{[mb::_LAST_MATCH_START()]}"
  "@{LAST_MATCH_START}"                      "@{[mb::_LAST_MATCH_START()]}"
  "@{^LAST_MATCH_START}"                     "@{[mb::_LAST_MATCH_START()]}"
  "$-[1]"                                    "@{[mb::_LAST_MATCH_START(1)]}"
  "$LAST_MATCH_START[1]"                     "@{[mb::_LAST_MATCH_START(1)]}"
  "${LAST_MATCH_START}[1]"                   "@{[mb::_LAST_MATCH_START(1)]}"
  "${^LAST_MATCH_START}[1]"                  "@{[mb::_LAST_MATCH_START(1)]}"
  "@+"                                       "@{[mb::_LAST_MATCH_END()]}"
  "@LAST_MATCH_END"                          "@{[mb::_LAST_MATCH_END()]}"
  "@{LAST_MATCH_END}"                        "@{[mb::_LAST_MATCH_END()]}"
  "@{^LAST_MATCH_END}"                       "@{[mb::_LAST_MATCH_END()]}"
  "$+[1]"                                    "@{[mb::_LAST_MATCH_END(1)]}"
  "$LAST_MATCH_END[1]"                       "@{[mb::_LAST_MATCH_END(1)]}"
  "${LAST_MATCH_END}[1]"                     "@{[mb::_LAST_MATCH_END(1)]}"
  "${^LAST_MATCH_END}[1]"                    "@{[mb::_LAST_MATCH_END(1)]}"
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  The following conversions are for Microsoft Windows, but will always be
  converted so that the converted script will work on any system.

  -----------------------------------------------------------------------------
  in your script                             script transpiled by this software
  -----------------------------------------------------------------------------
  chdir                                      mb::_chdir
  lstat                                      mb::_lstat
  opendir                                    mb::_opendir
  stat                                       mb::_stat
  unlink                                     mb::_unlink
  filetest -B                                mb::_B
  filetest -C                                mb::_C
  filetest -M                                mb::_M
  filetest -T                                mb::_T
  filetest -d                                mb::_d
  filetest -e                                mb::_e
  filetest -f                                mb::_f
  filetest -r                                mb::_r
  filetest -s                                mb::_s
  filetest -w                                mb::_w
  filetest -x                                mb::_x
  filetest -z                                mb::_z
  -----------------------------------------------------------------------------

  Each elements in strings or regular expressions that are double-quote like are
  converted as follows.

  ---------------------------------------------------------------------------------------------
  in your script                             script transpiled by this software
  ---------------------------------------------------------------------------------------------
  \L\u MBCS-quotee \E\E                      \L\u OO-quotee \E\E
  \U\l MBCS-quotee \E\E                      \U\l OO-quotee \E\E
  \L MBCS-quotee \E                          \L OO-quotee \E
  \U MBCS-quotee \E                          \U OO-quotee \E
  \l MBCS-quotee \E                          \l OO-quotee \E
  \u MBCS-quotee \E                          \u OO-quotee \E
  \Q MBCS-quotee \E                          \Q OO-quotee \E
  ---------------------------------------------------------------------------------------------

  Each elements in regular expressions are converted as follows.

  ----------------------------------------------------------------------------------------------------------------------
  in your script                             script transpiled by this software (on sjis encoding)
  ----------------------------------------------------------------------------------------------------------------------
  qr'.'                                      qr{\G${mb::_anchor}@{[qr'(?:(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|.)' ]}@{[mb::_m_passed()]}}
  qr'\B'                                     qr{\G${mb::_anchor}@{[qr'(?:(?<![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])|(?<=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]))' ]}@{[mb::_m_passed()]}}
  qr'\D'                                     qr{\G${mb::_anchor}@{[qr'(?:(?![0123456789])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'\H'                                     qr{\G${mb::_anchor}@{[qr'(?:(?![\x09\x20])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'\N'                                     qr{\G${mb::_anchor}@{[qr'(?:(?!\n)(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'\R'                                     qr{\G${mb::_anchor}@{[qr'(?>\r\n|[\x0A\x0B\x0C\x0D])' ]}@{[mb::_m_passed()]}}
  qr'\S'                                     qr{\G${mb::_anchor}@{[qr'(?:(?![\t\n\f\r\x20])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'\V'                                     qr{\G${mb::_anchor}@{[qr'(?:(?![\x0A\x0B\x0C\x0D])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'\W'                                     qr{\G${mb::_anchor}@{[qr'(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'\b'                                     qr{\G${mb::_anchor}@{[qr'(?:(?<![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])|(?<=[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_])(?![ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]))' ]}@{[mb::_m_passed()]}}
  qr'\d'                                     qr{\G${mb::_anchor}@{[qr'[0123456789]' ]}@{[mb::_m_passed()]}}
  qr'\h'                                     qr{\G${mb::_anchor}@{[qr'[\x09\x20]' ]}@{[mb::_m_passed()]}}
  qr'\s'                                     qr{\G${mb::_anchor}@{[qr'[\t\n\f\r\x20]' ]}@{[mb::_m_passed()]}}
  qr'\v'                                     qr{\G${mb::_anchor}@{[qr'[\x0A\x0B\x0C\x0D]' ]}@{[mb::_m_passed()]}}
  qr'\w'                                     qr{\G${mb::_anchor}@{[qr'[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]' ]}@{[mb::_m_passed()]}}
  qr'[\b]'                                   qr{\G${mb::_anchor}@{[qr'(?:(?=[\x08])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:alnum:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39\x41-\x5A\x61-\x7A])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:alpha:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x41-\x5A\x61-\x7A])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:ascii:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x00-\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:blank:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x09\x20])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:cntrl:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x00-\x1F\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:digit:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:graph:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x21-\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:lower:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[abcdefghijklmnopqrstuvwxyz])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:print:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x20-\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:punct:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:space:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[\s\x0B])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:upper:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=[ABCDEFGHIJKLMNOPQRSTUVWXYZ])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:word:]]'                             qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39\x41-\x5A\x5F\x61-\x7A])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:xdigit:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=[\x30-\x39\x41-\x46\x61-\x66])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^alnum:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x5A\x61-\x7A])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^alpha:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x41-\x5A\x61-\x7A])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^ascii:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x00-\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^blank:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x09\x20])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^cntrl:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x00-\x1F\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^digit:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^graph:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x21-\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^lower:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![abcdefghijklmnopqrstuvwxyz])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^print:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x20-\x7F])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^punct:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^space:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\s\x0B])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^upper:]]'                           qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZ])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^word:]]'                            qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x5A\x5F\x61-\x7A])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr'[[:^xdigit:]]'                          qr{\G${mb::_anchor}@{[qr'(?:(?=(?:(?![\x30-\x39\x41-\x46\x61-\x66])(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F]))))(?^:(?>(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])|[\x00-\x7F])))' ]}@{[mb::_m_passed()]}}
  qr/./                                      qr{\G${mb::_anchor}@{[qr/(?:@{mb::_dot})/ ]}@{[mb::_m_passed()]}}
  qr/\B/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_B})/ ]}@{[mb::_m_passed()]}}
  qr/\D/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_D})/ ]}@{[mb::_m_passed()]}}
  qr/\H/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_H})/ ]}@{[mb::_m_passed()]}}
  qr/\N/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_N})/ ]}@{[mb::_m_passed()]}}
  qr/\R/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_R})/ ]}@{[mb::_m_passed()]}}
  qr/\S/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_S})/ ]}@{[mb::_m_passed()]}}
  qr/\V/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_V})/ ]}@{[mb::_m_passed()]}}
  qr/\W/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_W})/ ]}@{[mb::_m_passed()]}}
  qr/\b/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_b})/ ]}@{[mb::_m_passed()]}}
  qr/\d/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_d})/ ]}@{[mb::_m_passed()]}}
  qr/\h/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_h})/ ]}@{[mb::_m_passed()]}}
  qr/\s/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_s})/ ]}@{[mb::_m_passed()]}}
  qr/\v/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_v})/ ]}@{[mb::_m_passed()]}}
  qr/\w/                                     qr{\G${mb::_anchor}@{[qr/(?:@{mb::_w})/ ]}@{[mb::_m_passed()]}}
  qr/[\b]/                                   qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[\\b])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:alnum:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:alnum:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:alpha:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:alpha:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:ascii:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:ascii:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:blank:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:blank:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:cntrl:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:cntrl:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:digit:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:digit:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:graph:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:graph:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:lower:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:lower:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:print:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:print:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:punct:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:punct:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:space:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:space:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:upper:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:upper:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:word:]]/                             qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:word:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:xdigit:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:xdigit:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^alnum:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^alnum:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^alpha:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^alpha:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^ascii:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^ascii:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^blank:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^blank:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^cntrl:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^cntrl:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^digit:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^digit:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^graph:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^graph:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^lower:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^lower:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^print:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^print:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^punct:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^punct:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^space:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^space:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^upper:]]/                           qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^upper:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^word:]]/                            qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^word:]])]}/ ]}@{[mb::_m_passed()]}}
  qr/[[:^xdigit:]]/                          qr{\G${mb::_anchor}@{[qr/@{[mb::_cc(qq[[:^xdigit:]])]}/ ]}@{[mb::_m_passed()]}}
  ----------------------------------------------------------------------------------------------------------------------

=head1 DEPENDENCIES

This software requires perl5.00503 or later.

=head1 BUGS, LIMITATIONS, and COMPATIBILITY

I have tested and verified this software using the best of my ability.
However, a software containing much regular expression is bound to contain
some bugs. Thus, if you happen to find a bug that's in this software and
not your own program, you can try to reduce it to a minimal test case and
then report it to the following author's address. If you have an idea that
could make this a more useful tool, please let everyone share it.

=over 2

=item * Special Variables $` and $& need /( Capture All )/

  Because $` and $& use $1.

  ----------------------------------------------------------------------------------------------------------------------
  in your script      after m//, works as                         after s///, works as
  ----------------------------------------------------------------------------------------------------------------------
  $`                  CORE::substr($&, 0, -CORE::length($1))      $1
  ${`}                CORE::substr($&, 0, -CORE::length($1))      $1
  $PREMATCH           CORE::substr($&, 0, -CORE::length($1))      $1
  ${^PREMATCH}        CORE::substr($&, 0, -CORE::length($1))      $1
  $&                  $1                                          CORE::substr($&, CORE::length($1))
  ${&}                $1                                          CORE::substr($&, CORE::length($1))
  $MATCH              $1                                          CORE::substr($&, CORE::length($1))
  ${^MATCH}           $1                                          CORE::substr($&, CORE::length($1))
  ----------------------------------------------------------------------------------------------------------------------

=item * return value from tr///s

tr/// (or y///) operator with /s modifier returns 1 always. If you need right
number, you can use mb::tr().

=item * chdir

Function chdir() cannot work if path is ended by chr(0x5C).

  see also,
  Bug #81839
  chdir does not work with chr(0x5C) at end of path
  http://bugs.activestate.com/show_bug.cgi?id=81839

=item * mb::substr as Lvalue

If Perl version is older than 5.14, mb::substr differs from CORE::substr, and
cannot be used as a lvalue. To change part of a string, you need use the optional
fourth argument which is the replacement string.

mb::substr($string, 13, 4, "JPerl");

=item * Limitation of Regular Expression

This software has limitation from \G in multibyte anchoring. Only Perl 5.30.0 or
later can treat the codepoint string which exceeds 65534 octets with a regular
expression, and only Perl 5.10.1 or later can 32766 octets.

  see also,
  
  The upper limit "n" specifiable in a regular expression quantifier of the form "{m,n}" has been doubled to 65534
  https://metacpan.org/pod/release/XSAWYERX/perl-5.30.0/pod/perldelta.pod#The-upper-limit-%22n%22-specifiable-in-a-regular-expression-quantifier-of-the-form-%22%7Bm,n%7D%22-has-been-doubled-to-65534
  
  In 5.10.0, the * quantifier in patterns was sometimes treated as {0,32767}
  http://perldoc.perl.org/perl5101delta.html
  
  [perl #116379] \G can't treat over 32767 octet
  http://www.nntp.perl.org/group/perl.perl5.porters/2013/01/msg197320.html
  
  perlre - Perl regular expressions
  http://perldoc.perl.org/perlre.html
  
  perlre length limit
  http://stackoverflow.com/questions/4592467/perlre-length-limit

=item * fc(), lc(), lcfirst(), uc(), and ucfirst()

fc() not supported. lc(), lcfirst(), uc(), and ucfirst() support US-ASCII only.

=item * character ranges by hyphen

Character ranges by hyphen of regular expression supports US-ASCII only.
And tr///, y/// doesn't support ranges by hyphen.

=item * cloister of regular expression

The cloister (?s) and (?i) of a regular expression will not be implemented for
the time being. Cloister (?s) can be substituted with the .(dot) and \N on /s
modifier.

=item * Empty Variable in Regular Expression

Unlike literal null string, an interpolated variable evaluated to the empty string
can't use the most recent pattern from a previous successful regular expression.

=item * Limitation of ?? and m??

Multibyte character needs ( ) which is before {n,m}, {n,}, {n}, *, and + in ?? or
m??. As a result, you need to rewrite a script about $1,$2,$3,... You cannot use
(?: ), ?, {n,m}?, {n,}?, and {n}? in ?? and m??, because delimiter of m?? is '?'.

=item * Look-behind Assertion

The look-behind assertion like (?<=[A-Z]) is not prevented from matching trail
octet of the previous MBCS codepoint.

=item * Modifier /a /d /l and /u of Regular Expression

The concept of this software is not to use two or more encoding methods as
literal string and literal of regexp in one Perl script. Therefore, modifier
/a, /d, /l, and /u are not supported.
\d means [0-9] universally.

=item * Named Codepoint

A named codepoint, such \N{GREEK SMALL LETTER EPSILON}, \N{greek:epsilon}, or
\N{epsilon} is not supported.

=item * Unicode Properties (aka Codepoint Properties) of Regular Expression

Unicode properties (aka codepoint properties) of regexp are not available.
Also (?[]) in regexp of Perl 5.18 is not available. There is no plans to currently
support these.

=item * ${^WIN32_SLOPPY_STAT} is ignored

Even if ${^WIN32_SLOPPY_STAT} is set to a true value, file test functions mb::*(),
mb::lstat(), and mb::stat() on Microsoft Windows open the file for the path which
has chr(0x5c) at end.

=item * Delimiter of String and Regexp

qq//, q//, qw//, qx//, qr//, m//, s///, tr///, and y/// can't use a wide codepoint
as the delimiter.

=item * \b{...} Boundaries in Regular Expressions

Following \b{...} available starting in v5.22 are not supported.

  \b{gcb} or \b{g}   Unicode "Grapheme Cluster Boundary"
  \b{sb}             Unicode "Sentence Boundary"
  \b{wb}             Unicode "Word Boundary"
  \B{gcb} or \B{g}   Unicode "Grapheme Cluster Boundary" doesn't match
  \B{sb}             Unicode "Sentence Boundary" doesn't match
  \B{wb}             Unicode "Word Boundary" doesn't match

=item * format

Function "format" can't handle MBCS codepoints unlike JPerl.

=item * Mac OS 9

Apple Inc. Mac OS 9 not supported. sorry about it.

=back

=head1 UTF8 Flag Considered Harmful, and Our Goal

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
processing model at Perl 5.8. It is impossible to get agreement it
from majority of Perl programmers who are not heavy users.
How to solve it by returning to an original Perl, let's read page
402 of the Programming Perl, 3rd edition, again.

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

  Native Encoding Scripting
  - native encoding of file contents
  - native encoding of file name on filesystem
  - native encoding of command line
  - native encoding of environment variable
  - native encoding of API
  - native encoding of network packet
  - native encoding of database

Ideally, We'd like to achieve these five Goals:

=over 2

=item * Goal #1:

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

This software attempts to achieve this goal by mimicking the behavior
of JPerl.

=item * Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

This software is not a magician. So there is no ability to see your
mind and run the program.

You must decide and write octet semantics or codepoint semantics yourself
in case by case.

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
      New --- New character-oriented

There is a combination from (a) to (e) in data, script, and interpreter
of old and new. Let's add the Encode module and this software did not
exist at time of be written this document and JPerl did exist.

                        (a)     (b)     (c)     (d)     (e)
                                      JPerl,mb        Encode
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

The reason why JPerl is very excellent is that it is at the position of
(c). That is, it is not necessary to write a special code to process new
codepoint oriented script.

=item * Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is impossible. Because the following time is necessary.

(1) Time of escape script for old byte-oriented perl.

(2) Time of processing regular expression by escaped script while
    multibyte anchoring.

Someday, I want to ask Larry Wall about this goal in elevator.

=item * Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

JPerl remains one Perl language by forking to two interpreters.
However, the Perl core team did not desire fork of the interpreter.
As a result, Perl language forked contrary to goal #4.

A codepoint oriented perl is not necessary to make it specially,
because a byte-oriented perl can already treat the binary data.
This software is only an application program of byte-oriented Perl,
a filter program.

And you will get support from the Perl community, when you solve the
problem by the Perl script.

mb.pm modulino keeps one language and one interpreter.

=item * Goal #5:

mb.pm users will be able to maintain mb.pm by Perl.

May the mb.pm be with you, always.

=back

Back when Programming Perl, 3rd ed. was written, UTF8 flag was not born
and Perl is designed to make the easy jobs easy. This software provides
programming environment like at that time.

=head1 Perl's motto

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

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

 L<perlunicode>, L<Encode>, L<open>, L<utf8>, L<bytes>, 
 L<Arabic>, L<Big5>, L<Big5HKSCS>, L<CP932::R2>, L<CP932IBM::R2>, L<CP932NEC::R2>, 
 L<CP932X::R2>, L<Char::Arabic>, L<Char::Big5HKSCS>, L<Char::Big5Plus>, L<Char::Cyrillic>, 
 L<Char::EUCJP>, L<Char::EUCTW>, L<Char::GB18030>, L<Char::GBK>, L<Char::Greek>, 
 L<Char::HP15>, L<Char::Hebrew>, L<Char::INFORMIXV6ALS>, L<Char::JIS8>, L<Char::KOI8R>, 
 L<Char::KOI8U>, L<Char::KPS9566>, L<Char::Latin1>, L<Char::Latin10>, L<Char::Latin2>, 
 L<Char::Latin3>, L<Char::Latin4>, L<Char::Latin5>, L<Char::Latin6>, L<Char::Latin7>, 
 L<Char::Latin8>, L<Char::Latin9>, L<Char::OldUTF8>, L<Char::Sjis>, L<Char::TIS620>, 
 L<Char::UHC>, L<Char::USASCII>, L<Char::UTF2>, L<Char::Windows1252>, L<Char::Windows1258>, 
 L<Cyrillic>, L<GBK>, L<Greek>, L<IOas::CP932>, L<IOas::CP932IBM>, L<IOas::CP932NEC>, 
 L<IOas::CP932X>, L<IOas::SJIS2004>, L<Jacode>, L<Jacode4e>, L<Jacode4e::RoundTrip>, 
 L<KOI8R>, L<KOI8U>, L<KPS9566>, L<KSC5601>, L<Latin1>, L<Latin10>, L<Latin2>, L<Latin3>, 
 L<Latin4>, L<Latin5>, L<Latin6>, L<Latin7>, L<Latin8>, L<Latin9>, L<Modern::Open>, 
 L<SJIS2004::R2>, L<Sjis>, L<UTF2>, L<UTF8::R2>, L<Windows1250>, L<Windows1252>, 
 L<Windows1254>, L<Windows1257>, L<Windows1258>, 

 Announcing Perl 7
 Jun 24, 2020 by brian d foy
 https://www.perl.com/article/announcing-perl-7/

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

 CJKV Information Processing
 Chinese, Japanese, Korean & Vietnamese Computing
 By Ken Lunde
 First Edition  January 1999
 Pages: 1128
 ISBN 10: 1-56592-224-7 | ISBN 13: 9781565922242
 http://shop.oreilly.com/product/9781565922242.do

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

 Kaoru Maeda, Perl's history Perl 1,2,3,4
 https://www.slideshare.net/KaoruMaeda/perl-perl-1234

 nurse, What is "string"
 https://naruse.hateblo.jp/entries/2014/11/07#1415355181

 NISHIO Hirokazu, What's meant "string as a sequence of characters"?
 https://nishiohirokazu.hatenadiary.org/entry/20141107/1415286729

 nurse, History of Japanese EUC 22:00
 https://naruse.hateblo.jp/entries/2009/03/08

 Mike Whitaker, Perl And Unicode
 https://www.slideshare.net/Penfold/perl-and-unicode

 About Windows and Japanese text
 https://blogs.windows.com/japan/2020/02/20/about-windows-and-japanese-text/

 About Windows diagnostic data
 https://blogs.windows.com/japan/2019/12/05/about-windows-diagnostic-data/

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

 About Windows and Japanese text
 https://blogs.windows.com/japan/2020/02/20/about-windows-and-japanese-text/

 About Windows diagnostic data
 https://blogs.windows.com/japan/2019/12/05/about-windows-diagnostic-data/

 CPAN Directory INABA Hitoshi
 https://metacpan.org/author/INA
 http://backpan.cpantesters.org/authors/id/I/IN/INA/
 https://metacpan.org/release/Jacode4e-RoundTrip
 https://metacpan.org/release/Jacode4e
 https://metacpan.org/release/Jacode

 Recent Perl packages by "INABA Hitoshi"
 http://code.activestate.com/ppm/author:INABA-Hitoshi/

=head1 ACKNOWLEDGEMENTS

This software was made referring to software and the document that the
following hackers or persons had made. 
I am thankful to all persons.

 Rick Yamashita, Shift_JIS
 https://shino.tumblr.com/post/116166805/%E5%B1%B1%E4%B8%8B%E8%89%AF%E8%94%B5%E3%81%A8%E7%94%B3%E3%81%97%E3%81%BE%E3%81%99-%E7%A7%81%E3%81%AF1981%E5%B9%B4%E5%BD%93%E6%99%82us%E3%81%AE%E3%83%9E%E3%82%A4%E3%82%AF%E3%83%AD%E3%82%BD%E3%83%95%E3%83%88%E3%81%A7%E3%82%B7%E3%83%95%E3%83%88jis%E3%81%AE%E3%83%87%E3%82%B6%E3%82%A4%E3%83%B3%E3%82%92%E6%8B%85%E5%BD%93
 http://www.wdic.org/w/WDIC/%E3%82%B7%E3%83%95%E3%83%88JIS

 Larry Wall, Perl
 http://www.perl.org/

 Kazumasa Utashiro, jcode.pl
 https://metacpan.org/author/UTASHIRO
 ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/

 Jeffrey E. F. Friedl, Mastering Regular Expressions
 http://regex.info/

 SADAHIRO Tomoyuki, The right way of using Shift_JIS
 http://nomenclator.la.coocan.jp/perl/shiftjis.htm
 https://metacpan.org/author/SADAHIRO

 Yukihiro "Matz" Matsumoto, YAPC::Asia2006 Ruby on Perl(s)
 https://archive.org/details/YAPCAsia2006TokyoRubyonPerls

 jscripter, For jperl users
 http://text.world.coocan.jp/jperl.html

 Bruce., Unicode in Perl
 http://www.rakunet.org/tsnet/TSabc/18/546.html

 Hiroaki Izumi, Shouldn't use Perl5.8 / Perl5.10 on the Windows
 https://sites.google.com/site/hiroa63iz/perlwin

 Yuki Kimoto, Is it true that you shouldn't use Perl on Windows?
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

 Kenichi Ishigaki, Pod-PerldocJp, Welcome to modern Perl world
 https://metacpan.org/release/Pod-PerldocJp
 http://gihyo.jp/dev/serial/01/modern-perl/0031
 http://gihyo.jp/dev/serial/01/modern-perl/0032
 http://gihyo.jp/dev/serial/01/modern-perl/0033

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

 Jesse Vincent, Compatibility is a virtue
 https://www.nntp.perl.org/group/perl.perl5.porters/2010/05/msg159825.html

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

 TANABATA - The Star Festival - common legend of east asia
 https://ja.wikipedia.org/wiki/%E4%B8%83%E5%A4%95
 https://ko.wikipedia.org/wiki/%EC%B9%A0%EC%84%9D
 https://zh-classical.wikipedia.org/wiki/%E4%B8%83%E5%A4%95
 https://zh-yue.wikipedia.org/wiki/%E4%B8%83%E5%A7%90%E8%AA%95
 https://zh.wikipedia.org/wiki/%E4%B8%83%E5%A4%95

=cut
