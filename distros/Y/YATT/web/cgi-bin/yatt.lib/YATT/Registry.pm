# -*- mode: perl; coding: utf-8 -*-

package YATT::Registry;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use UNIVERSAL;

# Debugging aid.
require YATT;
use YATT::Exception;

{
  package YATT::Registry::NS; use YATT::Inc;
  BEGIN {require Exporter; *import = \&Exporter::import}
  use base qw(YATT::Class::Configurable);
  use YATT::Fields qw(Widget
		      cf_nsid cf_parent_nsid cf_base_nsid
		      cf_pkg cf_special_entities
		      cf_name cf_vpath cf_loadkey
		      cf_mtime cf_age
		      ^is_loaded
		    );
  # When fields is empty, %FIELDS doesn't blessed.
  # This causes "Pseudo-hashes are deprecated"

  use YATT::Types
    ([Dir => [qw(cf_base_template)]
      , 'Dir'
      , [Template => [qw(tree cf_base_template ^widget_list
			 ^cf_metainfo)]]
     ]
     , -base => [NS => __PACKAGE__]
     , -alias => [Root => 'YATT::Registry'
		  , Registry => 'YATT::Registry']
     , -default => [loader => 'YATT::Registry::Loader']
     , -debug => $ENV{YATT_DEBUG_TYPES}
     , qw(:type_name :export_alias)
    );
}

use YATT::Util qw(checked_eval checked lsearch);
use YATT::Util::Taint;
use YATT::Registry::NS;
use YATT::Util::Symbol;

use base Dir;
use YATT::Fields qw(^Loader NS last_nsid
		    cf_auto_reload
		    cf_type_map
		    cf_debug_registry
		    cf_rc_global
		    cf_template_global
		    cf_no_lineinfo
		    current_parser
		    cf_default_base_class
		    cf_use
		    loading
		    nspattern
		  )
  , ['^cf_namespace' => qw(yatt perl)]
  , ['^cf_app_prefix' => "::"]
  ;

sub new {
  my $nsid = 0;
  my Root $root = shift->SUPER::new(@_, vpath => '/', nsid => $nsid);

  if (defined $ENV{YATT_CF_LINEINFO}) {
    $root->{cf_no_lineinfo} = not $ENV{YATT_CF_LINEINFO};
  }

  # $root->{NS}{$nsid} = $root; # ← サイクルするってば。
  # 一回、空呼び出し。
  $root->get_package($root);

  # root は new 時に強制 refresh.
  # after_configure だと、configure の度なので、new のみに。
  $root->refresh($root);

  # Now safe to lift @ISA.
  $root->{is_loaded} = 1;

  $root;
}

sub configure_loader {
  (my Root $root, my ($desc)) = @_;
  my ($type, $loadkey, @args) = @$desc;
  $root->{Loader} = $root->default_loader->$type->new($loadkey, @args);
  $root->{cf_loadkey} = $loadkey;
}

sub configure_DIR {
  (my Root $root, my ($dir)) = @_;
  $root->{Loader} = $root->default_loader->DIR->new($dir);
  $root->{cf_loadkey} = $dir;
}

sub after_configure {
  (my Root $root) = @_;
  my $nspat = join("|" , @{$root->namespace});
  $root->{nspattern} = qr{^(?:$nspat)$};
}

#========================================
# use YATT::Registry ** => ** 系.

{
  our Root $ROOT;
  our NS $CURRENT;

  sub eval_in_dir {
    # XXX: should take care for variable capture.
    (my Root $root, my NS $target, my ($script, @args)) = @_;
    if (is_tainted($script)) {
      confess "script is tainted: $script\n";
    }

    my $targetClass = $root->get_package($target);

    my $prog = "package $targetClass;"
      . " use strict;"
	. " use warnings FATAL => qw(all);"
	  . " $script";
    local @_ = (@args);
    local ($ROOT, $CURRENT) = ($root, $target);
    &YATT::break_eval;
    my @result;
    if (wantarray) {
      @result = eval $prog;
    } else {
      $result[0] = eval $prog;
    }
    # XXX: $prog をどう見せたいかが、状況で色々変化する。
    die $@ if $@;
    wantarray ? @result : $result[0];
  }

  sub import {
    my $modpack = shift;
    my $callpack = caller;
    $modpack->install_builtins($callpack);

    return unless @_;

    croak "Odd number of arguments for 'use $modpack @_'" if @_ % 2;

    my $fields = $CURRENT->fields_hash;
    while (my ($name, $value) = splice @_, 0, 2) {
      if (my $sub = $modpack->can("import_$name")) {
	$sub->($modpack, $callpack, $value);
      } elsif ($sub = $CURRENT->can("configure_$name")) {
	$sub->($CURRENT, $value);
      } elsif ($fields->{"cf_$name"}) {
	$CURRENT->{"cf_$name"} = $value;
      } else {
	croak "Unknown YATT::Registry parameter: $name";
      }
    }
  }

  # Root 以外の Dir では、こちらが呼ばれる(はず)
  sub import_base {
    croak "Can't find current registry" unless defined $ROOT;
    my ($modpack, $targetClass, $vpath) = @_;
    my Dir $dir = $CURRENT->lookup_dir($ROOT, split '/', $vpath)
      or croak "Can't find directory: $vpath";
    $CURRENT->{cf_base_nsid} = $dir->{cf_nsid};
    lift_isa_to($ROOT->get_package($dir), $targetClass);
  }
}

