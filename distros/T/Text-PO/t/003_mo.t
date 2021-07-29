#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use Test::More qw( no_plan );
    use_ok( 'Text::PO::MO' ) || BAIL_OUT( "Cannot load Test::PO::MO" );
    use File::Spec ();
    use Module::Generic::File qw( file );
    our $DEBUG = 0;
};

use utf8;
my $domain = 'com.example.api';
my( $vol, $path, $this_file ) = File::Spec->splitpath( __FILE__ );
my $lc_path = File::Spec->catdir( $path, qw( fr_FR LC_MESSAGES ) );
my $mo_file = File::Spec->catpath( $vol, $lc_path, "${domain}.mo" );

my $mo = Text::PO::MO->new( $mo_file, { domain => $domain, debug => $DEBUG });
isa_ok( $mo, 'Text::PO::MO' );
my $po = $mo->as_object;
isa_ok( $po, 'Text::PO' );
# $po->dump;
# diag( join( "\n", @{$po->elements->first->msgstr} ) );
diag( $po->elements->length, " elements found." ) if( $DEBUG );
is( $po->elements->length, 9, "elements retrieved from \"$mo_file\"" );
my $elems = $po->elements;
is( $elems->[4]->msgid, 'Bad Request' );
is( $elems->[4]->msgstr, 'Mauvaise requête' );
my $meta = $po->meta;
if( $DEBUG )
{
    diag( $meta->length, " meta fields found." );
    $meta->foreach(sub
    {
        my( $k, $v ) = @_;
        diag( "Meta field $k -> '$v'" );
    });
}
# $po->debug(3);
# $po->dump || die( $po->error );

my $lc_path2 = file( File::Spec->catdir( $path, qw( en_GB LC_MESSAGES ) ) );
$lc_path2->mkpath;
my $mo_file2 = File::Spec->catpath( $vol, $lc_path2, "${domain}.mo" );
my $mo2 = Text::PO::MO->new( $mo_file2, { domain => $domain, encoding => 'utf-8', debug => $DEBUG });
$mo2->write( $po ) || die( $mo2->error );

done_testing();

__END__

