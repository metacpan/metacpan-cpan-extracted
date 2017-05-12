#! /usr/bin/perl -Tw

use v5.10; use strict; use warnings;
use Test::More; BEGIN { eval { require Test::NoWarnings } };
*had_no_warnings='Test::NoWarnings'->can('had_no_warnings')||sub{pass"skip: no warnings"};

plan tests => 130; # was: 3*(4+2+7+8+6+2)*3; #261

#use Regexp::Wildcards;
use Text::Glob::DWIW ':all';
local $| = 1;


sub try {
 my ($s, $x, $y) = @_;
 $y = $x unless defined $y;
 #my $d = $rw->{do};
 #$d = join ' ', keys %$d if ref($d) eq 'HASH';
 is(tg_re($x),        qr/^(?:$y)\z/s,     "$s (pure)"); # 'ab'.$y
 is(tg_re('ab'.$x),   qr/^(?:ab$y)\z/s,   "$s (begin)"); # 'ab'.$y
 is(tg_re('a'.$x.'b'),qr/^(?:a${y}b)\z/s, "$s (middle)"); # 'a'.$y.'b'
 is(tg_re($x . 'ab'), qr/^(?:${y}ab)\z/s, "$s (end)"); # $y.'ab'
}


my $sec='simple'; my $p;  # Simple

 try  "$sec *", '*', '.*?'; #
 try  "$sec ?", '?', '.';

 is(tg_re('?*ab'), qr/^(?:..*?ab)\z/s, #'..*ab',
    "$sec ? and * (begin)");
 is(tg_re('?a*b'), qr/^(?:.a.*?b)\z/s, #'.a.*b',
    "$sec ? and * (middle)");
 is(tg_re('?ab*'), qr/^(?:.ab.*?)\z/s, #'.ab.*',
    "$sec ? and * (end)");

 is(tg_re('*ab?'), qr/^(?:.*?ab.)\z/s, #'.*ab.',
    "simple * and ? (begin)");
 is(tg_re('a*b?'), qr/^(?:a.*?b.)\z/s, #'a.*b.',
    "simple * and ? (middle)");
 is(tg_re('ab*?'), qr/^(?:ab.*?.)\z/s, #'ab.*.',
    "simple * and ? (end)");

$sec='multiple';  # Multiple

 try  "multiple *", '**', '.*?'; # '.*' single instance fits but other reasons
 try  "multiple ?", '??', '..';

 # Captures

 #$rw->capture('single');
 #try  "multiple capturing $one", $one.$one.'\\'.$one.$one,
 #                                   '(.)(.)\\'.$one.'(.)';

 #$rw->capture(add => [ qw<any greedy> ]);
 #try  "multiple capturing $any (greedy)", $any.$any.'\\'.$any.$any,
 #                                             '(.*)\\'.$any.'(.*)';
 #my $wc = $any.$any.$one.$one.'\\'.$one.$one.'\\'.$any.$any;
 #try  "multiple capturing $any (greedy) and capturing $one",
 #         $wc, '(.*)(.)(.)\\'.$one.'(.)\\'.$any.'(.*)';

 #$rw->capture(set => [ qw<any greedy> ]);
 #try  "multiple capturing $any (greedy) and non-capturing $one",
 #         $wc, '(.*)..\\'.$one.'.\\'.$any.'(.*)';

 #$rw->capture(rem => 'greedy');
 #try  "multiple capturing $any (non-greedy)", $any.$any.'\\'.$any.$any,
 #                                                '(.*?)\\'.$any.'(.*?)';
 #try  "multiple capturing $any (non-greedy) and non-capturing $one",
 #         $wc, '(.*?)..\\'.$one.'.\\'.$any.'(.*?)';

 #$rw->capture({ single => 1, any => 1 });
 #try  "multiple capturing $any (non-greedy) and capturing $one",
 #         $wc, '(.*?)(.)(.)\\'.$one.'(.)\\'.$any.'(.*?)';

 #$rw->capture();

