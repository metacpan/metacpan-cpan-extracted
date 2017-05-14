package Tk::CornerBox;

use Tk::Canvas;
use Tk::Frame;
use Tk;

use vars qw ($VERSION $TRIMCOUNT);
use base qw (Tk::Frame);
use strict;

$VERSION = '0.02';

$TRIMCOUNT = 3;

Tk::Widget->Construct ('CornerBox');

sub Populate
   {
    my $this = shift;

    $this->SUPER::Populate (@_);

    my $l_Canvas = $this->Component
       (
        'Canvas' => 'Canvas',
        '-width' => 20,
        '-height' => 20,
        '-borderwidth' => 0,
        '-highlightthickness' => 0,
       );

    $l_Canvas->pack
       (
        '-fill' => 'both',
        '-expand' => 'false',
        '-padx' => 0,
        '-pady' => 0,
       );

    $l_Canvas->Tk::bind ('<ButtonPress-1>' => [\&Press, $this]);
    $l_Canvas->Tk::bind ('<B1-Motion>' => [\&Resize, $this]);
    $l_Canvas->Tk::bind ('<Configure>' => [\&Configure, $this]);
    $this->Tk::bind ('<Enter>' => [\&Enter, $this]);
    $this->Tk::bind ('<Leave>' => [\&Leave, $this]);

    return $this;
   }

sub Configure
   {
    my ($p_Canvas, $this) = @_;

    return unless ($this->IsMapped());

    my $l_Height = $this->height();
    my $l_Width = $this->width();

    $p_Canvas->configure
       (
        '-scrollregion' => [0, 0, $l_Width, $l_Height],
       );

    unless (defined ($this->{'m_TrimList'}))
       {
        my $l_HighColor = $this->Darken ($this->cget ('-background'), 150);
        my $l_LowColor = $this->Darken ($this->cget ('-background'), 60);

        for (my $l_Index = 0; $l_Index < $TRIMCOUNT; ++$l_Index)
           {
            push
               (
                @{$this->{'m_TrimList'}},
                $p_Canvas->create ('line', 30, 0, 0, 30, '-fill' => $l_HighColor),
                $p_Canvas->create ('line', 30, 1, 1, 30, '-fill' => $l_LowColor),
               );
           }
       }

    for (my $l_Index = 0; $l_Index <= $#{$this->{'m_TrimList'}}; $l_Index += 2)
       {
        my ($l_Light, $l_Dark) = @{$this->{'m_TrimList'}} [$l_Index .. ($l_Index + 1)];
        my $l_Divisor = (($l_Index + 2) / 2) - 1;

        $p_Canvas->coords
           (
            $l_Light,
            $l_Width, ($l_Height / ($TRIMCOUNT + 1)) * $l_Divisor,
            ($l_Width / ($TRIMCOUNT + 1)) * $l_Divisor, $l_Height,
           );

        $p_Canvas->coords
           (
            $l_Dark,
            $l_Width, (($l_Height / ($TRIMCOUNT + 1)) * $l_Divisor) + 2,
            ($l_Width / (($TRIMCOUNT + 1)) * $l_Divisor) + 2, $l_Height,
           );
       }
   }

sub Enter
   {
    $_[0]->{'m_Cursor'} = $_[0]->cget ('-cursor');
    $_[0]->configure ('-cursor' => ($^O =~ /^(MSWin32|DOS)$/ ? 'size_nw_se' : 'bottom_right_corner'));
   }

sub Leave
   {
    $_[0]->configure ('-cursor' => $_[0]->{'m_Cursor'} || 'arrow');
   }

sub Press
   {
    $_[1]->{'-deltax'} = $_[1]->pointerx();
    $_[1]->{'-deltay'} = $_[1]->pointery();
   }

sub Resize
   {
    my @l_Coordinates = split (/[+x]/, $_[1]->toplevel()->geometry());
    
    $l_Coordinates [0] += ($_[1]->pointerx() - $_[1]->{'-deltax'});
    $l_Coordinates [1] += ($_[1]->pointery() - $_[1]->{'-deltay'});

    $_[1]->{'-deltax'} = $_[1]->pointerx();
    $_[1]->{'-deltay'} = $_[1]->pointery();

    $_[1]->toplevel()->geometry
       (
        $l_Coordinates [0].'x'.$l_Coordinates [1] # .'+'.$l_Coordinates [2].'+'.$l_Coordinates [3]
       );
   }

1;

__END__

=cut

=head1 NAME

Tk::CornerBox - a geometry manager for scaling two subwidgets

=head1 SYNOPSIS

    use Tk;

    use Tk::CornerBox;

    my $l_MainWindow = MainWindow->new();

    my $l_Corner = $l_MainWindow->CornerBox();

    $l_Corner->place
       (
        '-width' => 20,
        '-height' => 20,
        '-relx' => 1,
        '-rely' => 1,
        '-anchor' => 'se',
        '-x' => -3,
        '-y' => -3,
       );

    Tk::MainLoop();

=head1 DESCRIPTION

The CornerBox is a simple textured widget that allows you to resize the window its in by dragging it.
You use it by creating one in the regular Tk manner and (preferably) packing or placing it in the
lower right corner of your window. It is frame derived and should act accordingly.

=head1 AUTHORS

Damion K. Wilson, dkw@rcm.bm

Based on the little corner drag widget that you see all over the place.

Hey, I know it's a M$oft thingy but I've got to integrate my Perl/Tk apps into
that environment.

=head1 HISTORY 
 
February 1999: Actually started using it

=cut
