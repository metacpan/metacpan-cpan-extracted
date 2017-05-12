use Test::More;

BEGIN {
    use_ok( 'Text::Info'           );
    use_ok( 'Text::Info::Sentence' );
    use_ok( 'Text::Info::Utils'    );
}

diag( 'Testing Text::Info ' . $Text::Info::VERSION );

ok( my $text = Text::Info->new );

is( $text->sentence_count, 0 );
is( $text->word_count, 0 );
is( $text->readability->fres, undef );

done_testing;
