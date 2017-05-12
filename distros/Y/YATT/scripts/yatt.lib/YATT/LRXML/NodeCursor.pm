# -*- mode: perl; coding: utf-8 -*-
package YATT::LRXML::NodeCursor; # Location, Zipper?
use strict;
use warnings qw(FATAL all NONFATAL misc);

use base qw(YATT::Class::Configurable);
use YATT::Fields qw(^tree ^cf_metainfo cf_path);
sub Path () {'YATT::LRXML::NodeCursor::Path'}

use YATT::Util::Symbol;
use YATT::LRXML::Node qw(stringify_node
			 stringify_attlist
			 create_node
			 create_node_from
			 copy_array);

use Carp;

# XXX: Configurable に init と clone のプロトコルを…って、
# fields の中身に依存するから、やばいか。

BEGIN {
  package YATT::LRXML::NodeCursor::Path;
  use base qw(YATT::Class::ArrayScanner);
  use YATT::Fields qw(cf_path cur_postype prev_postype);

  use YATT::LRXML::Node qw(node_type ATTRIBUTE_TYPE);

  use YATT::Util::Enum -prefix => 'POSTYPE_', qw(UNKNOWN ATTLIST BODY);

  sub init {
    my ($self, $array, $path, $index0) = splice @_, 0, 4;
    $self->SUPER::init(array => $array
		       , index => ($index0 || 0)
		       + YATT::LRXML::Node::_BODY
		       , path => $path, @_)
      ->after_next;
  }

  sub clone {
    my MY $orig = shift;
    ref($orig)->new($orig->{cf_array}, $orig->{cf_path}
		    # XXX: To compensate init()
		    , $orig->{cf_index} - YATT::LRXML::Node::_BODY);
  }

  sub parent {
    my MY $path = shift; $path->{cf_path}
  }

  sub after_next {
    (my MY $path) = @_;
    return $path unless defined $path->{cf_index}
      and $path->{cf_index} <= $#{$path->{cf_array}};
    my $val = $path->{cf_array}->[$path->{cf_index}];
    $path->{prev_postype} = $path->{cur_postype};
    if (not defined $path->{cur_postype}
	or $path->{cur_postype} == POSTYPE_ATTLIST) {
      $path->{cur_postype} = ref $val && node_type($val) == ATTRIBUTE_TYPE
	? POSTYPE_ATTLIST : POSTYPE_BODY;
    }
    $path
  }

  sub is_beginning {
    (my MY $path) = @_;
    return 1 unless defined $path->{prev_postype};
    return unless $path->{cur_postype} == POSTYPE_BODY;
    $path->{prev_postype} == POSTYPE_ATTLIST;
  }
}

sub initargs {qw(tree)}

sub new_opened {
  my ($class, $tree) = splice @_, 0, 2;
  $class->new($tree, path => $class->Path->new($tree), @_);
}

sub new_path {
  my MY $self = shift;
  $self->Path->new($self->{tree}, shift); # XXX: tree でいいの?
}

sub clone_path {
  my MY $self = shift;
  my Path $path = shift || $self->{cf_path};
  $self->Path->new($path->{cf_array}, $path ? $path->{cf_path} : undef);
}

sub clone {
  (my MY $self, my ($path)) = @_;
  # XXX: 他のパラメータは? 特に、継承先で足したパラメータ。
  ref($self)->new($self->{tree}
		  , metainfo => $self->{cf_metainfo}
		  , path => ($path || ($self->{cf_path} ? $self->{cf_path}->clone
				       : undef)));
}

sub variant_builder {
  my MY $self = shift;
  my Path $orig = $self->{cf_path};
  my $variant = do {
    if (@_) {
      $self->create_node(@_);
    } else {
      $self->create_node_from($orig->{cf_array});
    }
  };
  $self->adopter_for($variant, $orig->{cf_path});
}