# これが呼ばれるのは Root の時だけ。
sub configure_base {
  (my MY $root, my $realdir) = @_;
  unless (-d $realdir) {
    croak "No such directory for base='$realdir'";
  }

  my $base_nsid = $root->createNS
    (Dir => loadkey => untaint_any($realdir));

  $root->{cf_base_nsid} = $base_nsid;
  lift_isa_to($root->get_package(my $base = $root->nsobj($base_nsid))
	      , $root->get_package($root));

  $root->refresh($base);

  $root;
}

#----------------------------------------

{
  our $IS_RELOADING;
  sub is_reloading { $IS_RELOADING }
  sub with_reloading_flag {
    (my Root $root, my ($flag, $sub)) = @_;
    local $IS_RELOADING = $flag;
    $sub->();
  }
}

#----------------------------------------

sub Entity (*$) {
  my ($name, $sub) = @_;
  my ($instClass) = caller;
  my $glob = globref($instClass, "entity_$name");
  if (MY->is_reloading and defined *{$glob}{CODE}) {
    # To avoid 'Subroutine MyApp5::entity_bar redefined'.
    undef *$glob;
  }
  *$glob = $sub;
}

sub ElementMacro (*$) {
  my ($name, $sub) = @_;
  my ($instClass) = caller;
  *{globref($instClass, "macro_$name")} = $sub;
}

sub list_builtins { qw(Entity ElementMacro) }

sub install_builtins {
  my ($modpack, $destpack) = @_;
  foreach my $name ($modpack->list_builtins) {
    my $sub = $modpack->can($name)
      or die "Can't find builtin: $name";
    *{globref($destpack, $name)} = $sub;
  }
}

#========================================

sub next_nsid {
  my Root $root = shift;
  ++$root->{last_nsid};
}

sub createNS {
  (my Root $root, my ($type)) = splice @_, 0, 2;
  # class_id は？
  my $nsid = $root->next_nsid;
  my NS $nsobj = $root->{NS}{$nsid} = $root->$type->new(nsid => $nsid, @_);
  my $pkg = $root->get_package($nsobj);
  foreach my $name (map {defined $_ ? @$_ : ()} $root->{cf_rc_global}) {
    *{globref($pkg, $name)} = *{globref($root->{cf_app_prefix}, $name)};
  }
  $nsid;
}

sub nsobj {
  (my Root $root, my ($nsid)) = @_;
  unless (defined $nsid) {
    croak "nsobj: undefined nsid!";
  }
  return $root if $nsid == 0;
  $root->{NS}{$nsid};
}

sub get_package {
  (my Root $root, my NS $nsobj, my ($sep)) = @_;
  # nsid のまま渡しても良いように。
  $nsobj = $root->nsobj($nsobj) unless ref $nsobj;

  $nsobj->{cf_pkg} ||= do {
    my $pkg = do {
      if ($root == $nsobj) {
	$root->{cf_app_prefix} || '::'
      } else {
	join $sep || "::"
	  , $root->{cf_app_prefix} || '::'
	    , sprintf '%.1s%d', $nsobj->type_name
	      , $nsobj->{cf_nsid};
      }
    };
    $root->checked_eval(qq{package $pkg});
    $pkg;
  };
}

sub refresh {
  (my Root $root, my NS $node) = @_;
  $node ||= $root;
  return unless $node->{cf_loadkey};
  return if $node->{cf_age} and not $root->{cf_auto_reload};
  return unless $root->{Loader};

  # age があるのに、 is_loaded に達してない == まだ構築の途中。
  return if $node->{cf_age} and not $node->{is_loaded};
  $root->{loading}{$node->{cf_nsid}} = 1;

  print STDERR "Referesh: $node->{cf_loadkey}\n"
    if $root->{cf_debug_registry};

  $root->{Loader}->handle_refresh($root, $node);
  $node->{is_loaded} = 1;
  delete $root->{loading}{$node->{cf_nsid}};
}

