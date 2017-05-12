package WxPerl::MenuMaker;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Wx ();
use Wx::Event ();

=head1 NAME

WxPerl::MenuMaker - create and manage linked menus and toolbars

=head1 SYNOPSIS

This is not a wxMenu, only a way to hold and manage named references to
the menu items and toolbar items.

  my $mm = WxPerl::MenuMaker->new(
    handler => $self,
    nomethod => sub {warn "$_[1] cannot '$_[0]()'"},
  );

  $mm->create_menubar(\@menu);
  # the toolbar takes a few more parameters
  $mm->create_toolbar(\@toolbar,
    parent => $frame, # all you really need
    id => -1,
    position => wxDefaultPosition,
    size => wxDefaultSize,
    style => wxTB_HORIZONTAL|wxTB_FLAT|wxTB_DOCKABLE,
    bitmap_size => [32, 32],
  );

  # and you can get them back
  my $menu = $mm->menubar;
  my $menu_item = $mm->menu_items->file_open;
  my $toolbar = $mm->toolbar;
  my $toolbar_item = $mm->toolbar_items->that_button;

  # and
  my $associate = $mm->associated_menu->that_button;

=cut

=head1 Constructor

=head2 new

  my $mm = WxPerl::MenuMaker->new(
    handler => $self,
    nomethod => sub {warn "$_[1] cannot '$_[0]()'"},
  );

=cut

sub new {
  my $class = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;
  ref($class) and croak("not an object method");

  my $self = {%args};
  # create the classes
  my $class_base = "$self";
  $class_base =~ s/HASH\(([^\)]*)\)/${class}::$1/ or
    croak("cannot transform $self into a package");
  my $newclass_isa = do { no strict 'refs'; \@{"${class_base}::ISA"}; };
  push(@$newclass_isa, $class); # You're one of us now...

  my @classes = qw(
    menu_items
    toolbar_items
    toolbar_meta
    associated_tool
    associated_menu
    );
  foreach my $attrib (@classes) {
    my $new_class = $class_base . '::' . $attrib;
    my $obj = {};
    bless($obj, $new_class);
    $class->_mk_accessor($class_base, $attrib, $obj);
  }

  bless($self, $class_base);
  return($self);
} # end subroutine new definition
########################################################################
  sub handler {$_[0]->{handler}};
  sub nomethod {$_[0]->{nomethod}};

=head2 create_menubar

Should typically be called before create_toolbar().

  my @menu = (
    {
      name  => 'file',
      menu  => [...], # see create_menu()
      label => '&File',
    }
  );
  $mm->create_menubar(\@menu);

In the above example, the submenu [...] will have its entries prefixed
by C<file_>.  Thus, you will be able to access the C<open> submenu item
via C<$mm-E<gt>menu_items-E<gt>file_open>.

=cut

sub create_menubar {
  my $self = shift;
  my $mmap = shift(@_) or croak('requires menu argument');
  (ref($mmap || '') eq 'ARRAY') or croak("requires an array reference");

  my $menubar = Wx::MenuBar->new();
  $self->_mk_accessor($self, 'menubar', $menubar);
  # now walk through that
  for(my $i = 0; $i < @$mmap; $i++) {
    my $item = $mmap->[$i];
    my $name = $self->_name_check($item->{name}) or
      croak("menubar item $i has no name");
    my $submenu = $item->{menu} or croak("item $i has no submenu");
    my $menu = $self->create_menu($submenu, prefix => $name . '_');

    # XXX not sure I like this bit of storing toplevel (menubar) entries
    # in with all of the menu items, but if file_open is in file, it
    # sort of makes sense
    $self->_mk_accessor($self->menu_items, $name, $menu);
    $menubar->Append($menu, $item->{label});
  }
  if(my $handler = $self->handler) {
    $handler->SetMenuBar($menubar);
  }
  return($menubar);
} # end subroutine create_menubar definition
########################################################################

=head2 create_menu

This is called for you by create_menubar().

Using this for standalone menus is untested.

  my @menu = (
    {
      name        => 'open',
      action      => 'file_open',
      label       => '&Open
    },
    {
      separator   => 1
    },
    {
      auto_action => 1,
      name        => 'quit',
      label       => 'Quit'
    }
  );
  my $menu = $mm->create_menu(\@menu, prefix => 'file_');

