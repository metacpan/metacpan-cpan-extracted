#!/usr/local/bin/perl

use warnings;
use strict;
use lib qw(../blib/lib);

use Text::BibTeX::BibStyle;
use Test::More;

$ENV{BIBSTYLE} = "bibstyle";

# The entries have the format:
#      test/function name, code, expected stack, expected warnings,
#      predefs, expected outputs
my @tests =
    (
     [numbers        => '#3 #1 #4', '#3 #1 #4'],
     [strings        => qq("foo" "bar baz"), '"foo" "bar baz"'],
     [quotes         => qq(\'foo \'bar), "'foo 'bar"],

     [predefs        => q(sort.key$ entry.max$ crossref global.max$ ),
      'missing #100 missing #1000'],
     ['>'            => '#3 #1 > #1 #4 > #-2 #-2 > "a" "b" >',
      '#1 #0 #0 #0', << 'EOW'
>, 1: Argument 1 of '>' has wrong type ("b")
>, 1: Argument 2 of '>' has wrong type ("a")
EOW
      ],
     ['<'            => '#3 #1 < #1 #4 < #-2 #-2 < "a" "b" <',
      '#0 #1 #0 #0', << 'EOW'
<, 1: Argument 1 of '<' has wrong type ("b")
<, 1: Argument 2 of '<' has wrong type ("a")
EOW
      ],
     ['='            => << 'EOT',
#3 #1 = 
#-2 #-2 = 
"abc" "cba" = 
"def" quote$ * duplicate$ =
#2 "ghi" =
"jkl" #-1 =
EOT
      '#0 #1 #0 #1 #0 #0', << 'EOW',
# =, 5: Argument 2 of '=' has wrong type (#2)
# =, 6: Argument 2 of '=' has wrong type ("jkl")
EOW
      ],
     ['+'            => << 'EOT', 
#3 #1 + #1 #4 + #-2 #-2 +
"a" "b" +
EOT
      '#4 #5 #-4 #0', << 'EOW'
+, 2: Argument 1 of '+' has wrong type ("b")
+, 2: Argument 2 of '+' has wrong type ("a")
EOW
      ],
     ['-'            => << 'EOT', 
#3 #1 - #1 #4 - #-2 #-2 -
"a" "b" -
EOT
      '#2 #-3 #0 #0', << 'EOW'
-, 2: Argument 1 of '-' has wrong type ("b")
-, 2: Argument 2 of '-' has wrong type ("a")
EOW
      ],
     ['*'            => q(quote$ "foo" #10 int.to.chr$ "bar" quote$ * * * *),
                        qq(""foo\nbar"")],

     [':='           => << "EOT", 
# \#3 'a := a 
# #1 'b := #4 'c := b c 
# "Hi, there" 's := s
# "Error" s :=
# #2 'undef :=
EOT
      '#3 #1 #4 "Hi, there"', <<'EOW', <<'EOP'
:=, 4: Argument 1 of ':=' has wrong type ("Hi, there")
:=, 5: Undefined variable 'undef'
EOW
INTEGERS { a b c }
STRINGS { s t }
EOP
      ],
     ['add.period$'  => << 'EOT',
"Foo" add.period$ "Bar?" add.period$ 
"Ba{z.}" add.period$ "Bletch{!}" add.period$
#1 add.period$
EOT
 '"Foo." "Bar?" "Ba{z.}" "Bletch{!}" ""', <<'EOW', 
# add.period$, 3: Argument 1 of 'add.period$' has wrong type (#1)
EOW
      ],
     ['call.type$'     => 'call.type$', '', << 'EOW'],
# call.type$, 1: No current entry in function 'call.type$'
EOW
     ['change.case$'   => << 'EOT', 
"FOO Bear {CMO{S}}: The Tragic Story of {Foo}" 's := 
s "t" change.case$
s "l" change.case$
s "u" change.case$
s "q" change.case$
#1 #2 change.case$
EOT
  #'
      join(' ',('"Foo bear {CMO{S}}: The tragic story of {Foo}"',
		'"foo bear {CMO{S}}: the tragic story of {Foo}"',
		'"FOO BEAR {CMO{S}}: THE TRAGIC STORY OF {Foo}"',
		'"FOO Bear {CMO{S}}: The Tragic Story of {Foo}"',
		'""')), <<'EOW', 'STRINGS { s }',
# change.case$, 5: Argument 1 of 'change.case$' has illegal specification (q)
# change.case$, 6: Argument 1 of 'change.case$' has wrong type (#2)
# change.case$, 6: Argument 2 of 'change.case$' has wrong type (#1)
EOW
      ],
     ['chr.to.int$'  => <<'EOT',
"a" chr.to.int$ "A" chr.to.int$ 
#1 chr.to.int$
"Error" chr.to.int$
EOT
      '#97 #65 #0 #0', <<'EOW', 
# chr.to.int$, 2: Argument 1 of 'chr.to.int$' has wrong type (#1)
# chr.to.int$, 3: Argument 1 to 'chr.to.int$' must be a single character
EOW
      ],
     ['cite$'        => 'cite$', '""', << 'EOW'],
# cite$, 1: No current entry in function 'cite$'
EOW
     ['duplicate$'   => qq("a" duplicate\$ \#2 duplicate\$ \'v duplicate\$),
                        qq("a" "a" \#2 \#2 \'v \'v)],

     ['empty$'       => << 'EOT', '#0 #1 #1 #1 #0 #1',
"a" empty$ 
" 	" empty$ 
s empty$ 
es empty$ 
"b" 'es := es empty$
f empty$
EOT
 #'
      undef, q(STRINGS { s } ENTRY {f} {} {es})],

     ['format.name$' => << 'EOT', << 'EOE', << 'EOW', << 'EOP'
# "Charles {L}ouis Xavier Joseph de l\'{a} Vall{\'e}e Poussin and {\OE}dipus Rex and Mickey M. Mouse and {Steele Jr.}, Guy and Ford-Chrysler, Jr., Henry and {ATT, Inc.} and others" 'name :=
# "{ff~}{vv~}{ll}{, jj}" format.names
# "{vv~~}{ll}{, jj}{, f.}" format.names
# "{v{}}{l{}}?" format.names
# "{f.~}{vv~}{ll}{, jj}" format.names
#1 "foo" #2 format.name$
EOT
"{ff~}{vv~}{ll}{, jj}" "Charles~{L}ouis Xavier~Joseph de~l\'{a} Vall{\'e}e Poussin" "{\OE}dipus Rex" "Mickey~M. Mouse" "Guy {Steele Jr.}" "Henry Ford-Chrysler, Jr." "{ATT, Inc.}" "others" "
" "{vv~~}{ll}{, jj}{, f.}" "de~l\'{a} Vall{\'e}e Poussin, C. {L}. X. J." "Rex, {\OE}." "Mouse, M. M." "{Steele Jr.}, G." "Ford-Chrysler, Jr., H." "{ATT, Inc.}" "others" "
" "{v{}}{l{}}?" "dl VP?" "R?" "M?" "{S}?" "FC?" "{A}?" "o?" "
" "{f.~}{vv~}{ll}{, jj}" "C.~{L}. X.~J. de~l\'{a} Vall{\'e}e Poussin" "{\OE}.~Rex" "M.~M. Mouse" "G.~{Steele Jr.}" "H.~Ford-Chrysler, Jr." "{ATT, Inc.}" "others" "
" ""
EOE
# format.name$, 6: Argument 1 of 'format.name$' has wrong type (#2)
# format.name$, 6: Argument 2 of 'format.name$' has wrong type ("foo")
# format.name$, 6: Argument 3 of 'format.name$' has wrong type (#1)
EOW
# FUNCTION { format.names } {
#   'format := format
#   name num.names$ 'name.cnt :=
#   #0 'cnt :=
#   { #1 cnt #1 + 'cnt := cnt name.cnt > - }
#   { name cnt format format.name$ } while$
#   #10 int.to.chr$
# }
# INTEGERS { cnt name.cnt }
# STRINGS { format name }
EOP
      ],
     ['if$'          => <<'EOT', '"Hi" "there" "fans"',
#2  { "Hi" }   { "Low" }  if$
#0  { "here" } 'there     if$
#-1 'blowers   { "fans" } if$
"a" #3         #4         if$
EOT
      <<'EOW', 'FUNCTION {there} { "there" }',
# if$, 4: Argument 1 of 'if$' has wrong type (#4)
# if$, 4: Argument 2 of 'if$' has wrong type (#3)
# if$, 4: Argument 3 of 'if$' has wrong type ("a")
EOW
      ],
     ['int.to.chr$'  => <<'EOT',
#66 int.to.chr$ 
#98 int.to.chr$
"s" int.to.chr$
EOT
      '"B" "b" ""', << 'EOW'
int.to.chr$, 3: Argument 1 of 'int.to.chr$' has wrong type ("s")
EOW
      ],
     ['int.to.str$'  => << 'EOT',
#66 int.to.str$
#98 int.to.str$
"c" int.to.str$
EOT
      '"66" "98" ""', << 'EOW'
int.to.str$, 3: Argument 1 of 'int.to.str$' has wrong type ("c")
EOW
      ],
     ['missing$'       => << 'EOT', '#0 #0 #1 #1 #0 #1 #0',
"a" missing$ 
" 	" missing$ 
s missing$ 
es missing$ 
"b" 'es := es missing$
f missing$
#1 missing$
EOT
 #'
      << 'EOW', q(STRINGS { s } ENTRY {f} {} {es}),
# missing$, 7: Argument 1 of 'missing$' has wrong type (#1)
EOW
      ],
     ['newline$'     => q(newline$ ), '', '', '', "\n"],

     ['num.names$'   => << 'EOT', '#1 #3 #1 #1 #0',
"A.B. See" num.names$ 
"Eye, J.I. and Queue, R.S. and Tea, U.V." num.names$
"Sand, P.B." num.names$
"{Dee and Dum}, Tweedle" num.names$
#3 num.names$
EOT
      << 'EOW', 
# num.names$, 5: Argument 1 of 'num.names$' has wrong type (#3)
EOW
      ],
     ['pop$'         => << 'EOT', '#1 "a"'
#1 "a" #2 "b" 'b { "foo" } pop$ pop$ pop$ pop$
EOT
      ],
     ['preamble$'    => 'preamble$', '""'],
     ['purify$'      => << 'EOT', '"This is a sstr1ng" ""', << 'EOW'
"Th{is}~\`{\i}s a #@$^&* {\ss}{\foo{t}{r1{n}g}}" purify$
#2 purify$
EOT
# purify$, 2: Argument 1 of 'purify$' has wrong type (#2)
EOW
      ],
     ['quote$'       => q(quote$ ), '"""'],
     ['skip$'        => q(skip$ ), ''],
     ['stack$'       => << 'EOT', '',
#3 "a" 'v s i { "b" #2 { "c" } } stack$
EOT
      << "EOW", 'INTEGERS { i } STRINGS { s }'
\{"b" #2 {"c"}\}
missing
missing
'v
"a"
#3
EOW
#'
      ],
     ['substring$'   => << 'EOT', '"bcd" "yxw" "zy" "" ""',
"abcde" #2 #3 substring$
"zyxwv" #-2 #3 substring$
"zyxwv" #-4 #3 substring$
"hijkl" #0 #3 substring$
#2 "a" "b" substring$
EOT
      << 'EOW'
# substring$, 4: Argument 2 to 'substring$' cannot be 0
# substring$, 5: Argument 1 of 'substring$' has wrong type ("b")
# substring$, 5: Argument 2 of 'substring$' has wrong type ("a")
# substring$, 5: Argument 3 of 'substring$' has wrong type (#2)
EOW
      ],
     ['swap$'        => qq(\#3 "a" swap\$ \'v { "b" } swap\$),
      qq("a" \#3 {"b"} \'v)],

     ['text.length$' => << 'EOT',
"abc" text.length$
"d{ef{g}}h" text.length$
"\AE{\oe}ck" text.length$
"M\" quote$ * "{u}ll{\'e}r" * text.length$
"T\^{y" text.length$
#8 text.length$
EOT
#"}
      '#3 #5 #4 #6 #2 #0', << 'EOW', 
# text.length$, 6: Argument 1 of 'text.length$' has wrong type (#8)
EOW
      ],
     ['text.prefix$' => << 'EOT',
"abcd" #3 text.prefix$
"d{ef{g}}h" #2 text.prefix$
"d{ef{g" #2 text.prefix$
"\AE{\oe}ck" #2 text.prefix$
"M\" quote$ * "{u}ll{\'e}r" * #4 text.prefix$
"le T\^{y" #5 text.prefix$
#8 "Error" text.prefix$
EOT
#"}
      '"abc" "d{ef{g}}" "d{ef{g}}" "\AE{\oe}" "M\"{u}ll" "le T\^{y}" ""',
      << 'EOW'
# text.prefix$, 7: Argument 1 of 'text.prefix$' has wrong type ("Error")
# text.prefix$, 7: Argument 2 of 'text.prefix$' has wrong type (#8)
EOW
      ],
     ['top$'         => << "EOT", '', << 'EOW'
#1 top\$
"ab" top\$ 
'v top\$
\{ #4 { "b" } #3 } top\$
EOT
# #1
# "ab"
# 'v
# {#4 {"b"} #3}
EOW
      ],
     ['type$'        => 'type$', '""'],
     ['warning$'     => << 'EOT', '', << 'EOW'
"Raw eggs are risky" warning$
#2 warning$
EOT
# Warning--Raw eggs are risky
# warning$, 2: Argument 1 of 'warning$' has wrong type (#2)
EOW
      ],
     ['while$'       => << 'EOT', '"a" "b" "c" "A" "B" "C"', << 'EOW', << 'EOP'
#-1 'i :=
 { i #1 + 'i := i #3 < }
 { "a" chr.to.int$ i + int.to.chr$} while$
#-1 'i :=
 'cont 'do while$
#1 "x" while$
EOT
# while$, 6: Argument 1 of 'while$' has wrong type ("x")
# while$, 6: Argument 2 of 'while$' has wrong type (#1)
EOW
INTEGERS {i}
FUNCTION {do}   {  "A" chr.to.int$ i + int.to.chr$ }
FUNCTION {cont} { i #1 + 'i := i #3 < }
EOP
      ],
     ['width$'       => << 'EOT',
# "abc" width$
# "ABC" width$
# "M\" quote$ * "{u}\ss {\AE}s{\'o}p?`" * width$
# #314 width$
EOT
      '#1500 #2180 #5076 #0', <<'EOW'
# width$, 4: Argument 1 of 'width$' has wrong type (#314)
EOW
      ],
     ['write$'       => << 'EOT', '"NOT output"', <<'EOW', undef, <<'EOO'
"This string should be output" write$ newline$
"NOT output" #1 write$
EOT
# write$, 2: Argument 1 of 'write$' has wrong type (#1)
EOW
This string should be output
EOO
      ],
     );

if (@ARGV) {
    my %tests;
    $tests{$_->[0]} = $_ foreach @tests;
    @tests = 
	map /^-?\d+$/ ? ($tests[$_]) : $tests{$_} ? ($tests{$_}) : (), @ARGV;
}

plan tests => 0+@tests;

my %options = (nowarn => 1);
$options{debug} = 1 if $ENV{DEBUG};
my $bibstyle = Text::BibTeX::BibStyle->new(%options);

foreach my $test (@tests) {
    my ($name, $code, $expect, $exp_warns, $predefs, $exp_outs) = @$test;
    $exp_warns ||= '';
    $predefs   ||= '';
    $exp_outs  ||= '';
    $code      =~ s/^\# //gm;
    $exp_warns =~ s/^\# //gm;
    $predefs   =~ s/^\# //gm;
    chomp $expect;
    my $interp = <<"EOS";
#line 1 ${name} predefs
${predefs}
#line 1 <string>
FUNCTION {---f---}
{ 
#line 1 $name
$code
#line 3 <string>
}

EXECUTE {---f---}
EOS
    ;
    $bibstyle->replace_bibstyle($interp);
    {
	local $SIG{__WARN__} = sub {
	    my ($str) = @_;
	    die $str unless @{$bibstyle->{warnings}} && do{
		my $warn = $bibstyle->{warnings}[-1];
		chomp $warn;
		index($str, $warn) == 0;
	    }
	    };
	$bibstyle->execute;
	my @warns  = $bibstyle->warnings;
	my $warns  = join '', @warns;
	my $output = $bibstyle->get_output;
	my @stack  = map $bibstyle->_format_token($_), @{$bibstyle->{stack}};
	is ("@stack\n$warns$output", "$expect\n$exp_warns$exp_outs", $name);
    }
}
