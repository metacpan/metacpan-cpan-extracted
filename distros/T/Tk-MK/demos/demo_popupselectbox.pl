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
use Tk::PopUpSelectBox;

my $mw = MainWindow->new();
my $selection1 =  '-';
my @options1 = qw/aaa bbb ccc ddd eee fff ggg/;
my $opt1 = $mw->PopUpSelectBox (
        -command  => \&test1_cb,
        -options  => [ @options1 ],
        -variable => \$selection1, 
		-activate => '1',
)->pack(-padx => 50, -pady => 50);;

# my $opt2 = $mw->PopUpSelectBox (
#         -command  => sub { print "hallo >@_<\n" },
#         -options  => [ qw/AAA BBB CCC/ ],
#         -variable => \$selection1, 
# 		-activate => '1',
# )->pack(-padx => 50, -pady => 50);;


my $selection2 =  'fff';
my @suboptions = ( ['xxx', 1], ['yyy', 3],  ['zzz', 5] , ['qqqq', 6], '@@@' );
my @suboptions2 = ( ['aa', 11], ['bb', 33],  ['cc', 55] , [['==', \@suboptions], undef], 
					['ee', 77], ['ff', 88] , ['gg', 99], ['hh', 10],
					['ii', 11], ['jj', 22] , ['kk', 33], ['ll', 44],
				  );

my @options2 = (['aaa', 1], '333', ['bbb', 1], ['ccc', 1], ['ddd', 1], ['eee', 1], ['fff', 1], ['ggg', 1],
				['hhh', 1], ['iii', 1], ['jjj', 1], ['qqq', 1], ['www', 8], [['+++', \@suboptions], undef],
				['vvvv', 2],[['***', \@suboptions2], undef],'###', 'ZZZ',
				[['***', \@suboptions2], undef]
			   );

print "----------------------------------------------------------\n";
my $opt2 = $mw->PopUpSelectBox (
        #-bitmap  => '@' . Tk->findINC('cbxarrow.xbm'),
        -image  => $mw->Getimage('folder'),
        -command  => \&test2_cb,
        -options  => [ @options2 ],
        -variable => \$selection2, 
		-listmaxheight => 10,
		-activate => '0',
		-separator => '/',
		-font => 'helvetica 20',
		#-foreground => 'red',  -bg => 'green',
# 		-activeforeground => 'white',
# 		-activebackground => 'blue',
		-listbackground => 'white',
		-selectforeground => 'yellow',
		-selectbackground => 'blue',
		#-listheight => 5,
		-ignoreExisting => 1,
)->pack(-padx => 50, -pady => 50);

# try feature of add-on
#$opt2->add_options(@suboptions);

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
