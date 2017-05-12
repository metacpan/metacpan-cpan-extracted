#!/usr/bin/perl

use strict;
use lib "lib"; # use local version
use Tk;
use Tk::VisualBrowser;



my $top = MainWindow->new;

my $vb;

my $VERSION = 1.03;

my $simulate_create_thumbs = 0;
# Menubar
$top->configure(-menu => my $menubar = $top->Menu);
$menubar->cascade(-label => "~File",
  -menuitems =>
  [
    [command => 'List of Pictures', '-command', sub{ show_list( $vb) }],
    [command => 'List of selected', '-command', sub{ show_selected( $vb) }],
    [command => 'Swap', '-command', sub{ $vb->swap_selected }],
    [command => 'Select all', '-command', sub{ $vb->select_all }],
    [command => 'Deselect all', '-command', sub{ $vb->deselect_all }],

    [qw/command Exit -command/, sub{ exit }],
  ],
);
$menubar->cascade(-label => "~Configure",
  -menuitems =>
  [
    [command => '4 rows, 4 columns', '-command', sub{ $vb->configure(-rows =>4, -cols =>4) }],
    [command => '5 rows, 8 columns', '-command', sub{ $vb->configure(-rows =>5, -cols =>8) }],
    [command => '-use_labels=> 0', '-command', sub{ $vb->configure(-use_labels => 0, -rows =>5, -cols =>8) }],
  ],
);
$menubar->cascade(-label => "~Help",
  -menuitems =>
  [
    [qw/command About -command/, sub{ print "test.pl: version $VERSION\n"}],
    [qw/command Contents -command/, sub{ print "TODO: implement Help ...\n" }],
  ],
);



my $frm1 = $top->Frame->pack;

my $cb_sim_crthb = $frm1->Checkbutton(
  -text      => "Simulate Creation of Thumbs",
  -variable  => \$simulate_create_thumbs,
  -onvalue   => 1,
  -offvalue  => 0,
)->pack;



#$vb = $top->VisualBrowser(-rows => 8, -cols => 8)->pack;
$vb = $top->VisualBrowser(-use_labels=> 1, -use_balloons => 1)->pack;
my @IMG =();

my $dir = "test-thumbs";
my @Title;
my @Label;
my $i = 0;
opendir(D, $dir) or die "Can't open directory $dir: $!\n";  
foreach my $file(readdir(D)){
  push @IMG, "$dir/$file" if $file =~ /^th/; 
  $i++;
  push @Title, "Bild Nr. $i";
  push @Label, "Image $i";
} # foreach $file

my @IMG2 = @IMG; # copy

$vb->configure(-pictures => \@IMG,
  -rows => 5, -cols => 8,
  -thumbnail => \&get_thb,
  -highlight => "yellow",
  -balloon_texts => \@Title,
  -label_texts => \@Label,
);


my $b_exit = $top->Button(
  -text      => "Exit",
  -width     => 6,
  -command   => sub{
    exit;
                },
)->pack();

$vb->scroll(0);


# select all
$vb->select_all;
my @sel = $vb->get_selected;
$vb->deselect_all;


# select none


# swap two pictures



# try to get color info about some subwidgets:


#======================
MainLoop;

sub get_thb {
  select undef, undef, undef, 0.1 if $simulate_create_thumbs;
  shift;
}

sub show_list { #{{{
  my $vb = shift;
  show_files(@{$vb->cget('-pictures')});
} # show_list }}}

sub show_selected { #{{{
  my $vb = shift;
  show_files($vb->get_selected);
} # show_selected #}}}

sub show_files { #{{{
  my @files = @_;
  my $tl = $top->Toplevel( -title => "Pictures in ./");

  my $list = $tl -> ScrlListbox(
  -label => 'Pictures',
  -height => 15,
  -width  => 55,
  -selectmode => 'single',
  -exportselection => 0,
  ) -> pack;

  my $b_ok = $tl->Button(
    -text      => "Ok",
    -width     => 4,
    -command   => sub{
                     $tl->destroy;
                  },
  )->pack;
  
  foreach my $jpg ( @files ){
    $list->insert("end", " $jpg");
  }
} # show_files }}}

