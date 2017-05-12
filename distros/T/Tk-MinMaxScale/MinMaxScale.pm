package Tk::MinMaxScale;
use Carp;
use Tk;
use Tie::Watch;
#use warnings; #################### for tests ################################
#use Data::Dumper; ################ for tests ################################

use base qw(Tk::Frame);

$VERSION = '0.12';

Construct Tk::Widget 'MinMaxScale';

sub ClassInit {
	my ($class, $mw) = @_;
	$class->SUPER::ClassInit($mw);
}

my $shifted; # is Shift-Key pressed ?
my $DEBUG = 0; # for Tie::Watch

sub Populate {
	my ($cw, $args) = @_;
	$cw->SUPER::Populate($args);

	my $pn = __PACKAGE__;
	delete $args->{'-variable'} && carp("$pn warning: option \"-variable\" is not allowed");

	# let's make the widget horizontal unless defined other specs
	$cw->{'mms_orient'} = delete $args->{'-orient'};
	$cw->{'mms_orient'} = 'horizontal' unless defined $cw->{'mms_orient'};
	my $sideforpack = $cw->{'mms_orient'} eq 'vertical' ? 'left' : 'top';

	$cw->{'mms_command'} = delete $args->{'-command'};
	$cw->{'mms_command'} = sub {} unless defined $cw->{'mms_command'};

	$cw->{'mms_from'} = delete $args->{'-from'};
	$cw->{'mms_from'} = 0 unless defined $cw->{'mms_from'};
	$cw->{'mms_to'} = delete $args->{'-to'};
	$cw->{'mms_to'} = 100 unless defined $cw->{'mms_to'};

	$cw->{'mms_labelmin'} = delete $args->{'-labelmin'};
	$cw->{'mms_labelmax'} = delete $args->{'-labelmax'};

	$cw->{'mms_variablemin'} = delete $args->{'-variablemin'};
	if (!defined $cw->{'mms_variablemin'}) {
		$cw->{'mms_variablemin'} = \$cw->{'mms_valeurmin'};
		${$cw->{'mms_variablemin'}} = $cw->{'mms_from'};
	}
	$cw->{'mms_oldmin'} = ${$cw->{'mms_variablemin'}};

	$cw->{'mms_variablemax'} = delete $args->{'-variablemax'};
	if (!defined $cw->{'mms_variablemax'}) {
		$cw->{'mms_variablemax'} = \$cw->{'mms_valeurmax'};
		${$cw->{'mms_variablemax'}} = $cw->{'mms_to'};
	}
	$cw->{'mms_oldmax'} = $cw->{'mms_to'};

	# create the 'min' Scale subwidget
	my $smin = $cw->Scale(
		%$args,
		-variable => $cw->{'mms_variablemin'},
		-label => $cw->{'mms_labelmin'},
		-orient => $cw->{'mms_orient'},
		-from => $cw->{'mms_from'},
		-to => $cw->{'mms_to'},
	)->pack(-side => $sideforpack);

	watch_variable($cw, 'mms_watchmin', 'mms_variablemin', \&minchange);

	# create the 'max' Scale subwidget
	my $smax = $cw->Scale(
		%$args,
		-variable => $cw->{'mms_variablemax'},
		-label => $cw->{'mms_labelmax'},
		-orient => $cw->{'mms_orient'},
		-from => $cw->{'mms_from'},
		-to => $cw->{'mms_to'},
	)->pack(-side => $sideforpack);

	watch_variable($cw, 'mms_watchmax', 'mms_variablemax', \&maxchange);

	$cw->toplevel->bind("<Key>", [ \&is_shift_key, Ev('s'), Ev('K') ] );
	$cw->toplevel->bind("<KeyRelease>", [ \&is_shift_key, Ev('s'), Ev('K') ] );

	$cw->ConfigSpecs (
		-from => 		[METHOD, undef, undef, undef],
		-to => 			[METHOD, undef, undef, undef],
		-variablemin => [METHOD, undef, undef, undef],
		-variablemax => [METHOD, undef, undef, undef],
		-labelmin => 	[METHOD, undef, undef, undef],
		-labelmax => 	[METHOD, undef, undef, undef],
		-orient => 		[METHOD, undef, undef, undef],
		-command =>     [METHOD, undef, undef, undef],
		DEFAULT => 		[[$smin, $smax], undef, undef, undef],
	);

	$cw->Advertise('smin' => $smin);
	$cw->Advertise('smax' => $smax);
}

sub watch_variable {
	my ($cw, $key, $kvar, $sub) = @_;
	$cw->{$key} = Tie::Watch->new(
		-variable => $cw->{$kvar},
		-store => $sub,
		-debug => $DEBUG,
	);
	$cw->{$key}->{'cw'} = $cw;
}

