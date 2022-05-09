package mb;
'有朋自遠方来不亦楽乎'=~/^\xE6\x9C\x89/ or die "Perl script '@{[__FILE__]}' must be UTF-8 encoding.\n";
# You are welcome! MOJIBAKE-san, you are our friend forever!!
######################################################################
#
# mb - Scripting in Big5, Big5-HKSCS, GBK, Sjis, UHC, UTF-8, ...
#
# https://metacpan.org/release/mb
#
# Copyright (c) 2020, 2021, 2022 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.43';
$VERSION = $VERSION;

# internal use
$mb::last_s_passed = 0; # last s/// status (1 if s/// passed)

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 } use warnings; local $^W=1;

# set OSNAME
my $OSNAME = $^O;

# encoding name of operating system
my $system_encoding = undef;

# encoding name of MBCS script
my $script_encoding = undef;

# over US-ASCII
my $over_ascii = undef;

# supports qr/./ in MBCS script
my $x = undef;

# supports [\b] \d \h \s \v \w in MBCS script
my $bare_backspace = '\x08';
my $bare_d = '0123456789';
my $bare_h = '\x09\x20';
my $bare_s = '\t\n\f\r\x20';
my $bare_v = '\x0A\x0B\x0C\x0D';
my $bare_w = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_';

# as many escapes as possible to avoid perl's feature
my $escapee_in_qq_like = join('', map {"\\$_"} grep( ! /[A-Za-z0-9_]/, map { CORE::chr } 0x21..0x7E));

# as less escapes as possible to avoid over-escaping
my $escapee_in_q__like = '\\' . "\x5C";

# generic linebreak
my $R = '(?>\\r\\n|\\r|\\n)';

# check running perl interpreter
if ($^X =~ /jperl/i) {
    die "script '@{[__FILE__]}' can run on only perl, not JPerl\n";
}

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
            my($package,$filename,$line) = caller;
            die "$filename requires @{[__PACKAGE__]} $_[0], however @{[__FILE__]} am only $mb::VERSION, stopped at $filename line $line.\n";
        }
        shift @_;
    }

    # set system encoding
    $system_encoding = detect_system_encoding();

    # set script encoding
    if (defined $_[0]) {
        my $encoding = $_[0];
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | sjis | uhc | utf8 | wtf8 ) \z/xms) {
            set_script_encoding($encoding);
        }
        else {
            die "@{[__FILE__]} script_encoding '$encoding' not supported.\n";
        }
    }
    else {
        set_script_encoding($system_encoding);
    }

    # $^X($EXECUTABLE_NAME) for execute MBCS Perl script
    $mb::PERL = qq{$^X @{[__FILE__]}};
    $mb::PERL = $mb::PERL; # to avoid: Name "mb::PERL" used only once: possible typo at ...

    # original $0($PROGRAM_NAME) before transpile
    ($mb::ORIG_PROGRAM_NAME = $0) =~ s/\.oo(\.[^.]+)\z/$1/;
    $mb::ORIG_PROGRAM_NAME = $mb::ORIG_PROGRAM_NAME; # to avoid: Name "mb::ORIG_PROGRAM_NAME" used only once: possible typo at ...
}

