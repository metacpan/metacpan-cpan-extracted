use strict;
use warnings;

use Test::RequiresInternet ('www.xkcd.com' => 80);

use Test::More tests => 12;
use Test::Exception;
use WWW::XKCD::AsText;

my $xkcd = WWW::XKCD::AsText->new;
isa_ok($xkcd, 'WWW::XKCD::AsText');

my $barrel = "[[A boy sits in a barrel which is floating in an ocean.]]
Boy: I wonder where I'll float next?
[[The barrel drifts into the distance. Nothing else can be seen.]]
{{Alt: Don't we all.}}";

is( $xkcd->retrieve(1), $barrel,              'retrieve returns correct text on 1' );
is( $xkcd->text,        $barrel,              'text returns correct text on 1'     );
is( $xkcd->uri,         'http://xkcd.com/1/', 'uri returns correct uri on 1'       );
is( $xkcd->error,       undef,                'no error is returned on 1'          );

dies_ok { $xkcd->retrieve(' ') } 'dies on \s';
dies_ok { $xkcd->retrieve('a') } 'dies on a';
dies_ok { $xkcd->retrieve( 0 ) } 'dies on 0';

is( $xkcd->retrieve(999999), undef,                     'retrieve returns undef on 999999'  );
is( $xkcd->text,             undef,                     'text returns undef on 999999'      );
is( $xkcd->uri,              'http://xkcd.com/999999/', 'uri returns correct uri on 999999' );
is( $xkcd->error,            '404 Not Found',           '404 error is returned on 999999'   );