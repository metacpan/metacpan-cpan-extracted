#!/usr/bin/perl

use XML::STX;


use Gtk;
use strict;

my $vGtk;
eval { require Gtk; $vGtk = $Gtk::VERSION; };
if ($@) {
    print "Gtk-Perl is missing!\n";
    print "It must be installed before you can run stxview.pl\n";
    exit;
    }

set_locale Gtk;  # internationalize
init Gtk;        # initialize Gtk-Perl

my $false = 0;
my $true = 1;

my @titles;

my $window;
my $vbox;
my $pane;
my $tree_scrolled_win;
my $list_scrolled_win;
my $tree;
my $root;
my $subtree;
my $item;
my $list;
my $entry;

my $pass_through = {0 => 'none', 1 => 'all', 2 => 'text'};
my $yn = {0 => 'no', 1 => 'yes'};
my $visibility = {1 => 'local', 2 => 'group', 3 => 'global'};

# Create a window
$window = new Gtk::Window( 'toplevel' );
$window->set_usize( 750, 500 );
$window->set_title( "STX Viewer" );
$window->set_policy( $false, $false, $true );
$window->signal_connect( "delete_event", sub { Gtk->exit( 0 ); } );

# Create the main VBox
$vbox = new Gtk::VBox( $false, 0 );
$window->add( $vbox );
$vbox->show();

# ----------------------------------------
# Create a menu
my $menubar = new Gtk::MenuBar();
$vbox->pack_start( $menubar, $false, $false, 2 );
$menubar->show();

my $menu_sheet = new Gtk::MenuItem( "Stylesheet" );
$menu_sheet->signal_connect( 'activate', \&openSheet );
$menubar->append( $menu_sheet );
$menu_sheet->show();

my $menu_about = new Gtk::MenuItem( "About" );
$menu_about->signal_connect( 'activate', \&about );
$menubar->append( $menu_about );
$menu_about->show();

my $menu_exit = new Gtk::MenuItem( "Exit" );
$menu_exit->signal_connect( 'activate', sub { Gtk->exit( 0 ); } );
$menubar->append( $menu_exit );
$menu_exit->show();

# ----------------------------------------
# Create a horizontal pane
$pane = new Gtk::HPaned();
$vbox->pack_start( $pane, $false, $false, 2 );
$pane->set_handle_size( 10 );
$pane->set_gutter_size( 8 );
$pane->show();

# Create a ScrolledWindow for the tree
$tree_scrolled_win = new Gtk::ScrolledWindow( undef, undef );
$tree_scrolled_win->set_usize( 225, 470 );
$pane->add1($tree_scrolled_win);
$tree_scrolled_win->set_policy( 'automatic', 'automatic' );
$tree_scrolled_win->show();

# Create a ScrolledWindow for the list
$list_scrolled_win = new Gtk::ScrolledWindow( undef, undef );
$pane->add2( $list_scrolled_win );
$list_scrolled_win->set_policy( 'automatic', 'automatic' );
$list_scrolled_win->show();

# Create root tree
$tree = new Gtk::Tree();
$tree_scrolled_win->add_with_viewport( $tree );
$tree->set_selection_mode( 'single' );
$tree->set_view_mode( 'item' );
$tree->show();

# Create list box
# @titles = qw( Filename Size Permissions Owner Group Time Date );
$list = new Gtk::CList( 2 );
$list_scrolled_win->add( $list );
$list->set_column_width( 0, 175 );
$list->set_column_width( 1, 310 );
$list->set_selection_mode( 'single' );
$list->set_shadow_type( 'none' );
$list->show();

$window->show();
main Gtk;
exit( 0 );



### Subroutines ########################################