sub mark_load_failure {
  my Root $root = shift;
  while ((my $nsid, undef) = each %{$root->{loading}}) {
    my NS $ns = $root->nsobj($nsid);
    # 仮に、一度は load 済みだとする。
    $ns->{is_loaded} = 1;
    delete $root->{loading}{$nsid};
  }
}

sub get_ns {
  (my Root $root, my ($elempath)) = @_;
  $root->vivify_ns($root, @$elempath);
}

sub get_package_from_node {
  (my Root $root, my ($node)) = @_;
  my Dir $dir = $root->get_dir_from_node($node);
  $root->get_package($dir);
}

sub get_dir_from_node {
  (my Root $root, my ($node)) = @_;
  my Template $tmpl = $root->get_template_from_node($node);
  $root->nsobj($tmpl->{cf_parent_nsid});
}

sub get_template_from_node {
  (my Root $root, my ($node)) = @_;
  $root->nsobj($node->metainfo->cget('nsid'));
}

sub get_widget {
  my Root $root = shift;
  $root->get_widget_from_dir($root, @_);
}

sub get_widget_from_template {
  (my Root $root, my Template $tmpl, my ($nsname)) = splice @_, 0, 3;
  my $widget;

  # Relative lookup. ($nsname case is for [delegate])
  $widget = $tmpl->lookup_widget($root, @_ ? @_ : $nsname)
    and return $widget;

  # Absolute, ns-specific lookup.
  if ($root->has_ns($root, $nsname)) {
    $widget = $root->get_widget_from_dir($root, $nsname, @_)
      and return $widget;
  }

  # Absolute, general lookup.
  return $root->get_widget_from_dir($root, @_);
}

sub get_widget_from_dir {
  (my Root $root, my Dir $dir) = splice @_, 0, 2;
  my @elempath = @_;
  $dir = $dir->vivify_ns($root, splice @elempath, 0, @elempath - 2);
  unless ($dir) {
    croak "Can't find widget: ", join(":", @_);
  }
  if (@elempath == 2) {
    $dir->widget_by_nsname($root, @elempath);
  } elsif (@elempath == 1) {
    $dir->widget_by_name($root, @elempath);
  } else {
    return;
  }
}

