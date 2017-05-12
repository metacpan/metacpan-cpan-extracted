use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 18;

use XML::Atom::Entry;
use XML::Atom::Atompub;

my $entry = XML::Atom::Entry->new;

$entry->alternate_link('http://example.com/foo.html');
$entry->edit_media_link('http://example.com/foo.png');
is $entry->alternate_link, 'http://example.com/foo.html';
is $entry->edit_media_link, 'http://example.com/foo.png';

like $entry->as_xml, qr{<link (?:xmlns="http://www.w3.org/2005/Atom" )?rel="alternate" href="http://example.com/foo.html"/>};
like $entry->as_xml, qr{<link (?:xmlns="http://www.w3.org/2005/Atom" )?rel="edit-media" href="http://example.com/foo.png"/>};

$entry->edited('2007-01-01T00:00:00Z');
is $entry->edited, '2007-01-01T00:00:00Z';

my $control = XML::Atom::Control->new;
isa_ok $control, 'XML::Atom::Control';

$control->draft('yes');
is $control->draft, 'yes';
$entry->control($control);

my $content = XML::Atom::Content->new( Version => 1.0 );
$content->src('http://example.com/foo.png');
$content->type('image/png');
is $content->src, 'http://example.com/foo.png';
is $content->type, 'image/png';
$entry->content($content);

my $ns_uri = quotemeta $XML::Atom::Service::DefaultNamespace;
like $entry->as_xml, qr{<app:edited(?: xmlns:app="$ns_uri")?>2007-01-01T00:00:00Z</app:edited>};
like $entry->as_xml, qr{<(?:app:)?control xmlns="$ns_uri">\s*<(?:app:)?draft>yes</(?:app:)?draft>\s*</(?:app:)?control>}ms;


my $sample = "t/samples/sample.atom";
$entry = XML::Atom::Entry->new($sample);
isa_ok $entry, 'XML::Atom::Entry';

is $entry->alternate_link, 'http://example.com/foo.html';
is $entry->edit_media_link, 'http://example.com/foo.png';

is $entry->title, 'Title';
is $entry->edited, '2007-01-01T00:00:00Z';
is $entry->control->draft, 'yes';
is $entry->content->src, 'http://example.com/foo.png';
