#!/usr/local/bin/perl -w
# COPYRIGHT
#       Author: Oded S. Resnik
#       Copyright (c) 2003-2010 Raz Information Systems Ltd.
#       http://www.raz.co.il
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#######################################################################

use Tk;
require Tk::Dialog;
require Tk::Text::Viewer;
use vars qw($VERSION);

$VERSION='1.002';
my $width = $ARGV[0] ? 132 : 80;
my $height = 25;
my $font = "fixed";
my $fontSize = "12";
########################################################################
my $mw = MainWindow->new;
my $t1 = $mw->Scrolled('Viewer', -wrap => 'none', -width => $width,  
	-height=> $height, -cursor=>'tcross',
	-font=> $font . " " . $fontSize);
$t1->tagConfigure('sel', -foreground => 'red');
$t1->pack(-side => 'right', -fill => 'both', -expand => 'yes');
$t1->LabelConfig({-text=>"Search :", -foreground=>'blue'});
$t1->EntryConfig("-foreground=>'blue'");
# ------ Menu
my $mMenu = $t1->Menu( -type => 'menubar' );
$mw->configure( -menu => $mMenu );
my %MenuItems = (
    '9Help' =>
    [
                 [ 'command' => 'Help', -accelerator => 'F1',
                   -underline => 0,
                   -command => sub { ShowHelp() ; } ],
                 "-",
         [ 'command' => 'About...', -command => sub { DoAbout() ; } ],
    ],
   '1File' =>
    [
        [ 'command' => 'Quit...', -accelerator => 'Control-F4',
               -underline => 0,
               -command => [destroy => $mw] ]
    ],
   '2Edit' =>
    [
        [ 'command' => 'Copy', -accelerator => 'Control-c',
               -underline => 0,
               -command => sub { $t1->clipboardCopy;},
           -state => 'normal'],
        "-",
        [ 'command' => 'Select All', -accelerator => 'Alt-a',
               -underline => 0,
               -command => sub { $t1->selectAll}],
        [ 'command' => 'Unselect', -accelerator => 'Alt-u',
               -underline => 0,
               -command => sub { $t1->unselectAll;}]
    ],


  '3Search' =>
    [
                 [ 'command' => 'Find Text...',
                   -accelerator => 'Control-f',
                   -underline => 0,
                   -command => sub { $t1->FindSimplePopUp() ; } ],
        "-",
        [ 'command' => 'Find Next',
        -accelerator => 'F4',
        -command =>  sub {$t1->FindSelectionNext() }],
        [ 'command' => 'Find Previous',
        -accelerator => 'F3',
        -command =>  sub {$t1->FindSelectionPrevious() }],
        [ 'command' => 'Find All',
        -accelerator => 'F5',
        -command =>  sub {$t1->FindAll('-exact','-nocase') }],


    ]);
foreach (sort keys %MenuItems) {
        my ($binbKey, $bindCmd) = GetCmd($MenuItems{$_});
    /^\d{1}(.*)/;
    $mMenu->Menubutton(    -text =>$1,
                                   -underline => 0,
                                   -menuitems => $MenuItems{$_}
                          );
    };# MenuItems

#---- Check command line
my $me = $0;
$me =~ s|^.*/||;
$me =~ s/\..*$//;
 
if ($ARGV[0]) {
    return 1 if $ARGV[0] eq '-Test.pm Syntax test';
    die "$me: Can't read $ARGV[0] \n" unless -r $ARGV[0];
    $t1->Load($ARGV[0]);
    $t1->configure(-background=>'white');
    $t1->focus();
        $mw->title("$me: $ARGV[0]");
    }
    else  {
        my $lb = $mw->Scrolled('Listbox', -cursor=>'hand1');
        $lb->packAdjust(-side => 'left', -fill => 'both', -delay => 1);
        $lb->bind('<Double-ButtonRelease-1>',
                           sub { $t1->Load($lb->getSelected);
			$t1->configure(-background=>'white');
			$t1->focus();
                                    $mw->title("$me: " . $lb->getSelected) });
    opendir(DIR,'.');
    my $name;
    foreach $name (readdir(DIR))
         {
          $lb->insert('end',$name) if (-T $name);
         }
    closedir(DIR);
    }
MainLoop;

sub DoAbout {
    my $aboutdialog;
    $aboutdialog =
    $mw->Dialog(-buttons => ['Ok'],
            -default_button => 'OK',
            -bitmap=> 'info',
            -title => 'About',
            -text => "Text Viewer Version: $VERSION\n" .
                           "By Oded S. Resnik\n\n"        .
                           "\n"        .
                           "\n",
        -wraplength     => '6i',
);

    $aboutdialog -> Show;
}

sub ShowHelp {
    my $helpmsg = '
key-N find previous match
Key-n find next match
Key-/ search forward
    Enter search text - then type Enter

Use right mouse to select text, use left mouse for text menu.

';
    my $helpdialog;
    my $help_text;
    $helpdialog = $t1->DialogBox( -buttons => ["Ok"],
                       -title => 'Help');
    $help_text = $helpdialog -> add ('Label');
    $help_text -> configure ( -font =>'terminal',
                -justify => 'left',
                               -text =>$helpmsg);

    $help_text -> pack;
    $helpdialog -> Show;
}

sub GetCmd {
# Application key binding from menu definitions
my $rArray = shift;
my ($rCode, $accelerator, $param) = (undef, undef, undef);
foreach (@$rArray) {
    GetCmd($_) if (ref($_) eq 'ARRAY');
    for ($_) {
        if (/-command|-accelerator/) {
            $param = $_;
            next;
            }
        if  ($param && $param =~ /-command/) {
            $rCode = $_ if ((ref($_)) =~ /CODE|ARRAY/);
            $param = undef;
            next;
            }
        if  ($param && $param =~ /-accelerator/) {
            $accelerator = $_;
            $param = undef;
            next;
            }
        }
    if ($rCode && $accelerator) {
        $mw->bind($mw,"<$accelerator>",$rCode);
        }
    }
};
1;
__END__

=head1 NAME

Viewer.pl - File viewer using Tk::Text::Viewer

=head1 SYNOPSIS

        viewer.pl [TextFile]

=head1 DESCRIPTION

viewer is text viewer utility that displays text files under TK.
Check the Help menu for user instructions.

=head1 SEE ALSO

L<Tk::Text::Viewer>.

=head1 AUTHOR

=over 4


C<Tk::Text::Viewer> was written by Oded S. Resnik E<lt>raz@raz.co.ilE<gt> in 2003.

B<Copyright (c) 2003-2010 RAZ Information Systems All rights reserved>.
I<http://www.raz.co.il/>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file

=back

=cut
