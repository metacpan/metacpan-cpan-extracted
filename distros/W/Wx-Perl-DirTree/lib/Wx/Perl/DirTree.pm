package Wx::Perl::DirTree;

use strict;
use warnings;

use Exporter;

use Wx qw(
    wxOK wxID_ABOUT wxID_EXIT wxICON_INFORMATION wxTOP wxVERTICAL 
    wxNO_FULL_REPAINT_ON_RESIZE wxSYSTEM_MENU wxCAPTION wxMINIMIZE_BOX 
    wxCLOSE_BOX wxDefaultPosition
);

use Wx::Event qw(
    EVT_MENU EVT_CLOSE EVT_SIZE EVT_UPDATE_UI EVT_KEY_DOWN 
    EVT_TREE_SEL_CHANGING EVT_TREE_SEL_CHANGED
);

use Wx::Perl::VirtualTreeCtrl qw(EVT_POPULATE_TREE_ITEM);

our $VERSION = 0.07;

our @ISA = qw(Exporter);

our @EXPORT_OK   = qw(wxPDT_DIR wxPDT_FILE);
our %EXPORT_TAGS = (
    'const' => \@EXPORT_OK,
);

use constant wxPDT_DIR  => 2;
use constant wxPDT_FILE => 4;

sub new {
    my ($class,$parent,$size,$args) = @_;
    
    my $self = bless {}, $class;
    
    _load_subs();
    $self->_tree( $parent, $size, $args );
    
    return $self;
}

sub _tree {
    my ($self, $parent, $size, $args) = @_;
    
    if( !$self->{tree} and $parent and $size ){
        $self->{treectrl} = Wx::TreeCtrl->new( 
            $parent, -1, wxDefaultPosition, $size 
        );
        
        $self->{tree} = Wx::Perl::VirtualTreeCtrl->new( 
            $self->{treectrl}, -1, wxDefaultPosition, $size 
        );
    
        EVT_POPULATE_TREE_ITEM( $parent, $self->{tree}, \&AddChildren );
        
        # if user wants to restrict the items allowed to be selected
        # add another event handler
        if ( exists $args->{allowed} ) {
            EVT_TREE_SEL_CHANGING( $parent, $self->{tree}->GetTree, sub{
                my ($self,$event) = @_;
                CheckSelection( $event, $args->{allowed} );
            } );
        }
        
        add_root( $self->{tree}, $args );
    }
    
    return $self->{tree};
}

sub CheckSelection {
    my ($event,$allowed) = @_;
    
    my $tree = $event->GetEventObject;
    my $item = $event->GetItem;
    my $data = $tree->GetPlData( $item );
    
    return if $allowed & wxPDT_FILE && $allowed & wxPDT_DIR;
    
    if ( ( $allowed & wxPDT_FILE ) && -d $data ) {
        $event->Veto;
    }
    if ( ( $allowed & wxPDT_DIR ) && -f $data ) {
        $event->Veto;
    }
}

sub GetTree {
    my ($self) = @_;
    
    return $self->_tree->GetTree;
}

sub GetSelectedPath {
    my ($self) = @_;
    
    my $tree = $self->_tree;
    my $path = $tree->GetPlData( $tree->GetSelection );
    return $path;
}

sub _load_subs {
    my $os = $^O;
    
    if( $os =~ /win32/i ){
        require Wx::Perl::DirTree::Win32;
        Wx::Perl::DirTree::Win32->import();
    }
    else{
        require Wx::Perl::DirTree::Linux;
        Wx::Perl::DirTree::Linux->import();
    }

}

1;



=pod

=head1 NAME

Wx::Perl::DirTree - A directory tree widget for wxPerl

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Wx::Perl::DirTree;
  
  my $panel = Wx::Panel->new;
  my $tree  = Wx::Perl::DirTree->new( $panel, [100,100] );
    
  my $main_sizer   = Wx::BoxSizer->new( wxVERTICAL );
  $main_sizer->Add( $tree->GetTree,  0, wxTOP, 0 );
  
  # in a subroutine
  print $tree->GetSelectedPath;

=head1 DESCRIPTION

Many widgets that display directory trees are dialogs or can't handle drives on
Windows. This module aims to fill the gap. It can be integrated in any frame or
dialog and it handles drives under Windows.

=head1 METHODS

=head2 GetSelectedPath

  $tree->GetSelectedPath

This method returns the path of the item that is selected.

=head2 GetTree

  $tree->GetTree

This is just a convenience method that wraps the GetTree method
of Wx::Perl::VirtualTree.

=head2 new

Creates a new object

  my $tree  = Wx::Perl::DirTree->new( $panel, [100,100] );
  
  my $tree2  = Wx::Perl::DirTree->new( 
      $panel, 
      [100,100],
      {
          dir => $path_to_dir,
      }
  );
  
  my $tree2  = Wx::Perl::DirTree->new( 
      $panel, 
      [100,100],
      {
          dir     => $path_to_dir,
          is_root => 1,
      }
  );

Parameters:

=over 4

=item 1 $parent

A parent widget.

=item 2 $size

The size of the tree widget. This has to be an array reference.

=item 3 $hashref

In this hash reference you can specifiy more parameters:

=over 4

=item * dir

If you want to "open" a specific directory, you can specify "dir"

=item * is_root

If set to a true value, the dir tree starts at the specified directory. If you
want to provide a directory tree that shows only the directories below the
home directory of a user you can do this:

  Wx::Perl::DirTree->new(
    $panel,
    $size,
    {
        dir => File::HomeDir->my_home,
        is_root => 1,
    }
  );

=item * allowed

With that option you can specify whether only directories or only files can
be selected. If this option is ommitted, both types can be selected.

  use Wx::Perl::DirTree qw(:const); # loads two constants
  
  my $tree = Wx::Perl::DirTree->new(
    $panel,
    $size,
    {
        dir => File::HomeDir->my_home,
        allowed => wxPDT_DIR, # only directories can be selected
    }
  );

=back

=back

See also the scripts in the example dir.

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

# ABSTRACT: A directory tree widget for wxPerl

