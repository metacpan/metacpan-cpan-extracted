#! /usr/bin/env perl

;#                                                               
;# COPYRIGHT
;# Copyright (c) 1998-2007 Anthony R Fletcher.  All rights reserved.  This
;# module is free software; you can redistribute it and/or modify it
;# under the same terms as Perl itself.
;#
;# Please retain my name on any bits taken from this code.
;# This code is supplied as-is - use at your own risk.
;#                                                               
;#			AR Fletcher.

;# This is a Tk month browser.
;# Place into Tk/Year.pm somewhere in your perl-lib path.

use 5;
use warnings;
use strict;

package Tk::Year;

our $VERSION = '1.1';

use Carp;
use POSIX;
use Time::Local;
use Text::Abbrev;
use Tk;
use Tk::Widget;
use Tk::Month;

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'Year';

sub debug {};
#sub debug { print STDERR @_; };

;# ---------------------------------------------------------------------

;## Constructor.  Uses new inherited from base class
sub Populate
{
	debug "args: @_\n";

	my $self = shift;
	my $args = shift;

	# Create all the widgets, but don't pack them.
	$self->SUPER::Populate($args);
	
	# Construct the subwidgets.
	$self->{frame} = $self->make();

	# Set up extra configuration
	$self->ConfigSpecs(
		'-cols'		=> ['METHOD',undef,undef, 3],
		'-year'		=> ['METHOD',undef,undef, (localtime())[5]+1900],

		'-press'	=> ['METHOD',undef,undef, undef],
		'-command'	=> '-press',

		# configurable from Xdefaults file.
		'-font'		=> ['CHILDREN','font','Font', undef],
		'-first'	=> ['METHOD','first','First', 0],
		'-sep'		=> ['METHOD','sep','Sep', 3],
		'-buttonhighlightcolor'	=> ['METHOD','buttonhighlightcolor','ButtonHighlightColor', ''],
		'-buttonhighlightbackground'	=> ['METHOD','buttonhighlightbackground','ButtonHighlightBackground', ''],
		'-buttonfg'	=> ['METHOD','buttonfg','ButtonFg', ''],
		'-buttonbg'	=> ['METHOD','buttonbg','ButtonBg', ''],
		'-buttonbd'	=> ['METHOD','buttonbd','ButtonBd', ''],
		'-buttonrelief'	=> ['METHOD','buttonrelief','ButtonRelief', ''],
	);

	# Any further contracts happen to the title widget.
	$self->Delegates(
		Construct => $self->{title},
		DEFAULT => $self->{title},
	);

	# return widget.
	$self;
}

;# Create all the subwidgets needed
sub make
{
	debug "args: @_\n";

	my $self	= shift;

	my $width = 2;

	# First create all the buttons in a grid.

	# navigation row.
	$self->{title} = $self->Menubutton(
		-width	=> 15,
		-text	=> 'Tk::Year',
	);
	
	# Create the month widgets
	for my $month (@Tk::Month::year)
	{
		my $m = $self->Month(
				-title	=> '%B',
				-month	=> $month,
				-navigation	=> 0,
				-side		=> 0,
			);

		push (@{$self->{'months'}}, $m);
	}

	$self;
}

# (Re-)Pack the months in to the correct number of columns.
sub cols
{
	my $self = shift;
	
	# requesting the value.
	return $self->{Configure}->{-cols} unless @_;

	# setting the value.
	my $cols = shift;
	$self->{Configure}->{-cols} = $cols;

	# Pack the title.
	$self->{title}->grid(
		-row		=> 0,
		-column		=> int(($cols-1)/2),
		-columnspan	=> 2 - $cols %2 ,
		-sticky		=> 'nsew',
	);

	# Positions (0,0), (0,1), (0,6), (0,7) are the
	# navigation buttons.

	my $n = 0;
	for my $month (@{$self->{'months'}})
	{
		# decide the row and column.
		my $c = $n % $cols ;
		my $r = int($n / $cols) +1;
		$n ++;
		
		$month ->grid(
				'-row'		=> $r + 1,
				'-column'	=> $c,
				'-sticky'	=> 'nsew',
				'-padx'		=> 5,
			);
	}
}