$sec="escaping"; # Escaping

 try  "escaping *", '\\*'; #qr/^(?:\*)\z/s; #'\\*';
 try  "escaping * before intermediate newline", "\\*\n\\*"; # [x] hmm the NL is esc.?
 try  "escaping ?", '\\?';
 try  "escaping ? before intermediate newline", "\\?\n\\?"; # [x]
 try  "escaping \\\\\\*", '\\\\\\*';
 try  "escaping \\\\\\?", '\\\\\\?';
 try  "not escaping \\\\*", '\\\\*', '\\\\.*?';
 try  "not escaping \\\\?", '\\\\?', '\\\\.';

 # Escaping escapes

 try  'escaping \\', '\\', '\\\\';
 try  'not escaping \\', '\\\\', '\\\\';
 try  'escaping \\ before intermediate newline', "\\\n\\", "\\\\\n\\\\"; # [x]
 try  'not escaping \\ before intermediate newline', "\\\\\n\\\\", "\\\\\n\\\\";
 try  'escaping regex characters', '()', '\\(\\)';
 try  'not escaping escaped regex characters', '\\\\\\(\\)';

 # Mixed

 try  "mixed * and \\*", '*\\**', '.*?\\*.*?';
 try  "mixed ? and \\?", '?\\??', '.\\?.';

 # --------------------------------------------------------------------------

#is(tg_re('a\\,b\\\\\\,c'), qr/^(?:a\\,b\\\\\\,c)\z/s, #'a\\,b\\\\\\,c',
#   'unix: commas outside of brackets 2');
#is(tg_re(',a,b,c\\\\,'), '\\,a\\,b\\,c\\\\\\,', ',a,b\\\\,' '\\,a,b\\\\\\,'
#   'unix: commas outside of brackets at begin/end'); # no special for us
#is(tg_re('a,b\\\\,c'), '(?:a|b\\\\|c)', 'win32: commas');
#is(tg_re('a\\,b\\\\,c'), '(?:a\\,b\\\\|c)', 'win32: escaped commas 1');
#is(tg_re('a\\,b\\\\\\,c'), 'a\\,b\\\\\\,c', 'win32: escaped commas 2');
#is(tg_re(',a,b\\\\,'), '(?:|a|b\\\\|)', 'win32: commas at begin/end');
#is(tg_re('\\,a,b\\\\\\,'), '(?:\\,a|b\\\\\\,)',
#   'win32: escaped commas at begin/end');

for my $ident ('a\\,b\\\\\\,c', 'a\\,b\\\\\\,c', '\\,a\\,b\\,c\\\\\\,')
  { is tg_re($ident), qr/^(?:$ident)\z/s, 'some comma stuff'; }

for my $ident ('a,b\\\\,c', 'a\\,b\\\\,c', ',a,b\\\\,', '\\,a,b\\\\\\,')
{ #is tg_re($ident), qr/^(?:$ident)\z/s, "some comma stuff: '$ident'";
  $sec='comma'; # no change in meaning -v- of RE, let quotemeta overreact for now
  (my $variant=$ident)=~s/((?:^|[^\\])(?:\\\\)*),/$1\\,/g;
  my $re=tg_re($ident); ok $re eq qr/^(?:$ident)\z/s || $re eq qr/^(?:$variant)\z/s, "$sec: $ident";
}

is tg_re('{a\\,b\\\\\\,c}'), qr/^(?:a\,b\\\,c)\z/s,'esc&,';
is tg_re('{,a,b,c\\\\,}'),   qr/^(?:|a|b|c\\|)\z/s,'esc&,';
is tg_re('{a,b\\\\,c}'),     qr/^(?:a|b\\|c)\z/s,  'esc&,';
is tg_re('{a\\,b\\\\,c}'),   qr/^(?:a\,b\\|c)\z/s, 'escaped commas 1';
is tg_re('{a\\,b\\\\\\,c}'), qr/^(?:a\,b\\\,c)\z/s,'escaped commas 2';
is tg_re('{,a,b\\\\,}'),     qr/^(?:|a|b\\|)\z/s,  'commas at begin/end';
is tg_re('{\\,a,b\\\\\\,}'), qr/^(?:\,a|b\\\,)\z/s,'escd , at begin/end';

 # --------------------------------------------------------------------------

