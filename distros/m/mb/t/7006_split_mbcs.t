# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (

# 1 returning the resulting list value in list context
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b'); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 11 or the count of substrings in scalar context
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b'); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 21 if the PATTERN doesn't match the string at all, split returns the original string as a single substring
    sub {mb::eval q< @_=split(qr/‚Q/,'‚`‚P‚a‚P‚b'); "@_" eq "‚`‚P‚a‚P‚b" >},
    sub {mb::eval q< $_=split(qr/‚Q/,'‚`‚P‚a‚P‚b'); $_ == 1 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 31 if it matches once, you get two substrings,
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a'); "@_" eq "‚` ‚a" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a'); $_ == 2 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 41 and so on
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b'); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b'); $_ == 3 >},
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P‚c'); "@_" eq "‚` ‚a ‚b ‚c" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P‚c'); $_ == 4 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 51 you may supply regular expression modifiers to the PATTERN, like /PATTERN/i,
    sub {mb::eval q< @_=split(qr/a/,'‚Pa‚Qa‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/a/,'‚Pa‚Qa‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/a/i,'‚Pa‚Qa‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/a/i,'‚Pa‚Qa‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/A/i,'‚Pa‚Qa‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/A/i,'‚Pa‚Qa‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/a/i,'‚PA‚QA‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/a/i,'‚PA‚QA‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/A/i,'‚PA‚QA‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/A/i,'‚PA‚QA‚R');  $_ == 3 >},

# 61 /PATTERN/x,
    sub {mb::eval q< @_=split(qr/ a /x,'‚Pa‚Qa‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/ a /x,'‚Pa‚Qa‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/ a /ix,'‚Pa‚Qa‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/ a /ix,'‚Pa‚Qa‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/ A /ix,'‚Pa‚Qa‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/ A /ix,'‚Pa‚Qa‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/ a /ix,'‚PA‚QA‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/ a /ix,'‚PA‚QA‚R');  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/ A /ix,'‚PA‚QA‚R'); "@_" eq "‚P ‚Q ‚R" >},
    sub {mb::eval q< $_=split(qr/ A /ix,'‚PA‚QA‚R');  $_ == 3 >},

# 71 the //m modifier is assumed when you split on the pattern /^/
    sub {mb::eval q< @_=split(qr/^/,"‚`\n‚a\n‚b"); "@_" eq "‚`\n ‚a\n ‚b" >},
    sub {mb::eval q< $_=split(qr/^/,"‚`\n‚a\n‚b");  $_ == 3 >},
    sub {mb::eval q< @_=split(qr/^/m,"‚`\n‚a\n‚b"); "@_" eq "‚`\n ‚a\n ‚b" >},
    sub {mb::eval q< $_=split(qr/^/m,"‚`\n‚a\n‚b");  $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 81 if LIMIT is specified and positive, the function splits into no more than that many fields
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b',2); "@_" eq "‚` ‚a‚P‚b" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b',2); $_ == 2 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 91 (though it may split into fewer if it runs out of separators)
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b',4); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b',4); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 101 if LIMIT is negative, it is treated as if an arbitrarily large LIMIT has been specified
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b',-1); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b',-1); $_ == 3 >},
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P',4); "@_" eq "‚` ‚a ‚b " >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P',4); $_ == 4 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 111 if LIMIT is omitted
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P',); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P',); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 121 or zero, trailing null fields are stripped from the result
    sub {mb::eval q< @_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P',0); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=split(qr/‚P/,'‚`‚P‚a‚P‚b‚P',0); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 131 if EXPR is omitted, the function splits the $_ string
    sub {mb::eval q< $_='‚`‚P‚a‚P‚b'; @_=split(qr/‚P/); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚`‚P‚a‚P‚b'; $_=split(qr/‚P/); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 141 if PATTERN is also omitted
    sub {mb::eval q< $_='‚` ‚a ‚b'; @_=split(); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚` ‚a ‚b'; $_=split(); $_ == 3 >},
    sub {mb::eval q< $_='‚` ‚a ‚b'; @_=split; "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚` ‚a ‚b'; $_=split; $_ == 3 >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; @_=split; "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; $_=split; $_ == 3 >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; @_=split; "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
# 151
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; $_=split; $_ == 3 >},
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; @_=split; "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; $_=split; $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 161 or is the literal space, " ", the function splits on whitespace, /\s+/, after skipping any leading whitespace
    sub {mb::eval q< $_='‚` ‚a ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚` ‚a ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
# 171
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 181 strings of any length can be split
    sub {mb::eval q< @_=split(qr//,'‚v‚n‚q‚c'); "@_" eq "‚v ‚n ‚q ‚c" >},
    sub {mb::eval q< @_=split(qr/:/,'‚Œ‚‰‚Ž‚…‚P:‚Œ‚‰‚Ž‚…‚Q:‚Œ‚‰‚Ž‚…‚R'); "@_" eq "‚Œ‚‰‚Ž‚…‚P ‚Œ‚‰‚Ž‚…‚Q ‚Œ‚‰‚Ž‚…‚R" >},
    sub {mb::eval q< @_=split(" ",'  ‚‚‚’‚‚‡‚’‚‚‚ˆ‚P  ‚‚‚’‚‚‡‚’‚‚‚ˆ‚Q  ‚‚‚’‚‚‡‚’‚‚‚ˆ‚R  ‚‚‚’‚‚‡‚’‚‚‚ˆ‚S  '); "@_" eq "‚‚‚’‚‚‡‚’‚‚‚ˆ‚P ‚‚‚’‚‚‡‚’‚‚‚ˆ‚Q ‚‚‚’‚‚‡‚’‚‚‚ˆ‚R ‚‚‚’‚‚‡‚’‚‚‚ˆ‚S" >},
    sub {mb::eval q< @_=split(qr/^/,"‚`\n‚a\n‚b\n‚c\n"); "@_" eq "‚`\n ‚a\n ‚b\n ‚c\n" >},
    sub {mb::eval q< @_=split(qr/^/m,"‚`\n‚a\n‚b\n‚c\n"); "@_" eq "‚`\n ‚a\n ‚b\n ‚c\n" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 191 A pattern capable of matching either the null string or something longer
#    than the null string (for instance, a pattern consisting of any single
#    character modified by a * or ?) will split the value of EXPR into separate
#    characters wherever it matches the null string between characters; nonnull
#    matches will skip over the matched separator characters in the usual fashion.
#    (In other words, a pattern won't match in one spot more than once, even if
#    it matched with a zero width.)
    sub {mb::eval q< $_=join(':',split(qr/ */,'‚ˆ‚‰ ‚”‚ˆ‚…‚’‚…')); $_ eq '‚ˆ:‚‰:‚”:‚ˆ:‚…:‚’:‚…' >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 201 as a trivial case, the null pattern // simply splits into separate characters, and spaces do not disappear
    sub {mb::eval q< $_=join(':',split(qr//,'‚ˆ‚‰ ‚”‚ˆ‚…‚’‚…')); $_ eq '‚ˆ:‚‰: :‚”:‚ˆ:‚…:‚’:‚…' >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 211 The LIMIT parameter splits only part of a string
    sub {mb::eval q< my($a,$b,$c)=split(qr/:/,'‚`:‚a:‚b:‚c:‚d:‚e',3); "$a $b $c" eq "‚` ‚a ‚b:‚c:‚d:‚e" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 221 when assigning to a list, if LIMIT is omitted, Perl supplies a LIMIT one
#    larger than the number of variables in the list, to avoid unnecessary work.
#    for the split above, LIMIT would have been 4 by default, and $remainder
#    would have received only the third field, not all the rest of the fields.
    sub {mb::eval q< my($a,$b,$c)=split(qr/:/,'‚`:‚a:‚b:‚c:‚d:‚e'); "$a $b $c" eq "‚` ‚a ‚b" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 231 but if the PATTERN contains parentheses, then the substring matched by each pair of parentheses is included in the resulting list, interspersed with the fields that are ordinarily returned
    sub {local $^W=0; mb::eval q< @_=split(qr/([-,])/,'‚P-‚P‚O,‚Q‚O'); "@_" eq "‚P - ‚P‚O , ‚Q‚O" >},
    sub {mb::eval q< @_=split(qr/([|C])/,'‚P|‚P‚OC‚Q‚O'); "@_" eq "‚P | ‚P‚O C ‚Q‚O" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 241 with more parentheses, a field is returned for each pair, even if some pairs don't match, in which case undefined values are returned in those positions
    sub {mb::eval q< @_= map { defined($_) ? $_ : '' } split(qr/(-)|(,)/,'‚P-‚P‚O,‚Q‚O'); "@_" eq "‚P -  ‚P‚O  , ‚Q‚O" >},
    sub {mb::eval q< return 'SKIP' if $] =~ /^5\.006/; @_=split(qr/(-)|(,)/,'‚P-‚P‚O,‚Q‚O'); not(defined($_[2])) >},
    sub {mb::eval q< return 'SKIP' if $] =~ /^5\.006/; @_=split(qr/(-)|(,)/,'‚P-‚P‚O,‚Q‚O'); not(defined($_[4])) >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 251 the /PATTERN/ argument may be replaced with an expression to specify patterns that vary at runtime
    sub {mb::eval q< my $var='‚P'; @_=split($var,'‚`‚P‚a‚P‚b'); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< for my $var ('‚P'    ) { @_=split(qr/$var/o,'‚`‚P‚a‚P‚b'); } "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< return 'SKIP' if $] =~ /^5\.006001/; for my $var ('‚P','‚Q'  ) { @_=split(qr/$var/o,'‚`‚P‚a‚P‚b'); } "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< return 'SKIP' if $] =~ /^5\.006001/; for my $var ('‚P','‚Q','‚R') { @_=split(qr/$var/o,'‚`‚P‚a‚P‚b'); } "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 261 as a special case, if the expression is a single space (" "), the function splits on whitespace just as split with no arguments does
    sub {mb::eval q< $_='‚` ‚a ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚` ‚a ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; @_=split(' '); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
# 271
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; $_=split(' '); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 281 in contrast, split(qr/ /) will give you as many null initial fields as there are leading spaces
    sub {mb::eval q< $_='‚` ‚a ‚b'; @_=split(qr/ /); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< $_='‚` ‚a ‚b'; $_=split(qr/ /); $_ == 3 >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; @_=split(qr/ /); "@_" eq " ‚` ‚a ‚b" >},
    sub {mb::eval q< $_=' ‚` ‚a ‚b'; $_=split(qr/ /); $_ == 4 >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; @_=split(qr/ /); "@_" eq "‚`  ‚a  ‚b" >},
    sub {mb::eval q< $_='‚`  ‚a  ‚b'; $_=split(qr/ /); $_ == 5 >},
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; @_=split(qr/ /); "@_" eq " ‚`  ‚a  ‚b" >},
    sub {mb::eval q< $_=' ‚`  ‚a  ‚b'; $_=split(qr/ /); $_ == 6 >},
    sub {mb::eval q< my $var=' '; $_='‚` ‚a ‚b'; @_=split($var); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< my $var=' '; $_='‚` ‚a ‚b'; $_=split($var); $_ == 3 >},
# 291
    sub {mb::eval q< return 'PASS'; my $var=' '; $_=' ‚` ‚a ‚b'; @_=split($var); "@_" eq " ‚` ‚a ‚b" >},
    sub {mb::eval q< return 'PASS'; my $var=' '; $_=' ‚` ‚a ‚b'; $_=split($var); $_ == 4 >},
    sub {mb::eval q< return 'PASS'; my $var=' '; $_='‚`  ‚a  ‚b'; @_=split($var); "@_" eq " ‚`  ‚a  ‚b" >},
    sub {mb::eval q< return 'PASS'; my $var=' '; $_='‚`  ‚a  ‚b'; $_=split($var); $_ == 5 >},
    sub {mb::eval q< return 'PASS'; my $var=' '; $_=' ‚`  ‚a  ‚b'; @_=split($var); "@_" eq " ‚`  ‚a  ‚b" >},
    sub {mb::eval q< return 'PASS'; my $var=' '; $_=' ‚`  ‚a  ‚b'; $_=split($var); $_ == 6 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
# 301
    sub {mb::eval q< my $var=' '; $_=' ‚` ‚a ‚b'; @_=split($var); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< my $var=' '; $_=' ‚` ‚a ‚b'; $_=split($var); $_ == 3 >},
    sub {mb::eval q< my $var=' '; $_='‚`  ‚a  ‚b'; @_=split($var); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< my $var=' '; $_='‚`  ‚a  ‚b'; $_=split($var); $_ == 3 >},
    sub {mb::eval q< my $var=' '; $_=' ‚`  ‚a  ‚b'; @_=split($var); "@_" eq "‚` ‚a ‚b" >},
    sub {mb::eval q< my $var=' '; $_=' ‚`  ‚a  ‚b'; $_=split($var); $_ == 3 >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 311 you can use this property to remove leading and trailing whitespace from a string and to collapse intervening stretches of whitespace into a single space
    sub {mb::eval q< $_=join(' ',split(' ','  ‚“  ‚”  ‚’  ‚‰  ‚Ž  ‚‡  ')); $_ eq '‚“ ‚” ‚’ ‚‰ ‚Ž ‚‡' >},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},

# 321 the following example splits an RFC 822 message header into a hash containing $head{Date}, $head{Subject}
#    $header =~ s/\n\s+/ /g; # Merge continuation lines.
#    %head = ("FRONTSTUFF", split /^(\S*?):\s*/m, $header);
    sub {mb::eval <<'END_EVAL' },
my $header=<<'END'; $header=~s/\n\s+/ /g; my %head = ('FRONTSTUFF', split(qr/^(\S*?):\s*/m, $header)); qq(@head{'‚e‚’‚‚','‚s‚','‚r‚•‚‚‚Š‚…‚ƒ‚”','‚c‚‚”‚…'}) eq qq{‚`‚Œ‚‰‚ƒ‚…—‚…‚˜‚‚‚‚Œ‚…D‚ƒ‚‚\n ‚a‚‚‚—‚…‚˜‚‚‚‚Œ‚…D‚ƒ‚‚\n ‚“‚‚‚‚Œ‚…@‚„‚‚”‚@‚†‚‚’@‚”‚…‚“‚”‚‰‚Ž‚‡@‚”‚ˆ‚…@h‚‚‚FFQ‚“‚‚Œ‚‰‚”h@‚†‚•‚Ž‚ƒ‚”‚‰‚‚Ž\n ‚P@‚`‚‚’@‚Q‚O‚Q‚O@‚P‚PF‚Q‚Q\n}
‚r‚ˆ‚‰‚†‚”@‚i‚h‚r
@@‚e‚’‚‚@‚v‚‰‚‹‚‰‚‚…‚„‚‰‚C@‚”‚ˆ‚…@‚†‚’‚…‚…@‚…‚Ž‚ƒ‚™‚ƒ‚Œ‚‚‚…‚„‚‰‚
@@‚r‚ˆ‚‰‚†‚”@‚i‚h‚r@i‚r‚ˆ‚‰‚†‚”@‚i‚‚‚‚Ž‚…‚“‚…@‚h‚Ž‚„‚•‚“‚”‚’‚‰‚‚Œ@‚r‚”‚‚Ž‚„‚‚’‚„‚“C@‚‚Œ‚“‚@‚r‚i‚h‚rC@‚l‚h‚l‚d@‚Ž‚‚‚…@‚r‚ˆ‚‰‚†‚”Q‚i‚h‚rj
@@‚‰‚“@‚@‚ƒ‚ˆ‚‚’‚‚ƒ‚”‚…‚’@‚…‚Ž‚ƒ‚‚„‚‰‚Ž‚‡@‚†‚‚’@‚”‚ˆ‚…@‚i‚‚‚‚Ž‚…‚“‚…@‚Œ‚‚Ž‚‡‚•‚‚‡‚…C@‚‚’‚‰‚‡‚‰‚Ž‚‚Œ‚Œ‚™@‚„‚…‚–‚…‚Œ‚‚‚…‚„@‚‚‚™@‚
@@‚i‚‚‚‚Ž‚…‚“‚…@‚ƒ‚‚‚‚‚Ž‚™@‚ƒ‚‚Œ‚Œ‚…‚„@‚`‚r‚b‚h‚h@‚b‚‚’‚‚‚’‚‚”‚‰‚‚Ž@‚‰‚Ž@‚ƒ‚‚Ž‚Š‚•‚Ž‚ƒ‚”‚‰‚‚Ž@‚—‚‰‚”‚ˆ@‚l‚‰‚ƒ‚’‚‚“‚‚†‚”@‚‚Ž‚„
@@‚“‚”‚‚Ž‚„‚‚’‚„‚‰‚š‚…‚„@‚‚“@‚i‚h‚r@‚w@‚O‚Q‚O‚W@‚`‚‚‚…‚Ž‚„‚‰‚˜@‚PD
‚e‚’‚‚: ‚`‚Œ‚‰‚ƒ‚…—‚…‚˜‚‚‚‚Œ‚…D‚ƒ‚‚
‚s‚: ‚a‚‚‚—‚…‚˜‚‚‚‚Œ‚…D‚ƒ‚‚
‚r‚•‚‚‚Š‚…‚ƒ‚”: ‚“‚‚‚‚Œ‚…@‚„‚‚”‚@‚†‚‚’@‚”‚…‚“‚”‚‰‚Ž‚‡@‚”‚ˆ‚…@h‚‚‚FFQ‚“‚‚Œ‚‰‚”h@‚†‚•‚Ž‚ƒ‚”‚‰‚‚Ž
‚c‚‚”‚…: ‚P@‚`‚‚’@‚Q‚O‚Q‚O@‚P‚PF‚Q‚Q
END
END_EVAL
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
    sub {mb::eval q<1>},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
