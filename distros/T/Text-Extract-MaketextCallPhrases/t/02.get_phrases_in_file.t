use Test::More tests => 11;

use File::Temp ();
require bytes;    # just want function not pragma

BEGIN {
    use_ok('Text::Extract::MaketextCallPhrases');
}

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");
my ( $fh, $filename ) = File::Temp::tempfile();
seek( $fh, 0, 0 );
my $guts = _get_guts();
print {$fh} $guts;
truncate( $fh, bytes::length($guts) );
seek( $fh, 0, 0 );

is( -s $filename, bytes::length($guts), 'Tmpt file sanityc check' );

my $result_ar = get_phrases_in_file($filename);

is( $result_ar->[0]->{'phrase'}, 'Greeting Programs', 'single line - phrase' );
is( $result_ar->[0]->{'line'},   1,                   'single line - line' );
is( $result_ar->[0]->{'file'},   $filename,           'single line - file' );

is( $result_ar->[1]->{'phrase'}, "I say, lovely weather\nwe are having today.", 'two lines - phrase' );
is( $result_ar->[1]->{'line'},   3,                                             'two lines - line' );
is( $result_ar->[1]->{'file'},   $filename,                                     'two lines - file' );

is( $result_ar->[2]->{'phrase'}, "Dear diary, \n\nThis is not a secret.\n\nChuck Norris uses Perl\n", 'multiple lines - phrase' );
is( $result_ar->[2]->{'line'},   6,                                                                   'multiple lines - line' );
is( $result_ar->[2]->{'file'},   $filename,                                                           'multiple lines - file' );

# This should not be needed but just to be extra vigilant
close $fh;
unlink $filename;

# / This should not be needed but just to be extra vigilant

sub _get_guts {
    return <<'END_GUTS';
maketext("Greeting Programs"); 

maketext('I say, lovely weather
we are having today.');

maketext('Dear diary, 

This is not a secret.

Chuck Norris uses Perl
');

END_GUTS
}
