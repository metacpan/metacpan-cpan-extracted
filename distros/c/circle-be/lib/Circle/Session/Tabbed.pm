#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2014 -- leonerd@leonerd.org.uk

package Circle::Session::Tabbed;

use strict;
use base qw( Tangence::Object Circle::Commandable Circle::Configurable );
use Carp;

sub _session_type
{
   my ( $opts ) = @_;

   keys %$opts or return __PACKAGE__;

   print STDERR "Need Tabbed FE session for extra options:\n";
   print STDERR "  ".join( "|", sort keys %$opts )."\n";

   return undef;
}

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{root} = $args{root};
   $self->{identity} = $args{identity};

   # Start with just the root object in first tab

   $self->set_prop_tabs( [ $args{root} ] );
   $self->{items} = {};

   return $self;
}

sub items
{
   my $self = shift;
   return @{ $self->get_prop_tabs };
}

sub describe
{
   my $self = shift;
   return __PACKAGE__."[$self->{identity}]";
}

sub _item_to_index
{
   my $self = shift;
   my ( $item ) = @_;

   my @items = $self->items;
   $items[$_] == $item and return $_ for 0 .. $#items;

   return undef;
}

sub show_item
{
   my $self = shift;
   my ( $item ) = @_;

   return if grep { $_ == $item } $self->items;

   $self->push_prop_tabs( $item );
}

sub unshow_item
{
   my $self = shift;
   my ( $item ) = @_;

   my $index;
   if( ref $item ) {
      $index = $self->_item_to_index( $item );
      return unless defined $index;
   }
   else {
      $index = $item;
   }

   $self->splice_prop_tabs( $index, 1, () );
}

sub new_item
{
   my $self = shift;
   my ( $item ) = @_;

   # Did we know about it?
   return if exists $self->{items}->{$item};

   $self->{items}->{$item} = 1;
   $self->show_item( $item );
}

sub delete_item
{
   my $self = shift;
   my ( $item ) = @_;

   delete $self->{items}->{$item};
   $self->unshow_item( $item );
}

sub clonefrom
{
   my $self = shift;
   my ( $src ) = @_;

   my @srcitems = $src->items;

   foreach my $index ( 0 .. $#srcitems ) {
      my $item = $srcitems[$index];

      my $curindex = $self->_item_to_index( $item );
      if( !defined $curindex ) {
         $self->splice_prop_tabs( $index, 0, $item );
      }
      elsif( $curindex != $index ) {
         $self->move_prop_tabs( $curindex, $index - $curindex );
      }
   }

   $self->splice_prop_tabs( scalar @srcitems, scalar $self->items - scalar @srcitems, () );
}

sub _get_item
{
   my $self = shift;
   my ( $path, $curitem, $create ) = @_;

   $curitem or $path =~ m{^/} or croak "Cannot walk a relative path without a start item";

   $curitem = $self->{root} if $path =~ s{^/}{};

   foreach ( split( m{/}, $path ) ) {
      next unless length $_; # skip empty path elements

      my $nextitem;
      if( $curitem->can( "get_item" ) ) {
         $nextitem = $curitem->get_item( $_, $create );
      }
      elsif( $curitem->can( "enumerate_items" ) ) {
         $nextitem = $curitem->enumerate_items->{$_};
      }
      else {
         die "@{[ $curitem->describe ]} has no child items\n";
      }

      defined $nextitem or die "@{[ $curitem->describe ]} has no child item called $_\n";

      $curitem = $nextitem;
   }

   return $curitem;
}

sub _cat_path
{
   my ( $p, $q ) = @_;

   return $q if $p eq "";
   return "/$q" if $p eq "/";
   return "$p/$q";
}

sub load_configuration
{
   my $self = shift;
   my ( $ynode ) = @_;

   $self->set_prop_tabs( [] );

   foreach my $tab ( @{ $ynode->{tabs} } ) {
      my $item = $self->_get_item( $tab, $self->{root}, 1 );
      $self->push_prop_tabs( $item );
   }
}

sub store_configuration
{
   my $self = shift;
   my ( $ynode ) = @_;

   $ynode->{tabs} = [ map {
      my $item = $_;
      my @components;
      while( $item ) {
         unshift @components, $item->enumerable_name;
         $item = $item->parent;
      }
      join "/", @components;
   } $self->items ];
}

