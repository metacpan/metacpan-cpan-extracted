use strict;
use Test::Base;
use XML::OPML::LibXML;

plan tests => 4 * blocks;

filters { input => 'chomp', title => 'chomp', date => 'chomp', outline => 'chomp' };

run {
    my $block  = shift;
    my $parser = XML::OPML::LibXML->new;
    my $doc    = $parser->parse_file("t/samples/" . $block->input);
    isa_ok $doc, 'XML::OPML::LibXML::Document';
    is $doc->title, $block->title;
    is $doc->date_created, $block->date;
    is( ($doc->outline->[0]->title || $doc->outline->[0]->text), $block->outline);
}

__END__

===
--- input
opml.xml
--- title
Sample Subscriptions
--- date
Tue, 10 Oct 2006 01:15:41 +0900
--- outline
blog.bulknews.net

===
--- input
opml-nested.xml
--- title
Sample Subscriptions
--- date
Tue, 10 Oct 2006 01:15:41 +0900
--- outline
Subscriptions

===
--- input
playlist.opml
--- title
playlist.xml
--- date
Thu, 27 Jul 2000 03:24:18 GMT
--- outline
Background

===
--- input
presentation.opml
--- title
presentation.xml
--- date
Thu, 27 Jul 2000 01:35:52 GMT
--- outline
Welcome to Frontier 5!

===
--- input
specification.opml
--- title
specification.xml
--- date
Thu, 27 Jul 2000 01:20:06 GMT
--- outline
It's XML, of course
