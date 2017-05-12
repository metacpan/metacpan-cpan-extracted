package Text::Autoformat::Hang;
$Text::Autoformat::Hang::VERSION = '1.74';
use 5.006;
use strict;
use warnings;

# ROMAN NUMERALS

sub inv($@) { my ($k, %inv)=shift; for(0..$#_) {$inv{$_[$_]}=$_*$k} %inv }
my @unit= ( "" , qw ( I II III IV V VI VII VIII IX ));
my @ten = ( "" , qw ( X XX XXX XL L LX LXX LXXX XC ));
my @hund= ( "" , qw ( C CC CCC CD D DC DCC DCCC CM ));
my @thou= ( "" , qw ( M MM MMM ));
my %rval= (inv(1,@unit),inv(10,@ten),inv(100,@hund),inv(1000,@thou));
my $rbpat= join ")(",join("|",reverse @thou), join("|",reverse @hund), join("|",reverse @ten), join("|",reverse @unit);
my $rpat= join ")(?:",join("|",reverse @thou), join("|",reverse @hund), join("|",reverse @ten), join("|",reverse @unit);
my $rom = qq/(?:(?=[MDCLXVI])(?:$rpat))/;

my $abbrev = join '|', qw{ etc[.]   pp[.]   ph[.]?d[.] },
                       "(?!$rom)(?:[A-Z][A-Za-z]+[.])+",
                       '(?:[A-Z][.])(?:[A-Z][.])+';

sub fromRoman($)
{
    return 0 unless $_[0] =~ /^.*?($rbpat).*$/i;
    return $rval{uc $1} + $rval{uc $2} + $rval{uc $3} + $rval{uc $4};
}

sub toRoman($$)
{
    my ($num,$example) = @_;
    return '' unless $num =~ /^([0-3]??)(\d??)(\d??)(\d)$/;
    my $roman = $thou[$1||0] . $hund[$2||0] . $ten[$3||0] . $unit[$4||0];
    return $example=~/[A-Z]/ ? uc $roman : lc $roman;
}

# BITS OF A NUMERIC VALUE

my $num = q/(?:[0-9]{1,3}\b(?!:[0-9][0-9]\b))/;     # Ignore 8:20 etc.
my $let = q/[A-Za-z]/;
my $pbr = q/[[(<]/;
my $sbr = q/])>/;
my $ows = q/[ \t]*/;
my %close = ( '[' => ']', '(' => ')', '<' => '>', "" => '' );

my $hangPS      = qq{(?i:ps:|(?:p\\.?)+s\\b\\.?(?:[ \\t]*:)?)};
my $hangNB      = qq{(?i:n\\.?b\\.?(?:[ \\t]*:)?)};
my $hangword    = qq{(?:(?:Note)[ \\t]*:)};
my $hangbullet  = qq{[*.+-]};
my $hang        = qq{(?:(?i)(?:$hangNB|$hangword|$hangbullet)(?=[ \t]))};

# IMPLEMENTATION

sub new { 
    my ($class, $orig, $lists_mode) = @_;
    return Text::Autoformat::NullHang->new() if !$lists_mode;

    my $origlen = length $orig;
    my @vals;
    if ($_[1] =~ s#\A($hangPS)##) {
        @vals = { type => 'ps', val => $1 }
    }
    elsif ($lists_mode =~ /1|bullet/i && $_[1] =~ s#\A($hang)##) {
        @vals = { type => 'bul', val => $1 }
    }
    elsif ($_[1] =~ m#\A\([^\s)]+\s#) {
        @vals = ();
    }
    else {
        no warnings "all";
        my $cut;
        while (length $_[1]) {
            last if $_[1] =~ m#\A($ows)($abbrev)#
                 && (length $1 || !@vals);  # ws-separated or first

            last if $_[1] =~ m{\A $ows $pbr [^$sbr \t]* \s}xms;

            $cut = $origlen - length $_[1];
            my $pre = $_[1] =~ s#\A($ows$pbr$ows)## ? $1 : "";
            my $val
                = ($lists_mode =~ /1|number/i && $_[1] =~ s#\A($num)##)
                        ? { type=>'num', val=>$1 }
                : ($lists_mode =~ /1|roman/i && $_[1] =~ s#\A($rom)\b##i)
                        ? { type=>'rom', val=>$1, nval=>fromRoman($1) }
                : ($lists_mode =~ /1|alpha/i && $_[1] =~ s#\A($let(?!$let))##i)
                        ? { type=>'let', val=>$1 }
                :         { val => "", type => "" };
            $_[1] = $pre.$_[1] and last unless $val->{val};
            $val->{post} = $pre && $_[1] =~ s#\A($ows()[.:/]?[$close{$pre}][.:/]?)## && $1
                             || $_[1] =~ s#\A($ows()[$sbr.:/])## && $1
                             || "";
            $val->{pre}  = $pre;
            $val->{cut}  = $cut;
            push @vals, $val;
        }
        while (@vals && !$vals[-1]{post}) {
            $_[1] = substr($orig,pop(@vals)->{cut});
        }
    }

    # check for orphaned years or unlikely Roman numerals...
    if (@vals==1 && defined $vals[0]->{post} && $vals[0]->{post} =~ /[\.>)]/) {
        my $v = $vals[0];
        if ($v->{type} eq 'num' && $v->{val} >= 1000) {
            $_[1] = substr($orig,pop(@vals)->{cut});
        }
    }

    return Text::Autoformat::NullHang->new if !@vals;
    bless \@vals, $class;
} 

sub incr {
    no warnings "all";
    my ($self, $prev, $prevsig) = @_;
    my $level;
    # check compatibility

    return unless $prev && !$prev->empty;

    for $level (0..(@$self<@$prev ? $#$self : $#$prev)) {
        if ($self->[$level]{type} ne $prev->[$level]{type}) {
            return if @$self<=@$prev;   # no incr if going up
            $prev = $prevsig;
            last;
        }
    }
    return unless $prev && !$prev->empty;
    if ($self->[0]{type} eq 'ps') {
        my $count = 1 + $prev->[0]{val} =~ s/(p[.]?)/$1/gi;
        $prev->[0]{val} =~ /^(p[.]?).*(s[.]?[:]?)/;
        $self->[0]{val} = $1  x $count . $2;
    }
    elsif ($self->[0]{type} eq 'bul') {
        # do nothing
    }
    elsif (@$self>@$prev) { # going down level(s)
        for $level (0..$#$prev) {
                @{$self->[$level]}{'val','nval'} = @{$prev->[$level]}{'val','nval'};
        }
        for $level (@$prev..$#$self) {
                _reset($self->[$level]);
        }
    }
    else    # same level or going up
    {
        for $level (0..$#$self) {
            @{$self->[$level]}{'val','nval'} = @{$prev->[$level]}{'val','nval'};
        }
        _incr($self->[-1])
    }
}

sub _incr {
    no warnings "all";
    if ($_[0]{type} eq 'rom') {
        $_[0]{val} = toRoman(++$_[0]{nval},$_[0]{val});
    }
    else {
        $_[0]{val}++ unless $_[0]{type} eq 'let' && $_[0]{val}=~/Z/i;
    }
}

sub _reset {
    no warnings "all";
    if ($_[0]{type} eq 'rom') {
        $_[0]{val} = toRoman($_[0]{nval}=1,$_[0]{val});
    }
    elsif ($_[0]{type} eq 'let') {
        $_[0]{val} = $_[0]{val} =~ /[A-Z]/ ? 'A' : 'a';
    }
    else {
        $_[0]{val} = 1;
    }
}

sub stringify {
    my ($self) = @_;
    my ($str, $level) = ("");
    for $level (@$self) {
        no warnings "all";
        $str .= join "", @{$level}{'pre','val','post'};
    }
    return $str;
} 

sub val {
    my ($self, $i) = @_;
    return $self->[$i]{val};
}

sub fields { return scalar @{$_[0]} }

sub field {
    my ($self, $i, $newval) = @_;
    $self->[$i]{type} = $newval if @_>2;
    return $self->[$i]{type};
}

sub signature {
    no warnings "all";
    my ($self) = @_;
    my ($str, $level) = ("");
    for $level (@$self) {
        $level->{type} ||= "";
        $str .= join "", $level->{pre},
                         ($level->{type} =~ /rom|let/ ? "romlet" : $level->{type}),
                         $level->{post};
    }
    return $str;
} 

sub length {
    length $_[0]->stringify
}

sub empty { 0 }

1;