# Callback for expanding a tree
sub expandTree {
    my ( $item, $subtree ) = @_;
    
    my $group = $item->get_user_data();
    my $item_new;
    my $new_subtree;

    foreach my $t ( sort keys(%{$group->{templates}}) ) {
	my $name = $group->{templates}->{$t}->{pattern};
	$name =~ s/\{([^\}]+)\}/{ns}/g;
	$item_new = new_with_label Gtk::TreeItem( "template $t ($name)" );
	$item_new->signal_connect( 'select', \&selectItem, 
				   $group->{templates}->{$t});
	$subtree->append( $item_new );
	$item_new->show();
    }

    foreach my $p ( sort keys(%{$group->{procedures}}) ) {
	my $name = $group->{procedures}->{$p}->{name};
	$name =~ s/\{([^\}]+)\}/{ns}/g;
	$item_new = new_with_label Gtk::TreeItem( "procedure $p ($name)" );
	$item_new->signal_connect( 'select', \&selectItem,
				   $group->{procedures}->{$p});
	$subtree->append( $item_new );
	$item_new->show();
    }

    foreach my $g ( sort keys(%{$group->{groups}}) ) {
	my $name = $group->{groups}->{$g}->{name};
	$name =~ s/\{([^\}]+)\}/{ns}/g;
	$item_new = new_with_label Gtk::TreeItem( "group $g ($name)" );
	$item_new->set_user_data( $group->{groups}->{$g} );
	$item_new->signal_connect( 'select', \&selectItem, 
				   $group->{groups}->{$g});
	$subtree->append( $item_new );
	$item_new->show();
	
	$new_subtree = new Gtk::Tree();
	$item_new->set_subtree( $new_subtree );
	$item_new->signal_connect( 'expand', \&expandTree, $new_subtree );
	$item_new->signal_connect( 'collapse', \&collapseTree );
	
    }
}


# Callback for collapsing a tree
sub collapseTree {
    my ( $item ) = @_;

    my $subtree = new Gtk::Tree();

    $item->remove_subtree();
    $item->set_subtree( $subtree );
    $item->signal_connect( 'expand', \&expandTree, $subtree );
}


# Called whenever an item is clicked
sub selectItem {
    my ( $widget, $o ) = @_;

    $list->clear();
    
    if (ref $o eq 'XML::STX::Stylesheet') {
	$list->append('STYLESHEET', '');
	my @name = split("/", $o->{URI});
	$list->append('- principal module file:', $name[-1]);

	$list->append('', '');
	$list->append('Stylesheet options', '');
	$list->append('- stxpath-default-namespace:', 
		      $o->{Options}->{'stxpath-default-namespace'}->[-1]);
	$list->append('- output-encoding:',
		      $o->{Options}->{'output-encoding'});

	_groupProperties($o->{dGroup}, 'Default group options');

    } elsif (ref $o eq 'XML::STX::Group') {
	$list->append('GROUP', '');
	$list->append('- name:', exists $o->{name} ? $o->{name} : '#anonymous');

	_groupProperties($o, 'Group options');

    } elsif (ref $o eq 'XML::STX::Template' && exists $o->{name}) {
	$list->append('PROCEDURE', '');
	$list->append('- name:', $o->{name});

	_templateProperties($o);

    } else {
	$list->append('TEMPLATE', '');
	$list->append('- match pattern:', $o->{pattern});
	$list->append('- priority:', 
		      $o->{eff_p} == 10 ? join('|',@{$o->{priority}}) : $o->{eff_p});

	_templateProperties($o);
    }

}


