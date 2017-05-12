#! /usr/bin/perl

use Tk::IconCanvas;
use Tk::Menu;
use Tk;

sub Setup
   {
    my $l_MainWindow = Tk::MainWindow->new();

    my $l_ItemMenu = MakeMenu
       (
        $l_MainWindow,
        'Connect',
        'Detach',
        'Delete',
        'Copy',
       );

    my $l_CanvasMenu = MakeMenu
       (
        $l_MainWindow,
        'Opaque Toggle',
        'Autoadjust Toggle',
        'Drag Toggle',
        'Adjust',
        'Paste',
        'Postscript',
       );

    my $l_ServerMenu = MakeMenu
       (
        $l_MainWindow,
        'Connect',
        'Detach',
        'Delete',
        'Copy',
       );

    my $l_Canvas = $l_MainWindow->IconCanvas
       (
        '-command' => sub {printf ("Magic [%s]\n", join ('|', @_));},
        '-menu' => $l_CanvasMenu,
        '-relief' => 'sunken',
        '-borderwidth' => 2,
        '-bg' => 'white',
       );

    $l_Canvas->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
       );

    my $l_One = $l_Canvas->Icon
       (
        '-title' => 'Database server',
        '-pixmap' => 'database',
        '-menu' => $l_ItemMenu,
       );

    my $l_Three = $l_Canvas->Icon
       (
        '-title' => 'serious',
        '-pixmap' => 'server',
        '-menu' => $l_ServerMenu,
       );

    foreach my $l_Name (qw (A B C D))
       {
        my $l_Two = $l_Canvas->Icon
           (
            '-menu' => $l_ItemMenu,
            '-pixmap' => 'client',
            '-title' => $l_Name,
            '-attach' => $l_One,
            '-x' => 400,
            '-y' => 400,
           );
       }

    foreach my $l_Name (qw (mail netclient))
       {
        my $l_Two = $l_Canvas->Icon
           (
            '-menu' => $l_ItemMenu,
            '-pixmap' => $l_Name,
            '-title' => $l_Name,
            '-x' => 200,
            '-y' => 400,
           );
       }

    $l_Canvas->configure ('-attach' => [$l_Three, $l_One]);
    $l_Canvas->configure ('-attach' => [$l_Three, $l_One]);
   }

sub MakeMenu
   {
    my $l_Menu = shift->Menu (-tearoff => 0);

    foreach my $l_Label (@_)
       {
        $l_Menu->add
           (
            'command',
            '-label' => $l_Label,
            '-command' => sub {MenuSelection ($l_Menu, $l_Label, @_);}
           );
       }

    return $l_Menu;
   }

sub MenuSelection
   {
    my ($p_Menu, $p_Label) = (@_);
    my $l_Canvas = $p_Menu->{m_Canvas};
    my $l_Selection = $l_Canvas->cget (-menuselection);

    if (defined ($l_Selection)) # Item menu invocations here, Canvas menu doesn't return an item
       {
        if ($p_Label eq 'Detach')
           {
            $l_Canvas->detach ($l_Selection);
           }
        elsif ($p_Label eq 'Delete')
           {
            $l_Canvas->delete ($l_Selection);
           }
        elsif ($p_Label eq 'Copy')
           {
            $l_Canvas->copy ($l_Selection);
           }
       }
    elsif ($p_Label eq 'Opaque Toggle')
       {
        $l_Canvas->configure (-opaque => ! $l_Canvas->cget (-opaque));
       }
    elsif ($p_Label eq 'Drag Toggle')
       {
        $l_Canvas->configure (-dragallowed => ! $l_Canvas->cget (-dragallowed));
       }
    elsif ($p_Label eq 'Adjust')
       {
        $l_Canvas->ArrangeItems();
       }
    elsif ($p_Label eq 'Autoadjust Toggle')
       {
        $l_Canvas->configure (-autoadjust => ! $l_Canvas->cget (-autoadjust));
       }
    elsif ($p_Label eq 'Paste')
       {
        $l_Canvas->paste ($l_Selection);
       }
    elsif ($p_Label eq 'Postscript')
       {
        $l_Canvas->postscript ('-file' => 'dkwtest.ps', -colormode => 'grey');
       }
   }

Setup();
Setup();

Tk::MainLoop();