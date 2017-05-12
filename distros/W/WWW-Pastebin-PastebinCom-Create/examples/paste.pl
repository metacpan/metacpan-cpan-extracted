#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(../lib  lib);
use WWW::Pastebin::PastebinCom::Create;

my $bin = WWW::Pastebin::PastebinCom::Create->new;

$bin->paste(
    text    => q{
        #!/usr/bin/env perl

        use strict;
        use warnings;
        use lib qw(../lib  lib);
    },
    format  => 'perl',
    expiry  => 'asap',
    desc    => 'test paste',
    private => 1,
) or die $bin->error;

print "Your paste uri is $bin\n";

