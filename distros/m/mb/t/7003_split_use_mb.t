# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AUse of uninitialized value \$_\[[0123456789]+\] in join or string at / ? return :
        warn $_[0];
    };
}

@test = (

# 1 returning the resulting list value in list context
    sub { @_=split(qr/1/,'A1B1C'); "@_" eq "A B C" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 11 or the count of substrings in scalar context
    sub { $_=split(qr/1/,'A1B1C'); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 21 if the PATTERN doesn't match the string at all, split returns the original string as a single substring
    sub { @_=split(qr/2/,'A1B1C'); "@_" eq "A1B1C" },
    sub { $_=split(qr/2/,'A1B1C'); $_ == 1 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 31 if it matches once, you get two substrings,
    sub { @_=split(qr/1/,'A1B'); "@_" eq "A B" },
    sub { $_=split(qr/1/,'A1B'); $_ == 2 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 41 and so on
    sub { @_=split(qr/1/,'A1B1C'); "@_" eq "A B C" },
    sub { $_=split(qr/1/,'A1B1C'); $_ == 3 },
    sub { @_=split(qr/1/,'A1B1C1D'); "@_" eq "A B C D" },
    sub { $_=split(qr/1/,'A1B1C1D'); $_ == 4 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 51 you may supply regular expression modifiers to the PATTERN, like /PATTERN/i,
    sub { @_=split(qr/a/,'1a2a3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/a/,'1a2a3');  $_ == 3 },
    sub { @_=split(qr/a/i,'1a2a3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/a/i,'1a2a3');  $_ == 3 },
    sub { @_=split(qr/A/i,'1a2a3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/A/i,'1a2a3');  $_ == 3 },
    sub { @_=split(qr/a/i,'1A2A3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/a/i,'1A2A3');  $_ == 3 },
    sub { @_=split(qr/A/i,'1A2A3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/A/i,'1A2A3');  $_ == 3 },

# 61 /PATTERN/x,
    sub { @_=split(qr/ a /x,'1a2a3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/ a /x,'1a2a3');  $_ == 3 },
    sub { @_=split(qr/ a /ix,'1a2a3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/ a /ix,'1a2a3');  $_ == 3 },
    sub { @_=split(qr/ A /ix,'1a2a3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/ A /ix,'1a2a3');  $_ == 3 },
    sub { @_=split(qr/ a /ix,'1A2A3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/ a /ix,'1A2A3');  $_ == 3 },
    sub { @_=split(qr/ A /ix,'1A2A3'); "@_" eq "1 2 3" },
    sub { $_=split(qr/ A /ix,'1A2A3');  $_ == 3 },

# 71 the //m modifier is assumed when you split on the pattern /^/
    sub { @_=split(qr/^/,"A\nB\nC"); "@_" eq "A\n B\n C" },
    sub { $_=split(qr/^/,"A\nB\nC");  $_ == 3 },
    sub { @_=split(qr/^/m,"A\nB\nC"); "@_" eq "A\n B\n C" },
    sub { $_=split(qr/^/m,"A\nB\nC");  $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 81 if LIMIT is specified and positive, the function splits into no more than that many fields
    sub { @_=split(qr/1/,'A1B1C',2); "@_" eq "A B1C" },
    sub { $_=split(qr/1/,'A1B1C',2); $_ == 2 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 91 (though it may split into fewer if it runs out of separators)
    sub { @_=split(qr/1/,'A1B1C',4); "@_" eq "A B C" },
    sub { $_=split(qr/1/,'A1B1C',4); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 101 if LIMIT is negative, it is treated as if an arbitrarily large LIMIT has been specified
    sub { @_=split(qr/1/,'A1B1C',-1); "@_" eq "A B C" },
    sub { $_=split(qr/1/,'A1B1C',-1); $_ == 3 },
    sub { @_=split(qr/1/,'A1B1C1',4); "@_" eq "A B C " },
    sub { $_=split(qr/1/,'A1B1C1',4); $_ == 4 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 111 if LIMIT is omitted
    sub { @_=split(qr/1/,'A1B1C1',); "@_" eq "A B C" },
    sub { $_=split(qr/1/,'A1B1C1',); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 121 or zero, trailing null fields are stripped from the result
    sub { @_=split(qr/1/,'A1B1C1',0); "@_" eq "A B C" },
    sub { $_=split(qr/1/,'A1B1C1',0); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 131 if EXPR is omitted, the function splits the $_ string
    sub { $_='A1B1C'; @_=split(qr/1/); "@_" eq "A B C" },
    sub { $_='A1B1C'; $_=split(qr/1/); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 141 if PATTERN is also omitted
    sub { $_='A B C'; @_=split(); "@_" eq "A B C" },
    sub { $_='A B C'; $_=split(); $_ == 3 },
    sub { $_='A B C'; @_=split; "@_" eq "A B C" },
    sub { $_='A B C'; $_=split; $_ == 3 },
    sub { $_=' A B C'; @_=split; "@_" eq "A B C" },
    sub { $_=' A B C'; $_=split; $_ == 3 },
    sub { $_='A  B  C'; @_=split; "@_" eq "A B C" },
    sub {1},
    sub {1},
    sub {1},
# 151
    sub { $_='A  B  C'; $_=split; $_ == 3 },
    sub { $_=' A  B  C'; @_=split; "@_" eq "A B C" },
    sub { $_=' A  B  C'; $_=split; $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 161 or is the literal space, " ", the function splits on whitespace, /\s+/, after skipping any leading whitespace
    sub { $_='A B C'; @_=split(' '); "@_" eq "A B C" },
    sub { $_='A B C'; $_=split(' '); $_ == 3 },
    sub { $_=' A B C'; @_=split(' '); "@_" eq "A B C" },
    sub { $_=' A B C'; $_=split(' '); $_ == 3 },
    sub { $_='A  B  C'; @_=split(' '); "@_" eq "A B C" },
    sub { $_='A  B  C'; $_=split(' '); $_ == 3 },
    sub { $_=' A  B  C'; @_=split(' '); "@_" eq "A B C" },
    sub {1},
    sub {1},
    sub {1},
# 171
    sub { $_=' A  B  C'; $_=split(' '); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 181 strings of any length can be split
    sub { @_=split(qr//,'WORD'); "@_" eq "W O R D" },
    sub { @_=split(qr/:/,'line1:line2:line3'); "@_" eq "line1 line2 line3" },
    sub { @_=split(" ",'  paragraph1  paragraph2  paragraph3  paragraph4  '); "@_" eq "paragraph1 paragraph2 paragraph3 paragraph4" },
    sub { @_=split(qr/^/,"A\nB\nC\nD\n"); "@_" eq "A\n B\n C\n D\n" },
    sub { @_=split(qr/^/m,"A\nB\nC\nD\n"); "@_" eq "A\n B\n C\n D\n" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 191 A pattern capable of matching either the null string or something longer
#    than the null string (for instance, a pattern consisting of any single
#    character modified by a * or ?) will split the value of EXPR into separate
#    characters wherever it matches the null string between characters; nonnull
#    matches will skip over the matched separator characters in the usual fashion.
#    (In other words, a pattern won't match in one spot more than once, even if
#    it matched with a zero width.)
    sub { $_=join(':',split(qr/ */,'hi there')); $_ eq 'h:i:t:h:e:r:e' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 201 as a trivial case, the null pattern // simply splits into separate characters, and spaces do not disappear
    sub { $_=join(':',split(qr//,'hi there')); $_ eq 'h:i: :t:h:e:r:e' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 211 The LIMIT parameter splits only part of a string
    sub { my($a,$b,$c)=split(qr/:/,'A:B:C:D:E:F',3); "$a $b $c" eq "A B C:D:E:F" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 221 when assigning to a list, if LIMIT is omitted, Perl supplies a LIMIT one
#    larger than the number of variables in the list, to avoid unnecessary work.
#    for the split above, LIMIT would have been 4 by default, and $remainder
#    would have received only the third field, not all the rest of the fields.
    sub { my($a,$b,$c)=split(qr/:/,'A:B:C:D:E:F'); "$a $b $c" eq "A B C" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 231 but if the PATTERN contains parentheses, then the substring matched by each pair of parentheses is included in the resulting list, interspersed with the fields that are ordinarily returned
    sub { @_=split(qr/([-,])/,'1-10,20'); "@_" eq "1 - 10 , 20" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 241 with more parentheses, a field is returned for each pair, even if some pairs don't match, in which case undefined values are returned in those positions
    sub { @_=split(qr/(-)|(,)/,'1-10,20'); "@_" eq "1 -  10  , 20" },
    sub { return 'SKIP' if $] =~ /^5\.006/; @_=split(qr/(-)|(,)/,'1-10,20'); not defined($_[2]) },
    sub { return 'SKIP' if $] =~ /^5\.006/; @_=split(qr/(-)|(,)/,'1-10,20'); not defined($_[4]) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 251 the /PATTERN/ argument may be replaced with an expression to specify patterns that vary at runtime
    sub { my $var='1'; @_=split($var,'A1B1C'); "@_" eq "A B C" },
    sub { for my $var (1    ) { @_=split(qr/$var/o,'A1B1C'); } "@_" eq "A B C" },
    sub { return 'SKIP' if $] =~ /^5\.006001/; for my $var (1,2  ) { @_=split(qr/$var/o,'A1B1C'); } "@_" eq "A B C" },
    sub { return 'SKIP' if $] =~ /^5\.006001/; for my $var (1,2,3) { @_=split(qr/$var/o,'A1B1C'); } "@_" eq "A B C" },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 261 as a special case, if the expression is a single space (" "), the function splits on whitespace just as split with no arguments does
    sub { $_='A B C'; @_=split(' '); "@_" eq "A B C" },
    sub { $_='A B C'; $_=split(' '); $_ == 3 },
    sub { $_=' A B C'; @_=split(' '); "@_" eq "A B C" },
    sub { $_=' A B C'; $_=split(' '); $_ == 3 },
    sub { $_='A  B  C'; @_=split(' '); "@_" eq "A B C" },
    sub { $_='A  B  C'; $_=split(' '); $_ == 3 },
    sub { $_=' A  B  C'; @_=split(' '); "@_" eq "A B C" },
    sub {1},
    sub {1},
    sub {1},
# 271
    sub { $_=' A  B  C'; $_=split(' '); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 281 in contrast, split(qr/ /) will give you as many null initial fields as there are leading spaces
    sub { $_='A B C'; @_=split(qr/ /); "@_" eq "A B C" },
    sub { $_='A B C'; $_=split(qr/ /); $_ == 3 },
    sub { $_=' A B C'; @_=split(qr/ /); "@_" eq " A B C" },
    sub { $_=' A B C'; $_=split(qr/ /); $_ == 4 },
    sub { $_='A  B  C'; @_=split(qr/ /); "@_" eq "A  B  C" },
    sub { $_='A  B  C'; $_=split(qr/ /); $_ == 5 },
    sub { $_=' A  B  C'; @_=split(qr/ /); "@_" eq " A  B  C" },
    sub { $_=' A  B  C'; $_=split(qr/ /); $_ == 6 },
    sub { my $var=' '; $_='A B C'; @_=split($var); "@_" eq "A B C" },
    sub { my $var=' '; $_='A B C'; $_=split($var); $_ == 3 },
# 291
    sub { return 'SKIP' if $] >= 5.018; my $var=' '; $_=' A B C'; @_=split($var); "@_" eq " A B C" },
    sub { return 'SKIP' if $] >= 5.018; my $var=' '; $_=' A B C'; $_=split($var); $_ == 4 },
    sub { return 'SKIP' if $] >= 5.018; my $var=' '; $_='A  B  C'; @_=split($var); "@_" eq "A  B  C" },
    sub { return 'SKIP' if $] >= 5.018; my $var=' '; $_='A  B  C'; $_=split($var); $_ == 5 },
    sub { return 'SKIP' if $] >= 5.018; my $var=' '; $_=' A  B  C'; @_=split($var); "@_" eq " A  B  C" },
    sub { return 'SKIP' if $] >= 5.018; my $var=' '; $_=' A  B  C'; $_=split($var); $_ == 6 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 301
    sub { return 'SKIP' if $] < 5.018; my $var=' '; $_=' A B C'; @_=split($var); "@_" eq "A B C" },
    sub { return 'SKIP' if $] < 5.018; my $var=' '; $_=' A B C'; $_=split($var); $_ == 3 },
    sub { return 'SKIP' if $] < 5.018; my $var=' '; $_='A  B  C'; @_=split($var); "@_" eq "A B C" },
    sub { return 'SKIP' if $] < 5.018; my $var=' '; $_='A  B  C'; $_=split($var); $_ == 3 },
    sub { return 'SKIP' if $] < 5.018; my $var=' '; $_=' A  B  C'; @_=split($var); "@_" eq "A B C" },
    sub { return 'SKIP' if $] < 5.018; my $var=' '; $_=' A  B  C'; $_=split($var); $_ == 3 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 311 you can use this property to remove leading and trailing whitespace from a string and to collapse intervening stretches of whitespace into a single space
    sub { $_=join(' ',split(' ','  s  t  r  i  n  g  ')); $_ eq 's t r i n g' },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 321 the following example splits an RFC 822 message header into a hash containing $head{Date}, $head{Subject}
#    $header =~ s/\n\s+/ /g; # Merge continuation lines.
#    %head = ("FRONTSTUFF", split /^(\S*?):\s*/m, $header);
    sub { my $header=<<'END'; $header=~s/\n\s+/ /g; my %head = ('FRONTSTUFF', split(qr/^(\S*?):\s*/m, $header)); qq(@head{'From','To','Subject','Date'}) eq qq{Alice\@example.com\n Bob\@example.com\n sample data for testing the "split" function\n 1 Apr 2020 11:22\n} },
Shift JIS
  From Wikipedia, the free encyclopedia
  Shift JIS (Shift Japanese Industrial Standards, also SJIS, MIME name Shift_JIS)
  is a character encoding for the Japanese language, originally developed by a
  Japanese company called ASCII Corporation in conjunction with Microsoft and
  standardized as JIS X 0208 Appendix 1.
From: Alice@example.com
To: Bob@example.com
Subject: sample data for testing the "split" function
Date: 1 Apr 2020 11:22
END
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
