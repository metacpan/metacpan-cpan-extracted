use strict;
use Test::More tests => 2;

use_ok 'Text::Variations';

{
    my $tv = Text::Variations->new("Hey {{person}} - don't be so {{emotion}}!");
    is    #
        $tv->generate( { person => 'Jude', emotion => 'sad' } ),
        "Hey Jude - don't be so sad!",    #
        'interpolation works';
}
