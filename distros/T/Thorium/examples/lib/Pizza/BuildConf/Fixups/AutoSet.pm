package Pizza::BuildConf::Fixups::AutoSet;

use strict;
use feature ':5.10';

sub refresh {
    say("\n", '*' x 80);
    say("In ", __PACKAGE__, " you can potentially change any config data...");
    say("Set auto_fixup_module for Pizza::BuildConf in ./configure");
    say('*' x 80, "\n");
}

1;
