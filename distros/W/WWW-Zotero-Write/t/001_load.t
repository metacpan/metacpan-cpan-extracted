# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WWW::Zotero::Write' ); }

my $object = WWW::Zotero::Write->new ();
isa_ok ($object, 'WWW::Zotero::Write');



