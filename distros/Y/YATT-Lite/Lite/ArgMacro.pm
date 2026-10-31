package YATT::Lite::ArgMacro;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

sub MY () {__PACKAGE__}

use YATT::Lite::Util qw(globref define_const);
use YATT::Lite::Constants;

#
# package MyApp::ArgMacro::Enum;
# use YATT::Lite::ArgMacro
#   out => [qw(list=list)],
#   in  => ['first=value/0', 'last=value!'];
#
# sub on_expand {
#   (my MY $macro, my CGen $cgen, my Args $args, my Vars $vars) = @_;
#   my Result $result = {};
#   ...
#   $result;
# }
#
sub import {
  my ($pack, %opts) = @_;
  # Subclasses (ie. argmacro modules) inherit this import. Using them
  # must not redefine anything.
  return if $pack ne MY;
  my $callpack = caller;
  MY->declare_into($callpack, %opts);
}

sub declare_into {
  my ($pack, $destpkg, %opts) = @_;

  my $out = delete $opts{out}
    or croak "ArgMacro requires 'out' (list of output args)";
  my $in = delete $opts{in} // [];
  my $refer = delete $opts{refer} // [];
  if (keys %opts) {
    croak "Unknown options for ArgMacro: ".join(", ", sort keys %opts);
  }

  # refer は widget 側で宣言する引数を参照するだけなので、名前のみ
  foreach my $name (@$refer) {
    croak "ArgMacro refer accepts only arg names: $name"
      unless $name =~ /^\w+\z/;
  }

  my $spec = +{
    out => [map {$pack->parse_arg_spec($_)} @$out],
    in  => [map {$pack->parse_arg_spec($_)} @$in],
    refer => [@$refer],
  };
  croak "ArgMacro requires at least one output arg" unless @{$spec->{out}};

  my %seen;
  foreach my $name ((map {$_->[0]} @{$spec->{out}}, @{$spec->{in}})
                    , @{$spec->{refer}}) {
    croak "Duplicate arg name in ArgMacro: $name" if $seen{$name}++;
  }

  require YATT::Lite::MFields;
  YATT::Lite::MFields->add_isa_to($destpkg, MY);

  # my CGen $cgen 等の型付き lexical のため、型のクラスを先に読み込んでおく
  # (perl -c で単独コンパイルできるように)
  require YATT::Lite::CGen::Perl;
  require YATT::Lite::Core;

  my @in_names = ((map {$_->[0]} @{$spec->{in}}), @{$spec->{refer}});
  my @out_names = map {$_->[0]} @{$spec->{out}};

  my %types = (
    MY     => $destpkg,
    Args   => $pack->define_record_class("${destpkg}::Args", @in_names),
    Vars   => $pack->define_record_class("${destpkg}::Vars", @in_names),
    Result => $pack->define_record_class("${destpkg}::Result", @out_names),
    CGen   => 'YATT::Lite::CGen::Perl',
    ArgMacro => 'YATT::Lite::Core::ArgMacro',
  );
  foreach my $name (sort keys %types) {
    my $glob = globref($destpkg, $name);
    next if *{$glob}{CODE};
    define_const($glob, $types{$name});
  }

  define_const(globref($destpkg, 'macro_spec'), $spec);

  $destpkg;
}

