use strict;
use warnings;

use XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing
BEGIN { eval { require Test::LongString; Test::LongString->import; 1 } or *is_string = \&is; }

sub f { use utf8; XML::Atom::SimpleFeed->new( qw( title ß id € generator • updated 0 ), @_ )->as_string . "\n" }

is_string f, <<"", 'us-ascii';
<?xml version="1.0" encoding="us-ascii"?>
<feed xmlns="http://www.w3.org/2005/Atom"><title type="html">&#223;</title><id>&#8364;</id><generator>&#8226;</generator><updated>1970-01-01T00:00:00Z</updated></feed>

is_string f( -encoding => 'latin1' ), <<"", 'latin1';
<?xml version="1.0" encoding="latin1"?>
<feed xmlns="http://www.w3.org/2005/Atom"><title>\x{df}</title><id>&#8364;</id><generator>&#8226;</generator><updated>1970-01-01T00:00:00Z</updated></feed>

is_string f( -encoding => 'utf8' ), <<"", 'utf8';
<?xml version="1.0" encoding="utf8"?>
<feed xmlns="http://www.w3.org/2005/Atom"><title>\x{c3}\x{9f}</title><id>\x{e2}\x{82}\x{ac}</id><generator>\x{e2}\x{80}\x{a2}</generator><updated>1970-01-01T00:00:00Z</updated></feed>

done_testing;
