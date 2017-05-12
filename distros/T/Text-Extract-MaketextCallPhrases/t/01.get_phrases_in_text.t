use Test::More tests => 442;

BEGIN {
    use_ok('Text::Extract::MaketextCallPhrases');
}

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

for my $blob ( _get_blob(0), _get_blob(1) ) {

    my $results = get_phrases_in_text($blob);

    ok( !exists $results->[0]->{'file'}, 'get_phrases_in_text does not have a file field' );

    is( $results->[0]->{'phrase'}, "Greetings Programs DQ",  "Normal, Double Quotes" );
    is( $results->[1]->{'phrase'}, "Greetings Programs SQ",  "Normal, Single Quotes" );
    is( $results->[2]->{'phrase'}, "Greetings Programs DQQ", "Normal, qq{} Quotes" );
    is( $results->[3]->{'phrase'}, "Greetings Programs SQQ", "Normal, q{} Quotes" );
    is( $results->[4]->{'phrase'}, "QW",                     "Normal, qw() quote" );
    is( $results->[5]->{'phrase'}, "I am HERE DOC\n",        "Normal, Here Doc" );
    is( $results->[6]->{'phrase'}, "I am\n\nmultiline",      "Normal, Multi-line" );

    is( $results->[0]->{'quotetype'},    'double', "quotetype for Normal, Double Quotes" );
    is( $results->[0]->{'quote_before'}, '"',      'quote_before Double Quotes' );
    is( $results->[0]->{'quote_after'},  '"',      'quote_after Double Quotes' );

    is( $results->[1]->{'quotetype'},    'single', "quotetype for Normal, Single Quotes" );
    is( $results->[1]->{'quote_before'}, "'",      'quote_before Single Quotes' );
    is( $results->[1]->{'quote_after'},  "'",      'quote_after Single Quotes' );

    is( $results->[2]->{'quotetype'},    'double', "quotetype for Normal, qq{} Quotes" );
    is( $results->[2]->{'quote_before'}, 'qq{',    'quote_before w/ qq{} Quotes' );
    is( $results->[2]->{'quote_after'},  '}',      'quote_after w/ qq{} Quotes' );

    is( $results->[3]->{'quotetype'},    'single', "quotetype for Normal, q{} Quotes" );
    is( $results->[3]->{'quote_before'}, 'q{',     'quote_before w/ q{} Quotes' );
    is( $results->[3]->{'quote_after'},  '}',      'quote_after w/ q{} Quotes' );

    is( $results->[4]->{'quotetype'},    'single', "quotetype for Normal, qw() Quotes" );
    is( $results->[4]->{'quote_before'}, 'qw(',    'quote_before w/ qw()' );
    is( $results->[4]->{'quote_after'},  ' ',      'quote_after w/ qw()' );

    is( $results->[7]->{'phrase'},  "Greetings Programs DQ BS",  "Normal space, Double Quotes" );
    is( $results->[8]->{'phrase'},  "Greetings Programs SQ BS",  "Normal space, Single Quotes" );
    is( $results->[9]->{'phrase'},  "Greetings Programs DQQ BS", "Normal space, qq{} Quotes" );
    is( $results->[10]->{'phrase'}, "Greetings Programs SQQ BS", "Normal space, q{} Quotes" );
    is( $results->[11]->{'phrase'}, "QW-BS",                     "Normal space, qw() quote" );
    is( $results->[12]->{'phrase'}, "I am HERE DOC BS\n",        "Normal space, Here Doc" );
    is( $results->[13]->{'phrase'}, "I am\n\nmultiline\n\nBS",   "Normal space, Multi-line" );

    is( $results->[14]->{'phrase'}, "Greetings Programs DQ NP",  "Normal no paren, Double Quotes" );
    is( $results->[15]->{'phrase'}, "Greetings Programs SQ NP",  "Normal no paren, Single Quotes" );
    is( $results->[16]->{'phrase'}, "Greetings Programs DQQ NP", "Normal no paren, qq{} Quotes" );
    is( $results->[17]->{'phrase'}, "Greetings Programs SQQ NP", "Normal no paren, q{} Quotes" );
    is( $results->[18]->{'phrase'}, "QW-NP",                     "Normal no paren, qw() quote" );
    is( $results->[19]->{'phrase'}, "I am HERE DOC NP\n",        "Normal no paren, Here Doc" );
    is( $results->[20]->{'phrase'}, "I am\n\nmultiline\n\nNP",   "Normal no paren, Multi-line" );

    is( $results->[21]->{'phrase'}, "I am perl",       "perl format" );
    is( $results->[22]->{'phrase'}, "I am TT",         "TT format" );
    is( $results->[23]->{'phrase'}, "I am cPanel tag", "cpanel format" );

    is( $results->[24]->{'phrase'}, "ls backtick", "backtick" );
    is( $results->[25]->{'phrase'}, "ls qx",       "qx" );

    is( $results->[26]->{'phrase'}, "no m regex",    "regex no m" );
    is( $results->[27]->{'phrase'}, "match me",      "regex w/ m" );
    is( $results->[28]->{'phrase'}, "substitute",    "regex substitute" );
    is( $results->[29]->{'phrase'}, "transliterate", "transliterate" );
    is( $results->[30]->{'phrase'}, "qr",            "qr()" );

    is( $results->[31]->{'phrase'}, "", "Empty, DQ" );
    is( $results->[32]->{'phrase'}, "", "Empty, SQ" );
    is( $results->[33]->{'phrase'}, "", "Empty q" );
    is( $results->[34]->{'phrase'}, "", "Empty, qq" );
    is( $results->[35]->{'phrase'}, "", "Empty, qw()" );

    is( $results->[36]->{'phrase'}, "bareword",          "bare word" );
    is( $results->[37]->{'phrase'}, "bare::name::space", "name space like bare word" );
    is( $results->[38]->{'phrase'}, "Class->method",     "class method" );

    is( $results->[39]->{'phrase'}, '$var', 'scalar' );
    ok( !exists $results->[39]->{'quotetype'}, 'perlish no quotetype' );

    is( $results->[40]->{'phrase'}, '@array',       'array' );
    is( $results->[41]->{'phrase'}, '%hash',        'hash' );
    is( $results->[42]->{'phrase'}, '$obj->method', 'object method' );
    is( $results->[43]->{'phrase'}, '*GLOB',        'star glob' );
    is( $results->[44]->{'phrase'}, '&old_func',    '& func' );
    is( $results->[45]->{'phrase'}, '\\*slash_ref', 'slash star glob' );
    is( $results->[46]->{'phrase'}, 'func_paren(',  'function call' );

    is( $results->[47]->{'phrase'}, undef, "No arg, paren basic" );
    is( $results->[48]->{'phrase'}, undef, "No arg, no paren" );
    is( $results->[49]->{'phrase'}, undef, "No arg, paren space" );
    is( $results->[50]->{'phrase'}, undef, "No arg, no paren space" );
    is( $results->[51]->{'phrase'}, undef, "No arg, paren multiline" );
    is( $results->[52]->{'phrase'}, undef, "No arg, no paren multiline" );

    is( $results->[53]->{'phrase'}, undef, "trailing, multiline partial" );

    _is_normal( $results, 0 .. 23 );
    _is_error( $results, 31 .. 35, 47 .. 52 );
    _is_warning( $results, 24 .. 30, 36 .. 46, 53 );

    _is_type( $results, undef,       0 .. 23 );
    _is_type( $results, 'command',   24 .. 25 );
    _is_type( $results, 'pattern',   26 .. 30 );
    _is_type( $results, 'empty',     31 .. 35 );
    _is_type( $results, 'bareword',  36 .. 38 );
    _is_type( $results, 'perlish',   39 .. 46 );
    _is_type( $results, 'no_arg',    47 .. 52 );
    _is_type( $results, 'multiline', 53 );

    my $res_a = get_phrases_in_text( $blob, { 'regexp_conf' => [ [ qr/\<cptext/, qr/\s*\>/ ] ] } );
    is( scalar( @{$res_a} ),     scalar( @{$results} ) + 1, 'regexp_conf find aditional' );
    is( $res_a->[1]->{'phrase'}, 'I am cptext',             'regexp_conf preserves order' );

    my $res_b = get_phrases_in_text( $blob, { 'no_default_regex' => 1 } );
    is( scalar( @{$res_b} ), scalar( @{$results} ), 'no_default_regex has no effect without regexp_conf' );

    my $res_c = get_phrases_in_text( $blob, { 'regexp_conf' => [ [ qr/\<cptext/, qr/\s*\>/ ] ], 'no_default_regex' => 1 } );
    is( scalar( @{$res_c} ), 1, 'no_default_regex has effect with regexp_conf' );
}

