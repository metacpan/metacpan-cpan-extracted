#!/usr/bin/perl -w
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: tk_menudialog_demo.pl
## Description: Demo of using the Tk::MenuDialog module
##----------------------------------------------------------------------------
use strict;
use warnings;
## Cannot use Find::Bin because script may be invoked as an
## argument to another script, so instead we use __FILE__
use File::Basename qw(dirname fileparse basename);
use File::Spec;
## Add script directory
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)));
## Add script directory/lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{lib});
## Add script directory/../lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{..}, qq{lib});
use Readonly;
use Tk::MenuDialog 0.04;
use Data::Dumper;

##---------------------------------------
## Hash used to initialize the menu
##---------------------------------------
Readonly::Scalar my $MAIN_MENU => {
  title => qq{Tk::MenuDialog Demo},
  can_cancel => 0,
  button_spacing => 20,
  items => [
    {
      label => qq{&Configure},
      icon  => qq{settings.png},
    },
    { 
      label => qq{Te&st},
      icon  => qq{test.png},
    },
    {
      label => qq{&Run},
      icon  => qq{run.png},
      disabled => 1,
    },
    {
      label => qq{E&xit},
      icon  => qq{exit.png},
    },
  ],
};

##----------------------------------------------------------------------------
## Main code
##----------------------------------------------------------------------------
my $menu = Tk::MenuDialog->new->initialize($MAIN_MENU);

## Add this script's directory to the icon path
$menu->add_icon_path(dirname(__FILE__));

## Show the menu
my $data = $menu->show;

## Dump what we received
print(
  qq{The following data was returned:\n},
  Data::Dumper->Dump([$data,], [qw( data)]),
  qq{\n},
  );


__END__