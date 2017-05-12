#! /usr/bin/env perl

package Tk::Panel;

use 5.014000;
use warnings;
use strict;

use vars qw(@ISA $VERSION);

use Tk;
use Carp;
require Tk::Widget;

our $VERSION = '1.5';

Construct Tk::Widget 'Panel';
use base qw(Tk::Derived Tk::Frame);

sub debug {};

# Class initialisation function.
# Called exactly once for each MainWindow widget tree, just
# before the first widget is created.
sub ClassInit
{
	debug "args: @_\n";
	# nothing.
}

# Constructor.  Uses new inherited from base class
sub Populate
{
	debug "args: @_\n";

	my $self = shift;

	$self->SUPER::Populate(@_);

	# Create 2 more frames, boundary with groove, and inside.
	$self->{boundary}	= $self->Component('Frame', 'boundary');
	$self->{inside}		= $self->Component('Frame', 'inside');
	# Create the title widgets.
	$self->{label}	= $self->Component('Label', 'label');

	$self->{check}	= $self->Component('Checkbutton', 'check',
			-variable	=> \$self->{Configure}->{'-show'},
			-command	=> [ 'refresh', $self ],
		);

	#debug "boundary: $self->{boundary}\n";
	#debug "inside: $self->{inside}\n";
	#debug "check: $self->{check}\n";
	#debug "label: $self->{label}\n";

	# Set up extra configuration
	$self->ConfigSpecs(
		'-relief'	=> [$self->{boundary},'relief','Relief','groove'],
		'-border'	=> [$self->{boundary},'borderwidth','BorderWidth', 3],
		'-background'	=> [['SELF','DESCENDANTS'],undef,undef, undef],
		'-foreground'	=> [['SELF','DESCENDANTS'],undef,undef, undef],

		'-margin'	=> ['PASSIVE','margin','Margin', 10],

		'-text'		=> [
				[$self->{check}, $self->{label}],
				'text','Text', ''],

		'-show'		=> ['PASSIVE','','', 1],

		'-flatheight'	=> ['PASSIVE','','', 'standard'],

		'-state'	=> [$self->{check},'','', 'active'],
		'-toggle'	=> ['PASSIVE','','', 1],

		'-fg'		=> '-foreground',
		'-bg'		=> '-background',
	);

	# Where to create children.
	$self->Delegates('Construct' => $self->{inside});

	$self;
}

# DoWhenIdle seems to be replaced by afterIdle in Tk800.018.
sub afterIdle { &DoWhenIdle; }

;## Update the widget when you get a chance.
sub DoWhenIdle
{
	debug "args: @_\n";

	my $self = shift;

	$self->refresh();
}

sub refresh
{
	debug "args: @_\n";

	my $self = shift;

	local ($_);

	# ------------- display the title. ---------------

	# Choose which title widget is on and which is off.
	my ($on, $off) = $self->cget('-toggle') ?
				qw(check label) :
				qw(label check) ;

	# Turn off the one we don't want.
	$self->{$off}->placeForget();

	# position the one we do want to see.
	my $h = $self->{$on}->ReqHeight;
	my $b = $self->cget('-border');

	debug "label height $h\n";

	$self->{$on}->place(
		'-in'	=> $self->{boundary},
		'-relx'	=> 0.05,
		'-y'	=> -0.5 * $h - 0.5*$b,
	);

	# If there is no real title and its the label that
	# requested then don't show it. Otherwise a gap 
	# appears in the boundary.
	$self->{label}->placeForget()
		if ($self->cget('-text') eq '' && $on eq 'label');

	# ----------  Set the margins. -----------------
	my $m = $self->cget('-margin');

	my @config = (
		-padx	=> $m,
		-pady	=> $m,
		-fill	=> "both",
		-expand => "y",
	);

	$self->{boundary}->pack(@config);
	$self->{inside}->pack(-in=>$self->{boundary}, @config);

	# ----------------------------------------------

	unless ($self->cget('-show'))
	{
		debug "inside hidden.\n";

		# what is the closed height.
		my $ht = $self->cget('-flatheight');
		$ht = $self->{$on}->ReqHeight if ($ht eq 'standard');
		$ht = $self->cget('-border') if ($ht eq 'flat');

		croak "Option '-flatheight' must be a number, 'flat' or 'standard' (not '$ht').\n"
			unless ($ht =~ /^\d+$/);

		# We need to known the width so that we can set it
		# after hiding the inside so that the width
		# doesn't jump.
		my $wt = $self->{boundary}->Width;

		# collapse the boundary.
		$self->{boundary}->configure(
			'-height' => $ht,
			'-width' => $wt,
		);

		# hide the inside.
		$self->{inside}->packForget();
	}
}

# overload these.
sub gridColumnconfigure
{
	(shift)->{'inside'}->gridColumnconfigure(@_);
}
sub gridRowconfigure
{
	(shift)->{'inside'}->gridRowconfigure(@_);
}

;# Called as the widget is destroyed.
sub OnDestroy
{
	debug "args: @_\n";
}

