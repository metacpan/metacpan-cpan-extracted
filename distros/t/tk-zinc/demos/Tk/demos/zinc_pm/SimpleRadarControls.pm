package SimpleRadarControls;

# $Id: SimpleRadarControls.pm,v 1.2 2003/09/15 12:25:06 mertz Exp $
# This simple radar has been initially developped by P. Lecoanet <lecoanet@cena.fr>
# It has been adapted by C. Mertz <mertz@cena.fr> for demo purpose.
# Thanks to Dunnigan,Jack [Edm]" <Jack.Dunnigan@EC.gc.ca> for a bug correction.


use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

$top = 1;

sub new {
    my $proto = shift;
    my $type = ref($proto) || $proto;
    my ($zinc) = @_;
    my $self = {};

    $self{'zinc'} = $zinc;
    $self{'cur_x'} = 0;
    $self{'cur_y'} = 0;
    $self{'cur_angle'} = 0;
    $self{'corner_x'} = 0;
    $self{'corner_y'} = 0;
    
    $self{'tlbbox'} = $zinc->add('group', $top,
				 -sensitive => 0, -visible => 0,
				 -tags => 'currentbbox');
    $zinc->add('rectangle', $self{'tlbbox'}, [-3, -3, +3, +3]);
    $self{'trbbox'} = $zinc->add('group', $top,
				 -sensitive => 0, -visible => 0,
				 -tags => 'currentbbox');
    $zinc->add('rectangle', $self{'trbbox'}, [-3, -3, +3, +3]);
    $self{'blbbox'} = $zinc->add('group', $top,
				 -sensitive => 0, -visible => 0,
				 -tags => 'currentbbox');
    $zinc->add('rectangle', $self{'blbbox'}, [-3, -3, +3, +3]);
    $self{'brbbox'} = $zinc->add('group', $top,
				 -sensitive => 0, -visible => 0,
				 -tags => 'currentbbox');
    $zinc->add('rectangle', $self{'brbbox'}, [-3, -3, +3, +3]);
    $zinc->add('rectangle', $top, [0, 0, 1, 1],
	       -linecolor => 'red', -tags => 'lasso',
	       -visible => 0, -sensitive => 0);

    $zinc->Tk::bind('<Shift-ButtonPress-1>', [\&start_lasso, $self]);
    $zinc->Tk::bind('<Shift-ButtonRelease-1>', [\&fin_lasso, $self]);

    $zinc->Tk::bind('<ButtonPress-2>', sub { my $ev = $zinc->XEvent();
					     my @closest = $zinc->find('closest',
								      $ev->x, $ev->y);
					     print "at point=$closest[0]\n" });
    
    $zinc->Tk::bind('<ButtonPress-3>', [\&press, $self, \&motion]);
    $zinc->Tk::bind('<ButtonRelease-3>', [\&release, $self]);
    
    $zinc->Tk::bind('<Shift-ButtonPress-3>', [\&press, $self, \&zoom]);
    $zinc->Tk::bind('<Shift-ButtonRelease-3>', [\&release, $self]);
    
    $zinc->Tk::bind('<Control-ButtonPress-3>', [\&press, $self, \&rotate]);
    $zinc->Tk::bind('<Control-ButtonRelease-3>', [\&release, $self]);
    
    $zinc->Tk::bind('current', '<Enter>', [\&showbox, $self]);
    $zinc->Tk::bind('current', '<Leave>', [\&hidebox, $self]);

    bless ($self, $type);
    return $self;
}

#
# Controls for the window transform.
#
sub press {
    my ($zinc, $self, $action) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;

    $self->{'cur_x'} = $lx;
    $self->{'cur_y'} = $ly;
    $self->{'cur_angle'} = atan2($ly, $lx);
    $zinc->Tk::bind('<Motion>', [$action, $self]);
}

sub motion {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my @it;
    my @res;
    
    @it = $zinc->find('withtag', 'controls');
    if (scalar(@it) == 0) {
	return;
    }
    @res = $zinc->transform($it[0], [$lx, $ly, $self->{'cur_x'}, $self->{'cur_y'}]);
    $zinc->translate('controls', $res[0] - $res[2], $res[1] - $res[3]);
    $self->{'cur_x'} = $lx;
    $self->{'cur_y'} = $ly;
}

