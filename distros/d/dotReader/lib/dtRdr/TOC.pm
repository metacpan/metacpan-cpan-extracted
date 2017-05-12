package dtRdr::TOC;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use Carp;

use Class::Accessor::Classy;
ro(qw(
  id
  range
  info
));
rw(qw(
  title
  visible
  copy_ok
  word_start
  word_end
));
rs book   => \(my $set_book);
rs parent => \(my $set_parent);
no  Class::Accessor::Classy;
########################################################################

use dtRdr::Logger;

=head1 NAME

dtRdr::TOC - a linked Table of Contents tree

=head1 SYNOPSIS

This pod needs work.

=cut

=head1 Constructor

=head2 new

Create a new TOC item.

  my $toc = dtRdr::TOC->new( $book, $id, $range,
    {
      title   => $title,
      visible => 1|0,
      info => {
        my_thing => $foo,
      }
    },
    );

where

C<book> is the book object for this TOC entry,

C<id> is a unique identifier within this tree,

C<range> is a dtRdr::Range object that represents the text to which this
TOC entry refers,

C<title> is the display title for the TOC entry,

C<info =E<gt> {foo =E<gt> 'bar'}> is some information for your own later
reference.

and

A final, optional argument C<parent> is the parent TOC item for this
item.  You should typically not need the parent argument.  See
create_child() for why.

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;

  # break old api: (@_ >= 3 and (ref($_[3]) ne 'HASH')) and croak "wrong api";
  (@_ >= 1) or croak("not enough arguments to new()");

  my ($book, $id, $range, $arg_ref, $parent) = @_;
  # must have at least a book to be valid
  eval {$book->isa('dtRdr::Book')} or
    croak("$book is not a dtRdr::Book object");

  (defined($arg_ref) and ref($arg_ref ne 'HASH')) and
    croak "options ref must be a hash";

  my %args = ($arg_ref ? %$arg_ref : ());
  my $info = delete($args{info}) || {};

  { # validate harshly for now
    my %toplevel_args = map({$_ => 1} qw(
      title
      visible
      copy_ok
      ));
    my @extra_keys = grep({not exists($toplevel_args{$_})} keys(%args));
    @extra_keys and croak('items: ', join(", ", map({"'$_'"} @extra_keys)),
      " are not valid top-level arguments"
      );
  }

  defined($id) or croak("must have an id");

  my $self = {
    book => $book,
    range => $range,
    info => $info,
    parent => $parent,
    # children => [],
    id => $id,
    visible => 1,
    %args
  };

  bless($self, $class);
  if($parent) {
    my $root = $self->{_root} = $parent->root || $parent;
    $root->_add_to_index($self);
  }
  else {
    $self->{_index} = {
      id => {$id => $self},
    };
  }
  return($self);
} # end subroutine new definition
########################################################################

=head2 create_child

  my $child = $toc->create_child($id, $range, \%info);

=cut

sub create_child {
  my $self = shift;
  my ($id, $range, $info) = @_;
  $info ||= {};

  my $child = $self->new($self->get_book, $id, $range, $info, $self);
  $self->add_child($child);
  return($child);
} # end subroutine create_child definition
########################################################################


# TODO

=head1 TODO

And maybe something in Range -- see Metadata.pm's feature envy

my ($node, $bytes) = $toc->node_before_location($loc);

foreach my $node (@toc) {
  if($start < $loc and $loc < $stop) {
    last;
  }
}

=cut

=head1 Accessors

All accessors are foo() and set_foo().  get_foo() is an alias to foo().

=head2 id

Returns the ID for this TOC object

  my $id = $toc->id;

=cut

=head2 book

Returns something representing the book object (maybe just an identifier
for it) for this TOC object.

TREATING THE RESULT AS A BOOK MAY BREAK YOUR CODE!

  my $bookid = $toc->book;

=cut

=head2 range

Returns the range object for this TOC object

  my $range = $toc->range;

=cut

=head2 get_title

returns the title for this TOC node

  $toc->title

=cut

=head2 get_visible

  $toc->visible and print "visible!\n";

Returns true or false indicating whether the TOC item should be
displayed in the TOC widget.

=cut

########################################################################

=head1 Tree Operations

=head2 children

Returns all the child TOC objects for this TOC object. Returns the
empty list if there are none.

  my @children = $toc->children;

=cut

sub children {
  my $self = shift;
  $self->{children} and return(@{$self->{children}});
  return();
} # end subroutine children definition
########################################################################