sub command_list
   : Command_description("List showable window items")
   : Command_arg('path?')
   : Command_opt('all=+', desc => "list all the items")
{
   my $self = shift;
   my ( $itempath, $opts, $cinv ) = @_;

   my @items;
   
   if( $opts->{all} ) {
      @items = ( [ "/" => $self->{root} ] );
   }
   else {
      @items = ( [ "" => $cinv->invocant ] );
   }

   if( defined $itempath ) {
      if( $itempath =~ m{^/} ) {
         $items[0]->[0] = $itempath;
      }
      else {
         $items[0]->[0] .= $itempath;
      }
      $items[0]->[1] = $self->_get_item( $itempath, $items[0]->[1] );
   }

   $cinv->respond( "The following items exist" . ( defined $itempath ? " from path $itempath" : "" ) );

   # Walk a tree without using a recursive function
   my @table;
   while( my $i = pop @items ) {
      my ( $name, $item ) = @$i;

      push @table, [ "  $name", ref($item) ] if length $name;

      if( my $subitems = $item->can( "enumerate_items" ) && $item->enumerate_items ) {
         push @items, [ _cat_path( $name, $_ ) => $subitems->{$_} ] for reverse sort keys %$subitems;
      }
   }

   $cinv->respond_table( \@table, colsep => " - " );

   return;
}

sub command_show
   : Command_description("Show a window item")
   : Command_arg("path?")
   : Command_opt("all=+", desc => "show all the non-visible items")
{
   my $self = shift;
   my ( $itempath, $opts, $cinv ) = @_;

   my @items;
   if( $opts->{all} ) {
      my %visible = map { $_ => 1 } $self->items;

      my @more = ( $self->{root} );
      while( my $item = pop @more ) {
         push @items, $item if !$visible{$item};

         if( my $subitems = $item->can( "enumerate_items" ) && $item->enumerate_items ) {
            push @more, @{$subitems}{sort keys %$subitems};
         }
      }
   }
   elsif( defined $itempath ) {
      @items = $self->_get_item( $itempath, $cinv->invocant );
   }
   else {
      $cinv->responderr( "show: require PATH or -all" );
      return;
   }

   $self->show_item( $_ ) for @items;

   return;
}

sub command_hide
   : Command_description("Hide a window item")
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $item = $cinv->invocant;

   if( $item->isa( "Circle::RootObj" ) ) {
      $cinv->responderr( "Cannot hide the global tab" );
      return;
   }

   $self->unshow_item( $item );

   return;
}

sub command_tab
   : Command_description("Manipulate window item tabs")
{
}

sub command_tab_move
   : Command_description("Move the tab to elsewhere in the window ordering\n".
                         "POSITION may be an absolute number starting from 1,\n".
                         "                a relative number with a leading + or -,\n".
                         "                one of  first | left | right | last")
   : Command_subof('tab')
   : Command_arg('position')
{
   my $self = shift;
   my ( $position, $cinv ) = @_;

   my $tabs = $self->get_prop_tabs;

   my $item = $cinv->invocant;

   my $index;
   $tabs->[$_] eq $item and ( $index = $_, last ) for 0 .. $#$tabs;

   defined $index or return $cinv->responderr( "Cannot find current index of item" );

   $position = "+1"   if $position eq "right";
   $position = "-1"   if $position eq "left";
   $position = "1"    if $position eq "first"; # 1-based
   $position = @$tabs if $position eq "last";  # 1-based

   my $delta;
   if( $position =~ m/^[+-]/ ) {
      # relative
      $delta = $position+0;
   }
   elsif( $position =~ m/^\d+$/ ) {
      # absolute; but input from user was 1-based.
      $position -= 1;
      $delta = $position - $index;
   }
   else {
      return $cinv->responderr( "Unrecognised position/movement specification: $position" );
   }

   return $cinv->responderr( "Cannot move that far left"  ) if $index + $delta < 0;
   return $cinv->responderr( "Cannot move that far right" ) if $index + $delta > $#$tabs;

   $self->move_prop_tabs( $index, $delta );
   return;
}

sub command_tab_goto
   : Command_description("Activate a numbered tab\n".
                         "POSITION may be an absolute number starting from 1,\n".
                         "                a relative number with a leading + or -,\n".
                         "                one of  first | left | right | last")
   : Command_subof('tab')
   : Command_arg('position')
{
   my $self = shift;
   my ( $position, $cinv ) = @_;

   my $tabs = $self->get_prop_tabs;

   my $item = $cinv->invocant;

   my $index;
   $tabs->[$_] eq $item and ( $index = $_, last ) for 0 .. $#$tabs;

   defined $index or return $cinv->responderr( "Cannot find current index of item" );

   $position = "+1"   if $position eq "right";
   $position = "-1"   if $position eq "left";
   $position = "1"    if $position eq "first"; # 1-based
   $position = @$tabs if $position eq "last";  # 1-based

   if( $position =~ m/^[+-]/ ) {
      # relative
      $index += $position;
   }
   elsif( $position =~ m/^\d+$/ ) {
      # absolute; but input from user was 1-based.
      $index = $position - 1;
   }
   else {
      return $cinv->responderr( "Unrecognised position/movement specification: $position" );
   }

   $self->get_prop_tabs->[$index]->fire_event( raise => () );
   return;
}

0x55AA;
