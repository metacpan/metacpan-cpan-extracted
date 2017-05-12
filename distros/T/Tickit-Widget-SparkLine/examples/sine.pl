#!/usr/bin/env perl
use strict;
use warnings;
use Tickit;
use Tickit::Widget::VBox;
use Tickit::Widget::SparkLine;
use POSIX qw(tan);

use Tickit::Style;
Tickit::Style->load_style(<<'EOF');
VBox {
	spacing: 1;
}
SparkLine.sin {
fg: 'red';
}
SparkLine.cos {
fg: 'green';
}
SparkLine.tan {
fg: 'blue';
b: 1;
}
EOF

use constant PI => 3.141592653589793238462643383279502884;
my $vbox = Tickit::Widget::VBox->new;
my $tickit = Tickit->new(root => $vbox);

for my $func (qw(sin cos tan)) {
	my $w = Tickit::Widget::SparkLine->new( data => [ (0) x $tickit->cols ], class => $func)->resample_mode('max');
	my $ph = 0.0;
	my $code;
	my $f = CORE->can($func) ? \&{'CORE::' . $func} : \&{'POSIX::' . $func};
	$code = sub {
		# Chosen to give ~5s animation time
		$ph += PI / 25;
		my $v = do { no strict 'refs'; 4 * $f->($ph); };
		$v = 4 if $v > 4;
		$v = -4 if $v < -4;
		$w->shift;
		$w->push(4 + $v);
		$tickit->timer(after => 0.10, $code);
	};
	$code->();
	$vbox->add($w, expand => 1);
}
$tickit->run;