#is(tg_re('a{b\\\\,c\\\\}d', 'jokers'), 'a\\{b\\\\\\,c\\\\\\}d','jokers');
#is(tg_re('a{b\\\\,c\\\\}d', 'sql'), 'a\\{b\\\\\\,c\\\\\\}d', 'sql');
is tg_re('a{b\\\\,c\\\\}d',{rewrite=>0}), qr/^(?:ab\\d|ac\\d)\z/s; #'(?:a\\{b\\\\|c\\\\\\}d)';
is tg_re('a{b\\\\,c\\\\}d',{rewrite=>1}), qr/^(?:a(?:b\\|c\\)d)\z/s; #'(?:a\\{b\\\\|c\\\\\\}d)','win32');

is(tg_re($p='{}'),      qr/^(?:)\z/s,      "empty brackets $p"); #'(?:)'
is(tg_re($p='{a}'),     qr/^(?:a)\z/s,     "brackets 1 $p");     # '(?:a)'
is(tg_re($p='{a,b}'),   qr/^(?:a|b)\z/s,   "brackets 2 $p");     # '(?:a|b)'
is(tg_re($p='{a,b,c}'), qr/^(?:a|b|c)\z/s, "brackets 3 $p");     # '(?:a|b|c)'

is(tg_re($p='a{b,c}d',{rewrite=>0}), qr/^(?:abd|acd)\z/s, "1 bracketed block $p");
is(tg_re($p='a{b,c}d',{rewrite=>1}), qr/^(?:a(?:b|c)d)\z/s, #'a(?:b|c)d',
   "1 bracketed block $p");
is(tg_re($p='a{b,c}d{e,,f}',{rewrite=>0}), qr/^(?:abde|abd|abdf|acde|acd|acdf)\z/s, #'a(?:b|c)d(?:e||f)',
   "2 bracketed blocks $p");
is(tg_re($p='a{b,c}d{e,,f}',{rewrite=>1}), qr/^(?:a(?:b|c)d(?:e||f))\z/s, #'a(?:b|c)d(?:e||f)',
   "2 bracketed blocks $p");
#is(tg_re('a{b,c}d{e,,f}{g,h,}'), 'a(?:b|c)d(?:e||f)(?:g|h|)',
#   '3 bracketed blocks'); # write a expansion test instead

#is(tg_re('{a{b}}',{rewrite=>0}), qr/^(?:ab)\z/s, #'(?:a(?:b))',
#   '2 nested bracketed blocks 1');
is(tg_re('{a{b}}'), qr/^(?:ab)\z/s, #'(?:a(?:b))',
   '2 nested bracketed blocks 1');
is(tg_re('{a,{b},c}'), qr/^(?:a|b|c)\z/s, #'(?:a|(?:b)|c)',
   '2 nested bracketed blocks 2');
is(tg_re('{a,{b{d}e},c}'), qr/^(?:a|bde|c)\z/s, #'(?:a|(?:b(?:d)e)|c)',
   '3 nested bracketed blocks');
is(tg_re('{a,{b{d{}}e,f,,},c}',{rewrite=>1}), qr/^(?:a|(?:bde|f||)|c)\z/s,
   '4 nested bracketed blocks');   #'(?:a|(?:b(?:d(?:))e|f||)|c)',
is(tg_re('{a,{b{d{}}e,f,,},c}',{rewrite=>0}), qr/^(?:a|bde|f|||c)\z/s,
   '4 nested bracketed blocks');   #'(?:a|(?:b(?:d(?:))e|f||)|c)',
