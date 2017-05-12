# -*- mode: perl; coding: utf-8 -*-
package YATT::Util;
use base qw(Exporter);
use strict;
use warnings qw(FATAL all NONFATAL misc);

use Carp;
use File::Basename;

use YATT::Util::Taint;

BEGIN {
  our @EXPORT_OK
    = qw(&catch
	 &rootname
	 &optional
	 &try_can

	 &require_and
	 &call_type
	 &load_type

	 &default
	 &defined_fmt
	 &coalesce
	 &numeric

	 &lsearch
	 &escape
	 &decode_args
	 &named_attr
	 &attr
	 &resume

	 &checked
	 &checked_eval
	 &terse_dump

	 &add_arg_order_in

	 &copy_array

	 &line_info
	 &needs_line_info
       );
  our @EXPORT = @EXPORT_OK;
}

sub catch (&@) {
  my ($sub, $errorVar) = @_;
  eval { $sub->() };
  $$errorVar = $@;
}

sub rootname {
  push @_, qr{\.\w+$} unless @_ > 1;
  my ($basename, $dirname, $suffix) = fileparse(@_);
  join "", $dirname, $basename;
}

sub optional {
  my ($hash, $member, $key) = @_;
  defined (my $value = $hash->{$member}) or return;
  ($key, $value);
}

sub try_can {
  my ($obj, $method) = splice @_, 0, 2;
  my $sub = $obj->can($method) or return;
  $sub->($obj, @_);
}

sub load_type {
  my ($self, $typealias, $method) = @_;
  my $realclass = $self->$typealias();
  unless ($realclass->can($method || 'new')) {
    eval "require $realclass";
    die $@ if $@;
    if (my $break = YATT->can("break_\l$typealias")) {
      $break->();
    }
  }
  $realclass;
}

sub call_type {
  my ($self, $typealias, $method) = splice @_, 0, 3;
  my $realclass = load_type($self, $typealias, $method);
  $realclass->$method(@_);
}

sub require_and {
  my ($class) = shift;
  my $method = shift;
  unless ($class->can($method)) {
    eval "require $class";
    die $@ if $@;
  }
  $class->$method(@_);
}

sub coalesce {
  foreach my $item (@_) {
    return $item if defined $item;
  }
}
*default = *coalesce; *default = *coalesce;
sub numeric {
  default(@_, 0);
}

sub defined_fmt ($$$) {
  my ($fmt, $value, $default) = @_;
  unless (defined $value) {
    $default;
  } else {
    sprintf $fmt, $value;
  }
}

