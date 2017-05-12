use strict;
use warnings;

use Test::More tests => 5;
use Test::XML;

use Data::Dumper;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <span id="bob.if">bob</span>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->output(
);

my $cmp = <<DATA;
<div>
</div>
DATA

is_xml($output, $cmp, 'not defined');

$output = $x->output(
    bob => $x->replace(text => 'this is bob.'),
);

$cmp = <<DATA;
<div>
 <span id="bob.if">bob</span>
</div>
DATA

is_xml($output, $cmp, 'defined');

$data = <<DATA;
<div>
 <div id="bob.if">
  <span id="bob">bob</span>
 </div>
</div>
DATA

$x = XHTML::Instrumented->new(name => \$data, type => '');

$output = $x->output(
    bob => $x->replace(text => 'this is bob.'),
);

$cmp = <<DATA;
<div>
 <div id="bob.if">
  <span id="bob">this is bob.</span>
 </div>
</div>
DATA

is_xml($output, $cmp, 'defined');

$output = $x->output(
);

$cmp = <<DATA;
<div>
</div>
DATA

is_xml($output, $cmp, 'defined');

__END__

if
