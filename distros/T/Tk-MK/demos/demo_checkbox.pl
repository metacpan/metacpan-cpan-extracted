#!/usr/local/bin/perl -w
######################################## SOH ###########################################
## Function : Replacement for Tk:Optionmenu (more flexible handling for 'image_only')
##
## Copyright (c) 2002-2005 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
######################################## SOH ###########################################

##############################################
### Use
##############################################
use strict;

# graphical stuff
use Tk;
use Tk::Checkbox;

my $var = 'Down';
my $var2 = '11';
my $var3 = '0';
my $mw = MainWindow->new();

my $cb1 = $mw->Checkbox (
    -variable => \$var,
    -command  => \&test_cb,
    -onvalue  => 'Up',
    -offvalue => 'Down',
	#-noinitialcallback => '1',
)->pack(-padx => 50, -pady => 50);;

$cb1->configure( '-onvalue'  => 'upup' );
$cb1->configure( '-offvalue'  => 'downdown' );


my $cb2 = $mw->Checkbox (
    -variable => \$var2,
    -command  => \&test2_cb,
    -onvalue  => '11',
    -offvalue => '00',
	-noinitialcallback => '1',
	-size => '30',
)->pack(-padx => 50, -pady => 50);;


my $cb3 = $mw->Checkbox (
    -variable => \$var3,
    -command  => \&test3_cb,
	-size => '8',
)->pack(-padx => 50, -pady => 50);;


Tk::MainLoop;

sub test_cb
{
    print "test_cb called with [@_], \$var = >$var<\n";
}
sub test2_cb
{
    print "test2_cb called with [@_], \$var = >$var2<\n";
}
sub test3_cb
{
    print "test3_cb called with [@_], \$var = >$var3<\n";
}


###
### EOF
###

