use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 2;

require_ok( 'XHTML::Instrumented' );

my $data = <<'DATA';
<html>
<head>
 <title>head test</title>
</head>
<body>
 <div>
  <span><b><i>@@bob@@</i></b><b>.</b></span>
  <span><b><i>two</i></b><b>.</b></span>
 </div>
</body>
</html>
DATA

my $cmp = <<'DATA';
 <title>head test</title>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

$output = $x->head();

is_xml($output, $cmp, 'head');
