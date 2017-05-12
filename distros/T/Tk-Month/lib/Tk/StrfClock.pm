#! /usr/bin/env perl

package Tk::StrfClock;

require Exporter;

use 5;
use strict;
use warnings;

use Carp;
use POSIX;
use Tk;
use Tk::Label;
use Tk::Button;
use Tk::Menubutton;
use Tk::Optionmenu;

our $VERSION	= '1.5';

use vars qw(@ISA $AUTOLOAD %flags);

@ISA	= qw (Exporter);
our @EXPORT = qw(StrfClock);

Construct Tk::Widget 'StrfClock';

;# Extra flags and their defaults.
%flags = (
	-type		=> 'Label',	# Label, Button, etc..
	-format		=> '%c',	# strftime string
	-update		=> 'a',		# auto
	-advance	=> 0,		# seconds
	-ontick		=> undef,	# function
	-action		=> undef,	# =~ transformation
);

sub debug {};
;#sub debug { print STDERR @_; };

;# Create the widget.
sub new
{
	debug "args: @_\n";

	my $class = shift;
	my $top = shift;
	
	# bless
	my $self = {};
	bless $self, $class;
	debug "self is $self.\n";

	# Initialise.
	$self->init($top, @_);

	$self;
}

;# Initialise the widget.
sub init
{
	debug "args: @_\n";

	# Grab the args.
	my $self = shift;
	my $top = shift;
	my %args = @_;

	# Add defaults to the widget.
	while ( my($k, $v) = each(%flags) )
	{
		$self->{$k} = $v;
	}

	# Configure the Tk::StrfClock options.
	for my $a (keys %flags)
	{
	 	next unless (exists($args{$a}));
		$self->{$a} = delete($args{$a});

		debug "saving arg $a.\n";
	}

	# Construct the base widget depending on the type.
	if    ($self->{'-type'} eq 'Label')	
			{ $self->{base} = $top->Label(%args); }
	elsif ($self->{'-type'} eq 'Button')
			{ $self->{base} = $top->Button(%args); }
	elsif ($self->{'-type'} eq 'Menubutton')	
			{ $self->{base} = $top->Menubutton(%args); }
	elsif ($self->{'-type'} eq 'Optionmenu')	
			{ $self->{base} = $top->Optionmenu(%args); }
	else	
	{
		carp "__PACKAGE__: unknown type '$self->{'-type'}'";

		$self->{'-type'} = 'Label';
		$self->{base} = $top->Label(%args); 
	}

	# Sync the string in the base widget.
	$self->{datetime} = '';
	$self->{base}->configure(-textvariable => \$self->{datetime});

	# Start ticking.
	$self->tick();

	# return the object.
	$self;
}

;# Pack is just the same as the base widget.
;# Must return the correct object.
sub pack { my $self = shift; $self->{base}->pack(@_); $self; }

;# Overload the configure function.
sub configure
{
	# Grab the widget and the args.
	my $self = shift;
	my %args = @_;
	##for (keys %args) { debug "$_ '$args{$_}'\n"; };

	# Stop -type configures.
	if (exists($args{'-type'}))
	{
		carp "Cannot configure type now!";
		delete($args{'-type'});
	}
	
	# Configure the other Tk::StrfClock options.
	for my $a (keys %flags)
	{
	 	next unless (exists($args{$a}));
		$self->{$a} = delete($args{$a});
	}

	# Configure the base widget.
	$self->{base}->configure(%args);

	# Retick after the configure - this resets the tick
	# and does a refresh to boot.
	$self->tick();
}

;# The cget function....
sub cget
{
	# Grab the widget and the args.
	my $self = shift;

	# Check for private members
	for my $a (@_)
	{
		for my $b (keys %flags)
		{
			return $self->{$a} if ($a eq $b);
		}
	
		# Pass onto the base widget
		return $self->{base}->cget($a);
	}

}

;# DoWhenIdle seems to be replaced by afterIdle in Tk800.018.
sub afterIdle { &DoWhenIdle; }

sub DoWhenIdle
{
	debug "args: @_\n";

	my $self = shift;

	$self->tick();
}

