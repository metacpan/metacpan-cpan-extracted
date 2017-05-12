######################################################################
# Test suite for Text::TermExtract
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Text::TermExtract;
use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);

plan tests => 6;

my $text = q{ Hey, hey, how's it going? Wanna go to Wendy's 
              tonight? Wendy's has great sandwiches. };

my $ext = Text::TermExtract->new();

my @words = $ext->terms_extract( $text, {max => 3} );


is($words[0], "sandwiches", "keywords");
is($words[1], "tonight", "keywords");
is($words[2], "hey", "keywords");

$ext->exclude( ['sandwiches'] );
@words = $ext->terms_extract( $text, { max => 3 } );

is($words[0], "tonight", "keywords with exclusions");
is($words[1], "hey", "keywords with exclusions");
is($words[2], "wendy", "keywords with exclusions");