# Set the inter-month spacing.
sub sep
{
	my $self = shift;
	
	# requesting the value.
	return $self->{Configure}->{-sep} unless @_;

	# setting the value.
	my $sep = shift;
	$self->{Configure}->{-sep} = $sep;

	for my $month (@{$self->{'months'}})
	{
		$month ->grid('-padx' => $sep);
	}
}

;# configure or return various properties.
sub conf
{
	my $self = shift;

	# Decide what called us and hence which flag to set.
	my $var = (caller(1))[3];
	$var =~ s/^.*:/-/;

	debug "var = $var\n";

	return $self->{Configure}->{$var} unless @_;

	my $val = shift;
	debug "val = $val\n";
	
	# remember....
	$self->{Configure}->{$var} = $val;

	$self->confMonths($var => $val);

	debug "done\n";
}

;# configure all the months at once.
sub confMonths
{
	my $self = shift;
	my $var = shift;
	my $val = shift;
	
	# set the months
	for my $m (@{$self->{'months'}})
	{
		$m->configure( $var => $val, );
	}
}

;# return or set the year.
sub year
{
	my $self = shift;

	# requesting the year.
	return $self->{Configure}->{-year} unless @_;

	my $year = shift;

	# deal with aliases.
	if ($year eq '' || $year eq 'now')
	{
		# current year.
		$year = (localtime())[5] + 1900 ;
	}

	# sanity?
	unless ($year =~ /^\d+$/)
	{
		warn "Cannot set year to '$year'!\n";
		return;
	}

	if ($year > 2038)
	{
		warn "Tk::Year: Cannot deal with years beyound 2038\n";
		return;
	}

	# remember....
	$self->{Configure}->{-year} = $year;

	# set the title.
	$self->{title}->configure('-text' => $year, );

	# set the months
	$self->confMonths('-year' => $year);
}

;# set the characters of the months.
sub first { &conf; }
sub press { &conf; }
sub buttonfg { &conf; }
sub buttonbg { &conf; }
sub buttonbd { &conf; }
sub buttonrelief { &conf; }
sub buttonhighlightcolor { &conf; }
sub buttonhighlightbackground { &conf; }

;# increment and decrement the displayed year.
sub advance
{
	debug "args: @_\n";

	my ($self, $inc)	= @_;

	# sanitise the increment.
	$inc += 0;
	return if ($inc == 0);

	my $year = $self->cget('-year') + $inc;

	$self->configure(-year => $year);
}

