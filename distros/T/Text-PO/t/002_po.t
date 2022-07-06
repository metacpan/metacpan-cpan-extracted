#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More qw( no_plan );
    use JSON;
    use Module::Generic::File qw( cwd file tempfile );
    use Scalar::Util qw( reftype );
    use Nice::Try;
    use_ok( 'Text::PO' ) || BAIL_OUT( "Cannot load Test::PO" );
    our $DEBUG = 0;
};

my $po = Text::PO->new( debug => $DEBUG );
isa_ok( $po, 'Text::PO', 'Text::PO object instantiated' );
my $cwd = cwd();
my $f = $cwd->join( $cwd, qw( t fr_FR LC_MESSAGES com.example.api.po ) );
diag( "Parsing file $f" );
$po->parse( $f ) || BAIL_OUT( $po->error );
is( $po->elements->length, 8, 'number of elements' );
is( $po->domain, 'com.example.api', 'domain' );
my $ref = $po->as_hash;
is( reftype( $ref ), 'HASH', 'as_hash' );
is( scalar( keys( %$ref ) ), 8, 'as_hash returns 8 elements' );
my $json = $po->as_json;
try
{
    my $data = JSON->new->allow_nonref->decode( $json );
    is( reftype( $data ), 'HASH', 'as_json' );
}
catch($e)
{
    diag( "Decoding json data produced an error: $e" );
    fail( 'as_json' );
}

is( $po->charset, 'utf-8', 'charset' );
is( $po->content_encoding, '8bit', 'content_encoding' );
is( $po->content_type, 'text/plain; charset=utf-8', 'content_type' );
# <https://superuser.com/questions/392439/lang-and-language-environment-variable-in-debian-based-systems>
is( $po->current_lang, ( ( $ENV{LANGUAGE} || $ENV{LANG} ) ? [split( /:/, ( $ENV{LANGUAGE} || $ENV{LANG} ) )]->[0] : '' ), 'current_lang' );
is( $po->domain, 'com.example.api', 'domain' );
is( $po->encoding, 'utf8', 'encoding' );
my $temp = tempfile({ suffix => '.po', unlink => 0 });
my $fh = $temp->open( '>', { binmode => 'utf-8' } ) || BAIL_OUT( $temp->error );
diag( "Dumping data to $temp" );
$po->dump( $fh );
$fh->close;
# Now let's read it and see if it worked
my $po2 = Text::PO->new;
$po2->parse( $temp );
is( $po2->elements->length, 8, 'dump -> checking data writen' );
ok( $po2->exists( $po->elements->first ), 'exists' );
is( $po->language, 'fr_FR', 'language' );
is( $po->language_team, 'French <john.doe@example.com>', 'language_team' );
is( $po->last_translator, 'John Doe <john.doe@example.com>', 'last_translator' );
my $meta = $po->meta;
is( reftype( $meta ), 'HASH', 'meta returns an hash' );
ok( ( Scalar::Util::blessed( $meta ) && $meta->isa( 'Module::Generic::Hash' ) ), 'meta returns an object' );
is( $meta->keys->length, 11, 'meta keys size' );
my $keys = $po->meta_keys;
is( reftype( $keys ), 'ARRAY', 'meta_keys' );
is( $keys->length, 11, 'meta keys size (2)' );
is( $po->mime_version, '1.0', 'mime_version' );
is( $po->normalise_meta( 'language_team' ), 'Language-Team', 'normalise_meta' );
my $multi = $po->plural;
diag( "Error getting the plural value -> ", $po->error ) if( !defined( $multi ) );
is( reftype( $multi ), 'ARRAY', 'plural returned value' );
is( scalar( @$multi ), 2, 'plural returned array size' );
is( $multi->[0], 1, 'plural -> nplurals' );
is( $po->plural_forms, 'nplurals=1; plural=n>1;', 'plural_forms' );
my $f_ru = $cwd->join( $cwd, qw( t ru_RU.po ) );
my $po_ru = Text::PO->new( debug => $DEBUG );
$po_ru->parse( $f_ru );
is( $po_ru->plural_forms, 'nplurals=4; plural=(n==1) ? 0 : (n%10==1 && n%100!=11) ? 3 : ((n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20)) ? 1 : 2);', 'plural_forms for Russian' );
my $d = $po->po_revision_date || diag( "Unable to get the data object for po_revision_date: ", $po->error );
is( $po->po_revision_date, '2019-10-03 19-44+0000', 'po_revision_date' );
is( $po->project_id_version, 'MyProject 0.1', 'project_id_version' );
is( $po->report_bugs_to, 'john.doe@example.com', 'report_bugs_to' );

done_testing();

__END__