=head2 descendants

Recursive children

  my @descendants = $toc->descendants;

=cut

sub descendants {
  my $self = shift;

  my @desc;
  $self->_rmap(sub {
    my $node = shift;
    push(@desc, $node->children);
  });
  return(@desc);
} # end subroutine descendants definition
########################################################################

=head2 older_siblings

Nodes before this, at the same level.

  $toc->older_siblings;

=cut

sub older_siblings {
  my $self = shift;

  $self->is_root and return();
  my @siblings = $self->parent->children;

  while(my $s = pop(@siblings)) {($s == $self) and last;}

  return(@siblings);
} # end subroutine older_siblings definition
########################################################################


=head2 younger_siblings

  my @nodes = $toc->younger_siblings;

=cut

sub younger_siblings {
  my $self = shift;

  $self->is_root and return();
  my @siblings = $self->parent->children;

  while(my $s = shift(@siblings)) {($s == $self) and last;}

  return(@siblings);
} # end subroutine younger_siblings definition
########################################################################


=head2 next_sibling

Returns the next sibling or undef.

  $younger = $toc->next_sibling;

=cut

sub next_sibling {
  my $self = shift;

  my @younger = $self->younger_siblings or return();
  return($younger[0]);
} # end subroutine next_sibling definition
########################################################################

=head2 prev_sibling

Returns the previous sibling or undef.

  $older = $toc->prev_sibling;

=cut

sub prev_sibling {
  my $self = shift;

  my @older = $self->older_siblings or return();
  return($older[-1]);
} # end subroutine prev_sibling definition
########################################################################

=head2 parent

Returns the parent TOC object for the current object, or undef if
there is no parent TOC object.

  $toc->parent

=cut

# get_parent is a plain accessor

=head2 ancestors

Returns all of the node's ancestors (from parent upward.)

  my @ancestors = $toc->ancestors;

=cut

sub ancestors {
  my $self = shift;
  my $node = $self;
  my @ancestors;
  while(my $parent = $node->parent) {
    push(@ancestors, $parent);
    $node = $parent;
  }
  return(@ancestors);
} # end subroutine ancestors definition
########################################################################

=head2 has_children

True if the node has children.

  $toc->has_children

=cut

sub has_children {
  my $self = shift;

  if (defined $self->{children} && @{$self->{children}}) {
    return scalar(@{$self->{children}});
  }
  else {
    return 0;
  }
} # end subroutine has_children definition
########################################################################

=head2 add_child

Add a child TOC entry to this TOC entry.

  $toc->add_child($child);

=cut

sub add_child {
  my ($self, $child) = @_;
  unless(eval {$child->isa('dtRdr::TOC')} ) {
    confess "$child is not a TOC entry";
  }
  $self->{children} ||= [];
  push @{$self->{children}}, $child;
} # end subroutine add_child definition
########################################################################

=head2 child

Get the child with index $i.

  my $child = $toc->child($i);

=cut

sub child {
  my $self = shift;
  my ($i) = @_;
  (1 == @_) or croak "wrong number of arguments";

  my @children = $self->children;
  $children[$i] or croak 'no child there';
  return($children[$i]);
} # end subroutine child definition
########################################################################

=head2 root

  my $root = $toc->root;
  $root ||= $toc; # it was the root

=cut

sub root {
  my $self = shift;
  if($self->parent) {
    return($self->{_root});
  }
} # end subroutine root definition
########################################################################

=head2 is_root

  $toc->is_root;

=cut

sub is_root {
  my $self = shift;
  return(! defined($self->parent));
} # end subroutine is_root definition
########################################################################

=head2 _walk_to_node

Walks to the tree vector given by a list of successive child indices.

  my $node = $toc->_walk_to_node(@list);

=cut

sub _walk_to_node {
  my $self = shift;
  my (@list) = @_;
  my $child = $self;
  foreach my $i (@list) {
    $child = $child->child($i);
  }
  return($child);
} # end subroutine _walk_to_node definition
########################################################################

=head2 _add_to_index

  $root->_add_to_index($self);

=cut

sub _add_to_index {
  my $self = shift;
  my ($node) = @_;

  ($self->{_index} and not $self->parent) or die "I'm not the root";
  my $id = $node->id;
  exists($self->{_index}{id}{$id}) and
    croak("cannot duplicate id's ('$id')");
  $self->{_index}{id}{$id} = $node;
} # end subroutine _add_to_index definition
########################################################################

