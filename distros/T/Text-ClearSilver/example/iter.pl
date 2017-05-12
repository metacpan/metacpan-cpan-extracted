#!perl -w
use strict;
use Text::ClearSilver;

my $tcs = Text::ClearSilver->new;

my $template = <<'TCS';
For each data:
<?cs each:item = data ?>
<?cs var:name(item) ?>: <?cs var:item ?>
<?cs /each ?>
TCS

$tcs->process(\$template, { data => [qw(foo bar baz)] });

$tcs->process(\$template, { data => { first_name => 'Goro',  last_name => 'Fuji' } });