The hash reference items in the array are treated as follows:

=over

=item separator

Set the C<separator> property to true to get a separator.

=item action

If C<action> is defined, the event will be connected to a
menu_C<action>() method.

=item auto_action

If C<auto_action> is not present and false, your menu events will be
connected to 'menu_' . $name (where $name starts with the prefix.)

=back

In the above example, the resultant events are menu_file_open() and
menu_file_quit().

=cut

sub create_menu {
  my $self = shift;
  my $mmap = shift(@_) or croak('requires menu argument');
  (ref($mmap || '') eq 'ARRAY') or croak("requires an array reference");
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;

  my $menu = Wx::Menu->new();
  # now walk through that
  for(my $i = 0; $i < @$mmap; $i++) {
    my $item = $mmap->[$i];
    if($item->{separator}) {
      $menu->AppendSeparator;
      next;
    }
    my $name = $self->_name_check($item->{name}) or
      croak("menu item $i has no name");
    $name = $args{prefix} . $name if($args{prefix});
    my $menu_item;
    if(my $array = $item->{menu}) {
      #warn "create submenu for $name\n";
      my $submenu = $self->create_menu($array , prefix => $name . '_');
      #warn "got submenu $submenu $item->{label}";
      $menu_item = $menu->Append(
        Wx::NewId(), $item->{label}, $submenu, ''
      );
    }
    else {
      my $label = $item->{label};
      $label =~ s/\\t/\t/; # allow visible tabs
      $menu_item = $menu->Append(Wx::NewId(), $label, '');
      $self->_mk_event($item, $name, $menu_item);
    }
    $self->_mk_accessor($self->menu_items, $name, $menu_item);
  }
  return($menu);
} # end subroutine create_menu definition
########################################################################

=head2 _name_check

  $name = $self->_name_check($item->{name});

=cut

sub _name_check {
  my $self = shift;
  my ($name) = @_;
  $name or return;
  ($name =~ m/^\w+$/ and $name !~ m/^\d/) or
    croak("'$name' is invalid");
  return($name);
} # end subroutine _name_check definition
########################################################################

=head2 create_toolbar

  my @toolbar = (
    {
      tooltip     => 'File Manager',
      icon        => 'file-manager.png',
      auto_action => 0,
      name        => 'file_manager'
    },
    {
      tooltip     => 'Notes',
      icon        => 'tb_button_notes.png',
      name        => 'notes'
    },
    {
      separator => '1'
    },
    {
      tooltip     => 'Open File',
      icon        => 'kedit.png',
      associate   => 'file_open',
      name        => 'file_open'
    },
    {
      tooltip     => 'Browse',
      icon        => 'tb_button_browse.png',
      action      => 'do_something',
      name        => 'browse'
    },
    {
      tooltip     => 'Foo',
      icon        => 'tb_button_foo.png',
      action      => sub {warn "this is foo"},
      name        => 'foo'
    }
  );

  $mm->create_toolbar(\@toolbar,
    parent      => $frame, # all you really need
    id          => -1,
    position    => wxDefaultPosition,
    size        => wxDefaultSize,
    style       => wxTB_HORIZONTAL|wxTB_FLAT|wxTB_DOCKABLE,
    bitmap_size => [32, 32],
  );

If you set a handler in the constructor, you will not need to pass the
parent argument to this method.

The toolbar items are connected much like in create_menu(), except that
the default method is menu_tb_C<name>().

The C<associate> property will cause the tool to be associated to that
menu entry.  This means they will have the same ID (and thus the same
events.)

=cut

