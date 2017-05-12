package NoGetBlock;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub rule { 
    return { line => "hoge" };
};

1;
