use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<'DATA';
<div>
 <span><b><i>@@bob@@</i></b><b>.</b></span>
 <span><b><i>two</i></b><b>.</b></span>
</div>
DATA

my $cmp = <<'DATA';
<div>
 <span><i>Bob</i>.</span>
 <span><i>two</i>.</span>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '', filter => sub {
    my %p = @_;
    my $tag = $p{tag};
    my $args = $p{args};
    if ($tag eq 'b') {
	$args->{class} = ':removetag';
    }
});

my $output = $x->output(
    bob => 'Bob',
);

is_xml($output, $cmp, 'simple');

$data = <<'DATA';
<div>
 <span><b><i>@@bob.adsf@@</i></b><b>.</b></span>
 <span><b><i>three</i></b><b>.</b></span>
</div>
DATA

$cmp = <<'DATA';
<div>
 <span><b>Bob</b><b>.</b></span>
 <span><b>three</b><b>.</b></span>
</div>
DATA

$x = XHTML::Instrumented->new(
    name => \$data, type => '',
    filter => sub {
	my %p = @_;
	my $tag = $p{tag};
	my $args = $p{args};
	if ($tag eq 'i') {
	    $args->{class} = ':removetag';
	}
    });

$output = $x->output(
    bob => 'Bob',
);

is_xml($output, $cmp, 'simple');