=head2 get_by_id

  my $node = $toc->get_by_id($id);

=cut

sub get_by_id {
  my $self = shift;
  my ($id) = @_;
  (1 == @_) or croak;

  my $root = $self->root || $self;

  #die "self has:", join("\n  ", keys(%{$self->{_index}{id}}));
  my $node = $root->{_index}{id}{$id};
  return($node);
} # end subroutine get_by_id definition
########################################################################

=head2 enclosing_node

Searches for the node which encloses the given offset.

  $toc->enclosing_node($offset);

=cut

sub enclosing_node {
  my $self = shift;
  my ($offset) = @_;

  $self->range->encloses($offset) or return;
  foreach my $child ($self->children) {
    # speed note: the worst case is we spin through the children when
    # the first is past offset (e.g. $offset lives in the parent)
    if($child->range->encloses($offset)) {
      return($child->enclosing_node($offset));
    }
  }
  return($self);
} # end subroutine enclosing_node definition
########################################################################

########################################################################
# TODO these two sound familiar -- have a trait?
# -- just let the book make a *::Accessor::* object or something and quit worrying about
# whether the keys exist or not.

=head1 Meta Accessors

=head2 get_info

  $toc->get_info($key);

=cut

sub get_info {
  my $self = shift;
  my ($key) = @_;
  my $info = $self->info;
  defined($key) or return($info);

  # XXX to complain or not to complain?
  #exists($self->{info}{$key}) or croak;#carp "info has no key '$key'";

  return($info->{$key});
} # end subroutine get_info definition
########################################################################

=head2 set_info

  $toc->set_info($key, $val);

=cut

sub set_info {
  my $self = shift;
  my ($key, $val) = @_;
  # TODO Params::Validate or something?
  (2 == @_) or croak "need two parameters";
  defined($key) or croak "must have a defined key";

  my $info = $self->info;

  $info->{$key} = $val;
} # end subroutine set_info definition
########################################################################

# XXX unused?
 sub set_range { # XXX is this even valid
  my ($self, $range) = @_;
  do('./util/BREAK_THIS') or die;
  unless(defined $self->{range}) {
    $self->{range} = $range;
  }
  else {
    die "Attempt to change the range of a TOC item";
  }
}

 sub set_id { # XXX is this even valid
  my ($self, $id) = @_;
  do('./util/BREAK_THIS') or die;
  unless(defined $self->{id}) {
    $self->{id} = $id;
  }
  else {
    die "Attempt to change the id of a TOC item";
  }
}
########################################################################

=head2 validate_ranges

  my $bool = $toc->validate_ranges;

=cut

sub validate_ranges {
  my $self = shift;
  my $errors = 0;
  $self->_rmap(sub {
    my $node = shift;

    $errors and return; # just bail unless we really need to count them

    my $range = $node->range;
    my ($s, $e) = map({$range->$_} qw(a b));
    my $last_end;
    ##print STDERR "check ", $node->id, "\n";
    foreach my $child ($node->children) {
      ##print STDERR "against ", $child->id, "\n";
      my $crange = $child->range;
      my ($cs, $ce) = map({$crange->$_} qw(a b));
      if(defined($last_end)) { # check sibling overlap
        ($cs > $last_end) or $errors++;
        ##print STDERR "($cs > $last_end)\n";
      }
      ($cs >= $s) or $errors++;
      ($ce <= $e) or $errors++;
      ##print STDERR "($cs >= $s), ($ce <= $e)\n";

      $last_end = $ce;
    }
  });
  ##print STDERR "errors:  $errors\n";
  return(! $errors);
} # end subroutine validate_ranges definition
########################################################################

=head2 validate_ids

  my @errors = $toc->validate_ids;

=cut

sub validate_ids {
  my $self = shift;
  my @errors;
  $self->rmap(sub {
    my $id = $_->id;
    unless(defined($id)) {
      push(@errors, "undefined id (title: " . $_->title . ")");
      return;
    }
    unless(length($id)) {
      push(@errors, "zero-length id (title: " . $_->title . ")");
      return;
    }
    unless($id =~ m/^[A-Z0-9_-]+$/i) {
      push(@errors, "malformed: '$id'");
      return;
    }
  });
  return(@errors);
} # end subroutine validate_ids definition
########################################################################

=head2 _dump

  print $toc->_dump;