sub adopter_for {
  (my MY $self, my ($array, $path)) = @_;
  $self->clone($self->Path->new($array, $path || $self->{cf_path}))
}

sub add_node {
  my MY $self = shift;
  my Path $path = $self->{cf_path};
  push @{$path->{cf_array}}, @_;
  $self;
}

sub create_attribute {
  (my MY $self, my ($name)) = splice @_, 0, 2;
  $self->create_node([attribute => 0], $name, @_);
}

sub add_attribute {
  (my MY $self, my ($name)) = splice @_, 0, 2;
  $self->add_node(my $attr = $self->create_node([attribute => 0], $name, @_));
  $attr;
}

sub add_filtered_copy {
  (my MY $self, my ($node, $filter, $primary_only)) = @_;
  my $boundary = $primary_only ? 'is_primary_attribute' : 'readable';
  for (; $node->$boundary(); $node->next) {
    my @node = do {
      if ($node->is_attribute) {
	my ($sub, @rest) = ref $filter eq 'ARRAY' ? @$filter : $filter;
	$sub->(@rest, $node->node_name, $node->current);
      } else {
	copy_array($node->current);
      }
    };
    $self->add_node(@node) if @node;
  }
  $self;
}

sub copy_from {
  (my MY $clone, my MY $orig) = @_;
  for (my $n = $orig->clone; $n->readable; $n->next) {
    $clone->add_node(copy_array($n->current));
  }
  $clone;
}

sub clone_filtered_by {
  my MY $orig = shift;
  # XXX: $orig を next してしまって、良いのか？ clone した方が良いかも?
  my MY $clone = $orig->variant_builder;
  my ($hash, $all) = @_;
  my $boundary = $all ? 'readable' : 'is_primary_attribute';
  for (; $orig->$boundary(); $orig->next) {
    my @name;
    if ($orig->is_attribute and @name = $orig->node_path
	and $hash->{$name[0]}) {
      ${$hash->{$name[0]}} = $orig->current;
      next;
    }
    $clone->add_node(copy_array($orig->current));
  }
  $clone;
}

sub copy {
  (my MY $self, my ($node)) = @_;
  copy_array($node);
}

sub copy_renamed {
  (my MY $self, my ($name, $node)) = @_;
  if (defined $name) {
    $self->create_node_from
      ($node, $name, copy_array(YATT::LRXML::Node::node_children($node)));
  } else {
    copy_array($node);
  }
}

sub make_wrapped {
  (my MY $self, my ($type, $name)) = splice @_, 0, 3;
  my Path $orig = $self->{cf_path};
  my $wrap = $self->create_node($type || 'unknown', $name, $orig->{cf_array});
  my $path = $self->Path->new($wrap, $orig);
  ref($self)->new($self->{tree}
		  , metainfo => $self->{cf_metainfo}
		  , path => $path);
}

sub filter_or_add_from {
  (my MY $self, my ($node, $except, %opts)) = @_;
  my $boundary = delete $opts{primary_only}
    ? 'is_primary_attribute' : 'readable';
  croak "Invalid option: " . join(",", keys %opts) if %opts;

  my ($name, @filtered);
  for (; $node->$boundary(); $node->next) {
    if ($node->is_attribute
	and defined ($name = $node->node_name)
	and exists $except->{$name}) {
      # clone は？
      # name を書き換えても良いのでは？
      my $cur = $node->current;
      push @filtered, do {
	if (defined $except->{$name}) {
	  $self->copy_renamed($cur, $except->{$name});
	} else {
	  $cur
	}
      };
    } else {
      $self->add_node($node->current);
    }
  }

  @filtered;
}

sub open {
  my MY $self = shift;
  my $obj;
  unless (defined (my Path $path = $self->{cf_path})) {
    $self->clone($self->new_path);
  } elsif (not defined ($obj = $path->{cf_array}->[$path->{cf_index}])
	   or ref $obj ne 'ARRAY') {
    $obj;
  } else {
    # 本当に clone が良いのだろうか?
    $self->clone($self->Path->new($obj, $path));
  }
}

