package X::Osd;

use strict;
use warnings;
use Carp;

use Exporter;
use DynaLoader;
use AutoLoader;

use vars
  qw(@ISA $VERSION $CVS_VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use X::Osd ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = (
    'all' => [
        qw(
          string
          slider
          percentage
          printf
          get_colour
          hide
          set_bar_length
          set_colour
          set_font
          set_horizontal_offset
          set_vertical_offset
          set_pos
          set_align
          set_shadow_offset
          set_timeout
          show
          is_onscreen
          wait_until_no_display
          scroll
          get_number_lines
          )
    ]
    );

@EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

@EXPORT = qw(
  XOSD_top
  XOSD_bottom
  XOSD_middle
  XOSD_left
  XOSD_center
  XOSD_right
  );

$VERSION     = '0.7';
$CVS_VERSION = sprintf '%s', q$Revision: 1.17 $ =~ /: ([0-9.]*)/;

sub AUTOLOAD
{

    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0)
    {

        if ($! =~ /Invalid/ || $!{EINVAL})
        {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else
        {
            croak "Your vendor has not defined X::Osd macro $constname";
        }
    }
    {
        no strict 'refs';

        # Fixed between 5.005_53 and 5.005_61
        if ($] >= 5.00561)
        {    #?? this broken on 5.6.0

            #*$AUTOLOAD = sub () { $val };
            *$AUTOLOAD = sub { $val };
        }
        else
        {
            *$AUTOLOAD = sub { $val };
        }
    }
    goto &$AUTOLOAD;
}

sub new
{
    my $class = shift;
    return create(@_);
}

#Backwards compatibility
sub set_offset
{
    my ($self, $offset) = @_;
    my $success;
    $self->set_horizontal_offset($offset);
    $self->set_horizontal_offset($offset);
    return $offset;
}

bootstrap X::Osd $VERSION;

42;

__END__

=head1 NAME

X::Osd - Perl extension to the X On Screen Display library (xosd)

=head1 SYNOPSIS

  use X::Osd;
  my $osd = X::Osd->new(NULL, 2);
  $osd->set_font("-*-lucidatypewriter-medium-r-normal-*-*-25-*-*-*-*-*-*");
  $osd->set_colour("Green");
  $osd->set_timeout(3);
  $osd->set_pos(XOSD_top);
  $osd->set_align(XOSD_right);
  $osd->set_horizontal_offset(0);
  $osd->set_vertical_offset(10);
  $osd->set_shadow_offset(2);

  $osd->string(0,'Hello World!');
  $osd->percentage(0,56);
  $osd->slider(0,34);

=head1 DESCRIPTION

XOSD displays text on your screen, sounds simple right? The difference is it is unmanaged and shaped,
so it appears transparent. This gives the effect of an On Screen Display, like your TV/VCR etc..

It currently supports 3 type of writes, string for simple text, printf formatted text, slider and percentage display.

You need to have libxosd installed.  You can get it from http://www.ignavus.net/software.html

=head2 EXPORT

None by default.

=head2 Exported constants

  XOSD_top
  XOSD_middle
  XOSD_bottom
  XOSD_left
  XOSD_center
  XOSD_right

=head2 Exportable functions

=over 4

=item * create(disp, number_lines);

=item * string(line,string)

=item * printf(line, string)

=item *	percentage(line,percentage)

	where percentage is between 0 and 100

=item * slider(line,percentage)

	where percentage is between 0 and 100

=item * get_colour(red,green,blue)

=item * get_shadow_colour(red,green,blue)

=item * get_outline_colour(red,green,blue)

=item * hide()

=item * show()

=item * set_bar_length(osd, lenght)

=item * set_colour(color)

=item * set_shadow_colour(shadow_colour)

=item * set_outline_colour(outline_colour)

=item * set_font(font)

=item * set_vertical_offset(offset)

=item * set_horizontal_offset(offset)

=item * set_pos(pos)

where pos is one of (XOSD_top, XOSD_middle, XOSD_bottom)

=item * set_align(align)

where align is one of (XOSD_left, XOSD_center, XOSD_right)

=item * set_shadow_offset(shadow_offset)

=item * set_outline_offset(outline_offset)

=item * set_timeout(timeout)

=item * is_onscreen()

=item * wait_until_no_display()

=item * scroll(lines)

=item * get_number_lines()

=back

=head1 AUTHOR

Philippe M. Chiasson E<lt>gozer@cpan.orgE<gt>

=head1 CREDITS

 Bjorn Bringert E<lt>bjorn@bringert.netE<gt> xosd-1.0.x fixes
 Etan Reisner E<lt>deryni@eden.rutgers.eduE<gt> provided a patch for new xosd faatures

=head1 VERSION

This is revision $Id: Osd.pm,v 1.17 2003/07/01 12:52:19 gozer Exp $

=head1 CVS
The CVS repository of X::Osd is avaliabe thru anoncvs at:

 $> cvs -d :pserver:anoncvs@cvs.ectoplasm.org:/home/anoncvs login
 password: anoncvs
 $> cvs -d :pserver:anoncvs@cvs.ectoplasm.org:/home/anoncvs co X-Osd

=head1 COPYRIGHT

Copyright (c) 2002-2003 Philippe M. Chiasson. All rights reserved. This program is free software,
you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

I<perl>

Home & Author of XOSD
http://www.ignavus.net/software.html E<lt>spoonboy@ignavus.netE<gt>

=cut
