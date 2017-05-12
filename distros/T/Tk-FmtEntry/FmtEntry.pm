#=============================================================================
#
# Formatted Entry widget
#
#-----------------------------------------------------------------------------

package Tk::FmtEntry;
use vars qw/$VERSION/;
$VERSION = '0.1';

use Tk::widgets qw/Entry/;
use base qw/Tk::Derived Tk::Entry/;
use strict;
use warnings;
use Carp;

Construct Tk::Widget 'FmtEntry';

sub ClassInit {
    my ($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my ($w, $args) = @_;
    $w->SUPER::Populate($args);
    $w->{_fe_suppress} = 0;
    $w->{_fe_usrvcmd} = undef;
    $w->{_fe_usrvali} = 'none';
    $w->{_fe_fixuptimer} = undef;
    $w->SUPER::configure(
        -validate => 'key',
        -vcmd     => sub {$w->_fe_validate}
    );
    $w->ConfigSpecs(
        -delay           => [qw/PASSIVE delay Delay 0/],
        -formatcommand   => ['PASSIVE'],
        -fcmd            => '-formatcommand',
        -validate        => ['METHOD'],
        -validatecommand => ['METHOD'],
        'DEFAULT'        => ['SELF']
    );
    return $w;
}

sub validate {
    my $w = shift;
    return $w->{_fe_usrvali} if !@_;
    return if $w->{_fe_suppress};
    my $value = shift;
    croak "Tk::FmtEntry supports only 'none' or 'key' for -validate"
        if ($value ne 'none') && ($value ne 'key');
    $w->{_fe_usrvali} = $value;
}

sub validatecommand {
    my $w = shift;
    return $w->{_fe_usrvcmd} if !@_;
    return if $w->{_fe_suppress};
    my $value = shift;
    $w->{_fe_usrvcmd} = $value;
}

sub _fe_fixup {
    my $w   = shift;
    my $old = $w->get;
    my $i   = $w->index('insert');
    my $fcmd = $w->cget('-formatcommand');
    $w->{_fe_fixuptimer} = undef;

    # Call the formatter, if defined
    my $new = $old;
    my $j   = $i;
    if ($fcmd) {
        ($new, $j) = &$fcmd($old, $i, $w);
        $j = _fe_mapins($old, $i, $new) if !defined $j;    # guess new cursor
    }

    # Update the field
    if ($old ne $new) {
        # Hmmm... I dunno why $w->SUPER::configure still calls *us* instead
        #  of the parent's (Tk::Entry) configure.  So, to prevent spinning
        #  we'll use a suppress method.
        $w->{_fe_suppress} = 1;
        $w->configure(-validate => 'none');
        $w->delete(0, 'end');
        $w->insert(0, $new);
        $w->configure(-validate => 'key');
        $w->{_fe_suppress} = 0;
    }
    $w->SUPER::icursor($j);
}

sub _fe_validate {
    my $w = shift;
    return 1 if $w->{_fe_suppress};

    # Invoke user-supplied vcmd, if any
    my $ok = 1;
    $ok = &$w->{_fe_usrvcmd}(@_)
        if $w->{_fe_usrvali} eq 'key' && $w->{_fe_usrvcmd};

    # Queue the fixup
    my $delay = $w->cget('-delay');
    if ($delay && $ok) {
        $w->afterCancel($w->{_fe_fixuptimer}) if $w->{_fe_fixuptimer};
        $w->{_fe_fixuptimer} = $w->after($delay, sub {$w->_fe_fixup});
    }
    elsif ($ok) {
        $w->afterIdle(sub {$w->_fe_fixup});
    }
    return $ok;
}

# Map old insertion point to the new - a guess, anyway - not perfect.
# This is called if the format function doesn't return a revised position.
sub _fe_mapins {
    my ($old, $i, $new) = @_;

    # Map the old to new, char by char
    my $m   = 0;
    my @map = ();
    for my $o (0 .. length($old) - 1) {
        $map[$o] = undef;
        for my $n ($m .. length($new) - 1) {
            if (substr($old, $o, 1) eq substr($new, $n, 1)) {
                $map[$o] = $n;
                $m = $n + 1;
                last;
            }
        }
    }

    # Find new insertion point
    my $k = $i;
    my $j;
    while (($k <= $#map) && !defined($j = $map[$k++])) { }
    $j = 0            if @map == 0;
    $j = length($new) if !defined $j;

###print "_fe_mapins: '$old'\t$i\t'$new'\t$j\n";
    return $j;
}

__END__

=head1 NAME

Tk::FmtEntry - A Formatted Entry widget

=head1 SYNOPSIS

    my $fe = $mw->FmtEntry(-fcmd => sub {...})->pack;   # The widget

=head1 DESCRIPTION

A normal Entry widget, but it may enforce some format upon the entered value.  
For example, telephone number, credit-card, or currency (money) formats.  
The programmer must supply the formatting function.
See below for examples.

Otherwise, this acts a like a normal Entry widget, except for some restrictions
on the use of -validate.

The following additional options/value pairs are supported:

=over 4

=item B<-delay>

Normally, the formatting function is called as soon as possible after any edit
to the contents of the FmtEntry field.  However, you may want to delay the
formatting a bit, so multiple edits to the field can be "batched" and handled
at once.  This may also be useful when swipe-card reads are to be extracted
from a field that's also a user-entry (type-in) field.

Use the -delay option to specify the number of milliseconds to wait
before the formatting fuction is invoked.   Edits to the field must be idle
for this amount of time before the format function is called: if you set an 
80ms delay, for example, and the edits come in with 65ms, 79ms, 55ms, then 81ms
pauses, the call will occur after the last pause (not after each).

Note that users typically percieve delays of more than 80ms.

=item B<-formatcommand>

Alias: -fcmd

The formatting function.  This function is called to cleanup,
correct, and/or [re]format the value contained in the entry.
It is called with three arguments: the (possibly) unformatted string
in the entry field, and the current insertion cursor index, and a reference
to the FmtEntry widget.

B<The function should return two values:> the cleaned-up string,
and the revised insertion cursor point.  If the revised insertion point is
not returned (undef), then a simplistic correlation algorithm will
be used to B<guess> the new insertion cursor point.  It's not a very
good guess, so the cursor may not be where you expect it.  Thus, your
formatting function should calculate and return the revised position.

An example may help.  Suppose we want to enforce all entries to be
lowercase.  In this simple example, the insertion curor point does not change,
so we just return it un-altered, along with the lower-cased string:

    my $fe = $mw->FmtEntry(-fcmd => \&fmt_lc)->pack;
      .
      .
      .
    sub fmt_lc {
        my ($old, $i) = @_;
        return (lc $old, $i);
    }

=back

=head2 Interaction with -validate and -validatecommand

The only -validate options supported are 'none' and 'key'.
Attempting to set any other -validate option will cause this widget
to carp an error.

The -validatecommand (-vcmd) you specify is called out of Tk::FmtEntry's
internal validator function, but it works just like it was called 
from Tk::Entry.

=head2 Insertion Cursor Positioning

The hardest thing about using this widget is that your custom formatting
function needs to return a revised insert cursor position, in addition to the
[re]formatted string.  The 'insert cursor position' is where new characters
are added when you type.  If you don't correctly determine and return 
the revised position, things will go all screwy when the user types; their
characters may get scrambled.

For example, the user wants to type 57 into a field that
you're formatting as currency (money).
The user first types "5", which leaves the cursor at position i=1 (just
after the "5" character).
Your formatting function changes this string to "$5.00".
Because of the dollar sign prefix, the insertion cursor needs to change 
from position i=1 to position i=2.
If this was not done, the cursor would remain at i=1 and typing another digit,
say "7", would result in "$75.00" instead of the desired "$57.00".


=head2 How It Works

If the normal Entry widget allowed correction of the value during
a -validatecommand callback, then this derived widget wouldn't be necessary.
However, doing so can cause strange interactions with the -textvariable,
especially if the -textvariable is changed outside the callback function.
Hence, we have this FmtEntry widget.

This widget avoids the pitfalls of changing the Entry's value by deferring
the change to some time after the Entry finishes its processing.
It does this by using the -validatecommand callback on 'key' events,
to set an afterIdle() "fixup" callback.  This fixup callback is called moments
after (unless -delay is used), and the formatting/correction/whatever is done
there.  If your Tk application is very busy, you may notice a delay
before the (re)formatting occurs.  I'm not thrilled with this approach,
but it works pretty well.

=head1 METHODS

None.

=head1 ADVERTISED SUBWIDGETS

None.

=head1 EXAMPLES


=head2 Force Entry to be Uppercase

All letters typed in the FmtEntry field are uppercased.

  use Tk;
  use Tk::FmtEntry; 
  my $mw = new MainWindow;
  $mw->FmtEntry(-fcmd => \&fmt_uc)->pack;
  MainLoop;

  sub fmt_uc {
    my ($old, $i) = @_;
    return (uc $old, $i);
  }

In this example, the entry is simply uppercased via the formatting function
fmt_uc().  The cursor index $i does not change position, so it's just returned
as-is.

=head2 Credit Card Format

This example formats the entry as a 16-digit credit card number,
like XXXX-XXXX-XXXX-XXXX .  Only digits are accepted.

    !/usr/bin/perl -w
    use strict;
    use Tk;
    use Tk::FmtEntry;

    my $mw = new MainWindow;
    $mw->Label(-text => 'Enter a Credit Card number')->pack;
    $mw->FmtEntry(-fcmd => \&fmt_cc)->pack;
    MainLoop;

    sub fmt_cc {
        my ($old, $i) = @_;

        # To figure the new insert cursor position, 
        #  format just the left half and see where it lands.
        my $lf = substr($old, 0, $i);
        $lf =~ s/[^\d]//g;    			# remove all but digits
        $lf = substr($lf, 0, 16);                  # max 16 digits
        while ($lf =~ s/(\d{4})(\d)/$1-$2/) { };   # group to fours
        my $j = length($lf);                       # get new position

        # Now format again the whole thing
        my $new = $old;
        $new =~ s/[^\d]//g;                        # nuke all but digits
        $new = substr($new, 0, 16);                # max 16 digits
        while ($new =~ s/(\d{4})(\d)/$1-$2/) { };  # group to fours
        return ($new, $j);
    }

Note how the revised insert cursor position is determined.  Although there's
likely more efficient methods, a simple approach is to split the old string
at the old cursor postion (call this the 'left' part), then format this left
part and see how big it is.  The length is the new cursor position.
Then repeat, formatting the whole old string and return this as the new.

=head2 Money Format

Example formatting function for currency.  This formatter uses the trick of
placing a marker character (an asterix) into a second "marked" string, 
then after formatting it correlates the marked string to the new string, 
to determine the cursor position.  It's not perfect but it works reasonably
well (it has a problem with leading zeros - see if you can fix it!)

    #!/usr/bin/perl -w
    # Example Tk::FmtEntry with cash (money) style formatting
    use strict;
    use Tk;
    use Tk::FmtEntry;

    my $mw = new MainWindow;
    $mw->Label(-text => 'Enter Money Amount')->pack;
    $mw->FmtEntry(-fcmd => \&fmt_cash)->pack;
    MainLoop;

    sub fmt_cash {
        my ($old, $i) = @_;

        # Make the new string
        my $new = $old;
        $new =~ s/[^\d\.]//g;             # remove all but digits and decimal
        if ($new eq q{.}) {$old = $new = "0."; ++$i;}   # special for dp-only
        $new =~ s/(\.\d{0,2}).*$/$1/;                   # max two past dp
        $new = sprintf '$%4.2f', $new if $new ne q{};   # if blank, leave blank

        # Add commas
        $new = reverse $new;
        $new =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
        $new = reverse $new;

        # Make a marked string
        my $mrk
            = substr($old, 0, $i) . q{*} . substr($old, $i, length($old) - $i);
        $mrk =~ s/[^\d\.\*]//g;    # remove all but digits, decimal, and marker

        # Find new insert point
        my $j = 0;
        my $k = 0;
        foreach my $c (split //, $new) {
            if ($c eq q{$} || $c eq q{,}) {
                $j++;
                next;
            }
            last if substr($mrk, $k++, 1) eq q{*};    # found the marker
            $j++;
        }
        return ($new, $j);
    }

=head1 AUTHOR

Steve Roscio  C<< <roscio@cpan.org> >>

Copyright (c) 2010, Steve Roscio C<< <roscio@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law.  Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose.  The
entire risk as to the quality and performance of the software is with
you.  Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=head1 KEYWORDS

FmtEntry

=cut
