#!/usr/local/bin/perl

# Slider widget demo program

use strict;
use Tk;
use Tk::Label;
use Tk::Scale;

my $mw=MainWindow->new(-title=>'slider demo');

use vars qw/$x/;

my $w_Scale_001 = $mw -> Scale ( -sliderlength=>10, -variable=>\$x, -relief=>'flat', -troughcolor=>'DarkKhaki', -showvalue=>0, -tickinterval=>20, -state=>'normal', -orient=>'horizontal', -length=>200 ) -> pack(-side=>'left', -anchor=>'nw', -padx=>5, -pady=>5);
my $Value = $mw -> Label ( -text=>'Value', -relief=>'flat' ) -> pack(-side=>'left', -anchor=>'nw');
my $w_Label_002 = $mw -> Label ( -text=>'w_Label_002', -relief=>'flat', -textvariable=>\$x, -justify=>'left' ) -> pack(-side=>'left', -anchor=>'nw');
MainLoop;

#===vptk end===< DO NOT CODE ABOVE THIS LINE >===
