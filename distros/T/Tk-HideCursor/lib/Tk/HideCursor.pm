package Tk::HideCursor;

our $VERSION = 0.02;

#==============================================================================#

=head1 NAME

Tk::HideCursor - Hide the cursor when it passes over your widget

=head1 SYNOPSIS

	use Tk::HideCursor;
	$widget->hideCursor;
	$widget->showCursor;

=head1 DESCRIPTION

Adds methods to the Tk::Wm base class so that any widget may hide the cursor

=head2 METHODS

=over 4

=cut

#==============================================================================#

package Tk::Wm;

require 5.6.0;

use strict;
use warnings;
use Carp;

#==============================================================================#

my ($win32_curse, $orig_curse);

if ($^O =~ /Win32/) {
	eval "use Win32::API"; croak $@ if $@;
	$win32_curse = Win32::API->new('user32', 'ShowCursor', ['N'], 'N');
}

#==============================================================================#

=item $widget->hideCursor();

Hide the mouse cursor when it's over $widget.

=cut

sub hideCursor {
	my ($obj) = @_;

	if ($^O =~ /Win32/) {

		# Hide the cursor
		$win32_curse->Call(0);
		
	} else {
		#This should work to avoid embedding file but doesnt.
		#my $bits = pack("b8"x5,
		#	"........",
		#	"...0....",
		#	"...0....",
		#	"...0....",
		#	"........",
		#);
		#$obj->DefineBitmap("test",8,5,$bits);
		#$obj->configure(-cursor => "test");

		
		my $file = 'foo';
		open(my $fh ,"> $file") || die $!;
		print $fh 
			"#define t_cur_width 1\n".
			"#define t_cur_height 1\n".
			"#define t_cur_x_hot 0\n".
			"#define t_cur_y_hot 0\n".
			"static unsigned char t_cur_bits[] = {  0x00};\n";
		close $fh;
		$orig_curse = ($obj->configure(
			-cursor => ['@'.$file,$file,qw/cyan cyan/]
		))[3];
		unlink $file;
	}

	return 1;
}

#==============================================================================#

=item $widget->showCursor();

Show the cursor again (should return to the previous specified cursor - if
any)

=cut

sub showCursor {
	my ($obj) = @_;

	if ($^O =~ /Win32/) {
		$win32_curse->Call(1);
	} else {
		$obj->configure(-cursor => $orig_curse);
	}
}

#==============================================================================#

=back

=head1 BUGS

Under Win32, Tk cursor handling is (currently) very basic. Hiding is 
achieved using the Win32::API. This has the limitation that the cursor 
is hidden for all widgets, not just the specified one.

=head1 AUTHOR

This module is Copyright (c) 2002 Gavin Brock gbrock@cpan.org. All rights 
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Tk>

L<Win32::API> 

=cut

# That's all folks..
#==============================================================================#
1;
