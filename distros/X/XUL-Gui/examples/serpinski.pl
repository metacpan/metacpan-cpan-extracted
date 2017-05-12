use strict;
use warnings;
use XUL::Gui 'g->';

my $width = 400;
my $height = sqrt($width**2 - ($width/2)**2);

g->display(
	g->box(
		g->fill,
		g->middle,
		style => q{
			background-color: black;
			padding: 		  40px;
		},
		g->canvas(
			id     => 'canvas',
			width  => $width,
			height => int $height,
		)
	),
	g->delay(sub {
		my $canvas = g->id('canvas')->getContext('2d');
		$canvas->fillStyle = 'white';

		my @points = (
				   [$width/2, 0],
			[0, $height], [$width, $height],
			#[$width/2, $height/2],     # other patterns
			#[$width/4, $height/2],
			#[$width*(3/4), $height/2],
			#[$width/2, $height],
		);
		my ($x, $y) = @{ $points[0] };
		my $num = @points;
		my ($frame, $p);
		while (1) {
			$p = $points[ rand $num ];
			$x = ($x + $$p[0]) / 2;
			$y = ($y + $$p[1]) / 2;

			# draw the point with a little antialiasing
			$canvas->fillRect($x + 1/4, $y + 1/4, 1/2, 1/2);

            $frame++;

            if ($XUL::Gui::TESTING) {
                if    (not $frame % 100  ) {g->flush}
                elsif (not $frame % 1_001) {g->doevents}
                elsif (    $frame > 5_000) {g->quit}
            } elsif (not ++$frame % 1_000) {
				$frame % 100_000
					   ? g->flush
					   : g->doevents # keeps firefox happy
			}
		}
	})
);