sub create_toolbar {
  my $self = shift;
  my $tb = shift(@_) or croak('requires menu argument');
  (ref($tb || '') eq 'ARRAY') or croak("requires an array reference");
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;
  my $parent = $args{parent} || $self->{handler};
  $parent or croak('must have parent argument');
  $self->{handler} ||= $parent;
  my $size = $args{size} || [32, 32];

  my $toolbar = Wx::ToolBar->new($parent,
    -1,
    exists($args{position}) ? $args{position} : Wx::wxDefaultPosition(),
    exists($args{size}) ? $args{size} : Wx::wxDefaultSize(),
    exists($args{style}) ? $args{style} :
      Wx::wxTB_HORIZONTAL()|Wx::wxTB_FLAT()
  );

  # create the closure for it
  $self->_mk_accessor($self, 'toolbar', $toolbar);

  # run down the list
  for(my $i = 0; $i < @$tb; $i++) {
    my $item = $tb->[$i];
    $self->_add_toolbar_item(%$item, _num => $i);
  }

	$parent->SetToolBar($toolbar);
  $toolbar->SetToolBitmapSize(Wx::wxSIZE(@$size));
  $toolbar->Realize();
  return($toolbar);
} # end subroutine create_toolbar definition
########################################################################

=head2 append_toolbar

  $mm->append_toolbar(%args);

=cut

sub append_toolbar {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%args) = @_;

  $self->_add_toolbar_item(separator => 1);
  my $item = $self->_add_toolbar_item(%args);
  $self->toolbar->Realize;
  return($item);
} # end subroutine append_toolbar definition
########################################################################

=head2 _add_toolbar_item

  my $tool = $self->_add_toolbar_item(%args);

=cut

sub _add_toolbar_item {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my (%item) = @_;

  my $toolbar = $self->toolbar;

  if($item{separator}) {
    return($toolbar->AddSeparator());
  }

  defined(my $name = $item{name}) or croak("item ",
    (exists($item{_num}) ? "($item{_num})" : ''), " must have a name");
  #warn "adding $name with $item{icon}";
  my $id = -1;
  my $associate = $item{associate};
  if($associate) {
    my $assoc = $self->menu_items->$associate;
    $id = $assoc->GetId;
  }

  (-e $item{icon}) or
    croak("missing icon '$item{icon}' for toolbar item '$name'");
  my $tool = $toolbar->AddTool($id, $name,
    Wx::Bitmap->new($item{icon}, Wx::wxBITMAP_TYPE_ANY()),
    (defined($item{alt_icon}) ?
      Wx::Bitmap->new($item{alt_icon}, Wx::wxBITMAP_TYPE_ANY()) :
      Wx::wxNullBitmap()
    ),
    Wx::wxITEM_NORMAL(), # TODO style
    $item{tooltip},
    (defined($item{longhelp}) ? $item{longhelp} : ''),
  );
  $self->_mk_accessor($self->toolbar_items, $name, $tool);

  if($associate) { # association *by name only*
    $self->_mk_accessor($self->associated_menu, $name, $associate);
    $self->_mk_accessor($self->associated_tool, $associate, $name);
  }
  else { # set the event
    $self->_mk_event(\%item, 'tb_' . $name, $tool->GetId);
  }
  return($tool);
} # end subroutine _add_toolbar_item definition
########################################################################

=head2 _mk_accessor

  $class->_mk_accessor($package, $method, $value);

=cut

sub _mk_accessor {
  my $self = shift;
  my ($package, $method, $value) = @_;
  my $class = ref($package) || $package;
  no strict 'refs';
  *{$class . '::' . $method} = sub {$value};
} # end subroutine _mk_accessor definition
########################################################################

=head2 _mk_event

  $self->_mk_event($item, $name, $menu_item);

=cut

sub _mk_event {
  my $self = shift;
  my ($item, $name, $menu) = @_;

  my $dbg = 0;

  my $handler = $self->handler or return;
  my $auto = (exists($item->{auto_action}) ? $item->{auto_action} : 1);
  $auto = 0 if(defined($item->{action}));
  if(my $action = ($auto ? $name : $item->{action})) {
    my $subref;
    if(ref($action) || '' eq 'CODE') {
      $subref = $action;
    }
    else {
      $action = 'menu_' . $action;
      $dbg and warn "connect $action to $name for $menu";
      unless($handler->can($action)) {
        $dbg and warn "cannot";
        if(my $sub = $self->nomethod) {
          $dbg and warn "nomethod";
          Wx::Event::EVT_MENU(
            $handler, $menu, sub {$sub->($action, @_)}
          );
        }
        return;
      }
      $subref = sub {$_[0]->$action($_[1])};
      $dbg and warn "can";
    }
    Wx::Event::EVT_MENU($handler, $menu, $subref);
  }
  return;
} # end subroutine _mk_event definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
