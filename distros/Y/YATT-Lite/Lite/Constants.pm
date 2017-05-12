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
   , NODE_ => [qw(TYPE BEGIN END LNO PATH REST=VALUE=BODY ATTLIST
		  AELEM_HEAD AELEM_FOOT BODY_BEGIN BODY_END)]
   # node item
   # BODY が必ず配列になるが、代わりに @attlist は配列不要に。 空の [] を pad しなくて済む
   # XXX: <:yatt:else /> とかもあったじゃん！
  );

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

# list expand if nested.
sub lxnest {
  ref $_[0][0] ? @{$_[0]} : $_[0]
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

sub node_body {
  shift->node_value(@_);
}

sub node_body_slot {
  my ($self, $node) = @_;
  given ($node->[NODE_TYPE]) {
    when (TYPE_ELEMENT) {
      return $node->[NODE_BODY][NODE_VALUE] if defined $node->[NODE_BODY];
    }
    when (TYPE_ATT_NESTED) {
      return $node->[NODE_VALUE];
    }
    default {
      die "Invalid node type for node_body_slot: $_";
    }
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

#========================================
my $symtab = YATT::Lite::Util::symtab(__PACKAGE__);
our @EXPORT = grep {*{$symtab->{$_}}{CODE}} keys %$symtab;
our @EXPORT_OK = @EXPORT;

require Exporter;
import Exporter qw(import);

1;
