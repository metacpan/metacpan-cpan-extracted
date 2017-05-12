use strict;
use Test::More 'no_plan';

use Text::Emoticon;

for my $driver (qw( MSN Yahoo )) {
    eval {
        my $emo = Text::Emoticon->new($driver);
        my $f = $emo->filter('Hi :)');
        like $f, qr/img/;
    };
    if ($@) {
        diag( "new version of $driver module needed." );
        pass;
    }
}

