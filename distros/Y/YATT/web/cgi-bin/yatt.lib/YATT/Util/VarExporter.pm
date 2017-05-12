package YATT::Util::VarExporter;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use base qw(YATT::Class::Configurable);
use YATT::Fields qw(pages);

use YATT::Util::Symbol;

sub import {
  my $pack = shift;
  my $callpack = caller;
  my $self = $pack->new(@_);
  $self->register_into($callpack);
  # $callpack に cache を作り、かつ、 import を作る
}

sub new {
  my MY $self = shift->SUPER::new;
  while (my ($page, $vars) = splice @_, 0, 2) {
    $self->{pages}{$page} = $vars;
  }
  $self
}

sub register_into {
  (my MY $self, my $pkg) = @_;
  MY->add_isa($pkg, MY);
  *{globref($pkg, '_CACHE')} = \ $self;
  *{globref($pkg, 'find_vars')} = sub {
    shift->instance->find_vars(@_);
  };
  *{globref($pkg, 'import')} = sub {
    my $callpack = caller;
    my MY $self = shift->instance;
    $self->export_to($callpack, @_);
  };
}

sub instance {
  my ($mypkg) = @_;
  ${*{globref($mypkg, '_CACHE')}{SCALAR}};;
}

sub export_to {
  (my MY $self, my ($destpkg, $page, $failok)) = @_;
  my $vars = $self->find_vars($page ||= $self->page_name)
    or $failok or die "No such page: $page";

  foreach my $name (keys %$vars) {
    my $value = $vars->{$name};
    if ($failok and ref $value and UNIVERSAL::can($value, 'varname')
	and UNIVERSAL::can($value, 'value')) {
      # For $failok case (== from yatt)
      my $glob = globref($destpkg, $value->varname($name));
      (*$glob) = map {ref $_ ? $_ : \ $_} $value->value;
    } else {
      my $glob = globref($destpkg, $name);
      *$glob = do {
	if (not ref $value or ref $value eq 'ARRAY' or ref $value eq 'HASH') {
	  \ $value
	} else {
	  $value;
	}
      };
      # 関数の場合は、関数だけでなく、スカラ変数にも入れておく。
      *$glob = \ $value if ref $value eq 'CODE';
    }
  }
}

sub find_vars {
  my MY $self = ref $_[0] ? shift : shift->instance();
  my ($page, $varname) = @_;
  my $page_vars = $self->{pages}{$page}
    or return;
  unless (defined $varname) {
    $page_vars;
  } else {
    $page_vars->{$varname};
  }
}

# YATT 固有で良いよね。

sub build_scope_for {
  my ($mypkg, $gen, $page) = @_;
  my MY $self = $mypkg->instance;
  my $vars = $self->find_vars($page);
  my %scope;
  foreach my $name (keys %$vars) {
    my $value = $vars->{$name};
    my $type = do {
      unless (ref $value) {
	$gen->t_text;
      } elsif (ref $value eq 'ARRAY') {
	$gen->t_list
      } elsif (ref $value eq 'CODE') {
	$gen->t_code
      } elsif (UNIVERSAL::can($value, 'varname')
	       and UNIVERSAL::can($value, 'value')) {
	$gen->t_html;
      } else {
	$gen->t_scalar;
      }
    };
    $scope{$name} = $type->new(varname => $name);
  }
  \%scope;
}

sub as_html {
  my ($text) = @_;
  bless \ $text, 'YATT::Util::VarExporter::html';
}

package
YATT::Util::VarExporter::html;
use overload '""' => 'value';
sub varname {shift; 'html_'. shift}
sub value {${shift()}}

1;
