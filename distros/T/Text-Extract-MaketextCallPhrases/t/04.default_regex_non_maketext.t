use Test::More tests => 41 + ( 3 * 5 );

use Text::Extract::MaketextCallPhrases;

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

my $blob = <<'END_EXAMP';
return Local::Maketext::Utile::MarkPhrase::translatable('translatable() full NS');
Jabby::translatable('translatable() alt NS');
my $tan = translatable('translatable() assignment norm');my $tns =translatable('translatable() assignment no space');
my $fbl =
translatable('translatable() at beginning of line');
$bar = translatable ('translatable () space before par');
$foo = translatable 'translatable() I am no in parens, ick';
dispath(translatable('translatable() in function call'))
dispath(   translatable('translatable() in function call space')   )
This test contains the word translatable but is not a fucntion call.
<cptext 'Hello cPanel Tag'>
[% cptext("Hello cPanel TT") %]
Yo Cpanel::Exception->new('Ka boom no args') Bar
Yo Cpanel::Exception->new(
    'Ka boom next line no args'
) Bar
Yo Cpanel::Exception->new('Ka boom no args [_1]', 42) Bar
Yo Cpanel::Exception->new(
    'Ka boom next line no args [_1] [_2]', 37
    42
) Bar

Cpanel::Exception::Foo->new('C E one more');
Cpanel::Exception::Foo::Bar->new('C E two more');
Cpanel::Exception::Foo::Bar::Baz->new('C E three more');

Cpanel::Exception::create()
Cpanel::Exception::create("Herp::Derp");
Cpanel::Exception::create("Herp::Derp", 'Please herp your derp!');
Cpanel::Exception::create("Herp::Derp", 'The herp has been derped: [_1]', [$err]);

Cpanel::Exception::Foo::create()
Cpanel::Exception::Foo::create("Herp::Derp");
Cpanel::Exception::Foo::create("Herp::Derp", 'foo Please herp your derp!');
Cpanel::Exception::Foo::create("Herp::Derp", 'foo The herp has been derped: [_1]', [$err]);

Cpanel::Exception::Foo::Bar::create()
Cpanel::Exception::Foo::Bar::create("Herp::Derp");
Cpanel::Exception::Foo::Bar::create("Herp::Derp", 'bar Please herp your derp!');
Cpanel::Exception::Foo::Bar::create("Herp::Derp", 'bar The herp has been derped: [_1]', [$err]);

Cpanel::Exception::Foo::Bar::Baz::create()
Cpanel::Exception::Foo::Bar::Baz::create("Herp::Derp");
Cpanel::Exception::Foo::Bar::Baz::create("Herp::Derp", 'baz Please herp your derp!');
Cpanel::Exception::Foo::Bar::Baz::create("Herp::Derp", 'baz The herp has been derped: [_1]', [$err]);

# ? TODO ? ::create(PHRASE) (i.e. no NS w/ phrase) - might be too ambiguous to (want to) support

Cpanel::Exception->create()
Cpanel::Exception->create('I am method!')

Cpanel::Exception::Foo->create()
Cpanel::Exception::Foo->create('foo I am method!')

Cpanel::Exception::Foo::Bar->create()
Cpanel::Exception::Foo::Bar->create('bar I am method!')

Cpanel::Exception::Foo::Bar::Baz->create()
Cpanel::Exception::Foo::Bar::Baz->create('baz I am method!')

Cpanel::LocaleString->new("LS OBJ");
Cpanel::LocaleString->new( "LS OBJ SPACE" );
Cpanel::LocaleString->new( "LS OBJ ARGS", [1,2,3] );
Cpanel::LocaleString->new(
   "LS OBJ AFTER LINE",
   [1,2,3]
);
END_EXAMP

my $results = get_phrases_in_text($blob);
is( $results->[0]->{'phrase'},     "translatable() full NS",                "translatable() full NS" );
is( $results->[1]->{'phrase'},     "translatable() alt NS",                 "translatable() alt NS" );
is( $results->[2]->{'phrase'},     "translatable() assignment norm",        "translatable() assignment norm" );
is( $results->[3]->{'phrase'},     "translatable() assignment no space",    "translatable() assignment no space" );
is( $results->[4]->{'phrase'},     "translatable() at beginning of line",   "translatable() at beginning of line" );
is( $results->[5]->{'phrase'},     "translatable () space before par",      "translatable () space before par" );
is( $results->[6]->{'phrase'},     "translatable() I am no in parens, ick", "translatable() I am no in parens, ick" );
is( $results->[7]->{'phrase'},     "translatable() in function call",       "translatable() in function call" );
is( $results->[8]->{'phrase'},     "translatable() in function call space", "translatable() in function call space" );
is( $results->[9]->{'phrase'},     "but",                                   "translatable in text - value" );
is( $results->[9]->{'is_warning'}, 1,                                       "translatable in text - is_warning" );
is( $results->[9]->{'type'},       'bareword',                              "translatable in text - type" );