;# Refresh the time.
sub refresh
{
	debug "args: @_\n";
	my $self = shift;

	# don't do anything unless these are set up.....
	return unless defined($self->cget('-update'));
	return unless defined($self->cget('-format'));

	debug "$self: update is '", $self->cget('-update'), "'\n";
	debug "$self: format is '", $self->cget('-format'), "'\n";

	# Update the date/time string....

	# get the localtime details.
	my @localtime = localtime(time + $self->cget('-advance'));

	# Note: some POSIX::strftime translate %f to a single f.
	# So have to deal with this first. In particular, ActivePerl.

	# deal with %f.....
	my $str	= $self->cget('-format');
	$str	=~ s/%f/&th($localtime[3])/eg;

	debug "$self: format is now '$str'\n";

	# finally pass it through strftime.
	$self->{datetime} = POSIX::strftime($str, @localtime);
	#
	# Apply any optional action to the string.
	my $act = $self->cget('-action');
	if (defined($act))
	{
		debug "$self: format before action is '$str'\n";
		debug "$self: action is '$act'\n";

		eval "\$self->{datetime} =~ $act";
	}

	@localtime;
}

;# Calculate the number of seconds before we need to update.
;# Usage: $nap = $C->until(@localtime);
sub until
{
	debug "args: @_\n";

	my $self	= shift;
	my @localtime	= @_;

	my $update	= $self->cget('-update');

	$update = 'a' if (!defined($update) || $update eq '');

	# return the update if its just a number.
	return $update unless ($update =~ /\D/);

	if ($update =~ /^a/i)
	{
		# guess the update.....
		my $fmt	= $self->cget('-format');

		if    ($fmt =~ /%[cST]/)	{ $update = 's';}
		elsif ($fmt =~ /%M/ )		{ $update = 'm';}
		elsif ($fmt =~ /%H/ )		{ $update = 'h';}
		elsif ($fmt =~ /%P/i )		{ $update = 'p';}
		else				{ $update = 'd';}
	}

	if ($update =~ /^s/i)
	{
		# sync every second.
		$update = 1;
	}
	elsif ($update =~ /^m/i)
	{
		# sync on the minute.
		$update = 60 - $localtime[0];
	}
	elsif ($update =~ /^h/i)
	{
		# sync on the hour.
		$update = 3600 - $localtime[0] - 60*$localtime[1];
	}
	elsif ($update =~ /^p/i)
	{
		# sync at midday and midnight.
		$update = 12*3600 - $localtime[0] -
			60*$localtime[1] - 3600*($localtime[2]%12);
	}
	elsif ($update =~ /^d/i)
	{
		# sync at midnight.
		$update = 24*3600 - $localtime[0] - 60*$localtime[1] - 3600*$localtime[2];
	}
	else
	{
		#carp __PACKAGE__ . ": unknown value '$update' for update (resetting to 1 sec).\n";

		$update = 1;
	}

	debug "required nap is $update seconds.\n";

	$update;
}

;# Tick every so often and update the label.
;# $self->tick().
sub tick
{
	debug "args: @_\n";
	my $self = shift;

	# don't do anything unless these are set up.....
	return unless defined($self->{'-update'});
	return unless defined($self->{'-format'});

	# update the date/time string....
	my @localtime = $self->refresh();

	# If update is a letter then sync on a minute, hour or day.
	my $update = $self->until(@localtime);

	debug "update is in $update seconds.\n";

	return undef unless ($update > 0 );
	
	# If there is an ontick function, do it.
	&{$self->cget('-ontick')}($self) if (defined($self->cget('-ontick')));

	# cancel any previous ticking.
	if (exists($self->{after}))
	{
		debug "cancelling after '$self->{after}'\n";

		# works but produces an odd error.
		$self->{base}->afterCancel($self->{after});

		# work around
		$self->{base}->Tk::after('cancel' => $self->{after});

		delete($self->{after});
	}

	# don't forget to tick again....
	$self->{after} = $self->{base}->after($update*1000, [ 'tick', $self]);

	debug "after ref '", ref($self->{after}), "'\n";
	debug "$self: updating in $update seconds ($self->{after}).\n";

	$self->{after};
}

;# return the correct ending for first (1st), etc..
;# This is hardwired and needs to be modified
;# for each language.
sub th
{
	debug "args @_\n";

	my $e = shift;

	# eg. first == 1st....
	my $f = "th";
	if    ($e =~ /11$/)	{ $f = "th"; }
	elsif ($e =~ /12$/)	{ $f = "th"; }
	elsif ($e =~ /13$/)	{ $f = "th"; }
	elsif ($e =~ /1$/)	{ $f = "st"; }
	elsif ($e =~ /2$/)	{ $f = "nd"; }
	elsif ($e =~ /3$/)	{ $f = "rd"; }

	$f;
}

;# Casecade all the missing functions to the base.
sub AUTOLOAD
{
	debug "args: @_\n";
	debug "\$AUTOLOAD=$AUTOLOAD\n";

	my $self = shift || '';
	croak "$AUTOLOAD: '$self' is not an object!\n" unless ref($self);

	# What are we trying to do?
	my $what = $AUTOLOAD;
	$what =~ s/.*:://;

	# Cascade this to the base widget.
	eval "\$self->{base}->$what(\@_)";
}