#is(tg_re('{a,{b{d{}}e,f,,},c}{,g{{}h,i}}'), qr/^(?:...)\z/s,
##'(?:a|(?:b(?:d(?:))e|f||)|c)(?:|g(?:(?:)h|i))',
#   '4+3 nested bracketed blocks'); # most likely correct, but i don't walk through mentally.

is(tg_re('\\{\\\\}'),           qr/^(?:\{\\\})\z/s, #'\\{\\\\\\}',
   'escaping brackets');
is(tg_re('\\{a,b,c\\\\\\}'),    qr/^(?:\{a\,b\,c\\\})\z/s, #'\\{a\\,b\\,c\\\\\\}',
   'escaping commas 1');
is(tg_re('\\{a\\\\,b\\,c}'),    qr/^(?:\{a\\\,b\,c\})\z/s, #'\\{a\\\\\\,b\\,c\\}',
   'escaping commas 2');
is(tg_re('\\{a\\\\,b\\,c\\}'),  qr/^(?:\{a\\\,b\,c\})\z/s, 'escaping commas 3');
is(tg_re('\\{a\\\\,b\\,c\\\\}'),qr/^(?:\{a\\\,b\,c\\\})\z/s, #'\\{a\\\\\\,b\\,c\\\\\\}',
   'escaping brackets and commas');

is(tg_re('{a\\},b\\{,c}'), qr/^(?:a\}|b\{|c)\z/s, #'(?:a\\}|b\\{|c)',
   'overlapping brackets');
#is(tg_re('{a\\{b,c}d,e}'), '(?:a\\{b|c)d\\,e\\}',
#   'partial unbalanced catching 1');
#is(tg_re('{a\\{\\\\}b,c\\\\}'), qr/^(?:a\{\\\}b\,c\\\})\z/s, #'(?:a\\{\\\\)b\\,c\\\\\\}',
#   'partial unbalanced catching 2');
is tg_re($p='{a{b,c\\}d,e}}',{rewrite=>0}), qr/^(?:ab|ac\}d|ae)\z/s,"not quoted opening: $p"; # r
is tg_re($p='{a{b,c\\}d,e}}',{rewrite=>1}), qr/^(?:a(?:b|c\}d|e))\z/s,"not quoted opening: $p"; # r
is(tg_re('{a{b,c\\}d,e}',{rewrite=>0}), qr/^(?:\{ab|\{ac\}d|\{ae)\z/s,
   'no partial unbalanced catching');
is(tg_re('{a{b,c\\}d,e}',{rewrite=>1}), qr/^(?:\{a(?:b|c\}d|e))\z/s,
   'no partial unbalanced catching');
# was: qr/^(?:\{a\{b\,c\}d\,e\})\z/s, #'\\{a\\{b\\,c\\}d\\,e\\}',
is(tg_re('{a,\\{,\\},b}'), qr/^(?:a|\{|\}|b)\z/s, 'substituting commas 1');
is(tg_re('{a,\\{d,e,,\\}b,c}'), qr/^(?:a|\{d|e||\}b|c)\z/s, #'(?:a|\\{d|e||\\}b|c)',
   'substituting commas 2');
is(tg_re('{a,\\{d,e,,\\}b,c}\\\\{f,g,h,i}',{rewrite=>0}),
qr/^(?:a\\f|a\\g|a\\h|a\\i|\{d\\f|\{d\\g|\{d\\h|\{d\\i|e\\f|e\\g|e\\h|e\\i|\\f|\\g|\\h|\\i|\}b\\f|\}b\\g|\}b\\h|\}b\\i|c\\f|c\\g|c\\h|c\\i)\z/s,  'handling the rest');
is(tg_re('{a,\\{d,e,,\\}b,c}\\\\{f,g,h,i}',{rewrite=>1}),
   qr/^(?:(?:a|\{d|e||\}b|c)\\(?:f|g|h|i))\z/s,
   'handling the rest');                       #'(?:a|\\{d|e||\\}b|c)\\\\(?:f|g|h|i)',

had_no_warnings();