{
  sub YATT::Registry::NS::list_declared_widget_names {
    (my NS $tmpl) = @_;
    my @result;
    foreach my $name (keys %{$tmpl->{Widget}}) {
      my $w = $tmpl->{Widget}{$name};
      next unless $w->declared;
      push @result, $name;
    }
    @result;
  }

  # For relative lookup.
  sub YATT::Registry::NS::Template::lookup_widget {
    (my Template $tmpl, my Root $root) = splice @_, 0, 2;
    croak "lookup_widget: argument type mismatch for \$root."
      unless defined $root and ref $root and $root->isa(Root);
    return unless @_;

    foreach my NS $start ($tmpl, $root->nsobj($tmpl->{cf_parent_nsid})) {
      my @elempath = @_;

      my NS $ns = do {
	if (@elempath <= 2) {
	  $start;
	} else {
	  $start->lookup_dir($root, splice @elempath, 0, @elempath - 2);
	}
      };

      my $found = do {
	if (@elempath == 2) {
	  $ns->widget_by_nsname($root, @elempath);
	} else {
	  $ns->widget_by_name($root, @elempath);
	}
      };
      return $found if $found;
    }
  }

  sub YATT::Registry::NS::Template::lookup_template {
    (my Template $tmpl, my Root $root, my ($name)) = @_;
    $root->nsobj($tmpl->{cf_parent_nsid})->lookup_template($root, $name)
  }

  sub YATT::Registry::NS::Template::lookup_dir {
    (my Template $tmpl, my Root $root) = splice @_, 0, 2;
    $root->nsobj($tmpl->{cf_parent_nsid})->lookup_dir($root, @_);
  }

  sub YATT::Registry::NS::Dir::has_ns {
    (my Dir $dir, my Root $root, my ($nsname)) = @_;
    my $nsid;

    $nsid = $dir->{Dir}{$nsname} || $dir->{Template}{$nsname}
      and return $root->nsobj($nsid);

    return unless $dir->{cf_base_nsid};

    $root->nsobj($dir->{cf_base_nsid})->has_ns($root, $nsname);
  }

  sub YATT::Registry::NS::Dir::lookup_template {
    (my Dir $dir, my Root $root, my ($name)) = @_;
    my $nsid;
    while (not($nsid = $dir->{Template}{$name})
	   and $dir->{cf_base_nsid}) {
      $dir = $root->nsobj($dir->{cf_base_nsid});
      $root->refresh($dir);
    }
    return unless $nsid;
    $root->nsobj($nsid);
  }

  use Carp;
  sub YATT::Registry::NS::Dir::lookup_dir {
    (my Dir $dir, my Root $root, my (@nspath)) = @_;
    croak "argtype mismatch! not a Root." unless UNIVERSAL::isa($root, Root);
    return $root unless @nspath;
    (my Dir $start, my (@orig)) = ($dir, @nspath);
    $root->refresh($dir);
    while ($dir and defined (my $ns = shift @nspath)) {
      $dir = $root and next if $ns eq '';
      my $nsid = $dir->{Dir}{$ns};
      unless ($nsid) {
	return $start->{cf_base_nsid}
	  ? $root->nsobj($start->{cf_base_nsid})->lookup_dir($root, @orig)
	    : undef;
      }
      $dir = $root->nsobj($nsid);
      $root->refresh($dir);
    }
    $dir;
  }

  sub YATT::Registry::NS::Dir::list_ns {
    (my Dir $dir, my ($dict)) = @_;
    $dict ||= {};
    my @list;
    foreach my $type (qw(Template Dir)) {
      foreach my $key (keys %{$dir->{$type}}) {
	push @list, $key unless $dict->{$key}++;
      }
    }
    wantarray ? @list : \@list;
  }

  sub YATT::Registry::NS::Dir::vivify_ns {
    (my Dir $dir, my Root $root, my (@nspath)) = @_;
    my @orig = @nspath;
    while (@nspath) {
      $root->refresh($dir);
      $dir = do {
	my $ns = shift @nspath;
	my Dir $d = $dir;
	my $nsid;
	while (not($nsid = $d->{Dir}{$ns})
	       and not($nsid = $d->{Template}{$ns})
	       and $d->{cf_base_nsid}) {
	  $d = $root->nsobj($d->{cf_base_nsid});
	  $root->refresh($d);
	}
	unless ($nsid) {
	  croak "No such ns '$ns': " . join ":", @orig;
	}
	$root->nsobj($nsid);
      };
    }
    $dir;
  }

  sub YATT::Registry::NS::Dir::after_rc_loaded {
    (my Dir $dir, my Root $root) = @_;
    if (defined(my $base = $dir->{cf_base_nsid})) {
      foreach my Template $tmpl (map {$root->nsobj($_)}
				 values %{$dir->{Template}}) {
	$tmpl->{cf_base_nsid} = $base;
      }
    }
  }

  sub YATT::Registry::NS::Dir::widget_by_nsname {
    (my Dir $dir, my Root $root, my ($ns, $name)) = @_;
    $root->refresh($dir);
    if (defined $dir->{cf_name} and $dir->{cf_name} eq $ns) {
      my $widget = $dir->widget_by_name($root, $name);
      return $widget if $widget;
    }
    # [1] dir:template
    # [2] template:widget
    foreach my $type (qw(Dir Template)) {
      next unless my $nsid = $dir->{$type}{$ns};
      next unless my $widget = $root->nsobj($nsid)
	->widget_by_name($root, $name);
      return $widget;
    }
    return unless $dir->{cf_base_nsid};
    $root->nsobj($dir->{cf_base_nsid})->widget_by_nsname($root, $ns, $name);
  }

  sub YATT::Registry::NS::Dir::widget_by_name {
    (my Dir $dir, my Root $root, my ($name)) = @_;
    $root->refresh($dir);
    if (my $nsid = $dir->{Template}{$name}) {
      $root->refresh($root->nsobj($nsid));
    }
    $dir->{Widget}{$name}
      || $dir->{cf_base_nsid}
	&& $root->nsobj($dir->{cf_base_nsid})->widget_by_name($root, $name);
  }

  sub YATT::Registry::NS::Template::widget_by_nsname {
    (my Template $tmpl, my Root $root, my ($ns, $name)) = @_;
    if ($tmpl->{cf_name} eq $ns) {
      my $widget = $tmpl->widget_by_name($root, $name);
      return $widget if $widget;
    }
    my Dir $parent = $root->nsobj($tmpl->{cf_parent_nsid});
    if (defined $parent->{cf_name} and $parent->{cf_name} eq $ns) {
      my $widget = $tmpl->widget_by_name($root, $name);
      return $widget if $widget;
    }
    $parent->widget_by_nsname($root, $ns, $name);
  }

  sub YATT::Registry::NS::Template::widget_by_name {
    (my Template $tmpl, my Root $root, my ($name)) = @_;
    $root->refresh($tmpl);
    my $widget;
    $widget = $tmpl->{Widget}{$name}
      and return $widget;

    # 同一ディレクトリのテンプレートを先に検索するため。
    # XXX: しかし、継承順序に問題が出ているはず。
    $widget = $root->nsobj($tmpl->{cf_parent_nsid})
      ->widget_by_name($root, $name)
	and return $widget;

    if ($tmpl->{cf_base_template}) {
      $widget = $root->nsobj($tmpl->{cf_base_template})
	->widget_by_name($root, $name)
	  and return $widget;
    }

    if ($tmpl->{cf_base_nsid}) {
      $widget = $root->nsobj($tmpl->{cf_base_nsid})
	->widget_by_name($root, $name)
	  and return $widget;
    }

    return;
  }
}