# "name", "name=type", "name=type/default" ... (same as argument spec
# of <!yatt:argmacro>). Returns [name, spec_or_undef].
sub parse_arg_spec {
  my ($pack, $item) = @_;
  my ($name, $desc) = ref $item ? @$item : split /=/, $item, 2;
  unless (defined $name and $name =~ /^[[:alpha:]_]\w*\z/) {
    croak "Invalid arg name in ArgMacro: ".($name // '(undef)');
  }
  if (defined $desc) {
    my ($type) = split m{[|/?!:]}, $desc, 2;
    if (defined $type and $type =~ /^(?:code|delegate)\z/
        or $desc =~ /^\[/) {
      croak "ArgMacro arg type '$desc' is not supported in modules: $name";
    }
  }
  [$name, $desc];
}

# Defines a class whose %FIELDS is exactly @names. This enables compile time
# checking of field names on typed lexicals: my Result $r; $r->{typo} dies.
# Idempotent, so templates can be recompiled.
sub define_record_class {
  my ($pack, $class, @names) = @_;
  my $glob = globref($class, 'FIELDS');
  %{*$glob} = map {$_ => 1} @names;
  my $new = globref($class, 'new');
  *$new = sub { require fields; fields::new(ref $_[0] || $_[0]) }
    unless *{$new}{CODE};
  $class;
}

#========================================
# Bridge to YATT::Lite::Core::ArgMacro

sub as_argmacro_part {
  my ($class, $parser, $name, $ns) = @_;

  my $spec = $class->macro_spec;
  $ns //= $parser->primary_ns;

  # Default values (eg. value/0) are parsed as text with entities,
  # which needs position info of the parser.
  local $parser->{_startpos} = 0;
  local $parser->{_curpos} = 0;
  local $parser->{_startln} = 1;
  local $parser->{_endln} = 1;

  my $argmacro = $parser->ArgMacro->new(
    name => $name, kind => 'argmacro', decl => 'argmacro',
    namespace => $ns,
    output_args => [map {$class->_mk_arg_node(@$_)} @{$spec->{out}}],
    refer_names => [@{$spec->{refer}}],
  );

  $parser->add_args($argmacro, map {$class->_mk_arg_node(@$_)} @{$spec->{in}});

  $argmacro->{_on_expand} = sub {
    my ($cgen, $args, $vars, $macro, $node) = @_;
    my $result = $class->on_expand($cgen, $args, $vars, $macro, $node);
    unless (ref $result eq 'HASH' or UNIVERSAL::isa($result, 'HASH')) {
      croak "$class->on_expand must return a hash";
    }
    $result;
  };

  require YATT::Lite::CGen::ArgMacro;
  $argmacro->{_on_declare}
    = YATT::Lite::CGen::ArgMacro->make_on_declare($argmacro);

  $argmacro;
}

sub _mk_arg_node {
  my ($class, $name, $desc) = @_;
  my $node = [];
  if (defined $desc) {
    $node->[NODE_TYPE] = TYPE_ATT_TEXT;
    $node->[NODE_BODY] = $desc;
  } else {
    $node->[NODE_TYPE] = TYPE_ATT_NAMEONLY;
  }
  $node->[NODE_PATH] = $name;
  $node;
}

sub on_expand {
  my ($class) = @_;
  croak "$class must implement on_expand";
}

#
# 通常のマクロ (macro_foreach 等) の中で、要素 $node の属性にこの argmacro を
# 展開する (旧 YATT の YATT::ArgMacro->create_from に相当)。
#
#   $node = MyApp::ArgMacro::Foo->expand_element($cgen, $node, rename => 'x=foo');
#
# トリガー (in) が有れば、それを出力属性に置き換えた新しい node を返す。
# 無ければ元の $node を返す。リストコンテキストでは ($node, $result)。
#
sub expand_element {
  my ($class, $cgen, $node, %opts) = @_;
  my ($toName, $fromName) = do {
    if (defined(my $rename = delete $opts{rename})) {
      my @match = $rename =~ m{^(\w+)=(\w+)\z}
        or croak "Invalid rename spec '$rename'";
      @match;
    } else {
      ();
    }
  };
  if (keys %opts) {
    croak "Unknown options for expand_element: ".join(", ", sort keys %opts);
  }

  require YATT::Lite::CGen::ArgMacro;
  my ($instName, $instance, $triggers, $outputs)
    = YATT::Lite::CGen::ArgMacro->instantiate(
      $class->argmacro_part_for($cgen), $toName, $fromName
    );

  my ($newPrimary, $results) = YATT::Lite::CGen::ArgMacro->expand_args(
    $cgen, $cgen->node_unwrap_attlist($node->[NODE_ATTLIST]), $node, undef,
    [$instName], {$instName => $instance},
    {map {$_ => [$instName, $triggers->{$_}]} keys %$triggers},
    {map {$_ => [$instName, $outputs->{$_}]} keys %$outputs},
  );

  my $result = $results && $results->{$instName};
  my $newNode = do {
    if ($result) {
      my $copy = [@$node];
      $copy->[NODE_ATTLIST] = $newPrimary;
      $copy;
    } else {
      $node;
    }
  };

  wantarray ? ($newNode, $result) : $newNode;
}

# この module の Core::ArgMacro (VFS 毎に一度だけ作る)
sub argmacro_part_for {
  my ($class, $cgen) = @_;
  my $vfs = $cgen->{vfs};
  $vfs->{_argmacro_module_cache}{"class:$class"}
    //= $class->as_argmacro_part($vfs->get_parser, $class);
}

1;