sub _groupProperties {
    my ($g, $label) = @_;

    $list->append('', '');
    $list->append($label, '');
    $list->append('- pass-through:', 
		  $pass_through->{$g->{Options}->{'pass-through'}});
    $list->append('- recognize-cdata:', 
		  $yn->{$g->{Options}->{'recognize-cdata'}});
    $list->append('- strip-space:', 
		  $yn->{$g->{Options}->{'strip-space'}});
    
    $list->append('', '');
    $list->append('Visible templates', '');
    
    my @pc1 = sort {$a <=> $b} map($_->{tid}, @{$g->{pc1}}, @{$g->{pc1A}});
    $list->append('- precedence category 1:', join(',', @pc1));
    my @pc2 = sort {$a <=> $b} map($_->{tid}, @{$g->{pc2}}, @{$g->{pc2A}});
    $list->append('- precedence category 2:', join(',', @pc2));
    my @pc3 = sort {$a <=> $b} map($_->{tid}, @{$g->{pc3}}, @{$g->{pc3A}});
    $list->append('- precedence category 3:', join(',', @pc3));

    $list->append('', '');
    $list->append('Visible procedures', '');
    
    @pc1 = sort keys %{$g->{pc1P}};
    $list->append('- precedence category 1:', join(',', @pc1));
    @pc2 = sort keys %{$g->{pc2P}};
    $list->append('- precedence category 2:', join(',', @pc2));
    @pc3 = sort keys %{$g->{pc3P}};
    $list->append('- precedence category 3:', join(',', @pc3));

    $list->append('', '');
    $list->append('Group variables and buffers', '');
    
    my @v = map('$' . $_, sort keys %{$g->{vars}->[-1]});
    $list->append('- variables:', join(',', @v));
    my @b = sort keys %{$g->{bufs}->[-1]};
    $list->append('- buffers:', join(',', @b));
}


sub _templateProperties {
    my $t = shift;

    $list->append('', '');
    $list->append('Properties', '');
    $list->append('- visibility:', $visibility->{$t->{visibility}});
    $list->append('- public:', $yn->{$t->{public}});
    $list->append('- new scope:', $yn->{$t->{'new-scope'}});
}


# Open a stylesheet file
sub openSheet {

    # Create a new file selection widget
    my $dialog = new Gtk::FileSelection( "File Selection" );
    $dialog->signal_connect( "destroy", sub { $dialog->destroy(); } );
    $dialog->hide_fileop_buttons();

    # Connect the ok_button to file_ok_sel function
    $dialog->ok_button->signal_connect( "clicked", \&fileOK, $dialog );

    # Connect the cancel_button to destroy the widget
    $dialog->cancel_button->signal_connect( "clicked",
					    sub { $dialog->destroy(); } );

    $dialog->show();
}


# Get the selected filename and print it to the console
sub fileOK {
   my ($widget, $dialog) = @_;
   my $file = $dialog->get_filename();

   my $stx = XML::STX->new();
   my $templ;

   eval { $templ = $stx->new_templates($file); };

   if ($@) {
       displayPopUp('STX Parser Error', $@, 550, 120);

   } else {
       displayTree($file, $templ);
   }
   $dialog->destroy();
}


# Displays tree
sub displayTree {
   my ($file, $template) = @_;

   $root->destroy() if $root;
   $list->clear();

   my @name = split("/", $file);
   my $subtree;

   $root = new_with_label Gtk::TreeItem ( $name[-1] );
   $tree->append( $root );
   $root->signal_connect( 'select', \&selectItem, $template->{Stylesheet});
   $root->set_user_data( $template->{Stylesheet}->{dGroup} );
   $root->show();

   $subtree = new Gtk::Tree();
   $root->set_subtree( $subtree );
   $root->signal_connect( 'expand', \&expandTree, $subtree );
   $root->signal_connect( 'collapse', \&collapseTree );
   $root->expand();
}


# About box
sub about {

    displayPopUp('About STX Viewer',
		 "STX Viewer for XML::STX\n" 
		 . "(XML-STX v$XML::STX::VERSION, Gtk-Perl v$vGtk)\n\n"
		 . '(c) 2002-2003 Ginger Alliance',
		 300, 150);    
}


sub displayPopUp {
    my ($title, $text, $width, $height) = @_;

    my $popup = new Gtk::Dialog();
    $popup->set_title( $title );
    $popup->set_position('center');
    $popup->set_default_size($width, $height) if ($width and $height);
    
    my $button = new Gtk::Button( 'OK' );
    $button->signal_connect("clicked", sub { $popup->destroy(); });
    $popup->action_area->pack_start( $button, $true, $true, 0 );
    $button->show();

    my $label = new Gtk::Label( $text );
    $popup->vbox->pack_start( $label, $false, $false, 10 );
    $label->show();

    $popup->show();
}
