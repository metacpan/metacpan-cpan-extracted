use strict;
use Wiki::Toolkit::TestConfig;
use Test::More tests => 11;

# These are standalone tests for the default formatter module,
# Wiki::Toolkit::Formatter::Default -- they can be adapted to test any
# formatter object without the need for the rest of the distribution.

use_ok( "Wiki::Toolkit::Formatter::Default" );

# Test that the implicit_links flag gets passed through right.
my $raw = "This paragraph has StudlyCaps in.";
my $formatter = Wiki::Toolkit::Formatter::Default->new(
			    implicit_links  => 1,
			    node_prefix     => "wiki.cgi?node=" );

my $cooked = $formatter->format( $raw );
like( $cooked, qr!StudlyCaps</a>!,
      "StudlyCaps turned into link when we specify implicit_links=1" );

$formatter = Wiki::Toolkit::Formatter::Default->new(
			    implicit_links  => 0,
			    node_prefix     => "wiki.cgi?node=" );

$cooked = $formatter->format($raw);
unlike( $cooked, qr!StudlyCaps</a>!,
	"...but not when we specify implicit_links=0" );

$raw = <<EOT;

This is some text that contains an [Extended Link], ie it links to the
node called Extended Link.  It also links to [Another Node|somewhere else],
and contains a WikiWord.

EOT

$formatter = Wiki::Toolkit::Formatter::Default->new(
    implicit_links => 1,
    extended_links => 1,
    node_prefix    => "wiki.cgi?node=" );
my @links_to = $formatter->find_internal_links( $raw );
my %links_hash = map { $_ => 1 } @links_to;

ok( $links_hash{"Extended Link"}, "find_internal_links finds extended link" );
ok( $links_hash{"Another Node"},  "...and titled extended link" );
ok( $links_hash{"WikiWord"},      "...and implicit link" );
is( scalar @links_to, 3, "...and has found the right number of links" );

$formatter = Wiki::Toolkit::Formatter::Default->new(
    implicit_links => 1,
    extended_links => 0,
    node_prefix    => "wiki.cgi?node=" );
@links_to = $formatter->find_internal_links( $raw );
%links_hash = map { $_ => 1 } @links_to;

ok( ! $links_hash{"Extended Link"},
   "find_internal_links doesn't find extended links when they're turned off" );
ok( ! $links_hash{"Another Node"},  "...or titled ones" );
ok( $links_hash{"WikiWord"},      "...but does find implicit links" );

$formatter = Wiki::Toolkit::Formatter::Default->new(
    implicit_links => 0,
    node_prefix    => "wiki.cgi?node=" );
@links_to = $formatter->find_internal_links( $raw );
%links_hash = map { $_ => 1 } @links_to;

ok( ! $links_hash{"WikiWord"},
   "find_internal_links doesn't find implicit links when they're turned off" );
