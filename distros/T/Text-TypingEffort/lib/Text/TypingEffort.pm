package Text::TypingEffort;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    effort
    layout
    register_layout
);
our $VERSION = '0.25';

our %basis;   # stores the basis for our calculations
our %layouts; # stores the keyboard layouts

=head1 NAME

Text::TypingEffort - Calculate the effort required to type a given text

=head1 SYNOPSIS

  use Text::TypingEffort qw/effort/;
  
  my $effort = effort("The quick brown fox jumps over the lazy dog");

C<$effort> will be a hashref something like this

  $effort = {
      characters => 43,     # the number of characters in the text
      presses    => 44,     # key presses need to type the text
      distance   => 950,    # millimeters the fingers moved while typing
      energy     => 2.2..., # the energy (Joules) used while typing
  };

=head1 DESCRIPTION

Text::TypingEffort is used to calculate how much physical effort was
required to type a given text.  Several metrics of effort are used.
These metrics are described in detail in the L</METRICS> section.

This module is useful for determining which keyboard layout is
more efficient, for making API/language design decisions, or to show your
boss how hard you're working.

=head2 Function Quick Reference

The following quick reference provides brief information about the 
arguments that the functions can take.  More detailed information is
given below.

 # effort() with a single argument
 my $effort = effort(
 
    $text | \$text                        # the text to analyze
 );
 
 # effort() with named arguments
 my $effort = effort(
 
    text     => $text | \$text,           # the text to analyze
    file     => $filename | $filehandle,  # analyze a file
    layout   => 'qwerty'                  # keyboard layout
              | 'dvorak'
              | 'aset',
              | 'xpert',
              | 'colemak',
    unknowns => 0 | 1,                    # tally unknown chars?
    initial  => \%metrics,                # set initial values
    caps     => 0 | 2 | 3 | ...           # Caps Lock technique
 );
 
 # layout()
 my $l = layout;                          # get QWERTY layout
 my $l = layout($layout_name);            # get named layout
 
 # register_layout()
 register_layout($name, \@layout);        # register custom layout

=head1 FUNCTIONS

=head2 effort [$TEXT | \$TEXT]

The argument should be a scalar or a reference to a scalar which contains
the text to be analyzed.  If no parameter is provided, C<$_> is used
as the value of C<$TEXT>.  Leading whitespace on each line of C<$TEXT>
is ignored since a decent text editor handles that for the typist.
Only characters found on a standard US-104 keyboard are tallied in
the metrics.  That means that accented characters, unicode, etc. are
not included.  If a character is unrecognized, it may be counted under
the 'unknowns' metric (see that documentation).

=head2 effort %ARGUMENTS

effort() may also be called with a list of named arguments.  This allows
more flexibility in how the metrics are calculated.  Below is a list of
acceptable arguments.  In summary, calling effort like this

 effort($text);

is identical to explicitly specifying all the defaults like this

 effort(
    text     => $text,
    layout   => 'qwerty',
    unknowns => 0,
    initial  => {},
    caps     => 4,
 );


=head3 text

Specifies the text to be analyzed.  The value should be either a scalar or
a reference to a scalar which contains the text.  If neither this argument
nor B<file> is specified, C<$_> is used as the text to analyze.

=head3 file

Specifies a file which contains the text to be analyzed.  If the value
is a filehandle which is open for reading, the text will be read from that
file handle.  The filehandle will remain open after C<effort> is finished 
with it.

If the value is a filename, the file will be opened and the text for analysis
read from the file.  If neither this argument nor B<text> is specified,
C<$_> is used as the text to analyze.

=head3 layout

Default: qwerty

Specifies the keyboard layout to use when calculating metrics.  Acceptable,
case-insensitive values for B<layout> are: qwerty, dvorak, aset, xpert,
colemak.  If some other value is provided, the default value of 'qwerty' is
used.

=head3 unknowns

Default: 0

Should a histogram of unrecognized characters be returned with the other
metrics?  A true value indicates yes and a false value no. Tallying this
histogram takes a little bit more work in the inner loop and therefore
makes processing ever so slightly slower.  It can be useful for seeing
how much of the text was not counted in the other metrics.

See B<unknowns> in the L</METRICS> section for information on how this option
affects C<effort>'s return value.

=head3 initial

Default: {}

Sets the initial values for each of the metrics.  This option is the way to
have C<effort> accumulate the results of multiple calls.  By doing something
like

 $effort = effort($text_1);
 $effort = effort(text=>$text_2, initial=>$effort);

