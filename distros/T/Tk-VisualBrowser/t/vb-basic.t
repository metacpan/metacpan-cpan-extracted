# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Tk-VisualBrowser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
BEGIN { use_ok('Tk::VisualBrowser') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Tk;
my $top = MainWindow->new;

my $vb;

my $VERSION = 1.00;

# Menubar
$top->configure(-menu => my $menubar = $top->Menu
  ,  -title => "Tk::VisualBrowser ".$Tk::VisualBrowser::VERSION
);
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
$menubar->cascade(-label => "~Help",
  -menuitems =>
  [
    [qw/command About -command/, sub{ print "test.pl: version $VERSION\n"}],
    [qw/command Contents -command/, sub{ print "TODO: implement Help ...\n" }],
  ],
);



$vb = $top->VisualBrowser(-rows => 3, -cols => 4)->pack;
my @IMG = qw(
ScanImage16.gif
ScanImage17.gif
ScanImage18.gif
ScanImage19.gif
ScanImage20.gif
ScanImage21.gif
ScanImage22.gif
ScanImage23.gif
ScanImage39.gif
ScanImage40.gif
ScanImage41.gif
);
my @IMG2 = @IMG; # copy

# try to use 0 as number of rows:
eval {
  $vb->configure(-rows => 0, -cols => 4);
};
#print ">>$@<<\n";
ok($@, "error in number of rows");

# try to use 0 as number of cols:
eval {
  $vb->configure(-rows => 3, -cols => 0);
};
#print ">>$@<<\n";
ok($@, "error in number of cols");


$vb->configure(-pictures => \@IMG,
  -rows => 3, -cols => 3,
  -thumbnail => \&get_thb,
  -highlight => "yellow",
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
ok( eq_array(\@sel, \@IMG), "select all");

# select none
$vb->deselect_all;
@sel = $vb->get_selected;
is( scalar @sel, 0, "deselect all");

$vb->select(3);
$vb->select(4);
@sel = $vb->get_selected_idx;
ok( eq_array(\@sel, [3, 4]), "select 3, 4");
@sel = $vb->get_selected;
ok( eq_array(\@sel, [$IMG[3], $IMG[4]]), "select names 3, 4");
$vb->deselect_all;

# swap two pictures
($IMG2[3], $IMG2[5]) = ($IMG2[5], $IMG2[3]);
$vb->{SEL}[5] = 1;  # whitebox test ...
$vb->{SEL}[3] = 1;
$vb->swap_selected;
$vb->select_all;
@sel = $vb->get_selected;
$vb->deselect_all;
ok( eq_array(\@sel, \@IMG2), "swap");

# select more than two and try to swap
$vb->{SEL}[5] = 1;  # whitebox test ...
$vb->{SEL}[3] = 1;
$vb->{SEL}[2] = 1;
my $ok = $vb->swap_selected;

is($ok, 0, "error in swap");
$vb->deselect_all;


# try to get color info about some subwidgets:
my $bg = $vb->{Thmb}[0][1]->cget(-background);
is($bg, "#CCCCCC", "bg Thmb");
$vb->configure(-bg_color => "#c3c3c3");
$vb->configure(-pictures => \@IMG ); # in order to get the new colors via rebuild ...
$bg = $vb->{Thmb}[0][1]->cget(-background);
is($bg, "#c3c3c3", "bg Thmb");

#======================
if (! $ENV{INTERACTIVE_MODE}){
$top->after(1500, sub{ remove_test();} );
$top->after(3000, sub{ ok(1, "exit automatically"); exit} );
}
MainLoop;

sub get_thb {
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

sub remove_test { # {{{
  $vb->deselect_all();
  $vb->select(3);
  $vb->select(5);
  $vb->remove_selected();
  $vb->select_all();
  my @sel = $vb->get_selected;
  print "@sel\n";
  print "@IMG\n";
  splice(@IMG2, 5, 1);
  splice(@IMG2, 3, 1);
  ok( eq_array(\@sel, \@IMG), "select after remove");
  ok( eq_array(\@sel, \@IMG2), "select after remove");
} # remove_test }}}
__END__

 vim:ft=perl:foldmethod=marker:foldcolumn=4