sub lsearch (&$;$) {
  my ($cmp, $list, $i) = @_;
  $i = 0 unless defined $i;
  foreach (@{$list}[$i .. $#$list]) {
    return $i if $cmp->();
  } continue {
    $i++;
  }
  return
}

my %escape = (qw(< &lt;
		 > &gt;
		 " &quot;
		 & &amp;)
	      , "\'", "&#39;");

our $ESCAPE_UNDEF = '';

sub escape {
  return if wantarray && !@_;
  my @result;
  foreach my $str (@_) {
    push @result, do {
      unless (defined $str) {
	$ESCAPE_UNDEF;
      } elsif (ref $str eq 'SCALAR') {
	# PASS Thru. (Already escaped)
	$$str;
      } elsif (ref($str) =~ /^YATT::Util::/) {
	# Yet another PASS Thru. (Already escaped)
	$$str;
      } else {
	my $copy = $str;
	$copy =~ s{([<>&\"\'])}{$escape{$1}}g;
	$copy;
      }
    };
  }
  wantarray ? @result : $result[0];
}

sub _handle_arg_desc {
  my ($desc) = shift;
  unless (defined $desc->[2]) {
    # '?' case.
    defined $_[0] && $_[0] ne '' ? $_[0] : $desc->[1];
  } elsif (ref $desc->[2]) {
    # extension.
    $desc->[2]->($desc->[1], $_[0]);
  } elsif ($desc->[2] eq '/') {
    defined $_[0] ? $_[0] : $desc->[1];
  } elsif ($desc->[2] eq '|') {
    $_[0] ? $_[0] : $desc->[1];
  } else {
    confess "Invalid arg spec $desc->[2] for $desc->[0]";
  }
}

sub decode_args {
  my ($args) = shift;
  unless (defined $args) {
    map {
      ref $_[$_] eq 'ARRAY' ? $_[$_]->[1] : undef;
    } 0 .. $#_;
  } elsif (ref $args eq 'ARRAY') {
    map {
      unless (ref $_[$_]) {
	$args->[$_];
      } else {
	_handle_arg_desc($_[$_], $args->[$_]);
      }
    } 0 .. $#_;
  } else {
    my @args;
    foreach my $desc (@_) {
      push @args, do {
	unless (ref $desc) {
	  delete $args->{$desc};
	} else {
	  _handle_arg_desc($desc, delete $args->{$desc->[0]});
	}
      };
    }
    if (%$args) {
      my ($pkg, $file, $line) = caller(0);
      die "Invalid args at $file line $line: "
	. join(", ", sort keys %$args) . "\n";
    }
    @args;
  }
}

sub attr {
  my ($attname) = shift;
  my @result = grep {defined $_ && $_ ne ''} @_;
  return '' unless @result;
  bless \(sprintf q{ %s="%s"}, $attname, join ' ', @result)
   , __PACKAGE__ . '::attr';
}

sub named_attr {
  my ($attname, $value, $spc) = @_;
  return '' unless defined $value && $value ne '';
  sprintf('%s%s="%s"', defined $spc ? $spc : ' '
	  , $attname, YATT::escape($value));
}

{
  package YATT::Util::attr;
  use overload qw("" stringify);
  sub stringify {
   ${$_[0]}
  }
}

sub resume {
  my ($CGI, $name, $value, $type) = @_;
  unless (defined $type) {
    ""
  } elsif ($type =~ /^(?:radio|checkbox)$/i) {
    my $cache = $CGI->{'.RESUME_CACHE'}->{$name} ||= do {
      my %cache;
      $cache{$_} = 1 for $CGI->param($name);
      \%cache;
    };
    $cache->{$value} ? "checked" : "";
  } elsif ($type =~ /^(?:|text|password)$/i) {
    named_attr(value => scalar $CGI->param($name), ' ');
  } else {
    # textarea と select option の selected. (multi もあるでよ)
  }
}

sub checked {
  my ($pack, $method, $fmt, $obj) = splice @_, 0, 4;
  my $result = eval {$obj->$method(@_)};
  if ($@) {
    sprintf $fmt, $@;
  } else {
    $result;
  }
}

sub checked_eval {
  # $_[0] is ignored.
  # XXX: local @_ = do { eval $_[1] }; を使えないか？
  die "Undefined expression" unless defined $_[1];
  croak "Tainted expression" if is_tainted($_[1]);
  my @___result;
  &YATT::break_eval;
  if (wantarray) {
    @___result = eval $_[1];
  } else {
    $___result[0] = eval $_[1];
  }
  die $@ if $@;
  wantarray ? @___result : $___result[0];
}

sub terse_dump {
  require Data::Dumper;
  join ", ", map {
    Data::Dumper->new([$_])->Terse(1)->Indent(0)->Dump;
  } @_;
}

sub copy_array {
  my $arg = shift;
  unless (ref $arg) {
    return $arg
  } elsif (ref $arg eq 'ARRAY') {
    [map {copy_array($_)} @$arg]
  } else {
    croak "Not an array ref: $arg";
  }
}

sub add_arg_order_in {
  my $argDict  = $_[0] ||= {};
  my $argOrder = $_[1] ||= [];
  my ($name, $arg) = splice @_, 2;

  croak "Duplicate argument definition: '$name'"
    if defined $argDict->{$name};

  $arg->configure(argno => scalar keys %$argDict, varname => $name);
  push @$argOrder, $name;
  $argDict->{$name} = $arg;

  $arg;
}

sub is_debug {
  my $db = $main::{"DB::"};
  defined $db and defined ${*{$db}{HASH}}{sub};
}

sub no_lineinfo {
  is_debug() and not $ENV{DEBUG_DETAIL};
}

BEGIN {
  # check if DB::sub exists.
  if (no_lineinfo()) {
    *needs_line_info = sub () { 0 };
    *line_info = sub {""};
    require Scalar::Util;
    *put_debuginfo = sub {
      my ($pack, $fn) = splice @_, 0, 2;
      @{$main::{"_<$fn"}} = (undef, map {
	Scalar::Util::dualvar(1, $_);
      } split /(?<=\n)/, $_[0]);
    };
  } else {
    *needs_line_info = sub () { 1 };
    *line_info = sub {
      my ($offset) = @_;
      my ($pack, $file, $line) = caller;
      sprintf(qq|#line %d "%s"\n|, $line + $offset, $file)
    };
    *put_debuginfo = sub () {};
  }
}

1;