# This is really just a sanity check that these are found, the tests for maketext() cover all sorts of odd syntax
for my $meth (qw(lextext maketext_html_context maketext_ansi_context  maketext_plain_context maketext_W3_are_cUst0M_context)) {
    my $blob    = qq{$meth('$meth() norm');dothis($meth("$meth() in function"));$meth\n'$meth() odd'\n;};
    my $results = get_phrases_in_text($blob);
    is( $results->[0]->{'phrase'}, "$meth() norm",        "$meth() found" );
    is( $results->[1]->{'phrase'}, "$meth() in function", "$meth() found again" );
    is( $results->[2]->{'phrase'}, "$meth() odd",         "$meth() found with odd call" );
}

$results = get_phrases_in_text( $blob, { cpanel_mode => 1 } );
is( $results->[10]->{'phrase'}, "Hello cPanel Tag",                    "cptext tag" );
is( $results->[11]->{'phrase'}, "Hello cPanel TT",                     "cptext TT" );
is( $results->[12]->{'phrase'}, "Ka boom no args",                     "Cpanel::Exception->new() one line no args" );
is( $results->[13]->{'phrase'}, "Ka boom next line no args",           "Cpanel::Exception->new() next line no args" );
is( $results->[14]->{'phrase'}, "Ka boom no args [_1]",                "Cpanel::Exception->new() one line w/ args" );
is( $results->[15]->{'phrase'}, "Ka boom next line no args [_1] [_2]", "Cpanel::Exception->new() next line w/ args" );
is( $results->[16]->{'phrase'}, "C E one more",                        "Cpanel::Exception::*->new() with one more NS chunk" );
is( $results->[17]->{'phrase'}, "C E two more",                        "Cpanel::Exception::*->new() with two more NS chunks" );
is( $results->[18]->{'phrase'}, "C E three more",                      "Cpanel::Exception::*->new() with three more NS chunks" );

# the first/second ::create w/out the optional phrase should not be in the result, which is true if these pass:
is( $results->[19]->{'phrase'}, 'Please herp your derp!',         "C E ::create phrase no args" );
is( $results->[20]->{'phrase'}, 'The herp has been derped: [_1]', "C E ::create phrase  w/ args" );

is( $results->[21]->{'phrase'}, 'foo Please herp your derp!',         "C E with one more NS chunk ::create phrase no args" );
is( $results->[22]->{'phrase'}, 'foo The herp has been derped: [_1]', "C E with one more NS chunk ::create phrase  w/ args" );

is( $results->[23]->{'phrase'}, 'bar Please herp your derp!',         "C E with two more NS chunks ::create phrase no args" );
is( $results->[24]->{'phrase'}, 'bar The herp has been derped: [_1]', "C E with two more NS chunks ::create phrase  w/ args" );

is( $results->[25]->{'phrase'}, 'baz Please herp your derp!',         "C E with three more NS chunks ::create phrase no args" );
is( $results->[26]->{'phrase'}, 'baz The herp has been derped: [_1]', "C E with three more NS chunks ::create phrase  w/ args" );

is( $results->[27]->{'phrase'}, 'I am method!',     "C E ->create" );
is( $results->[28]->{'phrase'}, 'foo I am method!', "C E with one more NS chunk ->create" );
is( $results->[29]->{'phrase'}, 'bar I am method!', "C E with two more NS chunks ->create" );
is( $results->[30]->{'phrase'}, 'baz I am method!', "C E with three more NS chunks ->create" );

is( $results->[31]->{'phrase'}, "LS OBJ",            "Cpanel::LocaleString->new() basic" );
is( $results->[32]->{'phrase'}, "LS OBJ SPACE",      "Cpanel::LocaleString->new() w/ space" );
is( $results->[33]->{'phrase'}, "LS OBJ ARGS",       "Cpanel::LocaleString->new() w/ args" );
is( $results->[34]->{'phrase'}, "LS OBJ AFTER LINE", "Cpanel::LocaleString->new() w/ phrase on next line" );

$blob = <<'END_EXAMP_2';
object.translatable("Herp a Derp");
object.translatable("Herp a Derp with substitution: [_1]");
Blah translatable('howdy dooty')
eval_evil("translatable('forp forp forp')")
END_EXAMP_2

$results = get_phrases_in_text($blob);
is( $results->[0]->{'phrase'}, "Herp a Derp",                         ".translatable() aka JavaScript" );
is( $results->[1]->{'phrase'}, "Herp a Derp with substitution: [_1]", ".translatable() aka JavaScript with a parameter" );
is( $results->[2]->{'phrase'}, "howdy dooty",                         "translatable() preceded by space" );
is( $results->[3]->{'phrase'}, "forp forp forp",                      "translatable() preceded by word break (straight quote)" );