;# Demonstration application.
sub StrfClock
{
	debug __PACKAGE__ . " version $VERSION\n";

	# do some remedial argument parsing.
	if (@_ && ($_[0] eq '-d'))
	{
		shift(@_);

		# set up debugging...
		eval '	sub debug {
				my ($package, $file, $line,
					$subroutine, $hasargs, $wantargs) = caller(1);
				$line = (caller(0))[2];
	
				print STDERR "$file:$line $subroutine: ", @_;
	
			};
		';
	}

	# Test script
	use Tk;
	#use Tk::StrfClock;

	my $top=MainWindow->new();
	$top->title(__PACKAGE__ . " version $VERSION");

	# Default arguments.
	my @formats = (
		'%c',
		'%I:%M%p, %A, %e%f %B %Y.',
		'%I:%M%p, %A, %B %e, %Y.',
		'%Y %B %e %T',
		'%Y %B %e %H:%M',
		'%Y %B %e %H%p',
		'%Y %B %e %T',
		'%A %p',
		'%H:%M',
		'%T',
	);

	my @args = ();
	for (@_)
	{
		push (@args, ($_ eq 'test' ) ? @formats : $_);
	}

	########################################
	# Label
	if (0)
	{
		my $bframe = $top->Frame(
		)->pack(
			-expand	=> 1,
			-fill	=> 'y',
			-side	=> 'top',
			-anchor	=> 'nw',
		);

		my $cframe = $top->Frame(
			#-relief	=> 'sunken',
			#-border	=> 1,
			-background	=> 'white',
		)->pack(
			-expand	=> 1,
			-fill	=> 'both',
			-side	=> 'top',
			-anchor	=> 'nw',
		);
	
		# primary Tk::StrfClock widget.
		my $dt = $cframe->StrfClock(
			-foreground	=> 'blue',
			-background	=> 'white',
			-ontick		=> sub { print $_[0]->{datetime}, "\n"; },
		)->pack(
			-anchor	=> 'w',
			-expand	=> 1,
			-fill	=> 'y',
		);

		# take the first argument if its there.
		$dt->configure( -format	=> shift(@args),) if (@args);

		###############################################
		# the File menu button....
		my $file = $bframe->Menubutton(
			-text		=> 'File',
			-tearoff	=> 0,
			-border		=> 0,
			-borderwidth	=> 0,
		)->pack(
			-side		=> 'left'
		);
		$file->configure(
			-activebackground	=> $file->cget('-background'),
		);


		# exit.
		#$file->separator();
		$file->command(
			"-label"	=> 'Hide Buttons',
			"-command"	=> sub { $bframe->packForget(); },
		);
		$file->command(
			"-label"	=> 'Exit',
			"-command"	=> sub { exit; },
		);
		###############################################

		# the File menu button....
		my $Format = $bframe->Menubutton(
			-text		=> 'Format',
			-tearoff	=> 0,
			-border		=> 0,
			-borderwidth	=> 0,
		)->pack(
			-side	=> 'left',
		);
		$Format->configure(
			-activebackground	=> $Format->cget('-background'),
		);

		for my $format (@formats)
		{
			$Format->command(
				"-label"	=> $format,
				"-command"	=> [ sub { $_[0]->configure(-format => $_[1]); }, $dt, $format ],
			);
		}


		###############################################
		# The Tk::StrfClock widgets.
		my $upd = '';
		my $adv = 0;
		local ($_);
		for (@args)
		{
			if (/%/)
			{
				$cframe->StrfClock(
					-format	=> $_,
					-update	=> $upd,
					-advance=> $adv,
				)->pack(
					-anchor	=> 'w',
					-expand	=> 1,
					-fill	=> 'y',
				);
			}
			elsif (/^[\+\-]\d+$/)	{ $adv = $_; }
			else 			{ $upd = $_; }
		}
	}

	###################################################
	# Menubutton
	#if (0)
	{
		# primary StrfClock widget.
		my $dt = $top->StrfClock(
			-foreground	=> 'blue',
			-background	=> 'white',
			-activeforeground => 'red',
			#-ontick		=> sub { print $_[0]->{datetime}, "\n"; },
			-type		=> 'Menubutton',
			-action		=> 's/AM/am/',

			# Menubutton
			-tearoff	=> 0,
			-border		=> 0,
			-borderwidth	=> 0,
		)->pack(
			-anchor	=> 'w',
			-expand	=> 1,
			-fill	=> 'y',
		);

		# take the first argument if its there.
		$dt->configure( -format	=> shift(@args),) if (@args);

		###############################################

		# the menu items.
		$dt->title('Formats');
		for my $format (@formats)
		{
			$dt->command(
				"-label"	=> $format,
				"-command"	=> [ sub { $_[0]->configure(-format => $_[1]); }, $dt, $format ],
			);
		}

		$dt->separator();
		$dt->command(
				"-label"	=> 'tick print on',
				"-command"	=> [ sub { 
			(shift)->configure(-ontick=> sub { print $_[0]->{datetime}, "\n"; });
				}, $dt ],
		);
		$dt->command(
				"-label"	=> 'tick print off',
				"-command"	=> [ sub { 
			(shift)->configure(-ontick=>undef);
				}, $dt ],
		);
		$dt->command(
				"-label"	=> 'Exit',
				"-command"	=> [ sub { exit; } ],
		);
	}
	
	###################################################
	# Optionmenu
	if (0)
	{
		# primary StrfClock widget.
		my $dt = $top->StrfClock(
			-foreground	=> 'green',
			-background	=> 'white',
			-activeforeground => 'red',
			-ontick		=> sub { print $_[0]->{datetime}, "\n"; },
			-type		=> 'Optionmenu',

			# base widget
			-border		=> 0,
			-borderwidth	=> 0,
		)->pack(
			-anchor	=> 'w',
			-expand	=> 1,
			-fill	=> 'y',
		);

		# take the first argument if its there.
		$dt->configure( -format	=> shift(@args),) if (@args);

		###############################################

		# the menu items.
		$dt->title('Formats');
		for my $format (@formats)
		{
			$dt->command(
				"-label"	=> $format,
				"-command"	=> [ sub { $_[0]->configure(-format => $_[1]); }, $dt, $format ],
			);
		}

		$dt->separator();
		$dt->command(
				"-label"	=> 'Exit',
				"-command"	=> [ sub { exit; } ],
		);
	}
	
	###################################################
	# Button
	if (0)
	{
		# primary StrfClock widget.
		my $dt = $top->StrfClock(
			-type		=> 'Button',
			-format		=> '%c',
			-ontick		=> sub { print "Button: ", $_[0]->{datetime}, "\n"; },

			# Button
			-foreground	=> 'blue',
			-background	=> 'white',
			-border		=> 0,
			-borderwidth	=> 0,
			-command	=> [ sub { print "Button\n"; } ],
		)->pack(
			-anchor	=> 'w',
			-expand	=> 1,
			-fill	=> 'y',
		);

	}

	MainLoop();

	# Only gets here if the window is killed.
	exit;
}