# cursor 本体ではなく、path だけが欲しいときのために。
# ← open をカスタマイズしたい時に用いる。
sub open_path {
  my MY $self = shift;
  unless (defined (my Path $path = $self->{cf_path})) {
    $self->new_path;
  } else {
    my $obj = $path->{cf_array}->[$path->{cf_index}];
    die "Not an object!" unless defined $obj && ref $obj eq 'ARRAY';
    $self->Path->new($obj, $path);
  }
}

sub can_open {
  my MY $self = shift;
  my Path $path = $self->{cf_path};
  my $obj = $path->{cf_array}->[$path->{cf_index}];
  defined $obj && ref $obj eq 'ARRAY';
}

sub close {
  my MY $self = shift;
  if (my Path $parent = $self->{cf_path}->parent) {
    $parent->{cf_index}++;
    $self->clone($parent);
  } else {
    return
  }
}

sub parent {
  my MY $self = shift;
  $self->clone($self->{cf_path}->parent);
}

sub can_close {
  my MY $self = shift;
  defined $self->{cf_path};
}

BEGIN {
  my @delegate_to_path =
    qw(read
       current
       next
       prev
       array
     );
  foreach my $meth (@delegate_to_path) {
    *{globref(__PACKAGE__, $meth)} = sub {
      my MY $self = shift;
      return unless defined $self->{cf_path};
      $self->{cf_path}->$meth(@_);
    };
  }

  my @delegate_and_self = qw(go_next);
  foreach my $meth (@delegate_and_self) {
    *{globref(__PACKAGE__, $meth)} = sub {
      my MY $self = shift;
      return unless defined $self->{cf_path};
      $self->{cf_path}->$meth(@_);
      $self;
    };
  }

  foreach my $meth (grep {/^(node|is)_/} YATT::LRXML::Node->exports) {
    my $for_text = do {no strict 'refs'; \&{"text_$meth"}};
    my $sub = YATT::LRXML::Node->can($meth);
    *{globref(__PACKAGE__, $meth)} = sub {
      my MY $cursor = shift;
      return unless $cursor->readable;
      if (ref(my $value = $cursor->current)) {
	$sub->($value, @_);
      } else {
	$for_text->($value, @_);
      }
    };
  }

  foreach my $meth (my @delegate_to_meta = qw(filename)) {
    *{globref(__PACKAGE__, $meth)} = sub {
      my MY $cursor = shift;
      defined (my $meta = $cursor->{cf_metainfo})
	or return;
      $meta->$meth(@_);
    };
  }
}

sub rewind {
  my MY $self = shift;
  if (my Path $path = $self->{cf_path}) {
    $path->{cf_index} = YATT::LRXML::Node::_BODY;
  }
  $self
}

sub readable {
  my MY $self = shift;
  defined $self->{cf_path} && $self->{cf_path}->readable;
}

# value, size は全体。
sub value {
  my MY $self = shift;
  unless (defined $self->{cf_path}) {
    $self->{tree}
  } else {
    $self->{cf_path}->value;
  }
}

sub array_size {
  my MY $self = shift;
  YATT::LRXML::Node::node_size(do {
    unless (defined (my Path $path = $self->{cf_path})) {
      $self->{tree};
    } else {
      $path->{cf_array};
    }
  });
}

sub size {
  my MY $self = shift;
  unless (defined (my Path $path = $self->{cf_path})) {
    YATT::LRXML::Node::node_size($self->{tree});
  } elsif (not defined (my $obj = $path->{cf_array}->[$path->{cf_index}])) {
    0
  } elsif (ref $obj) {
    YATT::LRXML::Node::node_size($obj);
  } else {
    1;
  }
}

sub has_parent {
  my MY $self = shift;
  defined (my Path $path = $self->{cf_path}) or return 0;
  $path->{cf_path}
}

