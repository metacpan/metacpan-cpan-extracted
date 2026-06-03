use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use XML::PugiXML;

# load_string takes a C string; an embedded NUL would silently truncate the
# document and parse a different (shorter) one. NUL is invalid in XML 1.0, so
# it must be rejected with a clear error rather than succeed on the prefix.
my $doc = XML::PugiXML->new;

eval { $doc->load_string("<root/>\x00trailing") };
like $@, qr/embedded NUL/, 'load_string rejects an embedded NUL byte';

# NUL-free XML still loads and parses normally.
ok $doc->load_string('<root><a/></root>'), 'load_string still works for NUL-free XML';
like $doc->to_string, qr{<root}, '...and the tree serializes back';

# Tree-mutation methods share the same NUL-safe argument typemap, so an
# embedded NUL in a name/value/content is rejected rather than silently
# truncating the stored data.
$doc->load_string('<root/>');
my $root = $doc->root;
eval { $root->set_name("bad\x00name") };
like $@, qr/embedded NUL/, 'set_name rejects an embedded NUL';
eval { $root->set_attr('k', "bad\x00val") };
like $@, qr/embedded NUL/, 'set_attr rejects an embedded NUL in the value';
eval { $root->append_child("bad\x00child") };
like $@, qr/embedded NUL/, 'append_child rejects an embedded NUL in the name';
ok eval { $root->set_attr('k', 'ok'); 1 }, 'set_attr still works for a NUL-free value';

done_testing;
