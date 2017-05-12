use strict;
use warnings;

use XUL::Gui ':all';
use Time::HiRes 'time';
my @size = (800, 600);
my @balls;

display debug => 0, Window
	Stack id => 'stack',
		width  => $size[0],
		height => $size[1],
		style  => 'background-color: black',
		Label(id => 'fps', style => 'color: white'),
		delay {
			my $time = time;
			my $frame = 0;
			$_ -= 60 for @size;
			while (1) {
				ID(stack)->appendChild(Ball())
					unless @balls > 100 or $frame % 10;
				$_->update for @balls;
				if (++$frame % 100 == 0) {
                    if ($XUL::Gui::TESTING and @balls >= 25) {
                        quit
                    }
					eval {
						ID(fps)->value = int(100 / ($_ - $time)) . ' fps';
						$time = $_;
					} for time;
					doevents
				} else {
					flush
				}
			}
		};

BEGIN {*Ball = widget {
	unshift @balls, $_;
	my $ball = Box
		left => 0,
		top => 0,
		style => q{
			width:  60px;
			height: 60px;
			border: 2px solid white;
			-moz-border-radius: 30px;
		};

	$_->can('update') = do {
		my ($left, $top) = ($size[0]/2, $size[1]);
		my $dt = 1 + rand 0.015;
		my $dl = 1 - rand 0.015;
		$_ /= 0.2 for $dt, $dl;
		sub {
			$dl *= -1 if $left <= 0 or $left >= $size[0];
			$dt *= -1 if $top  <= 0 or $top  >= $size[1];

			$ball->left = $left += $dl;
			$ball->top  = $top  += $dt;
		}
	};
	$ball
}}