=cut

sub _dump {
  my $self = shift;
  my $string = "$self";
  $string =~ s/.*=HASH\((.*)\)/$1/;
  my $pstring = 'is ROOT NODE';
  if(my $parent = $self->get_parent) {
    $pstring = "$parent";
    $pstring =~ s/.*=HASH\((.*)\)/$1/;
    $pstring = 'in ' . $pstring;
  }
  my @ret = (join(' ',
    $string, $pstring , '(' . ($self->visible ? '+' : '-') . ')' ,
    $self->title || '-NO TITLE-',
    '[' . $self->id . ']',
    )
    );
  if(my @children = $self->children) {
    foreach my $child (@children) {
      my @cnodes = $child->_dump;
      $_ = '  ' . $_ for (@cnodes);
      push(@ret, @cnodes);
    }
  }
  return(@ret);
} # end subroutine _dump definition
########################################################################

=head2 rmap

Depth-first recursion.  At each level, $sub is called as $sub->($node, \%ctrl).

The %ctrl hash allows you to send commands back to the dispatcher.

  my $sub = sub {
    my ($node, $ctrl) = @_;
    if(something($node)) {
      $ctrl->{prune} = 1; # do not follow children
    }
  };
  $toc->rmap($sub);

=cut

sub rmap {
  my $self = shift;
  my ($subref) = @_;
  my %ctrl;
  {
    local $_ = $self;
    $subref->($self, \%ctrl);
  }
  $ctrl{prune} and return;
  foreach my $child ($self->children) {
    $child->rmap($subref);
  }
} # end subroutine rmap definition
########################################################################

=head2 _rmap

deprecated

  $toc->_rmap($sub);

=cut

sub _rmap {
  my $self = shift;
  my ($subref) = @_;
  $subref->($self);
  foreach my $child ($self->children) {
    $child->_rmap($subref);
  }
} # end subroutine _rmap definition
########################################################################

=head2 _while_gutted

  $toc->_while_gutted(sub {my $braindead = shift;});

=cut

sub _while_gutted {
  my $self = shift;
  my ($subref) = @_;
  do('./util/BREAK_THIS') or die;

  my $book = $self->book;

  # we have to take out the innards to get a reliable dclone
  my %guts;
  $guts{$_} = delete($book->{$_}) for(keys(%$book)); # don't hate me

  $subref->($self);

  $book->{$_} = delete($guts{$_}) for(keys(%guts));

  return($self);
} # end subroutine _while_gutted definition
########################################################################

=head2 _unhook

Drop book, parent, and _index.  Turn ranges into [$id, $start, $end].

  $simple = $toc->_unhook;

=cut

sub _unhook {
  my $self = shift;

  my %simple;
  for my $prop (qw(info id title visible copy_ok)) {
    $simple{$prop} = $self->{$prop} if(exists($self->{$prop}));
  }
  my $range = $self->range;
  $simple{range} = [$range->id, $range->a, $range->b];
  $simple{wrange} = [$self->get_word_start, $self->get_word_end];
  $simple{children} = [] if($self->{children});
  foreach my $child ($self->children) {
    push(@{$simple{children}}, $child->_unhook);
  }
  return(\%simple);
} # end subroutine _unhook definition
########################################################################

=head2 _rehook

...re-attach the book (as well as rebuilding the index.)

  $obj->_rehook($book);

=cut

# NOTE this has to break encapsulation since it it all about
# optimization if something goes wrong, caller should just dump the
# cached TOC and rebuild

sub _rehook {
  my $self = shift;
  my ($book) = @_;

  { # process the dump metadata
    my $dumpmeta = delete($self->{dumpmeta}) or
      croak("missing 'dumpmeta' property in toc");
    # TODO dispatch to older handlers
    ($dumpmeta->{version} == 0.1) or die "this needs work";

    my $fp = $dumpmeta->{fingerprint};
    defined($fp) or die 'toc has no fingerprint';
    my $bfp = $book->fingerprint;
    defined($bfp) or die 'book has no fingerprint';
    ($fp eq $bfp) or
      die "fingerprints do not match!\n  stored: $fp\n  book:   $bfp";
  }

  # $self is the root
  $self->{_index} = { id => {} };
  $self->{parent} = undef;

  # walk the tree, rebuilding the index and linkage
  my $package = ref($self);
  # TODO SPEED iterate instead of recurse might be faster?
  # TODO PROGRESS - $book->progressing('_rehook', $percent) ?
  $self->_rmap(sub {
    my $node = shift; # is root the first time through

    # our own loop-over-children for parent and rootness
    foreach my $child (@{$node->{children}}) {
      # bless them here so $child->rmap will work later
      bless($child, $package);
      $child->$set_parent($node);
      $child->{_root} = $self;
    }

    $self->_add_to_index($node);
    $node->$set_book($book);
    my @wrange = @{delete($node->{wrange})};
    $node->set_word_start($wrange[0]);
    $node->set_word_end($wrange[1]);
    my @range = @{$node->{range}};
    my $r_id = shift(@range);
    $node->{range} = dtRdr::Range->create(
      id => $r_id, node => $book, range => [@range]
    );
  });

  return($self);
} # end subroutine _rehook definition
########################################################################

