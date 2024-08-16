package YATT::Lite::Entities;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use constant DEBUG_IMPORT => $ENV{DEBUG_YATT_IMPORT} // 0;

use mro 'c3';
# XXX: 残念ながら、要整理。

require YATT::Lite::MFields;

use YATT::Lite::Util qw/
                         globref terse_dump url_encode
                         raise_response
                         raise_download
                         raise_psgi_error
                         raise_psgi_dump
                         secure_text_plain
                         psgi_text
			 build_nested_query
                       /;

sub default_export { qw(*YATT) }

#========================================
# Facade を template に見せるための, グローバル変数.
our $YATT;
sub symbol_YATT { return *YATT }
sub YATT { $YATT }
sub DIR { $YATT }

# Factory/Dispatcher/Logger/... を template に見せる
our $SYS;
sub symbol_SYS { return *SYS }
sub SYS { $SYS }
sub SYSTEM { $SYS }
sub SITE { $SYS }

# Connection
our $CON;
sub symbol_CON { return *CON }
sub CON { return $CON }
#========================================

sub import {
  my ($pack, @opts) = @_;
  Carp::carp(scalar caller, " calls $_[0]->import()") if DEBUG_IMPORT;
  @opts = $pack->default_export unless @opts;
  my $callpack = caller;
  my (%opts, @task);
  foreach my $exp (@opts) {
    if (my $sub = $pack->can("define_$exp")) {
      push @task, $sub;
    } elsif ($exp =~ /^-(\w+)$/) {
      $sub = $pack->can("declare_$1")
	or croak "Unknown declarator: $1";
      $sub->($pack, \%opts, $callpack);
    } elsif ($exp =~ /^\*(\w+)$/) {
      $sub = $pack->can("symbol_$1")
	or croak "Can't export symbol $1";
      my $val = $sub->();
      unless (defined $val) {
	croak "Undefined symbol in export spec: $exp";
      }
      *{globref($callpack, $1)} = $val;
    } elsif ($sub = $pack->can($exp)) {
      *{globref($callpack, $exp)} = $sub;
    } else {
      croak "Unknown export spec: $exp";
    }
  }
  foreach my $sub (@task) {
    $sub->($pack, \%opts, $callpack);
  }
}

# use 時に関数を生成したい場合、 define_ZZZ を定義すること。
# サブクラスで新たな symbol を export したい場合、 symbol_ZZZ を定義すること

*declare_as_parent = *declare_as_base; *declare_as_parent = *declare_as_base;

sub declare_as_base {
  my ($myPack, $opts, $callpack) = @_;
  # ckrequire($myPack); # Not needed because $myPack is just used!

  mro::set_mro($callpack, 'c3');

  # Fill $callpack's %FIELDS, by current ISA.
  YATT::Lite::MFields->add_isa_to($callpack, $myPack)
      ->define_fields($callpack);
}

#########################################

sub define_import {
  my ($myPack, $opts, $callpack) = @_;
  *{globref($callpack, 'import')} = \&import;
}

sub define_MY {
  my ($myPack, $opts, $callpack) = @_;
  my $my = globref($callpack, 'MY');
  unless (*{$my}{CODE}) {
    YATT::Lite::Util::define_const($my, $callpack);
  }
}

#========================================
# 組み込み Entity
# Entity 呼び出し時の第一引数は, packageName (つまり文字列) になる。

sub entity_breakpoint {
  require YATT::Lite::Breakpoint;
  &YATT::Lite::Breakpoint::breakpoint();
}

#
# Identity. This helps learning about entity path expression.
#
sub entity_val {
  my ($this, $val) = @_;
  $val;
}

#
# Hiding return value is another important idiom.
#
sub entity_ignore {
  ();
}

sub entity_param {
  shift;
  $CON->param(@_);
}

sub entity_set_param {
  my ($this, $name, $value) = @_;
  $CON->param($name, $value);
  '';
}

sub entity_delete_param {
  shift;
  $CON->delete_param(@_);
}

sub entity_concat {
  my $this = shift;
  join '', @_;
}

sub entity_coalesce {
  my $this = shift;
  foreach my $str (@_) {
    return $str if defined $str;
  }
  '';
}

sub entity_default {
  my $this = shift;
  foreach my $str (@_) {
    return $str if defined $str and $str ne '';
  }
  '';
}

*entity_lsize = *entity_llength; *entity_lsize = *entity_llength;
sub entity_llength {
  my ($this, $list) = @_;
  return undef unless defined $list and ref $list eq 'ARRAY';
  scalar @$list;
}