sub minchange {
	my ($var, $valmin) = @_;
	my $cw = $var->{'cw'};
	my $oldmin = $cw->{'mms_oldmin'};
	my $oldmax = $cw->{'mms_oldmax'};
	my $valmax = ${$cw->{'mms_variablemax'}};
	my $to = $cw->{'mms_to'};
	$valmin = $to if $valmin > $to;
	if ($shifted) {
		my $distance = $oldmax - $oldmin; # distance between sliders
		my $distancemin = $to - $valmin; # distance between min slider and maximum
		if ($distancemin < $distance) {
			${$cw->{'mms_variablemin'}} = $valmax - $distance;
			return;
		} else {
			${$cw->{'mms_variablemax'}} = $valmin + $distance;
		}
	} else {
		${$cw->{'mms_variablemax'}} = $valmin  if $valmin > $valmax;
	}
	$cw->{'mms_oldmin'} = ${$cw->{'mms_variablemin'}};
	$cw->{'mms_oldmax'} = ${$cw->{'mms_variablemax'}};
	$var->Store($valmin);
	# users callback
	my $cmd = $cw->{'mms_command'};
	&$cmd;
}

sub maxchange {
	my ($var, $valmax) = @_;
	my $cw = $var->{'cw'};
	my $oldmin = $cw->{'mms_oldmin'};
	my $oldmax = $cw->{'mms_oldmax'};
	my $valmin = ${$cw->{'mms_variablemin'}};
	my $from = $cw->{'mms_from'};
	$valmax = $from if $valmax < $from;
	if ($shifted) {
		my $distance = $oldmax - $oldmin; # distance between sliders
		my $distancemax = $valmax - $from; # distance between minimum and max slider
		if ($distancemax < $distance) {
			${$cw->{'mms_variablemax'}} = $valmin + $distance;
			return;
		} else {
			${$cw->{'mms_variablemin'}} = $valmax - $distance;
		}
	} else {
		${$cw->{'mms_variablemin'}} = $valmax if $valmax < $valmin;
	}
	$cw->{'mms_oldmin'} = ${$cw->{'mms_variablemin'}};
	$cw->{'mms_oldmax'} = ${$cw->{'mms_variablemax'}};
	$var->Store($valmax);
	# users callback
	my $cmd = $cw->{'mms_command'};
	&$cmd;
}

sub command {
	my ($cw, $val) = @_;
	$cw->{'mms_command'} = $val if $val;
}

sub orient {
	my ($cw, $val) = @_;
	if ($val) {
		$cw->{'mms_orient'} = $val;
		my $sideforpack = $val eq 'vertical' ? 'left' : 'top';
		$cw->Subwidget('smin')->configure(-orient => $val);
		$cw->Subwidget('smin')->pack(-side => $sideforpack);
		$cw->Subwidget('smax')->configure(-orient => $val);
		$cw->Subwidget('smax')->pack(-side => $sideforpack);
	}
	return $cw->{'mms_orient'};
}

sub labelmin {
	my ($cw, $val) = @_;
	if ($val) {
		$cw->{'mms_labelmin'} = $val;
		$cw->Subwidget('smin')->configure(-label => $val);
	}
	return $cw->{'mms_labelmin'};
}

sub labelmax {
	my ($cw, $val) = @_;
	if ($val) {
		$cw->{'mms_labelmax'} = $val;
		$cw->Subwidget('smax')->configure(-label => $val);
	}
	return $cw->{'mms_labelmax'};
}

sub variablemin {
	my ($cw, $val) = @_;
	if ( ($val) && ($val != $cw->{'mms_variablemin'}) ) {
		$cw->{'mms_watchmin'}->Unwatch;
		$cw->{'mms_variablemin'} = $val;
		watch_variable($cw, 'mms_watchmin', 'mms_variablemin', \&minchange);

		my $scale = $cw->Subwidget('smin');
		$scale->configure(-variable => $val);
	}
	return $cw->{'mms_variablemin'};
}

sub variablemax {
	my ($cw, $val) = @_;
	if ( ($val) && ($val != $cw->{'mms_variablemax'}) ) {
		$cw->{'mms_watchmax'}->Unwatch;
		$cw->{'mms_variablemax'} = $val;
		watch_variable($cw, 'mms_watchmax', 'mms_variablemax', \&maxchange);

		my $scale = $cw->Subwidget('smax');
		$scale->configure(-variable => $val);
	}
	return $cw->{'mms_variablemax'};
}

sub from {
	my ($cw, $val) = @_;
	if ( ($val) && ($val < $cw->{'mms_to'}) ) {
		$cw->{'mms_from'} = $val;
		my $scale = $cw->Subwidget('smin');
		$scale->configure(-from => $val);
		$scale = $cw->Subwidget('smax');
		$scale->configure(-from => $val);
	}
	return $cw->{'mms_from'};
}

