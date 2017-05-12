# -*- mode: perl; coding: utf-8 -*-
package YATT::LRXML::Node;
# Media か？
# To cooperate with JSON easily, Nodes should not rely on OO style.

use strict;
use warnings qw(FATAL all NONFATAL misc);
use YATT::Util::Symbol;
use YATT::Util;
use Carp;

use base qw(Exporter);
our (@EXPORT_OK, @EXPORT);
BEGIN {
  @EXPORT_OK = qw(stringify_node
		  stringify_attlist

		  create_node
		  create_node_from
		  copy_node_renamed_as

		  create_attlist
		  node_size
		  node_children
		  node_type_name
		  node_name
		  node_nsname
		  node_path
		  node_headings
		  node_set_nlines
		  node_user_data
		  node_user_data_by
		  node_attribute_format
		  is_attribute
		  is_primary_attribute
		  is_bare_attribute
		  is_quoted_by_element
		  is_empty_element

		  quoted_by_element

		  copy_array

		  EMPTY_ELEMENT
		);
  @EXPORT = @EXPORT_OK;
}

sub exports { @EXPORT_OK }

sub MY () {__PACKAGE__}

our @NODE_MEMBERS; BEGIN {@NODE_MEMBERS = qw(TYPE FLAG NLINES USER_SLOT
					     RAW_NAME BODY)}
use YATT::Util::Enum -prefix => '_', @NODE_MEMBERS;

BEGIN {
  foreach my $name (@NODE_MEMBERS) {
    my $offset = MY->can("_$name")->();
    my $func = "node_".lc($name);
    *{globref(MY, $func)} = sub {
      shift->[$offset]
    };
    push @EXPORT_OK, $func;
    push @EXPORT, $func;
  }
}

our @NODE_TYPES;
our %NODE_TYPES;
our @NODE_FORMAT;

