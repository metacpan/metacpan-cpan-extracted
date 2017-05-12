package WxPerl::MenuMap;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


=head1 NAME

WxPerl::MenuMap - An object to introspect a Wx::Menu

=head1 ABOUT

This package creates an object with read-only accessors for mapping the
menu's items to IDs.

It is still highly experimental.

=head1 SYNOPSIS

  use WxPerl::MenuMap;
  ...
  my $menu = WxPerl::MenuMap->new($menu_object);
  EVT_MENU($self, $menu->file_open, sub {$_[0]->blah($_[1])});

=cut

=head2 new

  my $menu = WxPerl::MenuMap->new($menu_object);

=cut

sub new {
  my $class = shift;
  my $menu = shift(@_) or croak('requires menu argument');
  (@_ % 2) and croak('odd number of elements in argument hash');
  my (%args) = @_;
  ref($class) and croak("not an object method");

  # create the class
  my $newclass = "$menu";
  $newclass =~ s/.*=SCALAR\(([^\)]*)\)/${class}::$1/ or
    croak("cannot transform $menu into a package");
  my $newclass_isa = do { no strict 'refs'; \@{"${newclass}::ISA"}; };
  push(@$newclass_isa, $class); # You're one of us now...

  my $self = {menu => $menu};
  bless($self, $newclass);
  $self->_init;
  return($self);
} # end subroutine new definition
########################################################################

=head2 _init

  $self->_init;

=cut

sub _init {
  my $self = shift;
  my $menu = $self->{menu};

  my $package = ref($self);

  my %map = _map_menubar($menu);
  $self->{_map} = \%map;
  foreach my $entry (keys(%map)) {
    #warn "hookup $entry";
    my $number = $map{$entry};
    no strict 'refs';
    *{$package . '::' . $entry} = eval("sub {$number}");
  }

} # end subroutine _init definition
########################################################################

=head2 _map_menubar

  my %map = _map_menubar($menu);

=cut

sub _map_menubar {
  my ($menubar) = @_;

  my %map;
  for(my $i = 0; $i < $menubar->GetMenuCount; $i++) {
    my $menu = $menubar->GetMenu($i);
    my $label = _prep($menubar->GetLabelTop($i));
    #warn "got $label -> $menu";
    my %subm = _map_menu($menu);
    foreach my $key (keys(%subm)) {
      my $path = $label . '_' . $key;
      $map{$path} = $subm{$key};
      #warn "now $path";
    }
  }
  return(%map);
} # end subroutine _map_menubar definition
########################################################################

=head2 _map_menu

  my %map = _map_menu($menu);

=cut

sub _map_menu {
  my ($menu) = @_;

  my %map;
  foreach my $item ($menu->GetMenuItems) {
    next if($item->IsSeparator);
    my $label = _prep($item->GetLabel);
    #warn "item: $item ($label)";
    $map{$label} = $item->GetId;
    my $submenu = $item->GetSubMenu or next;
    my %submap = _map_menu($submenu);
    foreach my $key (keys(%submap)) {
      my $path = $label . '_' . $key;
      $map{$path} = $submap{$key};
    }
  }
  return(%map);
} # end subroutine _map_menu definition
########################################################################

=head2 _prep

  my $label = _prep($menulabel);

=cut

sub _prep {
  my ($label) = @_;
  $label = lc($label);
  $label =~ s/[^\w]/_/g;
  $label =~ s/^(\d)/_$1/;
  return($label);
} # end subroutine _prep definition
########################################################################

=head2 items

  my @list = $menu->items;

=cut

sub items {
  my $self = shift;

  return(keys(%{$self->{_map}}));
} # end subroutine items definition
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