sub entity_join {
  my ($this, $sep) = splice @_, 0, 2;
  join $sep, grep {defined $_ && $_ ne ''} @_;
}

sub entity_format {
  my ($this, $format) = (shift, shift);
  sprintf $format, @_;
}

sub entity_HTML {
  my $this = shift;
  \ join "", grep {defined $_} @_;
}

sub entity_url_encode {
  my $this = shift;
  join "", map {url_encode($this, $_)} @_;
}

sub entity_alternative {
  my ($this, $value, $list) = @_;
  my @alt = do {
    if (defined $value) {
      grep {$value ne $_} @$list;
    } else {
      grep {defined $_} @$list;
    }
  };
  $alt[0]
}

# XXX: auto url_encode
sub entity_append_params {
  my ($this, $url) = splice @_, 0, 2;
  return $url unless @_;
  require URI;
  require Hash::MultiValue;
  my $uri = URI->new($url);
  my $hmv = Hash::MultiValue->new($uri->query_form);
  my %multi;
  foreach my $item (@_) {
    my ($key, @strs) = @$item;
    $hmv->remove($key) unless $multi{$key}++;
    $hmv->add($key, join("", @strs));
  }
  $uri->query_form($hmv->flatten);
  $uri->as_string;
}

sub entity_dump {
  shift;
  terse_dump(@_);
}

sub entity_can_render {
  my ($this, $wspec) = @_;
  my @nsegs = YATT::Lite::Util::lexpand($wspec);
  my $wname = join _ => map {defined $_ ? $_ : ''} @nsegs;
  $this->can("render_$wname");
}

sub entity_uc { shift; uc($_[0]) }
sub entity_ucfirst { shift; ucfirst($_[0]) }
sub entity_lc { shift; lc($_[0]) }
sub entity_lcfirst { shift; lcfirst($_[0]) }

sub entity_strftime {
  my ($this, $fmt, $sec, $is_uts) = @_;
  $sec //= time;
  require POSIX;
  POSIX::strftime($fmt, $is_uts ? gmtime($sec) : localtime($sec));
}

sub entity_mkhash {
  my ($this, @list) = @_;
  my %hash;
  $hash{$_} = 1 for @list;
  \%hash;
}

sub entity_datetime {
  my ($this, $method, @args) = @_;
  $method //= 'now';
  require DateTime;
  DateTime->$method(@args);
}

sub entity_localtime {
  my ($this, $time) = @_;
  require Time::Piece;
  Time::Piece->localtime($time);
}

sub entity_gmtime {
  my ($this, $time) = @_;
  require Time::Piece;
  Time::Piece->gmtime($time);
}

sub entity_redirect {
  my ($this) = shift;
  $CON->redirect(@_);
}

# &yatt:code_of_entity(redirect);
#
sub entity_code_of_entity {
  shift->entity_code_of(entity => @_);
}

sub entity_code_of {
  my ($this, $prefix, $name) = @_;
  $this->can(join("_", $prefix, $name));
}

sub entity_inspector {
  require Sub::Inspector;
  my ($this, $code) = @_;
  croak "Not a code ref" unless ref $code;
  Sub::Inspector->new($code);
}

sub raise_dump {
  my ($this, @args) = @_;
  $this->raise_response($this->psgi_text(500, terse_dump(@args)));
}

sub entity_raise_dump {shift->raise_dump(@_)}

sub entity_query_string {
  my $this = shift;
  my $args = (@_ == 1 ? $_[0] : +{@_});
  # XXX: check unknown options... statically?! ← entmacro?
  $args->{sep} //= $args->{separator} // ';';
  my $hash = do {
    my $h = $args->{of} // $args->{in} // $CON->as_hash;
    if (my $sub = UNIVERSAL::can($h, 'clone')) {
      $sub->($h);
    } else {
      YATT::Lite::Util::ixhash(%$h);
    }
  };
  if (my $merge = $args->{merge}) {
    $hash->{$_} = $merge->{$_} for keys %$merge;
  }
  if (my $delete = $args->{delete}) {
    delete $hash->{$_} for YATT::Lite::Util::lexpand($delete);
  }
  $this->build_nested_query($hash, $args);
}

sub entity_build_nested_query {
  my ($this, $hash, $args) = @_;
  $this->build_nested_query($hash, $args);
}

use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_entns();

1;
