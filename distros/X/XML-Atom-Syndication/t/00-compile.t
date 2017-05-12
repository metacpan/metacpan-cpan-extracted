my $loaded;
BEGIN { print "1..1\n" }
use XML::Atom::Syndication;
use XML::Atom::Syndication::Category;
use XML::Atom::Syndication::Content;
use XML::Atom::Syndication::Entry;
use XML::Atom::Syndication::Feed;
use XML::Atom::Syndication::Generator;
use XML::Atom::Syndication::Link;
use XML::Atom::Syndication::Person;
use XML::Atom::Syndication::Source;
use XML::Atom::Syndication::Text;
use XML::Atom::Syndication::Util;
use XML::Atom::Syndication::Writer;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
