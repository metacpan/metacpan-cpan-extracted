package dtRdr::Callbacks::Book;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use Class::Accessor::Classy;
rw 'aggregated';
no  Class::Accessor::Classy;

=begin TODO

o arrays -- probably add_foo_sub() appends and set_foo_sub() smashes

o html head / css stuff

=end TODO

=head1 NAME

dtRdr::Callbacks::Book - the callbacks object for books

=head1 SYNOPSIS

Just using the module will typically do everything you need.

  use dtRdr::Callbacks::Book;

This installs callback() and get_callbacks() methods in your class.  The
callback() method is for adding to your class's callbacks.

  YourClass->callback->set_foo_sub(sub {...});

The get_callbacks() methods aggregates your classes callbacks with your
base class.  If your plugin has no specific callbacks, you can just
inherit it, but this is not recommended.

To run the 'foo' callback (which will either be specific to your class,
your base class, or else the default), just:

  YourClass->get_callbacks->foo($args);

Alternatively, the standalone usage: 

  use dtRdr::Callbacks::Book (); # suppress import()
  my $callbacks = dtRdr::Callbacks::Book->new();
  $callbacks->set_core_link_sub(sub {"foo://" . $_[0]});

  # later ...

  my $link = $callback->core_link($book, 'dr_note_link.png');

=cut

my %defaults; # holds default subs for undeclared stuff

=head2 new

  my $callbacks = dtRdr::Callbacks::Book->new();

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 aggregate

Overwrites each property (from right to left) and returns an aggregated
callback object.  List types are appended rather than overwritten.

  my $all_callbacks = $callback->aggregate($and1, $and2, $and3);

=cut

sub aggregate {
  my $self = shift;
  my @others = @_;
  my @list = (reverse(@others), $self);
  my @keys = do {
    my %all = map({$_ => 1} grep(/_sub$/, map({keys(%$_)} @list)));
    keys(%all);
  };
  my $aggregated = $self->new;
  foreach my $key (@keys) {
    foreach my $item (@list) {
      next unless(exists($item->{$key}));
      my $ref = $item->{$key};
      $ref or next;
      # subrefs just smash, but arrays need to accumulate
      if(ref($ref) eq 'ARRAY') {
        # careful not to grow any existing references
        my $current = $aggregated->{$key} || [];
        $ref = [@$current, @$ref];
      }
      $aggregated->{$key} = $ref;
    }
  }
  $aggregated->{aggregated} = 1;
  return($aggregated);
} # end subroutine aggregate definition
########################################################################

=head1 Callbacks

The documentation for each callback here should also serve as your
custom callback's prototype.

=head2 XML things

=head3 core_link

Create a uri to a core file (such as an icon.)  The default is to
prepend 'dr://CORE/'.

  my $link = $callbacks->core_link($item);

=cut

$defaults{core_link} = sub {
  my ($item) = @_;
  return('dr://CORE/' . $item);
};
########################################################################

=head3 img_src_rewrite

Rewrites the img tag's src uri (such as into a base-64 encoded form.)
The default just parrots the $uri with which it was called.

  $uri = $callbacks->img_src_rewrite($uri, $book);

=cut

$defaults{img_src_rewrite} = sub {
  my ($src, $book) = @_;
  return($src);
};
########################################################################

=head2 Annotation Events

=head3 annotation_created

  $callbacks->annotation_created($anno);

=cut

$defaults{annotation_created} = undef;
########################################################################

=head3 annotation_changed

  $callbacks->annotation_changed($anno);

=cut

$defaults{annotation_changed} = undef;
########################################################################

=head3 annotation_deleted

  $callbacks->annotation_deleted($anno);

=cut

$defaults{annotation_deleted} = undef;
########################################################################

########################################################################
# DO NOT ATTEMPT TO DEFINE ANY DEFAULTS BELOW HERE
########################################################################

########################################################################
# build and install them and their accessors
foreach my $key (keys(%defaults)) {
  __PACKAGE__->define($key, $defaults{$key});
}
########################################################################

=head1 Meta

These methods let you add to the callback object, though it is best to
define the methods in this package as above.