=head2 unhooked

  my $plain = $toc->unhooked;

=cut

sub unhooked {
  my $self = shift;
  my $unhooked = $self->_unhook;

  # embed some meta info in it
  {
    my $fingerprint = $self->book->fingerprint;
    defined($fingerprint) or die 'book has no fingerprint';
    $unhooked->{dumpmeta} = {
      version => 0.1,
      fingerprint => $fingerprint,
    };
  }
  return($unhooked);
} # end subroutine unhooked definition
########################################################################

=head2 yaml_dump

Maybe Deprecated - do your own dumps?

  my $yaml = $toc->yaml_dump;

=cut

sub yaml_dump {
  my $self = shift;

  my $unhooked = $self->unhooked;
  require YAML::Syck;
  return(YAML::Syck::Dump($unhooked));
} # end subroutine yaml_dump definition
########################################################################

=head2 yaml_load

Load the TOC from a YAML string (or reference if you need the speed) and
re-attach the book (as well as rebuilding the index.)

  my $re_toc = dtRdr::TOC->yaml_load($yaml, $book);

  my $re_toc = dtRdr::TOC->yaml_load(\$yaml, $book);

=cut

sub yaml_load {
  my $package = shift;
  my ($yaml, $book) = @_;
  $book or croak("need a book");

  if(my $ref = ref($yaml)) { # does this make anything any faster?
    ($ref eq 'SCALAR') or croak("not a scalar reference ($ref)");
  }
  else {
    my $v = $yaml;
    $yaml = \$v;
  }
  require YAML::Syck;
  local $YAML::Syck::ImplicitUnicode = 1;
  my $data = YAML::Syck::Load($$yaml);
  bless($data, $package);
  return($data->_rehook($book));
} # end subroutine yaml_load definition
########################################################################

=head2 stb_load

Load from a Storable.pm binary file.

  my $re_toc = dtRdr::TOC->stb_load(\$stb, $book);

=cut

sub stb_load {
  my $package = shift;
  my ($stb, $book) = @_;
  $book or croak("need a book");

  if(my $ref = ref($stb)) { # does this make anything any faster?
    ($ref eq 'SCALAR') or croak("not a scalar reference ($ref)");
  }
  else {
    my $v = $stb;
    $stb = \$v;
  }
  require Storable;
  #WARN("going to thaw ", length($$stb), " bytes");
  # store() and freeze() create slightly different data :-(
  # we would do better to read directly from a filehandle here?

  ## my $start1 = Time::HiRes::time();
  open(my $fh, '<', $stb);
  my $data = Storable::fd_retrieve($fh);
  ## warn "storable load in ", Time::HiRes::time() - $start1, " seconds\n";

  bless($data, $package);
  ## my $start2 = Time::HiRes::time();
  my $self = $data->_rehook($book);
  ## warn "rehook in ", Time::HiRes::time() - $start2, " seconds\n";
  return($self);
} # end subroutine stb_load definition
########################################################################

=head2 freeze

  $stored = $toc->freeze;

=cut

sub freeze {
  my $self = shift;
  require Storable;
  my $frozen;
  $self->_while_gutted(sub {
    # maybe flag it like so or possibly something stricter
    $self->{is_gutted} = 1;

    $frozen = Storable::freeze($self);

    delete $self->{is_gutted};
    });


  return($frozen);
} # end subroutine freeze definition
########################################################################

=head2 thaw

  $toc->thaw($book);

=cut

sub thaw {
  my $self = shift;
  croak("does nothing yet");
} # end subroutine thaw definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

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

1;
# vim:ts=2:sw=2:et:sta