BEGIN {
  my @desc = ([text => '%s'] # May not be used.
	      , [comment => '<!--#%2$s' . '%1$s-->']
	      , [decl_comment => '--%1$s--']
	      , [pi      => '<?%2$s'    . '%1$s?>' ]
	      , [entity  => '%3$s'.'%2$s'.'%1$s;', ['&', '%']]

	      , [root    => \&stringify_root]
	      , [element => \&stringify_element]
	      , [attribute => \&stringify_attribute]
	      , [declarator => \&stringify_declarator]
	      , [html => \&stringify_element]
	      , [unknown => \&stringify_unknown]
	      );
  $NODE_TYPES{$_->[0]} = keys %NODE_TYPES for @desc;
  @NODE_TYPES  = map {$_->[0]} @desc;
  @NODE_FORMAT = map {ref $_->[1] eq 'CODE' ? $_->[1] : [@$_[1..$#$_]]} @desc;
}

BEGIN {
  my @type_enum = map {uc($_) . '_TYPE'} @NODE_TYPES;
  require YATT::Util::Enum;
  import YATT::Util::Enum @type_enum;
  push @EXPORT_OK, @type_enum;
  push @EXPORT, @type_enum;
}

# ATTRIBUTE の FLAG の意味は、↓これと &quoted_by_element が決める。
our @QUOTE_CHAR; BEGIN {@QUOTE_CHAR = ("", '\'', "\"", [qw([ ])])}
# XXX: ↓ 役割は減る予定。
our @QUOTE_TYPES; BEGIN {@QUOTE_TYPES = (1, 2, 0)}

sub new {
  my $pack = shift;
  bless $pack->create_node(@_), $pack;
}

# $pack->create_node($typeName, $nodeName, $nodeBody)
# $pack->create_node([$typeName, $flag], [@nodePath], @nodeBody)

sub sum_node_nlines {
  my $nlines = 0;
  foreach my $item (@_) {
    unless (ref $item) {
      $nlines += $item =~ tr,\n,,;
    } elsif (defined (my $sub = $item->[_NLINES])) {
      $nlines += $sub;
    } else {
      $nlines += sum_node_nlines(node_children($item));
    }
  }
  $nlines;
}

sub create_node {
  my ($pack, $type, $name) = splice @_, 0, 3;
  my ($typename, $flag) = ref $type ? @$type : $type;
  $flag = 0 unless defined $flag;
  my $typeid = $NODE_TYPES{$typename};
  die "Unknown type: $typename" unless defined $typeid;
  # DEPEND_ALIGNMENT: SET_NLINES:
  [$typeid, $flag, sum_node_nlines(@_), undef, $name, @_];
}

sub create_node_from {
  my ($pack, $orig, $name) = splice @_, 0, 3;
  my ($typeid, $flag) = @{$orig}[_TYPE, _FLAG];
  $name = copy_array($$orig[_RAW_NAME]) unless defined $name;
  # DEPEND_ALIGNMENT: SET_NLINES:
  [$typeid, $flag, sum_node_nlines(@_), undef, $name, @_]
}

sub copy_node_renamed_as {
  my ($pack, $name, $orig) = splice @_, 0, 3;
  create_node_from($pack, $orig, $name, @{$orig}[_BODY .. $#$orig]);
}

sub node_headings {
  my $node = shift;
  ([$NODE_TYPES[$$node[_TYPE]], $$node[_FLAG]]
   , $$node[_RAW_NAME]);
}

sub node_body_starting () { _BODY }

sub node_size {
  my $node = shift;
  @$node - _BODY;
}

sub node_children {
  my $node = shift;
  @{$node}[_BODY .. $#$node];
}

sub node_type_name {
  $NODE_TYPES[shift->[_TYPE]];
}

sub is_attribute {
  $_[0]->[_TYPE] == ATTRIBUTE_TYPE;
}

sub is_primary_attribute {
  $_[0]->[_TYPE] == ATTRIBUTE_TYPE
    && (! defined $_[0]->[_FLAG]
	|| $_[0]->[_FLAG] < @QUOTE_CHAR);
}

sub is_bare_attribute {
  $_[0]->[_TYPE] == ATTRIBUTE_TYPE
    && defined $_[0]->[_FLAG]
      && $_[0]->[_FLAG] == 0;
}

sub stringify_node {
  my ($node) = shift;
  my $type = $node->[_TYPE];
  if (not defined $type or $type eq '') {
    die "Invalid node object: ".YATT::Util::terse_dump($node);
  }
  if (@NODE_FORMAT <= $type) {
    die "Unknown type: $type";
  }
  if (ref(my $desc = $NODE_FORMAT[$type]) eq 'CODE') {
    $desc->($node, @_);
  } else {
    my ($fmt, $prefix, $suffix) = @$desc;
    use YATT::Util::redundant_sprintf;
    sprintf($fmt
	    , stringify_each_by($node)
	    , node_nsname($node, '')
	    , defined $prefix ? $prefix->[$node->[_FLAG]] : ''
	    , defined $suffix ? $suffix->[$node->[_FLAG]] : '');
  }
}

# node_path は name スロットを返す。wantarray 対応。

sub node_path {
  my ($node, $first, $sep, $default) = @_;
  my $raw;
  unless (defined ($raw = $node->[_RAW_NAME])) {
    defined $default ? $default : return;
  } elsif (not ref $raw) {
    # undef かつ wantarray は只の return に分離した方が良いかも？
    $raw;
  } else {
    my @names = @$raw[($first || 0) .. $#$raw];
    wantarray ? @names : join(($sep || ":")
			      , map {defined $_ ? $_ : ''} @names);
  }
}

# node_nsname は namespace 込みのパスを返す。

sub node_nsname {
  my ($node, $default, $sep) = @_;
  scalar node_path($node, 0, $sep, $default);
}

# node_name は namespace を除いたパスを返す。
# yatt:else なら else が返る。

sub node_name {
  my ($node, $default, $sep) = @_;
  node_path($node, 1, $sep, $default);
}

sub node_set_nlines {
  my ($node, $nlines) = @_;
  $node->[_NLINES] = $nlines;
  $node;
}

sub node_user_data {
  my ($node) = shift;
  if (@_) {
    $node->[_USER_SLOT] = shift;
  } else {
    $node->[_USER_SLOT];
  }
}

sub node_user_data_by {
  my ($node) = shift;
  my $slot = $node->[_USER_SLOT] ||= do {
    my ($obj, $meth) = splice @_, 0, 2;
    $obj->$meth(@_);
  };
  wantarray ? @$slot : $slot;
}

#----------------------------------------

sub stringify_element {
  my ($elem) = @_;
  stringify_as_tag($elem, node_nsname($elem), $elem->[_FLAG]);
}

sub stringify_declarator {
  my ($elem, $strip_ns) = @_;
  # XXX: 本物にせよ。
  my $tag = node_nsname($elem);
  my $attlist = stringify_each_by($elem, ' ', ' ', '', _BODY);
  "<!$tag$attlist>"
}

sub stringify_root {
  my ($elem) = @_;
    stringify_each_by($elem
		      , ''
		      , ''
		      , ''
		      , _BODY);
}

sub stringify_unknown {
  die 'unknown';
}

#----------------------------------------

sub stringify_as_tag {
  my ($node, $name, $is_ee) = @_;
  my $bodystart = node_beginning_of_body($node);
  my $tag = do {
    if (defined $name && is_attribute($node)) {
      ":$name";
    } else {
      $name;
    }
  };
  my $attlist = stringify_attlist($node, $bodystart);
  if ($is_ee) {
    stringify_each_by($node
		      , $tag ? qq(<$tag$attlist />) : ''
		      , ''
		      , ''
		      , $bodystart);
  } else {
    stringify_each_by($node
		      , $tag ? qq(<$tag$attlist>) : ''
		      , ''
		      , $tag ? qq(</$tag>) : ''
		      , $bodystart);
  }
}

sub stringify_attlist {
  my ($node) = shift;
  my $bodystart = shift || node_beginning_of_body($node);
  #  print "[[for @{[$node->get_name]}; <",
  return '' if defined $bodystart and _BODY == $bodystart
    or not defined $bodystart and $#$node < _BODY;
  stringify_each_by($node, ' ', ' ', '', _BODY
		    , (defined $bodystart ? ($bodystart - 1) : ()))
}

sub stringify_each_by {
  my ($node, $open, $sep, $close) = splice @_, 0, 4;
  $open ||= ''; $sep ||= ''; $close ||= '';
  my $from = @_ ? shift : _BODY;
  my $to = @_ ? shift : $#$node;
  my $result = $open;
  if (defined $from and defined $to) {
    $result .= join $sep, map {
      unless (defined $_) {
	''
      } elsif (ref $_) {
	my $s = stringify_node($_);
	unless (defined $s) {
	  require YATT::Util;
	  die "Can't stringify node: ". YATT::Util::terse_dump($_)
	}
	$s;
      } else {
	$_
      }
    } @{$node}[$from .. $to];
  }
  $result .= $close if defined $close;
  $result;
}

sub node_beginning_of_body {
  my ($node) = @_;
  lsearch {
    not ref $_ or not is_primary_attribute($_)
  } $node, _BODY;
}

#----------------------------------------

sub create_attlist {
  my ($parser) = shift;
  my @result;
  while (@_) {
    my ($sp, $name, $eq, @values) = splice @_, 0, 6;
    my $found = lsearch {defined} \@values;
    my ($subtype, $attname, @attbody) = do {
      unless (defined $found) {
	(undef, $name);
      } elsif (not defined $name and $found == 2
	      and $values[$found] =~ /^[\w\:\-\.]+$/) {
	# has single bareword. use it as name and keep value undef.
	(undef, $values[$found]);
      } else {
	# parse_entities can return ().
	($QUOTE_TYPES[$found], $name =>
	 $parser->parse_entities($values[$found]));
      }
    };
    my @typed; @typed = split /:/, $attname if defined $attname;
    # DEPEND_ALIGNMENT: SET_NLINES:
    push @result, [ATTRIBUTE_TYPE, $subtype, 0, undef
		   , @typed > 1 ? \@typed : $attname
		   , @attbody];
  }
  @result;
}

sub stringify_attribute {
  my ($node) = @_;
  if (defined $$node[_FLAG] && $$node[_FLAG] >= @QUOTE_CHAR) {
    stringify_as_tag($node
		     , node_nsname($node)
		     , $$node[_FLAG] - MY->quoted_by_element(0));
  } else {
    my (@stringify_as) = attribute_stringify_as($node);
    if (@stringify_as == 1) {
      $stringify_as[0]
    } else {
      stringify_each_by($node, @stringify_as, _BODY);
    }
  }
}

sub node_attribute_format {
  my ($node) = @_;
  my ($open, $sep, $close) = attribute_stringify_as($node);
  ($open, $close);
}

sub attribute_stringify_as {
  my ($node) = @_;
  unless (defined $$node[_BODY]) {
    (join_or_string($$node[_RAW_NAME]), '', '');
  } else {
    my $Q = $$node[_FLAG] ? @QUOTE_CHAR[$$node[_FLAG]] : "";
    my ($sep, $opn, $clo) = ref $Q ? (' ', @$Q) : ('', $Q, $Q);
    my $prefix = join_or_empty(join_or_string($$node[_RAW_NAME]), '=').$opn;
    ($prefix, $sep, $clo);
  }
}

sub join_or_string {
  ref $_[0] ? join(":", @{$_[0]}) : $_[0];
}

sub join_or_empty {
  my $str = '';
  foreach my $item (@_) {
    return '' unless defined $item;
    $str .= $item;
  }
  $str;
}

sub EMPTY_ELEMENT () { 1 + @QUOTE_CHAR }

sub quoted_by_element {
  my ($pack, $is_ee) = @_;
  if ($is_ee) {
    EMPTY_ELEMENT;
  } else {
    scalar @QUOTE_CHAR; # 3 for now.
  }
}

sub is_quoted_by_element {
  my ($node) = @_;
  defined $node->[_FLAG] && $node->[_FLAG] >= @QUOTE_CHAR;
}

sub is_empty_element {
  my ($node) = @_;
  defined $node->[_FLAG] && $node->[_FLAG] == EMPTY_ELEMENT;
}

1;