sub node_error {
  (my Root $root, my ($node, $fmt)) = splice @_, 0, 3;
  $root->node_error_obj($node
			, error_fmt => ref $fmt ? join(" ", $fmt) : $fmt
			, error_param => [@_]
			, caller => [caller]);
}

sub node_error_obj {
  (my Root $root, my ($node, @param)) = @_;
  # XXX: $root->{cf_backtrace} なら longmess も append, とか。
  # XXX: Error オブジェクトにするべきかもね。でも依存は嫌。
  #  ← die を $root->raise で wrap すれば良い？
  my $stringify = $root->checked(stringify => "(Can't stringify: %s)", $node);
  my $filename = $root->checked(filename => "(Can't get filename %s)", $node);
  my $linenum = $root->checked(linenum => "(Can't get linenum %s)", $node);
  $root->Exception->new(@param
			, node_obj => $node
			, node => $stringify, file => $filename
			, line => $linenum);
}

sub node_nimpl {
  (my Root $root, my ($node, $msg)) = @_;
  my $caller = [my ($pack, $file, $line) = caller];
  $root->node_error_obj($node
			, error_fmt => join(' '
					    , ($msg || "Not yet implemented")
					    , "(perl file $file line $line)")
			, caller => $caller);
}

sub strip_ns {
  (my Root $root, my ($list)) = @_;
  $root->shift_ns_by($root->{nspattern}, $list);
}

sub shift_ns_by {
  (my Root $root, my ($pattern, $list)) = @_;
  return unless @$list;
  return unless defined $pattern;
  if (ref $pattern) {
    return unless $list->[0] =~ $pattern
  } else {
    return unless $list->[0] eq $pattern;
  }
  shift @$list;
}

#========================================

use YATT::LRXML::Node qw(DECLARATOR_TYPE node_path create_node);
sub DEFAULT_WIDGET () {''}

use YATT::LRXML::MetaInfo;
use YATT::Widget;

use YATT::LRXML; # for Builder.
use YATT::Types
  ([WidgetBuilder => [qw(cf_widget ^cf_template cf_root_builder)]]
   , -base => qw(YATT::LRXML::Builder)
   , -alias => [Builder => __PACKAGE__ . '::WidgetBuilder'
		, Scanner => 'YATT::LRXML::Scanner']
  );

# XXX: 名前が紛らわしい。lrxml tree の root か、Registry の root か、と。
sub new_root_builder {
  (my Root $root, my $parser, my Scanner $scan) = @_;
  my MetaInfo $meta = $parser->metainfo;
  my Template $tmpl = $root->nsobj($meta->{cf_nsid});

  my $widget = $root->create_widget_in
    ($tmpl, DEFAULT_WIDGET
     , filename => $meta->cget('filename')
     , decl_start => $scan->{cf_linenum}
     , body_start => $scan->{cf_linenum} + $scan->number_of_lines);

  # 親ディレクトリに登録。
  my Dir $parent = $root->nsobj($tmpl->{cf_parent_nsid});

  $parent->{Widget}{$tmpl->{cf_name}} = $widget;

  $parser->configure(tree => my $sink = $widget->cget('root'));

  $root->Builder->new($sink, undef
		      , widget => $widget
		      , template => $tmpl
		      , startpos => 0
		      , startline => $scan->{cf_linenum}
		      , linenum   => $scan->{cf_linenum});
}

sub fake_cursor_from {
  (my MY $trans, my ($cursor, $node, $is_opened)) = @_;
  my $parent = $cursor->Path->new($node, $cursor->cget('path'));
  my $path = $is_opened ? $parent
    : $cursor->Path->new($trans->create_node(unknown => undef, $node)
			 , $parent);
  $cursor->clone($path);
}

