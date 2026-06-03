use strict;
use warnings;
use Test::More;
use XML::PugiXML;

# Regression: the default indent of to_string()/save_file() must be a TAB.
# ParseXS mangled the C<"\t"> signature default into a literal space+'t';
# it is now applied in the CODE block instead.

my $doc = XML::PugiXML->new;
$doc->load_string('<r><a>1</a></r>') or die $@;

my $s = $doc->to_string;
like   $s, qr/\t<a>/, 'to_string default indent is a tab';
unlike $s, qr/ t<a>/, 'to_string default indent is not a literal " t"';

my $tmp = "tmp_indent_$$.xml";
$doc->save_file($tmp);
open my $fh, '<', $tmp or die "open $tmp: $!";
local $/;
my $f = <$fh>;
close $fh;
unlink $tmp;
like $f, qr/\t<a>/, 'save_file default indent is a tab';

# an explicit indent is still honored
like $doc->to_string('  '), qr/  <a>/, 'explicit two-space indent honored';

done_testing;
