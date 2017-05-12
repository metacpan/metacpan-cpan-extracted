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
use Tk::Optionbox;

my $mw = MainWindow->new();
my $selection1 =  '-';
my @options1 = qw/aaa bbb ccc ddd eee fff ggg/;
my $opt1 = $mw->Optionbox (
        -text     => "options1",
        -command  => \&test1_cb,
        -options  => [ @options1 ],
        -variable => \$selection1, 
		-tearoff  => '1',
		-activate => '1',
)->pack(-padx => 50, -pady => 50);;



my $selection2 =  'fff';
my @suboptions = ( ['xxx', 1], ['yyy', 3],  ['zzz', 5] , ['vvvv', 6], '@@@' );
my @suboptions2 = ( ['aa', 11], ['bb', 33],  ['cc', 55] , [['==', \@suboptions], undef], ['dd', 66] );

my @options2 = (['aaa', 1], '333', ['bbb', 1], ['ccc', 1], ['ddd', 1], ['eee', 1], ['fff', 1], ['ggg', 1],
				['hhh', 1], ['iii', 1], ['jjj', 1], ['qqq', 1], ['www', 8], [['+++', \@suboptions], undef],
				['vvvv', 2],[['***', \@suboptions2], undef],'###' );
my $opt2 = $mw->Optionbox (
        #-text     => "options2",
        -bitmap  => '@' . Tk->findINC('cbxarrow.xbm'),
        -command  => \&test2_cb,
        -options  => [ @options2 ],
        -variable => \$selection2, 
		-tearoff  => '0',
		-rows => 10,
		-activate => '0',
		-separator => '/',
		-font => 'helvetica 20',
		#-foreground => 'red',  -bg => 'green',
		#-activeforeground => 'white',
		#-activebackground => 'blue',
)->pack(-padx => 50, -pady => 50);

# try feature of add-on
$opt2->add_options(@suboptions);

Tk::MainLoop;

sub test1_cb
{
    print "selection1 called with [@_], \$var = >$selection1<\n";
}
sub test2_cb
{
    print "selection2 called with [@_], \$var = >$selection2<\n";
}

###
### EOF
###