sub depth {
  my MY $self = shift;
  my $depth = 0;
  while (defined (my Path $path = $self->{cf_path})) {
    $depth++;
  }
  $depth;
}

sub startline {
  my MY $self = shift;
  $self->metainfo->cget('startline');
}

sub linenum {
  (my MY $self, my ($offset_atstart)) = @_;
  my $linenum = $self->startline;
  my Path $path = $self->{cf_path};
  my $offset = $offset_atstart;
  while ($path) {
    $linenum += $self->count_lines_of(map {
      $path->{cf_array}[$_]
    } YATT::LRXML::Node::_BODY .. $path->{cf_index} - 1 + ($offset || 0));
    $path = $path->{cf_path};
    undef $offset;
  }
  $linenum;
}

sub count_lines_of {
  # XXX: 他でも使うように。
  my ($pack) = shift;
  my $sum = 0;
  foreach my $item (@_) {
    next unless defined $item;
    $sum += do {
      if (ref $item) {
	YATT::LRXML::Node::node_nlines($item);
      } else {
	$item =~ tr:\n::;
      }
    };
  }
  $sum;
}

sub node_is_beginning {
  my MY $self = shift;
  my Path $path = $self->{cf_path} or return;
  $path->is_beginning;
}

sub node_is_end {
  my MY $self = shift;
  my Path $path = $self->{cf_path} or return;
  defined $path->{cf_index} or return;
  $path->{cf_index} >= $#{$path->{cf_array}};
}

*stringify = *stringify_current; *stringify = *stringify_current;

sub stringify_current {
  my MY $self = shift;
  my Path $path = $self->{cf_path};
  unless (defined $path) {
    stringify_node($self->{tree});
  } elsif (ref (my $value = $path->current)) {
    stringify_node($value);
  } else {
    $value;
  }
}

sub stringify_all {
  my MY $self = shift;
  my Path $path = $self->{cf_path};
  unless (defined $path) {
    stringify_node($self->{tree});
  } else {
    stringify_node($path->{cf_array});
  }
}

sub path_list {
  my MY $self = shift;
  my @path;
  if (my Path $path = $self->{cf_path}) {
  # XXX: 一、ずれてるじゃん、と。引くの?
    do {
      unshift @path, $path->{cf_index} - YATT::LRXML::Node::_BODY;
      $path = $path->{cf_path};
    } while $path;
  }
  wantarray ? @path : join ", ", @path;
}

sub parse_typespec {
  my MY $self = shift;
  my ($head, @rest) = $self->node_children;
  unless (defined $head) {
    ()
  } elsif ($head =~ s{^(\w+((?:\:\w+)*))?(?:([|/?!])(.*))?}{}s) {
    # $1 can undef.
    ($1 && $2 ? [split /:/, $1] : $1
     , default => @rest ? [defined $4 ? ($4) : (), @rest] : $4
     , default_mode => $3)
  } else {
    (undef);
  }
}

sub next_is_body {
  my MY $self = shift;
  my Path $path = $self->{cf_path} or return;
  my $next = $path->{cf_index} + 1;
  return if $next >= @{$path->{cf_array}};
  my $item = $path->{cf_array}[$next];
  return unless defined $item;
  return 1 unless ref $item;
  not YATT::LRXML::Node::is_primary_attribute($item);
}

sub text_is_attribute { 0 }
sub text_is_bare_attribute { 0 }
sub text_is_primary_attribute { 0 }
sub text_is_quoted_by_element { 0 }
sub text_node_size { 1 }
sub text_node_type { YATT::LRXML::Node::TEXT_TYPE }
sub text_node_body { shift }
sub text_node_type_name { 'text' }
sub text_node_flag { 0 }
sub text_node_name { undef }
sub text_node_children {
  if (ref $_[0]) {
    YATT::LRXML::Node::node_children($_[0])
  } else {
    $_[0];
  }
}

1;
