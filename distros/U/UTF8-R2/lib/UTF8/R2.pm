package UTF8::R2;
######################################################################
#
# UTF8::R2 - makes UTF-8 scripting easy for enterprise use or LTS
#
# http://search.cpan.org/dist/UTF8-R2/
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Galapagos Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.02';
$VERSION = $VERSION;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use Carp ();
use Symbol ();

my %utf8_codepoint = ();
$utf8_codepoint{'RFC2279'} = q{(?>
    [\x00-\x7F\xC0-\xC1\xF5-\xFF]                |
    [\xC2-\xDF][\x80-\xBF]                       |
    [\xE0-\xEF][\x80-\xBF][\x80-\xBF]            |
    [\xF0-\xF4][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
    [\x00-\xFF]
)};
$utf8_codepoint{'RFC3629'} = q{(?>
    [\x00-\x7F\xC0-\xC1\xF5-\xFF]                |
    [\xC2-\xDF][\x80-\xBF]                       |
    [\xE0-\xE0][\xA0-\xBF][\x80-\xBF]            |
    [\xE1-\xEC][\x80-\xBF][\x80-\xBF]            |
    [\xED-\xED][\x80-\x9F][\x80-\xBF]            |
    [\xEE-\xEF][\x80-\xBF][\x80-\xBF]            |
    [\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |
    [\x00-\xFF]
)};
for (sort keys %utf8_codepoint) {
    $utf8_codepoint{$_} =~ s/[ \r\n]//g;
}

# /./ [\b] \d \h \s \v \w
my $x =
    ($^X =~ /jperl(\.exe)?\z/i) && (`$^X -v` =~ /SJIS version/) ?
    q{(?>[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]|[\x00-\xFF])} : # debug tool using JPerl(SJIS version)
    $utf8_codepoint{'RFC2279'};
my $bare_b = '\x08';
my $bare_d = '0123456789';
my $bare_h = '\x09\x20';
my $bare_s = '\t\n\f\r\x20';
my $bare_v = '\x0A\x0B\x0C\x0D';
my $bare_w = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_';

sub import {
    my $self = shift @_;
    if (defined($_[0]) and ($_[0] =~ /\A[0123456789]/)) {
        if ($_[0] != $UTF8::R2::VERSION) {
            my($package,$filename,$line) = caller;
            die "$filename requires UTF8::R2 $_[0], this is version $UTF8::R2::VERSION, stopped at $filename line $line.\n";
        }
        shift @_;
    }
    for (@_) {
        if (defined $utf8_codepoint{$_}) {
            $x = $utf8_codepoint{$_};
        }
    }
}

sub _ {
    @_ ? $_[0] : $_
}

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

sub UTF8::R2::chr (;$) {
    local $_ = &_;
    if ($_ < 0) {
        return pack 'C*', 0xEF, 0xBF, 0xBD; # Unicode Codepoint 'REPLACEMENT CHARACTER' (U+FFFD)
    }
    else {
        my @octet = ();
        do {
            unshift @octet, ($_ % 0x100);
            $_ = int($_ / 0x100);
        } while ($_ > 0);
        return pack 'C*', @octet;
    }
}

sub UTF8::R2::getc (;*) {
    my $fh = @_ ? Symbol::qualify_to_ref($_[0],caller()) : \*STDIN;
    my @octet = CORE::getc($fh);
    if ($octet[0] =~ /\A[\xC2-\xDF]\z/) {
        push @octet, CORE::getc($fh);
    }
    elsif ($octet[0] =~ /\A[\xE0-\xEF]\z/) {
        push @octet, CORE::getc($fh);
        push @octet, CORE::getc($fh);
    }
    elsif ($octet[0] =~ /\A[\xF0-\xF4]\z/) {
        push @octet, CORE::getc($fh);
        push @octet, CORE::getc($fh);
        push @octet, CORE::getc($fh);
    }
    return join '', @octet;
}

sub UTF8::R2::index ($$;$) {
    if (@_ == 2) {
        my $index = CORE::index $_[0], $_[1];
        if ($index < 1) {
            return $index;
        }
        else {
            return UTF8::R2::length(CORE::substr $_[0], 0, $index);
        }
    }
    elsif (@_ == 3) {
        my $index = CORE::index $_[0], $_[1], CORE::length(UTF8::R2::substr($_[0], 0, $_[2]));
        if ($index < 1) {
            return $index;
        }
        else {
            return UTF8::R2::length(CORE::substr $_[0], 0, $index);
        }
    }
}

sub UTF8::R2::lc (;$) {
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
    return join '', map { {qw( A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z )}->{$_}||$_ } (&_ =~ /\G$x/g);
    #                          A a B b C c D d E e F f G g H h I i J j K k L l M m N n O o P p Q q R r S s T t U u V v W w X x Y y Z z
}

sub UTF8::R2::lcfirst (;$) {
    if (&_ =~ UTF8::R2::qr(qr/\A(.)(.*)\z/)) {
        return UTF8::R2::lc($1) . $2;
    }
    else {
        return '';
    }
}

sub UTF8::R2::length (;$) {
    return scalar(() = &_ =~ /\G$x/g);
}

sub UTF8::R2::ord (;$) {
    my $ord = 0;
    if (&_ =~ /\A($x)/) {
        for my $octet (unpack 'C*', $1) {
            $ord = $ord * 0x100 + $octet;
        }
    }
    return $ord;
}

sub UTF8::R2::qr ($) {
    my $before_regex = $_[0];
    my($package,$filename,$line) = caller;
#
    my $modifiers = '';
    if (($modifiers) = $before_regex =~ /\A \( \? \^? (.*?) : /x) {
        $modifiers =~ s/-.*//;
    }
#
    my @after_subregex = ();
    while ($before_regex =~ s{ \A
        (?> \[ (?: (?>\\x\{[01234567890ABCDEFabcdef]+\}) | (?>\\$x) | $x )+? \] ) |
                   (?>\\x\{[01234567890ABCDEFabcdef]+\}) | (?>\\$x) | $x
    }{}x) {
        my $before_subregex = $&;
#
        # [^...] or [...]
        if (my($negative,$before_class) = $before_subregex =~ /\A \[ (\^?) ((?>\\$x|$x)+?) \] \z/x) {
            my @before_subclass = $before_class =~ /\G (?: (?>\\x\{[01234567890ABCDEFabcdef]+\}) | (?>\\$x) | $x ) /xg;
            my @sbcs = ();
            my @mbcs = ();
            for my $before_subclass (@before_subclass) {
#
                # \x{unicode_hex}
                if (($] =~ /\A5\.006/) and (my($unicode_by_hex) = $before_subclass =~ /\A \\x \{ ([01234567890ABCDEFabcdef]+) \} \z/x)) {
                    my $unicode = hex $unicode_by_hex;
                    if (0) {}
                    elsif ($unicode <     0x80) { push @sbcs, pack('U0C*',                                                                   $unicode          ) }
                    elsif ($unicode <    0x800) { push @mbcs, pack('U0C*',                                            $unicode>>6     |0xC0, $unicode&0x3F|0x80) }
                    elsif ($unicode <  0x10000) { push @mbcs, pack('U0C*',                    $unicode>>12     |0xE0, $unicode>>6&0x3F|0x80, $unicode&0x3F|0x80) }
                    elsif ($unicode < 0x110000) { push @mbcs, pack('U0C*', $unicode>>18|0xF0, $unicode>>12&0x3F|0x80, $unicode>>6&0x3F|0x80, $unicode&0x3F|0x80) }
                    else { Carp::confess qq{@{[__FILE__]}: \\x{$unicode_by_hex} is out of Unicode (0 to 0x10FFFF)}; }
                }
#
                # \any
                elsif ($before_subclass eq '\D')          { push @mbcs, "(?:(?![$bare_d])$x)"  }
                elsif ($before_subclass eq '\H')          { push @mbcs, "(?:(?![$bare_h])$x)"  }
#               elsif ($before_subclass eq '\N')          { push @mbcs, "(?:(?!\\n)$x)"        } # \N in a character class must be a named character: \N{...} in regex
#               elsif ($before_subclass eq '\R')          { push @mbcs, "(?>\\r\\n|[$bare_v])" } # Unrecognized escape \R in character class passed through in regex
                elsif ($before_subclass eq '\S')          { push @mbcs, "(?:(?![$bare_s])$x)"  }
                elsif ($before_subclass eq '\V')          { push @mbcs, "(?:(?![$bare_v])$x)"  }
                elsif ($before_subclass eq '\W')          { push @mbcs, "(?:(?![$bare_w])$x)"  }
                elsif ($before_subclass eq '\b')          { push @sbcs, $bare_b                }
                elsif ($before_subclass eq '\d')          { push @sbcs, $bare_d                }
                elsif ($before_subclass eq '\h')          { push @sbcs, $bare_h                }
                elsif ($before_subclass eq '\s')          { push @sbcs, $bare_s                }
                elsif ($before_subclass eq '\v')          { push @sbcs, $bare_v                }
                elsif ($before_subclass eq '\w')          { push @sbcs, $bare_w                }
                elsif (CORE::length($before_subclass)==1) { push @sbcs, $before_subclass       }
                else                                      { push @mbcs, $before_subclass       }
            }
#
            # [^...]
            if ($negative eq q[^]) {
                push @after_subregex,
                    ( @sbcs and  @mbcs) ? '(?:(?!' . join('|', @mbcs, '['.join('',@sbcs).']') . ")$x)" :
                    (!@sbcs and  @mbcs) ? '(?:(?!' . join('|', @mbcs                        ) . ")$x)" :
                    ( @sbcs and !@mbcs) ? '(?:(?!' .                  '['.join('',@sbcs).']'  . ")$x)" :
                    '';
            }
#
            # [...]
            else {
                push @after_subregex,
                    ( @sbcs and  @mbcs) ? '(?:'    . join('|', @mbcs, '['.join('',@sbcs).']') . ')' :
                    (!@sbcs and  @mbcs) ? '(?:'    . join('|', @mbcs                        ) . ')' :
                    ( @sbcs and !@mbcs) ?                             '['.join('',@sbcs).']'        :
                    '';
            }
        }
#
        # \x{unicode_hex}
        elsif (($] =~ /\A5\.006/) and (my($unicode_by_hex) = $before_subregex =~ /\A \\x \{ ([01234567890ABCDEFabcdef]+) \} \z/x)) {
            my $unicode = hex $unicode_by_hex;
            if (0) {}
            elsif ($unicode <     0x80) { push @after_subregex, pack('U0C*',                                                                   $unicode          ) }
            elsif ($unicode <    0x800) { push @after_subregex, pack('U0C*',                                            $unicode>>6     |0xC0, $unicode&0x3F|0x80) }
            elsif ($unicode <  0x10000) { push @after_subregex, pack('U0C*',                    $unicode>>12     |0xE0, $unicode>>6&0x3F|0x80, $unicode&0x3F|0x80) }
            elsif ($unicode < 0x110000) { push @after_subregex, pack('U0C*', $unicode>>18|0xF0, $unicode>>12&0x3F|0x80, $unicode>>6&0x3F|0x80, $unicode&0x3F|0x80) }
            else { Carp::confess qq{@{[__FILE__]}: \\x{$unicode_by_hex} is out of Unicode (0 to 0x10FFFF)}; }
        }
#
        # \any or .
        elsif ($before_subregex eq '.')  { push @after_subregex, ($modifiers =~ /s/) ? $x : "(?:(?!\\n)$x)"                    }
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
        else                             { push @after_subregex, $before_subregex                                              }
    }
#
    my $after_regex = join '', @after_subregex;
    return qr/$after_regex/;
}

sub UTF8::R2::reverse (@) {
    if (wantarray) {
        return CORE::reverse @_;
    }
    else {
        return join '', CORE::reverse( @_ ? join('',@_) =~ /\G$x/g : /\G$x/g );
    }
}

sub UTF8::R2::rindex ($$;$) {
    if (@_ == 2) {
        my $rindex = CORE::rindex $_[0], $_[1];
        if ($rindex < 1) {
            return $rindex;
        }
        else {
            return UTF8::R2::length(CORE::substr $_[0], 0, $rindex);
        }
    }
    elsif (@_ == 3) {
        my $rindex = CORE::rindex $_[0], $_[1], CORE::length(UTF8::R2::substr($_[0], 0, $_[2]));
        if ($rindex < 1) {
            return $rindex;
        }
        else {
            return UTF8::R2::length(CORE::substr $_[0], 0, $rindex);
        }
    }
}

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

eval sprintf <<'END', ($] >= 5.014) ? ':lvalue' : '';
#                            vv--------*******
sub UTF8::R2::substr ($$;$$) %s {
    my @x = $_[0] =~ /\G$x/g;
#
    if (($_[1] < (-1 * scalar(@x))) or (+1 * scalar(@x) < $_[1])) {
        return;
    }
#
    if (@_ == 4) {
        my $substr = join '', splice @x, $_[1], $_[2], $_[3];
        $_[0] = join '', @x;
        $substr; # "return $substr" doesn't work, don't write "return"
    }
    elsif (@_ == 3) {
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
    else {
        my $octet_offset =
            ($_[1] < 0) ? -1 * CORE::length(join '', @x[$#x+$_[1]+1 .. $#x])     :
            ($_[1] > 0) ?      CORE::length(join '', @x[0           .. $_[1]-1]) :
            0;
        CORE::substr($_[0], $octet_offset);
    }
}
END

sub UTF8::R2::tr ($$$;$) {
    my @x           = $_[0] =~ /\G$x/g;
    my @search      = $_[1] =~ /\G$x/g;
    my @replacement = $_[2] =~ /\G$x/g;
    my %modifier    = (defined $_[3]) ? (map { $_ => 1 } CORE::split //, $_[3]) : ();
#
    my %tr = ();
    for (my $i=0; $i <= $#search; $i++) {
#
        # tr/AAA/123/ works as tr/A/1/
        if (not exists $tr{$search[$i]}) {
#
            # tr/ABC/123/ makes %tr = ('A'=>'1','B'=>'2','C'=>'3',);
            if (defined $replacement[$i] and ($replacement[$i] ne '')) {
                $tr{$search[$i]} = $replacement[$i];
            }
#
            # tr/ABC/12/d makes %tr = ('A'=>'1','B'=>'2','C'=>'',);
            elsif (exists $modifier{d}) {
                $tr{$search[$i]} = '';
            }
#
            # tr/ABC/12/ makes %tr = ('A'=>'1','B'=>'2','C'=>'2',);
            elsif (defined $replacement[$#replacement] and ($replacement[$#replacement] ne '')) {
                $tr{$search[$i]} = $replacement[$#replacement];
            }
#
            # tr/ABC// makes %tr = ('A'=>'A','B'=>'B','C'=>'C',);
            else {
                $tr{$search[$i]} = $search[$i];
            }
        }
    }
#
    my $tr = 0;
    my $replaced = '';
#
    # has /c modifier
    if (exists $modifier{c}) {
#
        # has /s modifier
        if (exists $modifier{s}) {
            my $last_transliterated = undef;
            while (defined(my $x = shift @x)) {
#
                # /c modifier works here
                if (exists $tr{$x}) {
                    $replaced .= $x;
                    $last_transliterated = undef;
                }
                else {
#
                    # /d modifier works here
                    if (exists $modifier{d}) {
                    }
#
                    elsif (defined $replacement[$#replacement]) {
#
                        # /s modifier works here
                        if (defined($last_transliterated) and ($replacement[$#replacement] eq $last_transliterated)) {
                        }
#
                        # tr/// works here
                        else {
                            $replaced .= ($last_transliterated = $replacement[$#replacement]);
                        }
                    }
                    $tr++;
                }
            }
        }
#
        # has no /s modifier
        else {
            while (defined(my $x = shift @x)) {
#
                # /c modifier works here
                if (exists $tr{$x}) {
                    $replaced .= $x;
                }
                else {
#
                    # /d modifier works here
                    if (exists $modifier{d}) {
                    }
#
                    # tr/// works here
                    elsif (defined $replacement[$#replacement]) {
                        $replaced .= $replacement[$#replacement];
                    }
                    $tr++;
                }
            }
        }
    }
#
    # has no /c modifier
    else {
#
        # has /s modifier
        if (exists $modifier{s}) {
            my $last_transliterated = undef;
            while (defined(my $x = shift @x)) {
                if (exists $tr{$x}) {
#
                    # /d modifier works here
                    if ($tr{$x} eq '') {
                    }
#
                    # /s modifier works here
                    elsif (defined($last_transliterated) and ($tr{$x} eq $last_transliterated)) {
                    }
#
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
#
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
#
    # /r modifier works here
    if (exists $modifier{r}) {
        return $replaced;
    }
#
    # has no /r modifier
    else {
        $_[0] = $replaced;
        return $tr;
    }
}

sub UTF8::R2::uc (;$) {
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
    return join '', map { {qw( a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z )}->{$_}||$_ } (&_ =~ /\G$x/g);
    #                          a A b B c C d D e E f F g G h H i I j J k K l L m M n N o O p P q Q r R s S t T u U v V w W x X y Y z Z
}

sub UTF8::R2::ucfirst (;$) {
    if (&_ =~ UTF8::R2::qr(qr/\A(.)(.*)\z/)) {
        return UTF8::R2::uc($1) . $2;
    }
    else {
        return '';
    }
}

# syntax sugar for UTF-8 codepoint regex
#
# tie my %utf8r2, 'UTF8::R2';
# $result = $_ =~ $utf8r2{qr/$utf8regex/}
# $result = $_ =~ s<$utf8r2{qr/before/}><after>egr

sub TIEHASH  { bless {}, $_[0] }
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
  use UTF8::R2 qw( RFC3629 ); # m/./ matches RFC3629 codepoint (default)
  use UTF8::R2 qw( RFC2279 ); # m/./ matches RFC2279 codepoint
  use UTF8::R2 ver.sion;      # match or die

    $result = UTF8::R2::chop(@_)
    $result = UTF8::R2::chr($_)
    $result = UTF8::R2::getc(FILE)
    $result = UTF8::R2::index($_, 'ABC', 5)
    $result = UTF8::R2::lc($_)
    $result = UTF8::R2::lcfirst($_)
    $result = UTF8::R2::length($_)
    $result = UTF8::R2::ord($_)
    $result = UTF8::R2::qr(qr/$utf8regex/)
    $result = UTF8::R2::reverse(@_)
    $result = UTF8::R2::rindex($_, 'ABC', 5)
    @result = UTF8::R2::split(qr/$utf8regex/, $_, 3)
    $result = UTF8::R2::substr($_, 0, 5)
    $result = UTF8::R2::tr($_, 'ABC', 'XYZ', 'cdsr')
    $result = UTF8::R2::uc($_)
    $result = UTF8::R2::ucfirst($_)

    tie my %utf8r2, 'UTF8::R2';
    $result = $_ =~ $utf8r2{qr/$utf8regex/}
    $result = $_ =~ s<$utf8r2{qr/before/}><after>egr

=head1 OCTET SEMANTICS SUBROUTINES VS. CODEPOINT SEMANTICS SUBROUTINES

Because this module override nothing, the embedded functions provide octet semantics continue.
UTF-8 codepoint semantics is provided by the new subroutine name.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Octet Semantics        UTF-8 Codepoint Semantics
  by traditional name    by new name                                Note and Limitations
  ------------------------------------------------------------------------------------------------------------------------------------------
  chop                   UTF8::R2::chop(@_)                         usually chomp() is useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  chr                    UTF8::R2::chr($_)                          returns UTF-8 codepoint octets by UTF-8 number (not by Unicode number)
  ------------------------------------------------------------------------------------------------------------------------------------------
  getc                   UTF8::R2::getc(FILE)                       get UTF-8 codepoint octets
  ------------------------------------------------------------------------------------------------------------------------------------------
  index                  UTF8::R2::index($_, 'ABC', 5)              index() is compatible and usually useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  lc                     UTF8::R2::lc($_)                           works as tr/A-Z/a-z/, universally
  ------------------------------------------------------------------------------------------------------------------------------------------
  lcfirst                UTF8::R2::lcfirst($_)                      see UTF8::R2::lc()
  ------------------------------------------------------------------------------------------------------------------------------------------
  length                 UTF8::R2::length($_)                       length() is compatible and usually useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  m// or qr//            UTF8::R2::qr(qr/$utf8regex/)               not supports metasymbol \X that match grapheme
                           or                                       not support range of codepoint(like a "[A-Z]")
                         tie my %utf8r2, 'UTF8::R2';                not supports POSIX character class (like a [:alpha:])
                         $utf8r2{qr/$utf8regex/}                    not supports named character (such as \N{GREEK SMALL LETTER EPSILON}, \N{greek:epsilon}, or \N{epsilon})
                                                                    not supports character properties (like \p{PROP} and \P{PROP})
  ------------------------------------------------------------------------------------------------------------------------------------------
  ord                    UTF8::R2::ord($_)                          returns UTF-8 number (not Unicode number) by UTF-8 codepoint octets
  ------------------------------------------------------------------------------------------------------------------------------------------
  pos                      (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------
  reverse                UTF8::R2::reverse(@_)
  ------------------------------------------------------------------------------------------------------------------------------------------
  rindex                 UTF8::R2::rindex($_, 'ABC', 5)             rindex() is compatible and usually useful
  ------------------------------------------------------------------------------------------------------------------------------------------
  s/before/after/egr     s<@{[UTF8::R2::qr(qr/before/)]}><after>egr
                           or
                         tie my %utf8r2, 'UTF8::R2';
                         s<$utf8r2{qr/before/}><after>egr
  ------------------------------------------------------------------------------------------------------------------------------------------
  split//                UTF8::R2::split(qr/$utf8regex/, $_, 3)
  ------------------------------------------------------------------------------------------------------------------------------------------
  sprintf                  (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------
  substr                 UTF8::R2::substr($_, 0, 5)                 length() is compatible and usually useful
                                                                    :lvalue feature needs perl 5.014 or later
  ------------------------------------------------------------------------------------------------------------------------------------------
  tr/// or y///          UTF8::R2::tr($_, 'ABC', 'XYZ', 'cdsr')     not support range of codepoint(like a "tr/A-Z/a-z/")
  ------------------------------------------------------------------------------------------------------------------------------------------
  uc                     UTF8::R2::uc($_)                           works as tr/a-z/A-Z/, universally
  ------------------------------------------------------------------------------------------------------------------------------------------
  ucfirst                UTF8::R2::ucfirst($_)                      see UTF8::R2::uc()
  ------------------------------------------------------------------------------------------------------------------------------------------
  write                    (nothing)
  ------------------------------------------------------------------------------------------------------------------------------------------

=head1 REGEX FEATURES

  -------------------------------------------------------------------------------------------------------
  Special Escapes in Regex                  Support Perl Version
  -------------------------------------------------------------------------------------------------------
  UTF8::R2::qr(qr/ \x{Unicode} /)           since perl 5.006
  UTF8::R2::qr(qr/ [^ ... ] /)              since perl 5.008  ** CAUTION ** perl 5.006 cannot this
  UTF8::R2::qr(qr/ \h /)                    since perl 5.010
  UTF8::R2::qr(qr/ \v /)                    since perl 5.010
  UTF8::R2::qr(qr/ \H /)                    since perl 5.010
  UTF8::R2::qr(qr/ \V /)                    since perl 5.010
  UTF8::R2::qr(qr/ \R /)                    since perl 5.010
  UTF8::R2::qr(qr/ \N /)                    since perl 5.012
  -------------------------------------------------------------------------------------------------------

=head1 OUR GOAL

P.401 See chapter 15: Unicode
of ISBN 0-596-00027-8 Programming Perl Third Edition.

Before the introduction of Unicode support in perl, The eq operator
just compared the byte-strings represented by two scalars. Beginning
with perl 5.8, eq compares two byte-strings with simultaneous
consideration of the UTF8 flag.

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
How to solve it by returning to a original method, let's drag out
page 402 of the Programming Perl, 3rd ed. again.

  Information processing model beginning with perl3 or this software
  of UNIX/C-ism.

    +--------------------------------------------+
    |    Text string as Digital octet string     |
    |    Digital octet string as Text string     |
    +--------------------------------------------+
    |       Not UTF8 Flagged, No Mojibake        |
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

This goal has been achieved by that UTF8::R2 module override nothing.

=item * Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

Not "magically."
You must decide and write octet semantics or codepoint semantics yourself
in case by case.

=item * Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is impossible.
Because processing time of multibyte anchoring in regular expression is
necessary.

=item * Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

UTF8::R2 module remains one language and one interpreter by providing
codepoint semantics subroutines.

=item * Goal #5:

UTF8::R2 users will be able to maintain it by Perl.

May the UTF8::R2 be with you, always.

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

=cut