is( get_phrases_in_text('maketext(q{\\!\\@\\#\\$\\%\\^\\&\\*\\(\\)\\_})')->[0]{'phrase'}, q{!@#$%^&*()_}, 'quotemeta() is unescaped' );

my $orig = <<'END_ORIG';
  maketext("yo yo\nba ba\nzi zi\n");
  maketext('yo yo\nba ba\nzi zi\n');
  maketext("I \xe2\x99\xa5 perl");
  maketext('I \xe2\x99\xa5 perl');
  maketext("I \x{2665} perl");
  maketext('I \x{2665} perl');
  maketext("one
  
 two
    
 three\n");
 maketext("Hello \"World\" DQ");
 maketext('Hello \'World\' SQ');
END_ORIG

my $orig_res = get_phrases_in_text($orig);
is( $orig_res->[0]->{'phrase'},        "yo yo\nba ba\nzi zi\n", 'phrase is transmogrified w DQ' );
is( $orig_res->[0]->{'original_text'}, 'yo yo\nba ba\nzi zi\n', 'original_text is not transmogrified w/ DQ' );
is( $orig_res->[1]->{'phrase'},        'yo yo\nba ba\nzi zi\n', 'phrase is not transmogrified w/ SQ' );
is( $orig_res->[1]->{'original_text'}, 'yo yo\nba ba\nzi zi\n', 'original_text is not transmogrified q/ SQ' );

is( $orig_res->[2]->{'phrase'},        "I \xe2\x99\xa5 perl", 'utf-8 grapheme phrase istransmogrified w/ DQ' );
is( $orig_res->[2]->{'original_text'}, 'I \xe2\x99\xa5 perl', 'utf-8 grapheme original_text is not transmogrified w/ DQ' );
is( $orig_res->[3]->{'phrase'},        "I \xe2\x99\xa5 perl", 'utf-8 grapheme phrase is still transmogrified w/ SQ' );
is( $orig_res->[3]->{'original_text'}, 'I \xe2\x99\xa5 perl', 'utf-8 grapheme original_text is not transmogrified w/ SQ' );

is( $orig_res->[4]->{'phrase'},        'I \x{2665} perl', 'unicode grapheme phrase is not transmogrified w/ DQ' );
is( $orig_res->[4]->{'original_text'}, 'I \x{2665} perl', 'unicode grapheme original_text is not transmogrified w/ DQ' );
is( $orig_res->[5]->{'phrase'},        'I \x{2665} perl', 'unicode grapheme phrase is not transmogrified w/ SQ' );
is( $orig_res->[5]->{'original_text'}, 'I \x{2665} perl', 'unicode grapheme original_text is not transmogrified w/ SQ' );

is( $orig_res->[6]->{'phrase'},        "one\n  \n two\n    \n three\n",  'multiline phrase is transmogrified w DQ' );
is( $orig_res->[6]->{'original_text'}, "one\n  \n two\n    \n three\\n", 'multiline original_text is not transmogrified w/ DQ' );

is( $orig_res->[7]->{'phrase'},        q{Hello "World" DQ},     'DQ escaped phrase is transmogrified w DQ' );
is( $orig_res->[7]->{'original_text'}, q{Hello \\"World\\" DQ}, 'DQ escapes original_text is not transmogrified w/ DQ' );
is( $orig_res->[8]->{'phrase'},        q{Hello 'World' SQ},     'SQ escaped phrase is transmogrified w DQ' );
is( $orig_res->[8]->{'original_text'}, q{Hello \\'World\\' SQ}, 'SQ escapes original_text is not transmogrified w/ DQ' );

my $qw_text_res = get_phrases_in_text("maketext( qw(foo) ) maketext(qw(  foo )) maketext(qw( foo bar baz )  )");

is( $qw_text_res->[0]->{'phrase'},       "foo",    'parsed OK qw(WORD)' );
is( $qw_text_res->[0]->{'quotetype'},    'single', "quotetype qw(WORD)" );
is( $qw_text_res->[0]->{'quote_before'}, 'qw(',    'quote_before qw(WORD)' );
is( $qw_text_res->[0]->{'quote_after'},  ")",      'quote_after qw(WORD)' );
is( $qw_text_res->[1]->{'phrase'},       "foo",    'parsed OK qw(  WORD )' );
is( $qw_text_res->[1]->{'quotetype'},    'single', "quotetype qw(  WORD )" );
is( $qw_text_res->[1]->{'quote_before'}, 'qw(  ',  'quote_before qw(  WORD )' );
is( $qw_text_res->[1]->{'quote_after'},  " )",     'quote_after qw(  WORD )' );
is( $qw_text_res->[2]->{'phrase'},       "foo",    'parsed OK qw( WORD WORD WORD )' );
is( $qw_text_res->[2]->{'quotetype'},    'single', "quotetype qw( WORD WORD WORD )" );
is( $qw_text_res->[2]->{'quote_before'}, 'qw( ',   'quote_before qw( WORD WORD WORD)' );
is( $qw_text_res->[2]->{'quote_after'},  " ",      'quote_after qw( WORD WORD WORD)' );

my $parened_here_text = <<'END_HERE';
maketext(<<"IHERE", "arg", "argx", "argy");
yo yo
ba ba
zi zi
IHERE
END_HERE

my $parened_here_text_res = get_phrases_in_text($parened_here_text);
is( $parened_here_text_res->[0]->{'phrase'},       "yo yo\nba ba\nzi zi\n", 'paren-ed here doc parsed OK' );
is( $parened_here_text_res->[0]->{'quotetype'},    'double',                "paren-ed here doc quotetype" );
is( $parened_here_text_res->[0]->{'quote_before'}, '<<"IHERE"',             'quote_before paren-ed here doc' );
is( $parened_here_text_res->[0]->{'quote_after'},  "IHERE\n",               'quote_after paren-ed here doc' );
is( $parened_here_text_res->[0]->{'heredoc'},      '"IHERE"',               "paren-ed here doc heredoc" );

my $quotes_here_text = <<'END_HERE';
maketext(<<"END_DOUB";
I am double quoted.
END_DOUB
)

maketext(<<'END_SING';
I am single quoted.
END_SING
)

maketext(<<END_IMPL;
I am implied double quoted.
END_IMPL
)

END_HERE

my $quotes_here_text_results = get_phrases_in_text($quotes_here_text);
is( $quotes_here_text_results->[0]->{'phrase'},       "I am double quoted.\n",         "quotetype for Normal, Here Doc (double)" );
is( $quotes_here_text_results->[1]->{'phrase'},       "I am single quoted.\n",         "quotetype for Normal, Here Doc (single)" );
is( $quotes_here_text_results->[2]->{'phrase'},       "I am implied double quoted.\n", "quotetype for Normal, Here Doc (implicit)" );
is( $quotes_here_text_results->[0]->{'quotetype'},    'double',                        "quotetype for Normal, Here Doc (double)" );
is( $quotes_here_text_results->[1]->{'quotetype'},    'single',                        "quotetype for Normal, Here Doc (single)" );
is( $quotes_here_text_results->[2]->{'quotetype'},    'double',                        "quotetype for Normal, Here Doc (implicit)" );
is( $quotes_here_text_results->[0]->{'quote_before'}, '<<"END_DOUB"',                  'quote_before Here Doc (double)' );
is( $quotes_here_text_results->[0]->{'quote_after'},  "END_DOUB\n",                    'quote_after Here Doc (double)' );
is( $quotes_here_text_results->[1]->{'quote_before'}, q{<<'END_SING'},                 'quote_before Here Doc (single)' );
is( $quotes_here_text_results->[1]->{'quote_after'},  "END_SING\n",                    'quote_after Here Doc (single)' );
is( $quotes_here_text_results->[2]->{'quote_before'}, '<<END_IMPL',                    'quote_before Here Doc (implicit)' );
is( $quotes_here_text_results->[2]->{'quote_after'},  "END_IMPL\n",                    'quote_after Here Doc (implicit)' );

is( $quotes_here_text_results->[0]->{'heredoc'}, '"END_DOUB"',  "heredoc for Normal, Here Doc (double)" );
is( $quotes_here_text_results->[1]->{'heredoc'}, q{'END_SING'}, "heredoc for Normal, Here Doc (single)" );
is( $quotes_here_text_results->[2]->{'heredoc'}, 'END_IMPL',    "heredoc for Normal, Here Doc (implicit)" );

my $quoth_sing_res = get_phrases_in_text(q{maketext('$var') maketext('  $var  ') maketext('\ttab newline\n')});
_is_type( $quoth_sing_res, 'perlish', 0 .. 1 );
is( $quoth_sing_res->[0]->{'phrase'},    '$var',            "quoted \$var in single quotes" );
is( $quoth_sing_res->[1]->{'phrase'},    '  $var  ',        "quoted \$var in single quotes w/ space" );
is( $quoth_sing_res->[2]->{'phrase'},    '\ttab newline\n', "slash chars in single quote preserved as literal" );
is( $quoth_sing_res->[0]->{'quotetype'}, 'single',          "quotetype for quoted \$var in single quotes" );

my $quoth_doub_res = get_phrases_in_text(q{maketext("$var") maketext("  $var  ") maketext("\ttab newline\n")});
_is_type( $quoth_doub_res, 'perlish', 0 .. 1 );
is( $quoth_doub_res->[0]->{'phrase'},    '$var',            "\$var in single quotes" );
is( $quoth_doub_res->[1]->{'phrase'},    '  $var  ',        "\$var in single quotes w/ space" );
is( $quoth_doub_res->[2]->{'phrase'},    "\ttab newline\n", "slash chars in double quote interpolated" );
is( $quoth_doub_res->[0]->{'quotetype'}, 'double',          "quotetype for quoted \$var in double quotes" );

# trailing WS that Text::Balanced ignores which then can throw off the offset
my %post_token_space = (
    "01 maketext('none')"     => [ 'none',  12 ],
    "02 maketext( 'one')"     => [ 'one',   13 ],
    "03 maketext(  'two')"    => [ 'two',   14 ],
    "04 maketext(   'three')" => [ 'three', 15 ],
    "05 maketext(    'four')" => [ 'four',  16 ],
    "06 maketext(\t'tab')"    => [ 'tab',   13 ],
);
for my $item ( sort keys %post_token_space ) {
    my $post_token_space = get_phrases_in_text($item);
    is( $post_token_space->[0]->{'phrase'}, $post_token_space{$item}->[0], "space after token phrase: $post_token_space{$item}->[0]" );
    is( $post_token_space->[0]->{'offset'}, $post_token_space{$item}->[1], "space after token offset: $post_token_space{$item}->[0]" );
}

sub _is_type {
    my $results = shift;
    my $type    = shift;
    for my $n (@_) {
        is( $results->[$n]->{'type'}, $type, defined $type ? "$n is $type" : "$n has no type" );
    }
}

sub _is_normal {
    my $results = shift;
    for my $n (@_) {
        ok( !$results->[$n]->{'is_warning'} && !$results->[$n]->{'is_error'}, "$n is normal" );
    }
}

sub _is_error {
    my $results = shift;
    for my $n (@_) {
        ok( !$results->[$n]->{'is_warning'} && $results->[$n]->{'is_error'}, "$n is error" );
    }
}

sub _is_warning {
    my $results = shift;
    for my $n (@_) {
        ok( $results->[$n]->{'is_warning'} && !$results->[$n]->{'is_error'}, "$n is warning" );
    }
}

sub _get_blob {
    my ($wants_arg) = @_;
    $wants_arg = $wants_arg ? " , 'foo'" : '';

    return <<"END_TEXT";
# normal

maketext( "Greetings Programs DQ"$wants_arg ); <cptext 'I am cptext'$wants_arg> maketext( 'Greetings Programs SQ'$wants_arg ); 
maketext( qq{Greetings Programs DQQ}$wants_arg ); maketext( q{Greetings Programs SQQ}$wants_arg ); 
maketext(qw(QW FAIL)$wants_arg);

maketext(<<'END_HERE';
I am HERE DOC
END_HERE
$wants_arg);

maketext(
'I am

multiline'    
$wants_arg)


maketext ( "Greetings Programs DQ BS"$wants_arg ); maketext ( 'Greetings Programs SQ BS'$wants_arg ); 
maketext ( qq{Greetings Programs DQQ BS}$wants_arg ); maketext ( q{Greetings Programs SQQ BS}$wants_arg );
maketext ( qw(QW-BS FAIL)$wants_arg );
maketext (<<'END_HERE';
I am HERE DOC BS
END_HERE
$wants_arg);
maketext (
'I am

multiline

BS'    
$wants_arg)


maketext "Greetings Programs DQ NP"; maketext 'Greetings Programs SQ NP'; 
maketext qq{Greetings Programs DQQ NP}; maketext q{Greetings Programs SQQ NP};
maketext qw(QW-NP FAIL);
maketext <<'END_HERE';
I am HERE DOC NP
END_HERE
$wants_arg;

maketext
'I am

multiline

NP'
$wants_arg;

# normal, formats

\$locale->maketext("I am perl"$wants_arg); [% locale.maketext("I am TT"$wants_arg)] <cpanel Locale="maketext("I am cPanel tag"$wants_arg)">

# command warning

maketext(`ls backtick`$wants_arg) maketext(qx{ls qx}$wants_arg);

# pattern warning

maketext(/no m regex/$wants_arg); maketext(m/match me/$wants_arg); maketext(s{substitute}{for this}$wants_arg); maketext(tr{transliterate}{}$wants_arg); maketext(qr/qr/$wants_arg);

# empty error

maketext(""$wants_arg) maketext(''$wants_arg); maketext(q{}$wants_arg);maketext(qq{}$wants_arg)maketext(qw()$wants_arg)

# bareword warning

maketext(bareword$wants_arg) maketext(bare::name::space$wants_arg) maketext( Class->method$wants_arg )

# perlish warning

maketext(\$var$wants_arg)  maketext(\@array)    maketext(\%hash$wants_arg)      maketext(\$obj->method$wants_arg) 
maketext(*GLOB$wants_arg) maketext(&old_func$wants_arg) maketext(\\*slash_ref$wants_arg) maketext(func_paren()$wants_arg)

# no_arg error

maketext() maketext; maketext (    ) maketext    ; maketext (    


)

maketext


; 

# multiline warning

maketext( "I am trailing off end of line
END_TEXT
}
