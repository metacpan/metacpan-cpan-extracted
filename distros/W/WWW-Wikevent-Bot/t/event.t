#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use Test::More tests => 44;
use Test::Differences;

BEGIN {
    use_ok('WWW::Wikevent::Event', ':options');
    close STDERR;
}

my $e;
ok( $e= WWW::Wikevent::Event->new(), 'Can create a new event object' );

my $wikitext;

$wikitext = q{<event
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'to_string works on an empty event' );
eq_or_diff( "$e", $wikitext, 'and the quote override works' );

$e->name( 'Test Event' );
$wikitext = q{<event
    name="Test Event"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting name works' );
is( $e->name(), 'Test Event', 'getting name works' );

$e->date( '2007-09-20' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting date works' );
is( $e->date(), '2007-09-20', 'getting date works' );

$e->time( '9pm' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting time works' );
is( $e->time(), '9pm', 'getting time works' );

$e->endtime( '10pm' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting endtime works' );
is( $e->endtime(), '10pm', 'getting endtime works' );

$e->duration( '1h' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting duration works' );
is( $e->duration(), '1h', 'getting duration works' );

$e->duration( '1h' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting duration works' );
is( $e->duration(), '1h', 'getting duration works' );

# price
$e->price( '$10' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    price="$10"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting price works' );
is( $e->price(), '$10', 'getting price works' );

# tickets
$e->tickets( 'http://example.com' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    price="$10"
    tickets="http://example.com"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting tickets works' );
is( $e->tickets(), 'http://example.com', 'getting tickets works' );

# restrictions
$e->restrictions( 'All ages' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting restrictions works' );
is( $e->restrictions(), 'All ages', 'getting restrictions works' );

# lang
$e->lang( 'en' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting lang works' );
is( $e->lang(), 'en', 'getting lang works' );

# locality
$e->locality( 'Chicago' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting locality works' );
is( $e->locality(), 'Chicago', 'getting locality works' );

# venue
$e->venue( 'The Hideout' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
></event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting venue works' );
is( $e->venue(), 'The Hideout', 'getting venue works' );

# desc
$e->desc( 'This is a test description
with two lines' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>This is a test description
with two lines
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting description works' );
is( $e->desc(), 'This is a test description
with two lines', 'getting description works' );

# who
$e->who( [ 'somebody', 'somebody else' ] );
# who_string
is( $e->who_string(), '* <who>somebody</who>
* <who>somebody else</who>
', 'building who string works' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>* <who>somebody</who>
* <who>somebody else</who>

This is a test description
with two lines
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting who works' );
is_deeply( scalar $e->who(), [ 'somebody', 'somebody else' ], 'getting who works' );

# who
$e->who( 'somebody', 'somebody else' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>* <who>somebody</who>
* <who>somebody else</who>

This is a test description
with two lines
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting who as an array works' );
my @whoout = $e->who();
is_deeply( \@whoout, [ 'somebody', 'somebody else' ], 'getting who as an array works' );

# what
$e->what( [ 'something', 'something else' ] );
# what_string
is( $e->what_string(), 
        '<what>something</what>, <what>something else</what>',
        'building what string works' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>* <who>somebody</who>
* <who>somebody else</who>

This is a test description
with two lines
<what>something</what>, <what>something else</what>
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting what works' );
is_deeply( scalar $e->what(), [ 'something', 'something else' ], 'getting what works' );

# what
$e->what( 'something', 'something else' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>* <who>somebody</who>
* <who>somebody else</who>

This is a test description
with two lines
<what>something</what>, <what>something else</what>
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'setting what as an array works' );
my @whatout = $e->what();
is_deeply( \@whatout, [ 'something', 'something else' ], 'getting what as an array works' );

# add_who
$e->add_who( 'somebody else' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>* <who>somebody</who>
* <who>somebody else</who>
* <who>somebody else</who>

This is a test description
with two lines
<what>something</what>, <what>something else</what>
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'add_who works' );
is_deeply( scalar $e->who(), [ 'somebody', 'somebody else', 'somebody else' ], 'getting who works' );

# add_what
$e->add_what( 'something else' );
$wikitext = q{<event
    name="Test Event"
    date="2007-09-20"
    time="9pm"
    endtime="10pm"
    duration="1h"
    lang="en"
    price="$10"
    tickets="http://example.com"
    restrictions="All ages"
    locality="Chicago"
    venue="The Hideout"
>* <who>somebody</who>
* <who>somebody else</who>
* <who>somebody else</who>

This is a test description
with two lines
<what>something</what>, <what>something else</what>, <what>something else</what>
</event>
};
eq_or_diff( $e->to_string, $wikitext, 'add_who works' );
is_deeply( scalar $e->what(), [ 'something', 'something else', 'something else' ], 'getting who works' );



