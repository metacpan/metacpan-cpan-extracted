#!perl -w
use strict;
use Text::ClearSilver;

my $tcs = Text::ClearSilver->new;

$tcs->process(\<<'TCS', {});
<?cs def:add(x, y) ?>[<?cs var:#x+#y ?>]<?cs /def ?>
<?cs def:cat(x, y) ?>[<?cs var:x+y ?>]<?cs /def?>
10 + 20 = <?cs call add(10, 20) ?> (as number)
15 + 25 = <?cs call cat(15, 25) ?> (as string)
TCS