you get the same results as if you had done

 $effort = effort($text_1 . $text_2);

except the former scales more gracefully.  The value of B<initial> should
be a hashref with keys and values similar to the result of a previous
call to C<effort>.  If the hashref does not contain a key-value pair
for a given metric, the initial value of that metric will be its normal
default value (generally 0).

If the value of B<initial> is not a hashref, C<effort> proceeds as if
the B<initial> argument were not present at all.  This behavior may
change in the future, so don't rely upon it.

=head3 caps

Default: 4

Determines how strings of consecutive capital letters should be handled.
The default value of 4 means that four or more capital letters in a
row should be treated as though the user pressed "Caps Lock" at the
beginning, then typed the characters and then pressed "Caps Lock" again.
This behavior more accurately models what typical users do when typing
strings of capital letters.  You may change the number of capital letters
that must be in a row in order to trigger this behavior by specifying
an integer greater than 1 as the value of the B<caps> argument.  If you
specify, the value 1, the value 2 will be used instead.

If the value of B<caps> is 0, capital letters are treated as though the
user pressed Shift for each one.  If C<undef> is given, the default
value of B<caps> is used.

When caps handling is enabled, "capital letter" means any character that
can be typed without the Shift key when Caps Lock is on.  That includes
characters such as '.' and '/' and '-' etc.  However, the string of
consecutive caps must start and end with a real capital letter.  That way,
a string such as '-----T-----' won't be calculated using Caps Lock.

=cut

