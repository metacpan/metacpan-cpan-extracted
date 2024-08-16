package YATT::Lite::Constants;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use 5.010; no if $] >= 5.017011, warnings => "experimental";

require Carp;

#========================================
# 今回は LRXML の serializability を捨てる
use YATT::Lite::Util::Enum
  (TYPE_ => [qw(LINEINFO COMMENT
		LCMSG
		  ENTITY PI ELEMENT
		  ATTRIBUTE=ATT_NAMEONLY ATT_BARENAME ATT_TEXT ATT_NESTED
		  ATT_MACRO=DECL_ENTITY)]
   , NODE_ => [qw(TYPE BEGIN END LNO
                  SYM_END
                  BODY_BEGIN BODY_END
                  PATH REST=VALUE=BODY ATTLIST
		  AELEM_HEAD AELEM_FOOT)]
   # node item
   # BODY が必ず配列になるが、代わりに @attlist は配列不要に。 空の [] を pad しなくて済む
   # XXX: <:yatt:else /> とかもあったじゃん！

   , ENT_ => [qw(TYPE KEY REST=VALUE=BODY)]
  );

# Not worked. why?
# BEGIN {
#   push our @EXPORT_OK, qw/*TYPE_ *NODE_/;
# }

sub cut_first (&@) {
  my ($code, $list) = @_;
  local $_;
  for (my $i = 0; $i < @$list; $i++) {
    $_ = $list->[$i];
    next unless $code->($_);
    splice @$list, $i, 1;
    return $_;
  }
}

sub cut_first_att {
  my ($list) = @_;
  cut_first {$_->[NODE_TYPE] >= TYPE_ATTRIBUTE} $list;
}

# node expand.
sub nx {
  @{$_[0]}[(NODE_PATH + ($_[1] // 0)) .. $#{$_[0]}];
}
sub bar_escape ($) {
  unless (defined $_[0]) {
    Carp::confess "Undefined text";
  }
  my $cp = shift;
  $cp =~ s{([\|\\])}{\\$1}g;
  $cp;
}
sub qtext ($) {
  'q|'.bar_escape($_[0]).'|'
}
sub qqvalue ($) {
  'q'.qtext($_[0]);
}

sub node_type    { $_[1]->[NODE_TYPE] }
sub node_path    { $_[1]->[NODE_PATH] }
sub node_attlist { $_[1]->[NODE_ATTLIST] }

sub node_has_name_list {
  array_of_array($_[1][NODE_PATH]);
}
sub array_of_array {
  my ($path) = @_;
  ref $path eq 'ARRAY'
    && ref $path->[0] eq 'ARRAY'
}

sub node_body {
  shift->node_value(@_);
}

sub node_body_slot {
  my ($self, $node) = @_;
  my $type = $node->[NODE_TYPE];
  if ($type == TYPE_ELEMENT) {
    return $node->[NODE_BODY][NODE_VALUE] if defined $node->[NODE_BODY];
  }
  elsif ($type == TYPE_ATT_NESTED) {
    return $node->[NODE_VALUE];
  }
  else {
    die "Invalid node type for node_body_slot: $type";
  }
}

sub node_unwrap_attlist {
  my ($self, $maybeWrappedAttlist) = @_;
  if ($maybeWrappedAttlist
      and @$maybeWrappedAttlist == 1
      and ref $maybeWrappedAttlist->[0] eq 'ARRAY'
      and @{$maybeWrappedAttlist->[0]} == 1
      and ref $maybeWrappedAttlist->[0][0] eq 'ARRAY') {
    $maybeWrappedAttlist->[0]
  } else {
    $maybeWrappedAttlist;
  }
}

sub node_value {
  my ($self, $node) = @_;
  wantarray ? YATT::Lite::Util::lexpand($node->[NODE_VALUE])
    : $node->[NODE_VALUE];
}

sub node_extract {
  my ($self, $node) = splice @_, 0, 2;
  nx($node, @_);
}

sub node_as_hash {
  my ($self, $node) = @_;

  my $hash;
  foreach my $k (qw(TYPE
                    PATH BODY ATTLIST
                    AELEM_HEAD AELEM_FOOT)) {
    my $i = __PACKAGE__->can("NODE_$k")->();
    next if $#$node <= $i;
    $hash->{lc($k)} = $node->[$i] if defined $node->[$i];
  }
  $hash;
}

#========================================
# Entity entpath related wrappers.
# Each element in entpath has its own structure.

sub entx {
  my ($ent) = @_;
  @{$ent}[ENT_BODY..$#$ent];
}

# list expand if nested.
sub lxnest {
  ref $_[0][0] ? @{$_[0]} : $_[0]
}

#========================================
my $symtab = YATT::Lite::Util::symtab(__PACKAGE__);
our @EXPORT = grep {*{$symtab->{$_}}{CODE}} keys %$symtab;
our @EXPORT_OK = @EXPORT;

require Exporter;
import Exporter qw(import);

1;