sub zoom {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my $maxx;
    my $maxy;
    my $sx;
    my $sy;
    
    if ($lx > $self->{'cur_x'}) {
	$maxx = $lx;
    } else {
	$maxx = $self->{'cur_x'};
    }
    if ($ly > $self->{'cur_y'}) {
	$maxy = $ly
    } else {
	$maxy = $self->{'cur_y'};
    }
    #avoid illegal division by zero
    return unless ($maxx && $maxy);

    $sx = 1.0 + ($lx - $self->{'cur_x'})/$maxx;
    $sy = 1.0 + ($ly - $self->{'cur_y'})/$maxy;
    $self->{'cur_x'} = $lx if ($lx>0); # avoid ZnTransfoDecompose :singular matrix
    $self->{'cur_y'} = $ly if ($ly>0); # error messages
    $zinc->scale('controls', $sx, $sy);
#   $main::scale *= $sx;
#   main::update_transform($zinc);
}

sub rotate {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my $langle;
    
    $langle = atan2($ly, $lx);
    $zinc->rotate('controls', -($langle - $self->{'cur_angle'}));
    $self->{'cur_angle'} = $langle;
}

sub release {
    my ($zinc, $self) = @_;
    $zinc->Tk::bind('<Motion>', '');
}

sub start_lasso {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my @coords;
    
    $self->{'cur_x'} = $lx;
    $self->{'cur_y'} = $ly;
    $self->{'corner_x'} = $lx;
    $self->{'corner_y'} = $ly;
    @coords = $zinc->transform($top, [$lx, $ly]);
    $zinc->coords('lasso', [$coords[0], $coords[1], $coords[0], $coords[1]]);
    $zinc->itemconfigure('lasso', -visible => 1);
    $zinc->raise('lasso');
    $zinc->Tk::bind('<Motion>', [\&lasso, $self]);
}

sub lasso {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my @coords;
    
    $self->{'corner_x'} = $lx;
    $self->{'corner_y'} = $ly;
    @coords = $zinc->transform($top, [$self->{'cur_x'}, $self->{'cur_y'}, $lx, $ly]);
    $zinc->coords('lasso', [$coords[0], $coords[1], $coords[2], $coords[3]]);
}

sub fin_lasso {
    my ($zinc, $self) = @_;
    my $enclosed;
    my $overlapping;
    
    $zinc->Tk::bind('<Motion>', '');
    $zinc->itemconfigure('lasso', -visible => 0);
    $enclosed = join(', ', $zinc->find('enclosed',
				       $self->{'cur_x'}, $self->{'cur_y'},
				       $self->{'corner_x'}, $self->{'corner_y'}));
    $overlapping = join(', ', $zinc->find('overlapping',
					  $self->{'cur_x'}, $self->{'cur_y'},
					  $self->{'corner_x'}, $self->{'corner_y'}));
    print "enclosed=$enclosed, overlapping=$overlapping\n";
}

sub showbox {
    my ($zinc, $self) = @_;
    my @coords;
    my @it;
    
    if (! $zinc->hastag('current', 'currentbbox')) {
	@it = $zinc->find('withtag', 'current');
	if (scalar(@it) == 0) {
	    return;
	}
	@coords = $zinc->transform($top, $zinc->bbox('current'));

	$zinc->coords($self->{'tlbbox'}, [$coords[0], $coords[1]]);
	$zinc->coords($self->{'trbbox'}, [$coords[2], $coords[1]]);
	$zinc->coords($self->{'brbbox'}, [$coords[2], $coords[3]]);
	$zinc->coords($self->{'blbbox'}, [$coords[0], $coords[3]]);
	$zinc->itemconfigure('currentbbox', -visible => 1);
    }
}

sub hidebox {
    my ($zinc, $self) = @_;
    my $ev = $zinc->XEvent();
    my $lx = $ev->x;
    my $ly = $ev->y;
    my @next;
    
    @next = $zinc->find('closest', $lx, $ly);
    if ((scalar(@next) == 0) ||
	! $zinc->hastag($next[0], 'currentbbox') ||
	$zinc->hastag('current', 'currentbbox')) {
	$zinc->itemconfigure('currentbbox', -visible => 0);
    }
}