sub fake_cursor {
  (my MY $gen, my Widget $widget, my ($metainfo)) = splice @_, 0, 3;
  my $cursor = $widget->cursor(metainfo => $metainfo);
  my $node = $gen->create_node(unknown => undef, @_);
  $cursor->clone($cursor->Path->new($node, $cursor->cget('path')));
}

sub fake_cursor_to_build {
  (my MY $root, my Builder $builder, my Scanner $scan
   , my ($elem)) = @_;
  $root->fake_cursor($builder->{cf_widget}
		     , $builder->{cf_template}->metainfo
		     ->clone(startline => $scan->{cf_linenum})
		     , $elem);
}

sub new_decl_builder {
  (my MY $root, my Builder $builder, my Scanner $scan
   , my ($elem, $parser)) = @_;
  foreach my $shift (0, 1) {
    my $path = [node_path($elem)];
    $root->strip_ns($path) if $shift;
    my $handler_name = join("_", declare => @$path);

    if (my $handler = $root->can($handler_name)) {
      my $nc = $root->fake_cursor_to_build($builder, $scan, $elem)->open;
      return $handler->($root, $builder, $scan, $nc, $parser);
    }
  }

  die $root->node_error($root->fake_cursor_to_build($builder, $scan, $elem)
			, "Unknown declarator");
}

sub declare_base {
  (my Root $root, my Builder $builder, my ($scan, $args, $parser)) = @_;
  if ($builder->{parent}) {
    die $scan->token_error("Misplaced yatt:base");
  }
  my $path = $args->node_body;
  my Template $this = $builder->{cf_template};
  my Template $base = $this->lookup_template($root, $path)
    or die $scan->token_error("Can't find template $path");

  # XXX: refresh は lookup_template の中ですべきか？
  $root->refresh($base);

  # 名前は保存しなくていいの?
  $this->{cf_base_template} = $base->{cf_nsid};

  $root->add_isa($root->get_package($this)
		 , $root->get_package($base));

  # builder を返すことを忘れずに。
  $builder;
}

sub declare_args {
  (my Root $root, my Builder $builder
   , my ($scan, $nc, $parser, @configs)) = @_;
  if ($builder->{parent}) {
    die $scan->token_error("Misplaced yatt:args");
  }
  # widget -> args の順番で出現する場合もある。
  # root 用の builder を取り出し直す
  if ($builder->{cf_root_builder}) {
    $builder = $builder->{cf_root_builder};
  }
  my Widget $widget = $builder->{cf_widget};
  $widget->{cf_declared} = 1;
  $widget->{cf_decl_start} = $scan->{cf_last_linenum};
  $widget->{cf_body_start} = $scan->{cf_last_linenum} + $scan->{cf_last_nol};
  $widget->configure(@configs) if @configs;
  $root->define_args($widget, $nc);
  $root->after_define_args($widget);
  $builder;
}

sub declare_params {
  shift->declare_args(@_, public => 1);
}

sub declare_widget {
  (my Root $root, my Builder $builder, my Scanner $scan
   , my ($args, $parser)) = @_;

  if ($builder->{parent}) {
    die $root->node_error($root->fake_cursor_to_build($builder, $scan
						      , $builder->product)
			  , "Misplaced yatt:widget in:");
  }

  defined (my $name = $args->node_name)
    or die $root->node_error($args, "widget name is missing");

  # XXX: filename, lineno
  my Widget $widget = $root->create_widget_in
    ($builder->{cf_template}, $name
     , declared => 1
     , filename  => $builder->{cf_template}->metainfo->cget('filename')
     , decl_start => $scan->{cf_last_linenum}
     , body_start => $scan->{cf_last_linenum} + $scan->{cf_last_nol});

  $root->define_args($widget, $args->go_next);
  $root->after_define_args($widget);

  $root->Builder->new($widget->cget('root'), undef
		      , widget => $widget
		      , template => $builder->{cf_template}
		      , startpos => $scan->{cf_index}
		      , startline => $scan->{cf_linenum}
		      , linenum   => $scan->{cf_linenum}
		      # widget -> args に戻るためには root_builder を
		      # 渡さねばならぬ
		      , root_builder =>
		      $builder->{cf_root_builder} || $builder
		     );
}

sub create_widget_in {
  (my Root $root, my Template $tmpl, my ($name)) = splice @_, 0, 3;
  my $widget = YATT::Widget->new
    (name => $name, template_nsid => $tmpl->{cf_nsid}
     , @_);
  $tmpl->{Widget}{$name} = $widget;
  push @{$tmpl->{widget_list}}, $widget;
  $widget;
}

sub current_parser {
  my Root $root = shift;
  $root->{current_parser}[0];
}

sub after_define_args {shift; shift}