#---------------------------------------------------------------------
# running as command
sub main {

    # usage
    if (scalar(@ARGV) == 0) {
        die <<END;
usage:

perl mb.pm              MBCS_Perl_script.pl (auto detect)
perl mb.pm -e big5      MBCS_Perl_script.pl
perl mb.pm -e big5hkscs MBCS_Perl_script.pl
perl mb.pm -e eucjp     MBCS_Perl_script.pl
perl mb.pm -e gb18030   MBCS_Perl_script.pl
perl mb.pm -e gbk       MBCS_Perl_script.pl
perl mb.pm -e sjis      MBCS_Perl_script.pl
perl mb.pm -e uhc       MBCS_Perl_script.pl
perl mb.pm -e utf8      MBCS_Perl_script.pl
perl mb.pm -e wtf8      MBCS_Perl_script.pl

perl mb.pm script.pl ??-DOS-like *wildcard* available

END
    }

    # set system encoding
    $system_encoding = detect_system_encoding();

    # set script encoding from command line
    my $encoding = '';
    if (($encoding) = $ARGV[0] =~ /\A -e ( .+ ) \z/xms) {
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | sjis | uhc | utf8 | wtf8 ) \z/xms) {
            set_script_encoding($encoding);
            shift @ARGV;
        }
        else {
            die "script_encoding '$encoding' not supported.\n";
        }
    }
    elsif ($ARGV[0] =~ /\A -e \z/xms) {
        $encoding = $ARGV[1];
        if ($encoding =~ /\A (?: big5 | big5hkscs | eucjp | gb18030 | gbk | sjis | uhc | utf8 | wtf8 ) \z/xms) {
            set_script_encoding($encoding);
            shift @ARGV;
            shift @ARGV;
        }
        else {
            die "script_encoding '$encoding' not supported.\n";
        }
    }
    else {
        set_script_encoding($system_encoding);
    }

    # poor "make"
    (my $script_oo = $ARGV[0]) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
    if (
        (not -e $script_oo)                    or
        (mtime($script_oo) <= mtime($ARGV[0])) or
        (mtime($script_oo) <= mtime(__FILE__))
    ) {

        # read application script
        mb::_open_r(my $fh, $ARGV[0]) or die "$0(@{[__LINE__]}): can't open file: $ARGV[0]\n";

        # sysread(...) has hidden binmode($fh) that's not portable
        # local $_; sysread($fh, $_, -s $ARGV[0]);
        local $_ = CORE::do { local $/; <$fh> }; # good!
        close $fh;

        # poor file locking
        local $SIG{__DIE__} = sub { rmdir "$ARGV[0].lock"; };
        if (mkdir "$ARGV[0].lock", 0755) {
            mb::_open_w(my $fh, $script_oo) or die "$0(@{[__LINE__]}): can't open file: $script_oo\n";
            print {$fh} mb::parse();
            close $fh;
            rmdir "$ARGV[0].lock";
        }
        else {
            die "$0(@{[__LINE__]}): can't mkdir: $ARGV[0].lock\n";
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

    # @ARGV wildcard globbing
    if ($OSNAME =~ /MSWin32/) {
        my @argv = ();
        for (@ARGV) {

            # has space
            if (/\A (?:$x)*? [ ] /oxms) {
                if (my @glob = mb::dosglob(qq{"$_"})) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # has wildcard metachar
            elsif (/\A (?:$x)*? [*?] /oxms) {
                if (my @glob = mb::dosglob($_)) {
                    push @argv, @glob;
                }
                else {
                    push @argv, $_;
                }
            }

            # no wildcard globbing
            else {
                push @argv, $_;
            }
        }
        @ARGV = @argv;
    }

    # run octet-oriented script
    $| = 1;
    system($^X, "-I$module_path", "-M$module_name=$mb::VERSION,$script_encoding", map { / / ? "$quote$_$quote" : $_ } $script_oo, @ARGV[1..$#ARGV]);
    exit($? >> 8);
}

#---------------------------------------------------------------------
# cluck() for MBCS encoding
sub cluck {
    my $i = 0;
    my @cluck = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @cluck, "[$i] $filename($line) $subroutine\n";
        $i++;
    }
    print STDERR "\n", @_, "\n";
    print STDERR CORE::reverse @cluck;
}

#---------------------------------------------------------------------
# confess() for MBCS encoding
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
# short cut of (stat(file))[9]
sub mtime {
    my($file) = @_;
    return ((stat $file)[9]);
}

######################################################################
# subroutines for MBCS application programmers
######################################################################

#---------------------------------------------------------------------
# chop() for MBCS encoding
sub mb::chop (@) {
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
# chr() for MBCS encoding
sub mb::chr (;$) {
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
# do FILE for MBCS encoding
sub mb::do ($) {
    my($file) = @_;
    for my $prefix_file ($file, map { "$_/$file" } @INC) {
        if (-f $prefix_file) {

            # poor "make"
            (my $prefix_file_oo = $prefix_file) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
            if (
                (not -e $prefix_file_oo)                        or
                (mtime($prefix_file_oo) <= mtime($prefix_file)) or
                (mtime($prefix_file_oo) <= mtime(__FILE__))
            ) {
                mb::_open_r(my $fh, $prefix_file) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file\n";
                local $_ = CORE::do { local $/; <$fh> };
                close $fh;

                # poor file locking
                local $SIG{__DIE__} = sub { rmdir "$prefix_file.lock"; };
                if (mkdir "$prefix_file.lock", 0755) {
                    mb::_open_w(my $fh, $prefix_file_oo) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file_oo\n";
                    print {$fh} mb::parse();
                    close $fh;
                    rmdir "$prefix_file.lock";
                }
                else {
                    confess "$0(@{[__LINE__]}): can't mkdir: $prefix_file.lock\n";
                }
            }
            $INC{$file} = $prefix_file_oo;

            # run as Perl script
            # must use CORE::do to use <DATA>, because CORE::eval cannot do it
            # moreover "goto &CORE::do" doesn't work
            return CORE::eval sprintf(<<'END', (caller)[0,2,1]);
package %s;
#line %s "%s"
CORE::do "$prefix_file_oo";
END
        }
    }
    confess "Can't find $file in \@INC";
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
        while ($expr =~ s{\A [\x20]* ( "(?:$x)+?" | (?:(?!["\x20])$x)+ ) }{}xms) {
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
            if (my($dir) = $pattern =~ m{\A ($x*) \\ }xms) {
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
    local $_ = @_ ? $_[0] : $_;

    # run as Perl script in caller package
    return CORE::eval sprintf(<<'END', (caller)[0,2,1], mb::parse());
package %s;
#line %s "%s"
%s
END
}

#---------------------------------------------------------------------
# getc() for MBCS encoding
sub mb::getc (;*) {
    my $fh = @_ ? shift(@_) : \*STDIN;
    confess 'Too many arguments for mb::getc' if @_ and not wantarray;
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
    elsif ($script_encoding =~ /\A (?: utf8 | wtf8 ) \z/xms) {
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
        if (CORE::substr($str,$pos) =~ /\A($x)/oxms) {
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
    local $_ = @_ ? $_[0] : $_;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
    return join '', map { {qw( A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z )}->{$_}||$_ } /\G$x/g;
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
}

#---------------------------------------------------------------------
# universal lcfirst() for MBCS encoding
sub mb::lcfirst (;$) {
    local $_ = @_ ? $_[0] : $_;
    if (/\A($x)(.*)\z/s) {
        return mb::lc($1) . $2;
    }
    else {
        return '';
    }
}

#---------------------------------------------------------------------
# length() for MBCS encoding
sub mb::length (;$) {
    local $_ = @_ ? $_[0] : $_;
    return scalar(() = /\G$x/g);
}

#---------------------------------------------------------------------
# ord() for MBCS encoding
sub mb::ord (;$) {
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
# require for MBCS encoding
sub mb::require (;$) {
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

                # poor "make"
                (my $prefix_file_oo = $prefix_file) =~ s{\A (.*) \. ([^.]+) \z}{$1.oo.$2}xms;
                if (
                    (not -e $prefix_file_oo)                        or
                    (mtime($prefix_file_oo) <= mtime($prefix_file)) or
                    (mtime($prefix_file_oo) <= mtime(__FILE__))
                ) {
                    mb::_open_r(my $fh, $prefix_file) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file\n";
                    local $_ = CORE::do { local $/; <$fh> };
                    close $fh;

                    # poor file locking
                    local $SIG{__DIE__} = sub { rmdir "$prefix_file.lock"; };
                    if (mkdir "$prefix_file.lock", 0755) {
                        mb::_open_w(my $fh, $prefix_file_oo) or confess "$0(@{[__LINE__]}): can't open file: $prefix_file_oo\n";
                        print {$fh} mb::parse();
                        close $fh;
                        rmdir "$prefix_file.lock";
                    }
                    else {
                        confess "$0(@{[__LINE__]}): can't mkdir: $prefix_file.lock\n";
                    }
                }
                $INC{$_} = $prefix_file_oo;

                # run as Perl script
                # must use CORE::do to use <DATA>, because CORE::eval cannot do it.
                local $@;
                my $result = CORE::eval sprintf(<<'END', (caller)[0,2,1]);
package %s;
#line %s "%s"
CORE::do "$prefix_file_oo";
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
# reverse() for MBCS encoding
sub mb::reverse (@) {

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
        if (CORE::substr($str,$pos) =~ /\A($x)/oxms) {
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
# get OSNAME
sub mb::get_OSNAME () {
    return $OSNAME;
}

#---------------------------------------------------------------------
# set script encoding name and more
sub mb::set_script_encoding ($) {
    $script_encoding = $_[0];

    # over US-ASCII
    $over_ascii = {
        'sjis'      => '(?>[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x80-\xFF])',                         # shift_jis ANSI/OEM Japanese; Japanese (Shift-JIS)
        'gbk'       => '(?>[\x81-\xFE][\x00-\xFF])',                                              # gb2312 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
        'uhc'       => '(?>[\x81-\xFE][\x00-\xFF])',                                              # ks_c_5601-1987 ANSI/OEM Korean (Unified Hangul Code)
        'big5'      => '(?>[\x81-\xFE][\x00-\xFF])',                                              # big5 ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)
        'big5hkscs' => '(?>[\x81-\xFE][\x00-\xFF])',                                              # HKSCS support on top of traditional Chinese Windows
        'eucjp'     => '(?>[\xA1-\xFE][\x00-\xFF])',                                              # EUC-JP Japanese (JIS 0208-1990 and 0121-1990)
        'gb18030'   => '(?>[\x81-\xFE][\x30-\x39][\x81-\xFE][\x30-\x39]|[\x81-\xFE][\x00-\xFF])', # GB18030 Windows XP and later: GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)
    #   'utf8'      => '(?>[\xC2-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF][\x80-\xBF]|[\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF])', # utf-8 Unicode (UTF-8) RFC2279
        'utf8'      => '(?>[\xE1-\xEC][\x80-\xBF][\x80-\xBF]|[\xC2-\xDF][\x80-\xBF]|[\xEE-\xEF][\x80-\xBF][\x80-\xBF]|[\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]|[\xE0-\xE0][\xA0-\xBF][\x80-\xBF]|[\xED-\xED][\x80-\x9F][\x80-\xBF]|[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]|[\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF])', # utf-8 Unicode (UTF-8) optimized RFC3629 for ja_JP
        'wtf8'      => '(?>[\xE1-\xEF][\x80-\xBF][\x80-\xBF]|[\xC2-\xDF][\x80-\xBF]|[\xE0-\xE0][\xA0-\xBF][\x80-\xBF]|[\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]|[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]|[\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF])',                                                                     # optimized WTF-8 for ja_JP
    }->{$script_encoding} || '[\x80-\xFF]';

    # supports qr/./ in MBCS script
    $x = qr/(?>$over_ascii|[\x00-\x7F])/;

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

    if ($script_encoding =~ /\A (?: utf8 | wtf8 ) \z/xms) {
        ${mb::_anchor} = qr{.*?}xms;
    }
    elsif ($] >= 5.030000) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,65534}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    elsif ($] >= 5.010001) {
        ${mb::_anchor} = {
            'sjis'      => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\x9F\xE0-\xFC]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?>[\x81-\x9F\xE0-\xFC][\x81-\x9F\xE0-\xFC])*?))}xms,
            'eucjp'     => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\xA1-\xFE\xA1-\xFE]+\z).*?|.*?[^\xA1-\xFE\xA1-\xFE](?>[\xA1-\xFE\xA1-\xFE][\xA1-\xFE\xA1-\xFE])*?))}xms,
            'gbk'       => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'uhc'       => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5'      => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'big5hkscs' => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
            'gb18030'   => qr{(?(?=.{0,32766}\z)(?:$x)*?|(?(?=[^\x81-\xFE\x81-\xFE]+\z).*?|.*?[^\x81-\xFE\x81-\xFE](?>[\x81-\xFE\x81-\xFE][\x81-\xFE\x81-\xFE])*?))}xms,
        }->{$script_encoding} || die;
    }
    else {
        ${mb::_anchor} = qr{(?:$x)*?}xms;
    }

    # codepoint class shortcuts in qq-like regular expression
    @{mb::_dot} = "(?>$over_ascii|.)"; # supports /s modifier by /./
    @{mb::_B} = "(?:(?<![$bare_w])(?![$bare_w])|(?<=[$bare_w])(?=[$bare_w]))";
    @{mb::_D} = "(?:(?![0-9])$x)";
    @{mb::_H} = "(?:(?![\\x09\\x20])$x)";
    @{mb::_N} = "(?:(?!\\n)$x)";
    @{mb::_R} = "(?>\\r\\n|[\\x0A\\x0B\\x0C\\x0D])";
    @{mb::_S} = "(?:(?![\\t\\n\\f\\r\\x20])$x)";
    @{mb::_V} = "(?:(?![\\x0A\\x0B\\x0C\\x0D])$x)";
    @{mb::_W} = "(?:(?![A-Za-z0-9_])$x)";
    @{mb::_b} = "(?:(?<![$bare_w])(?=[$bare_w])|(?<=[$bare_w])(?![$bare_w]))";
    @{mb::_d} = "[0-9]";
    @{mb::_h} = "[\\x09\\x20]";
    @{mb::_s} = "[\\t\\n\\f\\r\\x20]";
    @{mb::_v} = "[\\x0A\\x0B\\x0C\\x0D]";
    @{mb::_w} = "[A-Za-z0-9_]";
}

#---------------------------------------------------------------------
# get script encoding name
sub mb::get_script_encoding () {
    return $script_encoding;
}

#---------------------------------------------------------------------
# substr() for MBCS encoding
BEGIN {
    CORE::eval sprintf <<'END', ($] >= 5.014) ? ':lvalue' : '';
#                      VV------------------------AAAAAAA
sub mb::substr ($$;$$) %s {
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
}

#---------------------------------------------------------------------
# tr/// and y/// for MBCS encoding
sub mb::tr ($$$;$) {
    my @x           = $_[0] =~ /\G($x)/xmsg;
    my @search      = list_all_ASCII_by_hyphen($_[1] =~ /\G(\\-|$x)/xmsg);
    my @replacement = list_all_ASCII_by_hyphen($_[2] =~ /\G(\\-|$x)/xmsg);
    my %modifier    = (defined $_[3]) ? (map { $_ => 1 } CORE::split //, $_[3]) : ();

    my %tr = ();
    for (my $i=0; $i <= $#search; $i++) {

        # tr/AAA/123/ works as tr/A/1/
        if (not exists $tr{$search[$i]}) {

            # tr/ABC/123/ makes %tr = ('A'=>'1','B'=>'2','C'=>'3',);
            if (defined($replacement[$i]) and ($replacement[$i] ne '')) {
                $tr{$search[$i]} = $replacement[$i];
            }

            # tr/ABC/12/d makes %tr = ('A'=>'1','B'=>'2','C'=>'',);
            elsif (exists $modifier{d}) {
                $tr{$search[$i]} = '';
            }

            # tr/ABC/12/ makes %tr = ('A'=>'1','B'=>'2','C'=>'2',);
            elsif (defined($replacement[-1]) and ($replacement[-1] ne '')) {
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
    local $_ = @_ ? $_[0] : $_;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
    return join '', map { {qw( a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z )}->{$_}||$_ } /\G$x/g;
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
}

#---------------------------------------------------------------------
# universal ucfirst() for MBCS encoding
sub mb::ucfirst (;$) {
    local $_ = @_ ? $_[0] : $_;
    if (/\A($x)(.*)\z/s) {
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
            return CORE::eval('$' . ($_[0] + 1));
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
            return CORE::eval('$' . $_[0]);
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
    if (defined $&) {
        if ($mb::last_s_passed) {
            if (defined($1) and (CORE::substr($&, 0, CORE::length($1)) eq $1)) {
                return CORE::substr($&, CORE::length($1));
            }
            else {
                confess 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
            }
        }
        else {
            if (defined($1) and (CORE::substr($&, -CORE::length($1)) eq $1)) {
                return $1;
            }
            else {
                confess 'Use of "$&", $MATCH, and ${^MATCH} need to /( capture all )/ in regexp';
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
    if (defined $&) {
        if ($mb::last_s_passed) {
            return $1;
        }
        else {
            if (defined($1) and (CORE::substr($&,-CORE::length($1)) eq $1)) {
                return CORE::substr($&, 0, -CORE::length($1));
            }
            else {
                confess 'Use of "$`", $PREMATCH, and ${^PREMATCH} need to /( capture all )/ in regexp';
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
# ignore space of m/[here]/xx, qr/[here]/xx, s/[here]//xx
sub mb::_ignore_space ($) {
    my($has_space) = @_;
    my $has_no_space = '';

    # parse into elements
    while ($has_space =~ /\G (
        \(\? \^? [a-z]*        [:\)] | # cloister (?^x) (?^x: ...
        \(\? \^? [a-z]*-[a-z]+ [:\)] | # cloister (?^x-y) (?^x-y: ...
        \[ ((?: \\@{mb::_dot} | @{mb::_dot} )+?) \] |
        \\x\{ [0-9A-Fa-f]{2} \}      |
        \\o\{ [0-7]{3}       \}      |
        \\x   [0-9A-Fa-f]{2}         |
        \\    [0-7]{3}               |
        \\@{mb::_dot}                |
        @{mb::_dot}
    ) /xmsgc) {
        my($element, $classmate) = ($1, $2);

        # in codepoint class
        if (defined $classmate) {
            $has_no_space .= '[';
            while ($classmate =~ /\G (
                \\x\{ [0-9A-Fa-f]{2} \} |
                \\o\{ [0-7]{3}       \} |
                \\x   [0-9A-Fa-f]{2}    |
                \\    [0-7]{3}          |
                \\@{mb::_dot}           |
                @{mb::_dot}
            ) /xmsgc) {
                my $element = $1;
                if ($element !~ /\A[$bare_s]\z/) {
                    $has_no_space .= $element;
                }
            }
            $has_no_space .= ']';
        }

        # out of codepoint class
        else {
            $has_no_space .= $element;
        }
    }
    return $has_no_space;
}

#---------------------------------------------------------------------
# ignore case of m//i, qr//i, s///i
sub mb::_ignorecase ($) {
    my($has_case) = @_;
    my $has_no_case = '';

    # parse into elements
    while ($has_case =~ /\G (
        \(\? \^? [a-z]*        [:\)] | # cloister (?^x) (?^x: ...
        \(\? \^? [a-z]*-[a-z]+ [:\)] | # cloister (?^x-y) (?^x-y: ...
        \[ ((?: \\@{mb::_dot} | @{mb::_dot} )+?) \] |
        \\x\{ [0-9A-Fa-f]{2} \}      |
        \\o\{ [0-7]{3}       \}      |
        \\x   [0-9A-Fa-f]{2}         |
        \\    [0-7]{3}               |
        \\@{mb::_dot}                |
        @{mb::_dot}
    ) /xmsgc) {
        my($element, $classmate) = ($1, $2);

        # in codepoint class
        if (defined $classmate) {
            $has_no_case .= '[';
            while ($classmate =~ /\G (
                \\x\{ [0-9A-Fa-f]{2} \} |
                \\o\{ [0-7]{3}       \} |
                \\x   [0-9A-Fa-f]{2}    |
                \\    [0-7]{3}          |
                \\@{mb::_dot}           |
                @{mb::_dot}
            ) /xmsgc) {
                my $element = $1;
                $has_no_case .= {qw(
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
            $has_no_case .= ']';
        }

        # out of codepoint class
        else {
            $has_no_case .= {qw(
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
    return qr{$has_no_case};
}

#---------------------------------------------------------------------
# custom codepoint class in qq-like regular expression
sub mb::_cc ($) {
    my($classmate) = @_;
    if ($classmate =~ s{\A \^ }{}xms) {
        return '(?:(?!' . parse_re_codepoint_class($classmate) . ")$x)";
    }
    else {
        return '(?:(?=' . parse_re_codepoint_class($classmate) . ")$x)";
    }
}

#---------------------------------------------------------------------
# makes clustered codepoint from string
sub mb::_clustered_codepoint ($) {
    if (my @codepoint = $_[0] =~ /\G($x)/xmsgc) {
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
    $_[0] = \do { local *_ } if $] < 5.006;
    return open($_[0], ">> $_[1]");
}

#---------------------------------------------------------------------
# open for read by undefined filehandle
sub mb::_open_r ($$) {
    $_[0] = \do { local *_ } if $] < 5.006;
    return open($_[0], $_[1]);
}

#---------------------------------------------------------------------
# open for write by undefined filehandle
sub mb::_open_w ($$) {
    $_[0] = \do { local *_ } if $] < 5.006;
    return open($_[0], "> $_[1]");
}

#---------------------------------------------------------------------
# split() for MBCS encoding
sub mb::_split (;$$$) {
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
            \\ $x              |
            \# .*? $           | # comment on /x modifier
            \(\?\# (?:$x)*? \) |
            \[ (?:$x)+? \]     |
            \(\?               |
            \(\+               |
            \(\*               |
            $x                 |
            [\x00-\xFF]
        ) }xgc;
    }
    else {
        @parsed = $pattern =~ m{ \G (
            \\ $x              |
            \(\?\# (?:$x)*? \) |
            \[ (?:$x)+? \]     |
            \(\?               |
            \(\+               |
            \(\*               |
            $x                 |
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
        while ((--$limit > 0) and ($string =~ s<\A((?:$x)$substring_quantifier)$pattern><>)) {
            for (my $n_th=1; $n_th <= $last_match_no; $n_th++) {
                push @split, CORE::eval('$'.$n_th);
            }
        }
    }

    # if $_[2] is omitted or zero or negative
    else {
        CORE::eval q{ no warnings }; # avoid: Complex regular subexpression recursion limit (nnnnn) exceeded at ...

        # gets substrings by repeat chopping by pattern
        while ($string =~ s<\A((?:$x)$substring_quantifier)$pattern><>) {
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
# chdir() for MSWin32
sub mb::_chdir (;$) {

    # not on MSWin32 or UTF-8
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        if (@_ == 0) {
            return CORE::chdir;
        }
        else {
            return CORE::chdir $_[0];
        }
    }

    # on MSWin32
    if (@_ == 0) {
        return CORE::chdir;
    }
    elsif (($script_encoding =~ /\A (?: sjis ) \z/xms) and ($_[0] =~ /\A $x* [\x81-\x9F\xE0-\xFC][\x5C] \z/xms)) {
        if (defined wantarray) {
            return 0;
        }
        else {
            confess "mb::_chdir: Can't chdir '$_[0]'\n";
        }
    }
    elsif (($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and ($_[0] =~ /\A $x* [\x81-\xFE][\x5C] \z/xms)) {
        if (defined wantarray) {
            return 0;
        }
        else {
            confess "mb::_chdir: Can't chdir '$_[0]'\n";
        }
    }
    else {
        return CORE::chdir $_[0];
    }
}

#---------------------------------------------------------------------
# stackable filetest -X -Y -Z for MSWin32
sub mb::_filetest {
    my @filetest = map { /(-[A-Za-z])/g } @{ shift(@_) };
    local $_ = @_ ? shift : (($filetest[-1] eq '-t') ? \*STDIN : $_);
    confess "Too many arguments for filetest @filetest" if @_ and not wantarray;

    # testee has "\x5C" octet at end
    if (
        ($OSNAME =~ /MSWin32/) and
        ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and
        /[\x5C]\z/
    ) {
        $_ = qq{$_.};
    }

    # supports stackable filetest
    my $result;
    my $filetest = pop @filetest;
    if ($result = CORE::eval($filetest . ' $_')) { # '$_' at 1st time, and ...
    }
    else {
        return wantarray ? ($result, @_) : $result;
    }
    for my $filetest (CORE::reverse @filetest) {
        if ($result = CORE::eval($filetest . ' _')) { # '_' at 2nd time or later
        }
        else {
            return wantarray ? ($result, @_) : $result;
        }
    }
    return wantarray ? ($result, @_) : $result;
}

#---------------------------------------------------------------------
# lstat() for MSWin32
sub mb::_lstat (;$) {
    local $_ = @_ ? $_[0] : $_;
    if ($_ eq '_') {
        confess qq{lstat doesn't support '_'\n};
    }

    # testee has "\x5C" octet at end
    if (
        ($OSNAME =~ /MSWin32/) and
        ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and
        /[\x5C]\z/
    ) {
        $_ = qq{$_.};
    }

    return CORE::lstat $_;
}

#---------------------------------------------------------------------
# opendir() for MSWin32
sub mb::_opendir ($$) {
    if (not defined $_[0]) {
        $_[0] = \do { local *_ };
    }

    # works on MSWin32 only
    if (($OSNAME !~ /MSWin32/) or ($script_encoding !~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms)) {
        return CORE::opendir $_[0], $_[1];
    }
    elsif (-d $_[1]) {
        return CORE::opendir $_[0], $_[1];
    }
    elsif (-d qq{$_[1].}) {
        return CORE::opendir $_[0], qq{$_[1].};
    }
    return undef;
}

#---------------------------------------------------------------------
# stat() for MSWin32
sub mb::_stat (;$) {
    local $_ = @_ ? $_[0] : $_;

    # testee has "\x5C" octet at end
    if (
        ($OSNAME =~ /MSWin32/) and
        ($script_encoding =~ /\A (?: sjis | gbk | uhc | big5 | big5hkscs | gb18030 ) \z/xms) and
        /[\x5C]\z/
    ) {
        $_ = qq{$_.};
    }

    return CORE::stat $_;
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

######################################################################
# source code filter
######################################################################

#---------------------------------------------------------------------
# detect system encoding any of big5, big5hkscs, eucjp, gb18030, gbk, sjis, uhc, utf8, wtf8
sub detect_system_encoding {

    # running on Microsoft Windows
    if ($OSNAME =~ /MSWin32/) {
        if (my($codepage) = qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/) {
            return {qw(
                932   sjis
                936   gbk
                949   uhc
                950   big5
                951   big5hkscs
                20932 eucjp
                54936 gb18030
            )}->{$codepage};
        }
        else {
            return 'utf8';
        }
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

my @here_document_delimiter = ();

#---------------------------------------------------------------------
# parse script
sub parse {
    local $_ = @_ ? $_[0] : $_;

    # Yes, I studied study yesterday, once again.
    study $_; # acts between perl 5.005 to perl 5.014

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
# parse ambiguous characters
sub parse_ambiguous_char {
    my $parsed = '';

    # Ambiguous characters
    # --------------------------------------------------------
    # Character   Operator          Term
    # --------------------------------------------------------
    # %           modulo            %hash
    # &           &, &&             &subroutine
    # '           package           'string'
    # *           multiplication    *typeglob
    # +           addition          unary plus
    # -           subtraction       unary minus
    # .           concatenation     .3333
    # /           division          /pattern/
    # <           less than         <>, <HANDLE>, <fileglob>
    # <<          left shift        <<HERE, <<~HERE, <<>>
    # ?           ?:                ?pattern?
    # --------------------------------------------------------

    # any term then operator
    # "\x25" [%] PERCENT SIGN (U+0025)
    # "\x26" [&] AMPERSAND (U+0026)
    # "\x2A" [*] ASTERISK (U+002A)
    # "\x2E" [.] FULL STOP (U+002E)
    # "\x2F" [/] SOLIDUS (U+002F)
    # "\x3C" [<] LESS-THAN SIGN (U+003C)
    # "\x3F" [?] QUESTION MARK (U+003F)
    if (/\G ( \s* (?:
        %=     | %    |
        &&=    | &&   | &\.= | &\. | &= | & |
        \*\*=  | \*\* | \*=  | \*  |
        \.\.\. | \.\. | \.=  | \.  |
        \/\/=  | \/\/ | \/=  | \/  |
        <=>    | <<   | <=   | <   |
        \?
    )) /xmsgc) {
        $parsed .= $1;
    }

    return $parsed;
}

#---------------------------------------------------------------------
# parse expression in script
sub parse_expr {
    my $parsed = '';

    # __END__ or __DATA__
    if (/\G ^ ( (?: __END__ | __DATA__ ) $R .* ) \z/xmsgc) {
        $parsed .= $1;
    }

    # =pod ... =cut
    elsif (/\G ^ ( = [A-Za-z_][A-Za-z_0-9]* [\x00-\xFF]*? $R =cut \b [^\n]* $R ) /xmsgc) {
        $parsed .= $1;
    }

    # "\r\n", "\r", "\n"
    elsif (/\G (?= $R ) /xmsgc) {
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

    # "\t"
    # "\x20" [ ] SPACE (U+0020)
    elsif (/\G ( [\t ]+ ) /xmsgc) {
        $parsed .= $1;
    }

    # "\x3B" [;] SEMICOLON (U+003B)
    elsif (/\G ( ; ) /xmsgc) {
        $parsed .= $1;
    }

    # balanced brackets
    # "\x28" [(] LEFT PARENTHESIS (U+0028)
    # "\x7B" [{] LEFT CURLY BRACKET (U+007B)
    # "\x5B" [[] LEFT SQUARE BRACKET (U+005B)
    elsif (/\G ( [(\{\[] ) /xmsgc) {
        $parsed .= parse_expr_balanced($1);
        $parsed .= parse_ambiguous_char();
    }

    # version string
    # v102.111.111
    # 102.111.111
    elsif (/\G ( 
        v [0-9]+ (?: \.[0-9]+ ){1,} \b |
          [0-9]+ (?: \.[0-9]+ ){2,} \b
    ) /xmsgc) {
        my $v_string = $1;
        $parsed .= join('.', map { "mb::chr($_)" } ($v_string =~ /[0-9]+/g));
        $parsed .= parse_ambiguous_char();
    }

    # version string
    # v9786
    elsif (/\G v ( [0-9]+ ) \b (?! \s* => ) /xmsgc) {
        $parsed .= "mb::chr($1)";
        $parsed .= parse_ambiguous_char();
    }

    # numbers
    # "\x2E" [.] [0-9]
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
    elsif (m{\G (

# since Perl v5.22 adds hexadecimal floating point literals
# https://perldoc.perl.org/perl5220delta#Floating-point-parsing-has-been-improved
# https://perldoc.perl.org/5.32.0/perldata#Scalar-value-constructors

# https://qiita.com/mod_poppo/items/3fa4cdc35f9bfb352ad5
# https://qiita.com/mod_poppo/items/3fa4cdc35f9bfb352ad5#perl
#
# $ perl -l -e 'print(0x1.23); print(0x1.23p0)'
# makes ==> 123
# makes ==> 1.13671875

        0[Xx] [0-9A-Fa-f_]+ \. [0-9A-Fa-f_]* [Pp] [+-]? [0-9_]+ |
        0[Xx]               \. [0-9A-Fa-f_]+ [Pp] [+-]? [0-9_]+ |
        0[Xx] [0-9A-Fa-f_]+                                     |

# since perl v5.33.5 Core Enhancements New octal syntax 0oddddd

        0[Oo] [0-7_]+ |
        0     [0-7_]* |

        0[Bb] [01_]+  |

        [1-9] [0-9_]* \. [0-9_]* [Ee] [+-]? [0-9_]+ |
        [1-9] [0-9_]*                               |
                      \. [0-9_]+ [Ee] [+-]? [0-9_]+ |
                      \. [0-9_]+

    ) }xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # file test operators on MSWin32
    # "\x2D" [-] HYPHEN-MINUS (U+002D)

    # -X -Y -Z 'file' --> mb::_filetest [qw( -X -Y -Z )], 'file'
    # -X -Y -Z "file" --> mb::_filetest [qw( -X -Y -Z )], "file"
    # -X -Y -Z `file` --> mb::_filetest [qw( -X -Y -Z )], `file`
    # -X -Y -Z $file  --> mb::_filetest [qw( -X -Y -Z )], $file
    # ..., and filetest any word except file handle or directory handle
    # -X -Y -Z m//    --> mb::_filetest [qw( -X -Y -Z )], m//
    # -X -Y -Z q//    --> mb::_filetest [qw( -X -Y -Z )], q//
    # -X -Y -Z qq//   --> mb::_filetest [qw( -X -Y -Z )], qq//
    # -X -Y -Z qr//   --> mb::_filetest [qw( -X -Y -Z )], qr//
    # -X -Y -Z qw//   --> mb::_filetest [qw( -X -Y -Z )], qw//
    # -X -Y -Z qx//   --> mb::_filetest [qw( -X -Y -Z )], qx//
    # -X -Y -Z s///   --> mb::_filetest [qw( -X -Y -Z )], s///
    # -X -Y -Z tr///  --> mb::_filetest [qw( -X -Y -Z )], tr///
    # -X -Y -Z y///   --> mb::_filetest [qw( -X -Y -Z )], y///
    #          vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #                                                               vvvvvvvvvvvv  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( (?: -[ABCMORSTWXbcdefgkloprstuwxz] \s* )+ \b ) (?= (?: \( \s* )* (?: ' | " | ` | \$ | (?: (?: m | q | qq | qr | qw | qx | s | tr | y ) \b )) ) /xmsgc) {
        $parsed .= "mb::_filetest [qw( $1 )], ";
    }

    # filetest file handle or directory handle
    # -X -Y -Z _    --> mb::_filetest [qw( -X -Y -Z )], \*_
    # -X -Y -Z FILE --> mb::_filetest [qw( -X -Y -Z )], \*FILE
    #          vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #            vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv       vvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( (?: -[ABCMORSTWXbcdefgkloprstuwxz] \s* )+ \b ) (?= [A-Za-z_][A-Za-z0-9_]* ) /xmsgc) {
        $parsed .= "mb::_filetest [qw( $1)], ";
        $parsed .= '\\*';
    }

    # -X -Y -Z ... --> mb::_filetest [qw( -X -Y -Z )], ...
    #          vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #            vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( (?: -[ABCMORSTWXbcdefgkloprstuwxz] \s* )+ \b ) /xmsgc) {
        $parsed .= "mb::_filetest [qw( $1)]";
        if (my $ambiguous_char = parse_ambiguous_char()) {
            $parsed .= $ambiguous_char;
        }
        else {
            $parsed .= ', ';
        }
    }

    # yada-yada or triple-dot operator
    elsif (/\G ( \.\.\. ) /xmsgc) {
        $parsed .= $1;
    }

    # -> and any method
    elsif (/\G ( -> \s* [A-Za-z_][A-Za-z_0-9]* ) /xmsgc) {
        $parsed .= $1;
    }

    # any operators
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
    }

    # $`           --> mb::_PREMATCH()
    # ${`}         --> mb::_PREMATCH()
    # $PREMATCH    --> mb::_PREMATCH()
    # ${PREMATCH}  --> mb::_PREMATCH()
    # ${^PREMATCH} --> mb::_PREMATCH()
    elsif (/\G (?: \$` | \$\{`\} | \$PREMATCH | \$\{PREMATCH\} | \$\{\^PREMATCH\} ) /xmsgc) {
        $parsed .= 'mb::_PREMATCH()';
        $parsed .= parse_ambiguous_char();
    }

    # $&        --> mb::_MATCH()
    # ${&}      --> mb::_MATCH()
    # $MATCH    --> mb::_MATCH()
    # ${MATCH}  --> mb::_MATCH()
    # ${^MATCH} --> mb::_MATCH()
    elsif (/\G (?: \$& | \$\{&\} | \$MATCH | \$\{MATCH\} | \$\{\^MATCH\} ) /xmsgc) {
        $parsed .= 'mb::_MATCH()';
        $parsed .= parse_ambiguous_char();
    }

    # $1 --> mb::_CAPTURE(1)
    # $2 --> mb::_CAPTURE(2)
    # $3 --> mb::_CAPTURE(3)
    elsif (/\G \$ ([1-9][0-9]*) /xmsgc) {
        $parsed .= "mb::_CAPTURE($1)";
        $parsed .= parse_ambiguous_char();
    }

    # @{^CAPTURE} --> mb::_CAPTURE()
    elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
        $parsed .= 'mb::_CAPTURE()';
        $parsed .= parse_ambiguous_char();
    }

    # ${^CAPTURE}[0] --> mb::_CAPTURE(1)
    # ${^CAPTURE}[1] --> mb::_CAPTURE(2)
    # ${^CAPTURE}[2] --> mb::_CAPTURE(3)
    elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_CAPTURE($n_th+1)";
        $parsed .= parse_ambiguous_char();
    }

    # @-                   --> mb::_LAST_MATCH_START()
    # @LAST_MATCH_START    --> mb::_LAST_MATCH_START()
    # @{LAST_MATCH_START}  --> mb::_LAST_MATCH_START()
    # @{^LAST_MATCH_START} --> mb::_LAST_MATCH_START()
    elsif (/\G (?: \@- | \@LAST_MATCH_START | \@\{LAST_MATCH_START\} | \@\{\^LAST_MATCH_START\} ) /xmsgc) {
        $parsed .= 'mb::_LAST_MATCH_START()';
        $parsed .= parse_ambiguous_char();
    }

    # $-[1]                   --> mb::_LAST_MATCH_START(1)
    # $LAST_MATCH_START[1]    --> mb::_LAST_MATCH_START(1)
    # ${LAST_MATCH_START}[1]  --> mb::_LAST_MATCH_START(1)
    # ${^LAST_MATCH_START}[1] --> mb::_LAST_MATCH_START(1)
    elsif (/\G (?: \$- | \$LAST_MATCH_START | \$\{LAST_MATCH_START\} | \$\{\^LAST_MATCH_START\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_LAST_MATCH_START($n_th)";
        $parsed .= parse_ambiguous_char();
    }

    # @+                 --> mb::_LAST_MATCH_END()
    # @LAST_MATCH_END    --> mb::_LAST_MATCH_END()
    # @{LAST_MATCH_END}  --> mb::_LAST_MATCH_END()
    # @{^LAST_MATCH_END} --> mb::_LAST_MATCH_END()
    elsif (/\G (?: \@\+ | \@LAST_MATCH_END | \@\{LAST_MATCH_END\} | \@\{\^LAST_MATCH_END\} ) /xmsgc) {
        $parsed .= 'mb::_LAST_MATCH_END()';
        $parsed .= parse_ambiguous_char();
    }

    # $+[1]                 --> mb::_LAST_MATCH_END(1)
    # $LAST_MATCH_END[1]    --> mb::_LAST_MATCH_END(1)
    # ${LAST_MATCH_END}[1]  --> mb::_LAST_MATCH_END(1)
    # ${^LAST_MATCH_END}[1] --> mb::_LAST_MATCH_END(1)
    elsif (/\G (?: \$\+ | \$LAST_MATCH_END | \$\{LAST_MATCH_END\} | \$\{\^LAST_MATCH_END\} ) \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "mb::_LAST_MATCH_END($n_th)";
        $parsed .= parse_ambiguous_char();
    }

    # CORE::do { block }   --> CORE::do { block }
    # CORE::eval { block } --> CORE::eval { block }
    # CORE::try { block }  --> CORE::try { block }
    elsif (/\G ( CORE:: (?: do | eval | try ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $parsed .= parse_ambiguous_char();
    }

    # mb::do { block }   --> do { block }
    # mb::eval { block } --> eval { block }
    # mb::try { block }  --> try { block }
    # do { block }       --> do { block }
    # eval { block }     --> eval { block }
    # try { block }      --> try { block }
    elsif (/\G (?: mb:: )? ( (?: do | eval | try ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $parsed .= parse_ambiguous_char();
    }

    # $#{}, ${}, @{}, %{}, &{}, *{}, defer {}, sub {}
    # "\x24" [$] DOLLAR SIGN (U+0024)
    elsif (/\G ((?: \$[#] | [\$\@%&*] | defer | sub ) \s* ) ( \{ ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        $parsed .= parse_ambiguous_char();
    }

    # mb::do   --> mb::do
    # CORE::do --> CORE::do
    # do       --> do
    elsif (/\G ( (?: mb:: | CORE:: )? do ) \b /xmsgc) {
        $parsed .= $1;
    }

    # mb::eval   --> mb::eval
    # CORE::eval --> CORE::eval
    # eval       --> eval
    elsif (/\G ( (?: mb:: | CORE:: )? eval ) \b /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # last index of array
    elsif (/\G ( [\$] [#] (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # scalar variable
    elsif (/\G (     [\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | ^\{[A-Za-z_][A-Za-z_0-9]*\} | [0-9]+ | [!"#\$%&'()+,\-.\/:;<=>?\@\[\\\]\^_`|~] ) (?: \s* (?: \+\+ | -- ) )? ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # array variable
    # "\x40" [@] COMMERCIAL AT (U+0040)
    elsif (/\G (   [\@\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | [_] ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # hash variable
    elsif (/\G ( [\%\@\$] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* | [!+\-] ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # user subroutine call
    # type glob
    elsif (/\G (     [&*] [\$]* (?: [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* ) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # comment
    # "\x23" [#] NUMBER SIGN (U+0023)
    elsif (/\G ( [#] [^\n]* ) /xmsgc) {
        $parsed .= $1;
    }

    # 2-quotes

    # '...'
    # "\x27" ['] APOSTROPHE (U+0027)
    elsif (m{\G ( ' ) }xmsgc) {
        $parsed .= parse_q__like_endswith($1);
        $parsed .= parse_ambiguous_char();
    }

    # "...", `...`
    # "\x22" ["] QUOTATION MARK (U+0022)
    # "\x60" [`] GRAVE ACCENT (U+0060)
    elsif (m{\G ( ["`] ) }xmsgc) {
        $parsed .= parse_qq_like_endswith($1);
        $parsed .= parse_ambiguous_char();
    }

    # /.../
    elsif (m{\G ( [/] ) }xmsgc) {
        my $regexp = parse_re_endswith('m',$1);
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # ?...?
    elsif (m{\G ( [?] ) }xmsgc) {
        my $regexp = parse_re_endswith('m',$1);
        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('m{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # <<>> double-diamond operator
    elsif (/\G ( <<>> ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # <FILE> diamond operator
    # <${file}>
    # <$file>
    # <fileglob>
    elsif (/\G (<) ((?:(?!\s)$x)*?) (>) /xmsgc) {
        my($open_bracket, $quotee, $close_bracket) = ($1, $2, $3);
        $parsed .= $open_bracket;
        while ($quotee =~ /\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $parsed .= parse_ambiguous_char();
    }

    # qw/.../, q/.../
    elsif (/\G ( qw | q ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_q__like_balanced($1); }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_q__like_balanced($1); }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # qq/.../
    elsif (/\G ( qq ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); } # qq'...' works as "..."
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_qq_like_endswith($1); } # qq'...' works as "..."
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # qx/.../
    elsif (/\G ( qx ) \b /xmsgc) {
        $parsed .= $1;
        if    (/\G ( [#] )        /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( ['] )        /xmsgc) { $parsed .= parse_q__like_endswith($1); }
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
        elsif (m{\G( [/] )        }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( [\S] )       /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( ['] )          /xmsgc) { $parsed .= parse_q__like_endswith($1); }
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $parsed .= parse_qq_like_balanced($1); }
            elsif (m{\G( [/] )          }xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            elsif (/\G ( [\S] )         /xmsgc) { $parsed .= parse_qq_like_endswith($1); }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # m/.../, qr/.../
    elsif (/\G ( m | qr ) \b /xmsgc) {
        $parsed .= $1;
        my $regexp = '';
        if    (/\G ( [#] )        /xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr#...#
        elsif (/\G ( ['] )        /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); }       # qr'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp .= parse_re_balanced('m',$1);      }       # qr{...}
        elsif (m{\G( [/] )        }xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr/.../
        elsif (/\G ( [:\@] )      /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # qr@...@
        elsif (/\G ( [\S] )       /xmsgc) { $regexp .= parse_re_endswith('m',$1);      }       # qr?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp .= $1;                      # qr SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE A...A
            elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); } # qr SPACE '...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('m',$1);      } # qr SPACE {...}
            elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE /.../
            elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # qr SPACE @...@
            elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # qr SPACE ?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('{\\G${mb::_anchor}@{[mb::_ignorecase(qr%s%s)]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('{\\G${mb::_anchor}@{[' .            'qr%s%s ]}@{[mb::_m_passed()]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
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
        elsif (/\G ( [:\@] )      /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('s',$1)) . '`');
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
            elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('s',$1)) . '`');
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

        # s##qq-quotee#
        elsif ($replacement[0] =~ /\A [#] /xms) {
            $replacement = 'qq' . $replacement[0]; # qq-type quotee
        }

        # s//qq-quotee/
        else {
            $replacement = 'qq ' . $replacement[0]; # qq-type quotee
        }

        # /xx modifier
        if (($modifier_not_cegir =~ tr/x//) >= 2) {
            $regexp = mb::_ignore_space($regexp);
        }

        # /i modifier
        if ($modifier_i) {
            $parsed .= sprintf('{(\\G${mb::_anchor})@{[mb::_ignorecase(qr%s%s)]}@{[mb::_s_passed()]}}%s{$1 . %s%s}e%s', $regexp, $modifier_not_cegir, $comment, $eval, $replacement, $modifier_cegr);
        }
        else {
            $parsed .= sprintf('{(\\G${mb::_anchor})@{[' .            'qr%s%s ]}@{[mb::_s_passed()]}}%s{$1 . %s%s}e%s', $regexp, $modifier_not_cegir, $comment, $eval, $replacement, $modifier_cegr);
        }
        $parsed .= parse_ambiguous_char();
    }

    # tr/.../.../, y/.../.../
    elsif (/\G (?: tr | y ) \b /xmsgc) {
        $parsed .= 's'; # not 'tr'
        my $search = '';
        my $comment = '';
        my $replacement = '';
        if    (/\G ( [#] )        /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr#...#...#
        elsif (/\G ( ['] )        /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr'...'...'
        elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $search .= parse_tr_like_balanced($1);                                                     # tr{...}...
            if    (/\G ( [#] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}#...#
            elsif (/\G ( ['] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                          # tr{}{...}
            elsif (m{\G( [/] )        }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}/.../
            elsif (/\G ( [\S] )       /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                          # tr{}?...?
            elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                        # tr{} SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $comment .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                    # tr{} SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE /.../
                elsif (/\G ( [\S] )         /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                    # tr{} SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        elsif (m{\G( [/] )        }xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr/.../.../
        elsif (/\G ( [\S] )       /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); }       # tr?...?...?
        elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1;                                                                             # tr SPACE ...
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE A...A...A
            elsif (/\G ( ['] )          /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE '...'...'
            elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $search .= parse_tr_like_balanced($1);                                               # tr SPACE {...}...
                if    (/\G ( [#] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}#...#
                elsif (/\G ( ['] )        /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}'...'
                elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                      # tr SPACE {}{...}
                elsif (m{\G( [/] )        }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}/.../
                elsif (/\G ( [\S] )       /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                      # tr SPACE {}?...?
                elsif (/\G ( \s+ )        /xmsgc) { $comment .= $1;                                                                    # tr SPACE {} SPACE ...
                    while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                        $comment .= $1;
                    }
                    if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE A...A
                    elsif (/\G ( ['] )          /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE '...'
                    elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $replacement .= parse_tr_like_balanced($1); }                                # tr SPACE {} SPACE {...}
                    elsif (m{\G( [/] )          }xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE /.../
                    elsif (/\G ( [\S] )         /xmsgc) { $replacement .= parse_tr_like_endswith($1); }                                # tr SPACE {} SPACE ?...?
                    else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
                }
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            elsif (m{\G( [/] )          }xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE /.../.../
            elsif (/\G ( [\S] )         /xmsgc) { $search .= parse_tr_like_endswith($1); $replacement .= parse_tr_like_endswith($1); } # tr SPACE ?...?...?
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

        # modifier
        my($modifier_not_r, $modifier_r) = parse_tr_modifier();
        if ($modifier_r) {
            $parsed .= sprintf(q<{[\x00-\xFF]*}%s{mb::tr($&,q%s,q%s,'%sr')}ser>, $comment, $search, $replacement, $modifier_not_r);
        }
        elsif ($modifier_not_r =~ /s/) {

            # this implementation cannot return right count of codepoints replaced.
            # if you want right count, you can call mb::tr() yourself.
            $parsed .= sprintf(q<{[\x00-\xFF]+}%s{mb::tr($&,q%s,q%s,'%sr')}se>,  $comment, $search, $replacement, $modifier_not_r);
        }
        else {

            # $parsed .= sprintf(q<{@{mb::_dot}}%s{mb::tr($&,q%s,q%s,'%sr')}msge>, $comment, $search, $replacement, $modifier_not_r);
            #------------------------------------------------------------------------------------------------------------------------------------------------
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/;    ($r,$_) } => (9,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/s;   ($r,$_) } => (9,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/d;   ($r,$_) } => (9,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/ds;  ($r,$_) } => (9,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/c;   ($r,$_) } => (9,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cs;  ($r,$_) } => (9,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cd;  ($r,$_) } => (9,AAABBCA)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cds; ($r,$_) } => (9,AAABBCA)

            # $parsed .= sprintf(q<{[\x00-\xFF]*}%s{mb::tr($&,q%s,q%s,'%sr')}msge>, $comment, $search, $replacement, $modifier_not_r);
            #------------------------------------------------------------------------------------------------------------------------------------------------
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/;    ($r,$_) } => (2,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/s;   ($r,$_) } => (2,12DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/d;   ($r,$_) } => (2,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/ds;  ($r,$_) } => (2,12DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/c;   ($r,$_) } => (2,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cs;  ($r,$_) } => (2,AAABBC2A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cd;  ($r,$_) } => (2,AAABBCA)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cds; ($r,$_) } => (2,AAABBCA)

            # if ($modifier_not_r =~ /c/) {
            #     $parsed .= sprintf(q<{@{[mb::_cc(q[^%s])]}}%s{mb::tr($&,q%s,q%s,'%sr')}msge>, $search, $comment, $search, $replacement, $modifier_not_r);
            # }
            # else {
            #     $parsed .= sprintf(q<{@{[mb::_cc(q[%s])]}}%s{mb::tr($&,q%s,q%s,'%sr')}msge>, $search, $comment, $search, $replacement, $modifier_not_r);
            # }
            #------------------------------------------------------------------------------------------------------------------------------------------------
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/;    ($r,$_) } => (7,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/s;   ($r,$_) } => (7,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/d;   ($r,$_) } => (7,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/ds;  ($r,$_) } => (7,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/c;   ($r,$_) } => (2,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cs;  ($r,$_) } => (2,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cd;  ($r,$_) } => (2,AAABBCA)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cds; ($r,$_) } => (2,AAABBCA)

            # better idea of mine
            if ($modifier_not_r =~ /c/) {
                $parsed .= sprintf(q<{(\\G${mb::_anchor})((?!%s)@{mb::_dot})}%s{$1.mb::tr($2,q%s,q%s,'%sr')}sge>, codepoint_tr($search), $comment, $search, $replacement, $modifier_not_r);
            }
            else {
                $parsed .= sprintf(q<{(\\G${mb::_anchor})((?=%s)@{mb::_dot})}%s{$1.mb::tr($2,q%s,q%s,'%sr')}sge>, codepoint_tr($search), $comment, $search, $replacement, $modifier_not_r);
            }
            #------------------------------------------------------------------------------------------------------------------------------------------------
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/;    ($r,$_) } => (7,111222DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/s;   ($r,$_) } => (1,12DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/d;   ($r,$_) } => (7,11122DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/ds;  ($r,$_) } => (1,12DE1)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/c;   ($r,$_) } => (2,AAABBC22A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cs;  ($r,$_) } => (1,AAABBC2A)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cd;  ($r,$_) } => (2,AAABBCA)
            # do { $_='AAABBCDEA'; $r=tr/ABC/12/cds; ($r,$_) } => (1,AAABBCA)
        }
        $parsed .= parse_ambiguous_char();
    }

    # indented here document
    elsif (/\G ( <<~ ) /xmsgc) {
        $parsed .= $1;
        if    (/\G (         ([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; }
        elsif (/\G (       \\([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* '([A-Za-z_][A-Za-z_0-9]*)' ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* "([A-Za-z_][A-Za-z_0-9]*)" ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; }
        elsif (/\G ( [\t ]* `([A-Za-z_][A-Za-z_0-9]*)` ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, ["[\\t ]*$2$R", 'qq']; }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # here document
    elsif (/\G ( << ) /xmsgc) {
        $parsed .= $1;
        if    (/\G (         ([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; }
        elsif (/\G (       \\([A-Za-z_][A-Za-z_0-9]*)  ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* '([A-Za-z_][A-Za-z_0-9]*)' ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'q' ]; }
        elsif (/\G ( [\t ]* "([A-Za-z_][A-Za-z_0-9]*)" ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; }
        elsif (/\G ( [\t ]* `([A-Za-z_][A-Za-z_0-9]*)` ) /xmsgc) { $parsed .= $1; push @here_document_delimiter, [       "$2$R", 'qq']; }
        else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
        $parsed .= parse_ambiguous_char();
    }

    # sub subroutine();
    elsif (/\G ( sub \s+ [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)* \s* ) /xmsgc) {
        $parsed .= $1;
    }

    # while (<<>>)
    elsif (/\G ( while \s* \( \s* ) ( <<>> ) ( \s* \) ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
        $parsed .= $3;
    }

    # while (<${file}>)
    # while (<$file>)
    # while (<FILE>)
    # while (<fileglob>)
    elsif (/\G ( while \s* \( \s* ) (<) ((?:(?!\s)$x)*?) (>) ( \s* \) ) /xmsgc) {
        $parsed .= $1;
        my($open_bracket, $quotee, $close_bracket) = ($2, $3, $4);
        my $close_bracket2 = $5;
        $parsed .= $open_bracket;
        while ($quotee =~ /\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
        $parsed .= $close_bracket2;
    }

    # while <<>>
    elsif (/\G ( while \s* ) ( <<>> ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
    }

    # while <${file}>
    # while <$file>
    # while <FILE>
    # while <fileglob>
    elsif (/\G ( while \s* ) (<) ((?:(?!\s)$x)*?) (>) /xmsgc) {
        $parsed .= $1;
        my($open_bracket, $quotee, $close_bracket) = ($2, $3, $4);
        $parsed .= $open_bracket;
        while ($quotee =~ /\G ($x) /xmsgc) {
            $parsed .= escape_qq($1, $close_bracket);
        }
        $parsed .= $close_bracket;
    }

    # if          (expr)
    # elsif       (expr)
    # unless      (expr)
    # while       (expr)
    # until       (expr)
    # given       (expr)
    # when        (expr)
    # CORE::catch (expr)
    # catch       (expr)
    elsif (/\G ( (?: if | elsif | unless | while | until | given | when | (?: CORE:: )? catch ) \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;

        # outputs expr
        my $expr = parse_expr_balanced($2);
        $parsed .= $expr;
    }

    # mb::catch (expr) --> catch (expr)
    elsif (/\G mb:: ( catch \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;

        # outputs expr
        my $expr = parse_expr_balanced($2);
        $parsed .= $expr;
    }

    # else
    elsif (/\G ( else ) \b /xmsgc) {
        $parsed .= $1;
    }

    # ... if     expr;
    # ... unless expr;
    # ... while  expr;
    # ... until  expr;
    elsif (/\G ( if | unless | while | until ) \b /xmsgc) {
        $parsed .= $1;
    }

    # foreach my $var (expr) --> foreach my $var (expr)
    # for     my $var (expr) --> for     my $var (expr)
    elsif (/\G ( (?: foreach | for ) \s+ my \s* [\$] [A-Za-z_][A-Za-z_0-9]* ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
    }

    # foreach $var (expr) --> foreach $var (expr)
    # for     $var (expr) --> for     $var (expr)
    elsif (/\G ( (?: foreach | for ) \s* [\$] [\$]* (?: \{[A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]*)*\} | [A-Za-z_][A-Za-z_0-9]*(?:(?:'|::)[A-Za-z_][A-Za-z_0-9]* ) ) ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
    }

    # foreach (expr1; expr2; expr3) --> foreach (expr1; expr2; expr3)
    # foreach (expr)                --> foreach (expr)
    # for     (expr1; expr2; expr3) --> for     (expr1; expr2; expr3)
    # for     (expr)                --> for     (expr)
    elsif (/\G ( (?: foreach | for ) \s* ) ( \( ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
    }

    # CORE::split --> mb::_split
    # mb::split   --> mb::_split
    # split       --> mb::_split
    elsif (/\G (?: CORE:: | mb:: )? ( split ) \b /xmsgc) {
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

        # split /^/   --> mb::_split qr/^/m
        # split /.../ --> mb::_split qr/.../
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

            # /xx modifier
            if (($modifier_not_cegir =~ tr/x//) >= 2) {
                $regexp = mb::_ignore_space($regexp);
            }

            # /i modifier
            if ($modifier_i) {
                $parsed .= sprintf('{@{[mb::_ignorecase(qr%s%s)]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
            else {
                $parsed .= sprintf('{@{[' .            'qr%s%s ]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
        }

        # split m/^/   --> mb::_split qr/^/m
        # split m/.../ --> mb::_split qr/.../
        elsif (/\G ( m | qr ) \b /xmsgc) {
            $parsed .= "qr";

            if    (/\G ( [#] )        /xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr#...#
            elsif (/\G ( ['] )        /xmsgc) { $regexp = parse_re_as_q_endswith('m',$1); }        # split qr'...'
            elsif (/\G ( [\(\{\[\<] ) /xmsgc) { $regexp = parse_re_balanced('m',$1);      }        # split qr{...}
            elsif (m{\G( [/] )        }xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr/.../
            elsif (/\G ( [:\@] )      /xmsgc) { $regexp = ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # split qr@...@
            elsif (/\G ( [\S] )       /xmsgc) { $regexp = parse_re_endswith('m',$1);      }        # split qr?...?
            elsif (/\G ( \s+ )        /xmsgc) { $parsed .= $1; $regexp = $1;                       # split qr SPACE ...
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $parsed .= $1;
                }
                if    (/\G ( [A-Za-z_0-9] ) /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE A...A
                elsif (/\G ( ['] )          /xmsgc) { $regexp .= parse_re_as_q_endswith('m',$1); } # split qr SPACE '...'
                elsif (/\G ( [\(\{\[\<] )   /xmsgc) { $regexp .= parse_re_balanced('m',$1);      } # split qr SPACE {...}
                elsif (m{\G( [/] )          }xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE /.../
                elsif (/\G ( [:\@] )        /xmsgc) { $regexp .= ('`' . quotee_of(parse_re_endswith('m',$1)) . '`'); } # split qr SPACE @...@
                elsif (/\G ( [\S] )         /xmsgc) { $regexp .= parse_re_endswith('m',$1);      } # split qr SPACE ?...?
                else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }
            }
            else { die "$0(@{[__LINE__]}): $ARGV[0] has not closed:\n", $parsed; }

            my($modifier_i, $modifier_not_cegir, $modifier_cegr) = parse_re_modifier();

            if ($modifier_not_cegir !~ /m/xms) {
                $modifier_not_cegir .= 'm';
            }

            # /xx modifier
            if (($modifier_not_cegir =~ tr/x//) >= 2) {
                $regexp = mb::_ignore_space($regexp);
            }

            # /i modifier
            if ($modifier_i) {
                $parsed .= sprintf('{@{[mb::_ignorecase(qr%s%s)]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
            else {
                $parsed .= sprintf('{@{[' .            'qr%s%s ]}}%s', $regexp, $modifier_not_cegir, $modifier_cegr);
            }
        }

        $parsed .= parse_ambiguous_char();
    }

    # provides bare Perl and JPerl compatible functions
    elsif (/\G ( (?: lc | lcfirst | uc | ucfirst ) ) \b /xmsgc) {
        $parsed .= "mb::$1";
        $parsed .= parse_ambiguous_char();
    }

    # CORE::require, mb::require, require
    elsif (/\G ( (?: CORE:: | mb:: )? require ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # mb::use --> BEGIN { mb::require ... }
    # mb::no  --> BEGIN { mb::require ... }
    elsif (/\G ( mb::use | mb::no ) \b /xmsgc) {
        my $method = { 'mb::use'=>'import', 'mb::no'=>'unimport' }->{$1} || die;
        $parsed .= "BEGIN { mb::require";
        while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
            $parsed .= $1;
        }
        if (/\G ( [A-Za-z_][A-Za-z_0-9]* (?: ::[A-Za-z_][A-Za-z_0-9]*)* ) /xmsgc) {
            my $module = $1;
            $parsed .= qq{'$module';};
            while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                $parsed .= $1;
            }
            if (/\G ( [0-9]+ (?: \.[0-9]+)* ) /xmsgc) {
                my $version = $1;
                $parsed .= qq{$module->VERSION($version);};
                while (/\G ( \s+ | [#] [^\n]* ) /xmsgc) {
                    $parsed .= $1;
                }
            }
            my $list = parse_expr_endswith(qr< [;\}] | \z >xms);
            if ($list eq '') {
                $parsed .= qq{ $module->$method; };
            }
            elsif (scalar(CORE::eval("()=$list")) == 0) {
            }
            else {
                $parsed .= qq{ $module->$method($list); };
            }
        }
        $parsed .= "}";
    }

    # mb::getc() --> mb::getc()
    #                       vvvvvvvvvvvvvvvvvvvvvvvvvv
    #                           vvvvvvvvvvvv
    elsif (/\G ( mb::getc ) (?= (?: \s* \( )+ \s* \) ) /xmsgc) {
        $parsed .= $1;
    }

    # mb::getc($fh) --> mb::getc($fh)
    # mb::getc $fh  --> mb::getc $fh
    #                       vvvvvvvvvvvvvvvvvvvvvvvvvv
    #                           vvvvvvvvvvvv
    elsif (/\G ( mb::getc ) (?= (?: \s* \( )* \s* \$ ) /xmsgc) {
        $parsed .= $1;
    }

    # mb::getc(FILE) --> mb::getc(\*FILE)
    # mb::getc FILE  --> mb::getc \*FILE
    #                          vvvvvvvvvvvvvvvvvvvvv
    #                            vvvvvvvvvvvv        vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( mb::getc ) \b ( (?: \s* \( )* \s* ) (?= [A-Za-z_][A-Za-z0-9_]* \b ) /xmsgc) {
        $parsed .= $1;
        $parsed .= $2;
        $parsed .= '\\*';
    }

    # mb::getc --> mb::getc
    elsif (/\G ( mb::getc ) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # CORE::functions that allow zero parameters
    # mb::functions that allow zero parameters
    elsif (/\G ( (?: CORE:: | mb:: )? (?:
        chop    |
        chr     |
        getc    |
        lc      |
        lcfirst |
        length  |
        ord     |
        uc      |
        ucfirst
    ) ) \b /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # CORE::functions that must parameters
    # mb::functions that must parameters
    elsif (/\G ( (?: CORE:: | mb:: )? (?:
        index   |
        reverse |
        rindex  |
        substr
    ) ) \b /xmsgc) {
        $parsed .= $1;
    }

    # mb::subroutines
    elsif (/\G ( mb:: (?: index_byte | rindex_byte ) ) \b /xmsgc) {
        $parsed .= $1;
    }

    # CORE::functions that allow zero parameters
    # functions that allow zero parameters
    elsif (/\G ( (?: CORE:: )? (?:
        _         |
        abs       |
        chomp     |
        cos       |
        exp       |
        fc        |
        hex       |
        int       |
        __LINE__  |
        log       |
        oct       |
        pop       |
        pos       |
        quotemeta |
        rand      |
        rmdir     |
        shift     |
        sin       |
        sqrt      |
        tell      |
        time      |
        umask     |
        wantarray
    ) ) \b /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # lstat(), stat() on MSWin32

    # lstat() --> mb::_lstat()
    # stat()  --> mb::_stat()
    #                           vvvvvvvvvvvvvvvvvvvvvvvvvv
    #                               vvvvvvvvvvvv
    elsif (/\G ( lstat | stat ) (?= (?: \s* \( )+ \s* \) ) /xmsgc) {
        $parsed .= "mb::_$1";
    }

    # lstat(...) --> mb::_lstat(...)
    # stat(...)  --> mb::_stat(...)
    #                           vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    #                               vvvvvvvvvvvv     vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( lstat | stat ) (?= (?: \s* \( )* \b (?: ' | " | ` | m | q | qq | qr | qw | qx | s | tr | y | \$ ) \b ) /xmsgc) {
        $parsed .= "mb::_$1";
    }

    # lstat(FILE)  --> mb::_lstat(\*FILE)
    # lstat FILE   --> mb::_lstat \*FILE
    # stat(FILE)   --> mb::_stat(\*FILE)
    # stat FILE    --> mb::_stat \*FILE
    #                              vvvvvvvvvvvvvvvvvvvvv
    #                                vvvvvvvvvvvv        vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( lstat | stat ) \b ( (?: \s* \( )* \s* ) (?= [A-Za-z_][A-Za-z0-9_]* \b ) /xmsgc) {
        $parsed .= "mb::_$1";
        $parsed .= $2;
        $parsed .= '\\*';
    }

    # opendir(DIR, ...) --> mb::_opendir(\*DIR, ...)
    # opendir DIR, ...  --> mb::_opendir \*DIR, ...
    #                         vvvvvvvvvvvvvvvvvvvvv
    #                           vvvvvvvvvvvv        vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    elsif (/\G ( opendir ) \b ( (?: \s* \( )* \s* ) (?= [A-Za-z_][A-Za-z0-9_]* \s* , ) /xmsgc) {
        $parsed .= "mb::_$1";
        $parsed .= $2;
        $parsed .= '\\*';
    }

    # function --> mb::subroutine on MSWin32
    # implements run on any systems by transpiling once
    elsif (/\G ( chdir | lstat | stat | unlink ) \b /xmsgc) {
        $parsed .= "mb::_$1";
        $parsed .= parse_ambiguous_char();
    }
    elsif (/\G ( opendir ) \b /xmsgc) {
        $parsed .= "mb::_$1";
    }

    # Carp::carp    <<HEREDOC
    # Carp::cluck   <<HEREDOC
    # Carp::confess <<HEREDOC
    # Carp::croak   <<HEREDOC
    # carp          <<HEREDOC
    # cluck         <<HEREDOC
    # confess       <<HEREDOC
    # croak         <<HEREDOC
    # die           <<HEREDOC
    # print         <<HEREDOC
    # printf        <<HEREDOC
    # say           <<HEREDOC
    # warn          <<HEREDOC
    elsif (/\G ( 
        Carp::carp    |
        Carp::cluck   |
        Carp::confess |
        Carp::croak   |
        carp          |
        cluck         |
        confess       |
        croak         |
        die           |
        print         |
        printf        |
        say           |
        warn
    ) (?= (?: \s+ | [#] .* )* << ) /xgc) {
        $parsed .= $1;
        # without $parsed .= parse_ambiguous_char();
    }

    # printf FILEHANDLE <<HEREDOC
    # print  FILEHANDLE <<HEREDOC
    # say    FILEHANDLE <<HEREDOC
    elsif (/\G (
        (?: printf | print | say )
        (?: \s+ | [#] .* )*
        (?! [a-z]+ ) # lowercase is considered to be function
        (?: \b [A-Za-z_][A-Za-z_0-9]*(?: :: [A-Za-z_][A-Za-z_0-9]*)* |
            \$ [A-Za-z_][A-Za-z_0-9]*(?: :: [A-Za-z_][A-Za-z_0-9]*)*
        )
    ) /xgc) {
        $parsed .= $1;
        # without $parsed .= parse_ambiguous_char();
    }

    # printf {FILEHANDLE} <<HEREDOC
    # print  {FILEHANDLE} <<HEREDOC
    # say    {FILEHANDLE} <<HEREDOC
    elsif (/\G (
        (?: printf | print | say )
        (?: \s+ | [#] .* )*
        ) (\{) 
    /xgc) {
        $parsed .= $1;
        $parsed .= parse_expr_balanced($2);
        # without $parsed .= parse_ambiguous_char();
    }

    # return
    elsif (/\G ( return ) /xmsgc) {
        $parsed .= $1;
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
        $parsed .= parse_ambiguous_char();
    }

    # any right parenthesis
    # "\x29" [)] RIGHT PARENTHESIS (U+0029)
    # "\x7D" [}] RIGHT CURLY BRACKET (U+007D)
    # "\x5D" []] RIGHT SQUARE BRACKET (U+005D)
    elsif (/\G ([\)\}\]]) /xmsgc) {
        $parsed .= $1;
        $parsed .= parse_ambiguous_char();
    }

    # any US-ASCII
    # "\x3A" [:] COLON (U+003A)
    elsif (/\G ([\x00-\x7F]) /xmsgc) {
        $parsed .= $1;
    }

    # otherwise
    elsif (/\G ($x) /xmsgc) {
        die "$0(@{[__LINE__]}): can't parse not US-ASCII '$1'.\n";
    }

    return $parsed;
}

#---------------------------------------------------------------------
# parse expression in balanced blackets
sub parse_expr_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed = $open_bracket;
    my $nest_bracket = 1;
    while (1) {

        # open bracket
        if (/\G (\Q$open_bracket\E) /xmsgc) {
            $parsed .= $1;
            $nest_bracket++;
        }

        # close bracket
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            $parsed .= $1;
            $parsed .= parse_ambiguous_char();
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
# parse expression that ends with a regexp
sub parse_expr_endswith {
    my($endswith) = @_;
    my $parsed = '';
    while (1) {
        if (/\G (?= $endswith ) /xmsgc) {
            last;
        }
        else {
            $parsed .= parse_expr();
        }
    }
    return $parsed;
}

#---------------------------------------------------------------------
# parse <<'HERE_DOCUMENT' as q-like
sub parse_heredocument_as_q_endswith {
    my($endswith) = @_;
    my $parsed = '';
    while (1) {
        if (/\G ( $R $endswith ) /xmsgc) {
            $parsed .= $1;
            last;
        }
        elsif (/\G ($x) /xmsgc) {
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
sub parse_heredocument_as_qq_endswith {
    my($endswith) = @_;
    my $parsed = '';
    my $nest_escape = 0;
    while (1) {
        if (/\G ( $R $endswith ) /xmsgc) {
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

        # \o{...}
        elsif (/\G \\o\{ (.*?) \} /xmsgc) {
            $parsed .= escape_to_hex(mb::chr(oct $1), '\\');
        }

        # \x{...}
        elsif (/\G \\x\{ (.*?) \} /xmsgc) {
            $parsed .= escape_to_hex(mb::chr(hex $1), '\\');
        }

        # \any
        elsif (/\G (\\) ($x) /xmsgc) {
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

        # @{^CAPTURE} --> @{[mb::_CAPTURE()]}
        elsif (/\G \@\{\^CAPTURE\} /xmsgc) {
            $parsed .= '@{[mb::_CAPTURE()]}';
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
        elsif (/\G ($x) /xmsgc) {
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
sub parse_q__like_balanced {
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
sub parse_q__like_endswith {
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
sub parse_q__like {
    my($closewith) = @_;
    if (/\G (\\\\) /xmsgc) {
        return $1;
    }
    elsif (/\G ($x) /xmsgc) {
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
sub parse_qq_like_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my $parsed_as_q  = $open_bracket;
    my $parsed_as_qq = $open_bracket;
    my $nest_bracket = 1;
    my $nest_escape = 0;
    while (1) {

        # blackets
        if (/\G (\\ \Q$open_bracket\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
        }
        elsif (/\G (\\ \Q$close_bracket\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
        }
        elsif (/\G (\Q$open_bracket\E) /xmsgc) {
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
sub parse_qq_like_endswith {
    my($endswith) = @_;
    my $parsed_as_q  = $endswith;
    my $parsed_as_qq = $endswith;
    my $nest_escape = 0;
    while (1) {

        # ends with
        if (/\G (\\ \Q$endswith\E) /xmsgc) {
            $parsed_as_q  .= $1;
            $parsed_as_qq .= $1;
        }
        elsif (/\G (\Q$endswith\E) /xmsgc) {
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
sub parse_qq_like {
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
    elsif (/\G ( (\\) ($x) ) /xmsgc) {
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

    # @{^CAPTURE} --> @{[mb::_CAPTURE()]}
    elsif (/\G ( \@\{\^CAPTURE\} ) /xmsgc) {
        $parsed_as_q  .= $1;
        $parsed_as_qq .= '@{[mb::_CAPTURE()]}';
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
    elsif (/\G ($x) /xmsgc) {
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
# tr/A-C/1-3/ for US-ASCII codepoint
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
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not US-ASCII});
            }
            elsif ($hyphened[$i+2] !~ m/\A [\x00-\x7F] \z/oxms) {
                confess sprintf(qq{@{[__FILE__]}: "$hyphened[$i+0]-$hyphened[$i+2]" in tr/// is not US-ASCII});
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
# parse tr{here}{here} in balanced blackets
sub parse_tr_like_balanced {
    my($open_bracket) = @_;
    my $close_bracket = {qw| ( ) { } [ ] < > |}->{$open_bracket} || die;
    my @x = ();
    my $nest_bracket = 1;
    while (1) {

        # blackets
        if (/\G (\\ \Q$open_bracket\E) /xmsgc) {
            push @x, $1;
        }
        elsif (/\G (\\ \Q$close_bracket\E) /xmsgc) {
            push @x, $1;
        }
        elsif (/\G (\Q$open_bracket\E) /xmsgc) {
            push @x, $1;
            $nest_bracket++;
        }
        elsif (/\G (\Q$close_bracket\E) /xmsgc) {
            if (--$nest_bracket <= 0) {
                last;
            }
            push @x, $1;
        }

        # \-
        elsif (/\G (\\ -) /xmsgc) {
            push @x, $1;
        }

        else {
            push @x, parse_tr_like($close_bracket);
        }
    }
    return join('', $open_bracket, @x, $close_bracket);
}

#---------------------------------------------------------------------
# parse tr/here/here/ that ends with a character
sub parse_tr_like_endswith {
    my($endswith) = @_;
    my $openwith = $endswith;
    my @x = ();
    while (1) {
        if (/\G (\\ \Q$endswith\E) /xmsgc) {
            push @x, $1;
        }
        elsif (/\G (\Q$endswith\E) /xmsgc) {
            last;
        }

        # \-
        elsif (/\G (\\ -) /xmsgc) {
            push @x, $1;
        }

        else {
            push @x, parse_tr_like($endswith);
        }
    }
    return join('', $openwith, @x, $endswith);
}

#---------------------------------------------------------------------
# parse tr/here/here/ common routine
sub parse_tr_like {
    my($closewith) = @_;

    if (0) {
    }

    # https://perldoc.perl.org/perlop#Interpolation
    # tr///, y///
    # No variable interpolation occurs.
    # String modifying combinations for case and quoting such as \Q, \U, and \E are not recognized.
    # The other escape sequences such as \200 and \t and backslashed characters such as \\ and \- are converted to appropriate literals.
    # The character "-" is treated specially and therefore \- is treated as a literal "-".

    # \ddd
    elsif (/\G \\ ( [0-3][0-7][0-7] | [0-7][0-7] | [0-7] ) /xmsgc) {
        return escape_tr(mb::chr(oct $1), $closewith);
    }

    # \oddd
    elsif (/\G \\o ( [0-3][0-7][0-7] | [0-7][0-7] | [0-7] ) /xmsgc) {
        return escape_tr(mb::chr(oct $1), $closewith);
    }

    # \o{...}
    elsif (/\G \\o\{ (.*?) \} /xmsgc) {
        return escape_tr(mb::chr(oct $1), $closewith);
    }

    # \xhh
    elsif (/\G \\x ( [0-9A-Fa-f][0-9A-Fa-f] | [0-9A-Fa-f] ) /xmsgc) {
        return escape_tr(mb::chr(hex $1), $closewith);
    }

    # \x{...}
    elsif (/\G \\x\{ (.*?) \} /xmsgc) {
        return escape_tr(mb::chr(hex $1), $closewith);
    }

    # \cX
    elsif (/\G ( \\c [\@ABCDEFGHIJKLMNOPQRSTUVWXYZ\[\\\]^_?] ) /xmsgc) {
        return {
            '\\c@'  => "\c@",
            '\\cA'  => "\cA",
            '\\cB'  => "\cB",
            '\\cC'  => "\cC",
            '\\cD'  => "\cD",
            '\\cE'  => "\cE",
            '\\cF'  => "\cF",
            '\\cG'  => "\cG",
            '\\cH'  => "\cH",
            '\\cI'  => "\cI",
            '\\cJ'  => "\cJ",
            '\\cK'  => "\cK",
            '\\cL'  => "\cL",
            '\\cM'  => "\cM",
            '\\cN'  => "\cN",
            '\\cO'  => "\cO",
            '\\cP'  => "\cP",
            '\\cQ'  => "\cQ",
            '\\cR'  => "\cR",
            '\\cS'  => "\cS",
            '\\cT'  => "\cT",
            '\\cU'  => "\cU",
            '\\cV'  => "\cV",
            '\\cW'  => "\cW",
            '\\cX'  => "\cX",
            '\\cY'  => "\cY",
            '\\cZ'  => "\cZ",
            '\\c['  => "\c[",
            '\\c\\' => CORE::chr(0x1C),
            '\\c]'  => "\c]",
            '\\c^'  => "\c^",
            '\\c_'  => "\c_",
            '\\c?'  => CORE::chr(0x7F),
        }->{$1} || die;
    }

    # \\ \a \b \e \f \n \r \t \E \l \L \u \U \Q
    elsif (/\G ( \\ ([\\abefnrtElLuUQ]) ) /xmsgc) {
        return {
            "\x5C\x5C" => "\x5C\x5C",
            '\a'       => "\a",
            '\b'       => "\b",
            '\e'       => "\e",
            '\f'       => "\f",
            '\n'       => "\n",
            '\r'       => "\r",
            '\t'       => "\t",
        }->{$1} || $2;
    }

    # any
    elsif (/\G ($x) /xmsgc) {
        return escape_tr($1, $closewith);
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
# qr/ [A-Z] / for Shift_JIS-like encoding
sub list_all_by_hyphen_sjis_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
(($a[1] <= 0x80) and (0xA0 <= $b[1])) ?
                sprintf(join('', qw( [\x%02x-\x80\xA0-\x%02x] )), $a[1],
                                                                  $b[1]) :
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]          )), $a[1],
                                                                  $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x           [\x00-\x%02x] )), $b[1], $b[2]),
0x81 <  $b[1] ? sprintf(join('', qw( [\x81-\x%02x]          [\x00-\xFF  ] )), $b[1]-1     ) : (),
$a[1] <= 0x80 ? sprintf(join('', qw( [\x%02x-\x80\xA0-\xDF]               )), $a[1]) :
$a[1] <  0xA0 ? ()                                                                   :
$a[1] <= 0xDF ? sprintf(join('', qw( [\x%02x-\xDF]                        )), $a[1]) : (),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFC ?  sprintf(join('', qw( [\x%02x-\xFC] [\x00-\xFF  ] )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF] )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for EUC-JP-like encoding
sub list_all_by_hyphen_eucjp_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]             )), $a[1],
                                                                     $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0xA1 < $b[1] ?  sprintf(join('', qw( [\xA1-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]               )), $a[1]       ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [\x00-\xFF  ] )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF] )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0xA1 < $b[1] ?  sprintf(join('', qw( [\xA1-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for Big5-like encoding
sub list_all_by_hyphen_big5_like {
    my($a, $b) = @_;
    my @a = (undef, unpack 'C*', $a);
    my @b = (undef, unpack 'C*', $b);

    if (0) { }
    elsif (CORE::length($a) == 1) {
        if (0) { }
        elsif (CORE::length($b) == 1) {
            return (
$a[1]<=$b[1] ?  sprintf(join('', qw( [\x%02x-\x%02x]             )), $a[1],
                                                                     $b[1]) : (),
            );
        }
        elsif (CORE::length($b) == 2) {
            return (
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]               )), $a[1]       ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [\x00-\xFF  ] )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF] )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x] )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x00-\xFF  ] )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for GB18030-like encoding
sub list_all_by_hyphen_gb18030_like {
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
                sprintf(join('', qw(       \x%02x  [\x00-\x2F\x3A-\x%02x]                    )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [^\x30-\x39 ]                             )), $b[1]-1     ) : (),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]       ),
            );
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x30-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x81 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x81-\x%02x] [\x30-\x39  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x30 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x30-\x%02x] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1], $b[2]-1            ) : (),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1]-1                   ) : (),
                sprintf(join('', qw( [\x81-\xFE  ] [^\x30-\x39 ]                             )),                           ),
                sprintf(join('', qw( [\x%02x-\x7F]                                           )), $a[1]                     ),
            );
        }
    }
    elsif (CORE::length($a) == 2) {
        if (0) { }
        elsif (CORE::length($b) == 2) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [^\x30-\x39 ]                             )), $a[1]+1     ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF]                             )), $a[1], $a[2]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x  [\x00-\x%02x]                             )), $b[1], $b[2]),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [^\x30-\x39 ]                             )), $b[1]-1     ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
        elsif (CORE::length($b) == 4) {
            return (
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x30-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x81  < $b[3] ? sprintf(join('', qw(       \x%02x        \x%02x  [\x81-\x%02x] [\x30-\x39  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x30  < $b[2] ? sprintf(join('', qw(       \x%02x  [\x30-\x%02x] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1], $b[2]-1            ) : (),
0x81  < $b[1] ? sprintf(join('', qw( [\x81-\x%02x] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1]-1                   ) : (),
$a[1] < 0xFE  ? sprintf(join('', qw( [\x%02x-\xFE] [^\x30-\x39 ]                             )), $a[1]+1                   ) : (),
                sprintf(join('', qw(  \x%02x       [\x%02x-\xFF]                             )), $a[1], $a[2]              ),
            );
        }
    }
    elsif (CORE::length($a) == 4) {
        if (0) { }
        elsif (CORE::length($b) == 4) {
            my $lower_limit = join('|',
$a[1] < 0xFE ?  sprintf(join('', qw( [\x%02x-\xFE] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $a[1]+1                   ) : (),
$a[2] < 0x39 ?  sprintf(join('', qw(  \x%02x       [\x%02x-\x39] [\x81-\xFE  ] [\x30-\x39  ] )), $a[1], $a[2]+1            ) : (),
$a[3] < 0xFE ?  sprintf(join('', qw(  \x%02x        \x%02x       [\x%02x-\xFE] [\x30-\x39  ] )), $a[1], $a[2], $a[3]+1     ) : (),
                sprintf(join('', qw(  \x%02x        \x%02x        \x%02x       [\x%02x-\x39] )), $a[1], $a[2], $a[3], $a[4]),
            );
            my $upper_limit = join('|',
                sprintf(join('', qw(       \x%02x        \x%02x        \x%02x  [\x30-\x%02x] )), $b[1], $b[2], $b[3], $b[4]),
0x81 < $b[3] ?  sprintf(join('', qw(       \x%02x        \x%02x  [\x81-\x%02x] [\x30-\x39  ] )), $b[1], $b[2], $b[3]-1     ) : (),
0x30 < $b[2] ?  sprintf(join('', qw(       \x%02x  [\x30-\x%02x] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1], $b[2]-1            ) : (),
0x81 < $b[1] ?  sprintf(join('', qw( [\x81-\x%02x] [\x30-\x39  ] [\x81-\xFE  ] [\x30-\x39  ] )), $b[1]-1                   ) : (),
            );
            return qq{(?=$lower_limit)(?=$upper_limit)};
        }
    }

    # over range of codepoint
    confess sprintf(qq{@{[__FILE__]}: codepoint class [$_[0]-$_[1]] is not 1 to 4 octets (%d-%d)}, CORE::length($a), CORE::length($b));
}

#---------------------------------------------------------------------
# qr/ [A-Z] / for UTF-8-like encoding
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
# parse codepoint class
sub parse_re_codepoint_class {
    my($codepoint_class) = @_;
    my @sbcs = ();
    my @xbcs = (); # "xbcs" means DBCS, TBCS, QBCS, ...

    # get members from class
    my @classmate = ();
    while ($codepoint_class !~ /\G \z /xmsgc) {
        if (0) { }
        elsif ($codepoint_class =~ /\G\\o\{([01234567]+)\}/xmsgc) {
            push @classmate, mb::chr(oct $1);
        }
        elsif ($codepoint_class =~ /\G\\x\{([0123456789ABCDEFabcdef]+)\}/xmsgc) {
            push @classmate, mb::chr(hex $1);
        }
        elsif ($codepoint_class =~ /\G(\[:.+?:\])/xmsgc) {
            push @classmate, $1;
        }
        elsif ($codepoint_class =~ /\G((?>\\$x))/xmsgc) {
            push @classmate, $1;
        }
        elsif ($codepoint_class =~ /\G($x)/xmsgc) {
            push @classmate, $1;
        }
        else {
            confess qq{@{[__FILE__]}: codepoint_class=($codepoint_class), classmate=(@classmate)};
        }
    }

    # get regular expression for MBCS codepoint class
    for (my $i=0; $i <= $#classmate; $i++) {
        my $classmate = $classmate[$i];

        # hyphen of [A-Z] or [^A-Z]
        if (($i < $#classmate) and ($classmate[$i+1] eq '-')) {
            my $a = $classmate[$i];
            my $b = $classmate[$i+2];
            if (0) { }
            elsif ($script_encoding =~ /\A (?: sjis ) \z/xms) {
                push @xbcs, list_all_by_hyphen_sjis_like   ($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: eucjp ) \z/xms) {
                push @xbcs, list_all_by_hyphen_eucjp_like  ($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: gbk | uhc | big5 | big5hkscs ) \z/xms) {
                push @xbcs, list_all_by_hyphen_big5_like   ($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: gb18030 ) \z/xms) {
                push @xbcs, list_all_by_hyphen_gb18030_like($a, $b);
            }
            elsif ($script_encoding =~ /\A (?: utf8 | wtf8 ) \z/xms) {
                push @xbcs, list_all_by_hyphen_utf8_like   ($a, $b);
            }
            else {
                push @sbcs, "$a-$b";
            }
            $i += 2;
        }

        # classic perl codepoint class shortcuts
        elsif ($classmate eq '\\D') { push @xbcs, "(?:(?![$bare_d])$x)";  }
        elsif ($classmate eq '\\H') { push @xbcs, "(?:(?![$bare_h])$x)";  }
#       elsif ($classmate eq '\\N') { push @xbcs, "(?:(?!\\n)$x)";        } # \N in a codepoint class must be a named character: \N{...} in regex
#       elsif ($classmate eq '\\R') { push @xbcs, "(?>\\r\\n|[$bare_v])"; } # Unrecognized escape \R in codepoint class passed through in regex
        elsif ($classmate eq '\\S') { push @xbcs, "(?:(?![$bare_s])$x)";  }
        elsif ($classmate eq '\\V') { push @xbcs, "(?:(?![$bare_v])$x)";  }
        elsif ($classmate eq '\\W') { push @xbcs, "(?:(?![$bare_w])$x)";  }
        elsif ($classmate eq '\\b') { push @sbcs, $bare_backspace;        }
        elsif ($classmate eq '\\d') { push @sbcs, $bare_d;                }
        elsif ($classmate eq '\\h') { push @sbcs, $bare_h;                }
        elsif ($classmate eq '\\s') { push @sbcs, $bare_s;                }
        elsif ($classmate eq '\\v') { push @sbcs, $bare_v;                }
        elsif ($classmate eq '\\w') { push @sbcs, $bare_w;                }

        # [:POSIX:]
        elsif ($classmate eq '[:alnum:]' ) { push @sbcs, '\x30-\x39\x41-\x5A\x61-\x7A';                  }
        elsif ($classmate eq '[:alpha:]' ) { push @sbcs, '\x41-\x5A\x61-\x7A';                           }
        elsif ($classmate eq '[:ascii:]' ) { push @sbcs, '\x00-\x7F';                                    }
        elsif ($classmate eq '[:blank:]' ) { push @sbcs, '\x09\x20';                                     }
        elsif ($classmate eq '[:cntrl:]' ) { push @sbcs, '\x00-\x1F\x7F';                                }
        elsif ($classmate eq '[:digit:]' ) { push @sbcs, '\x30-\x39';                                    }
        elsif ($classmate eq '[:graph:]' ) { push @sbcs, '\x21-\x7F';                                    }
        elsif ($classmate eq '[:lower:]' ) { push @sbcs, 'abcdefghijklmnopqrstuvwxyz';                   } # /i modifier requires 'a' to 'z' literally
        elsif ($classmate eq '[:print:]' ) { push @sbcs, '\x20-\x7F';                                    }
        elsif ($classmate eq '[:punct:]' ) { push @sbcs, '\x21-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7B-\x7E'; }
        elsif ($classmate eq '[:space:]' ) { push @sbcs, '\s\x0B';                                       } # "\s" and vertical tab ("\cK")
        elsif ($classmate eq '[:upper:]' ) { push @sbcs, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';                   } # /i modifier requires 'A' to 'Z' literally
        elsif ($classmate eq '[:word:]'  ) { push @sbcs, '\x30-\x39\x41-\x5A\x5F\x61-\x7A';              }
        elsif ($classmate eq '[:xdigit:]') { push @sbcs, '\x30-\x39\x41-\x46\x61-\x66';                  }

        # [:^POSIX:]
        elsif ($classmate eq '[:^alnum:]' ) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x61-\\x7A])$x)";                      }
        elsif ($classmate eq '[:^alpha:]' ) { push @xbcs, "(?:(?![\\x41-\\x5A\\x61-\\x7A])$x)";                                 }
        elsif ($classmate eq '[:^ascii:]' ) { push @xbcs, "(?:(?![\\x00-\\x7F])$x)";                                            }
        elsif ($classmate eq '[:^blank:]' ) { push @xbcs, "(?:(?![\\x09\\x20])$x)";                                             }
        elsif ($classmate eq '[:^cntrl:]' ) { push @xbcs, "(?:(?![\\x00-\\x1F\\x7F])$x)";                                       }
        elsif ($classmate eq '[:^digit:]' ) { push @xbcs, "(?:(?![\\x30-\\x39])$x)";                                            }
        elsif ($classmate eq '[:^graph:]' ) { push @xbcs, "(?:(?![\\x21-\\x7F])$x)";                                            }
        elsif ($classmate eq '[:^lower:]' ) { push @xbcs, "(?:(?![abcdefghijklmnopqrstuvwxyz])$x)";                             } # /i modifier requires 'a' to 'z' literally
        elsif ($classmate eq '[:^print:]' ) { push @xbcs, "(?:(?![\\x20-\\x7F])$x)";                                            }
        elsif ($classmate eq '[:^punct:]' ) { push @xbcs, "(?:(?![\\x21-\\x2F\\x3A-\\x3F\\x40\\x5B-\\x5F\\x60\\x7B-\\x7E])$x)"; }
        elsif ($classmate eq '[:^space:]' ) { push @xbcs, "(?:(?![\\s\\x0B])$x)";                                               } # "\s" and vertical tab ("\cK")
        elsif ($classmate eq '[:^upper:]' ) { push @xbcs, "(?:(?![ABCDEFGHIJKLMNOPQRSTUVWXYZ])$x)";                             } # /i modifier requires 'A' to 'Z' literally
        elsif ($classmate eq '[:^word:]'  ) { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x5A\\x5F\\x61-\\x7A])$x)";                 }
        elsif ($classmate eq '[:^xdigit:]') { push @xbcs, "(?:(?![\\x30-\\x39\\x41-\\x46\\x61-\\x66])$x)";                      }

        # \any
        elsif ($classmate =~ /\G (\\) ($x) /xmsgc) {
            if (CORE::length($2) == 1) {
                push @sbcs, ($1 . $2);
            }
            else {
                push @xbcs, '(?:' . $1 . escape_to_hex($2, ']') . ')';
            }
        }

        # any
        elsif ($classmate =~ /\G ($x) /xmsgc) {
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

    # return codepoint class
    my $parsed =
        ( @sbcs and  @xbcs) ? join('|', @xbcs, '['.join('',@sbcs).']') :
        (!@sbcs and  @xbcs) ? join('|', @xbcs                        ) :
        ( @sbcs and !@xbcs) ?                  '['.join('',@sbcs).']'  :
        die;
    return $parsed;
}

#---------------------------------------------------------------------
# parse qr'regexp' as q-like
sub parse_re_as_q_endswith {
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
                elsif (/\G ($x) /xmsgc) {
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
            $parsed .= mb::_cc($classmate);
        }

        # /./ or \any
        elsif (/\G \.  /xmsgc) { $parsed .= "(?:$over_ascii|.)";    } # after $over_ascii, /s modifier wants "." (not [\x00-\xFF])
        elsif (/\G \\B /xmsgc) { $parsed .= "(?:(?<![$bare_w])(?![$bare_w])|(?<=[$bare_w])(?=[$bare_w]))"; }
        elsif (/\G \\D /xmsgc) { $parsed .= "(?:(?![$bare_d])$x)";  }
        elsif (/\G \\H /xmsgc) { $parsed .= "(?:(?![$bare_h])$x)";  }
        elsif (/\G \\N /xmsgc) { $parsed .= "(?:(?!\\n)$x)";        }
        elsif (/\G \\R /xmsgc) { $parsed .= "(?>\\r\\n|[$bare_v])"; }
        elsif (/\G \\S /xmsgc) { $parsed .= "(?:(?![$bare_s])$x)";  }
        elsif (/\G \\V /xmsgc) { $parsed .= "(?:(?![$bare_v])$x)";  }
        elsif (/\G \\W /xmsgc) { $parsed .= "(?:(?![$bare_w])$x)";  }
        elsif (/\G \\b /xmsgc) { $parsed .= "(?:(?<![$bare_w])(?=[$bare_w])|(?<=[$bare_w])(?![$bare_w]))"; }
        elsif (/\G \\d /xmsgc) { $parsed .= "[$bare_d]";            }
        elsif (/\G \\h /xmsgc) { $parsed .= "[$bare_h]";            }
        elsif (/\G \\s /xmsgc) { $parsed .= "[$bare_s]";            }
        elsif (/\G \\v /xmsgc) { $parsed .= "[$bare_v]";            }
        elsif (/\G \\w /xmsgc) { $parsed .= "[$bare_w]";            }

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
        elsif (/\G ($x) /xmsgc) {
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
sub parse_re_balanced {
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
sub parse_re_endswith {
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
sub parse_re {
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
            elsif (/\G ($x) /xmsgc) {
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

        # quote by (?: ... ) to avoid syntax error: Can't coerce array into hash at ...
        #
        # [ABC]{3} --> @{[mb::_cc(qq[ABC])]}{3}     # makes: Can't coerce array into hash at ...
        # [ABC]{3} --> (?:@{[mb::_cc(qq[ABC])]}){3} # ok

        $parsed .= "(?:\@{[mb::_cc(qq[$classmate])]})";
    }

    # /./ or \any
    elsif (/\G \.  /xmsgc) { $parsed .= '(?:@{[@mb::_dot]})'; }
    elsif (/\G \\B /xmsgc) { $parsed .= '(?:@{[@mb::_B]})';   }
    elsif (/\G \\D /xmsgc) { $parsed .= '(?:@{[@mb::_D]})';   }
    elsif (/\G \\H /xmsgc) { $parsed .= '(?:@{[@mb::_H]})';   }
    elsif (/\G \\N /xmsgc) { $parsed .= '(?:@{[@mb::_N]})';   }
    elsif (/\G \\R /xmsgc) { $parsed .= '(?:@{[@mb::_R]})';   }
    elsif (/\G \\S /xmsgc) { $parsed .= '(?:@{[@mb::_S]})';   }
    elsif (/\G \\V /xmsgc) { $parsed .= '(?:@{[@mb::_V]})';   }
    elsif (/\G \\W /xmsgc) { $parsed .= '(?:@{[@mb::_W]})';   }
    elsif (/\G \\b /xmsgc) { $parsed .= '(?:@{[@mb::_b]})';   }
    elsif (/\G \\d /xmsgc) { $parsed .= '(?:@{[@mb::_d]})';   }
    elsif (/\G \\h /xmsgc) { $parsed .= '(?:@{[@mb::_h]})';   }
    elsif (/\G \\s /xmsgc) { $parsed .= '(?:@{[@mb::_s]})';   }
    elsif (/\G \\v /xmsgc) { $parsed .= '(?:@{[@mb::_v]})';   }
    elsif (/\G \\w /xmsgc) { $parsed .= '(?:@{[@mb::_w]})';   }

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
    elsif (/\G (\\) ($x) /xmsgc) {
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

    # ${^CAPTURE}[0] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(1))]}
    # ${^CAPTURE}[1] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(2))]}
    # ${^CAPTURE}[2] --> @{[mb::_clustered_codepoint(mb::_CAPTURE(3))]}
    elsif (/\G \$\{\^CAPTURE\} \s* (\[) /xmsgc) {
        my $n_th = quotee_of(parse_expr_balanced($1));
        $parsed .= "\@{[mb::_clustered_codepoint(mb::_CAPTURE($n_th+1))]}";
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
    elsif (/\G ($x) /xmsgc) {
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
sub parse_re_modifier {
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
sub parse_tr_modifier {
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
# makes codepoint class from string
sub codepoint_tr {
    my $searchlist = quotee_of($_[0]);

    my @sbcs = ();
    my @xbcs = (); # "xbcs" means DBCS, TBCS, QBCS, ...
    while ($searchlist !~ /\G \z /xmsgc) {

        # \-
        if ($searchlist =~ /\G (\\-) /xmsgc) {
            push @sbcs, $1;
        }

        # -
        elsif ($searchlist =~ /\G (-) /xmsgc) {
            push @sbcs, $1;
        }

        # any qq escapee
        elsif ($searchlist =~ /\G ([$escapee_in_qq_like]) /xmsgc) {
            push @sbcs, "\\$1";
        }

        # any
        elsif ($searchlist =~ /\G ($x) /xmsgc) {
            if (CORE::length($1) == 1) {
                push @sbcs, $1;
            }
            else {
                push @xbcs, escape_qq($1, '\\');
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

    # return codepoint class
    return
        ( @sbcs and  @xbcs) ? join('|', @xbcs, '['.join('',@sbcs).']') :
        (!@sbcs and  @xbcs) ? join('|', @xbcs                        ) :
        ( @sbcs and !@xbcs) ?                  '['.join('',@sbcs).']'  :
        die;
}

#---------------------------------------------------------------------
# get quotee from quoted "quotee"
sub quotee_of {
    if (CORE::length($_[0]) >= 2) {
        return CORE::substr($_[0],1,-1);
    }
    else {
        die;
    }
}

#---------------------------------------------------------------------
# escape q/string/ as q-like quote
sub escape_q {
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
sub escape_qq {
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
# escape tr/here/here/ as tr-like quote
sub escape_tr {
    my($codepoint, $endswith) = @_;
    if ($codepoint =~ /\A (\Q$endswith\E) \z/xms) {
        return "\\$1";
    }
    elsif ($codepoint =~ /\A ([^\x00-\x7F]) (\Q$endswith\E) \z/xms) {
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
# escape qq/string/ or qr/regexp/ to hex
sub escape_to_hex {
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

=encoding utf8

=head1 NAME

mb - Scripting in Big5, Big5-HKSCS, GBK, Sjis, UHC, UTF-8, ...

=head1 SYNOPSIS

  $ perl mb.pm              MBCS_Perl_script.pl (auto detect encoding of script)
  $ perl mb.pm -e big5      MBCS_Perl_script.pl
  $ perl mb.pm -e big5hkscs MBCS_Perl_script.pl
  $ perl mb.pm -e eucjp     MBCS_Perl_script.pl
  $ perl mb.pm -e gb18030   MBCS_Perl_script.pl
  $ perl mb.pm -e gbk       MBCS_Perl_script.pl
  $ perl mb.pm -e sjis      MBCS_Perl_script.pl
  $ perl mb.pm -e uhc       MBCS_Perl_script.pl
  $ perl mb.pm -e utf8      MBCS_Perl_script.pl
  $ perl mb.pm -e wtf8      MBCS_Perl_script.pl

  C:\WINDOWS> perl mb.pm script.pl ??-DOS-like *wildcard* available

  MBCS quotes:
        qq/ DAMEMOJI 功声乗ソ /
         q/ DAMEMOJI 功声乗ソ /
         m/ DAMEMOJI 功声乗ソ /
         s/ DAMEMOJI 功声乗ソ / DAMEMOJI 功声乗ソ /
    split / DAMEMOJI 功声乗ソ /
        tr/ DAMEMOJI 功声乗ソ / DAMEMOJI 功声乗ソ /
         y/ DAMEMOJI 功声乗ソ / DAMEMOJI 功声乗ソ /
        qr/ DAMEMOJI 功声乗ソ /

  MBCS subroutines:
    mb::chop(...);
    mb::chr(...);
    mb::do 'file';
    mb::dosglob(...);
    mb::eval 'string';
    mb::getc(...);
    mb::index(...);
    mb::index_byte(...);
    mb::length(...);
    mb::ord(...);
    mb::require 'file';
    mb::reverse(...);
    mb::rindex(...);
    mb::rindex_byte(...);
    mb::substr(...);
    mb::use Module;
    mb::no Module;

  MBCS special variables:
    $mb::PERL
    $mb::ORIG_PROGRAM_NAME

  supported encodings:
    Big5, Big5-HKSCS, EUC-JP, GB18030, GBK, Sjis, UHC, UTF-8, WTF-8

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

This software is a source code filter, a transpiler-modulino.

Perl is said to have been able to handle Unicode since version 5.8. However,
unlike JPerl, "Easy jobs easy" has been lost. (but we have got it again :-D)

In Shift_JIS and similar encodings(Big5, Big5-HKSCS, GB18030, GBK, Sjis, UHC)
have any DAMEMOJI who have metacharacters at second octet. Which characters
are DAMEMOJI is depends on whether the enclosing delimiter is single quote or
double quote.

This software escapes DAMEMOJI in your script, generate a new script and
run it.

There are some MBCS encodings in the world.

=over 2

=item * in Japan since 1978, JIS C 6226-1978,

=item * in China since 1980, GB 2312-80,

=item * in Taiwan since 1984, Big5,

=item * in South Korea since 1991, KS X 1002:1991,

=item * in Hong Kong since 1999, Hong Kong Supplementary Character Set, and more.

=back

Even if you are an avid Unicode proponent, you cannot change this fact. These
encodings are still used today in most areas except the world wide web.

This software does ...

=over 2

=item * supports MBCS literals of Perl scripts

=item * supports Big5, Big5-HKSCS, EUC-JP, GB18030, GBK, Sjis, UHC, UTF-8, and WTF-8

=item * does not use the UTF8 flag to avoid MOJIBAKE

=item * escapes DAMEMOJI of scripts

=item * handles raw encoding to support GAIJI

=item * adds multibyte anchoring to regular expressions

=item * rewrites character classes in regular expressions to work as MBCS codepoint

=item * supports special variables $`, $&, and $'

=item * does not change features of octet-oriented built-in functions

=item * lc(), lcfirst(), uc(), and ucfirst() convert US-ASCII only

=item * codepoint range by hyphen of tr/// and y/// support US-ASCII only

=item * You have using mb::* subroutines if you want codepoint semantics

=back

Let's enjoy MBSC scripting in Perl!!

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

=item * codepoint

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
  big5 (Big5)
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Big5
             * needs multibyte anchoring
             * unsafe US-ASCII casefolding of 2nd octet
             * needs escaping meta char of 2nd octet
             * and DAMEMOJI samples, here
               [@](40) 　(A140) ＼(A240) ｗ(A340) 一(A440) 世(A540) 共(A640) 作(A740) 杓(A840) 咖(A940) 昇(AA40) 陂(AB40) 拯(AC40) 耐(AD40) 哦(AE40) 浬(AF40) 虔(B040) 娼(B140) 毫(B240) 莆(B340) 婷(B440) 溉(B540) 詔(B640) 媳(B740) 睹(B840) 辟(B940) 愿(BA40) 罰(BB40) 劇(BC40) 瑾(BD40) 輥(BE40) 濃(BF40) 錐(C040) 瞧(C140) 駿(C240) 鞭(C340) 願(C440) 護(C540) 讖(C640) す(C740) 乂(C940) 汌(CA40) 杙(CB40) 坨(CC40) 泒(CD40) 哃(CE40) 柜(CF40) 穾(D040) 唊(D140) 毨(D240) 笄(D340) 酎(D440) 崰(D540) 淐(D640) 耞(D740) 釫(D840) 惲(D940) 湨(DA40) 罦(DB40) 軹(DC40) 媷(DD40) 毹(DE40) 稛(DF40) 觡(E040) 凘(E140) 榠(E240) 禗(E340) 裰(E440) 噚(E540) 澍(E640) 膞(E740) 踔(E840) 噳(E940) 澢(EA40) 蕀(EB40) 錋(EC40) 檕(ED40) 蕷(EE40) 鞞(EF40) 璸(F040) 蹛(F140) 徿(F240) 譑(F340) 嚵(F440) 鏼(F540) 蠩(F640) 糴(F740) 讌(F840) 纘(F940) 
               [[](5B) ︴(A15B) 兞(A25B) Ω(A35B) 久(A45B) 加(A55B) 吆(A65B) 吝(A75B) 沍(A85B) 坤(A95B) 歧(AA5B) 俎(AB5B) 架(AC5B) 茉(AD5B) 娌(AE5B) 琉(AF5B) 豺(B05B) 崙(B15B) 涵(B25B) 訥(B35B) 廂(B45B) 琥(B55B) 跋(B65B) 愴(B75B) 稟(B85B) 鉀(B95B) 暨(BA5B) 蒜(BB5B) 墩(BC5B) 稼(BD5B) 閭(BE5B) 璟(BF5B) 頤(C05B) 繆(C15B) 攆(C25B) 鵠(C35B) 壤(C45B) 騾(C55B) 觀(C65B) ぴ(C75B) 夬(C95B) 伻(CA5B) 汥(CB5B) 岮(CC5B) 牪(CD5B) 垙(CE5B) 枮(CF5B) 胂(D05B) 娙(D15B) 浟(D25B) 罜(D35B) 倕(D45B) 惙(D55B) 焎(D65B) 莨(D75B) 偨(D85B) 揳(D95B) 烻(DA5B) 艵(DB5B) 鄅(DC5B) 幍(DD5B) 滃(DE5B) 絿(DF5B) 賌(E05B) 墁(E15B) 榞(E25B) 箙(E35B) 跽(E45B) 嬂(E55B) 潩(E65B) 蔈(E75B) 醅(E85B) 嬠(E95B) 獩(EA5B) 螛(EB5B) 頲(EC5B) 濨(ED5B) 蟅(EE5B) 駷(EF5B) 礐(F05B) 鎎(F15B) 氌(F25B) 辴(F35B) 瀼(F45B) 騴(F55B) 酄(F65B) 譿(F75B) 鱍(F85B) 鱮(F95B) 
               [\](5C) ﹏(A15C) 兝(A25C) α(A35C) 么(A45C) 功(A55C) 吒(A65C) 吭(A75C) 沔(A85C) 坼(A95C) 歿(AA5C) 俞(AB5C) 枯(AC5C) 苒(AD5C) 娉(AE5C) 珮(AF5C) 豹(B05C) 崤(B15C) 淚(B25C) 許(B35C) 廄(B45C) 琵(B55C) 跚(B65C) 愧(B75C) 稞(B85C) 鈾(B95C) 暝(BA5C) 蓋(BB5C) 墦(BC5C) 穀(BD5C) 閱(BE5C) 璞(BF5C) 餐(C05C) 縷(C15C) 擺(C25C) 黠(C35C) 孀(C45C) 髏(C55C) 躡(C65C) ふ(C75C) 尐(C95C) 佢(CA5C) 汻(CB5C) 岤(CC5C) 狖(CD5C) 垥(CE5C) 柦(CF5C) 胐(D05C) 娖(D15C) 涂(D25C) 罡(D35C) 偅(D45C) 惝(D55C) 牾(D65C) 莍(D75C) 傜(D85C) 揊(D95C) 焮(DA5C) 茻(DB5C) 鄃(DC5C) 幋(DD5C) 滜(DE5C) 綅(DF5C) 赨(E05C) 塿(E15C) 槙(E25C) 箤(E35C) 踊(E45C) 嫹(E55C) 潿(E65C) 蔌(E75C) 醆(E85C) 嬞(E95C) 獦(EA5C) 螏(EB5C) 餤(EC5C) 燡(ED5C) 螰(EE5C) 駹(EF5C) 礒(F05C) 鎪(F15C) 瀙(F25C) 酀(F35C) 瀵(F45C) 騱(F55C) 酅(F65C) 贕(F75C) 鱋(F85C) 鱭(F95C) 
               []](5D) （(A15D) 兡(A25D) β(A35D) 也(A45D) 包(A55D) 因(A65D) 吞(A75D) 沘(A85D) 夜(A95D) 氓(AA5D) 侷(AB5D) 柵(AC5D) 苗(AD5D) 孫(AE5D) 珠(AF5D) 財(B05D) 崧(B15D) 淫(B25D) 設(B35D) 弼(B45D) 琶(B55D) 跑(B65D) 愍(B75D) 窟(B85D) 鉛(B95D) 榜(BA5D) 蒸(BB5D) 奭(BC5D) 稽(BD5D) 霄(BE5D) 瓢(BF5D) 館(C05D) 縲(C15D) 擻(C25D) 鼕(C35D) 孃(C45D) 魔(C55D) 釁(C65D) ぶ(C75D) 巿(C95D) 佉(CA5D) 沎(CB5D) 岠(CC5D) 狋(CD5D) 垚(CE5D) 柛(CF5D) 胅(D05D) 娭(D15D) 涘(D25D) 罞(D35D) 偟(D45D) 惈(D55D) 牻(D65D) 荺(D75D) 傒(D85D) 揠(D95D) 焱(DA5D) 菏(DB5D) 酡(DC5D) 廅(DD5D) 滘(DE5D) 絺(DF5D) 赩(E05D) 塴(E15D) 榗(E25D) 箂(E35D) 踃(E45D) 嬁(E55D) 澕(E65D) 蓴(E75D) 醊(E85D) 寯(E95D) 獧(EA5D) 螗(EB5D) 餟(EC5D) 燱(ED5D) 螬(EE5D) 駸(EF5D) 礑(F05D) 鎞(F15D) 瀧(F25D) 鄿(F35D) 瀯(F45D) 騬(F55D) 醹(F65D) 躕(F75D) 鱕(F85D) 鸋(F95D) 
               [^](5E) ）(A15E) 兣(A25E) γ(A35E) 乞(A45E) 匆(A55E) 回(A65E) 吾(A75E) 沂(A85E) 奉(A95E) 氛(AA5E) 兗(AB5E) 柩(AC5E) 英(AD5E) 屘(AE5E) 珪(AF5E) 貢(B05E) 崗(B15E) 淘(B25E) 訟(B35E) 彭(B45E) 琴(B55E) 跌(B65E) 愆(B75E) 窠(B85E) 鉋(B95E) 榨(BA5E) 蓀(BB5E) 嬉(BC5E) 稷(BD5E) 霆(BE5E) 甌(BF5E) 餞(C05E) 繃(C15E) 擷(C25E) 鼬(C35E) 孽(C45E) 魑(C55E) 鑲(C65E) ぷ(C75E) 旡(C95E) 体(CA5E) 灴(CB5E) 岵(CC5E) 狘(CD5E) 垕(CE5E) 柺(CF5E) 胣(D05E) 娮(D15E) 洯(D25E) 罠(D35E) 偩(D45E) 悱(D55E) 牼(D65E) 荳(D75E) 傂(D85E) 揶(D95E) 焣(DA5E) 菹(DB5E) 酤(DC5E) 廌(DD5E) 溙(DE5E) 綎(DF5E) 趑(E05E) 墋(E15E) 榐(E25E) 粻(E35E) 踇(E45E) 嬇(E55E) 潣(E65E) 蔪(E75E) 醁(E85E) 嶬(E95E) 獬(EA5E) 螓(EB5E) 餧(EC5E) 燨(ED5E) 螹(EE5E) 駶(EF5E) 禭(F05E) 鎦(F15E) 瀠(F25E) 醰(F35E) 瀷(F45E) 騪(F55E) 鐿(F65E) 躔(F75E) 鱙(F85E) 鸍(F95E) 
               [`](60) ︶(A160) 瓩(A260) ε(A360) 亡(A460) 匝(A560) 圳(A660) 呎(A760) 灼(A860) 奈(A960) 注(AA60) 冑(AB60) 柄(AC60) 苜(AD60) 害(AE60) 畔(AF60) 躬(B060) 常(B160) 深(B260) 訢(B360) 循(B460) 琛(B560) 跆(B660) 戡(B760) 節(B860) 鉑(B960) 槁(BA60) 蒐(BB60) 嬋(BC60) 窯(BD60) 霉(BE60) 瘴(BF60) 餡(C060) 總(C160) 曜(C260) 嚥(C360) 巉(C460) 鰥(C560) 顱(C660) べ(C760) 毌(C960) 伾(CA60) 牣(CB60) 岨(CC60) 狜(CD60) 复(CE60) 柊(CF60) 胜(D060) 娏(D160) 涋(D260) 罛(D360) 偣(D460) 悷(D560) 猝(D660) 荴(D760) 兟(D860) 揲(D960) 焢(DA60) 菀(DB60) 酢(DC60) 廋(DD60) 溎(DE60) 綃(DF60) 趎(E060) 墇(E160) 榵(E260) 粼(E360) 踅(E460) 嬏(E560) 潪(E660) 蔕(E760) 醄(E860) 嶩(E960) 獫(EA60) 螈(EB60) 馞(EC60) 燤(ED60) 螼(EE60) 駽(EF60) 穟(F060) 鎈(F160) 瀫(F260) 鏞(F360) 瀱(F460) 騩(F560) 鐶(F660) 躒(F760) 鱎(F860) 鸏(F960) 
               [{](7B) ﹃(A17B) ┐(A27B) ㄌ(A37B) 廾(A47B) 叻(A57B) 州(A67B) 坊(A77B) 肚(A87B) 宛(A97B) 泯(AA7B) 哂(AB7B) 洌(AC7B) 迦(AD7B) 徒(AE7B) 砸(AF7B) 閃(B07B) 惋(B17B) 現(B27B) 逢(B37B) 揩(B47B) 程(B57B) 閔(B67B) 暍(B77B) 腥(B87B) 頒(B97B) 漬(BA7B) 認(BB7B) 慮(BC7B) 緹(BD7B) 魷(BE7B) 篦(BF7B) 嚀(C07B) 臨(C17B) 璿(C27B) 爍(C37B) 糰(C47B) 瓤(C57B) 鬱(C67B) ァ(C77B) 忉(C97B) 吙(CA7B) 芅(CB7B) 怦(CC7B) 矼(CD7B) 峌(CE7B) 洑(CF7B) 苻(D07B) 彧(D17B) 烎(D27B) 荁(D37B) 唵(D47B) 捼(D57B) 畣(D67B) 虙(D77B) 喎(D87B) 斞(D97B) 琬(DA7B) 萑(DB7B) 閐(DC7B) 搒(DD7B) 煰(DE7B) 腞(DF7B) 輂(E07B) 嫨(E17B) 漻(E27B) 翢(E37B) 銠(E47B) 憱(E57B) 獛(E67B) 蔋(E77B) 鋞(E87B) 懆(E97B) 瞢(EA7B) 褬(EB7B) 鮒(EC7B) 瞫(ED7B) 覮(EE7B) 鴯(EF7B) 翸(F07B) 鞨(F17B) 矄(F27B) 霫(F37B) 礧(F47B) 鶒(F57B) 驄(F67B) 驌(F77B) 鼷(F87B) 鸔(F97B) 
               [|](7C) ﹄(A17C) └(A27C) ㄍ(A37C) 弋(A47C) 四(A57C) 帆(A67C) 坑(A77C) 育(A87C) 尚(A97C) 泜(AA7C) 咽(AB7C) 洱(AC7C) 迢(AD7C) 徑(AE7C) 砝(AF7C) 院(B07C) 悴(B17C) 琍(B27C) 逖(B37C) 揉(B47C) 稅(B57C) 閏(B67C) 會(B77C) 腮(B87C) 頌(B97C) 漏(BA7C) 誡(BB7C) 慝(BC7C) 罵(BD7C) 魯(BE7C) 糕(BF7C) 嚐(C07C) 舉(C17C) 甕(C27C) 牘(C37C) 辮(C47C) 疊(C57C) 鸛(C67C) ア(C77C) 戉(C97C) 吜(CA7C) 芎(CB7C) 怙(CC7C) 矹(CD7C) 峗(CE7C) 洀(CF7C) 苶(D07C) 恝(D17C) 烡(D27C) 茦(D37C) 唰(D47C) 掤(D57C) 痎(D67C) 虖(D77C) 圌(D87C) 斮(D97C) 琰(DA7C) 萆(DB7C) 隇(DC7C) 搉(DD7C) 煟(DE7C) 腶(DF7C) 輋(E07C) 嫟(E17C) 漒(E27C) 翣(E37C) 銔(E47C) 憰(E57C) 獡(E67C) 蔙(E77C) 鋧(E87C) 懁(E97C) 瞣(EA7C) 褟(EB7C) 鮐(EC7C) 瞲(ED7C) 觲(EE7C) 鴱(EF7C) 聵(F07C) 鞫(F17C) 矱(F27C) 霬(F37C) 礨(F47C) 鶘(F57C) 驂(F67C) 驏(F77C) 鼶(F87C) 鸓(F97C) 
               [}](7D) ﹙(A17D) ┘(A27D) ㄎ(A37D) 弓(A47D) 囚(A57D) 并(A67D) 址(A77D) 良(A87D) 屈(A97D) 泖(AA7D) 咪(AB7D) 洞(AC7D) 迪(AD7D) 徐(AE7D) 破(AF7D) 陣(B07D) 惦(B17D) 瓠(B27D) 逛(B37D) 揆(B47D) 稀(B57D) 開(B67D) 榔(B77D) 腳(B87D) 飼(B97D) 漂(BA7D) 誓(BB7D) 慕(BC7D) 罷(BD7D) 鴆(BE7D) 糖(BF7D) 嚅(C07D) 艱(C17D) 癖(C27D) 犢(C37D) 繽(C47D) 癮(C57D) 鸞(C67D) ィ(C77D) 扐(C97D) 吥(CA7D) 芑(CB7D) 怲(CC7D) 矻(CD7D) 峋(CE7D) 洝(CF7D) 苰(D07D) 恚(D17D) 牂(D27D) 茜(D37D) 啒(D47D) 挻(D57D) 痒(D67D) 蚿(D77D) 堩(D87D) 旐(D97D) 琫(DA7D) 菂(DB7D) 陾(DC7D) 搠(DD7D) 煐(DE7D) 腧(DF7D) 遒(E07D) 孷(E17D) 滭(E27D) 翥(E37D) 銪(E47D) 憢(E57D) 獚(E67D) 蔯(E77D) 鋑(E87D) 懌(E97D) 瞕(EA7D) 觱(EB7D) 魺(EC7D) 瞷(ED7D) 觳(EE7D) 鴸(EF7D) 臑(F07D) 鞤(F17D) 礝(F27D) 霨(F37D) 礤(F47D) 鶐(F57D) 驁(F67D) 驈(F77D) 齃(F87D) 黶(F97D) 
  ------------------------------------------------------------------------------
  big5hkscs (Big5-HKSCS)
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Hong_Kong_Supplementary_Character_Set
             * needs multibyte anchoring
             * unsafe US-ASCII casefolding of 2nd octet
             * needs escaping meta char of 2nd octet
             * and DAMEMOJI samples, here
               [@](40) 倻(8C40) 蕋(8F40) 趩(9040) 媁(9340) 銉(9440) 桇(9640) 愌(9740) 䄉(9940) 鋣(9A40) 嵛(9C40) 籖(9F40) 　(A140) ＼(A240) ｗ(A340) 一(A440) 世(A540) 共(A640) 作(A740) 杓(A840) 咖(A940) 昇(AA40) 陂(AB40) 拯(AC40) 耐(AD40) 哦(AE40) 浬(AF40) 虔(B040) 娼(B140) 毫(B240) 莆(B340) 婷(B440) 溉(B540) 詔(B640) 媳(B740) 睹(B840) 辟(B940) 愿(BA40) 罰(BB40) 劇(BC40) 瑾(BD40) 輥(BE40) 濃(BF40) 錐(C040) 瞧(C140) 駿(C240) 鞭(C340) 願(C440) 護(C540) 讖(C640) す(C740) Л(C840) 乂(C940) 汌(CA40) 杙(CB40) 坨(CC40) 泒(CD40) 哃(CE40) 柜(CF40) 穾(D040) 唊(D140) 毨(D240) 笄(D340) 酎(D440) 崰(D540) 淐(D640) 耞(D740) 釫(D840) 惲(D940) 湨(DA40) 罦(DB40) 軹(DC40) 媷(DD40) 毹(DE40) 稛(DF40) 觡(E040) 凘(E140) 榠(E240) 禗(E340) 裰(E440) 噚(E540) 澍(E640) 膞(E740) 踔(E840) 噳(E940) 澢(EA40) 蕀(EB40) 錋(EC40) 檕(ED40) 蕷(EE40) 鞞(EF40) 璸(F040) 蹛(F140) 徿(F240) 譑(F340) 嚵(F440) 鏼(F540) 蠩(F640) 糴(F740) 讌(F840) 纘(F940) 廹(FC40) 鑂(FE40) 
               [[](5B) É (885B) 团(895B) 撍(8A5B) 腭(8B5B) 冮(8C5B) 橗(8F5B) 迹(905B) 髠(915B) 㛓(935B) 釥(965B) 鋥(975B) 婮(985B) 䊔(995B) 靀(9A5B) 挵(9F5B) 惽(A05B) ︴(A15B) 兞(A25B) Ω(A35B) 久(A45B) 加(A55B) 吆(A65B) 吝(A75B) 沍(A85B) 坤(A95B) 歧(AA5B) 俎(AB5B) 架(AC5B) 茉(AD5B) 娌(AE5B) 琉(AF5B) 豺(B05B) 崙(B15B) 涵(B25B) 訥(B35B) 廂(B45B) 琥(B55B) 跋(B65B) 愴(B75B) 稟(B85B) 鉀(B95B) 暨(BA5B) 蒜(BB5B) 墩(BC5B) 稼(BD5B) 閭(BE5B) 璟(BF5B) 頤(C05B) 繆(C15B) 攆(C25B) 鵠(C35B) 壤(C45B) 騾(C55B) 觀(C65B) ぴ(C75B) ё(C85B) 夬(C95B) 伻(CA5B) 汥(CB5B) 岮(CC5B) 牪(CD5B) 垙(CE5B) 枮(CF5B) 胂(D05B) 娙(D15B) 浟(D25B) 罜(D35B) 倕(D45B) 惙(D55B) 焎(D65B) 莨(D75B) 偨(D85B) 揳(D95B) 烻(DA5B) 艵(DB5B) 鄅(DC5B) 幍(DD5B) 滃(DE5B) 絿(DF5B) 賌(E05B) 墁(E15B) 榞(E25B) 箙(E35B) 跽(E45B) 嬂(E55B) 潩(E65B) 蔈(E75B) 醅(E85B) 嬠(E95B) 獩(EA5B) 螛(EB5B) 頲(EC5B) 濨(ED5B) 蟅(EE5B) 駷(EF5B) 礐(F05B) 鎎(F15B) 氌(F25B) 辴(F35B) 瀼(F45B) 騴(F55B) 酄(F65B) 譿(F75B) 鱍(F85B) 鱮(F95B) 囯(FB5B) 玪(FE5B) 
               [\](5C) Ě (885C) 声(895C) 蹾(8A5C) 胬(8B5C) 笋(8E5C) 蕚(8F5C) 髢(915C) 脪(935C) 䓀(965C) 珢(975C) 娫(985C) 糭(995C) 䨵(9A5C) 鞸(9B5C) 㘘(9C5C) 疱(9E5C) 髿(9F5C) 癧(A05C) ﹏(A15C) 兝(A25C) α(A35C) 么(A45C) 功(A55C) 吒(A65C) 吭(A75C) 沔(A85C) 坼(A95C) 歿(AA5C) 俞(AB5C) 枯(AC5C) 苒(AD5C) 娉(AE5C) 珮(AF5C) 豹(B05C) 崤(B15C) 淚(B25C) 許(B35C) 廄(B45C) 琵(B55C) 跚(B65C) 愧(B75C) 稞(B85C) 鈾(B95C) 暝(BA5C) 蓋(BB5C) 墦(BC5C) 穀(BD5C) 閱(BE5C) 璞(BF5C) 餐(C05C) 縷(C15C) 擺(C25C) 黠(C35C) 孀(C45C) 髏(C55C) 躡(C65C) ふ(C75C) ж(C85C) 尐(C95C) 佢(CA5C) 汻(CB5C) 岤(CC5C) 狖(CD5C) 垥(CE5C) 柦(CF5C) 胐(D05C) 娖(D15C) 涂(D25C) 罡(D35C) 偅(D45C) 惝(D55C) 牾(D65C) 莍(D75C) 傜(D85C) 揊(D95C) 焮(DA5C) 茻(DB5C) 鄃(DC5C) 幋(DD5C) 滜(DE5C) 綅(DF5C) 赨(E05C) 塿(E15C) 槙(E25C) 箤(E35C) 踊(E45C) 嫹(E55C) 潿(E65C) 蔌(E75C) 醆(E85C) 嬞(E95C) 獦(EA5C) 螏(EB5C) 餤(EC5C) 燡(ED5C) 螰(EE5C) 駹(EF5C) 礒(F05C) 鎪(F15C) 瀙(F25C) 酀(F35C) 瀵(F45C) 騱(F55C) 酅(F65C) 贕(F75C) 鱋(F85C) 鱭(F95C) 园(FB5C) 檝(FD5C) 
               []](5D) È (885D) 处(895D) 尜(8B5D) 䀉(8C5D) 筕(8E5D) 㒖(8F5D) 哋(925D) 瑺(945D) 騟(955D) (965D) 㻩(975D) 输(995D) 鞲(9A5D) 襷(9C5D) 㷷(9D5D) 肶(9E5D) 篏(9F5D) 髗(A05D) （(A15D) 兡(A25D) β(A35D) 也(A45D) 包(A55D) 因(A65D) 吞(A75D) 沘(A85D) 夜(A95D) 氓(AA5D) 侷(AB5D) 柵(AC5D) 苗(AD5D) 孫(AE5D) 珠(AF5D) 財(B05D) 崧(B15D) 淫(B25D) 設(B35D) 弼(B45D) 琶(B55D) 跑(B65D) 愍(B75D) 窟(B85D) 鉛(B95D) 榜(BA5D) 蒸(BB5D) 奭(BC5D) 稽(BD5D) 霄(BE5D) 瓢(BF5D) 館(C05D) 縲(C15D) 擻(C25D) 鼕(C35D) 孃(C45D) 魔(C55D) 釁(C65D) ぶ(C75D) з(C85D) 巿(C95D) 佉(CA5D) 沎(CB5D) 岠(CC5D) 狋(CD5D) 垚(CE5D) 柛(CF5D) 胅(D05D) 娭(D15D) 涘(D25D) 罞(D35D) 偟(D45D) 惈(D55D) 牻(D65D) 荺(D75D) 傒(D85D) 揠(D95D) 焱(DA5D) 菏(DB5D) 酡(DC5D) 廅(DD5D) 滘(DE5D) 絺(DF5D) 赩(E05D) 塴(E15D) 榗(E25D) 箂(E35D) 踃(E45D) 嬁(E55D) 澕(E65D) 蓴(E75D) 醊(E85D) 寯(E95D) 獧(EA5D) 螗(EB5D) 餟(EC5D) 燱(ED5D) 螬(EE5D) 駸(EF5D) 礑(F05D) 鎞(F15D) 瀧(F25D) 鄿(F35D) 瀯(F45D) 騬(F55D) 醹(F65D) 躕(F75D) 鱕(F85D) 鸋(F95D) 㯳(FD5D) 
               [^](5E) Ō (885E) 备(895E) 橣(8C5E) 笩(8E5E) 髴(915E) 嚞(925E) (965E) 璴(975E) 樫(985E) 烀(995E) 韂(9A5E) 顇(9B5E) 蠄(9E5E) 鬪(9F5E) 鵄(A05E) ）(A15E) 兣(A25E) γ(A35E) 乞(A45E) 匆(A55E) 回(A65E) 吾(A75E) 沂(A85E) 奉(A95E) 氛(AA5E) 兗(AB5E) 柩(AC5E) 英(AD5E) 屘(AE5E) 珪(AF5E) 貢(B05E) 崗(B15E) 淘(B25E) 訟(B35E) 彭(B45E) 琴(B55E) 跌(B65E) 愆(B75E) 窠(B85E) 鉋(B95E) 榨(BA5E) 蓀(BB5E) 嬉(BC5E) 稷(BD5E) 霆(BE5E) 甌(BF5E) 餞(C05E) 繃(C15E) 擷(C25E) 鼬(C35E) 孽(C45E) 魑(C55E) 鑲(C65E) ぷ(C75E) и(C85E) 旡(C95E) 体(CA5E) 灴(CB5E) 岵(CC5E) 狘(CD5E) 垕(CE5E) 柺(CF5E) 胣(D05E) 娮(D15E) 洯(D25E) 罠(D35E) 偩(D45E) 悱(D55E) 牼(D65E) 荳(D75E) 傂(D85E) 揶(D95E) 焣(DA5E) 菹(DB5E) 酤(DC5E) 廌(DD5E) 溙(DE5E) 綎(DF5E) 趑(E05E) 墋(E15E) 榐(E25E) 粻(E35E) 踇(E45E) 嬇(E55E) 潣(E65E) 蔪(E75E) 醁(E85E) 嶬(E95E) 獬(EA5E) 螓(EB5E) 餧(EC5E) 燨(ED5E) 螹(EE5E) 駶(EF5E) 禭(F05E) 鎦(F15E) 瀠(F25E) 醰(F35E) 瀷(F45E) 騪(F55E) 鐿(F65E) 躔(F75E) 鱙(F85E) 鸍(F95E) 㘣(FB5E) 釖(FC5E) 枱(FD5E) 珉(FE5E) 
               [`](60) Ǒ(8860) 头(8960) 㞗(8B60) 䈣(8C60) 崾(8D60) 葘(8F60) 㦀(9060) 鬔(9160) 嚒(9260) 飜(9660) 総(9960) 䫤(9A60) 运(9D60) 裇(9E60) 鬮(9F60) 鮏(A060) ︶(A160) 瓩(A260) ε(A360) 亡(A460) 匝(A560) 圳(A660) 呎(A760) 灼(A860) 奈(A960) 注(AA60) 冑(AB60) 柄(AC60) 苜(AD60) 害(AE60) 畔(AF60) 躬(B060) 常(B160) 深(B260) 訢(B360) 循(B460) 琛(B560) 跆(B660) 戡(B760) 節(B860) 鉑(B960) 槁(BA60) 蒐(BB60) 嬋(BC60) 窯(BD60) 霉(BE60) 瘴(BF60) 餡(C060) 總(C160) 曜(C260) 嚥(C360) 巉(C460) 鰥(C560) 顱(C660) べ(C760) к(C860) 毌(C960) 伾(CA60) 牣(CB60) 岨(CC60) 狜(CD60) 复(CE60) 柊(CF60) 胜(D060) 娏(D160) 涋(D260) 罛(D360) 偣(D460) 悷(D560) 猝(D660) 荴(D760) 兟(D860) 揲(D960) 焢(DA60) 菀(DB60) 酢(DC60) 廋(DD60) 溎(DE60) 綃(DF60) 趎(E060) 墇(E160) 榵(E260) 粼(E360) 踅(E460) 嬏(E560) 潪(E660) 蔕(E760) 醄(E860) 嶩(E960) 獫(EA60) 螈(EB60) 馞(EC60) 燤(ED60) 螼(EE60) 駽(EF60) 穟(F060) 鎈(F160) 瀫(F260) 鏞(F360) 瀱(F460) 騩(F560) 鐶(F660) 躒(F760) 鱎(F860) 鸏(F960) 坆(FB60) 
               [{](7B) ù (887B) 询(897B) 庙(8C7B) 拥(8D7B) 籴(8E7B) 蕳(8F7B) 鶃(917B) 塲(967B) 㬹(997B) 㝯(9A7B) 纇(9B7B) 画(9C7B) 䶜(9D7B) 饀(9F7B) ﹃(A17B) ┐(A27B) ㄌ(A37B) 廾(A47B) 叻(A57B) 州(A67B) 坊(A77B) 肚(A87B) 宛(A97B) 泯(AA7B) 哂(AB7B) 洌(AC7B) 迦(AD7B) 徒(AE7B) 砸(AF7B) 閃(B07B) 惋(B17B) 現(B27B) 逢(B37B) 揩(B47B) 程(B57B) 閔(B67B) 暍(B77B) 腥(B87B) 頒(B97B) 漬(BA7B) 認(BB7B) 慮(BC7B) 緹(BD7B) 魷(BE7B) 篦(BF7B) 嚀(C07B) 臨(C17B) 璿(C27B) 爍(C37B) 糰(C47B) 瓤(C57B) 鬱(C67B) ァ(C77B) 乚(C87B) 忉(C97B) 吙(CA7B) 芅(CB7B) 怦(CC7B) 矼(CD7B) 峌(CE7B) 洑(CF7B) 苻(D07B) 彧(D17B) 烎(D27B) 荁(D37B) 唵(D47B) 捼(D57B) 畣(D67B) 虙(D77B) 喎(D87B) 斞(D97B) 琬(DA7B) 萑(DB7B) 閐(DC7B) 搒(DD7B) 煰(DE7B) 腞(DF7B) 輂(E07B) 嫨(E17B) 漻(E27B) 翢(E37B) 銠(E47B) 憱(E57B) 獛(E67B) 蔋(E77B) 鋞(E87B) 懆(E97B) 瞢(EA7B) 褬(EB7B) 鮒(EC7B) 瞫(ED7B) 覮(EE7B) 鴯(EF7B) 翸(F07B) 鞨(F17B) 矄(F27B) 霫(F37B) 礧(F47B) 鶒(F57B) 驄(F67B) 驌(F77B) 鼷(F87B) 鸔(F97B) 够(FB7B) 樬(FE7B) 
               [|](7C) ǖ(887C) 车(897C) 忂(8C7C) 挘(8D7C) 糳(8E7C) 䔖(8F7C) 諚(927C) 蠭(957C) (967C) 䤵(977C) 腖(997C) 补(9C7C) 鞺(9F7C) 捤(A07C) ﹄(A17C) └(A27C) ㄍ(A37C) 弋(A47C) 四(A57C) 帆(A67C) 坑(A77C) 育(A87C) 尚(A97C) 泜(AA7C) 咽(AB7C) 洱(AC7C) 迢(AD7C) 徑(AE7C) 砝(AF7C) 院(B07C) 悴(B17C) 琍(B27C) 逖(B37C) 揉(B47C) 稅(B57C) 閏(B67C) 會(B77C) 腮(B87C) 頌(B97C) 漏(BA7C) 誡(BB7C) 慝(BC7C) 罵(BD7C) 魯(BE7C) 糕(BF7C) 嚐(C07C) 舉(C17C) 甕(C27C) 牘(C37C) 辮(C47C) 疊(C57C) 鸛(C67C) ア(C77C) 戉(C97C) 吜(CA7C) 芎(CB7C) 怙(CC7C) 矹(CD7C) 峗(CE7C) 洀(CF7C) 苶(D07C) 恝(D17C) 烡(D27C) 茦(D37C) 唰(D47C) 掤(D57C) 痎(D67C) 虖(D77C) 圌(D87C) 斮(D97C) 琰(DA7C) 萆(DB7C) 隇(DC7C) 搉(DD7C) 煟(DE7C) 腶(DF7C) 輋(E07C) 嫟(E17C) 漒(E27C) 翣(E37C) 銔(E47C) 憰(E57C) 獡(E67C) 蔙(E77C) 鋧(E87C) 懁(E97C) 瞣(EA7C) 褟(EB7C) 鮐(EC7C) 瞲(ED7C) 觲(EE7C) 鴱(EF7C) 聵(F07C) 鞫(F17C) 矱(F27C) 霬(F37C) 礨(F47C) 鶘(F57C) 驂(F67C) 驏(F77C) 鼶(F87C) 鸓(F97C) 梦(FB7C) 憇(FC7C) 璂(FE7C) 
               [}](7D) ǘ(887D) 轧(897D) 㧻(8A7D) 垜(8B7D) 㧸(8D7D) 糵(8E7D) 枿(8F7D) 鸎(917D) 堢(967D) 綤(987D) 腙(997D) 鵉(9A7D) 墵(9B7D) 达(9D7D) 匬(9F7D) 栂(A07D) ﹙(A17D) ┘(A27D) ㄎ(A37D) 弓(A47D) 囚(A57D) 并(A67D) 址(A77D) 良(A87D) 屈(A97D) 泖(AA7D) 咪(AB7D) 洞(AC7D) 迪(AD7D) 徐(AE7D) 破(AF7D) 陣(B07D) 惦(B17D) 瓠(B27D) 逛(B37D) 揆(B47D) 稀(B57D) 開(B67D) 榔(B77D) 腳(B87D) 飼(B97D) 漂(BA7D) 誓(BB7D) 慕(BC7D) 罷(BD7D) 鴆(BE7D) 糖(BF7D) 嚅(C07D) 艱(C17D) 癖(C27D) 犢(C37D) 繽(C47D) 癮(C57D) 鸞(C67D) ィ(C77D) 刂(C87D) 扐(C97D) 吥(CA7D) 芑(CB7D) 怲(CC7D) 矻(CD7D) 峋(CE7D) 洝(CF7D) 苰(D07D) 恚(D17D) 牂(D27D) 茜(D37D) 啒(D47D) 挻(D57D) 痒(D67D) 蚿(D77D) 堩(D87D) 旐(D97D) 琫(DA7D) 菂(DB7D) 陾(DC7D) 搠(DD7D) 煐(DE7D) 腧(DF7D) 遒(E07D) 孷(E17D) 滭(E27D) 翥(E37D) 銪(E47D) 憢(E57D) 獚(E67D) 蔯(E77D) 鋑(E87D) 懌(E97D) 瞕(EA7D) 觱(EB7D) 魺(EC7D) 瞷(ED7D) 觳(EE7D) 鴸(EF7D) 臑(F07D) 鞤(F17D) 礝(F27D) 霨(F37D) 礤(F47D) 鶐(F57D) 驁(F67D) 驈(F77D) 齃(F87D) 黶(F97D) 冲(FA7D) 㛃(FB7D) 宪(FC7D) 䥓(FE7D) 
  ------------------------------------------------------------------------------
  eucjp (EUC-JP)
             1st       2nd
             A1..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Extended_Unix_Code#EUC-JP
             * needs multibyte anchoring
             * needs no escaping meta char of 2nd octet
             * safe US-ASCII casefolding of 2nd octet
  ------------------------------------------------------------------------------
  gb18030 (GB18030)
             1st       2nd       3rd       4th
             81..FE    30..39    81..FE    30..39
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/GB_18030
             * needs multibyte anchoring
             * unsafe US-ASCII casefolding of 2nd-4th octet
             * needs escaping meta char of 2nd octet
             * and DAMEMOJI samples, here
               [@](40) 丂(8140) 侤(8240) 傽(8340) 凘(8440) 匑(8540) 咢(8640) 嘆(8740) 園(8840) 堾(8940) 夽(8A40) 婡(8B40) 孈(8C40) 岪(8D40) 嶡(8E40) 廆(8F40) 怈(9040) 慇(9140) 扏(9240) 揁(9340) 擛(9440) 旲(9540) 朄(9640) 桜(9740) 楡(9840) 橜(9940) 欯(9A40) 汙(9B40) 淍(9C40) 滰(9D40) 濦(9E40) 烜(9F40) 燖(A040) ˊ(A840) 〡(A940) 狜(AA40) 獲(AB40) 珸(AC40) 瑻(AD40) 瓳(AE40) 疈(AF40) 癅(B040) 盄(B140) 睝(B240) 矦(B340) 碄(B440) 礍(B540) 禓(B640) 稝(B740) 窣(B840) 笯(B940) 篅(BA40) 籃(BB40) 粿(BC40) 紷(BD40) 継(BE40) 緻(BF40) 繞(C040) 罖(C140) 翤(C240) 聾(C340) 腀(C440) 臔(C540) 艪(C640) 茾(C740) 菮(C840) 葽(C940) 蔃(CA40) 薂(CB40) 藹(CC40) 虭(CD40) 蜙(CE40) 螥(CF40) 蠤(D040) 袬(D140) 褸(D240) 覢(D340) 訞(D440) 誁(D540) 諤(D640) 譆(D740) 谸(D840) 貮(D940) 贎(DA40) 跕(DB40) 蹳(DC40) 軥(DD40) 轅(DE40) 這(DF40) 郂(E040) 酅(E140) 釦(E240) 鉆(E340) 銨(E440) 錊(E540) 鍬(E640) 鏎(E740) 鐯(E840) 锧(E940) 闌(EA40) 隌(EB40) 霡(EC40) 鞞(ED40) 頏(EE40) 顯(EF40) 餈(F040) 馌(F140) 駺(F240) 驚(F340) 鬇(F440) 魼(F540) 鯜(F640) 鰼(F740) 鳣(F840) 鵃(F940) 鶣(FA40) 鸃(FB40) 麫(FC40) 鼲(FD40) 兀(FE40) 
               [[](5B) 乕(815B) 俒(825B) 僛(835B) 刐(845B) 匸(855B) 哰(865B) 嘯(875B) 圼(885B) 塠(895B) 奫(8A5B) 媅(8B5B) 孾(8C5B) 峓(8D5B) 嶽(8E5B) 廩(8F5B) 怺(905B) 慬(915B) 抂(925B) 揫(935B) 擺(945B) 昜(955B) 朳(965B) 梉(975B) 榌(985B) 橻(995B) 歔(9A5B) 沎(9B5B) 淸(9C5B) 漑(9D5B) 瀃(9E5B) 焄(9F5B) 燵(A05B) ╗ (A85B) 猍(AA5B) 玔(AB5B) 琜(AC5B) 璠(AD5B) 甗(AE5B) 痆(AF5B) 癧(B05B) 盵(B15B) 瞇(B25B) 砙(B35B) 碵(B45B) 礫(B55B) 禰(B65B) 穂(B75B) 竅(B85B) 筟(B95B) 篬(BA5B) 籟(BB5B) 糩(BC5B) 絒(BD5B) 綶(BE5B) 縖(BF5B) 繹(C05B) 羀(C15B) 耓(C25B) 肹(C35B) 腫(C45B) 臶(C55B) 芠(C65B) 荹(C75B) 萚(C85B) 蒣(C95B) 蔥(CA5B) 薣(CB5B) 蘙(CC5B) 蚚(CD5B) 蝃(CE5B) 蟍(CF5B) 衃(D05B) 裑(D15B) 襕(D25B) 覽(D35B) 訹(D45B) 誟(D55B) 諿(D65B) 譡(D75B) 豙(D85B) 賉(D95B) 赱(DA5B) 踇(DB5B) 躘(DC5B) 輀(DD5B) 轠(DE5B) 遊(DF5B) 郲(E05B) 醄(E15B) 鈁(E25B) 鉡(E35B) 鋄(E45B) 錥(E55B) 鎇(E65B) 鏪(E75B) 鑋(E85B) 閇(E95B) 闧(EA5B) 隱(EB5B) 靃(EC5B) 韀(ED5B) 頪(EE5B) 颷(EF5B) 餥(F05B) 馵(F15B) 騕(F25B) 骩(F35B) 鬧(F45B) 鮗(F55B) 鯷(F65B) 鱗(F75B) 鳾(F85B) 鵞(F95B) 鶾(FA5B) 鸞(FB5B) 黐(FC5B) 齕(FD5B) 
               [\](5C) 乗(815C) 俓(825C) 僜(835C) 刓(845C) 匼(855C) 哱(865C) 嘰(875C) 圽(885C) 塡(895C) 奬(8A5C) 媆(8B5C) 孿(8C5C) 峔(8D5C) 嶾(8E5C) 廫(8F5C) 怽(905C) 慭(915C) 抃(925C) 揬(935C) 擻(945C) 昞(955C) 朶(965C) 梊(975C) 榎(985C) 橽(995C) 歕(9A5C) 沑(9B5C) 淺(9C5C) 漒(9D5C) 瀄(9E5C) 焅(9F5C) 燶(A05C) ╘ (A85C) ‐(A95C) 猏(AA5C) 玕(AB5C) 琝(AC5C) 璡(AD5C) 甛(AE5C) 痋(AF5C) 癨(B05C) 盶(B15C) 瞈(B25C) 砛(B35C) 碶(B45C) 礬(B55C) 禱(B65C) 穃(B75C) 竆(B85C) 筡(B95C) 篭(BA5C) 籠(BB5C) 糪(BC5C) 絓(BD5C) 綷(BE5C) 縗(BF5C) 繺(C05C) 羂(C15C) 耚(C25C) 肻(C35C) 腬(C45C) 臷(C55C) 芢(C65C) 荺(C75C) 萛(C85C) 蒤(C95C) 蔦(CA5C) 薥(CB5C) 蘚(CC5C) 蚛(CD5C) 蝄(CE5C) 蟎(CF5C) 衆(D05C) 裓(D15C) 襖(D25C) 覾(D35C) 診(D45C) 誠(D55C) 謀(D65C) 譢(D75C) 豛(D85C) 賊(D95C) 赲(DA5C) 踈(DB5C) 躙(DC5C) 輁(DD5C) 轡(DE5C) 運(DF5C) 郳(E05C) 醆(E15C) 鈂(E25C) 鉢(E35C) 鋅(E45C) 錦(E55C) 鎈(E65C) 鏫(E75C) 鑌(E85C) 閈(E95C) 闬(EA5C) 隲(EB5C) 靄(EC5C) 韁(ED5C) 頫(EE5C) 颸(EF5C) 餦(F05C) 馶(F15C) 騖(F25C) 骪(F35C) 鬨(F45C) 鮘(F55C) 鯸(F65C) 鱘(F75C) 鳿(F85C) 鵟(F95C) 鶿(FA5C) 鸤(FB5C) 黒(FC5C) 齖(FD5C) 
               []](5D) 乚(815D) 俔(825D) 僝(835D) 刔(845D) 匽(855D) 哴(865D) 嘳(875D) 圿(885D) 塢(895D) 奭(8A5D) 媇(8B5D) 宂(8C5D) 峕(8D5D) 嶿(8E5D) 廬(8F5D) 怾(905D) 慮(915D) 抅(925D) 揮(935D) 擼(945D) 昡(955D) 朷(965D) 梋(975D) 榏(985D) 橾(995D) 歖(9A5D) 沒(9B5D) 淽(9C5D) 漖(9D5D) 瀅(9E5D) 焆(9F5D) 燷(A05D) ╙ (A85D) 猐(AA5D) 玗(AB5D) 琞(AC5D) 璢(AD5D) 甝(AE5D) 痌(AF5D) 癩(B05D) 盷(B15D) 瞉(B25D) 砞(B35D) 碷(B45D) 礭(B55D) 禲(B65D) 穄(B75D) 竇(B85D) 筣(B95D) 篯(BA5D) 籡(BB5D) 糫(BC5D) 絔(BD5D) 綸(BE5D) 縘(BF5D) 繻(C05D) 羃(C15D) 耛(C25D) 胅(C35D) 腯(C45D) 臸(C55D) 芣(C65D) 荾(C75D) 萞(C85D) 蒥(C95D) 蔧(CA5D) 薦(CB5D) 蘛(CC5D) 蚞(CD5D) 蝅(CE5D) 蟏(CF5D) 衇(D05D) 裖(D15D) 襗(D25D) 覿(D35D) 註(D45D) 誡(D55D) 謁(D65D) 譣(D75D) 豜(D85D) 賋(D95D) 赸(DA5D) 踋(DB5D) 躚(DC5D) 輂(DD5D) 轢(DE5D) 遌(DF5D) 郵(E05D) 醈(E15D) 鈃(E25D) 鉣(E35D) 鋆(E45D) 錧(E55D) 鎉(E65D) 鏬(E75D) 鑍(E85D) 閉(E95D) 闿(EA5D) 隴(EB5D) 靅(EC5D) 韂(ED5D) 頬(EE5D) 颹(EF5D) 餧(F05D) 馷(F15D) 騗(F25D) 骫(F35D) 鬩(F45D) 鮙(F55D) 鯹(F65D) 鱙(F75D) 鴀(F85D) 鵠(F95D) 鷀(FA5D) 鸧(FB5D) 黓(FC5D) 齗(FD5D) 
               [^](5E) 乛(815E) 俕(825E) 僞(835E) 刕(845E) 區(855E) 哵(865E) 嘵(875E) 坁(885E) 塣(895E) 奮(8A5E) 媈(8B5E) 宆(8C5E) 峖(8D5E) 巀(8E5E) 廭(8F5E) 恀(905E) 慯(915E) 抆(925E) 揯(935E) 擽(945E) 昢(955E) 朸(965E) 梌(975E) 榐(985E) 橿(995E) 歗(9A5E) 沕(9B5E) 淾(9C5E) 漗(9D5E) 瀆(9E5E) 焇(9F5E) 燸(A05E) ╚ (A85E) 猑(AA5E) 玘(AB5E) 琟(AC5E) 璣(AD5E) 甞(AE5E) 痎(AF5E) 癪(B05E) 盺(B15E) 瞊(B25E) 砠(B35E) 碸(B45E) 礮(B55E) 禴(B65E) 穅(B75E) 竈(B85E) 筤(B95E) 篰(BA5E) 籢(BB5E) 糬(BC5E) 絕(BD5E) 綹(BE5E) 縙(BF5E) 繼(C05E) 羄(C15E) 耝(C25E) 胇(C35E) 腲(C45E) 臹(C55E) 芧(C65E) 荿(C75E) 萟(C85E) 蒦(C95E) 蔨(CA5E) 薧(CB5E) 蘜(CC5E) 蚟(CD5E) 蝆(CE5E) 蟐(CF5E) 衈(D05E) 裗(D15E) 襘(D25E) 觀(D35E) 証(D45E) 誢(D55E) 謂(D65E) 譤(D75E) 豝(D85E) 賌(D95E) 赹(DA5E) 踍(DB5E) 躛(DC5E) 較(DD5E) 轣(DE5E) 過(DF5E) 郶(E05E) 醊(E15E) 鈄(E25E) 鉤(E35E) 鋇(E45E) 錨(E55E) 鎊(E65E) 鏭(E75E) 鑎(E85E) 閊(E95E) 阇(EA5E) 隵(EB5E) 靆(EC5E) 韃(ED5E) 頭(EE5E) 颺(EF5E) 館(F05E) 馸(F15E) 騘(F25E) 骬(F35E) 鬪(F45E) 鮚(F55E) 鯺(F65E) 鱚(F75E) 鴁(F85E) 鵡(F95E) 鷁(FA5E) 鸮(FB5E) 黕(FC5E) 齘(FD5E) 
               [`](60) 乣(8160) 俙(8260) 僠(8360) 刞(8460) 卄(8560) 哷(8660) 嘸(8760) 坄(8860) 塦(8960) 奰(8A60) 媊(8B60) 宍(8C60) 峘(8D60) 巂(8E60) 廯(8F60) 恅(9060) 慲(9160) 抈(9260) 揱(9360) 擿(9460) 昤(9560) 朻(9660) 梎(9760) 榒(9860) 檂(9960) 歚(9A60) 沗(9B60) 渀(9C60) 漙(9D60) 瀈(9E60) 焋(9F60) 燻(A060) ╜ (A860) ー(A960) 猔(AA60) 玚(AB60) 琡(AC60) 璥(AD60) 甡(AE60) 痐(AF60) 癭(B060) 盽(B160) 瞏(B260) 砢(B360) 碻(B460) 礰(B560) 禶(B660) 穈(B760) 竊(B860) 筦(B960) 篳(BA60) 籤(BB60) 糮(BC60) 絗(BD60) 綻(BE60) 縛(BF60) 繾(C060) 羆(C160) 耟(C260) 胉(C360) 腵(C460) 臽(C560) 芵(C660) 莁(C760) 萡(C860) 蒨(C960) 蔪(CA60) 薫(CB60) 蘞(CC60) 蚡(CD60) 蝋(CE60) 蟕(CF60) 衊(D060) 裛(D160) 襚(D260) 觍(D360) 訿(D460) 誤(D560) 謄(D660) 譧(D760) 豟(D860) 賎(D960) 赻(DA60) 踐(DB60) 躟(DC60) 輅(DD60) 轥(DE60) 違(DF60) 郹(E060) 醏(E160) 鈆(E260) 鉦(E360) 鋊(E460) 錪(E560) 鎌(E660) 鏯(E760) 鑐(E860) 閌(E960) 阘(EA60) 隸(EB60) 靈(EC60) 韅(ED60) 頯(EE60) 颼(EF60) 餪(F060) 馺(F160) 騚(F260) 骮(F360) 鬬(F460) 鮜(F560) 鯼(F660) 鱜(F760) 鴃(F860) 鵣(F960) 鷃(FA60) 鸴(FB60) 黗(FC60) 齚(FD60) 
               [{](7B) 亄(817B) 倇(827B) 儃(837B) 剓(847B) 厈(857B) 唟(867B) 噞(877B) 坽(887B) 墈(897B) 妠(8A7B) 媨(8B7B) 寋(8C7B) 峽(8D7B) 巤(8E7B) 弡(8F7B) 恵(907B) 憑(917B) 抺(927B) 搟(937B) 攞(947B) 晎(957B) 杮(967B) 梴(977B) 榹(987B) 檣(997B) 歿(9A7B) 泏(9B7B) 渰(9C7B) 漿(9D7B) 瀧(9E7B) 焮(9F7B) 爗(A07B) ▄ (A87B) ﹞(A97B) 獅(AA7B) 珄(AB7B) 瑊(AC7B) 瓄(AD7B) 畕(AE7B) 瘂(AF7B) 皗(B07B) 眥(B17B) 瞷(B27B) 硔(B37B) 磠(B47B) 祘(B57B) 秢(B67B) 穥(B77B) 竰(B87B) 箋(B97B) 簕(BA7B) 粄(BB7B) 納(BC7B) 絳(BD7B) 緖(BE7B) 縶(BF7B) 纚(C07B) 羬(C17B) 聓(C27B) 脅(C37B) 膡(C47B) 舺(C57B) 苳(C67B) 莧(C77B) 葅(C87B) 蓒(C97B) 蕒(CA7B) 藍(CB7B) 蘽(CC7B) 蛖(CD7B) 蝱(CE7B) 蟵(CF7B) 衶(D07B) 褅(D17B) 襸(D27B) 觷(D37B) 詛(D47B) 調(D57B) 謠(D67B) 讃(D77B) 貃(D87B) 賩(D97B) 趝(DA7B) 踸(DB7B) 躿(DC7B) 輠(DD7B) 辿(DE7B) 遻(DF7B) 鄘(E07B) 醷(E17B) 鈡(E27B) 銂(E37B) 鋥(E47B) 鍆(E57B) 鎨(E67B) 鐊(E77B) 鑬(E87B) 閧(E97B) 陒(EA7B) 雥(EB7B) 靮(EC7B) 韠(ED7B) 顊(EE7B) 飡(EF7B) 饆(F07B) 駕(F17B) 騵(F27B) 髙(F37B) 魗(F47B) 鮷(F57B) 鰗(F67B) 鱷(F77B) 鴞(F87B) 鵾(F97B) 鷞(FA7B) 鹻(FB7B) 鼂(FC7B) 齵(FD7B) 
               [|](7C) 亅(817C) 倈(827C) 億(837C) 剕(847C) 厊(857C) 唡(867C) 噟(877C) 坾(887C) 墊(897C) 妡(8A7C) 媩(8B7C) 寍(8C7C) 峾(8D7C) 巪(8E7C) 弢(8F7C) 恷(907C) 憒(917C) 抾(927C) 搢(937C) 攟(947C) 晐(957C) 東(967C) 梶(977C) 榺(987C) 檤(997C) 殀(9A7C) 泑(9B7C) 渱(9C7C) 潀(9D7C) 瀨(9E7C) 焲(9F7C) 爘(A07C) ▅ (A87C) ﹟(A97C) 獆(AA7C) 珅(AB7C) 瑋(AC7C) 瓅(AD7C) 畖(AE7C) 瘄(AF7C) 皘(B07C) 眧(B17C) 瞸(B27C) 硘(B37C) 磡(B47C) 祙(B57C) 秥(B67C) 穦(B77C) 竱(B87C) 箌(B97C) 簗(BA7C) 粅(BB7C) 紎(BC7C) 絴(BD7C) 緗(BE7C) 縷(BF7C) 纜(C07C) 羭(C17C) 聕(C27C) 脇(C37C) 膢(C47C) 舼(C57C) 苵(C67C) 莬(C77C) 葇(C87C) 蓔(C97C) 蕓(CA7C) 藎(CB7C) 蘾(CC7C) 蛗(CD7C) 蝲(CE7C) 蟶(CF7C) 衸(D07C) 褆(D17C) 襹(D27C) 觸(D37C) 詜(D47C) 諀(D57C) 謡(D67C) 讄(D77C) 貄(D87C) 質(D97C) 趞(DA7C) 踻(DB7C) 軀(DC7C) 輡(DD7C) 迀(DE7C) 遼(DF7C) 鄚(E07C) 醸(E17C) 鈢(E27C) 銃(E37C) 鋦(E47C) 鍇(E57C) 鎩(E67C) 鐋(E77C) 鑭(E87C) 閨(E97C) 陓(EA7C) 雦(EB7C) 靯(EC7C) 韡(ED7C) 顋(EE7C) 飢(EF7C) 饇(F07C) 駖(F17C) 騶(F27C) 髚(F37C) 魘(F47C) 鮸(F57C) 鰘(F67C) 鱸(F77C) 鴟(F87C) 鵿(F97C) 鷟(FA7C) 鹼(FB7C) 鼃(FC7C) 齶(FD7C) 
               [}](7D) 亇(817D) 倉(827D) 儅(837D) 剗(847D) 厎(857D) 唥(867D) 噠(877D) 坿(887D) 墋(897D) 妢(8A7D) 媫(8B7D) 寎(8C7D) 峿(8D7D) 巬(8E7D) 弣(8F7D) 恾(907D) 憓(917D) 拀(927D) 搣(937D) 攠(947D) 晑(957D) 杴(967D) 梷(977D) 榼(987D) 檥(997D) 殅(9A7D) 泒(9B7D) 渳(9C7D) 潁(9D7D) 瀩(9E7D) 焳(9F7D) 爙(A07D) ▆ (A87D) ﹠(A97D) 獇(AA7D) 珆(AB7D) 瑌(AC7D) 瓆(AD7D) 畗(AE7D) 瘆(AF7D) 皚(B07D) 眪(B17D) 瞹(B27D) 硙(B37D) 磢(B47D) 祡(B57D) 秨(B67D) 穧(B77D) 竲(B87D) 箎(B97D) 簘(BA7D) 粆(BB7D) 紏(BC7D) 絵(BD7D) 緘(BE7D) 縸(BF7D) 纝(C07D) 羮(C17D) 聖(C27D) 脈(C37D) 膤(C47D) 舽(C57D) 苶(C67D) 莭(C77D) 葈(C87D) 蓕(C97D) 蕔(CA7D) 藑(CB7D) 蘿(CC7D) 蛚(CD7D) 蝳(CE7D) 蟷(CF7D) 衹(D07D) 複(D17D) 襺(D27D) 觹(D37D) 詝(D47D) 諁(D57D) 謢(D67D) 讅(D77D) 貆(D87D) 賫(D97D) 趠(DA7D) 踼(DB7D) 軁(DC7D) 輢(DD7D) 迃(DE7D) 遾(DF7D) 鄛(E07D) 醹(E17D) 鈣(E27D) 銄(E37D) 鋧(E47D) 鍈(E57D) 鎪(E67D) 鐌(E77D) 鑮(E87D) 閩(E97D) 陖(EA7D) 雧(EB7D) 靰(EC7D) 韢(ED7D) 題(EE7D) 飣(EF7D) 饈(F07D) 駗(F17D) 騷(F27D) 髛(F37D) 魙(F47D) 鮹(F57D) 鰙(F67D) 鱹(F77D) 鴠(F87D) 鶀(F97D) 鷠(FA7D) 鹽(FB7D) 鼄(FC7D) 齷(FD7D) 
  ------------------------------------------------------------------------------
  gbk (GBK)
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/GBK_(character_encoding)
             * needs multibyte anchoring
             * unsafe US-ASCII casefolding of 2nd octet
             * needs escaping meta char of 2nd octet
             * and DAMEMOJI samples, here
               [@](40) 丂(8140) 侤(8240) 傽(8340) 凘(8440) 匑(8540) 咢(8640) 嘆(8740) 園(8840) 堾(8940) 夽(8A40) 婡(8B40) 孈(8C40) 岪(8D40) 嶡(8E40) 廆(8F40) 怈(9040) 慇(9140) 扏(9240) 揁(9340) 擛(9440) 旲(9540) 朄(9640) 桜(9740) 楡(9840) 橜(9940) 欯(9A40) 汙(9B40) 淍(9C40) 滰(9D40) 濦(9E40) 烜(9F40) 燖(A040) ˊ(A840) 〡(A940) 狜(AA40) 獲(AB40) 珸(AC40) 瑻(AD40) 瓳(AE40) 疈(AF40) 癅(B040) 盄(B140) 睝(B240) 矦(B340) 碄(B440) 礍(B540) 禓(B640) 稝(B740) 窣(B840) 笯(B940) 篅(BA40) 籃(BB40) 粿(BC40) 紷(BD40) 継(BE40) 緻(BF40) 繞(C040) 罖(C140) 翤(C240) 聾(C340) 腀(C440) 臔(C540) 艪(C640) 茾(C740) 菮(C840) 葽(C940) 蔃(CA40) 薂(CB40) 藹(CC40) 虭(CD40) 蜙(CE40) 螥(CF40) 蠤(D040) 袬(D140) 褸(D240) 覢(D340) 訞(D440) 誁(D540) 諤(D640) 譆(D740) 谸(D840) 貮(D940) 贎(DA40) 跕(DB40) 蹳(DC40) 軥(DD40) 轅(DE40) 這(DF40) 郂(E040) 酅(E140) 釦(E240) 鉆(E340) 銨(E440) 錊(E540) 鍬(E640) 鏎(E740) 鐯(E840) 锧(E940) 闌(EA40) 隌(EB40) 霡(EC40) 鞞(ED40) 頏(EE40) 顯(EF40) 餈(F040) 馌(F140) 駺(F240) 驚(F340) 鬇(F440) 魼(F540) 鯜(F640) 鰼(F740) 鳣(F840) 鵃(F940) 鶣(FA40) 鸃(FB40) 麫(FC40) 鼲(FD40) 兀(FE40) 
               [[](5B) 乕(815B) 俒(825B) 僛(835B) 刐(845B) 匸(855B) 哰(865B) 嘯(875B) 圼(885B) 塠(895B) 奫(8A5B) 媅(8B5B) 孾(8C5B) 峓(8D5B) 嶽(8E5B) 廩(8F5B) 怺(905B) 慬(915B) 抂(925B) 揫(935B) 擺(945B) 昜(955B) 朳(965B) 梉(975B) 榌(985B) 橻(995B) 歔(9A5B) 沎(9B5B) 淸(9C5B) 漑(9D5B) 瀃(9E5B) 焄(9F5B) 燵(A05B) ╗ (A85B) 猍(AA5B) 玔(AB5B) 琜(AC5B) 璠(AD5B) 甗(AE5B) 痆(AF5B) 癧(B05B) 盵(B15B) 瞇(B25B) 砙(B35B) 碵(B45B) 礫(B55B) 禰(B65B) 穂(B75B) 竅(B85B) 筟(B95B) 篬(BA5B) 籟(BB5B) 糩(BC5B) 絒(BD5B) 綶(BE5B) 縖(BF5B) 繹(C05B) 羀(C15B) 耓(C25B) 肹(C35B) 腫(C45B) 臶(C55B) 芠(C65B) 荹(C75B) 萚(C85B) 蒣(C95B) 蔥(CA5B) 薣(CB5B) 蘙(CC5B) 蚚(CD5B) 蝃(CE5B) 蟍(CF5B) 衃(D05B) 裑(D15B) 襕(D25B) 覽(D35B) 訹(D45B) 誟(D55B) 諿(D65B) 譡(D75B) 豙(D85B) 賉(D95B) 赱(DA5B) 踇(DB5B) 躘(DC5B) 輀(DD5B) 轠(DE5B) 遊(DF5B) 郲(E05B) 醄(E15B) 鈁(E25B) 鉡(E35B) 鋄(E45B) 錥(E55B) 鎇(E65B) 鏪(E75B) 鑋(E85B) 閇(E95B) 闧(EA5B) 隱(EB5B) 靃(EC5B) 韀(ED5B) 頪(EE5B) 颷(EF5B) 餥(F05B) 馵(F15B) 騕(F25B) 骩(F35B) 鬧(F45B) 鮗(F55B) 鯷(F65B) 鱗(F75B) 鳾(F85B) 鵞(F95B) 鶾(FA5B) 鸞(FB5B) 黐(FC5B) 齕(FD5B) 
               [\](5C) 乗(815C) 俓(825C) 僜(835C) 刓(845C) 匼(855C) 哱(865C) 嘰(875C) 圽(885C) 塡(895C) 奬(8A5C) 媆(8B5C) 孿(8C5C) 峔(8D5C) 嶾(8E5C) 廫(8F5C) 怽(905C) 慭(915C) 抃(925C) 揬(935C) 擻(945C) 昞(955C) 朶(965C) 梊(975C) 榎(985C) 橽(995C) 歕(9A5C) 沑(9B5C) 淺(9C5C) 漒(9D5C) 瀄(9E5C) 焅(9F5C) 燶(A05C) ╘ (A85C) ‐(A95C) 猏(AA5C) 玕(AB5C) 琝(AC5C) 璡(AD5C) 甛(AE5C) 痋(AF5C) 癨(B05C) 盶(B15C) 瞈(B25C) 砛(B35C) 碶(B45C) 礬(B55C) 禱(B65C) 穃(B75C) 竆(B85C) 筡(B95C) 篭(BA5C) 籠(BB5C) 糪(BC5C) 絓(BD5C) 綷(BE5C) 縗(BF5C) 繺(C05C) 羂(C15C) 耚(C25C) 肻(C35C) 腬(C45C) 臷(C55C) 芢(C65C) 荺(C75C) 萛(C85C) 蒤(C95C) 蔦(CA5C) 薥(CB5C) 蘚(CC5C) 蚛(CD5C) 蝄(CE5C) 蟎(CF5C) 衆(D05C) 裓(D15C) 襖(D25C) 覾(D35C) 診(D45C) 誠(D55C) 謀(D65C) 譢(D75C) 豛(D85C) 賊(D95C) 赲(DA5C) 踈(DB5C) 躙(DC5C) 輁(DD5C) 轡(DE5C) 運(DF5C) 郳(E05C) 醆(E15C) 鈂(E25C) 鉢(E35C) 鋅(E45C) 錦(E55C) 鎈(E65C) 鏫(E75C) 鑌(E85C) 閈(E95C) 闬(EA5C) 隲(EB5C) 靄(EC5C) 韁(ED5C) 頫(EE5C) 颸(EF5C) 餦(F05C) 馶(F15C) 騖(F25C) 骪(F35C) 鬨(F45C) 鮘(F55C) 鯸(F65C) 鱘(F75C) 鳿(F85C) 鵟(F95C) 鶿(FA5C) 鸤(FB5C) 黒(FC5C) 齖(FD5C) 
               []](5D) 乚(815D) 俔(825D) 僝(835D) 刔(845D) 匽(855D) 哴(865D) 嘳(875D) 圿(885D) 塢(895D) 奭(8A5D) 媇(8B5D) 宂(8C5D) 峕(8D5D) 嶿(8E5D) 廬(8F5D) 怾(905D) 慮(915D) 抅(925D) 揮(935D) 擼(945D) 昡(955D) 朷(965D) 梋(975D) 榏(985D) 橾(995D) 歖(9A5D) 沒(9B5D) 淽(9C5D) 漖(9D5D) 瀅(9E5D) 焆(9F5D) 燷(A05D) ╙ (A85D) 猐(AA5D) 玗(AB5D) 琞(AC5D) 璢(AD5D) 甝(AE5D) 痌(AF5D) 癩(B05D) 盷(B15D) 瞉(B25D) 砞(B35D) 碷(B45D) 礭(B55D) 禲(B65D) 穄(B75D) 竇(B85D) 筣(B95D) 篯(BA5D) 籡(BB5D) 糫(BC5D) 絔(BD5D) 綸(BE5D) 縘(BF5D) 繻(C05D) 羃(C15D) 耛(C25D) 胅(C35D) 腯(C45D) 臸(C55D) 芣(C65D) 荾(C75D) 萞(C85D) 蒥(C95D) 蔧(CA5D) 薦(CB5D) 蘛(CC5D) 蚞(CD5D) 蝅(CE5D) 蟏(CF5D) 衇(D05D) 裖(D15D) 襗(D25D) 覿(D35D) 註(D45D) 誡(D55D) 謁(D65D) 譣(D75D) 豜(D85D) 賋(D95D) 赸(DA5D) 踋(DB5D) 躚(DC5D) 輂(DD5D) 轢(DE5D) 遌(DF5D) 郵(E05D) 醈(E15D) 鈃(E25D) 鉣(E35D) 鋆(E45D) 錧(E55D) 鎉(E65D) 鏬(E75D) 鑍(E85D) 閉(E95D) 闿(EA5D) 隴(EB5D) 靅(EC5D) 韂(ED5D) 頬(EE5D) 颹(EF5D) 餧(F05D) 馷(F15D) 騗(F25D) 骫(F35D) 鬩(F45D) 鮙(F55D) 鯹(F65D) 鱙(F75D) 鴀(F85D) 鵠(F95D) 鷀(FA5D) 鸧(FB5D) 黓(FC5D) 齗(FD5D) 
               [^](5E) 乛(815E) 俕(825E) 僞(835E) 刕(845E) 區(855E) 哵(865E) 嘵(875E) 坁(885E) 塣(895E) 奮(8A5E) 媈(8B5E) 宆(8C5E) 峖(8D5E) 巀(8E5E) 廭(8F5E) 恀(905E) 慯(915E) 抆(925E) 揯(935E) 擽(945E) 昢(955E) 朸(965E) 梌(975E) 榐(985E) 橿(995E) 歗(9A5E) 沕(9B5E) 淾(9C5E) 漗(9D5E) 瀆(9E5E) 焇(9F5E) 燸(A05E) ╚ (A85E) 猑(AA5E) 玘(AB5E) 琟(AC5E) 璣(AD5E) 甞(AE5E) 痎(AF5E) 癪(B05E) 盺(B15E) 瞊(B25E) 砠(B35E) 碸(B45E) 礮(B55E) 禴(B65E) 穅(B75E) 竈(B85E) 筤(B95E) 篰(BA5E) 籢(BB5E) 糬(BC5E) 絕(BD5E) 綹(BE5E) 縙(BF5E) 繼(C05E) 羄(C15E) 耝(C25E) 胇(C35E) 腲(C45E) 臹(C55E) 芧(C65E) 荿(C75E) 萟(C85E) 蒦(C95E) 蔨(CA5E) 薧(CB5E) 蘜(CC5E) 蚟(CD5E) 蝆(CE5E) 蟐(CF5E) 衈(D05E) 裗(D15E) 襘(D25E) 觀(D35E) 証(D45E) 誢(D55E) 謂(D65E) 譤(D75E) 豝(D85E) 賌(D95E) 赹(DA5E) 踍(DB5E) 躛(DC5E) 較(DD5E) 轣(DE5E) 過(DF5E) 郶(E05E) 醊(E15E) 鈄(E25E) 鉤(E35E) 鋇(E45E) 錨(E55E) 鎊(E65E) 鏭(E75E) 鑎(E85E) 閊(E95E) 阇(EA5E) 隵(EB5E) 靆(EC5E) 韃(ED5E) 頭(EE5E) 颺(EF5E) 館(F05E) 馸(F15E) 騘(F25E) 骬(F35E) 鬪(F45E) 鮚(F55E) 鯺(F65E) 鱚(F75E) 鴁(F85E) 鵡(F95E) 鷁(FA5E) 鸮(FB5E) 黕(FC5E) 齘(FD5E) 
               [`](60) 乣(8160) 俙(8260) 僠(8360) 刞(8460) 卄(8560) 哷(8660) 嘸(8760) 坄(8860) 塦(8960) 奰(8A60) 媊(8B60) 宍(8C60) 峘(8D60) 巂(8E60) 廯(8F60) 恅(9060) 慲(9160) 抈(9260) 揱(9360) 擿(9460) 昤(9560) 朻(9660) 梎(9760) 榒(9860) 檂(9960) 歚(9A60) 沗(9B60) 渀(9C60) 漙(9D60) 瀈(9E60) 焋(9F60) 燻(A060) ╜ (A860) ー(A960) 猔(AA60) 玚(AB60) 琡(AC60) 璥(AD60) 甡(AE60) 痐(AF60) 癭(B060) 盽(B160) 瞏(B260) 砢(B360) 碻(B460) 礰(B560) 禶(B660) 穈(B760) 竊(B860) 筦(B960) 篳(BA60) 籤(BB60) 糮(BC60) 絗(BD60) 綻(BE60) 縛(BF60) 繾(C060) 羆(C160) 耟(C260) 胉(C360) 腵(C460) 臽(C560) 芵(C660) 莁(C760) 萡(C860) 蒨(C960) 蔪(CA60) 薫(CB60) 蘞(CC60) 蚡(CD60) 蝋(CE60) 蟕(CF60) 衊(D060) 裛(D160) 襚(D260) 觍(D360) 訿(D460) 誤(D560) 謄(D660) 譧(D760) 豟(D860) 賎(D960) 赻(DA60) 踐(DB60) 躟(DC60) 輅(DD60) 轥(DE60) 違(DF60) 郹(E060) 醏(E160) 鈆(E260) 鉦(E360) 鋊(E460) 錪(E560) 鎌(E660) 鏯(E760) 鑐(E860) 閌(E960) 阘(EA60) 隸(EB60) 靈(EC60) 韅(ED60) 頯(EE60) 颼(EF60) 餪(F060) 馺(F160) 騚(F260) 骮(F360) 鬬(F460) 鮜(F560) 鯼(F660) 鱜(F760) 鴃(F860) 鵣(F960) 鷃(FA60) 鸴(FB60) 黗(FC60) 齚(FD60) 
               [{](7B) 亄(817B) 倇(827B) 儃(837B) 剓(847B) 厈(857B) 唟(867B) 噞(877B) 坽(887B) 墈(897B) 妠(8A7B) 媨(8B7B) 寋(8C7B) 峽(8D7B) 巤(8E7B) 弡(8F7B) 恵(907B) 憑(917B) 抺(927B) 搟(937B) 攞(947B) 晎(957B) 杮(967B) 梴(977B) 榹(987B) 檣(997B) 歿(9A7B) 泏(9B7B) 渰(9C7B) 漿(9D7B) 瀧(9E7B) 焮(9F7B) 爗(A07B) ▄ (A87B) ﹞(A97B) 獅(AA7B) 珄(AB7B) 瑊(AC7B) 瓄(AD7B) 畕(AE7B) 瘂(AF7B) 皗(B07B) 眥(B17B) 瞷(B27B) 硔(B37B) 磠(B47B) 祘(B57B) 秢(B67B) 穥(B77B) 竰(B87B) 箋(B97B) 簕(BA7B) 粄(BB7B) 納(BC7B) 絳(BD7B) 緖(BE7B) 縶(BF7B) 纚(C07B) 羬(C17B) 聓(C27B) 脅(C37B) 膡(C47B) 舺(C57B) 苳(C67B) 莧(C77B) 葅(C87B) 蓒(C97B) 蕒(CA7B) 藍(CB7B) 蘽(CC7B) 蛖(CD7B) 蝱(CE7B) 蟵(CF7B) 衶(D07B) 褅(D17B) 襸(D27B) 觷(D37B) 詛(D47B) 調(D57B) 謠(D67B) 讃(D77B) 貃(D87B) 賩(D97B) 趝(DA7B) 踸(DB7B) 躿(DC7B) 輠(DD7B) 辿(DE7B) 遻(DF7B) 鄘(E07B) 醷(E17B) 鈡(E27B) 銂(E37B) 鋥(E47B) 鍆(E57B) 鎨(E67B) 鐊(E77B) 鑬(E87B) 閧(E97B) 陒(EA7B) 雥(EB7B) 靮(EC7B) 韠(ED7B) 顊(EE7B) 飡(EF7B) 饆(F07B) 駕(F17B) 騵(F27B) 髙(F37B) 魗(F47B) 鮷(F57B) 鰗(F67B) 鱷(F77B) 鴞(F87B) 鵾(F97B) 鷞(FA7B) 鹻(FB7B) 鼂(FC7B) 齵(FD7B) 
               [|](7C) 亅(817C) 倈(827C) 億(837C) 剕(847C) 厊(857C) 唡(867C) 噟(877C) 坾(887C) 墊(897C) 妡(8A7C) 媩(8B7C) 寍(8C7C) 峾(8D7C) 巪(8E7C) 弢(8F7C) 恷(907C) 憒(917C) 抾(927C) 搢(937C) 攟(947C) 晐(957C) 東(967C) 梶(977C) 榺(987C) 檤(997C) 殀(9A7C) 泑(9B7C) 渱(9C7C) 潀(9D7C) 瀨(9E7C) 焲(9F7C) 爘(A07C) ▅ (A87C) ﹟(A97C) 獆(AA7C) 珅(AB7C) 瑋(AC7C) 瓅(AD7C) 畖(AE7C) 瘄(AF7C) 皘(B07C) 眧(B17C) 瞸(B27C) 硘(B37C) 磡(B47C) 祙(B57C) 秥(B67C) 穦(B77C) 竱(B87C) 箌(B97C) 簗(BA7C) 粅(BB7C) 紎(BC7C) 絴(BD7C) 緗(BE7C) 縷(BF7C) 纜(C07C) 羭(C17C) 聕(C27C) 脇(C37C) 膢(C47C) 舼(C57C) 苵(C67C) 莬(C77C) 葇(C87C) 蓔(C97C) 蕓(CA7C) 藎(CB7C) 蘾(CC7C) 蛗(CD7C) 蝲(CE7C) 蟶(CF7C) 衸(D07C) 褆(D17C) 襹(D27C) 觸(D37C) 詜(D47C) 諀(D57C) 謡(D67C) 讄(D77C) 貄(D87C) 質(D97C) 趞(DA7C) 踻(DB7C) 軀(DC7C) 輡(DD7C) 迀(DE7C) 遼(DF7C) 鄚(E07C) 醸(E17C) 鈢(E27C) 銃(E37C) 鋦(E47C) 鍇(E57C) 鎩(E67C) 鐋(E77C) 鑭(E87C) 閨(E97C) 陓(EA7C) 雦(EB7C) 靯(EC7C) 韡(ED7C) 顋(EE7C) 飢(EF7C) 饇(F07C) 駖(F17C) 騶(F27C) 髚(F37C) 魘(F47C) 鮸(F57C) 鰘(F67C) 鱸(F77C) 鴟(F87C) 鵿(F97C) 鷟(FA7C) 鹼(FB7C) 鼃(FC7C) 齶(FD7C) 
               [}](7D) 亇(817D) 倉(827D) 儅(837D) 剗(847D) 厎(857D) 唥(867D) 噠(877D) 坿(887D) 墋(897D) 妢(8A7D) 媫(8B7D) 寎(8C7D) 峿(8D7D) 巬(8E7D) 弣(8F7D) 恾(907D) 憓(917D) 拀(927D) 搣(937D) 攠(947D) 晑(957D) 杴(967D) 梷(977D) 榼(987D) 檥(997D) 殅(9A7D) 泒(9B7D) 渳(9C7D) 潁(9D7D) 瀩(9E7D) 焳(9F7D) 爙(A07D) ▆ (A87D) ﹠(A97D) 獇(AA7D) 珆(AB7D) 瑌(AC7D) 瓆(AD7D) 畗(AE7D) 瘆(AF7D) 皚(B07D) 眪(B17D) 瞹(B27D) 硙(B37D) 磢(B47D) 祡(B57D) 秨(B67D) 穧(B77D) 竲(B87D) 箎(B97D) 簘(BA7D) 粆(BB7D) 紏(BC7D) 絵(BD7D) 緘(BE7D) 縸(BF7D) 纝(C07D) 羮(C17D) 聖(C27D) 脈(C37D) 膤(C47D) 舽(C57D) 苶(C67D) 莭(C77D) 葈(C87D) 蓕(C97D) 蕔(CA7D) 藑(CB7D) 蘿(CC7D) 蛚(CD7D) 蝳(CE7D) 蟷(CF7D) 衹(D07D) 複(D17D) 襺(D27D) 觹(D37D) 詝(D47D) 諁(D57D) 謢(D67D) 讅(D77D) 貆(D87D) 賫(D97D) 趠(DA7D) 踼(DB7D) 軁(DC7D) 輢(DD7D) 迃(DE7D) 遾(DF7D) 鄛(E07D) 醹(E17D) 鈣(E27D) 銄(E37D) 鋧(E47D) 鍈(E57D) 鎪(E67D) 鐌(E77D) 鑮(E87D) 閩(E97D) 陖(EA7D) 雧(EB7D) 靰(EC7D) 韢(ED7D) 題(EE7D) 飣(EF7D) 饈(F07D) 駗(F17D) 騷(F27D) 髛(F37D) 魙(F47D) 鮹(F57D) 鰙(F67D) 鱹(F77D) 鴠(F87D) 鶀(F97D) 鷠(FA7D) 鹽(FB7D) 鼄(FC7D) 齷(FD7D) 
  ------------------------------------------------------------------------------
  sjis (Shift_JIS-like encodings)
             1st       2nd
             81..9F    00..FF
             E0..FC    00..FF
             80..FF
             00..7F
             https://en.wikipedia.org/wiki/Shift_JIS
             * needs multibyte anchoring
             * unsafe US-ASCII casefolding of 2nd octet
             * needs escaping meta char of 2nd octet
             * and DAMEMOJI samples, here
               [@](40) 　(8140) ァ(8340) А(8440) 院(8940) 魁(8A40) 機(8B40) 掘(8C40) 后(8D40) 察(8E40) 宗(8F40) 拭(9040) 繊(9140) 叩(9240) 邸(9340) 如(9440) 鼻(9540) 法(9640) 諭(9740) 蓮(9840) 僉(9940) 咫(9A40) 奸(9B40) 廖(9C40) 戞(9D40) 曄(9E40) 檗(9F40) 漾(E040) 瓠(E140) 磧(E240) 紂(E340) 隋(E440) 蕁(E540) 襦(E640) 蹇(E740) 錙(E840) 顱(E940) 鵝(EA40) 
               [[](5B) ー(815B) ゼ(835B) Ъ(845B) 閏(895B) 骸(8A5B) 擬(8B5B) 啓(8C5B) 梗(8D5B) 纂(8E5B) 充(8F5B) 深(905B) 措(915B) 端(925B) 甜(935B) 納(945B) 票(955B) 房(965B) 夕(975B) 麓(985B) 兌(995B) 喙(9A5B) 媼(9B5B) 彈(9C5B) 拏(9D5B) 杣(9E5B) 歇(9F5B) 濕(E05B) 畆(E15B) 禺(E25B) 綣(E35B) 膽(E45B) 藜(E55B) 觴(E65B) 躰(E75B) 鐚(E85B) 饉(E95B) 鷦(EA5B) 
               [\](5C) ―(815C) ソ(835C) Ы(845C) 噂(895C) 浬(8A5C) 欺(8B5C) 圭(8C5C) 構(8D5C) 蚕(8E5C) 十(8F5C) 申(905C) 曾(915C) 箪(925C) 貼(935C) 能(945C) 表(955C) 暴(965C) 予(975C) 禄(985C) 兔(995C) 喀(9A5C) 媾(9B5C) 彌(9C5C) 拿(9D5C) 杤(9E5C) 歃(9F5C) 濬(E05C) 畚(E15C) 秉(E25C) 綵(E35C) 臀(E45C) 藹(E55C) 觸(E65C) 軆(E75C) 鐔(E85C) 饅(E95C) 鷭(EA5C) 
               []](5D) ‐(815D) ゾ(835D) Ь(845D) 云(895D) 馨(8A5D) 犠(8B5D) 珪(8C5D) 江(8D5D) 讃(8E5D) 従(8F5D) 疹(905D) 曽(915D) 綻(925D) 転(935D) 脳(945D) 評(955D) 望(965D) 余(975D) 肋(985D) 兢(995D) 咯(9A5D) 嫋(9B5D) 彎(9C5D) 拆(9D5D) 枉(9E5D) 歉(9F5D) 濔(E05D) 畩(E15D) 秕(E25D) 緇(E35D) 臂(E45D) 蘊(E55D) 訃(E65D) 躱(E75D) 鐓(E85D) 饐(E95D) 鷯(EA5D) 
               [^](5E) ／(815E) タ(835E) Э(845E) 運(895E) 蛙(8A5E) 疑(8B5E) 型(8C5E) 洪(8D5E) 賛(8E5E) 戎(8F5E) 真(905E) 楚(915E) 耽(925E) 顛(935E) 膿(945E) 豹(955E) 某(965E) 与(975E) 録(985E) 竸(995E) 喊(9A5E) 嫂(9B5E) 弯(9C5E) 擔(9D5E) 杰(9E5E) 歐(9F5E) 濘(E05E) 畤(E15E) 秧(E25E) 綽(E35E) 膺(E45E) 蘓(E55E) 訖(E65E) 躾(E75E) 鐃(E85E) 饋(E95E) 鷽(EA5E) 
               [`](60) 〜(8160) Ａ(8260) チ(8360) Я(8460) 荏(8960) 柿(8A60) 義(8B60) 形(8C60) 港(8D60) 餐(8E60) 汁(8F60) 秦(9060) 疏(9160) 蛋(9260) 伝(9360) 覗(9460) 描(9560) 冒(9660) 輿(9760) 倭(9860) 兪(9960) 啻(9A60) 嫣(9B60) 彖(9C60) 拜(9D60) 杼(9E60) 歔(9F60) 濮(E060) 畫(E160) 秡(E260) 總(E360) 臍(E460) 藾(E560) 訌(E660) 軈(E760) 鐐(E860) 饒(E960) 鸛(EA60) 
               [{](7B) ＋(817B) ボ(837B) к(847B) 閲(897B) 顎(8A7B) 宮(8B7B) 鶏(8C7B) 砿(8D7B) 施(8E7B) 旬(8F7B) 須(907B) 捜(917B) 畜(927B) 怒(937B) 倍(947B) 府(957B) 本(967B) 養(977B) 几(997B) 嘴(9A7B) 學(9B7B) 悳(9C7B) 掉(9D7B) 桀(9E7B) 毬(9F7B) 炮(E07B) 痣(E17B) 窖(E27B) 縵(E37B) 艝(E47B) 蛔(E57B) 諚(E67B) 轆(E77B) 閔(E87B) 驅(E97B) 黠(EA7B) 
               [|](7C) − (817C) ポ(837C) л(847C) 榎(897C) 掛(8A7C) 弓(8B7C) 芸(8C7C) 鋼(8D7C) 旨(8E7C) 楯(8F7C) 酢(907C) 掃(917C) 竹(927C) 倒(937C) 培(947C) 怖(957C) 翻(967C) 慾(977C) 處(997C) 嘶(9A7C) 斈(9B7C) 忿(9C7C) 掟(9D7C) 桍(9E7C) 毫(9F7C) 烟(E07C) 痞(E17C) 窩(E27C) 縹(E37C) 艚(E47C) 蛞(E57C) 諫(E67C) 轎(E77C) 閖(E87C) 驂(E97C) 黥(EA7C) 
               [}](7D) ±(817D) マ(837D) м(847D) 厭(897D) 笠(8A7D) 急(8B7D) 迎(8C7D) 閤(8D7D) 枝(8E7D) 殉(8F7D) 図(907D) 挿(917D) 筑(927D) 党(937D) 媒(947D) 扶(957D) 凡(967D) 抑(977D) 凩(997D) 嘲(9A7D) 孺(9B7D) 怡(9C7D) 掵(9D7D) 栲(9E7D) 毳(9F7D) 烋(E07D) 痾(E17D) 竈(E27D) 繃(E37D) 艟(E47D) 蛩(E57D) 諳(E67D) 轗(E77D) 閘(E87D) 驀(E97D) 黨(EA7D) 
  ------------------------------------------------------------------------------
  uhc (UHC)
             1st       2nd
             81..FE    00..FF
             00..7F
             https://en.wikipedia.org/wiki/Unified_Hangul_Code
             * needs multibyte anchoring
             * needs no escaping meta char of 2nd octet
             * unsafe US-ASCII casefolding of 2nd octet
  ------------------------------------------------------------------------------
  utf8 (UTF-8)
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
  ------------------------------------------------------------------------------
  wtf8 (WTF-8)
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
  ------------------------------------------------------------------------------

=head1 MBCS subroutines provided by this software

This software provides traditional feature "as was." The new MBCS features
are provided by subroutines with new names. If you like utf8 pragma, mb::*
subroutines will help you. On other hand, If you love JPerl, those
subroutines will not help you very much. Traditional functions of Perl are
useful still now in octet-oriented semantics.

  elder <--                            age                              --> younger
  ---------------------------------------------------------------------------------
  bare Perl4         JPerl4             use utf8;          mb.pm
  bare Perl5         JPerl5             pragma             modulino
  ---------------------------------------------------------------------------------
  chop               ---                ---                chop
  chr                chr                bytes::chr         chr
  getc               getc               ---                getc
  index              ---                bytes::index       index
  lc                 ---                ---                CORE::lc
  lcfirst            ---                ---                CORE::lcfirst
  length             length             bytes::length      length
  ord                ord                bytes::ord         ord
  reverse            reverse            ---                reverse
  rindex             ---                bytes::rindex      rindex
  substr             substr             bytes::substr      substr
  uc                 ---                ---                CORE::uc
  ucfirst            ---                ---                CORE::ucfirst
  ---                chop               chop               mb::chop
  ---                ---                chr                mb::chr
  ---                ---                getc               mb::getc
  ---                index              ---                mb::index_byte
  ---                ---                index              mb::index
  ---                lc                 ---                lc (by internal mb::lc)
  ---                lcfirst            ---                lcfirst (by internal mb::lcfirst)
  ---                ---                length             mb::length
  ---                ---                ord                mb::ord
  ---                ---                reverse            mb::reverse
  ---                rindex             ---                mb::rindex_byte
  ---                ---                rindex             mb::rindex
  ---                ---                substr             mb::substr
  ---                uc                 ---                uc (by internal mb::uc)
  ---                ucfirst            ---                ucfirst (by internal mb::ucfirst)
  ---                ---                lc                 ---
  ---                ---                lcfirst            ---
  ---                ---                uc                 ---
  ---                ---                ucfirst            ---
  ---------------------------------------------------------------------------------
  do 'file'          ---                ---                do 'file'
  eval 'string'      ---                ---                eval 'string'
  require 'file'     ---                ---                require 'file'
  use Module         ---                ---                use Module
  no Module          ---                ---                no Module
  ---                do 'file'          do 'file'          mb::do 'file'
  ---                eval 'string'      eval 'string'      mb::eval 'string'
  ---                require 'file'     require 'file'     mb::require 'file'
  ---                use Module         use Module         mb::use Module
  ---                no Module          no Module          mb::no Module
  $^X                ---                ---                $^X
  ---                $^X                $^X                $mb::PERL
  $0                 $0                 $0                 $mb::ORIG_PROGRAM_NAME
  ---                ---                ---                $0
  ---------------------------------------------------------------------------------

DOS-like glob() as MBCS subroutine

  -----------------------------------------------------------------
  MBCS semantics          broken function, not so useful
  -----------------------------------------------------------------
  mb::dosglob             glob, and <globbing*>
  -----------------------------------------------------------------

but everybody loves split(/\n/,`dir /b *.* 2>NUL`) since Perl4

index brothers

  ------------------------------------------------------------------------------------------
  functions or subs       works as        returns as      considered
  ------------------------------------------------------------------------------------------
  index                   octet           octet           useful, bare Perl like
  rindex                  octet           octet           useful, bare Perl like
  mb::index               codepoint       codepoint       not so useful, utf8 pragma like
  mb::rindex              codepoint       codepoint       not so useful, utf8 pragma like
  mb::index_byte          codepoint       octet           useful, JPerl like
  mb::rindex_byte         codepoint       octet           useful, JPerl like
  ------------------------------------------------------------------------------------------

Sometimes "compatibility" means "compromise." In that case, "best compatibility" means
"most useful compromise." That's what mb::index_byte() and mb::rindex_byte() are.
But sorry for the long name.

=head1 MBCS special variables provided by this software

This software provides the following two special variables for convenience

=over 2

=item * $mb::PERL

  system(qq{ $^X perl_script.pl });              # had been write this...
  
                                                 # on mb.pm modulino
  system(qq{ $^X       SBCS_perl_script.pl });   # for SBCS script
  system(qq{ $mb::PERL MBCS_perl_script.pl });   # for MBCS script

=item * $mb::ORIG_PROGRAM_NAME

  if ($0 =~ /-x64\.pl\z/) { ... }                # had been write this...
  
                                                 # on mb.pm modulino
  if ($0 =~ /-x64\.pl\z/) { ... }                # means program name translated by mb.pm modulino (are you right?)
  if ($mb::ORIG_PROGRAM_NAME =~ /-x64\.pl\z/) { ... }  # means original program name not translated by mb.pm modulino

=back

=head1 Porting from script in bare Perl4, and bare Perl5

=head2 If you want to write US-ASCII scripts from now on, or port existing US-ASCII scripts to mb.pm

Write scripts the usual way.
Running an US-ASCII script using mb.pm allows you to treat multibyte code points as I/O data.

=head2 On other hand, if you want to write octet-oriented scripts from now on, or port existing octet-oriented scripts to mb.pm

There are only a few places that need to be rewritten.

  -----------------------------------------------------------------
  original script in        script with
  Perl4, Perl5              mb.pm modulino
  -----------------------------------------------------------------
  chop                      chop
  chr                       chr
  do 'file'                 do 'file'
  eval 'string'             eval 'string'
  getc                      getc
  index                     index
  lc                        CORE::lc
  lcfirst                   CORE::lcfirst
  length                    length
  no Module                 no Module
  no Module qw(ARGUMENTS)   no Module qw(ARGUMENTS)
  ord                       ord
  require 'file'            require 'file'
  reverse                   reverse
  rindex                    rindex
  substr                    substr
  uc                        CORE::uc
  ucfirst                   CORE::ucfirst
  use Module                use Module
  use Module qw(ARGUMENTS)  use Module qw(ARGUMENTS)
  use Module ()             use Module ()
  qq{\Lfoo\E}               qq{@{[CORE::lc("foo")]}}
  qq{\lfoo\E}               qq{@{[CORE::lcfirst("foo")]}}
  qq{\Ufoo\E}               qq{@{[CORE::uc("foo")]}}
  qq{\ufoo\E}               qq{@{[CORE::ucfirst("foo")]}}
  -----------------------------------------------------------------

=head1 Porting from script in JPerl4, and JPerl5

=head2 If you want to write MBCS scripts from now on

If you want to make it multibyte, rewrite the Perl built-in function to the subroutine of the same name in the mb :: * package.

=head2 If you want to port existing JPerl scripts to mb.pm

There are only a few places that need to be rewritten.

  -----------------------------------------------------------------
  original script in        script with
  JPerl4, JPerl5            mb.pm modulino
  -----------------------------------------------------------------
  chop                      mb::chop
  do 'file'                 mb::do 'file'
  eval 'string'             mb::eval 'string'
  index                     mb::index_byte
  lc                        mb::lc (also lc)
  lcfirst                   mb::lcfirst (also lcfirst)
  no Module                 mb::no Module
  no Module qw(ARGUMENTS)   mb::no Module qw(ARGUMENTS)
  require 'file'            mb::require 'file'
  rindex                    mb::rindex_byte
  uc                        mb::uc (also uc)
  ucfirst                   mb::ucfirst (also ucfirst)
  use Module                mb::use Module
  use Module qw(ARGUMENTS)  mb::use Module qw(ARGUMENTS)
  use Module ()             mb::use Module ()
  -----------------------------------------------------------------

=head1 Porting from script with utf8 pragma

If you want to port existing scripts that has utf8 pragma to mb.pm
Like traditional style, Perl's built-in functions without package names provide octet-oriented functionality.
When you need multibyte functionally, you need to use subroutines in the "mb" package, on every time.

  -----------------------------------------------------------------
  original script with      script with
  utf8 pragma               mb.pm modulino
  -----------------------------------------------------------------
  chop                      mb::chop
  chr                       mb::chr
  do 'file'                 mb::do 'file'
  eval 'string'             mb::eval 'string'
  getc                      mb::getc
  index                     mb::index
  lc                        ---
  lcfirst                   ---
  length                    mb::length
  no Module                 mb::no Module
  no Module qw(ARGUMENTS)   mb::no Module qw(ARGUMENTS)
  ord                       mb::ord
  require 'file'            mb::require 'file'
  reverse                   mb::reverse
  rindex                    mb::rindex
  substr                    mb::substr
  uc                        ---
  ucfirst                   ---
  use Module                mb::use Module
  use Module qw(ARGUMENTS)  mb::use Module qw(ARGUMENTS)
  use Module ()             mb::use Module ()
  -----------------------------------------------------------------

=head1 What are DAMEMOJI?

In single quote, DAMEMOJI are double-byte characters that include the
following metacharacters ('', q{}, <<'END', qw{}, m'', s''', split(''),
split(m''), and qr'')

  ------------------------------------------------------------------
  hex   character as US-ASCII
  ------------------------------------------------------------------
  5C    [\]    backslashed escapes
  ------------------------------------------------------------------

In double quote, DAMEMOJI are double-byte characters that include the
following metacharacters ("", qq{}, <<END, <<"END", ``, qx{}, <<`END`, //,
m//, ??, s///, split(//), split(m//), and qr//)

  ------------------------------------------------------------------
  hex   character as US-ASCII
  ------------------------------------------------------------------
  21    [!]
  22    ["]
  23    [#]    regexp comment
  24    [$]    sigil of scalar variable
  25    [%]
  26    [&]
  27    [']
  28    [(]    regexp group and capture
  29    [)]    regexp group and capture
  2A    [*]    regexp matches zero or more times
  2B    [+]    regexp matches one or more times
  2C    [,]
  2D    [-]
  2E    [.]    regexp matches any octet
  2F    [/]
  3A    [:]
  3B    [;]
  3C    [<]
  3D    [=]
  3E    [>]
  3F    [?]    regexp matches zero or one times
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

=head1 How to escape 2nd octet of DAMEMOJI

$ perl mb.pm script.pl

in script "script.pl",

    -----------------------------------------
    encoding     DAMEMOJI      hex dump
    -----------------------------------------
    big5         "世"          [A5 40]
                 "加"          [A5 5B]
                 "功"          [A5 5C]
                 "包"          [A5 5D]
                 "匆"          [A5 5E]
                 "匝"          [A5 60]
                 "叻"          [A5 7B]
                 "四"          [A5 7C]
                 "囚"          [A5 7D]
    -----------------------------------------
    big5hkscs    "蕋"          [8F 40]
                 "团"          [89 5B]
                 "声"          [89 5C]
                 "处"          [89 5D]
                 "备"          [89 5E]
                 "头"          [89 60]
                 "询"          [89 7B]
                 "车"          [89 7C]
                 "轧"          [89 7D]
    -----------------------------------------
    gb18030      "丂"          [81 40]
                 "乕"          [81 5B]
                 "乗"          [81 5C]
                 "乚"          [81 5D]
                 "乛"          [81 5E]
                 "乣"          [81 60]
                 "亄"          [81 7B]
                 "亅"          [81 7C]
                 "亇"          [81 7D]
    -----------------------------------------
    gbk          "丂"          [81 40]
                 "乕"          [81 5B]
                 "乗"          [81 5C]
                 "乚"          [81 5D]
                 "乛"          [81 5E]
                 "乣"          [81 60]
                 "亄"          [81 7B]
                 "亅"          [81 7C]
                 "亇"          [81 7D]
    -----------------------------------------
    sjis         "ァ"          [83 40]
                 "ゼ"          [83 5B]
                 "ソ"          [83 5C]
                 "ゾ"          [83 5D]
                 "タ"          [83 5E]
                 "チ"          [83 60]
                 "ボ"          [83 7B]
                 "ポ"          [83 7C]
                 "マ"          [83 7D]
    -----------------------------------------

mb.pm modulino escapes literal DAMEMOJI in your script and save as new script

in script "script.oo.pl",

    -----------------------------------------
    encoding     not DAMEMOJI  hex dump
    -----------------------------------------
    big5         "功@"         [A5 [5C] 40]
                 "功["         [A5 [5C] 5B]
                 "功\"         [A5 [5C] 5C]
                 "功]"         [A5 [5C] 5D]
                 "功^"         [A5 [5C] 5E]
                 "功`"         [A5 [5C] 60]
                 "功{"         [A5 [5C] 7B]
                 "功|"         [A5 [5C] 7C]
                 "功}"         [A5 [5C] 7D]
    -----------------------------------------
    big5hkscs    "蕚@"         [8F [5C] 40]
                 "声["         [89 [5C] 5B]
                 "声\"         [89 [5C] 5C]
                 "声]"         [89 [5C] 5D]
                 "声^"         [89 [5C] 5E]
                 "声`"         [89 [5C] 60]
                 "声{"         [89 [5C] 7B]
                 "声|"         [89 [5C] 7C]
                 "声}"         [89 [5C] 7D]
    -----------------------------------------
    gb18030      "乗@"         [81 [5C] 40]
                 "乗["         [81 [5C] 5B]
                 "乗\"         [81 [5C] 5C]
                 "乗]"         [81 [5C] 5D]
                 "乗^"         [81 [5C] 5E]
                 "乗`"         [81 [5C] 60]
                 "乗{"         [81 [5C] 7B]
                 "乗|"         [81 [5C] 7C]
                 "乗}"         [81 [5C] 7D]
    -----------------------------------------
    gbk          "乗@"         [81 [5C] 40]
                 "乗["         [81 [5C] 5B]
                 "乗\"         [81 [5C] 5C]
                 "乗]"         [81 [5C] 5D]
                 "乗^"         [81 [5C] 5E]
                 "乗`"         [81 [5C] 60]
                 "乗{"         [81 [5C] 7B]
                 "乗|"         [81 [5C] 7C]
                 "乗}"         [81 [5C] 7D]
    -----------------------------------------
    sjis         "ソ@"         [83 [5C] 40]
                 "ソ["         [83 [5C] 5B]
                 "ソ\"         [83 [5C] 5C]
                 "ソ]"         [83 [5C] 5D]
                 "ソ^"         [83 [5C] 5E]
                 "ソ`"         [83 [5C] 60]
                 "ソ{"         [83 [5C] 7B]
                 "ソ|"         [83 [5C] 7C]
                 "ソ}"         [83 [5C] 7D]
    -----------------------------------------

then mb.pm executes "script.oo.pl"

in perl's memory,

    -----------------------------------------
    encoding     memory        hex dump
    -----------------------------------------
    big5         "世"          [A5] [40]
                 "加"          [A5] [5B]
                 "功"          [A5] [5C]
                 "包"          [A5] [5D]
                 "匆"          [A5] [5E]
                 "匝"          [A5] [60]
                 "叻"          [A5] [7B]
                 "四"          [A5] [7C]
                 "囚"          [A5] [7D]
    -----------------------------------------
    big5hkscs    "蕋"          [8F] [40]
                 "团"          [89] [5B]
                 "声"          [89] [5C]
                 "处"          [89] [5D]
                 "备"          [89] [5E]
                 "头"          [89] [60]
                 "询"          [89] [7B]
                 "车"          [89] [7C]
                 "轧"          [89] [7D]
    -----------------------------------------
    gb18030      "丂"          [81] [40]
                 "乕"          [81] [5B]
                 "乗"          [81] [5C]
                 "乚"          [81] [5D]
                 "乛"          [81] [5E]
                 "乣"          [81] [60]
                 "亄"          [81] [7B]
                 "亅"          [81] [7C]
                 "亇"          [81] [7D]
    -----------------------------------------
    gbk          "丂"          [81] [40]
                 "乕"          [81] [5B]
                 "乗"          [81] [5C]
                 "乚"          [81] [5D]
                 "乛"          [81] [5E]
                 "乣"          [81] [60]
                 "亄"          [81] [7B]
                 "亅"          [81] [7C]
                 "亇"          [81] [7D]
    -----------------------------------------
    sjis         "ァ"          [83] [40]
                 "ゼ"          [83] [5B]
                 "ソ"          [83] [5C]
                 "ゾ"          [83] [5D]
                 "タ"          [83] [5E]
                 "チ"          [83] [60]
                 "ボ"          [83] [7B]
                 "ポ"          [83] [7C]
                 "マ"          [83] [7D]
    -----------------------------------------

=head1 MBCS character casing

lc("A") makes halfwidth-"a", however lc("乙") makes "乙" not "兀", moreover lc("Ａ")
makes "Ａ" not fullwidth-"ａ".

    ----------------------------------------------------------------------------------------------
    encoding    script                         bare Perl4, bare Perl5     mb.pm modulino
                                               makes MOJIBAKE             makes no MOJIBAKE
    ----------------------------------------------------------------------------------------------
    big5        lc("A乙Ａ") [41][A441][A2CF]   "a兀Ａ" [61][A461][A2CF]   "a乙Ａ" [61][A441][A2CF]
    big5hkscs   lc("A淾Ａ") [41][8C41][A2CF]   "a蘏Ａ" [61][8C61][A2CF]   "a淾Ａ" [61][8C41][A2CF]
    gb18030     lc("A華Ａ") [41][C841][A3C1]   "a萢Ａ" [61][C861][A3C1]   "a華Ａ" [61][C841][A3C1]
    gbk         lc("A華Ａ") [41][C841][A3C1]   "a萢Ａ" [61][C861][A3C1]   "a華Ａ" [61][C841][A3C1]
    sjis        lc("AアＡ") [41][8341][8261]   "aヂＡ" [61][8361][8261]   "aアＡ" [61][8341][8261]
    uhc         lc("A갂Ａ") [41][8141][A3C1]   "a갵Ａ" [61][8161][A3C1]   "a갂Ａ" [61][8141][A3C1]
    ----------------------------------------------------------------------------------------------
    big5        uc("a兀ａ") [61][A461][A2E9]   "A乙ａ" [41][A441][A2E9]   "A兀ａ" [41][A461][A2E9]
    big5hkscs   uc("a蘏ａ") [61][8C61][A2E9]   "A淾ａ" [41][8C41][A2E9]   "A蘏ａ" [41][8C61][A2E9]
    gb18030     uc("a萢ａ") [61][C861][A3E1]   "A華ａ" [41][C841][A3E1]   "A萢ａ" [41][C861][A3E1]
    gbk         uc("a萢ａ") [61][C861][A3E1]   "A華ａ" [41][C841][A3E1]   "A萢ａ" [41][C861][A3E1]
    sjis        uc("aヂａ") [61][8361][8281]   "Aアａ" [41][8341][8281]   "Aヂａ" [41][8361][8281]
    uhc         uc("a갵ａ") [61][8161][A3E1]   "A갂ａ" [41][8141][A3E1]   "A갵ａ" [41][8161][A3E1]
    ----------------------------------------------------------------------------------------------

=head1 What transpiles to what by this software?

This software automatically transpiles MBCS literal strings in scripts to
octet-oriented strings(OO-quotee)

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  in your script                             script transpiled by this software
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  do 'file'                                  do 'file'
  do { block }                               do { block }
  mb::do 'file'                              mb::do 'file'
  mb::do { block }                           do { block }
  eval 'string'                              eval 'string'
  eval { block }                             eval { block }
  mb::eval 'string'                          mb::eval 'string'
  mb::eval { block }                         eval { block }
  require 123                                require 123
  require 'file'                             require 'file'
  mb::require 123                            mb::require 123
  mb::require 'file'                         mb::require 'file'
  use Module 5.005;                          use Module 5.005;
  use Module 5.005 qw(A B C);                use Module 5.005 qw(A B C);
  use Module 5.005 ();                       use Module 5.005 ();
  use Module;                                use Module;
  use Module qw(A B C);                      use Module qw(A B C);
  use Module ();                             use Module ();
  mb::use Module 5.005;                      BEGIN { mb::require 'Module'; Module->VERSION(5.005); Module->import; };
  mb::use Module 5.005 qw(A B C);            BEGIN { mb::require 'Module'; Module->VERSION(5.005);  Module->import(qw(A B C)); };
  mb::use Module 5.005 ();                   BEGIN { mb::require 'Module'; Module->VERSION(5.005); };
  mb::use Module;                            BEGIN { mb::require 'Module'; Module->import; };
  mb::use Module qw(A B C);                  BEGIN { mb::require 'Module';  Module->import(qw(A B C)); };
  mb::use Module ();                         BEGIN { mb::require 'Module'; };
  no Module 5.005;                           no Module 5.005;
  no Module 5.005 qw(A B C);                 no Module 5.005 qw(A B C);
  no Module 5.005 ();                        no Module 5.005 ();
  no Module;                                 no Module;
  no Module qw(A B C);                       no Module qw(A B C);
  no Module ();                              no Module ();
  mb::no Module 5.005;                       BEGIN { mb::require 'Module'; Module->VERSION(5.005); Module->unimport; };
  mb::no Module 5.005 qw(A B C);             BEGIN { mb::require 'Module'; Module->VERSION(5.005);  Module->unimport(qw(A B C)); };
  mb::no Module 5.005 ();                    BEGIN { mb::require 'Module'; Module->VERSION(5.005); };
  mb::no Module;                             BEGIN { mb::require 'Module'; Module->unimport; };
  mb::no Module qw(A B C);                   BEGIN { mb::require 'Module';  Module->unimport(qw(A B C)); };
  mb::no Module ();                          BEGIN { mb::require 'Module'; };
  chop                                       chop
  lc                                         mb::lc
  lcfirst                                    mb::lcfirst
  uc                                         mb::uc
  ucfirst                                    mb::ucfirst
  index                                      index
  rindex                                     rindex
  mb::getc()                                 mb::getc()
  mb::getc($fh)                              mb::getc($fh)
  mb::getc $fh                               mb::getc $fh
  mb::getc(FILE)                             mb::getc(\*FILE)
  mb::getc FILE                              mb::getc \*FILE
  mb::getc                                   mb::getc
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
  tr/MBCS-search/MBCS-replacement/cdsr       s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}ser
  tr/MBCS-search/MBCS-replacement/cds        s{[\x00-\xFF]+}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}se
  tr/MBCS-search/MBCS-replacement/ds         s{[\x00-\xFF]+}{mb::tr($&,q/OO-search/,q/OO-replacement/,'dsr')}se
  y/MBCS-search/MBCS-replacement/cdsr        s{[\x00-\xFF]*}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}ser
  y/MBCS-search/MBCS-replacement/cds         s{[\x00-\xFF]+}{mb::tr($&,q/OO-search/,q/OO-replacement/,'cdsr')}se
  y/MBCS-search/MBCS-replacement/ds          s{[\x00-\xFF]+}{mb::tr($&,q/OO-search/,q/OO-replacement/,'dsr')}se
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
  m#MBCS-quotee#cgimosx                      m{\G${mb::_anchor}@{[mb::_ignorecase(qr#OO-quotee#mosx)]}@{[mb::_m_passed()]}}cg
  m#MBCS-quotee#cgmosx                       m{\G${mb::_anchor}@{[qr#OO-quotee#mosx ]}@{[mb::_m_passed()]}}cg
  s#MBCS-regexp#MBCS-replacement#eegimosxr   s{(\G${mb::_anchor})@{[mb::_ignorecase(qr#OO-regexp#mosx)]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q#OO-replacement#}egr
  s#MBCS-regexp#MBCS-replacement#eegmosxr    s{(\G${mb::_anchor})@{[qr#OO-regexp#mosx ]}@{[mb::_s_passed()]}}{$1 . mb::eval mb::eval q#OO-replacement#}egr
  qr#MBCS-quotee#cgimosx                     qr{\G${mb::_anchor}@{[mb::_ignorecase(qr#OO-quotee#mosx)]}@{[mb::_m_passed()]}}cg
  qr#MBCS-quotee#cgmosx                      qr{\G${mb::_anchor}@{[qr#OO-quotee#mosx ]}@{[mb::_m_passed()]}}cg
  split m#^#                                 mb::_split qr{@{[qr#^#m ]}}
  split m#MBCS-quotee#cgimosx                mb::_split qr{@{[mb::_ignorecase(qr#OO-quotee#mosx)]}}cg
  split m#MBCS-quotee#cgmosx                 mb::_split qr{@{[qr#OO-quotee#mosx ]}}cg
  split qr#^#                                mb::_split qr{@{[qr#^#m ]}}
  split qr#MBCS-quotee#cgimosx               mb::_split qr{@{[mb::_ignorecase(qr#OO-quotee#mosx)]}}cg
  split qr#MBCS-quotee#cgmosx                mb::_split qr{@{[qr#OO-quotee#mosx ]}}cg
  /[abc 123]/xx                              m{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[abc123])]})/xx ]}@{[mb::_m_passed()]}}
  m/[abc 123]/xx                             m{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[abc123])]})/xx ]}@{[mb::_m_passed()]}}
  qr/[abc 123]/xx                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[abc123])]})/xx ]}@{[mb::_m_passed()]}}
  s/[abc 123]//xx                            s{(\G${mb::_anchor})@{[qr/(?:@{[mb::_cc(qq[abc123])]})/xx ]}@{[mb::_s_passed()]}}{$1 . qq //}e
  split /[abc 123]/xx                        mb::_split qr{@{[qr/(?:@{[mb::_cc(qq[abc123])]})/xxm ]}}
  split m/[abc 123]/xx                       mb::_split qr{@{[qr/(?:@{[mb::_cc(qq[abc123])]})/xxm ]}}
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
  "@{^CAPTURE}"                              "@{[mb::_CAPTURE()]}"
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
  v1.20.300.4000                             mb::chr(1).mb::chr(20).mb::chr(300).mb::chr(4000)
  1.20.300.4000                              mb::chr(1).mb::chr(20).mb::chr(300).mb::chr(4000)
  v1234=>''                                  v1234=>''
  v1234                                      mb::chr(1234)
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

The transpile-list below is primarily for Microsoft Windows, but it also
applies when run on other operating systems to ensure commonality. Even if
Perl 5.00503, you can stack file test operators, -r -w -f $file works as
-f $file && -w _ && -r _.

  -----------------------------------------------------------------------------
  in your script                             script transpiled by this software
  -----------------------------------------------------------------------------
  chdir                                      mb::_chdir
  opendir(DIR,'dir')                         mb::_opendir(\*DIR,'dir')
  opendir DIR,'dir'                          mb::_opendir \*DIR,'dir'
  opendir($dh,'dir')                         mb::_opendir($dh,'dir')
  opendir $dh,'dir'                          mb::_opendir $dh,'dir'
  opendir(my $dh,'dir')                      mb::_opendir(my $dh,'dir')
  opendir my $dh,'dir'                       mb::_opendir my $dh,'dir'
  unlink                                     mb::_unlink
  lstat()                                    mb::_lstat()
  lstat('a')                                 mb::_lstat('a')
  lstat("a")                                 mb::_lstat("a")
  lstat(`a`)                                 mb::_lstat(`a`)
  lstat(m/a/)                                mb::_lstat(m{\G${mb::_anchor}@{[qr/a/ ]}@{[mb::_m_passed()]}})
  lstat(q/a/)                                mb::_lstat(q/a/)
  lstat(qq/a/)                               mb::_lstat(qq/a/)
  lstat(qr/a/)                               mb::_lstat(qr{\G${mb::_anchor}@{[qr/a/ ]}@{[mb::_m_passed()]}})
  lstat(qw/a/)                               mb::_lstat(qw/a/)
  lstat(qx/a/)                               mb::_lstat(qx/a/)
  lstat(s/a/b/)                              mb::_lstat(s{(\G${mb::_anchor})@{[qr/a/ ]}@{[mb::_s_passed()]}}{$1 . qq /b/}e)
  lstat(tr/a/b/)                             mb::_lstat(s{(\G${mb::_anchor})((?=[a])@{mb::_dot})}{$1.mb::tr($2,q/a/,q/b/,'r')}sge)
  lstat(y/a/b/)                              mb::_lstat(s{(\G${mb::_anchor})((?=[a])@{mb::_dot})}{$1.mb::tr($2,q/a/,q/b/,'r')}sge)
  lstat($fh)                                 mb::_lstat($fh)
  lstat(FILE)                                mb::_lstat(\*FILE)
  lstat(_)                                   mb::_lstat(\*_)
  lstat $fh                                  mb::_lstat $fh
  lstat FILE                                 mb::_lstat \*FILE
  lstat _                                    mb::_lstat \*_
  lstat                                      mb::_lstat
  stat()                                     mb::_stat()
  stat('a')                                  mb::_stat('a')
  stat("a")                                  mb::_stat("a")
  stat(`a`)                                  mb::_stat(`a`)
  stat(m/a/)                                 mb::_stat(m{\G${mb::_anchor}@{[qr/a/ ]}@{[mb::_m_passed()]}})
  stat(q/a/)                                 mb::_stat(q/a/)
  stat(qq/a/)                                mb::_stat(qq/a/)
  stat(qr/a/)                                mb::_stat(qr{\G${mb::_anchor}@{[qr/a/ ]}@{[mb::_m_passed()]}})
  stat(qw/a/)                                mb::_stat(qw/a/)
  stat(qx/a/)                                mb::_stat(qx/a/)
  stat(s/a/b/)                               mb::_stat(s{(\G${mb::_anchor})@{[qr/a/ ]}@{[mb::_s_passed()]}}{$1 . qq /b/}e)
  stat(tr/a/b/)                              mb::_stat(s{(\G${mb::_anchor})((?=[a])@{mb::_dot})}{$1.mb::tr($2,q/a/,q/b/,'r')}sge)
  stat(y/a/b/)                               mb::_stat(s{(\G${mb::_anchor})((?=[a])@{mb::_dot})}{$1.mb::tr($2,q/a/,q/b/,'r')}sge)
  stat($fh)                                  mb::_stat($fh)
  stat(FILE)                                 mb::_stat(\*FILE)
  stat(_)                                    mb::_stat(\*_)
  stat $fh                                   mb::_stat $fh
  stat FILE                                  mb::_stat \*FILE
  stat _                                     mb::_stat \*_
  stat                                       mb::_stat
  -A $fh                                     mb::_filetest [qw( -A)],  $fh
  -A 'file'                                  mb::_filetest [qw( -A)],  'file'
  -A FILE                                    mb::_filetest [qw( -A )], \*FILE
  -A _                                       mb::_filetest [qw( -A )], \*_
  -A qq{file}                                mb::_filetest [qw( -A  )], qq{file}
  -B $fh                                     mb::_filetest [qw( -B)],  $fh
  -B 'file'                                  mb::_filetest [qw( -B)],  'file'
  -B FILE                                    mb::_filetest [qw( -B )], \*FILE
  -B _                                       mb::_filetest [qw( -B )], \*_
  -B qq{file}                                mb::_filetest [qw( -B  )], qq{file}
  -C $fh                                     mb::_filetest [qw( -C)],  $fh
  -C 'file'                                  mb::_filetest [qw( -C)],  'file'
  -C FILE                                    mb::_filetest [qw( -C )], \*FILE
  -C _                                       mb::_filetest [qw( -C )], \*_
  -C qq{file}                                mb::_filetest [qw( -C  )], qq{file}
  -M $fh                                     mb::_filetest [qw( -M)],  $fh
  -M 'file'                                  mb::_filetest [qw( -M)],  'file'
  -M FILE                                    mb::_filetest [qw( -M )], \*FILE
  -M _                                       mb::_filetest [qw( -M )], \*_
  -M qq{file}                                mb::_filetest [qw( -M  )], qq{file}
  -O $fh                                     mb::_filetest [qw( -O)],  $fh
  -O 'file'                                  mb::_filetest [qw( -O)],  'file'
  -O FILE                                    mb::_filetest [qw( -O )], \*FILE
  -O _                                       mb::_filetest [qw( -O )], \*_
  -O qq{file}                                mb::_filetest [qw( -O  )], qq{file}
  -R $fh                                     mb::_filetest [qw( -R)],  $fh
  -R 'file'                                  mb::_filetest [qw( -R)],  'file'
  -R FILE                                    mb::_filetest [qw( -R )], \*FILE
  -R _                                       mb::_filetest [qw( -R )], \*_
  -R qq{file}                                mb::_filetest [qw( -R  )], qq{file}
  -S $fh                                     mb::_filetest [qw( -S)],  $fh
  -S 'file'                                  mb::_filetest [qw( -S)],  'file'
  -S FILE                                    mb::_filetest [qw( -S )], \*FILE
  -S _                                       mb::_filetest [qw( -S )], \*_
  -S qq{file}                                mb::_filetest [qw( -S  )], qq{file}
  -T $fh                                     mb::_filetest [qw( -T)],  $fh
  -T 'file'                                  mb::_filetest [qw( -T)],  'file'
  -T FILE                                    mb::_filetest [qw( -T )], \*FILE
  -T _                                       mb::_filetest [qw( -T )], \*_
  -T qq{file}                                mb::_filetest [qw( -T  )], qq{file}
  -W $fh                                     mb::_filetest [qw( -W)],  $fh
  -W 'file'                                  mb::_filetest [qw( -W)],  'file'
  -W FILE                                    mb::_filetest [qw( -W )], \*FILE
  -W _                                       mb::_filetest [qw( -W )], \*_
  -W qq{file}                                mb::_filetest [qw( -W  )], qq{file}
  -X $fh                                     mb::_filetest [qw( -X)],  $fh
  -X 'file'                                  mb::_filetest [qw( -X)],  'file'
  -X FILE                                    mb::_filetest [qw( -X )], \*FILE
  -X _                                       mb::_filetest [qw( -X )], \*_
  -X qq{file}                                mb::_filetest [qw( -X  )], qq{file}
  -b $fh                                     mb::_filetest [qw( -b)],  $fh
  -b 'file'                                  mb::_filetest [qw( -b)],  'file'
  -b FILE                                    mb::_filetest [qw( -b )], \*FILE
  -b _                                       mb::_filetest [qw( -b )], \*_
  -b qq{file}                                mb::_filetest [qw( -b  )], qq{file}
  -c $fh                                     mb::_filetest [qw( -c)],  $fh
  -c 'file'                                  mb::_filetest [qw( -c)],  'file'
  -c FILE                                    mb::_filetest [qw( -c )], \*FILE
  -c _                                       mb::_filetest [qw( -c )], \*_
  -c qq{file}                                mb::_filetest [qw( -c  )], qq{file}
  -d $fh                                     mb::_filetest [qw( -d)],  $fh
  -d 'file'                                  mb::_filetest [qw( -d)],  'file'
  -d FILE                                    mb::_filetest [qw( -d )], \*FILE
  -d _                                       mb::_filetest [qw( -d )], \*_
  -d qq{file}                                mb::_filetest [qw( -d  )], qq{file}
  -e $fh                                     mb::_filetest [qw( -e)],  $fh
  -e 'file'                                  mb::_filetest [qw( -e)],  'file'
  -e FILE                                    mb::_filetest [qw( -e )], \*FILE
  -e _                                       mb::_filetest [qw( -e )], \*_
  -e qq{file}                                mb::_filetest [qw( -e  )], qq{file}
  -f $fh                                     mb::_filetest [qw( -f)],  $fh
  -f 'file'                                  mb::_filetest [qw( -f)],  'file'
  -f FILE                                    mb::_filetest [qw( -f )], \*FILE
  -f _                                       mb::_filetest [qw( -f )], \*_
  -f qq{file}                                mb::_filetest [qw( -f  )], qq{file}
  -g $fh                                     mb::_filetest [qw( -g)],  $fh
  -g 'file'                                  mb::_filetest [qw( -g)],  'file'
  -g FILE                                    mb::_filetest [qw( -g )], \*FILE
  -g _                                       mb::_filetest [qw( -g )], \*_
  -g qq{file}                                mb::_filetest [qw( -g  )], qq{file}
  -k $fh                                     mb::_filetest [qw( -k)],  $fh
  -k 'file'                                  mb::_filetest [qw( -k)],  'file'
  -k FILE                                    mb::_filetest [qw( -k )], \*FILE
  -k _                                       mb::_filetest [qw( -k )], \*_
  -k qq{file}                                mb::_filetest [qw( -k  )], qq{file}
  -l $fh                                     mb::_filetest [qw( -l)],  $fh
  -l 'file'                                  mb::_filetest [qw( -l)],  'file'
  -l FILE                                    mb::_filetest [qw( -l )], \*FILE
  -l _                                       mb::_filetest [qw( -l )], \*_
  -l qq{file}                                mb::_filetest [qw( -l  )], qq{file}
  -o $fh                                     mb::_filetest [qw( -o)],  $fh
  -o 'file'                                  mb::_filetest [qw( -o)],  'file'
  -o FILE                                    mb::_filetest [qw( -o )], \*FILE
  -o _                                       mb::_filetest [qw( -o )], \*_
  -o qq{file}                                mb::_filetest [qw( -o  )], qq{file}
  -p $fh                                     mb::_filetest [qw( -p)],  $fh
  -p 'file'                                  mb::_filetest [qw( -p)],  'file'
  -p FILE                                    mb::_filetest [qw( -p )], \*FILE
  -p _                                       mb::_filetest [qw( -p )], \*_
  -p qq{file}                                mb::_filetest [qw( -p  )], qq{file}
  -r $fh                                     mb::_filetest [qw( -r)],  $fh
  -r 'file'                                  mb::_filetest [qw( -r)],  'file'
  -r -w -f $fh                               mb::_filetest [qw( -r -w -f)],  $fh
  -r -w -f 'file'                            mb::_filetest [qw( -r -w -f)],  'file'
  -r -w -f FILE                              mb::_filetest [qw( -r -w -f )], \*FILE
  -r -w -f _                                 mb::_filetest [qw( -r -w -f )], \*_
  -r -w -f qq{file}                          mb::_filetest [qw( -r -w -f  )], qq{file}
  -r FILE                                    mb::_filetest [qw( -r )], \*FILE
  -r _                                       mb::_filetest [qw( -r )], \*_
  -r qq{file}                                mb::_filetest [qw( -r  )], qq{file}
  -s $fh                                     mb::_filetest [qw( -s)],  $fh
  -s 'file'                                  mb::_filetest [qw( -s)],  'file'
  -s FILE                                    mb::_filetest [qw( -s )], \*FILE
  -s _                                       mb::_filetest [qw( -s )], \*_
  -s qq{file}                                mb::_filetest [qw( -s  )], qq{file}
  -t $fh                                     mb::_filetest [qw( -t)],  $fh
  -t 'file'                                  mb::_filetest [qw( -t)],  'file'
  -t FILE                                    mb::_filetest [qw( -t )], \*FILE
  -t _                                       mb::_filetest [qw( -t )], \*_
  -t qq{file}                                mb::_filetest [qw( -t  )], qq{file}
  -u $fh                                     mb::_filetest [qw( -u)],  $fh
  -u 'file'                                  mb::_filetest [qw( -u)],  'file'
  -u FILE                                    mb::_filetest [qw( -u )], \*FILE
  -u _                                       mb::_filetest [qw( -u )], \*_
  -u qq{file}                                mb::_filetest [qw( -u  )], qq{file}
  -w $fh                                     mb::_filetest [qw( -w)],  $fh
  -w 'file'                                  mb::_filetest [qw( -w)],  'file'
  -w FILE                                    mb::_filetest [qw( -w )], \*FILE
  -w _                                       mb::_filetest [qw( -w )], \*_
  -w qq{file}                                mb::_filetest [qw( -w  )], qq{file}
  -x $fh                                     mb::_filetest [qw( -x)],  $fh
  -x 'file'                                  mb::_filetest [qw( -x)],  'file'
  -x FILE                                    mb::_filetest [qw( -x )], \*FILE
  -x _                                       mb::_filetest [qw( -x )], \*_
  -x qq{file}                                mb::_filetest [qw( -x  )], qq{file}
  -z $fh                                     mb::_filetest [qw( -z)],  $fh
  -z 'file'                                  mb::_filetest [qw( -z)],  'file'
  -z FILE                                    mb::_filetest [qw( -z )], \*FILE
  -z _                                       mb::_filetest [qw( -z )], \*_
  -z qq{file}                                mb::_filetest [qw( -z  )], qq{file}
  -----------------------------------------------------------------------------

Each elements in strings or regular expressions that are double-quote like are
transpiled as follows

  -----------------------------------------------------------------------------------------------
  in your script                             script transpiled by this software
  -----------------------------------------------------------------------------------------------
  "\u\L MBCS-quotee \E\E"                    "@{[mb::ucfirst(qq<@{[mb::lc(qq< OO-quotee >)]}>)]}"
  "\L\u MBCS-quotee \E\E"                    "@{[mb::ucfirst(qq<@{[mb::lc(qq< OO-quotee >)]}>)]}"
  "\l\U MBCS-quotee \E\E"                    "@{[mb::lcfirst(qq<@{[mb::uc(qq< OO-quotee >)]}>)]}"
  "\U\l MBCS-quotee \E\E"                    "@{[mb::lcfirst(qq<@{[mb::uc(qq< OO-quotee >)]}>)]}"
  "\L MBCS-quotee \E"                        "@{[mb::lc(qq< OO-quotee >)]}"
  "\U MBCS-quotee \E"                        "@{[mb::uc(qq< OO-quotee >)]}"
  "\l MBCS-quotee \E"                        "@{[mb::lcfirst(qq< OO-quotee >)]}"
  "\u MBCS-quotee \E"                        "@{[mb::ucfirst(qq< OO-quotee >)]}"
  "\Q MBCS-quotee \E"                        "@{[quotemeta(qq< OO-quotee >)]}"
  -----------------------------------------------------------------------------------------------

Each elements in regular expressions are transpiled as follows

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
  qr/./                                      qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_dot]})/ ]}@{[mb::_m_passed()]}}
  qr/\B/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_B]})/ ]}@{[mb::_m_passed()]}}
  qr/\D/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_D]})/ ]}@{[mb::_m_passed()]}}
  qr/\H/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_H]})/ ]}@{[mb::_m_passed()]}}
  qr/\N/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_N]})/ ]}@{[mb::_m_passed()]}}
  qr/\R/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_R]})/ ]}@{[mb::_m_passed()]}}
  qr/\S/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_S]})/ ]}@{[mb::_m_passed()]}}
  qr/\V/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_V]})/ ]}@{[mb::_m_passed()]}}
  qr/\W/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_W]})/ ]}@{[mb::_m_passed()]}}
  qr/\b/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_b]})/ ]}@{[mb::_m_passed()]}}
  qr/\d/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_d]})/ ]}@{[mb::_m_passed()]}}
  qr/\h/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_h]})/ ]}@{[mb::_m_passed()]}}
  qr/\s/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_s]})/ ]}@{[mb::_m_passed()]}}
  qr/\v/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_v]})/ ]}@{[mb::_m_passed()]}}
  qr/\w/                                     qr{\G${mb::_anchor}@{[qr/(?:@{[@mb::_w]})/ ]}@{[mb::_m_passed()]}}
  qr/[\b]/                                   qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[\\b])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:alnum:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:alnum:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:alpha:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:alpha:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:ascii:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:ascii:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:blank:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:blank:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:cntrl:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:cntrl:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:digit:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:digit:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:graph:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:graph:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:lower:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:lower:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:print:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:print:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:punct:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:punct:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:space:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:space:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:upper:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:upper:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:word:]]/                             qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:word:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:xdigit:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:xdigit:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^alnum:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^alnum:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^alpha:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^alpha:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^ascii:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^ascii:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^blank:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^blank:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^cntrl:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^cntrl:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^digit:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^digit:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^graph:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^graph:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^lower:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^lower:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^print:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^print:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^punct:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^punct:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^space:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^space:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^upper:]]/                           qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^upper:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^word:]]/                            qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^word:]])]})/ ]}@{[mb::_m_passed()]}}
  qr/[[:^xdigit:]]/                          qr{\G${mb::_anchor}@{[qr/(?:@{[mb::_cc(qq[[:^xdigit:]])]})/ ]}@{[mb::_m_passed()]}}
  ----------------------------------------------------------------------------------------------------------------------

=head1 Command-line Wildcard Expansion on Microsoft Windows

cmd.exe that is default command shell of Microsoft Windows doesn't expand
wildcard arguments supplied onto command line. But this software helps it.

  # @ARGV wildcard globbing
  if ($OSNAME =~ /MSWin32/) {
      my @argv = ();
      for (@ARGV) {
  
          # has space
          if (/\A (?:$x)*? [ ] /oxms) {
              if (my @glob = mb::dosglob(qq{"$_"})) {
                  push @argv, @glob;
              }
              else {
                  push @argv, $_;
              }
          }
  
          # has wildcard metachar
          elsif (/\A (?:$x)*? [*?] /oxms) {
              if (my @glob = mb::dosglob($_)) {
                  push @argv, @glob;
              }
              else {
                  push @argv, $_;
              }
          }
  
          # no wildcard globbing
          else {
              push @argv, $_;
          }
      }
      @ARGV = @argv;
  }

=head1 Yet Another Future of Multibyte Perl

JPerl is very useful software. This "JPerl" means "Japanized Perl" or
"Japanese Perl". The last version of JPerl is 5.005_04 and is not maintained
now. Japanization maintainer WATANABE Hirofumi-san said this ...

  "Because WATANABE am tired I give over maintaing JPerl."

at Slide #15: "The future of JPerl" in "jperlconf.ppt" on The Perl Confernce
Japan 1998. And he taught us on [Tokyo.pm] jus Benkyoukai at 1999-09-09,

  http://mail.pm.org/pipermail/tokyo-pm/1999-September/001854.html
  save as: SJIS.pm
  
  package SJIS;
  use Filter::Util::Call;
  sub multibyte_filter {
      my $status;
      if (($status = filter_read()) > 0 ) {
          s/([\x81-\x9f\xe0-\xef])([\x40-\x7e\x80-\xfc])/
              sprintf("\\x%02x\\x%02x",ord($1),ord($2))
          /eg;
      }
      $status;
  }
  sub import {
      filter_add(\&multibyte_filter);
  }
  1;

(Unfortunately, Filter::Util::Call module requires Perl 5.6, so I couldn't
use it on Perl 5.00503 that's my home.)

I am excited about this software and Perl's future --- I hope you are too.

=head1 DEPENDENCIES

This mb.pm modulino requires perl5.00503 or later to use. Also requires 'strict'
module. It requires the 'warnings' module, too if perl 5.6 or later.

=head1 Fatal Bugs Unavoidable

For several reasons, we were unable to achieve the following features:

=over 2

=item * chdir() on Microsoft Windows

Function chdir() cannot work if path is ended by chr(0x5C).

  This problem is specific to Microsoft Windows. It is not caused by the mb.pm
  modulino or the perl interpreter.
  
  # chdir.pl
  mkdir((qw( ソ ))[0], 0777);
  print "got=", chdir((qw( ソ ))[0]), " cwd=", `cd`;
  
  C:\HOME>perl5.00503.exe chdir.pl
    GOOD ==> got=1 cwd=C:\HOME\ソ
  
  C:\HOME>strawberry-perl-5.8.9.5.exe chdir.pl
    BAD ==> got=1 cwd=C:\HOME

This is a lost technology in this century.

  # suggested module name
  use mb::WinDir; # supports for all MBCS on Microsoft Windows
  my $wd = mb::WinDir->new('ソ');
  $wd->chdir('..');
  $wd->open(my $fh, ...);

=item * Limitation of Regular Expression

This software has limitation from \G in multibyte anchoring. Only perl 5.30.0 or
later can treat the codepoint string which exceeds 65534 octets with a regular
expression, and only perl 5.10.1 or later can 32766 octets.

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

Everything in this world has limits. If you use perl 5.10 or later, or perl 5.30
or later, you can increase those limits. That's better way.

=back

=head1 Small Bugs (Avoidable by Your Scripting)

You can avoid the following bugs with little hacks.

=over 2

=item * Special Variables $` and $& need m/( Capture All )/

If you use the special variables $ ` or $&, you must enclose the entire regular
expression in parentheses. Because $` and $& needs $1 to implement its.

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

In the past, Perl scripts with special variables $` and $& had a problem with
slow execution. Both that era and today, capturing by parentheses works well.

=item * Return Value from tr///s

tr/// (or y///) operator with /s modifier returns 1 always. If you need right
value, you can use mb::tr().

  $var1 = 'AAA';
  $got = $var1 =~ tr/A/1/s; # works as $got = $var1 =~ s{[\x00-\xFF]*}{mb::tr($&,q/A/,q/1/,'sr')}e;
    BAD ==> got 1
  
  $var2 = 'BBB';
  $got = $var2 =~ tr/A/1/s; # works as $got = $var2 =~ s{[\x00-\xFF]*}{mb::tr($&,q/A/,q/1/,'sr')}e;
    BAD ==> got 1
  
  $var3 = 'AAA';
  $got = mb::tr($var3,'A','1','s'); # works as $got = mb::tr($var3,'A','1','s');
    GOOD ==> got 3
  
  Transliteration routine
  
  $return = mb::tr($MBCS_string, $searchlist, $replacementlist, $modifier);
  $return = mb::tr($MBCS_string, $searchlist, $replacementlist);
  
  This subroutine is a runtime routine to implement tr/// operator for MBCS
  codepoint. This subroutine scans an $MBCS_string by codepoint and replaces all
  occurrences of the codepoint found in $searchlist with the corresponding
  codepoint in $replacementlist. It returns the number of codepoint replaced or
  deleted except on /s modifier used.
  
  $modifier are:
  
  ---------------------------------------------------------------------------
  Modifier   Meaning
  ---------------------------------------------------------------------------
  c          Complement $searchlist.
  d          Delete found but unreplaced characters.
  s          Squash duplicate replaced characters.
  r          Return transliteration and leave the original string untouched.
  ---------------------------------------------------------------------------
  
  To use with a read-only value without raising an exception, use the /r modifier.
  
  print mb::tr('bookkeeper','boep','peob','r'); # prints 'peekkoobor'

=item * mb::substr as Lvalue

If perl version is older than 5.14, mb::substr differs from CORE::substr, and
cannot be used as an lvalue. To change part of a string, you need use the optional
fourth argument which is the replacement string.

mb::substr($string, 13, 4, "JPerl");

If you use perl 5.14 or later, you can use lvalue feature.

=back

=head1 Not Supported Features (Tell us Good Idea)

Unfortunately, we couldn't make following features. Could you tell us someone
who know better idea?

=over 2

=item * Cloister of Regular Expression

The cloister (?i) and (?i:...) of a regular expression on encoding of big5,
big5hkscs, gb18030, gbk, sjis, and uhc will not be implemented for the time being.
I didn't implement this feature because it was difficult to implement and less
necessary. If you're interested in this issue, try challenge it.

=item * Look-behind Assertion

The look-behind assertion like (?<=[A-Z]) or (?<![A-Z]) are not prevented from
matching trail octet of the previous MBCS codepoint.

=back

=head1 Removed Features and No Features

mb.pm modulino does not support the following features intentionally.
There are no plans to implement it in the future, too.

=over 2

=item * Delimiter of String and Regexp

qq//, q//, qw//, qx//, qr//, m//, s///, tr///, and y/// can't use a wide codepoint
as the delimiter.
I didn't implement this feature because it's rarely needed.

=item * fc(), lc(), lcfirst(), uc(), and ucfirst()

fc() not supported. lc(), lcfirst(), uc(), and ucfirst() support US-ASCII only.

  # suggested module name
  use mb::Casing; # supports for all MBCS, including UTF-8
  my $lc_string      = mb::Casing::lc($string);
  my $lcfirst_string = mb::Casing::lcfirst($string);
  my $uc_string      = mb::Casing::uc($string);
  my $ucfirst_string = mb::Casing::ucfirst($string);
  my $fc_string      = mb::Casing::fc($string);

=item * Hyphen of tr/// Supports US-ASCII Only

Supported ranges of tr/// and y/// by hyphen are US-ASCII only.

=item * Modifier /a /d /l and /u of Regular Expression

I have removed these modifiers to remove your headache.
The concept of this software is not to use two or more encoding methods as
literal string and literal of regexp in one Perl script. Therefore, modifier
/a, /d, /l, and /u are not supported.
\d means [0-9] universally.

=item * Empty Variable in Regular Expression

An empty literal string as regexp means empty string. Unlike original Perl, if
'pattern' is an empty string, the last successfully matched regexp is NOT used.
Similarly, empty string made by interpolated variable means empty string, too.

=item * Named Codepoint

A named codepoint, such \N{GREEK SMALL LETTER EPSILON}, \N{greek:epsilon}, or
\N{epsilon} is not supported.

  # suggested module name
  use mb::Charnames qw( %N ); # supports for all MBCS, including UTF-8
  print "$N{'GREEK SMALL LETTER EPSILON'}";
  
  # By the way, you know how great it is to be able to write MBCS literal strings in your Perl scripts, right?

=item * Unicode Properties (aka Codepoint Properties) of Regular Expression

Unicode properties (aka codepoint properties) of regexp are not available.
Also (?[]) in regexp of perl 5.18 is not available. There is no plans to currently
support these.

  # suggested module name
  use mb::RegExp::Properties qw( %p %P ); # supports for all MBCS, including UTF-8
  $string =~ /$p{Uppercase}/;

This feature (\p{prop} and \P{prop}) is not stable in the Perl specification.
Thus, this feature is not available in scripts that require long-term maintenance.

  For example, [:alpha:]
  at Perl 5.005   (not supported)
  at Perl 5.6     \p{IsAlpha}
  at Perl 5.12.1  \p{PosixAlpha}, and \p{Alpha}
  at Perl 5.14    \p{X_POSIX_Alpha}, \p{POSIX_Alpha}, \p{XPosixAlpha}, and \p{PosixAlpha}

=item * \b{...} \B{...} Boundaries in Regular Expressions

Following \b{...} \B{...} available starting in Perl 5.22 are not supported.

  \b{gcb} or \b{g}   Unicode "Grapheme Cluster Boundary"
  \b{sb}             Unicode "Sentence Boundary"
  \b{wb}             Unicode "Word Boundary"
  \B{gcb} or \B{g}   Unicode "Grapheme Cluster Boundary" doesn't match
  \B{sb}             Unicode "Sentence Boundary" doesn't match
  \B{wb}             Unicode "Word Boundary" doesn't match

  # suggested module name
  use mb::RegExp::Boundaries qw( %b %B ); # supports for all MBCS, including UTF-8
  $string =~ /$b{wb}(.+)$b{wb}/;

This feature (\b{...} and \B{...}) considered not yet stable in the Perl specification.

=item * ?? and m?? are Not Supported

Multibyte character needs ( ) which is before {n,m}, {n,}, {n}, *, and + in ?? or
m??. As a result, you need to rewrite a script about $1,$2,$3,... You cannot use
(?: ), ?, {n,m}?, {n,}?, and {n}? in ?? and m??, because delimiter of m?? is '?'.
Here's a quote words from Dan Kogai-san.
"(I'm just a programmer,) so I can't fix the bug of the spec."

=item * format

Unlike JPerl, mb.pm modulino does not support the format feature. Because it is
difficult to implement and you can write the same script in other any ways.

=back

=head1 Our Goals (and UTF8 Flag Considered Harmful)

Maybe Larry Wall-san think that "escaping" is the best solution in this case.

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

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

This software attempts to achieve this goal by embedded functions work as
traditional and stably.

=item * Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

This software is not a magician, so cannot see your mind and run it.

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
      New --- New codepoint-oriented

There is a combination from (a) to (e) in data, script, and interpreter
of old and new. Let's add JPerl, utf8 pragma, and this software.

                        (a)     (b)     (c)     (d)     (e)
                                      JPerl,mb        utf8
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New codepoint-oriented

The reason why JPerl is very excellent is that it is at the position of
(c). That is, it is almost not necessary to write a special code to process
new codepoint oriented script.

=item * Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is impossible. Because the following time is necessary.

(1) Time of escape script for old byte-oriented perl.

(2) Time of processing regular expression by escaped script while
    multibyte anchoring.

=item * Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

JPerl remains one Perl "language" by forking to two "interpreters."
However, the Perl core team did not desire fork of the "interpreter."
As a result, Perl "language" forked contrary to goal #4.

A codepoint oriented perl is not necessary to make it specially,
because a byte-oriented perl can already treat the binary data.
This software is only an application program of byte-oriented Perl,
a filter program.

And you will get support from the Perl community, when you solve the
problem by the Perl script.

mb.pm modulino keeps one "language" and one "interpreter."

=item * Goal #5:

mb.pm users will be able to maintain mb.pm by Perl.

May the mb.pm be with you, always.

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

However, the ability to have any character in a string means you can
create, scan, and manipulate raw binary data as string -- something with
which many other utilities would have great difficulty.

--- Learning Perl 8th Edition

=head1 Combinations of mb.pm Modulino and Other Modules

The following is a description of all the situations in mb.pm modulino is used in Japan.

  +-------------+--------------+---------------------------------------------------------------------+
  | OS encoding | I/O encoding |                           script encoding                           |
  |             |              |----------------------------------+----------------------------------+
  |             |              |              Sjis                |              UTF-8               |
  +-------------+--------------+----------------------------------+----------------------------------+
  |             |              |  > perl mb.pm script.pl          |  > perl mb.pm -e utf8 script.pl  |
  |             |    Sjis      |                                  |  use IOas::Sjis;  # I/O          |
  |             |              |                                  |  use mb::Encode;  # file-path    |
  |    Sjis     +--------------+----------------------------------+----------------------------------+
  |             |              |  > perl mb.pm script.pl          |  > perl mb.pm -e utf8 script.pl  |
  |             |    UTF-8     |  use IOas::UTF8; # I/O           |                                  |
  |             |              |                                  |  use mb::Encode;  # file-path    |
  +-------------+--------------+----------------------------------+----------------------------------+
  |             |              |  $ perl mb.pm -e sjis script.pl  |  $ perl mb.pm script.pl          |
  |             |    Sjis      |                                  |  use IOas::Sjis;  # I/O          |
  |             |              |  use mb::Encode; # file-path     |                                  |
  |    UTF-8    +--------------+----------------------------------+----------------------------------+
  |             |              |  $ perl mb.pm -e sjis script.pl  |  $ perl mb.pm script.pl          |
  |             |    UTF-8     |  use IOas::UTF8; # I/O           |                                  |
  |             |              |  use mb::Encode; # file-path     |                                  |
  +-------------+--------------+----------------------------------+----------------------------------+

Some of the above are useful combinations

  +-------------+--------------+---------------------------------------------------------------------+
  | OS encoding | I/O encoding |                           script encoding                           |
  |             |              |----------------------------------+----------------------------------+
  |             |              |              Sjis                |              UTF-8               |
  +-------------+--------------+----------------------------------+----------------------------------+
  |             |              |  > perl mb.pm script.pl          |                                  |
  |             |    Sjis      |                                  |                                  |
  |             |              |                                  |                                  |
  |    Sjis     +--------------+----------------------------------+----------------------------------+
  |             |              |                                  |  > perl mb.pm -e utf8 script.pl  |
  |             |    UTF-8     |                                  |                                  |
  |             |              |                                  |  use mb::Encode;  # file-path    |
  +-------------+--------------+----------------------------------+----------------------------------+
  |             |              |  $ perl mb.pm -e sjis script.pl  |                                  |
  |             |    Sjis      |                                  |                                  |
  |             |              |  use mb::Encode; # file-path     |                                  |
  |    UTF-8    +--------------+----------------------------------+----------------------------------+
  |             |              |                                  |  $ perl mb.pm script.pl          |
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

see also: 7 superstitions about character encoding I encountered

https://qiita.com/tonluqclml/items/d4f8274e0292df393b04

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See the LICENSE
file for details.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

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
