package Tk::HexEntry;

use Tk ();
use Tk::Frame;
use Tk::Derived;
use strict;

use vars qw(@ISA $VERSION);
@ISA = qw(Tk::Derived Tk::Frame);
$VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);

Construct Tk::Widget 'HexEntry';

{ my $foo = $Tk::FireButton::INCBITMAP;
     $foo = $Tk::FireButton::DECBITMAP; # peacify -w
}

sub Populate {
    my($f,$args) = @_;

    require Tk::FireButton;
    require Tk::HexEntryPlain;

    my $orient = delete $args->{-orient} || "vertical";

    my $readonly = delete $args->{-readonly};

    my $e = $f->Component( $f->HexEntryPlainWidget => 'entry',
        -borderwidth        => 0,
        -highlightthickness => 0,
    );
    if ($readonly) {
	$e->bindtags([]);
    }

    my $binc = $f->Component( $f->IncFireButtonWidget() => 'inc',
	-command	    => sub { $e->incdec($e->cget(-increment)) },
	-takefocus	    => 0,
	-highlightthickness => 0,
	-anchor             => 'center',
    );
    $binc->configure(-bitmap => ($orient =~ /^vert/
				 ? $binc->INCBITMAP
				 : $binc->HORIZINCBITMAP
				)
		    );

    my $bdec = $f->Component( $f->DecFireButtonWidget() => 'dec',
	-command	    => sub { $e->incdec(- $e->cget(-increment)) },
	-takefocus	    => 0,
	-highlightthickness => 0,
	-anchor             => 'center',
    );
    $bdec->configure(-bitmap => ($orient =~ /^vert/
				 ? $bdec->DECBITMAP
				 : $bdec->HORIZDECBITMAP
				)
		    );

    $f->gridColumnconfigure(0, -weight => 1);
    $f->gridColumnconfigure(1, -weight => 0);

    $f->gridRowconfigure(0, -weight => 1);
    $f->gridRowconfigure(1, -weight => 1);

    if ($orient eq 'vertical') {
	$binc->grid(-row => 0, -column => 1, -sticky => 'news');
	$bdec->grid(-row => 1, -column => 1, -sticky => 'news');
    } else {
	$binc->grid(-row => 0, -column => 2, -sticky => 'news');
	$bdec->grid(-row => 0, -column => 1, -sticky => 'news');
    }

    $e->grid(-row => 0, -column => 0, -rowspan => 2, -sticky => 'news');

    $f->ConfigSpecs(
	-borderwidth => ['SELF'     => "borderWidth", "BorderWidth", 2	     ],
	-relief      => ['SELF'     => "relief",      "Relief",	    "sunken"  ],
	-background  => ['CHILDREN' => "background",  "Background", Tk::NORMAL_BG ],
	-foreground  => ['CHILDREN' => "background",  "Background", Tk::BLACK ],
	-buttons     => ['METHOD'   => undef,	    undef,	   1	     ],
	-state       => ['CHILDREN' => "state", 	    "State", 	   "normal"  ],
	-repeatdelay => [[$binc,$bdec]
				  => "repeatDelay", "RepeatDelay", 300	     ],
	-repeatinterval
		     => [[$binc,$bdec]
				  => "repeatInterval",
						    "RepeatInterval",
								   100	     ],
	-highlightthickness
                     => [SELF     => "highlightThickness",
						    "HighlightThickness",
								   2	     ],
	DEFAULT      => [$e],
    );

    $f->Delegates(DEFAULT => $e);

    $f;
}

sub HexEntryPlainWidget { "HexEntryPlain"         }
sub FireButtonWidget    { "FireButton"            }
sub IncFireButtonWidget { shift->FireButtonWidget }
sub DecFireButtonWidget { shift->FireButtonWidget }

sub buttons {
    my $f = shift;
    my $var = \$f->{Configure}{'-buttons'};
    my $old = $$var;

    if(@_) {
	my $val = shift;
	$$var = $val ? 1 : 0;
	my $e = $f->Subwidget('entry');
	my %info = $e->gridInfo; $info{'-sticky'} = 'news';
	delete $info{' -sticky'};
	$e->grid(%info, -columnspan => $val ? 1 : 2);
	$e->raise;
    }

    $old;
}

1;

__END__

=head1 NAME

Tk::HexEntry - A hexadecimal Entry widget with inc. & dec. Buttons

=head1 SYNOPSIS

S<    >B<use Tk::HexEntry;>

S<    >I<$parent>-E<gt>B<HexEntry>(?I<-option>=E<gt>I<value>, ...?);

=head1 ATTENTION 

This is only a changed copy from Tk::NumEntry and Tk::NumEntryPlain 
write from Graham Barr <F<gbarr@pobox.com>>. Thanks for this great Module!

=head1 DESCRIPTION

B<Tk::HexEntry> defines a widget for entering hexadecimal numbers. The widget
also contains buttons for increment and decrement.

B<Tk::HexEntry> supports all the options and methods that the plain 
HexEntry widget provides (see L<Tk::HexEntryPlain>), plus the
following options

=head1 STANDARD OPTIONS

Besides the standard options of the L<Entry|Tk::Entry> widget
HexEntry supports:

B<-orient> B<-repeatdelay> B<-repeatinterval>

The B<-orient> option specifies the packing order of the increment and
decrement buttons. This option can only be set at creation time.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:             B<buttons>

=item Class:            B<Buttons>

=item Switch:           B<-buttons>

=item Fallback:		B<1>

Boolean that defines if the inc and dec buttons are visible.


=item Switch:           B<-readonly>

=item Fallback:		B<0>

If B<-readonly> is set to a true value, then the value can only be
changed by pressing the increment/decrement buttons. This option can
only be set at creation time.

=back

=head1 WIDGET METHODS

Subclasses of HexEntry may override the following methods to use
different widgets for the composition of the HexEntry. These are:
HexEntryPlainWidget, FireButtonWidget, IncFireButtonWidget and
DecFireButtonWidget. FireButtonWidget is used if IncFireButtonWidget
or DecFireButtonWidget are not defined.

=head1 AUTHOR

Graham Barr <F<gbarr@pobox.com>>

Current maintainer is Slaven Rezic <F<slaven.rezic@berlin.de>>.

=head1 ACKNOWLEDGEMENTS

I would to thank  Achim Bohnet <F<ach@mpe.mpg.de>>
for all the feedback and testing. And for the splitting of the original
Tk::NumEntry into Tk::FireButton, Tk::NumEntryPlain and Tk::NumEntry

=head1 COPYRIGHT

Copyright (c) 1997-1998 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Except the typo's, they blong to Achim :-)

Rewrite to hexadecimal Values:
B<Tk::HexEntry>'s author is Frank Herrmann E<lt>xpix@xpix.deE<gt>

=cut