sub to {
	my ($cw, $val) = @_;
	if ( ($val) && ($val > $cw->{'mms_from'}) ) {
		$cw->{'mms_to'} = $val;
		my $scale = $cw->Subwidget('smin');
		$scale->configure(-to => $val);
		$scale = $cw->Subwidget('smax');
		$scale->configure(-to => $val);
	}
	return $cw->{'mms_to'};
}

sub is_shift_key {
	$shifted = ($_[1] =~ /^Shift/) && ($_[2] =~ /^Shift/) ? 0 : 1;
}

sub minvalue {
	my ($cw, $val) = @_;
	my $scalemin = $cw->Subwidget('smin');
	if ($val) {
		$scalemin->set($val);
		my $scalemax = $cw->Subwidget('smax');
		$scalemax->set($val) if $scalemax->get() < $val;
	}
	$scalemin->get();
}

sub maxvalue {
	my ($cw, $val) = @_;
	my $scalemax = $cw->Subwidget('smax');
	if ($val) {
		$scalemax->set($val);
		my $scalemin = $cw->Subwidget('smin');
		$scalemin->set($val) if $scalemin->get() > $val;
	}
	$scalemax->get();
}

1;

__END__

=head1 NAME

Tk::MinMaxScale - Two B<Scale> to get a (min, max) pair of values

=head1 SYNOPSIS

I<$mms> = I<$parent>-E<gt>B<MinMaxScale>(I<-option> =E<gt> I<value>, ... );

I<$mms> = I<$parent>-E<gt>B<MinMaxScale>(
    -variablemin =E<gt> \$vn,
    -variablemax =E<gt> \$vx,
    -labelmin =E<gt> ...,
    -labelmax =E<gt> ...,
    ...,
);

I<$varmin> = I<$mms>-E<gt>B<minvalue>;

I<$mms>-E<gt>B<minvalue>(10);

I<$varmax> = I<$mms>-E<gt>B<maxvalue>;

I<$mms>-E<gt>B<maxvalue>($var);

=head1 DESCRIPTION

Tk::MinMaxScale is a Frame-based widget wrapping two B<Scale> widgets,
the first acting as a 'minimum' and the second as a 'maximum'.
The value of the 'minimum' B<Scale> is always less than or equal to
the value of the 'maximum' B<Scale>.

The purpose of Tk::MinMaxScale is to get a range of values narrower
than the whole range given by the options B<-from> and B<-to>
(which are applied to both 'minimum' and 'maximum' Scale).
This is done through the variables associated to the options B<-variablemin>
and B<-variablemax>, or via the methods B<minvalue> and B<maxvalues>, see below.

In addition, dragging a slider while pressing a B<Shift> key drags both sliders,
locking their distance. You must hold down the B<Shift> key before dragging a slider.

=head1 OPTIONS

The widget accepts all options accepted by B<Scale> (except for B<-variable> option),
and their default value (with the exception for B<-orient> option which defaults to 'horizontal').

In addition, the following option/value pairs are supported, but not required:

=item B<-labelmin>

The text used as a label for the 'minimum' Scale. Default none.

=item B<-labelmax>

The text used as a label for the 'maximum' Scale. Default none.

=item B<-variablemin>

A reference to a global variable linked with the 'minimum' Scale.

=item B<-variablemax>

A reference to a global variable linked with the 'maximum' Scale.

All other options are applied to both 'minimum' and 'maximum' Scale(s).

=head1 METHODS

The MinMaxScale method creates a widget object. This object supports the configure
and cget methods described in Tk::options which can be used to enquire and modify
the options described above.
The widget also inherits all the methods provided by the generic Tk::Widget class.

The following additional methods are available for MinMaxScale widgets:

=item I<$mms>-E<gt>B<minvalue>(?I<value>?)

If I<value> is defined, sets the 'minimum' Scale of the widget to I<value>
(limited by 'B<-from>' value and the value of the 'maximum' Scale).
Returns the value of the 'minimum' Scale.

=item I<$mms>-E<gt>B<maxvalue>(?I<value>?)

If I<value> is defined, sets the 'maximum' Scale of the widget to I<value>
(limited by the value of the 'minimum' Scale and 'B<-to>' value).
Returns the value of the 'maximum' Scale.

=head1 BUGS / CAVEAT

At present, you are not allowed to configure I<-variablemin> or I<-variablemax> with a variable attached to another Tk::MinMaxScale widget.

=head1 TODO

=item -
switch to a 'one groove, two sliders' scale: I think this is not a so good idea.

=head1 AUTHOR & LICENSE

Jean-Pierre Vidal, E<lt>jeanpierre.vidal@free.frE<gt>

Feedback would be greatly appreciated, including typos, vocabulary and grammar.

This package is free software and is provided 'as is'
without express or implied warranty. It may be used, modified,
and redistributed under the same terms as Perl itself.

=head1 SEE ALSO

B<Tk::Scale>

=cut