;# If we are running this file then run the main function....
&StrfClock(@ARGV) if ($0 eq __FILE__);

1;

__END__

=head1 NAME

Tk::StrfClock - a X/TK digital clock widget based on strftime.

=head1 SYNOPSIS

  use Tk::StrfClock;

  $top->StrfClock(
	-type	=> [Label|Button|Menubutton|Optionmenu],
  	-format	=> <strftime format string>,
	-update => [<seconds>|s|m|h|d],
	-advance => [<seconds>],
	-action	=> <pattern matching action>,
	-ontick	=> <function>,
  );

=head1 DESCRIPTION 

Tk::StrfClock is a string clock widget based on one of
a Tk::Label, a Tk::Button, a Tk::Menubutton or a Tk::Optionmenu
(chosen at creation time). The current date and time (in some chosen
configuration) is displayed as the text in the base widget.

=head1 OPTIONS

All the base widget options are available.

=head2 -type => [Label|Button|Menubutton|Optionmenu],

Set the base widget type at creation time. This cannot be
configured thereafter.  The default is Tk::Label.

=head2 -format => <strftime format string>

Sets the required date/time format using POSIX strftime format.
The default is C<%c>.

=head2 -update => <seconds>|s|m|h|d|a

Sets how often the clock is updated.  If set to the characters
s, m, h, d or a then the clock is updated exactly on the second,
minute, hour, day or is automatically guessed.

The default is C<a>.

=head2 -advance => <seconds>

Sets the clock fast or slow this many seconds. 
The default is C<0>.

=head2 -action => <pattern matching action>

Sets a pattern matching action to be applied to the date string
before it is displayed. The default is to do nothing.

=head2 -ontick => <function>

Set a function to be run every tick of the clock. The default is
none.

=head1 MINIMAL EXAMPLE

  use Tk;
  use Tk::StrfClock;

  my $top=MainWindow->new();
  $top->StrfClock()->pack();
  MainLoop();

=head1 TESTING

Run the module itself to start a test program.
To increase the size of the fond add something like

=over 3

 *StrfClock*font: -*-fixed-medium-r-normal--20-*-*-*-*-*-*-*

=back

to your .Xdefaults file.

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