sub define_args {
  (my Root $root, my ($target, $args)) = @_;

  # $target は has_arg($name) と add_arg($name, $arg) を実装しているもの。
  # *: widget
  # *: codevar

  for (; $args->readable; $args->next) {
    # マクロ引数呼び出し %name(); がここで出現
    # comment も現れうる。
    # body = [code title=html] みたいなグループ引数もここで。

    my $sub = $root->can("add_decl_" . $args->node_type_name)
      or next;

    $sub->($root, $target, $args);
  }

  # おまけ。使わないけど、デバッグ時に少し幸せ。
  $root;
}

sub add_decl_attribute {
  (my Root $root, my ($target, $args)) = @_;
  my $argname = $args->node_name;
  unless (defined $argname) {
    die $root->node_error($args, "Undefined att name!");
  }
  if ($target->has_arg($argname)) {
    die $root->node_error($args, "Duplicate argname: $argname");
  }

  my ($type, @param) = $args->parse_typespec;
  my ($typename, $subtype) = do {
    if (ref $type) {
      ($type->[0], [@{$type}[1 .. $#$type]])
    } else {
      ($type, undef);
    }
  };
  if (defined $typename and my $sub = $root->can("attr_declare_$typename")) {
    $sub->($root, $target, $args, $argname, $subtype, @param);
  } else {
    $target->add_arg($argname, $root->create_var($type, $args, @param));
  }
}

sub create_var {
  (my Root $root, my ($type, $args, @param)) = @_;
  $type = '' unless defined $type;
  my ($primary, @subtype) = ref $type ? @$type : $type;
  defined (my $class = $root->{cf_type_map}{$primary})
    or croak $root->node_error($args, "No such type: %s", $primary);
  unshift @param, subtype => @subtype >= 2 ? \@subtype : $subtype[0]
    if @subtype;
  if (my $sub = $root->can("create_var_$primary")) {
    $sub->($root, $args, @param);
  } else {
    $class->new(@param);
  }
}

#========================================
{
  package YATT::Registry::Loader; use YATT::Inc;
  use base qw(YATT::Class::Configurable);
  use YATT::Fields qw(Cache);
  use Carp;
  use YATT::Registry::NS;

  sub DIR () { 'YATT::Registry::Loader::DIR' }

  sub handle_refresh {
    (my MY $loader, my Root $root, my NS $node) = @_;
    my $type = $node->type_name;
    if (my $sub = $loader->can("refresh_$type")) {
      $sub->($loader, $root, $node);
    } else {
      confess "Can't refresh type: $type";
    }
  }

  sub is_modified {
    my MY $loader = shift;
    my ($item, $old) = @_;
    my $mtime = $loader->mtime($item);
    return if defined $old and $old >= $mtime;
    $_[1] = $mtime;
    return 1;
  }

  package YATT::Registry::Loader::DIR;

  use base qw(YATT::Registry::Loader File::Spec);
  use YATT::Fields qw(cf_DIR cf_LIB);
  sub initargs { qw(cf_DIR) }
  sub init {
    my ($self, $dir) = splice @_, 0, 2;
    $self->SUPER::init($dir, @_);
    if (-d (my $libdir = "$dir/lib")) {
      require lib; import lib $libdir
    }
    $self;
  }

  use YATT::Registry::NS;
  use YATT::Util;
  use YATT::Util::Taint;

  sub mtime { shift; (stat(shift))[9]; }

  sub RCFILE () {'.htyattrc'}
  sub Parser () {'YATT::LRXML::Parser'}

  use Carp;

  sub checked_read_file {
    (my MY $loader, my ($fn, $layer)) = @_;
    croak "Given path is tainted! $fn" if is_tainted($fn);
    open my $fh, '<' . ($layer || ''), $fn
      or die "Can't open $fn! $!";
    local $/;
    scalar <$fh>;
  }

  sub refresh_Dir {
    (my MY $loader, my Root $root, my Dir $dir) = @_;
    my $dirname = $dir->{cf_loadkey};
    # ファイルリストの処理.
    return unless $loader->is_modified($dirname, $dir->{cf_mtime}{$dirname});

    my $is_reload = $dir->{cf_age}++;
    undef $dir->{is_loaded};

    if (is_tainted($dirname)) {
      croak "Directory $dirname is tainted"
    }

    if ($root == $dir) {
      foreach my $d ($dirname, map {!defined $_ ? () : ref $_ ? @$_ : $_}
		     $loader->{cf_LIB}) {
	$loader->load_dir($root, $dir, $d);
      }
    } else {
      $loader->load_dir($root, $dir, $dirname);
    }

    # RC 読み込みの前に、 default_base_class を設定。
    if ($root->{cf_default_base_class}
	and ($root->{cf_default_base_class} ne $root->{cf_pkg}
	     or $root->{is_loaded})) {
      # XXX: add_isa じゃなくて ensure_isa だね。
      #print STDERR "loading default_base_class $root->{cf_default_base_class}"
      # . " for dir $dirname\n";
      $root->checked_eval(qq{require $root->{cf_default_base_class}});
      $root->add_isa(my $pkg = $root->get_package($dir)
		     , $root->{cf_default_base_class});
    }

    # RC 読み込みは、最後に
    my $rcfile = $loader->catfile($dirname, $loader->RCFILE);
    if (-r $rcfile) {
      my $script = "";
      $script .= ";no warnings 'redefine';" if $is_reload;
      $script .= sprintf(qq{\n#line 1 "%s"\n}, $rcfile)
	unless $root->{cf_no_lineinfo};
      $script .= untaint_any($loader->checked_read_file($rcfile));
      &YATT::break_rc;
      $root->with_reloading_flag
	($is_reload, sub {
	   $root->eval_in_dir($dir, $script);
	 });
      &YATT::break_after_rc;

      $dir->after_rc_loaded($root);
    }

    $dir;
  }

  sub load_dir {
    (my MY $loader, my Root $root, my Dir $dir, my ($dirname)) = @_;
    local *DIR;
    opendir DIR, $dirname or die "Can't open dir '$dirname': $!";
    while (my $name = readdir(DIR)) {
      next if $name =~ /^\./;
      my $path = $loader->catfile($dirname, $name);
      # entry を作るだけ。load はしない。→ mtime も、子供側で。
      if (-d $path) {
	next unless $name =~ /^(?:\w|-)+$/; # Not CC for future widechar.
	$dir->{Dir}{$name} ||= $loader->{Cache}{$path}
	  ||= $root->createNS(Dir => name => $name
			      , loadkey => untaint_any($path)
			      , parent_nsid => $dir->{cf_nsid}
			      , base_nsid   => $dir->{cf_base_nsid}
			     );
      } elsif ($name =~ /^(\w+)\.html?$/) { # XXX: Should allow '-'.
	$dir->{Template}{$1} ||= $loader->{Cache}{$path}
	  ||= $root->createNS(Template => name => $1
			      , loadkey => untaint_any($path)
			      , parent_nsid => $dir->{cf_nsid}
			      , base_nsid   => $dir->{cf_base_nsid}
			     );
      }
    }
    # XXX: 無くなったファイルの開放は?
    closedir DIR;
  }

  sub refresh_Template {
    (my MY $loader, my Root $root, my Template $tmpl) = @_;
    my $path = $tmpl->{cf_loadkey};
    unless ($loader->is_modified($path, $tmpl->{cf_mtime}{$path})) {
      print STDERR "refresh_Template: not modified: $path\n"
	if $root->{cf_debug_registry};
      return;
    }

    if (is_tainted($path)) {
      croak "template path $path is tainted";
    }

    if (my $cleaner = $root->can("forget_template")) {
      $cleaner->($root, $tmpl);
    }

    my $is_reload = $tmpl->{cf_age}++;
    undef $tmpl->{is_loaded};

    $root->add_isa(my $pkg = $root->get_package($tmpl)
		   , $root->get_package($tmpl->{cf_parent_nsid}));
    foreach my $name (map {defined $_ ? @$_ : ()}
		      $root->{cf_template_global}) {
      *{globref($pkg, $name)} = *{globref($root->{cf_app_prefix}, $name)};
    }

    # XXX: There can be a race. (mtime vs open)
    my $parser = $loader->call_type
      (Parser => new => untaint => 1
       , registry => $root
       , special_entities => $root->{cf_special_entities});
    local $root->{current_parser}[0] = $parser;

    open my $fh, '<', $path or die "Can't open $path";

    $tmpl->{cf_metainfo} = $parser->configure_metainfo
      (nsid => $tmpl->{cf_nsid}
       , namespace => $root->namespace
       , filename => $path);

    $tmpl->{tree} = $parser->parse_handle($fh);

    # XXX: ついでに <!yatt:widget> を解釈. ← parser に前倒し。
    # $root->process_declarations($tmpl);
  }
}

#========================================

sub _lined {
  my $i = 1;
  my $result;
  foreach my $line (split /\n/, $_[0]) {
    if ($line =~ /^\#line (\d+)/) {
      $i = $1;
      $result .= $line . "\n";
    } else {
      $result .= sprintf "% 3d  %s\n", $i++, $line;
    }
  }
  $result
}

1;
