##==============================================================================
## Tk::autobind - automatically bind a widget to an ALT-key
##==============================================================================
## Copyright 2001-2003 Kevin Michael Vail.  All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##==============================================================================
## $Id: autobind.pm,v 1.2 2003/06/17 01:23:39 kevin Exp $
##==============================================================================
require 5.005;

package Tk::autobind;
use Tk;
use strict;
use vars qw($VERSION);
($VERSION) = q$Revision: 1.2 $ =~ /^Revision:\s+(\S+)/ or $VERSION = "0.0";

=head1 NAME

Tk::autobind - automatically bind a widget to an ALT-key

=head1 SYNOPSIS

C<< use Tk::autobind; >>

C<< I<$widget>->autobind(I<callback>); >>

=head1 DESCRIPTION

C<Tk::autobind> offers a convenient way to set up a form and have ALT-key
bindings for the widgets on that form.  All you have to do is call C<autobind>
after you create a widget.  If the widget has an C<-underline> configuration
option set to a value greater than or equal to 0, its ALT-key binding is the
key at that location in the widget's C<-text> configuration option.

For example, if you have a Checkbutton with the following C<-text>:

    Automatically fix

and its C<-underline> value is set to 0, then if the user presses ALT-A while
the focus is in the widget's main window, the checkbutton widget will be
invoked.

The binding that is generated is essentially

C<< $widget->toplevel->bind('<Alt-Key-I<x>>', $callback); >>

=head1 METHODS

=over 4

=item I<$widget>->autobind(I<callback>);

Adds the binding given above.  If I<callback> is specified, it must be one of
the forms of a valid Tk callback (see L<Tk::callbacks>).  If it is omitted, a
closure is generated and used:

    sub { $widget->Invoke }

If I<callback> is explicitly set to an empty string, the binding is removed.

This method always returns I<$widget> to allow method chaining.  For example,
you can stick B<autobind> before the call to B<pack>:

    my $checkbutton = $mw->Checkbutton(Name => 'cb1')->autobind->pack;

=cut

##==============================================================================
## autobind
##==============================================================================
sub Tk::Widget::autobind {
    my ($widget, $callback) = @_;
    my $underline;
    $underline = eval { $widget->cget('-underline') };
    if (!$@ && defined $underline && $underline >= 0) {
    	my $key;
    	$key = eval { substr($widget->cget('-text'), $underline, 1) };
        if (!$@ && defined $key) {
            $callback = sub { $widget->Invoke; } unless defined $callback;
            $widget->toplevel->bind("<Alt-Key-\L$key>", $callback);
        }
    }
    return $widget;
}

=pod

=back

=head1 SEE ALSO

L<Tk::bind>

=head1 AUTHOR

Kevin Michael Vail F<< <kevin@vaildc.net> >>

=cut

1;

##==============================================================================
## $Log: autobind.pm,v $
## Revision 1.2  2003/06/17 01:23:39  kevin
## Gracefully handle things when applied to a widget that doesn't
## _have_ an -underline or a -text config option.
##
## Revision 1.1  2001/09/01 02:36:35  kevin
## Allow this to work for dialogs, too.
##
## Revision 1.0  2001-08-24 11:22:14-04  kevin
## Initial revision
##==============================================================================