;######################################################################

sub test
{

	#use Tk;
	#use Tk::Panel;

	eval 'sub Panel::debug {
		my ($package, $filename, $line,
				$subroutine, $hasargs, $wantargs) = caller(1);
		print STDERR "$subroutine: ";

		if (@_) {print STDERR @_; }
		else    {print "Debug $filename line $line.\n";}
	}; ';

	# colours.
	my $lightgreen	= '#90ee90';
	my $lightblue	= '#9090ee';
	my $darkred	= '#8b0000';

	# ---- Main Window -----------------------------
	my $top = MainWindow->new();

	#-------------- Top panel. -----------------------
	my $g = $top->Panel('-text' => 'hello', '-fg'=>'red')->pack(
		-expand=>'yes', -fill=>'x',
	);

	my @pack = ('-side'=>'left');
	$top->after(10000, [ 'configure', $g, '-margin' => 20 ]);
	$top->after(20000, [ 'configure', $g, '-text' => 'Top panel' ]);

	# pack everything inside the inner frame.
	$b = $g->Button(
		-text		=> 'Exit',
		-command	=> sub {exit;},
	)->pack(@pack);

	$b = $g->Button(-text=>'hello', -command => [ 'configure', $g, '-text', 'hello'] )->pack(@pack);
	$b = $g->Button(-text=>'goodbye', -command => [ 'configure', $g, '-text', 'goodbye'] )->pack(@pack);
	$b = $g->Button('-text'=>'no label', -command => [ 'configure', $g, '-text', ''] )->pack(@pack);
	$b = $g->Button(-text=>'boo', -command => [ 'configure', $g, '-text', 'boo'] )->pack(@pack);
	$g->Button(
		-text => "toggle",
		-command => sub { 
			$g->configure('-toggle'=>!$g->cget('-toggle')); 
			},
	)->pack();


	#-------------- bottom panel. -----------------------
	my $h = $top->Panel(
		-fg	=> $darkred,
		-bg	=> $lightblue,
		-text	=> 'bottom panel',
		-toggle	=> 0,
		-flatheight	=> 'flat',
	)->pack();

	$b = $h->Button(
		-text => "double margin",
		-command => sub { $h->configure('-margin'=>$h->cget('-margin')*2); },
	)->pack();

	$b = $h->Button(
		-text => "halve margin",
		-command => sub { $h->configure('-margin'=>$h->cget('-margin')/2); },
	)->pack();

	$b = $h->Button(
		-text => "double border",
		-command => sub { $h->configure('-border'=>$h->cget('-border')*2); },
	)->pack();

	$b = $h->Button(
		-text => "halve border",
		-command => sub { $h->configure('-border'=>$h->cget('-border')/2); },
	)->pack();

	$b = $h->Button(
		-text => "toggle",
		-command => sub { 
			$h->configure('-toggle'=>!$h->cget('-toggle')); 
			},
	)->pack();

	$b = $h->Button(
		-text => "disable",
		-command => sub { $h->configure('-state'=>'disabled');},
	)->pack();
	$b = $h->Button(
		-text => "active",
		-command => sub { $h->configure('-state'=>'active');},
	)->pack();

	$b = $h->Button(
		-text => "unpack",
		-command => sub {
			$h->configure('-show'=>0);
			$h->after(3000, [ 'configure', $h, '-show' => 1]);
		},
	)->pack();

	# Start demonstration.
	MainLoop;
}

&test if ($0 eq __FILE__);

1;

__END__

=head1 NAME

Tk::Panel - A collapsable frame with title.

=head1 SYNOPSIS

  use Tk;
  use Tk::Panel;

  $m = $parent->Panel(
  	-relief	=> <relief of inner boundary>,
  	-border	=> <border size of inner boundary>
  	-text	=> <text of title>
  	-toggle	=> <0|1>
  	-state	=> <normal|active|disabled>
  	-show	=> 1|0
  );

  $m->Widget()->pack();

=head1 DESCRIPTION 

This is a frame type object with a boundary and a title.
The title can include a checkbox allowing the contents of
the panel to be collapsed.

Further widgets can be created inside the Panel.

=head1 OPTIONS

=head2 -relief => <relief of inner boundary>

Sets the relief of inner boundary. The default is C<raised>.

=head2 -border => <border size of inner boundary>

Sets the relief of inner boundary.

=head2 -text => "title text"

Sets the title of the Panel.

=head2 -toggle => 1|0

This sets if the Panel can be collapsed via the title.

=head2 -state => <normal|active|disabled>

This sets the state of the check button version of the title.

=head2 -show => 1|0

This sets if the Panel is expanded or collapsed.

=head1 SEE ALSO

See L<Tk> for Perl/Tk documentation.

=head1 AUTHOR

Anthony R Fletcher, E<lt>a r i f 'a-t' c p a n . o r gE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1998-2014 by Anthony R Fletcher.
All rights reserved.
Please retain my name on any bits taken from this code.
This code is supplied as-is - use at your own risk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

