#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# The infrastructure to feed the tests in a controllable manner, simulating
# the stdin and stdout.

use strict;

package Triceps::X::TestFeed;

sub CLONE_SKIP { 1; }

our $VERSION = 'v2.0.1';

use Carp;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	makePrintLabel setInputLines getResultLines readLine send sendf readLineX sendX
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#########################
# helper functions to support either user i/o or i/o from vars

# vars to serve as input and output sources
my @input;
my $result;

# Set the input and reset the result.
sub setInputLines # (@lines)
{
	@input = @_;
	$result = undef;
}

# Get back the result
sub getResultLines # ()
{
	return $result;
}

# simulates user input: returns the next line or undef
sub readLine # ()
{
	$_ = shift @input;
	$result .= "> $_" if defined $_; # have the inputs overlap in result, as on screen
	return $_;
}

# write a message to user
sub send # (@message)
{
	$result .= join('', @_);
}

# write a message to user, like printf
sub sendf # ($msg, $vars...)
{
	my $fmt = shift;
	$result .= sprintf($fmt, @_);
}

# versions for the real user interaction
sub readLineX # ()
{
	$_ = <STDIN>;
	return $_;
}

sub sendX # (@message)
{
	print @_;
}

# a template to make a label that prints the data passing through another label
sub makePrintLabel($$) # ($print_label_name, $parent_label)
{
	my $name = shift;
	my $lbParent = shift;
	my $lb = $lbParent->getUnit()->makeLabel($lbParent->getType(), $name,
		undef, sub { # (label, rowop)
			&send($_[1]->printP(), "\n");
		});
	$lbParent->chain($lb);
	return $lb;
}

1;