=head2 define

Define a callback and the default subref.

  dtRdr::Callbacks::Book->define('name', sub {...});

For multi-entry callbacks, the second argument is a (possibly empty)
array reference.

=cut

sub define {
  my $package = shift;
  my ($title, $def_subref) = @_;
  my $subname = $title . '_sub';
  my $installer = sub {
    my ($name, $sub) = @_;
    no strict 'refs';
    *{$package . '::' . $name} = $sub;
  };
  if(ref($def_subref) eq 'ARRAY') {
    die "not here yet";
    # $subname .= 's';
    # also, define the append_foo_subs($sub1, $sub2, $sub3); method
  }
  elsif((not defined($def_subref)) or (ref($def_subref) eq 'CODE')) {
    use Class::Accessor::Classy;
    rw $subname;
    no  Class::Accessor::Classy;
    my $getter = 'get_' . $subname;
    my $setter = 'set_' . $subname;
    my $setsub = sub {
      my $self = shift;
      my ($subref) = @_;
      $self->aggregated
        and croak("cannot set on an aggregated callback object");
      $self->$getter() and
        croak("attempt to redefine '$title' callback");
      my $super_setter = 'SUPER::' . $setter;
      $self->$super_setter($subref);
    }; # setsub
    $installer->($setter, $setsub);
    # no need for a getsub here
    my $dosub = sub {
      my $self = shift;
      my $subref = $self->$getter || $def_subref;
      $subref or return;
      return($subref->(@_));
    };
    $installer->($title, $dosub);
  }
  else {
    croak("unsupported reference type '$def_subref'");
  }
} # end subroutine define definition
########################################################################


=head2 has

Returns true if some method (other than the default) has been installed
under $name.  For multi-sub callbacks, returns true if one or more is
installed (whether it is the default or not.)

  $callbacks->has($name);

=cut

sub has {
  my $self = shift;
  my ($name) = @_;
  my $look = $name . '_sub';
  return(defined($self->$look)) if($self->can($look));
  # or it is plural
  $look .= 's';
  $self->can($look) or
    croak("'$name' is not a defined callback title");
  my $list = $self->$look || [];
  return(scalar(@$list) > 0);
} # end subroutine has definition
########################################################################

=head2 import

Calls install_in() on your current package.

  use dtRdr::Callbacks::Book;

=cut

sub import {
  my $package = shift;
  my $caller = caller();
  $package->install_in($caller);
} # end subroutine import definition
########################################################################

=head2 install_in

  dtRdr::Callbacks::Book->install_in($class);

=cut

sub install_in {
  my $package = shift;
  my ($dest_class) = @_;

  {
    no strict 'refs';
    if(defined(&{$dest_class . '::get_callbacks'})) {
      # XXX now what?
      # I guess, do nothing IFF they have both.
      defined(&{$dest_class . 'callback'}) or
        croak(
          "cannot install in '$dest_class' because ",
          "get_callbacks() is defined, but missing callback() is ",
          "going to break everything"
        );
      return;
    }
  }
  my $object = $package->new;

  my $get_callbacks = sub {
    my $class = shift;
    my $class_isa = do { no strict 'refs'; \@{"${class}::ISA"}; };
    my @callback_objs;
    my %no_dupes;
    foreach my $base (@$class_isa) {
      # We'll get a duplicate if we're just inheriting the base class's
      # get_callbacks method, so we get the subref and compare.
      if(my $check = $base->can('get_callbacks')) {
        # XXX I don't know what this does in a diamond, maybe NEXT.pm?
        # but we only go one deep because get_callbacks goes the next
        # level deep
        $no_dupes{$check} and next;
        $no_dupes{$check} = 1;
        my $obj = $base->get_callbacks;
        push(@callback_objs, $obj);
      }
    }
    return($object->aggregate(@callback_objs));
  }; # end $get_callbacks closure def
  {
    no strict 'refs';
    # install the aggregator
    *{$dest_class . '::get_callbacks'} = $get_callbacks;
    # and the accessor
    *{$dest_class . '::callback'} = sub {$object};
  }
} # end subroutine install_in definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
