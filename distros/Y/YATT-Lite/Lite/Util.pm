package YATT::Lite::Util;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use constant DEBUG_LOOKUP_PATH => $ENV{DEBUG_YATT_UTIL_LOOKUP_PATH};

use Encode ();

use URI::Escape ();
use Tie::IxHash;

require Scalar::Util;
require File::Spec;

{
  package YATT::Lite::Util;
  use Exporter qw(import);
  BEGIN {
    $INC{'YATT/Lite/Util.pm'} = 1;
    our @EXPORT = qw/numLines coalesce default globref symtab lexpand escape
		     untaint_any ckeval ckrequire untaint_unless_tainted
		     dict_sort terse_dump catch
		     nonempty
		     empty
		     subname
		     pkg2pm
		     globref_default
                     dumpout
		   /;
  }
  use Carp;
  sub numLines {
    croak "undefined value for numLines!" unless defined $_[0];
    $_[0] =~ tr|\n||;
  }
  sub coalesce {
    foreach my $item (@_) {
      return $item if defined $item;
    }
    undef;
  }
  *default = \*coalesce;

  sub nonempty {
    defined $_[0] && $_[0] ne '';
  }
  sub empty {
    not defined $_[0] or $_[0] eq '';
  }

  sub define_const {
    my ($name_or_glob, $value) = @_;
    my $glob = ref $name_or_glob ? $name_or_glob : globref($name_or_glob);
    *$glob = my $const_sub = sub () { $value };
    $const_sub;
  }

  sub globref {
    my ($thing, @name) = @_;
    my $class = ref $thing || $thing;
    no strict 'refs';
    \*{join("::", $class, grep {defined} @name)};
  }
  sub globref_default {
    unless (@_ == 2) {
      croak "Too few arguments";
    }
    my ($globref, $default) = @_;
    my $kind = ref $default;
    *{$globref}{$kind} || do {
      *{$globref} = $default;
      $default;
    };
  }
  sub symtab {
    *{globref(shift, '')}{HASH}
  }
  # XXX: Nice to have look_for_symtab, too.
  sub look_for_globref {
    my ($class, $name) = @_;
    my $symtab = symtab($class);
    return undef unless defined $symtab->{$name};
    globref($class, $name);
  }
  sub call_ns_function_or_default {
    my ($class, $funcname, $default) = @_;
    my $symtab = symtab($class);
    my ($glob, $code);
    if (defined ($glob = $symtab->{$funcname})
        and ($code = *{$glob}{CODE})) {
      $code->()
    } else {
      $default;
    }
  }
  sub ns_filename {
    my ($ns) = @_;
    if (my $fn = call_ns_function_or_default($ns, 'filename')) {
      "$ns \[$fn]"
    } else {
      $ns;
    }
  }
  sub fields_hash {
    my $sym = look_for_globref(shift, 'FIELDS')
      or return undef;
    *{$sym}{HASH};
  }
  # XXX: should be renamed to lhexpand
  sub lexpand {
    # lexpand can be used to counting.
    unless (defined $_[0]) {
      wantarray ? () : 0;
    } elsif (not ref $_[0]) {
      $_[0]
    } elsif (ref $_[0] eq 'ARRAY') {
      @{$_[0]}
    } elsif (ref $_[0] eq 'HASH') {
      %{$_[0]}
    } else {
      wantarray ? () : 0;
    }
  }
  sub lsearch (&@) {
    my $sub = shift;
    my $i = 0;
    foreach (@_) {
      return $i if $sub->($_);
    } continue {$i++}
    return;
  }
  # $fn:e
  sub extname { my $fn = shift; return $1 if $fn =~ s/\.(\w+)$// }
  # $fn:r
  sub rootname { my $fn = shift; $fn =~ s/\.\w+$//; join "", $fn, @_ }
  # $fn:r:t
  sub appname {
    my $fn = shift;
    $fn =~ s/\.\w+$//;
    return $1 if $fn =~ m{(\w+)$};
  }
  sub untaint_any { $_[0] =~ m{.*}s; $& }
  our $DEBUG_INJECT_TAINTED = 0;
  # untaint_unless_tainted($fn, read_file($fn))
  sub untaint_unless_tainted {
    return $_[1] unless ${^TAINT};
    if (defined $_[0] and not Scalar::Util::tainted($_[0])) {
      $DEBUG_INJECT_TAINTED ? $_[1] : untaint_any($_[1]);
    } else {
      $_[1];
    }
  }
  sub ckeval {
    my $__SCRIPT__ = join "", grep {
      defined $_ and Scalar::Util::tainted($_) ? croak "tainted! '$_'" : 1;
    } @_;
    my @__RESULT__;
    if ($] < 5.014) {
      if (wantarray) {
	@__RESULT__ = eval $__SCRIPT__;
      } else {
	$__RESULT__[0] = eval $__SCRIPT__;
      }
      die $@ if $@;
    } else {
      local $@;
      if (wantarray) {
	@__RESULT__ = eval $__SCRIPT__;
      } else {
	$__RESULT__[0] = eval $__SCRIPT__;
      }
      die $@ if $@;
    }
    wantarray ? @__RESULT__ : $__RESULT__[0];
  }
  sub ckrequire {
    ckeval("require $_[0]");
  }

  #
  # permissive_require($modName) allows you to load other module without worrying
  # about their internal use of `eval { require OtherMod }` which misfires the error_handler of
  # YATT::Lite::WebMVC0::DirApp.
  #
  sub permissive_require {
    local ($SIG{__DIE__}, $SIG{__WARN__});
    ckrequire($_[0]);
  }

  use Scalar::Util qw(refaddr);
  sub cached_in {
    my ($dir, $dict, $nameSpec, $sys, $mark, $loader, $refresher) = @_;
    my ($name) = lexpand($nameSpec);
    if (not exists $dict->{$name}) {
      my $item = $dict->{$name} = $loader ? $loader->($dir, $sys, $nameSpec)
	: $dir->load($sys, $nameSpec);
      $mark->{refaddr($item)} = 1 if $item and $mark;
      $item;
    } else {
      my $item = $dict->{$name};
      unless ($item and ref $item
	      and (not $mark or not $mark->{refaddr($item)}++)) {
	# nop
      } elsif ($refresher) {
	$refresher->($item, $sys, $nameSpec)
      } elsif (my $sub = UNIVERSAL::can($item, 'refresh')) {
	$sub->($item, $sys);
      }
      $item;
    }
  }

  sub split_path {
    my ($path, $startDir, $cut_depth, $default_ext) = @_;
    # $startDir is $app_root.
    # $doc_root should resides under $app_root.
    $cut_depth //= 1;
    $default_ext //= "yatt";
    $startDir =~ s,/+$,,;
    unless ($path =~ m{^\Q$startDir\E}gxs) {
      die "Can't split_path: prefix mismatch: $startDir vs $path";
    }

    my ($dir, $pos, $file) = ($startDir, pos($path));
    # *DO NOT* initialize $file. This loop relies on undefined-ness of $file.
    while ($path =~ m{\G/+([^/]*)}gcxs and -e "$dir/$1" and not defined $file) {
      if (-d _) {
	$dir .= "/$1";
      } else {
	$file = $1;
	# *DO NOT* last. To match one more time.
      }
    } continue {
      $pos = pos($path);
    }

    $dir .= "/" if $dir !~ m{/$};
    my $subpath = substr($path, $pos);
    if (not defined $file) {
      if ($subpath =~ m{^/(\w+)(?:/|$)} and -e "$dir/$1.$default_ext") {
	$subpath = substr($subpath, 1+length $1);
	$file = "$1.$default_ext";
      } elsif (-e "$dir/index.$default_ext") {
	# index.yatt should subsume all subpath.
      } elsif ($subpath =~ s{^/([^/]+)$}{}) {
	# Note: Actually, $file is not accesible in this case.
	# This is just for better error diag.
	$file = $1;
      }
    }

    my $loc = substr($dir, length($startDir));
    while ($cut_depth-- > 0) {
      $loc =~ s,^/[^/]+,,
	or croak "Can't cut path location: $loc";
      $startDir .= $&;
    }

    ($startDir
     , $loc
     , $file // ''
     , $subpath
     , (not defined $file)
    );
  }

  sub lookup_dir {
    my ($loc, $dirlist) = @_;
    $loc =~ s{^/*}{/};
    foreach my $dir (@$dirlist) {
      my $real = "$dir$loc";
      next unless -d $real;
      return wantarray ? ($real, $dir) : $real;
    }
  }

  sub lookup_path {
    my ($path_info, $dirlist, $index_name, $ext_list, $use_subpath) = @_;
    $index_name //= 'index';
    my ($ext1, @ext) = lexpand($ext_list);
    $ext1 //= "yatt";
    my $ixfn = $index_name . ".$ext1";
    my @dirlist = grep {defined $_ and -d $_} @$dirlist;
    print STDERR "dirlist" => terse_dump(@dirlist), "\n" if DEBUG_LOOKUP_PATH;
    my $pi = normalize_path($path_info);
    my ($loc, $cur, $ext) = ("", "");
  DIG:
    while ($pi =~ s{^/+([^/]+)}{}) {
      $cur = $1;
      $ext = ($cur =~ s/(\.[^\.]+)$// ? $1 : undef);
      print STDERR terse_dump(cur => $cur, ext => $ext), "\n" if DEBUG_LOOKUP_PATH;
      foreach my $dir (@dirlist) {
	my $base = "$dir$loc/$cur";
	if (defined $ext and -r "$base$ext") {
	  # If extension is specified and it is readable, use it.
	  return ($dir, "$loc/", "$cur$ext", $pi);
	} elsif ($pi =~ m{^/} and -d $base) {
	  # path_info has '/' and directory exists.
	  next; # candidate
	} else {
          foreach my $want_ext ($ext1, @ext) {
            if (-r (my $fn = "$base.$want_ext")) {
              return ($dir, "$loc/", "$cur.$want_ext", $pi);
            }
          }
          if ($use_subpath
              and -r (my $alt = "$dir$loc/$ixfn")) {
            $ext //= "";
            return ($dir, "$loc/", $ixfn, "/$cur$ext$pi", 1);
          } else {
            # Neither dir nor $cur$want_ext exists, it should be ignored.
            undef $dir;
          }
        }
      }
    } continue {
      $loc .= "/$cur";
      print STDERR terse_dump(continuing => $loc), "\n" if DEBUG_LOOKUP_PATH;
      @dirlist = grep {defined} @dirlist;
    }
      print STDERR terse_dump('end_of_loop'), "\n" if DEBUG_LOOKUP_PATH;

    return unless $pi =~ m{^/+$};

    foreach my $dir (@dirlist) {
      next unless -r "$dir$loc/$ixfn";
      return ($dir, "$loc/", "$ixfn", "", 1);
    }

      print STDERR terse_dump('at_last'), "\n" if DEBUG_LOOKUP_PATH;
    return;
  }

  # Shamelessly stolen (with slight mod) from Dancer2::FileUtils::normalize_path
  our $seqregex = qr{
                      [^/]*       # anything without a slash
                      /\.\.(/|\z) # that is accompanied by two dots as such
                  }x;
  sub normalize_path {

    # this is a revised version of what is described in
    # http://www.linuxjournal.com/content/normalizing-path-names-bash
    # by Mitch Frazier
    my $path = shift or return;

    $path =~ s{/\./}{/}g;
    1 while $path =~ s{$seqregex}{};

    #see https://rt.cpan.org/Public/Bug/Display.html?id=80077
    $path =~ s{^//}{/};
    return $path;
  }


  sub trim_common_suffix_from {
    @_ == 2 or Carp::croak "trim_common_suffix_from(FROM, COMPARE)";
    my @from = File::Spec->splitdir($_[0]);
    my @comp = File::Spec->splitdir($_[1]);
    while (@from and @comp and $from[-1] eq $comp[-1]) {
      pop @from; pop @comp;
    }
    File::Spec->catfile(@from);
  }

  sub dict_order {
    my ($a, $b, $start) = @_;
    $start = 1 unless defined $start;
    my ($result, $i) = (0);
    for ($i = $start; $i <= $#$a and $i <= $#$b; $i++) {
      if ($a->[$i] =~ /^\d/ and $b->[$i] =~ /^\d/) {
	$result = $a->[$i] <=> $b->[$i];
      } else {
	$result = $a->[$i] cmp $b->[$i];
      }
      return $result unless $result == 0;
    }
    return $#$a <=> $#$b;
  }

  # a   => ['a', 'a']
  # q1a => ['q1a', 'q', 1, 'a']
  # q11b => ['q11b', 'q', 11, 'b']
  sub dict_sort (@) {
    map {$_->[0]} sort {dict_order($a,$b)} map {[$_, split /(\d+)/]} @_;
  }
  sub dict_sort_by_nth ($@) {
    my $nth = shift;
    map {$_->[0]}
    sort {dict_order($a,$b)}
    map {[$_, split /(\d+)/, $$_[$nth]]} @_;
  }

  sub combination (@) {
    my $comb; $comb = sub {
      my $prefix = shift;
      return $prefix unless @_;
      my ($list, @rest) = @_;
      if (@rest) {
        map {$comb->([@$prefix, $_], @rest)} @$list;
      } else {
        map {[@$prefix, $_]} @$list;
      }
    };
    $comb->([], @_);
  }

  sub captured (&;$) {
    my ($code, $keep_utf8) = @_;
    my $buffer = "";
    {
      open my $fh, '>:utf8', \ $buffer
        or die "Can't create capture buf:$!";
      $code->($fh);
    }
    if ($keep_utf8 // 1) {
      Encode::_utf8_on($buffer);
    }
    $buffer;
  }

  sub terse_dump {
    require Data::Dumper;
    join ", ", map {
      Data::Dumper->new([$_])->Terse(1)->Indent(0)->Sortkeys(1)->Dump;
    } @_;
  }
  sub indented_dump {
    require Data::Dumper;
    join ", ", map {
      Data::Dumper->new([$_])->Terse(1)->Indent(1)->Sortkeys(1)->Dump;
    } @_;
  }

  sub is_debugging {
    my $symtab = $main::{'DB::'} or return 0;
    defined ${*{$symtab}{HASH}}{cmd_b}
  }

  sub catch (&) {
    my ($sub) = @_;
    local $@ = '';
    eval { $sub->() };
    $@;
  }
}

sub add_entity_into {
  my ($pack, $destns, $name, $sub, $allow_ignore) = @_;
  my $longname = join "::", $destns, "entity_$name";
  my $glob = globref($destns, "entity_$name");
  if (*{$glob}{CODE} and $allow_ignore) {
    return;
  }
  subname($longname, $sub);
  *$glob = $sub;
}

sub dofile_in {
  my ($pkg, $file) = @_;
  unless (-e $file) {
    croak "No such file: $file\n";
  } elsif (not -r _) {
    croak "Can't read file: $file\n";
  }
  ckeval("package $pkg; my \$result = do '$file'; die \$\@ if \$\@; \$result");
}

sub compile_file_in {
  my ($pkg, $file) = @_;
  if (-d $file) {
    croak "file '$file' is a directory!";
  }
  my $sub = dofile_in($pkg, $file);
  unless (defined $sub and ref $sub eq 'CODE') {
    die "file '$file' should return CODE (but not)!\n";
  }
  $sub;
}


BEGIN {
  my %escape = (qw(< &lt;
		   > &gt;
		   --> --&gt;
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
	} elsif (not ref $str) {
	  my $copy = $str;
	  $copy =~ s{([<>&\"\'])}{$escape{$1}}g;
	  $copy;
	} elsif (ref $str eq 'SCALAR') {
	  # PASS Thru. (Already escaped)
	  $$str // $ESCAPE_UNDEF; # fail safe
	} elsif (_is_escapable($str)) {
	  $str->as_escaped;
	} elsif (my $sub = UNIVERSAL::can($str, 'cf_pairs')) {
	  ref($str).'->new('.(join(", ", map {
	    my ($k, $v) = @$_;
	    "$k => " . do {
	      my $esc = escape($v);
	      if (not defined $esc) {
		'undef'
	      } elsif ($esc eq '') {
		"''"
	      } else {
		$esc;
	      }
	    };
	  } $sub->($str))).')';
	} else {
	  # XXX: Is this secure???
	  # XXX: Should be JSON?
	  my $copy = indented_dump($str);
	  $copy =~ s{([<\"]|-->)}{$escape{$1}}g; # XXX: Minimum. May be insecure.
	  $copy;
	}
      };
    }
    wantarray ? @result : $result[0];
  }
}

# XXX: Since method name "as_escaped" conflicts with CGen::Perl->as_escaped,
# We need a informational class for everything safely escapable
# via "as_escape()"
{
  sub _is_escapable {
    UNIVERSAL::isa($_[0], 'YATT::Lite::Util::escapable');
  }
  package
    YATT::Lite::Util::escapable;
}

{
  package
    YATT::Lite::Util::named_attr;
  BEGIN {our @ISA = ('YATT::Lite::Util::escapable')};
  use overload qw("" as_string);
  sub as_string {
    shift->[-1];
  }
  sub as_escaped {
    sprintf q{ %s="%s"}, $_[0][0], $_[0][1];
  }
}

sub named_attr {
  my $attname = shift;
  my @result = grep {defined $_ && $_ ne ''} @_;
  return '' unless @result;
  bless [$attname, join ' ', map {escape($_)} @result]
    , 'YATT::Lite::Util::named_attr';
}

{
  # XXX: These functions are deprecated. Use att_value_in() instead.

  sub value_checked  { _value_checked($_[0], $_[1], checked => '') }
  sub value_selected { _value_checked($_[0], $_[1], selected => '') }

  sub _value_checked {
    my ($value, $hash, $then, $else) = @_;
    sprintf q|value="%s"%s|, escape($value)
      , _if_checked($hash, $value, $then, $else);
  }

  sub _if_checked {
    my ($in, $value, $then, $else) = @_;
    $else //= '';
    return $else unless defined $in;
    if (ref $in ? $in->{$value // ''} : ($in eq $value)) {
      " $then"
    } else {
      $else;
    }
  }
}

{
  our %input_spec = (select => [0, 0]
		     , radio => [1, 0]
		     , checkbox => [2, 1]);
  sub att_value_in {
    my ($in, $type, $name, $formal_value, $as_value, $is_default) = @_;
    defined (my $spec = $input_spec{$type})
      or croak "Unknown type: $type";

    my ($typeid, $has_sfx) = @$spec;

    unless (defined $name and $name ne '') {
      croak "name is empty";
    }

    unless (defined $formal_value and $formal_value ne '') {
      croak "value is empty";
    }

    my @res;

    if ($type and $typeid) {
      push @res, qq|type="$type"|;
    }

    if ($typeid) {
      my $sfx = $has_sfx ? '['.escape($formal_value).']' : '';
      push @res, qq|name="@{[escape($name)]}$sfx"|;
    }

    if (not $has_sfx) {
      # select
      push @res, qq|value="@{[escape($formal_value)]}"|;
    } elsif ($as_value) {
      # checkbox/radio, with explicit value
      push @res, qq|value="@{[escape($as_value)]}"|;
    }

    if (find_value_in($in, $name, $formal_value, $is_default)) {
      push @res, $typeid ? "checked" : "selected";
    }

    join(" ", @res);
  }

  sub find_value_in {
    my ($in, $name, $formal_value, $is_default) = @_;

    if (ref $in eq 'HASH') {
      return $in->{$formal_value};
    }

    my $actual_value = do {
      if (my $sub = UNIVERSAL::can($in, "param")) {
	$sub->($in, $name);
      } else {
	undef;
      }
    };

    if (not defined $actual_value) {
      $is_default ? 1 : 0
    } elsif (not ref $actual_value) {
      $actual_value eq $formal_value
    } elsif (ref $actual_value eq 'HASH') {
      $actual_value->{$formal_value};
    } elsif (ref $actual_value eq 'ARRAY') {
      defined lsearch {$_ eq $formal_value} @$actual_value
    } else {
      undef
    }
  }
}

# Verbatimly stolen from CGI::Simple
# XXX: not used?
sub url_decode {
  my ( $self, $decode ) = @_;
  return () unless defined $decode;
  $decode =~ tr/+/ /;
  $decode =~ s/%([a-fA-F0-9]{2})/ pack "C", hex $1 /eg;
  # XXX: should set utf8 flag too?
  return $decode;
}

sub url_encode {
  my ( $self, $encode ) = @_;
  return () unless defined $encode;

  if (Encode::is_utf8($encode)) {
    $encode = Encode::encode_utf8($encode);
  }

  # XXX: Forward slash (and ':') is allowed, for cleaner url. This may break...
  $encode
    =~ s{([^A-Za-z0-9\-_.!~*'() /:])}{ uc sprintf "%%%02x",ord $1 }eg;
  $encode =~ tr/ /+/;
  return $encode;
}

sub url_encode_kv {
  my ($self, $k, $v) = @_;
  url_encode($self, $k) . '=' . url_encode($self, $v);
}

sub encode_query {
  my ($self, $param, $sep) = @_;
#  require URI;
#  my $url = URI->new('http:');
#  $url->query_form($item->{cf_PARAM});
#  $url->query;
  return $param unless ref $param;
  join $sep // ';', do {
    if (ref $param eq 'HASH') {
      map {
	url_encode_kv($self, $_, $param->{$_});
      } keys %$param
    } else {
      my @param = @$param;
      my @res;
      while (my ($k, $v) = splice @param, 0, 2) {
	my $ek = url_encode($self, $k);
	push @res, $ek . '='. (url_encode($self, $_) // '')
	  for ref $v ? @$v : $v;
      }
      @res;
    }
  };
}

sub callerinfo {
  my ($pkg, $file, $line) = caller(shift // 1);
  (file => $file, line => $line);
}

sub ostream {
  my $fn = ref $_[0] ? $_[0] : \ ($_[0] //= "");
  open my $fh, '>' . ($_[1] // ''), $fn
    or die "Can't create output memory stream: $!";
  $fh;
}

sub read_file {
  my ($fn, $layer) = @_;
  open my $fh, '<' . ($layer // ''), $fn or die "Can't open '$fn': $!";
  local $/;
  scalar <$fh>;
}

sub dispatch_all {
  my ($this, $con, $prefix, $argSpec) = splice @_, 0, 4;
  my ($nargs, @preargs) = ref $argSpec ? @$argSpec : $argSpec;
  my @queue;
  foreach my $item (@_) {
    if (ref $item) {
      print {$con} escape(splice @queue) if @queue;
      my ($wname, @args) = @$item;
      my $sub = $this->can('render_' . $prefix . $wname)
	or croak "Can't find widget '$wname' in dispatch";
      $sub->($this, $con, @preargs, splice(@args, 0, $nargs // 0), \@args);
    } else {
      push @queue, $item;
    }
  }
  print {$con} escape(@queue) if @queue;
}

sub dispatch_one {
  my ($this, $con, $prefix, $nargs, $item) = @_;
  if (ref $item) {
    my ($wname, @args) = @$item;
    my $sub = $this->can('render_' . $prefix . $wname)
      or croak "Can't find widget '$wname' in dispatch";
    $sub->($this, $con, splice(@args, 0, $nargs // 0), \@args);
  } else {
    print {$con} escape($item);
  }
}

sub con_error {
  my ($con, $err, @args) = @_;
  if ($con->can("raise") and my $sub = $con->can("error")) {
    $sub->($con, $err, @args)
  } else {
    sprintf $err, @args;
  }
}

sub safe_render {
  my ($this, $con, $wspec, @args) = @_;
  my @nsegs = lexpand($wspec);
  my $wname = join _ => map {defined $_ ? $_ : ''} @nsegs;
  my $sub = $this->can("render_$wname")
    or die con_error($con, "Can't find widget '%s'", $wname);
  $sub->($this, $con, @args);
}

sub mk_http_status {
  my ($code) = @_;
  require HTTP::Status;

  my $message = HTTP::Status::status_message($code);
  "Status: $code $message\015\012";
}

sub list_isa {
  my ($pack, $all) = @_;
  my $symtab = symtab($pack);
  my $sym = $symtab->{ISA} or return;
  my $isa = *{$sym}{ARRAY} or return;
  return @$isa unless $all;
  map {
    [$_, list_isa($_, $all)];
  } @$isa;
}

sub set_inc {
  my ($pkg, $val) = @_;
  $pkg =~ s|::|/|g;
  $INC{$pkg.'.pm'} = $val || 1;
  # $INC{$pkg.'.pmc'} = $val || 1;
  $_[1];
}

sub try_invoke {
  my $obj = shift;
  my ($method, @args) = lexpand(shift);
  my $default = shift;
  if (defined $obj
      and my $sub = UNIVERSAL::can($obj, $method)) {
    $sub->($obj, @args);
  } else {
    wantarray ? () : $default;
  }
}

sub NIMPL {
  my ($pack, $file, $line, $sub, $hasargs) = caller($_[0] // 1);
  croak "Not implemented call of '$sub'";
}

sub shallow_copy {
  if (ref $_[0] eq 'HASH') {
    +{%{$_[0]}};
  } elsif (ref $_[0] eq 'ARRAY') {
    +[@{$_[0]}];
  } elsif (not ref $_[0]) {
    my $copy = $_[0];
  } elsif ($_[1]) {
    # Pass thru unknown refs if 2nd arg is true.
    $_[0];
  } else {
    croak "Unsupported data type for shallow_copy: " . ref $_[0];
  }
}

if (not is_debugging() or catch {require Sub::Name}) {
  *subname = sub { my ($name, $sub) = @_; $sub }
} else {
  *subname = *Sub::Name::subname;
}

sub incr_opt {
  my ($key, $list) = @_;
  my $hash = do {
    if (@$list and defined $list->[0] and ref $list->[0] eq 'HASH') {
      shift @$list;
    } else {
      +{}
    }
  };
  $hash->{$key}++;
  $hash;
}

sub num_is_ge {
  defined $_[0] and not ref $_[0] and $_[0] ne ''
    and $_[0] =~ /^\d+$/ and $& >= $_[1];
}

# Order preserving unique.
sub unique (@) {
  my %dup;
  map {$dup{$_}++ ? () : $_} @_;
}

sub secure_text_plain {
  shift;
  ("Content-type" => "text/plain; charset=utf-8"
   , "X-Content-Type-Options" => "nosniff"  # To protect IE8~ from XSS.
   );
}

#========================================

# Just a wrapper (and hook) for die. $self is ignored.
sub raise_response {
  my ($self, $response) = @_;
  die $response;
}

#
# $this->raise_download($fileName, $bytesOrBytesRef, ?[@header]?)
#
sub raise_download {
  my $this = $_[0];
  my $filename = $_[1];
  my $bytesRef = ref $_[2] eq 'SCALAR' ? $_[2] : \$_[2];
  my @header = ("Content-type" => qq{application/octet-stream},
                , "Content-Length" => length($$bytesRef));
  push @header, "Content-Disposition" => qq{attachment; filename="$filename"}
    if defined $filename and $filename ne '';
  if (defined $_[3] and ref $_[3]) {
    push @header, lexpand($_[3]);
  }

  $this->raise_response([200, \@header, [$$bytesRef]]);
}

#========================================

foreach my $what (qw(error text dump)) {
  my $actual = "psgi_$what";
  my $sub = __PACKAGE__->can($actual);
  my $method = "raise_$actual";
  *{globref($method)} = sub {
    my $self = shift;
    $self->raise_response($sub->($self, @_));
  };
}

sub psgi_error {
  my ($self, $status, $msg, @rest) = @_;
  my $escaped = escape($msg);
  Encode::_utf8_off($escaped);
  return [$status, [$self->secure_text_plain, @rest]
          , [$escaped
             , $msg =~ /\n\z/ ? () : "\n" ]];
}

sub psgi_text {
  my ($self, $statusAndHeader, @args) = @_;
  my ($status, @header) = ref $statusAndHeader ? @$statusAndHeader : $statusAndHeader;
  return [$status, [$self->secure_text_plain, @header], \@args];
}

sub psgi_dump {
  my $self = shift;
  [200
   , [$self->secure_text_plain]
   , [join("\n", map {terse_dump($_)} @_)."\n"]];
}

sub dumpout (@) {
  __PACKAGE__->raise_psgi_dump(@_);
}

sub ixhash {
  tie my %hash, 'Tie::IxHash', @_;
  \%hash;
}

# Ported from: Rack::Utils.parse_nested_query
sub parse_nested_query {
  return {} unless defined $_[0] and $_[0] ne '';
  my ($enc) = $_[1];
  my $params = $_[2] // ixhash();
  if (ref $_[0]) {
    my @pairs = map {$enc ? map(Encode::decode($enc, $_), @$_) : @$_}
      ref $_[0] eq 'ARRAY' ? $_[0] : [%{$_[0]}];
    while (my ($k, $v) = splice @pairs, 0, 2) {
      normalize_params($params, $k, $v);
    }
  } else {
    foreach my $p (split /[;&]/, $_[0]) {
      my ($k, $v) = map {
	s/\+/ /g;
	my $raw = URI::Escape::uri_unescape($_);
	$enc ? Encode::decode($enc, $raw) : $raw;
      } split /=/, $p, 2;
      normalize_params($params, $k, $v) if defined $k;
    }
  }
  $params;
}

sub normalize_params {
  my ($params, $name, $v) = @_;
  if ($name eq '[]' and defined $v) {
    return [$v];
  }
  my ($k) = $name =~ m(\A[\[\]]*([^\[\]]+)\]*)
    or return;

  my $after = substr($name, length $&);

  if ($after eq '') {
    $params->{$k} = $v;
  } elsif ($after eq "[]") {
    my $item = $params->{$k} //= [];
    croak "expected ARRAY (got ".(ref $item || 'String').") for param `$k'"
      unless ref $item eq 'ARRAY';
    push @$item, $v;
  } elsif ($after =~ m(^\[\]\[([^\[\]]+)\]$) or $after =~ m(^\[\](.+)$)) {
    my $child_key = $1;
    my $item = $params->{$k} //= [];
    croak "expected ARRAY (got ".(ref $item || 'String').") for param `$k'"
      unless ref $item eq 'ARRAY';
    if (@$item and ref $item->[-1] eq 'HASH'
	and not exists $item->[-1]->{$child_key}) {
      normalize_params($item->[-1], $child_key, $v);
    } else {
      push @$item, normalize_params(ixhash(), $child_key, $v);
    }
  } else {
    my $item = $params->{$k} //= ixhash();
    croak "expected HASH (got ".(ref $item || 'String').") for param `$k'"
      unless ref $item eq 'HASH';
    $params->{$k} = normalize_params($item, $after, $v);
  }

  $params;
}

# Ported (with API modification) from: Rack::Utils.build_nested_query
sub build_nested_query {
  my ($self, $hash, $opts) = @_;
  my $ignore = ref $opts->{ignore} eq 'HASH'
    ? $opts->{ignore}
    : +{map {$_ => 1} @{$opts->{ignore}}};
  join $opts->{sep} // '&'
    , map {
      if ($ignore and $ignore->{$_}) {
        ()
      } else {
	my $v = $hash->{$_};
	my $k = url_encode($self, $_); # URI::Escape::uri_escape does too much.
	$k =~ tr/ /+/;
        build_nested_query_value($self, $v, $k);
      }
    } keys %$hash;
}

sub build_nested_query_value {
  my ($self, $value, $prefix) = @_;
  if (not defined $value) {
    $prefix;
  } elsif (ref $value eq 'ARRAY') {
    map {
      build_nested_query_value($self, $_, $prefix."[]");
    } @$value;
  } elsif (ref $value eq 'HASH' or UNIVERSAL::can($value, 'keys')) {
    map {
      my $escaped = URI::Escape::uri_escape_utf8($_);
      my $key = $prefix ? $prefix."[$escaped]" : $escaped;
      $key =~ tr/ /+/;
      build_nested_query_value($self, $value->{$_}, $key);
    } keys %$value;
  } elsif (not defined $prefix) {
    Carp::croak "value must be a Hash: ". terse_dump($value);
  } else {
    $prefix."=".URI::Escape::uri_escape_utf8($value);
  }
}

sub pkg2pm {
  my ($pack) = @_;
  $pack =~ s{::|'}{/}g;
  "$pack.pm";
}

sub dputs {
  (undef, undef, my $line) = caller(0);
  (undef, undef, undef, my $func) = caller(1);
  print STDERR "# $func $line: ", (map {
    if (defined $_ and not ref $_) {
      $_
    } else {
      terse_dump($_)
    }
  } @_), "\n";
}

sub is_done {
  defined $_[0] and ref $_[0] eq 'SCALAR' and not ref ${$_[0]}
    and ${$_[0]} eq 'DONE';
}

sub rewind {
  if ($_[0]->can("rewind")) {
    $_[0]->rewind
  } else {
    seek $_[0], 0, 0;
    truncate $_[0], 0;
  }
}

sub merge_hash_renaming (&@) {
  my ($code, $base, @overlay) = @_;
  my $result = +{%$base};
  foreach my $hash (@overlay) {
    local $_;
    foreach (keys %$hash) {
      if ($code) {
        my ($renamed) = $code->($_)
          or next;
        $result->{$renamed} = $hash->{$_};
      } else {
        $result->{$_} = $hash->{$_};
      }
    }
  }
  $result;
}

sub trimleft_length {
  shift;
  return $_[0] unless length $_[0];
  substr($_[0], length($_[1]));
}

sub reencode_malformed_utf8 {
  my ($str, $fallback_flag) = @_;
  Encode::_utf8_off($str);
  my $bytes = Encode::decode_utf8($str, $fallback_flag // Encode::FB_XMLCREF);
  Encode::_utf8_on($bytes);
  $bytes;
}

sub get_entity_symbol {
  my ($pack, $entns, $entity_name) = @_;
  my $symbol_name = join("_", entity => $entity_name);
  look_for_globref($entns, $symbol_name);
}

#
# to put all functions into @EXPORT_OK.
#
{
  our @EXPORT_OK = qw(define_const);
  my $symtab = symtab(__PACKAGE__);
  foreach my $name (grep {/^[a-z]/} keys %$symtab) {
    my $glob = $symtab->{$name};
    next unless *{$glob}{CODE};
    push @EXPORT_OK, $name;
  }
}

1;
