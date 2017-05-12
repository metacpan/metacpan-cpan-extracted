#!/usr/bin/env perl
use strict;
use warnings;
use XUL::Gui;
#$XUL::Gui::TIED_WIDGETS++;

our @size = (19, 19);
$|++;

sub start {
    if ($XUL::Gui::TESTING) {
        delay {
            ID(board)->reset;
            ID(board)->autoplay(2);
            quit;
        }
    }
	display debug=>0, Window id => 'window',
		title => 'perl sweeper',
		MIDDLE
		STYLE(q{
			vbox box {
				margin: 1px;
				border: 1px solid grey;
				-moz-border-radius: 2px;
			}
			.begin, .end {
				background-color: lightgrey;
			}
			.begin:hover {
				background-color: lightgreen;
			}
			.marked {
				background-color: orange;
			}
			.clear {
				background-color: lightlightgrey;
				margin: 1px;
				color: dimgrey;
				border: 1px solid lightgrey;
			}
			.bomb {
				background-color: darkorange;
				border-color: red;
			}
			.bomb *, .clicked * {
				font-size: 15px;
				font-weight: 900;
			}
			.clicked {
				background-color: red;
				border-color: orange;
			}
		}),
		Hbox( MIDDLE
		#	Label( id => 'time', value => '00:00' ),
			TextBox( id => 'size', value => '20x20', width=>60 ),
			TextBox( id => 'mines', value => 30, type=>'number', width=>40 ),
			Button( BLUR label => 'reset', oncommand => sub {
				ID(board)->reset
			}),
#            Button( BLUR label => 'autoplay', oncommand => sub {
#				ID(board)->autoplay(10)
#			}),
			#Button( label => 'mem test', oncommand => sub {
			#	use Time::HiRes 'time';
			#	my $time;
			#	my $interval = 0;
			#	while (1) {
			#		$time = time;
			#
			#		ID(board)->explode(0);
			#		doevents;
			#		ID(board)->reset;
			#
			#		$interval = ($interval * 3 + (time - $time)) / 4;
			#		print 'objects: ', scalar( keys %ID ), ", fps: ", 1/$interval, "\n";
			#	}
			#}),
			#Button( label => 'find cycle', oncommand => sub {
			#	use Devel::Cycle;
			#	my $len = keys %ID;
			#	for (keys %ID) {
			#		print "\n$_ ${\($len--)}: ";
			#		print find_cycle $ID{$_};
			#	}
			#}),
		),
		Board( id => 'board' ),
}

*Board = widget {Vbox id => 'board', delay {shift->reset} $_}
	playing => 1,
	reset => sub {
		my $self = shift;
		@size = map {$_ - 1} split /\D/ => $ID{size}->value;
		$$self{playing} = 1;
		$$self{board}->replaceChildren( $self->make_cells );
		gui 'window.resizeTo(', 40 + $size[1]*22, ', ', $size[0]*22 + 90, ')';
		$$self{cleared} = 0;
	},
	make_cells => sub {
		my $self = shift;
		$$self{mines} = my $mines = shift || ID(mines)->value;
		my %mines;
		$$self{win} = ($size[0]+1) * ($size[1]+1);
		while (keys %mines < $mines) {
			my ($x, $y) = map int(rand($_ + 1)) => @size;
			redo if $mines{"$x,$y"}++;
		}
		$$self{near}  = [];
		$$self{clear} = [];
		$$self{cells} = [
			map { my $x = $_;
				[map { my $y = $_;
					my $mine = !!$mines{"$x,$y"};
					if ($mine) {
						for my $x ($x - 1 .. $x + 1) {
							next if $x < 0 or $x > $size[0];
							for my $y ($y - 1 .. $y + 1) {
								next if $y < 0 or $y > $size[1];
								$$self{near}[$x][$y]++;
							}
						}
					}
					Cell(x => $x, y => $y, mine => $mine)
				} 0 .. $size[1]]
			} 0 .. $size[0]
		];
		map {Hbox @$_} @{ $$self{cells} }
	},
	click => sub {
		my ($self, $cell, $x, $y) = @_;
		return if $$cell{W}{marked};
		if ($$cell{W}->mine) {
			$self->explode($cell);
		} else {
			$self->clear($x, $y);
			$self->win if $self->check;
		}
	},
	check => sub {
		my $self = shift;
		$$self{cleared} + $$self{mines} == $$self{win}
	},
	win   => sub {
		my $self = shift;
		$$self{playing} = 0;
		alert 'you win' unless $$self{autoplay};
	},
	clear => sub {
		my $self = shift;
		my @clear = \@_;

		while (@clear) {
			my ($cx, $cy) = @{ shift @clear };
			next if $$self{cells}[$cx][$cy]{W}{marked};
			unless ($$self{clear}[$cx][$cy]++) {
				$$self{cleared}++;
				my $near = $$self{near}[$cx][$cy];
				$$self{cells}[$cx][$cy]{W}->clear($near);

				unless ($near) {
					for my $x ($cx - 1 .. $cx + 1) {
						next if $x < 0 or $x > $size[0];
						for my $y ($cy - 1 .. $cy + 1) {
							next if $y < 0 or $y > $size[1];
							next if $y == $cy and $x == $cx;
							push @clear, [$x, $y];
						}
					}
				}
			}
		}
	},
	explode => sub {
		my ($self, $clicked) = @_;
		$$self{playing} = 0;
		for my $x (0 .. $size[0]) {
			for my $y (0 .. $size[1]) {
				my $cell = $$self{cells}[$x][$y];
				if ($$cell{W}->mine) {
					$$cell{W}->explode($cell == $clicked)
				} else {
					$cell->class = 'end' unless $$cell{W}{clear}
											 or $$cell{W}{marked};
				}
			}
		}
	},
    autoplay => sub {
        use List::Util 'shuffle';
        my ($self, $rounds) = @_;
        local $$self{autoplay} = 1;
        for (1 .. $rounds || 1) {
            my @clear = shuffle grep !$$_{W}->mine,
                                map @$_ => @{$$self{cells}};

            while (my $cell = shift @clear) {
                unless ($$cell{W}{clear}) {
                    $self->click($cell, $$cell{W}->x, $$cell{W}->y);
                    doevents;
                }
            }
            $self->explode(0);
            doevents;
            $self->reset;
        }
    };;


*Cell = widget {
	my ($x, $y) = @{$_{A}}{qw/x y/};
	Box id => "box", class => 'begin', minwidth => 20, minheight => 20, maxwidth=>20, maxheight=>20,
		onclick => sub {
			return unless $$_{P}{W}{playing};
			if (pop->button == 0) {
				$$_{P}{W}->click($_, $x, $y)
			} else {
				if ($_->class eq 'begin' or $$_{W}{marked}) {
					$$_{W}->mark;
				}
			}
		}
}
	clear => sub {
		my ($self, $near) = @_;

		$$self{clear}++;
		$$self{box}->class = 'clear';
		$$self{box}->appendChild(Label value => $near) if $near;
	},
	mark => sub {
		my $self = shift;
		toggle $$self{marked};
		$$self{box}->class = $$self{marked} ? 'marked' : 'begin';
	},
	explode => sub {
		my ($self, $clicked) = @_;
		$$self{box}->class = $clicked ? 'clicked' : 'bomb';
		$$self{box}->appendChild(Label value => '*');
	};

start;
