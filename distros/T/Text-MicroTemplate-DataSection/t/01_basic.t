use strict;
use warnings;

use Test::More;
use Text::MicroTemplate::DataSection 'render_mt';

like render_mt('index.mt'), qr/index!/, 'index ok';

like render_mt('args.mt', 'Perl'), qr!Hello Perl World!, 'args ok';

done_testing;

__DATA__

@@ index.mt
index!

@@ args.mt
Hello <?= $_[0] ?> World.

