use Test::More tests => 18;

use Text::Extract::MaketextCallPhrases;

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

my $results_wout_ar = get_phrases_in_text( _str_without_notation() );

chomp( my $str = _str_without_notation() );
my $results_ownline = get_phrases_in_text( "## no extract maketext\n" . ($str) );

my $results_with_ar = get_phrases_in_text( _str_with_notation() );
my $results_mult_ar = get_phrases_in_text( _str_with_double_notation() );

is( scalar( @{$results_wout_ar} ), 6, 'without ## no extract maketext all instances found' );
is( scalar( @{$results_ownline} ), 6, 'own line ## no extract maketext doe snot affect' );
is( scalar( @{$results_with_ar} ), 4, 'with ## no extract maketext all unmarked instances found' );
is( scalar( @{$results_mult_ar} ), 4, 'multi ## no extract maketext all unmarked instances found' );

for my $res ( $results_with_ar, $results_mult_ar ) {
    is( $res->[0]->{'phrase'}, "This is string.",                                "## no extract maketext: phrase before notation is found" );
    is( $res->[1]->{'phrase'}, "This is a string after the notation.",           "## no extract maketext: phrase after notation is found" );
    is( $res->[2]->{'phrase'}, "This is another string after the notation.",     "## no extract maketext: phrase after more notation is found" );
    is( $res->[3]->{'phrase'}, 'This is yet another string after the notation.', "## no extract maketext: phrase after even more notation is found" );
}

my $comment_start = get_phrases_in_text(qq{maketext("hi")\n## no extract maketext: maketext is great!"});
is( scalar( @{$comment_start} ),     1,    '## no extract maketext @ beginning of comment works' );
is( $comment_start->[0]->{'phrase'}, "hi", "## no extract maketext @ beginning of comment has correct phrase" );

my $comment_mid = get_phrases_in_text(qq{maketext("low")\n# you should localize your code with (## no extract maketext) maketext is great!")});
is( scalar( @{$comment_mid} ),     1,     '## no extract maketext in middle of comment works, maketext!' );
is( $comment_mid->[0]->{'phrase'}, "low", "## no extract maketext in middle of comment has correct phrase" );

my $ml_with_notation = get_phrases_in_text(qq{maketext(\n"merp\nderp\n")## no extract maketext\nmaketext("flerp")});
is( $ml_with_notation->[0]->{'phrase'}, "merp\nderp\n", "## no extract maketext: at end of multline call does not ignore multiline phrase" );
is( $ml_with_notation->[1]->{'phrase'}, "flerp",        "## no extract maketext: at end of multline call does not affect a call on lines after it" );

sub _str_without_notation {
    return <<'END_TEXT'
    maketext('This is string.');

    sub maketext {
    }
    maketext('This is a string after the notation.');

    if ($f =~ m/maketext foo/) {
        $bar++;
    }

    maketext('This is another string after the notation.');

odd maketext(
    'I am an 
odd thing that must be this 
way for unspecified, ahem, “business reasons”. and I 
  want to hide
 my shame.'
)

asdcd maketext('This is yet another string after the notation.'); sdcsd
END_TEXT
}

sub _str_with_double_notation {
    my $str = _str_with_notation();
    $str =~ s/## no extract maketext/## no extract maketext balh blah ## no extract maketext/;
    return $str;
}

sub _str_with_notation {
    my $str = _str_without_notation();

    $str =~ s/(sub maketext {)/$1 ## no extract maketext/;
    $str =~ s/(maketext foo.*)/$1 ## no extract maketext/;
    $str =~ s/(odd maketext\()/$1 ## no extract maketext/;

    # diag($str);
    return $str;
}
