use strict;
use YATT::Lite::Macro;
use 5.010; no if $] >= 5.017011, warnings => "experimental";

Macro given => sub {
  my ($cgen, $node) = @_;
  $cgen->node_sync_curline($node);
  my ($path, $body, $primary, $head, $foot) = $cgen->node_extract($node);
  # my ($given) = $cgen->terse_dump($primary);
  # my ($given) = $cgen->terse_dump($primary->[0]);
  my $result = "";
  $result .= q!no warnings "experimental";! if $] >= 5.017011;
  $result .= "given (";
  $result .= $cgen->as_list($cgen->node_body($primary->[0]));
  $result .= ") {";
  # XXX: 改行
  #my ($cases) = $cgen->terse_dump($foot);
  foreach my $arg (lexpand($foot)) {
    $cgen->node_sync_curline($arg);
    given ($cgen->node_path($arg)->[1]) {
      when ('when') {
	my @atts = lexpand($cgen->node_attlist($arg));
	$result .= "when (" . $cgen->as_list($cgen->node_body($atts[0]));
	$result .= ") ";
	local $cgen->{scope} = $cgen->mkscope({}, $cgen->{scope});
	$result .= '{'.$cgen->as_print
	  ('}', scalar $cgen->node_body($arg));
	# $result .= '{'.$cgen->terse_dump($cgen->node_body($arg)).'}';
      }
      when ('default') {
	local $cgen->{scope} = $cgen->mkscope({}, $cgen->{scope});
	$result .= 'default {'.$cgen->as_print
	  ('}', scalar $cgen->node_body($arg));
      }
      default {
	$cgen->generror("Unknown option %s", $_);
      }
    }
  }
  $result .= "}";
  # $result .= $cgen->terse_dump($node);
  \ $result;
};