;#################################################################
;# A default startup routine.
sub test
{
	# only use this when testing.
	eval 'use Getopt::Long;';
	Getopt::Long::Configure("pass_through");
	GetOptions(
		'd'	=> sub { 
			eval '	sub debug {
				my ($package, $filename, $line,
					$subroutine, $hasargs, $wantargs) = caller(1);
				$line = (caller(0))[2];
		
				print STDERR "$subroutine: ";
		
				if (@_) {print STDERR @_; }
				else    {print "Debug $filename line $line.\n";}
			};
			';
		},
	);

	# Test script for the Tk Tk::Month widget.
	use Tk;
	use Tk::Optionmenu;
	#use Tk::Month;

	my $top=MainWindow->new();
	my $n = $top->Frame(
	)->pack();

	#########################################################
	# can set the week days here but not recommended.
	# Tk::Month::setWeek( qw(Su M Tu W Th F Sa) );

	my $a = $top->Year(
		-command	=> sub { print "hello @_\n"; },
	)->pack();

	$a->configure(@ARGV) if (@ARGV);

	$a->command(
		-label	=> 'forward',
		-command	=> [ sub { $_[0]->advance($_[1]);}, $a, 1],
	);
	$a->command(
		-label	=> 'back',
		-command	=> [ sub { $_[0]->advance($_[1]);}, $a, -1],
	);

	#########################################################

	$a->separator();

	for my $i ( qw(raised flat sunken) )
	{
		$a->command(
			-label		=> ucfirst($i),
			-command	=> sub { $a->configure(-buttonrelief => $i); },
		);
	}

	$a->separator();
	for my $i ( qw(2 3 4) )
	{
		$a->command(
			-label		=> "Columns $i",
			-command	=> [ sub { $_[0]->configure('-cols' => $_[1]);}, $a, $i],
		);
	}

	$a->separator();
	for my $i ( qw(0 1 2 3 4 5) )
	{
		$a->command(
			-label		=> "Separation $i",
			-command	=> [ sub { $_[0]->configure('-sep' => $_[1]);}, $a, $i],
		);
	}

	$a->separator();
	$a->command(
		-label		=> 'Exit',
		-command	=> sub { exit; },
	);

	# Navigation buttons.
	$n->Button(
		-text	=> '<<',
		-command	=> [ sub { $_[0]->advance($_[1]);}, $a, -10],
	)->pack(
		-side	=> 'left',
		);
	$n->Button(
		-text	=> '<',
		-command	=> [ sub { $_[0]->advance($_[1]);}, $a, -1],
	)->pack(
		-side	=> 'left',
		);
	$n->Button(
		-text	=> '=',
		-command	=> [ sub { $_[0]->configure(-year => ''); }, $a ],
	)->pack(
		-side	=> 'left',
		);
	$n->Button(
		-text	=> '>',
		-command	=> [ sub { $_[0]->advance($_[1]);}, $a, 1],
	)->pack(
		-side	=> 'left',
		);
	$n->Button(
		-text	=> '>>',
		-command	=> [ sub { $_[0]->advance($_[1]);}, $a, 10],
	)->pack(
		-side	=> 'left',
		);

	MainLoop();

	1;
}

# If we are running this file then run the test function....
&test if ($0 eq __FILE__);

1;

__END__

=head1 NAME

Tk::Year - Calendar widget which shows one year at a time.

=head1 SYNOPSIS

  use Tk;
  use Tk::Year;

  $m = $parent->Year(
		-year		=> '1997',
		-cols		=> 3,
		-sep		=> 5,
		-first		=> [0|1|2|3|4|5|6],
		-command	=> \&press,
	)->pack();

  $m->configure(
		-year		=> '1997',
		-first		=> [0|1|2|3|4|5|6],
  );

  $m->advance(<number-of-years>);

  $m->separator();
  $m->command(
		-label		=> 'Label',
		-command	=> \&callback,
  );

=head1 DESCRIPTION 

Tk::Year is a general purpose calendar widget
which shows one year at a time and allowes
user defined button actions.

=head1 METHODS

=head2 $m->advance(<number-of-years>);

This advances the year shown by the specified number of years;
negative numbers go backwards.

=over 3

The title (shouwing the current year) is a Tk::Menubutton and all the Tk::Menubutton 
actions can be applied to Tk::Year.

=back 

=head1 OPTIONS

=head2 -year => 'year'

Sets the required year. The default is the current year.

=head2 -cols => 'columns'

Sets the number of columns used to display the year. The default is 3.

=head2 -sep => 'sep'

Sets the separation between the columns of months. The default is 5 pixels.

=head2 -command => \&press

Set the command to execute when a button is pressed.
This function must accept a string
(the title of the Month widget)
and an array of arrays of dates.
Each date is of the format specified by the -printformat option.
The default is to print out the list on standard output.

=head2 -first

=head2 -buttonhighlightcolor

=head2 -buttonhighlightbackground

=head2 -buttonfg

=head2 -buttonbg

=head2 -buttonbd

=head2 -buttonrelief

These options apply to each of the L<Tk::Month> widgets.
See L<Tk::Month> for details.

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

