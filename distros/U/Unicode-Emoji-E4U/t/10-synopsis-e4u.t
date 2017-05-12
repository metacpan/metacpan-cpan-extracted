use strict;
use warnings;
use Test::More;

plan tests => 5;

# ------------------------------------------------------------------------
    use Unicode::Emoji::E4U;

    my $e4u = Unicode::Emoji::E4U->new;

    # fetch data files from Google Code (default)
    $e4u->datadir('http://emoji4unicode.googlecode.com/svn/trunk/data/');

    # or load from local cached files
#   $e4u->datadir('data');

    my $docomo   = $e4u->docomo;    # Unicode::Emoji::DoCoMo instance
    my $kddi     = $e4u->kddi;      # Unicode::Emoji::KDDI instance
    my $softbank = $e4u->softbank;  # Unicode::Emoji::SoftBank instance
    my $google   = $e4u->google;    # Unicode::Emoji::Google instance
# ------------------------------------------------------------------------

ok( ref $e4u,       'Unicode::Emoji::E4U' );
ok( ref $docomo,    'Unicode::Emoji::DoCoMo' );
ok( ref $kddi,      'Unicode::Emoji::KDDI' );
ok( ref $softbank,  'Unicode::Emoji::SoftBank' );
ok( ref $google,    'Unicode::Emoji::Google' );
