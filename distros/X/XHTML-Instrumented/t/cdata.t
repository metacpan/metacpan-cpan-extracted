use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<'DATA';
<style type="text/css">
/*<![CDATA[*/
#sml-01 {
  float: left;
  clear: left;
  padding: 0;
}
/*]]>*/
</style>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->get_tag('style');

my $cmp = <<'DATA';

/**/
#sml-01 {
  float: left;
  clear: left;
  padding: 0;
}
/**/
DATA

is($cmp, join('', @{$output->{data}}), 'data');

$output = $x->output(
    bob => 'Bob',
);

$cmp = <<'DATA';
<style type="text/css">
/*<![CDATA[*/
#sml-01 {
  float: left;
  clear: left;
  padding: 0;
}
/*]]>*/
</style>
DATA

is_xml($output, $cmp, 'style');