sub effort {
    # establish the default options
    my %DEFAULTS = (
        layout   => 'qwerty',
        unknowns => 0,
        initial  => {},
        caps     => 4,
    );

    # establish our current options
    my %opts;
    if( @_ == 1 ) {
        %opts = ( %DEFAULTS, text=>$_[0] );
    } else {
        %opts = ( %DEFAULTS, @_ );
    }
    
    $opts{text} = $_ unless defined $opts{file} or defined $opts{text};

    # repair the caps argument
    $opts{caps} = $DEFAULTS{caps} unless defined $opts{caps};
    $opts{caps} = 2               if     $opts{caps} == 1;

    # fill in the preliminary data structures as needed
    $opts{layout} = lc($opts{layout});
    %basis = &_basis( $opts{layout} )
        unless $basis{LAYOUT} and $basis{LAYOUT} eq $opts{layout};

    my $fh;   # the filehandle for reading the text
    my $text; # or a reference to the text itself
    my $close_fh = 0;
    if( defined $opts{file} ) {
        if( ref $opts{file} ) {
            $fh = $opts{file};
        } else {
            open($fh, "<$opts{file}")
                or croak "Couldn't open file $opts{file}";
            $close_fh = 1;
        }
    } elsif( ref $opts{text} ) {
        $text = $opts{text};
    } else {
        $text = \$opts{text};  # make $text a reference
    }

    # get the first line of text
    my $line;
    my $line_rx = ".*(?:\n|\r|\r\n)?";  # match a line
    if( $fh ) {
        $line = <$fh>;
    } else {
        $$text =~ /^/g; # reset the regex in case we're given same arg twice
        $$text =~ /($line_rx)/g;
        $line = $1; # the pattern always matches (I think)
    }

    # set the default initial values for the metrics
    my %sum;
    @sum{qw(characters presses distance)} = (0) x 3;
    $sum{unknowns} = {} if $opts{unknowns};

    # munge the initial values based on the 'initial' option
    if( ref($opts{initial}) eq 'HASH' and keys %{$opts{initial}} ) {
        for (qw/characters presses distance/) {
            $sum{$_} = $opts{initial}{$_} if defined $opts{initial}{$_};
        }
        for (qw/presses distance/) {
            $sum{unknowns}{$_} = { %{ $opts{initial}{unknowns}{$_} } }
                if defined $opts{initial}{unknowns}{$_};
        }
    }

    while( defined $line ) {
        if( chomp $line ) {
            # the newline counts as a character, a keypress and an ENTER
            $sum{characters}++;
            $sum{presses}++;
            $sum{distance} += $basis{distance}{ENTER};
        }
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;

        # handle consecutive chunks typed with Caps Lock on
        if( $opts{caps} ) {
            my $c = $opts{caps}-2;
            my $p = q{[A-Z]};  # pure caps
            my $d = q{[[:space:]A-Z0-9,./;'\[\]\\=`-]}; # defiled caps
            if( my $caps = $line =~ s#($p $d {$c,} $p)#\L$1#gx ) {
                # turn caps on and off for each chunk
                $sum{presses} += 2*$caps;
                $sum{distance} += 2*$caps*$basis{distance}{CAPS};
            }
        }

        foreach(split //, $line) {
            # only count the character if we recognize it
            $sum{characters}++ if exists $basis{presses}{$_};

            foreach my $metric (qw/presses distance/) {
                if( defined $basis{$metric}{$_} ) {
                    $sum{$metric} += $basis{$metric}{$_};
                } elsif( $opts{unknowns} ) {
                    $sum{unknowns}{$metric}{$_}++;
                }
            }
        }

        # get the next line
        if( $fh ) {
            $line = <$fh>;
        } else {
            if( $$text =~ /($line_rx)/gc ) {
                $line = $1;
            } else {
                undef $line;
            }
        }
    }

    close $fh if $close_fh;

    $sum{energy} = (&J_per_mm*$sum{distance}) + (&J_per_click*$sum{presses});

    return \%sum;
}

=head2 layout [$NAME]

Returns an arrayref representing the requested layout or C<undef> if
the given name is unknown.  If no layout name is provided, the QWERTY
layout is returned.

See C<register_layout> below or the Text::TypingEffort source code for
examples of the contents of the arrayref.

=cut

sub layout {
    my $name = lc(shift) || 'qwerty';
    return $layouts{$name} if exists $layouts{$name};
    return undef;
}

=head2 register_layout $NAME, \@LAYOUT

Register a new layout, using the given name.  The name is stored
without regard to case, so 'NAME' and 'name' are considered the same.
The layout itself should be an arrayref containing each key's character
and its shifted version.  Running the code below displays a pseudo-code
snippet showing how the QWERTY keyboard layout is defined.  Start in
the upper-left corner of a QWERTY keyboard and follow along through
the pseudo-code.  You should get the idea.  You can also find documented
examples in the source code.

 use Text::TypingEffort qw/layout/;
 $l = layout;
 print "register_layout('qwerty', [qw{\n";
 while( ($lower, $upper) = splice(@$l, 0, 2) ) {
        print "\t$lower $upper\n";
 }
 print "}]);\n";

Typically, C<register_layout> is called just prior to C<effort>.  For
example:

 my @layout = qw{
    ...
 };
 register_layout('my custom layout', \@layout);
 my $e = effort(
    text   => $text,
    layout => 'my custom layout',
 );

=cut

sub register_layout {
    my $name = lc shift;
    $layouts{$name} = shift;
}

=head1 METRICS

=head2 characters

The number of recognized characters in the text.  This is similar in
spirit to the Unix command C<wc -c>.  Only those characters which are encoded
in the internal keyboard layout will be counted.  That excludes accented
characters, Unicode characters and control characters but includes newlines.

=head2 presses

The number of keys pressed when typing the text.  The value of this metric is
the value of the B<characters> metric plus the number of times the Shift key
was pressed.

=head2 distance

The distance, in millimeters, that the fingers travelled while typing
the text.  This distance includes movement required for the Shift and
Enter keys, but does not include the vertical movement the finger makes
as the key descends during a press.  Perhaps a better name for this
metric would be horizontal_distance, but that's too long ;-)

The model for determining this metric is very simplistic.  It assumes
that a finger moves from its home position to the destination key and
then returns to the home position before moving on to the next key.
Of course, this is not how people actually type, but the model should
result in an upper-bound for the amount of finger movement.

=head2 energy

The number of Joules of energy required to type the text.  This metric is
the most inclusive in that it tries to accomodate the values of both the
B<presses> and the B<distance> metrics into a single metric.  However,
this metric is also the least accurate at modeling the real world.
The calculations are roughly based upon the I<The Compendium of Physical
Activities> (or rather hearsay about it's contents since I don't have
a copy).

The physical charactersistics of the keyboard are assumed to be roughly in
line with ISO 9241-4:1998, which specifies standards for such things.

=head2 unknowns

This metric is only included in the output if the B<unknowns> argument
to C<effort> was true.

The value is a histogram of the unrecognized characters encountered during
processing.  This includes any control characters, accented characters or
unicode characters.  Generally, anything other than the letters, numbers
and punctuation found on a standard U.S. keyboard will be counted here.

If all characters were recognized, the value will be an empty hashref.
If any characters were unknown, the value will be a hashref something
like this:

 unknowns => {
    presses => {
        'Å' => 2,
        'Ö' => 3,
    },
    distance => {
        'Å' => 2,
        'Ö' => 3,
    },
 }

The key indicates the metric for which information was missing.  The value
is a hash indicating the character and the number of times that character
occurred.  There will be no entries in the hash for the B<characters>
or B<energy> metrics as these are incidental to the other two.

This metric is only added to the result if the B<unknowns> option was
specified and true.

=head1 SEE ALSO

Tactus Keyboard article on the mechanics and standards of
keyboard design - L<http://www.tactuskeyboard.com/keymech.htm>

=head1 CONTRIBUTING

The source for Text::TypingEffort is maintained in a Git repository
located at L<git://git.ndrix.com/Text-TypingEffort>.  To submit patches,
you can do something like this:

 $ git clone git://git.ndrix.com/Text-TypingEffort
 $ cd Text-TypingEffort
 # hack, commit, hack, commit
 $ git format-patch -s origin
 $ git send-email --to michael@ndrix.org *.patch

See http://www.kernel.org/pub/software/scm/git/docs/everyday.html

=head1 AUTHOR

Michael Hendricks <michael@ndrix.org>

Thanks to Ricardo Signes for a patch for the C<layout> and
C<register_layout> subroutines.

=head1 BUGS/TODO

Please submit suggestions and report bugs to the CPAN Bug Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TypingEffort>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Michael Hendricks

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject
to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


=cut



############### subroutines to help with the calculations ################

sub _basis {
    my ($desired) = @_;

    my %basis;
    $basis{LAYOUT} = $desired;

    # get the keyboard characteristics
    my @keyboard = &us_104;

    # get the layout
    my @layout = @{ layout($desired) || layout };

    # get some keyboard characteristics
    my($lshift,$rshift) = splice(@keyboard, 0, 2);

    # the space character is somewhat exceptional
    $basis{distance}{' '} = 2*shift(@keyboard);
    $basis{presses}{' '} = 1;

    $basis{distance}{ENTER} = 2*shift(@keyboard);
    $basis{distance}{CAPS}  = 2*shift(@keyboard);

    # populate $basis{presses} and $basis{distance}
    while( my($shift, $d) = splice(@keyboard, 0, 2) ) {
        my($lc, $uc) = splice(@layout, 0, 2);

        $basis{presses}{$lc} = 1;
        $basis{presses}{$uc} = 2;

        # the *2 is because distances are initially one-way
        $basis{distance}{$lc} = 2*$d;
        $basis{distance}{$uc} = 2*($d + ($shift eq 'l' ? $lshift : $rshift));
    }

    return %basis;
}

# Calculate the number of Joules of energy needed to move the
# finger 1 millimeter as it reaches for a keyboard key.
#
# English and QWERTY are used in the values below because the caloric
# studies were done with a standard QWERTY keyboard and typing English text
sub J_per_mm {
    return
            502      # Joules/ hour (energy for 150lb man typing for 1 hour)
          * (1/60)   # hours / min
          * (1/40)   # min   / word (typing speed)
          * (1/4.3)  # words / char (average English word length)
          * (1/21.2);# chars / mm   (average distance when typing QWERTY)
}

# Calculate the number of Joules of energy needed to depress a single
# key on the keyboard.
#
# The energy required is the area of a triangle with sides equal
# to the key displacement in meters (.003) and the force required to
# depress the key in Newtons (.6)  These values are taken from
# ISO 9241-4:1998(E)  (indirectly since the actual source was a quote at
# http://www.tactuskeyboard.com/keymech.htm
sub J_per_click {
    return (1/2)*(.003)*(.6);
}


################ subroutines for keyboard specifications #################
sub us_104 {
    return (
        # distances the finger must move to reach the left Shift,
        # right Shift, Space, Enter and Caps Lock, respectively
        # (in millimeters)
        qw{
            15 30 0 35 15
        },

        # define the `12345 row
        # the first value is the shift key one must press when trying to
        # "capitalize" the given key.  Valid options are 'r' (right shift)
        # and 'l' (left shift).
        # the second value is the distance the finger must move from its
        # home position to reach the given key.  The distance is in millimeters.
        qw{
            r 45
            r 35
            r 35
            r 35
            r 35
            r 30
            r 40
            l 35
            l 35
            l 35
            l 30
            l 30
            l 35
            l 45
        },

        # define the QWERTY row
        qw/
            r 15
            r 15
            r 15
            r 15
            r 15
            l 25
            l 15
            l 15
            l 15
            l 15
            l 15
            l 30
        /,

        # define the home row
        qw{
            r  0
            r  0
            r  0
            r  0
            r 15
            l 15
            l  0
            l  0
            l  0
            l  0
            l 15
        },

        # define the ZXCVB row
        qw{
            r 15
            r 15
            r 15
            r 15
            r 30
            l 15
            l 15
            l 15
            l 15
            l 15
        },
    );

}

################### subroutines for keyboard layouts ####################
{ no warnings qw(qw);  # stop warnings about the '#' and ',' characters

    # the first value is the character generated by pressing the key
    # without any modifier.  The second value is the character generated
    # when pressing the key along with the SHIFT key.

    register_layout('qwerty', [
        # define the 12345 row
        qw{
            ` ~
            1 !
            2 @
            3 #
            4 $
            5 %
            6 ^
            7 &
            8 *
            9 (
            0 )
            - _
            = +
            \ |
        },

        # define the QWERTY row
        qw/
            q  Q
            w  W
            e  E
            r  R
            t  T
            y  Y
            u  U
            i  I
            o  O
            p  P
            [  {
            ]  }
        /,

        # define the home row
        qw{
            a A
            s S
            d D
            f F
            g G
            h H
            j J
            k K
            l L
            ; :
            ' "
        },

        # define the ZXCVB row
        qw{
            z Z
            x X
            c C
            v V
            b B
            n N
            m M
            , <
            . >
            / ?
        }
    ]);

    register_layout('dvorak', [
        # define the 12345 row
        qw/
            `  ~
            1  !
            2  @
            3  #
            4  $
            5  %
            6  ^
            7  &
            8  *
            9  (
            0  )
            [  {
            ]  }
            \\ |
        /,
        # define the ',.pYF row
        qw{
            ' "
            , <
            . >
            p P
            y Y
            f F
            g G
            c C
            r R
            l L
            / ?
            = +
        },
        # define the home row
        qw{
            a A
            o O
            e E
            u U
            i I
            d D
            h H
            t T
            n N
            s S
            - _
        },
        # define the ;QJKX row
        qw{
            ; :
            q Q
            j J
            k K
            x X
            b B
            m M
            w W
            v V
            z Z
        },
    ]);

    register_layout('aset', [
        # define the 12345 row
        qw{
            ` ~
            1 !
            2 @
            3 #
            4 $
            5 %
            6 ^
            7 &
            8 *
            9 (
            0 )
            - _
            = +
            \ |
        },

        # define the QWERTY row
        qw/
            q  Q
            w  W
            d  D
            r  R
            f  F
            y  Y
            u  U
            k  K
            o  O
            p  P
            [  {
            ]  }
        /,

        # define the home row
        qw{
            a A
            s S
            e E
            t T
            g G
            h H
            n N
            i I
            l L
            ; :
            ' "
        },

        # define the ZXCVB row
        qw{
            z Z
            x X
            c C
            v V
            b B
            j J
            m M
            , <
            . >
            / ?
        }
    ]);

    register_layout('xpert', [
        # define the 12345 row
        qw{
            ` ~
            1 !
            2 @
            3 #
            4 $
            5 %
            6 ^
            7 &
            8 *
            9 (
            0 )
            - _
            = +
            \ |
        },

        # define the XPERT row
        # the actual XPERT keyboard has a second 'e' key
        # where I put the ';' but since it eliminates the
        # semicolon, it has to go somewhere
        qw/
            x  X
            p  P
            ;  :
            r  R
            t  T
            y  Y
            u  U
            i  I
            o  O
            j  J
            [  {
            ]  }
        /,

        # define the home row
        qw{
            q Q
            s S
            d D
            f F
            n N
            h H
            a A
            e E
            l L
            k K
            ' "
        },

        # define the ZXCVB row
        qw{
            z Z
            w W
            c C
            v V
            b B
            g G
            m M
            , <
            . >
            ? /
        }
    ]);

    register_layout('colemak', [
        # define the 12345 row
        qw{
            ` ~
            1 !
            2 @
            3 #
            4 $
            5 %
            6 ^
            7 &
            8 *
            9 (
            0 )
            - _
            = +
            \ |
        },

        # define the QWFPG row
        qw/
            q  Q
            w  W
            f  F
            p  P
            g  G
            j  J
            l  L
            u  U
            y  Y
            ;  :
            [  {
            ]  }
        /,

        # define the home row
        qw{
            a A
            r R
            s S
            t T
            d D
            h H
            n N
            e E
            i I
            o O
            ' "
        },

        # define the ZXCVB row
        qw{
            z Z
            x X
            c C
            v V
            b B
            k K
            m M
            , <
            . >
            / ?
        }
    ]);
}

1;
__END__
