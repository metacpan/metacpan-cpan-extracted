use strict;
use warnings;

use Test::More;

eval "use Text::MicroTemplate::DataSectionEx 'render_mt'; 1;";
plan skip_all => 'require Text::MicroTemplate::DataSectionEx to run this test' if $@;

#use Text::MicroTemplate::DataSectionEx 'render_mt';

like render_mt('index'), qr/index!/, 'index ok';

like render_mt('base'), qr!<title>default title</title>!, 'base ok';
like render_mt('child'), qr!<title>override</title>!, 'inheritance ok';

like render_mt('args', 'Perl'), qr!Hello Perl World!, 'args ok';

done_testing;

__DATA__

@@ index.mt
index!

@@ base.mt
<title><? block title => sub { ?>default title<? } ?></title>

@@ child.mt
? extends 'base';

? block title => 'override';

@@ args.mt
Hello <?= $_[0] ?> World.

