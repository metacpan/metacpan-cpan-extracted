package YATT::Lite::CGen::Perl;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

require 5.010; # For named capture.

use constant DEBUG_MRO => $ENV{DEBUG_YATT_MRO};

use YATT::Lite::Core qw(Folder Template Part Widget Action Entity);
use YATT::Lite::Constants;

# Naming convention:
# generate_SRC     -- Public Interface.
# gen_DETAIL       -- Internal higher/large tasks.
# from_NODETYPE    -- Node Type specific dispatch entry.
# as_WHATHOW_FROM  -- Miscellaneous dispatching (for var type and others)

{
  #========================================
  package YATT::Lite::CGen::Perl; sub MY () {__PACKAGE__}
  use base qw(YATT::Lite::CGen);
  use YATT::Lite::MFields;
  use YATT::Lite::Util qw(lexpand numLines globref terse_dump catch);
  use Carp;
  #========================================
  sub list_inheritance {
    (my MY $self, my Template $tmpl) = @_;
    # XXX: Duplicate detection should be handled higer layer.
    my %dup;
    map {
      my Folder $f = $_;
      unless (defined $f->{cf_entns}) {
	die "BUG: EntNS is empty for ".terse_dump($f->{cf_name})."!";
      }
      if ($dup{$f->{cf_entns}}++) {
	()
      } else {
	$f->{cf_entns}
      }
    } $tmpl->list_base
  }
  sub setup_inheritance_for {
    (my MY $self, my $spec, my Template $tmpl) = @_;
    unless (defined $tmpl->{cf_entns}) {
      die "BUG: EntNS is empty for '$tmpl->{cf_name}'!";
    }
    my $glob = globref($$tmpl{cf_entns}, 'ISA');
    # XXX: base change should be reflected when reloaded, but...
    unless (defined $glob) {
      die "BUG: ISA glob for '$tmpl->{cf_name}' is empty!";
    }
    $self->ensure_generated_for_folders($spec, $tmpl->list_base);
    my @isa = $self->list_inheritance($tmpl);
    if (grep {not defined} @isa) {
      die "BUG: ISA for '$tmpl->{cf_name}' contains undef!";
    }
    if (my $err = catch {
      *$glob = \@isa;
    }) {
      die $self->generror("Can't set ISA for '%s' as [%s]: %s"
			  , $tmpl->{cf_name}
			  , join(", ", @isa)
			  , $err
			);
    }
  }
  sub generate_inheritance {
    (my MY $self, my Template $tmpl) = @_;
    my @isa = $self->list_inheritance($tmpl);
    my $mro = mro::get_mro($tmpl->{cf_entns});
    print STDERR "($mro) [$tmpl->{cf_path}] $tmpl->{cf_entns}::ISA = @isa\n"
      if DEBUG_MRO;
    sprintf q{use mro '%s'; our @ISA = qw(%s); }, $mro, join " ", @isa;
  }
  #========================================
  sub generate_preamble {
    (my MY $self, my Template $tmpl) = @_;
    $tmpl ||= $self->{curtmpl};
    my @stats;
    unless ($self->{cf_no_lineinfo}) {
      my $line = qq{#line }. $self->{curline};
      if (defined(my $fn = $tmpl->fake_filename)) {
	# cf_name is dummy filename.
	$line .= qq{ "$fn"};
      }
      push @stats, $line .= "\n";
    }
    push @stats, sprintf q{package %s; use strict; use warnings; use 5.010; }
      , $$tmpl{cf_entns};
    push @stats, $self->generate_inheritance($tmpl);
    push @stats, "use utf8; " if $$tmpl{cf_utf8};
    push @stats, q|no warnings qw(redefine); | if $$tmpl{cf_age}++;
    push @stats, sprintf q|sub filename {__FILE__}; |;
    @stats
  }
  sub generate_page {
    # XXX: 本物へ。 public フラグ?
    shift->generate_widget(@_);
  }
  sub generate_widget {
    (my MY $self, my Widget $widget, my ($widget_name, $tmpl_path)) = @_;
    if ($widget->{cf_suppressed}) {
      # First line is alread used for package declaration.
      return "\n" x ((($widget->{cf_endln} - 1) - $widget->{cf_startln}) - 2);
    }
    break_cgen();
    local $self->{curwidget} = $widget;
    # XXX: calling convention 周り, body の code 型
    local $self->{scope} = $self->mkscope
      ({}, $widget->{var_dict}, $widget->{arg_dict} ||= {}
       , {this => $self->mkvar_at(undef, text => 'this')
	  , 'CON' => $self->mkvar_at(undef, text => 'CON')
	  , '_' => $self->mkvar_at(undef, text => '_')}
      );
    local $self->{curtoks} = [@{$widget->{tree}}];
    ($self->sync_curline($widget->{cf_startln})
     , "sub render_$$widget{cf_name} {"
     , $self->gen_preamble($widget)
     , $self->gen_getargs($widget, not $widget->{cf_implicit})
     , $self->as_print("}")
    );
  }
  sub generate_action {
    (my MY $self, my Action $action) = @_;
    # XXX: 改行の調整が必要。
    my @src = ($self->sync_curline($action->{cf_startln})
               , "sub do_$$action{cf_name} {");
    my $src = $self->{curtmpl}->source_substr
      ($action->{cf_bodypos}, $action->{cf_bodylen});

    if (lexpand($action->{arg_order})
        or $src !~ m{^([\ \t\r\n]*)my\s*\([^;\)]+\)\s*=\s*\@_\s*;}) {
      # If an action has no arguments
      # and its source doesn't start with my (...) = @_;,
      # insert preamble and getargs.
      push @src, $self->gen_preamble($action)
        , $self->gen_getargs($action, not $action->{cf_implicit});
    }

    my $has_nl = $src =~ s/\r?\n\Z//;
    $self->{curline} = $action->{cf_bodyln} + numLines($src)
      + ($has_nl ? 1 : 0);
    (@src, $src, "}");
  }

  # XXX: As you see, dup code.
  # XXX: Should define common base class for Action and Entity.
  sub generate_entity {
    (my MY $self, my Entity $entity) = @_;
    # XXX: 改行の調整が必要。
    my @src = ($self->sync_curline($entity->{cf_startln})
               , "sub entity_$$entity{cf_name} {");
    my $src = $self->{curtmpl}->source_substr
      ($entity->{cf_bodypos}, $entity->{cf_bodylen});

    if (lexpand($entity->{arg_order})
        or $src !~ m{^([\ \t\r\n]*)my\s*\([^;\)]+\)\s*=\s*\@_\s*;}) {
      # If an entity has no arguments
      # and its source doesn't start with my (...) = @_;,
      # insert preamble and getargs.
      push @src, q{ my ($this) = shift; my $CON = $this->CON;}
        , $self->gen_getargs($entity, not $entity->{cf_implicit});
    }

    my $has_nl = $src =~ s/\r?\n\Z//;
    $self->{curline} = $entity->{cf_bodyln} + numLines($src)
      + ($has_nl ? 1 : 0);
    (@src, $src, "}");
  }

  #========================================
  sub gen_preamble {q{ my ($this, $CON) = splice @_, 0, 2;}}
  sub gen_getargs {
    (my MY $self, my Widget $widget, my $for_decl) = @_;
    my @res;
    foreach my $argName (lexpand($widget->{arg_order})) {
      # デフォルト値と、型と。
      my $var = $widget->{arg_dict}{$argName};
      push @res, $for_decl ? $self->sync_curline($var->lineno) : ()
	, sprintf q{ my %s = %s;}, $self->as_lvalue($var)
	  , $self->as_getarg($var);
      # shift しない方が、debug 時に stack trace に引数値が見えて嬉しい。
    }
    # <!yatt:widget ...> 末尾の改行
    push @res, "\n" and $self->{curline}++ if $for_decl;
    (@res, $self->sync_curline($widget->{cf_bodyln})
     , $self->cut_next_nl);
  }
  sub as_getarg {
    (my MY $self, my $var) = @_;
    my $actual = '$_['.$var->argno.']';
    return $actual unless defined (my $default = $var->default)
      and defined (my $mode = $var->dflag);
    my $varname = $self->as_lvalue($var);
    if ($mode eq "!") {
      return qq{defined $actual ? $actual : }
	. qq{die q|Argument '@{[$var->varname]}' is undef!|};
    }
    # XXX: do given/when は値を返さないから、ここでは使えない！ void context 扱いになっちまう。
    my ($cond) = do {
      if ($mode eq "|") {
	qq{$actual}
      } elsif ($mode eq "?") {
	qq{defined $actual && $actual ne ""}
      } elsif ($mode eq "/") {
	qq{defined $actual}
      } else {
	die "Unknown defaulting mode: $mode"
      }
    };
    sprintf q{(%s ? %s : %s)}, $cond, $actual
      , $self->as_cast_to($var, $default);
    # XXX: html 型変数へ text 型変数の混じったデフォルト値を入れるときには、 as_text じゃだめ
    # as_text に、やはり escape flag を渡せるようにするのが筋か?
  }
  #========================================
  our @DISPATCH;
  $DISPATCH[TYPE_LINEINFO] = \&from_lineinfo;
  $DISPATCH[TYPE_COMMENT]  = \&from_comment;
  $DISPATCH[TYPE_LCMSG]    = \&from_lcmsg;
  $DISPATCH[TYPE_ENTITY]   = \&from_entity;
  $DISPATCH[TYPE_PI]       = \&from_pi;
  $DISPATCH[TYPE_ELEMENT]  = \&from_element;
  $DISPATCH[TYPE_ATT_NESTED] = \&from_elematt;
  sub as_print {
    (my MY $self, my ($last, $localtoks)) = @_;
    push @{$self->{curtoks}}, @$localtoks if $localtoks;
    local $self->{needs_escaping} = 1;
    my (@result, @queue) = '';
    # curline は queue 詰めの外側で操作する。
    # $last は一回だけ出力するように、undef が必要。
    my $flush = sub {
      my ($has_nl, $task, $pad) = @_;
      push @result, $pad if defined $pad;
      push @result, q{print $CON (}.join(", ", @queue).");" if @queue;
      # もう token が残っていなくて、かつ $last が与えられていたら、 $last を足す。
      push @result, $task->() if $task;
      $result[-1] .= $last and undef $last if $last and not @{$self->{curtoks}};
      # 明示 "\n" が来ていた場合は、 ";" と同時に改行する。
      $result[-1] .= "\n" if $has_nl;
      undef @queue;
    };
    while (@{$self->{curtoks}}) {
      my $node = shift @{$self->{curtoks}};
      unless (ref $node) {
        # 次が element な時は、先行する indent を捨てる
        if (@{$self->{curtoks}} and ref $self->{curtoks}[0]
              and $self->{curtoks}[0][0] == TYPE_ELEMENT
              and $node =~ /^[\ \t]+\z/
          ) {
          next;
        }
	# text node の末尾が改行で終わっている場合、 明示的に "\n" を生成する
	my $has_nl = $node =~ s/\r?\n\Z//s;
	push @queue, qtext($node) if $node ne ''; # 削ったら空になるかも。
	$self->{curline} += numLines($node);
	$self->{curline}++ if $has_nl;
	push @queue, q{"\n"} if $has_nl
	  and @{$self->{curtoks}} || not $self->{no_last_newline};
	$flush->($has_nl) if $has_nl || $node =~ /\n/;
	next;
      }
      my $pad = $self->sync_curline($node->[NODE_LNO]) // '';
      my $sub = $DISPATCH[$node->[0]]
	or die $self->generror("Unknown node type: %d", $node->[0]);
      my $expr = $sub->($self, $node);
      unless (defined $expr) {
	push @result, $self->cut_next_nl;
	next;
      }
      if (ref $expr) {
	$flush->(undef, sub { ("$$expr;", $self->cut_next_nl) }, $pad);
      } else {
	$flush->(undef, undef, $pad) if length $pad;
	push @queue, $expr;
	$flush->() if $expr =~ /\n/;
      }
      # Following can remove trailing newline from </yatt:foreach>,
      # but it affects all of yatt tags.
      # if (@{$self->{curtoks}} and $self->{curtoks}[0] eq "\n") {
      #   shift @{$self->{curtoks}};
      # }
    }
    $flush->();
    join " ", @result;
  }
  sub gen_as {
    (my MY $self, my ($type, $dispatch, $escape, $text_quote))
      = splice @_, 0, 5;
    local $self->{needs_escaping} = $escape;
    my (@result);
    # Empty expr (ie <:yatt:arg></:yatt:arg>) should generate q|| as code.
    if (not @_ and $text_quote) {
      push @result, qtext('');
    }
    while (@_) {
      my $node = shift;
      unless (ref $node) {
	push @result, ($text_quote ? qtext($node) : $node);
	$self->{curline} += numLines($node);
	next;
      }
      # 許されるのは entity だけでは？ でもないか。 element 引数の時は、capture したいはず。
      my $sub = $dispatch->[$node->[0]] or do {
        die $self->generror("gen_as %s: Unknown node type: %d"
                            , $type, $node->[0]);
      };
      my $expr = $sub->($self, $node);
      next unless defined $expr;
      if (ref $expr) {
	die $self->generror("Syntax error, not allowed here: %s", $$expr);
      }
      push @result, $expr;
    }
    wantarray ? @result : join("", @result);
  }

  # as_list と対になる。
  our @AS_TEXT;
  $AS_TEXT[TYPE_LCMSG]    = \&from_lcmsg;
  $AS_TEXT[TYPE_ENTITY]   = \&from_entity;
  $AS_TEXT[TYPE_PI]       = \&text_from_pi;
  $AS_TEXT[TYPE_ELEMENT]  = \&text_from_element; # XXX: ?? Used??
  $AS_TEXT[TYPE_ATT_NESTED]  = sub {undef}; # gen_as が scalar 受けゆえ
  # as_text は、escape 不要。なぜなら、 print 時に escape されるから。
  # でも、 escape 有無を flag で渡せた方が、 html 型にも使えて便利では?
  # というか、 html 型には capture が必要か。 capture は buffering したいよね？
  sub as_text {
    join '.', shift->gen_as(text => \@AS_TEXT, 0, 1, @_);
  }

  our @AS_LIST;
  $AS_LIST[TYPE_ENTITY]   = \&from_entity;
  $AS_LIST[TYPE_PI]       = \&list_from_pi;
  $AS_LIST[TYPE_ELEMENT]  = \&list_from_element;
  $AS_LIST[TYPE_ATT_NESTED] = sub {undef}; # XXX: 微妙
  sub as_list {
    shift->gen_as(list => \@AS_LIST, 0, 0, @_);
  }
  #========================================
  sub from_element {
    # XXX: macro (if, foreach, my, format) (error if は?)
    (my MY $self, my $node) = @_;
    my $path = $node->[NODE_PATH];
    if (my $alt = $self->altgen($path->[0])) {
      qtext($alt->($node));
    } elsif (@$path == 2
	and my $macro = $self->can("macro_" . join "_", @$path)
	|| $self->can("macro_$path->[-1]")) {
      $macro->($self, $node);
    } else {
      # stack trace に現れるように, 敢えて展開。
      $self->gen_call($node, @{$node->[NODE_PATH]});
    }
  }
  sub text_from_element {
    (my MY $self, my $node) = @_;
    my $call_ref = $self->from_element($node);
    sprintf q{(YATT::Lite::Util::captured {my ($CON) = @_; %s})}, $$call_ref;
  }
  sub text_from_pi {
    (my MY $self, my $node) = @_;
    my $statements = $self->from_pi($node);
    sprintf q{(YATT::Lite::Util::captured {my ($CON) = @_; %s})}, $statements;
  }

  sub gen_call {
    (my MY $self, my ($node, @path)) = @_;
    my $wname = join ":", @path;
    if (@path == 2 and my $var = $self->find_callable_var($path[-1])) {
      # code 引数の中の引数のデフォルト値の中に、改行が有ったら？？
      # XXX: body の引数宣言が無い場合に <yatt:body/> は、ちゃんと呼び出せるか?
      return $self->can("as_varcall_" . $var->type->[0])
	->($self, $var, $node);
    }

    my Widget $widget = $self->lookup_widget(@path) or do {
      my $err = $self->generror(q{No such widget <%s>}, $wname);
      die $err;
    };

    $self->ensure_generated(perl => my Template $tmpl = $widget->{cf_folder});
    my $use_this = $tmpl == $self->{curtmpl};
    unless ($use_this) {
      $self->{curtmpl}->add_dependency($wname, $tmpl);
    }
    my $that = $use_this ? '$this' : $tmpl->{cf_entns};
    \ sprintf(q{%s->render_%s($CON, %s)}
	      , $that, $widget->{cf_name}
	      , $self->gen_putargs($widget, $node)
	     );
  }
  sub gen_putargs {
    (my MY $self, my Widget $widget, my $node, my $delegate_vars) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);
    return '' if not $delegate_vars and not $widget->{has_required_arg}
      and not $primary and not $body;
    my $wname = join ":", @$path;
    my ($posArgs, $actualNo, @argOrder);
    my $add_arg = sub {
      my ($name) = @_;
      my $formal = $widget->{arg_dict}{$name} or do {
	die $self->generror(q{Unknown arg '%s' in widget <%s>}, $name, $wname);
      };
      if (defined $argOrder[my $argno = $formal->argno]) {
	die $self->generror(q{Duplicate arg '%s'}, $name);
      } else {
	$argOrder[$argno] = ++$actualNo;
      }
      $formal;
    };
    # primary 引数
    my @argExpr = map {
      $self->sync_curline($_->[NODE_LNO]), ", ", $self->add_curline(do {
	my $name = argName($_);
	unless (defined $name) {
	  defined($name = $widget->{arg_order}[$posArgs //= 0])
	    or die $self->generror("Too many arguments for widget <%s>"); # This may not be called.

          # Positional arguments should not be treated as body argument.
          if ($widget->{arg_dict}{$name}->is_body_argument) {
            die $self->generror(
              "Too many arguments for widget <%s>: %s", $wname
              , $self->{curtmpl}->source_region($primary->[$posArgs][NODE_BEGIN],
                                                $primary->[$#$primary][NODE_END])
            );
          }

          $posArgs++;
	}

	my $formal = $add_arg->($name);
	unless (my $passThruVar = passThruVar($_)) {
	  $self->as_cast_to($formal, argValue($_));
	} elsif (my $actual = $self->find_var($passThruVar)) {
	  if ($formal->already_escaped and not $actual->already_escaped) {
	    # 受け手が escape 済みを期待しているのに、送り手がまだ escape されてないケース
	    $self->as_escaped($actual);
	  } else {
	    $self->as_lvalue($actual);
	  }
	} elsif (not defined argValue($_) and defined(my $v = $formal->flag)) {
	  # フラグ立てとして扱って良い型の場合。
	  $v;
	} else {
	  die $self->generror(q{argument '%s' requires value expression like '=...'}, $passThruVar);
	}
      });
    } @$primary;

    # element 引数
    foreach my $arg (lexpand($head), $body ? $body : (), lexpand($foot)) {
      my ($name, $expr) = @$arg[NODE_PATH, NODE_VALUE];
      my $formal = $add_arg->(ref $name ? $name->[-1] : $name);
      push @argExpr, ", ", $self->as_cast_to($formal, $expr);
    }

    # delegate の補間と、必須引数検査
    foreach my $i (0 .. $#{$widget->{arg_order}}) {
      next if defined $argOrder[$i];
      my $argName = $widget->{arg_order}[$i];
      if (my $inherit = $delegate_vars->{$argName}) {
	push @argExpr, ', '. $self->as_lvalue($inherit);
	$argOrder[$inherit->argno] = ++$actualNo;
      } elsif ($widget->{arg_dict}{$argName}->is_required) {
	die $self->generror("Argument '%s' is missing", $argName);
      }
    }
    sprintf q{(undef%s)[%s]}
      , join("", @argExpr), join(", ", map {defined $_ ? $_ : 0}
				 @argOrder[0 .. $#{$widget->{arg_order}}]);
  }
  sub as_lvalue {
    (my MY $self, my $var) = @_;
    my $type = $var->type;
    unless (defined $type) {
      die $self->generror("undefined var type");
    } elsif (my $sub = $self->can("as_lvalue_" . $type->[0])) {
      $sub->($self, $var);
    } else {
      "\$".$var->varname;
    }
  }
  sub as_lvalue_html {
    (my MY $self, my $var) = @_;
    '$html_'.$var->varname;
  }
  sub as_varcall_code {
    (my MY $self, my ($codeVar, $node)) = @_;
    return \ sprintf q{$%1$s && $%1$s->(%2$s)}, $codeVar->varname
      , $self->gen_putargs($codeVar->widget, $node);
    # XXX: デフォルト body のように、引数宣言が無いケースも考慮せよ。
  }
  sub as_varcall_delegate {
    (my MY $self, my ($var, $node)) = @_;
    my Widget $delegate = $var->widget;
    unless (defined $delegate) {
      Carp::croak "delegate target widget is empty!";
    }
    $self->ensure_generated(perl => my Template $tmpl = $delegate->{cf_folder});
    my $that = $tmpl == $self->{curtmpl} ? '$this' : $tmpl->{cf_entns};
    \ sprintf(q{%s->render_%s($CON, %s)}
	      , $that, $delegate->{cf_name}
	      , $self->gen_putargs($delegate, $node, $var->delegate_vars));
  }
  sub as_escaped {
    (my MY $self, my $var) = @_;
    if (my $sub = $self->can("as_escaped_" . $var->type->[0])) {
      $sub->($self, $var);
    } else {
      'YATT::Lite::Util::escape($'.$var->varname.')';
    }
  }

  #========================================
  sub as_cast_to {
    (my MY $self, my $var, my $value) = @_;
    my $type = $var->type->[0];
    my $sub = $self->can("as_cast_to_$type")
      or die $self->generror(q{Can't cast to type: %s}, $type);
    $sub->($self, $var, $value);
  }
  sub as_cast_to_text {
    (my MY $self, my ($var, $value)) = @_;
    return qtext($value) unless ref $value;
    $self->as_text(@$value);
  }
  sub as_cast_to_attr {
    shift->as_cast_to_text(@_);
  }
  sub as_cast_to_html {
    (my MY $self, my ($var, $value)) = @_;
    unless (ref $value) {
      $self->{curline} += numLines($value);
      return qtext($value);
    }
    join '.', shift->gen_as(text => \@AS_TEXT, 1, 1, @$value);
  }
  sub as_cast_to_scalar {
    (my MY $self, my ($var, $value)) = @_;
    'scalar(do {'.(ref $value ? $self->as_list(@$value) : $value).'})';
  }
  sub as_cast_to_bool {
    shift->as_cast_to_scalar(@_);
  }
  sub as_cast_to_list {
    (my MY $self, my ($var, $value)) = @_;
    '['.(ref $value ? $self->as_list(@$value) : $value).']';
  }
  sub as_cast_to_code {
    (my MY $self, my ($var, $value)) = @_;
    unless (ref $value eq 'ARRAY') {
      die $self->generror(q{Invalid text expression for variable '%s': %s}, $var->varname, $value);
    }
    local $self->{curtoks} = [@$value];
    my Widget $virtual = $var->widget;
    local $self->{scope} = $self->mkscope
      ({}, $virtual->{arg_dict} ||= {}, $self->{scope});
    local $self->{no_last_newline} = 1;
    q|sub {|. join('', $self->gen_getargs($virtual)
		   , $self->as_print("}"));
  }
  #----------------------------------------
  sub argName  {
    my ($arg, $skip) = @_;
    my $name = $$arg[NODE_PATH];
    if (array_of_array($name)) {
      Carp::croak("namelist is given for argName()!");
    } elsif (not (wantarray and ref $name)) {
      $name;
    } elsif (defined $skip) {
      @{$name}[$skip .. $#$name];
    } else {
      @$name;
    }
  }
  sub argValue { my $arg = shift; $$arg[NODE_VALUE] }
  sub passThruVar {
    my $arg = shift;
    if ($arg->[NODE_TYPE] == TYPE_ATT_NAMEONLY) {
      $$arg[NODE_PATH]
    } elsif ($arg->[NODE_TYPE] == TYPE_ATT_BARENAME) {
      $$arg[NODE_VALUE]
    }
  }
  #========================================
  sub from_pi {
    (my MY $self, my $node) = @_;
    # pi の ns 毎の役割を拡張可能に
    if (my $sub = $self->can("pi_of_" . $node->[NODE_PATH][0])) {
      return $sub->($self, $node);
    }
    $self->sync_curline($node->[NODE_LNO]);
    my @body = nx($node, 1);
    my ($fmt, $is_statement) = do {
      unless ($body[0] =~ s/^=+//) {
	(q{%s}, 1);
      } elsif (length $& >= 3) {
	q{do {%s}};
      } else {
	q{YATT::Lite::Util::escape(do {%s})};
      }
    };
    my $expr = join '', $self->as_list(@body);
    return \ "" unless $expr =~ /\S/;
    my $script = sprintf $fmt, $expr;
    $is_statement ? \ $script : $script;
  }
  #========================================
  sub from_lineinfo { }
  sub from_comment {
    (my MY $self, my $node) = @_;
    (undef, my ($nlines, $body)) = nx($node); # XXX: ok?
    $self->{curline} += $nlines;
    return \ ("\n" x $nlines);
  }
  sub from_lcmsg {
    (my MY $self, my $node) = @_;
    my ($path, $body) = nx($node);
    # $body is list of tokenlist.
    my $place = $self->{curtmpl}->fake_filename . ":" . $node->[NODE_LNO];

    # XXX: builtin xgettext
    if (@$body >= 2 or @$path >= 2) {
      # ngettext
      my ($uniq, $args, $numexpr) = ({}, []);
      my ($msgid, @plural) = map {
	scalar $self->gen_lcmsg($node, $_, $uniq, $args, \$numexpr);
      } @$body;
      if (my $sub = $self->{cf_lcmsg_sink}) {
	$sub->($place, $msgid, \@plural, $args);
      }
      sprintf q{sprintf($CON->ngettext(%s, %s), %s)}
	, join(", ", map {qtext($_)} ($msgid, @plural))
	  , $numexpr, join(", ", @$args);
    } else {
      my ($msgid, @args) = $self->gen_lcmsg($node, $body->[0]);
      if (my $sub = $self->{cf_lcmsg_sink}) {
	$sub->($place, $msgid, undef, \@args);
      }
      sprintf q{sprintf($CON->gettext(%s), %s)}
	, qtext($msgid), join(", ", @args);
    }
  }
  sub gen_lcmsg {
    (my MY $self, my ($node, $list, $uniq, $args, $ref_numeric)) = @_;
    my ($msgid, $vspec) = ("");
    if (@$list >= 2 and not ref $list->[0] and not ref $list->[-1]
	and $list->[0] =~ /^\n+$/ and $list->[-1] =~ /^\n+$/) {
      shift @$list; pop @$list;
      if (@$list and not ref $list->[0]) {
	$list->[0] =~ s/^\s+//;
      }
    }
    foreach my $item (@$list) {
      unless (ref $item) {
	# XXX: How about backslash?
	(my $cp = $item) =~ s/%/%%/g;
	$msgid .= $cp;
      } elsif ($item->[NODE_TYPE] != TYPE_ENTITY) {
	die "SYNERR";
      } elsif (ref ($vspec = $item->[NODE_BODY]) ne 'ARRAY'
	       || $vspec->[0] ne 'var') {
	# || @$vspec != 2
	die "SYNERR";
      } else {
	my $name = $vspec->[1];
	my $var = $self->find_var($name)
	  or die $self->generror(q{No such variable '%s'}, $name);
	unless ($uniq->{$name}) {
	  push @$args, $self->as_escaped($var);
	  $uniq->{$name} = 1 + keys %$uniq;
	}
	my $argno = $ref_numeric ? $uniq->{$name} . "\$" : '';
	# XXX: type==value is alias of scalar.
	if ($ref_numeric and $var->type->[0] eq 'scalar') {
	  $msgid .= "%${argno}d"; # XXX: format selection... but how? from entity?
	  if ($$ref_numeric) {
	    die "SYNERR";
	  }
	  $$ref_numeric = $self->as_lvalue($var);
	} else {
	  $msgid .= "%${argno}s";
	}
      }
    }
    $msgid =~ s/\r//g;
    # XXX: Unfortunately, this is not good for multiline message.
    wantarray ? ($msgid, lexpand($args)) : $msgid;
  }

  sub from_elematt {
    (my MY $self, my $node) = @_;
    # <:yatt:elematt>....</:yatt:elematt> は NOP へ。
    return \ "";
  }
  sub from_entity {
    (my MY $self, my $node) = @_;
    (undef, my @pipe) = nx($node);
    # XXX: expand のように全体に作用するものも有るから、これも現在の式を渡す方式にすべき。
    # 受け手が有るかどうかで式の生成方式も変わる?なら token リスト削りが良いか。
    $self->gen_entpath($self->{needs_escaping}, @pipe);
  }

  # XXX: lxnest を caller が呼ぶ必要が有る...が、それって良いことなのか...
  sub gen_entpath {
    (my MY $self, my ($escape_now)) = splice @_, 0, 2;
    return '' unless @_;
    local $self->{needs_escaping} = 0;
    if (@_ == 1 and ($_[0][0] eq 'call'
		       or $_[0][0] eq 'var' and $self->{cf_prefer_call_for_entity})
	and my $macro = $self->can("entmacro_$_[0][1]")) {
      return $macro->($self, $_[0]);
    }
    # XXX: path の先頭と以後は分けないと！ as_head, as_rest?
    my @result = map {
      my ($type, @rest) = @$_;
      unless (my $sub = $self->can("as_expr_$type")) {
	die $self->generror("unknown entity item %s", terse_dump($type));
      } else {
	$sub->($self, \$escape_now, @rest);
      }
    } @_;
    return '' unless @result;
    my $result = @result > 1 ? join("->", @result) : $result[0];
    # XXX: これだと逆に、 html 型が困る。
    if (not $escape_now or ref $result) {
      $result;
    } else {
      sprintf(q{YATT::Lite::Util::escape(%s)}, $result);
    }
  }
  # XXX: partial logic dup with ensure_entity_is_declared
  sub find_entity {
    (my MY $self, my ($name)) = @_;
    my Template $tmpl = $self->{curtmpl};
    $tmpl->{Item}{"entity\0$name"}
      // $tmpl->{cf_entns}->can("entity_$name");
  }
  sub ensure_entity_is_declared {
    (my MY $self, my ($name)) = @_;
    my Template $tmpl = $self->{curtmpl};
    if ($tmpl->{Item}{"entity\0$name"}) {
      # Found embedded entity definition.
      return;
    }
    unless ($tmpl->{cf_entns}->can("entity_$name")) {
      die $self->generror(q!No such entity in namespace "%s": %s!
			  , $tmpl->{cf_entns}, $name);
    }
  }
  sub gen_entlist {
    (my MY $self, my ($escape_now)) = splice @_, 0, 2;
    my @list = map {
      $self->gen_entpath($escape_now, lxnest($_))
    } @_;
    wantarray ? @list : join ", ", @list;
  }
  sub as_expr_var {
    (my MY $self, my ($esc_later, $name)) = @_;
    if (my $var = $self->find_var($name)) {
      if (my $sub = $self->can("as_expr_var_" . $var->type->[0])) {
	$sub->($self, $esc_later, $var, $name);
      } else {
	$self->as_lvalue($var);
      }
    } elsif ($self->find_entity($name)) {
      $self->gen_entcall($name);
    } else {
      die $self->generror(q{No such variable '%s'}, $name);
    }
  }
  sub as_expr_var_html {
    (my MY $self, my ($esc_later, $var, $name)) = @_;
    $$esc_later = 0;
    $self->as_lvalue_html($var);
  }
  sub as_expr_var_attr {
    (my MY $self, my ($esc_later, $var, $name)) = @_;
    # $$esc_later = 0;
    (undef, my $attname) = @{$var->type};
    sprintf(q{YATT::Lite::Util::named_attr('%s', $%s)}
	    , $attname // $name, $name);
  }
  sub as_expr_call {
    (my MY $self, my ($esc_later, $name)) = splice @_, 0, 3;
    # XXX: 受け側が print か、それとも一般の式か。 print なら \ すべき。
    # entns があるか、find_code_var か。さもなければエラーよね。
    if (my $var = $self->find_callable_var($name)) {
      # code 引数の中の引数のデフォルト値の中に、改行が有ったら？？
      # XXX: body の引数宣言が無い場合に <yatt:body/> は、ちゃんと呼び出せるか?
      return $self->as_expr_call_var($var, $name, @_);
    }

    $self->ensure_entity_is_declared($name);

    $self->gen_entcall($name, @_);
  }
  sub gen_entcall {
    (my MY $self, my ($name, @rest)) = @_;
    my $call = sprintf '$this->entity_%s(%s)', $name
      , scalar $self->gen_entlist(undef, @rest);
    $call;
  }
  sub as_expr_call_var {
    (my MY $self, my ($var, $name, @args)) = @_;
    if (my $sub = $self->can("as_expr_call_var_" . $var->type->[0])) {
      $sub->($self, $var, $name, @args);
    } else {
      \ sprintf q{$%1$s && $%1$s->(%2$s)}, $name
	, scalar $self->gen_entlist(undef, @args);
    }
  }
  sub as_expr_call_var_attr {
    (my MY $self, my ($var, $name, @args)) = @_;
    (undef, my $attname) = @{$var->type};
    sprintf q|YATT::Lite::Util::named_attr('%s', %s)|
      , $attname // $name
	, join ", ", "\$".$name, $self->gen_entlist(undef, @args);
  }
  sub as_expr_invoke {
    (my MY $self, my ($esc_later, $name)) = splice @_, 0, 3;
    sprintf '%s(%s)', $name
      , scalar $self->gen_entlist(undef, @_);
  }

  sub as_expr_expr {
    (my MY $self, my ($esc_later, $expr)) = @_;
    $expr;
  }
  sub as_expr_array {
    (my MY $self, my ($esc_later)) = splice @_, 0, 2;
    '['.$self->gen_entlist(undef, @_).']';
  }
  sub as_expr_hash {
    (my MY $self, my ($esc_later)) = splice @_, 0, 2;
    '{'.$self->gen_entlist(undef, @_).'}';
  }
  sub as_expr_aref {
    (my MY $self, my ($esc_later, $node)) = @_;
    '['.$self->gen_entpath(undef, lxnest($node)).']';
  }
  sub as_expr_href {
    (my MY $self, my ($esc_later, $node)) = @_;
    '{'.$self->gen_entpath(undef, lxnest($node)).'}';
  }
  sub as_expr_prop {
    (my MY $self, my ($esc_later, $name)) = @_;
    if ($self->{cf_prefer_call_for_entity}) {
      $name
    } elsif ($name =~ /^\w+$/) {
      "{$name}"
    } else {
      '{'.qtext($name).'}';
    }
  }
  sub as_expr_text {
    (my MY $self, my ($esc_later, $expr)) = @_;
    qqvalue($expr);
  }
  #========================================
}

sub make_arg_spec {
  my ($pack, $dict, $order) = splice @_, 0, 3;
  foreach my $name (@_) {
    $dict->{$name} = @$order;
    push @$order, $name;
  }
}

sub feed_arg_spec {
  (my MY $trans, my ($args, $arg_dict, $arg_order)) = splice @_, 0, 4;
  my ($found, $nth);
  foreach my $arg (lexpand($args)) {
    my ($name, @ext) = argName($arg); # XXX: <yatt:my var:type=value /> は？
    unless (defined $name) {
      $name = $arg_order->[$nth++]
	or die $trans->generror("Too many args");
    }
    defined (my $argno = $arg_dict->{$name})
      or die $trans->generror("Unknown arg '%s'", $name);

    if (defined (my $prevNode = $_[$argno])) {
      die $trans->generror("You may forgot '=' between %s and %s"
                           , $prevNode->[NODE_PATH]
                           , $trans->{curtmpl}->node_outer_source($arg));
    }

    $_[$argno] = $arg;
    $found++;
  }
  $found;
}

{
  MY->make_arg_spec(\ my %args, \ my @args, qw(if unless));
  sub macro_if {
    (my MY $self, my $node) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);
    my @arms = do {
      $self->feed_arg_spec($primary, \%args, \@args
			   , my ($if, $unless))
	or die $self->generror("Not enough arguments!");
      my ($kw, $cond) = do {
	if ($if) { (if => $if) }
	elsif ($unless) { (unless => $unless) }
	else { die "??" }
      };
      ["$kw (%s) ", $cond->[NODE_VALUE], lexpand($body->[NODE_VALUE])];
    };

    # いかん、 cond を生成するなら、body も生成しておかないと、行番号が困る。

    foreach my $arg (lexpand($foot)) {
      (undef, my $kw) = @{$arg->[NODE_PATH]};
      unless ($kw eq 'else') {
        die $self->generror("Unknown option for <%s>: %s"
                            , join(":", @$path), $kw);
      }
      $self->feed_arg_spec($arg->[NODE_ATTLIST], \%args, \@args
                           , my ($if, $unless));
      my ($fmt, $guard) = do {
        if ($if) {
          (q{elsif (%s) }, $if->[NODE_VALUE]);
        } elsif ($unless) {
          (q{elsif (not %s) }, $unless->[NODE_VALUE]);
        } else {
          (q{else }, undef);
        }
      };
      push @arms, [$fmt, $guard, lexpand($arg->[NODE_VALUE])]
    }
    my @expr = map {
      my ($fmt, $guard, @body) = @$_;
      local $self->{scope} = $self->mkscope({}, $self->{scope});
      local $self->{curtoks} = [@body];
      (defined $guard
       ? sprintf($fmt, join "", $self->as_list(lexpand($guard))) : $fmt)
	.'{'.$self->cut_next_nl.$self->as_print('}');
    } @arms;
    \ join "", @expr, $self->cut_next_nl;
  }
}

sub is_spread {
  ref $_[0] eq 'ARRAY'
    && @{$_[0]} == 4
    && $_[0][0] eq ''
    && $_[0][1] eq ''
    && $_[0][2] eq ''
}
sub take_spread_name {
  $_[0]->[3];
}

{
  sub macro_my {
    (my MY $self, my $node) = @_;
    my ($path, $body, $maybeWrappedAttlist, $head, $foot) = nx($node);
    my $has_body = $body && @$body ? 1 : 0;
    my $simple_adder = sub {
      my ($default_type, $arg, $valNode, $skip) = @_;
      my ($name, $typename) = argName($arg, $skip);
      if (my $oldvar = $self->find_var($name)) {
	die $self->generror("Conflicting variable '%s'"
			    ." (previously defined at line %s)"
			    , $name, $oldvar->lineno // '(unknown)');
      }
      $typename ||= $default_type;
      if (my $sub = $self->can("_macro_my_$typename")) {
	$sub->($self, $node, $name, $valNode);
      } else {
	my $var = $self->{scope}[0]{$name}
	  = $self->mkvar_at(undef, $typename, $name)
	  or die $self->generror("Unknown type '%s' for variable '%s'"
				 , $typename, $name);
	# typename == source の時が問題だ。
	my $expr = 'my '.$self->as_lvalue($var);
	my $value = argValue($valNode);
	$expr .= defined $value ? (' = '.$self->as_cast_to($var, $value)) : ';';
      }
    };
    my $adder = sub {
      my ($default_type, $arg, $valNode, $skip) = @_;
      if (array_of_array($arg->[NODE_PATH])) {
        my (@pre, @main);
        foreach my $nameSpec (@{$arg->[NODE_PATH]}) {
          my $is_spread = is_spread($nameSpec->[NODE_PATH]);
          my ($name, $typename) = do {
            if ($is_spread) {
              (take_spread_name($nameSpec->[NODE_PATH]), 'list')
            } else {
              argName($nameSpec, $skip);
            }
          };

          if (my $oldvar = $self->find_var($name)) {
            die $self->generror("Conflicting variable '%s'"
                                ." (previously defined at line %s)"
                                , $name, $oldvar->lineno // '(unknown)');
          }
          $typename ||= $default_type;
          if (my $sub = $self->can("_macro_my_$typename")) {
            ...
          }
          my $var = $self->{scope}[0]{$name}
            = $self->mkvar_at(undef, $typename, $name)
            or die $self->generror("Unknown type '%s' for variable '%s'"
                                   , $typename, $name);

            if (@pre) {
              die $self->generror("Multiple spread op is prohibited");
            }
          if ($is_spread) {
            push @pre, 'my '.$self->as_lvalue($var).' = []';
            push @main, '@'.$self->as_lvalue($var);
          } else {
            push @main, 'my '.$self->as_lvalue($var);
          }
        }
        my $main = sprintf(q|(%s) = (%s)|, join(", ", @main)
                           , join("", $self->as_list(lexpand(argValue($valNode)))));
        (@pre, $main);
      } else {
        $simple_adder->(@_)
      }
    };
    my $primary = $self->node_unwrap_attlist($maybeWrappedAttlist);
    my @assign;
    foreach my $arg (@{$primary}[0 .. $#$primary-$has_body]) {
      push @assign, $adder->(text => $arg, $arg);
    }
    if ($has_body) {
      my $arg = $primary->[-1];
      # XXX: ここは統合できるはず。ただし、NESTED の時に name が無いことを確認すべき。
      if ($arg->[NODE_TYPE] == TYPE_ATT_NESTED) {
	foreach my $each (@{$arg->[NODE_BODY]}) {
	  push @assign, $adder->(html => $each, $body);
	}
      } else {
	push @assign, $adder->(html => $arg, $body);
      }
    }
    foreach my $arg (map {lexpand($_)} $head, $foot) {
      push @assign, $adder->(text => $arg, $arg, 1); # Skip leading :yatt:
    }
    \ join "; ", @assign;
  }
  sub _macro_my_code {
    (my MY $self, my ($node, $name, $valNode)) = @_;
    my $var = $self->{scope}[0]{$name} = $self->mkvar_at(undef, code => $name);
    local $self->{curtoks} = [lexpand(argValue($valNode))];
    'my '.$self->as_lvalue($var).' = '.q|sub {| . $self->as_print('}');
  }
  sub _macro_my_source {
    (my MY $self, my ($node, $name, $valNode)) = @_;
    my $var = $self->{scope}[0]{$name} = $self->mkvar_at(undef, text => $name);
    'my '.$self->as_lvalue($var).' = '
      .join(q|."\n".|, map {qtext($_)}
	    split /\n/, $self->{curtmpl}->node_body_source($node));
  }

  sub macro_block {
    (my MY $self, my $node) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);
    $self->macro_scoped_block_of_tokens(+{}, @{argValue($body)});
  }

  sub macro_scoped_block_of_tokens {
    (my MY $self, my ($scope, @tokens)) = @_;
    local $self->{scope} = $self->mkscope($scope, $self->{scope});
    local $self->{curtoks} = \@tokens;
    \ ('{'.$self->as_print('}'));
  }
}

{
  MY->make_arg_spec(\ my %args, \ my @args, qw(list my nth));
  sub macro_foreach {
    (my MY $self, my ($node, $opts)) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);
    $self->feed_arg_spec($primary, \%args, \@args
			 , my ($list, $my, $nth))
      or die $self->generror("Not enough arguments for <yatt:foreach>!");

    my ($prologue, $continue, $epilogue) = ('', '', '');

    unless (defined $list) {
      die $self->generror("no list= is given");
    }

    my %local;
    my $loopvar = do {
      if ($my) {
	my ($x, @type) = lexpand($my->[NODE_PATH]);
	my $varname = $my->[NODE_VALUE];
	$local{$varname} = $self->mkvar_at(undef, $type[0] || '' => $varname);
	"my \$" . $varname;
      } else {
	# _ は？ entity 自体に処理させるか…
	''
      }
    };

    my ($nth_var, @nth_type) = do {
      if ($nth and my $vn = $nth->[NODE_VALUE]) {
	my ($x, @t) = lexpand($nth->[NODE_PATH]);
	if ($vn =~ /^(\w+)$/) {
	  ($vn, @t);
	} else {
	  die $self->generror("Invalid nth var: %s", $nth);
	}
      }
    };
    if ($nth_var) {
      $local{$nth_var} = $self->mkvar_at(undef, $nth_type[0] || '' => $nth_var);

      $prologue .= sprintf q{ my $%s = 1;}, $nth_var;
      $continue .= sprintf q{ $%s++;}, $nth_var;
    }

    my $fmt = q|{%4$s; foreach %1$s (%2$s) %3$s continue {%5$s} %6$s}|;
    my $listexpr = do {
      unless (my $passThruVarName = passThruVar($list)) {
	$self->as_list(lexpand($list->[NODE_VALUE]));
      } elsif (my $found_var = $self->find_var($passThruVarName)) {
	unless ($found_var->is_type('list')) {
	  die $self->generror(q{%s - %s should be list type.}
			      , join(":", @$path), $passThruVarName);
	}
	'@'.$self->as_lvalue($found_var);
      } else {
	die die $self->generror("Unknown variable for foreach list: '%s'", $passThruVarName);
      }
    };

    local $self->{curtoks} = [@{argValue($body)}];

    # <yatt:foreach ..>\n
    #                  ↑This newline should be removed.
    my $statements = "{";
    if (my $nl = $self->cut_next_nl) {
      $statements .= $nl;
    }

    # ___</yatt:foreach>
    # ↑ This indent is messy too.
    if (@{$self->{curtoks}} and $self->{curtoks}[-1] =~ /^[\ \t]+\z/) {
      pop @{$self->{curtoks}};
    }

    #    ...\n         ← not to remove this newline.
    # </yatt:foreach>
    local $self->{no_last_newline} = 0;

    local $self->{scope} = $self->mkscope(\%local, $self->{scope});
    $statements .= $self->as_print('}');

    if ($opts and $opts->{fragment}) {
      ($fmt, $loopvar, $listexpr, $statements
       , $prologue, $continue, $epilogue);
    } else {
      \ sprintf $fmt, $loopvar, $listexpr, $statements
	, $prologue, $continue, $epilogue;
    }
  }
}

{
  MY->make_arg_spec(\ my %args, \ my @args, qw(if unless local));
  sub macro_return {
    (my MY $self, my $node) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);

    if ($foot || $head) {
      die $self->generror("Unsupported syntax: foot");
    }

    $self->feed_arg_spec($primary, \%args, \@args
                         , my ($if, $unless, $local));

    my ($fmt, $guard) = do {
      if ($if || $unless) {
        # conditional return
        # if ()
        my ($kw, $cond) = do {
          if ($if) { (if => $if) }
          elsif ($unless) { (unless => $unless) }
          else { die "??" }
        };
        ("$kw (%s) ", $cond->[NODE_VALUE]);
      } else {
        ();
      }
    };

    my ($begin, $end) = do {
      if ($local) {
        ('{', ' return}');
      } else {
        ('{YATT::Lite::Util::rewind($CON); ', ' die \"DONE"}');
      }
    };

    my $expr = do {
      local $self->{scope} = $self->mkscope({}, $self->{scope});
      local $self->{curtoks} = [lexpand($body->[NODE_VALUE])];
      (defined $guard
       ? sprintf($fmt, join "", $self->as_list(lexpand($guard))) : '')
	.$begin.$self->cut_next_nl.$self->as_print($end);
    };

    \ $expr;
  }
}

# A skeleton for new macro.
# {
#   MY->make_arg_spec(\ my %args, \ my @args, qw(if unless));
#   sub macro_return {
#     (my MY $self, my $node) = @_;
#     my ($path, $body, $primary, $head, $foot) = nx($node);
#
#     \ ($self->dump_as_comment_line($self->node_as_hash($node)));
#   }
# }

sub dump_as_comment_line {
  (my MY $self, my $node) = @_;
  my $str = terse_dump($node);
  $str =~ s/^/# /mg;
  $str."\n";
}

# A skelton for new entmacro
# sub entmacro_XXX {
#   (my MY $self, my $node) = @_;
#   sprintf(q{YATT::Lite::Util::escape(%s)}, terse_dump($node));
# }

sub entmacro_scalar {
  (my MY $self, my $node) = @_;
  my (@expr) = $self->gen_entlist(undef, entx($node));
  sprintf q|scalar(%s)|, join "", @expr;
}

sub entmacro_not {
  (my MY $self, my $node) = @_;
  my (@expr) = $self->gen_entlist(undef, entx($node));
  sprintf q|(not(%s))|, join "", @expr;
}

sub entmacro_and {
  (my MY $self, my $node) = @_;
  my (@expr) = $self->gen_entlist(undef, entx($node));
  "(".join(" and ", map {"($_)"} @expr).")";
}

sub entmacro_or {
  (my MY $self, my $node) = @_;
  my (@expr) = $self->gen_entlist(undef, entx($node));
  "(".join(" or ", map {"($_)"} @expr).")";
}

sub entmacro_undef {
  (my MY $self, my $node) = @_;
  my (@expr) = $self->gen_entlist(undef, entx($node));
  sprintf q|(undef(%s))|, join "", @expr;
}

sub entmacro_with_ignoring_die {
  (my MY $self, my $node) = @_;
  my (@expr) = $self->gen_entlist(undef, entx($node));
  sprintf q|($this->YATT->with_ignoring_die(sub {%s}))|, join "", @expr;
}

sub entmacro_if {
  (my MY $self, my $node) = @_;
  my ($cond, $then, $else) = $self->gen_entlist(undef, entx($node));
  sprintf q|do {(%s) ? (%s) : (%s)}|
    , map {ref $_ ? $$_ : $_} $cond, $then, $else || q{''};
}

sub entmacro_ifeq {
  (my MY $self, my $node) = @_;
  my ($val, $what, $then, $else) = $self->gen_entlist(undef, entx($node));
  sprintf q|do {((%s // '') eq (%s // '')) ? (%s) : (%s)}|
    , map {ref $_ ? $$_ : $_} $val, $what, $then, $else || q{''};
}

sub entmacro_value_checked {
  (my MY $self, my $node) = @_;
  my (@list) = $self->gen_entlist(undef, entx($node));
  unless (@list == 2) {
    die $self->generror("Invalid number of args: value_checked(VALUE, HASH)");
  }
  sprintf q|YATT::Lite::Util::value_checked(%s)|
    , join ", ", map {ref $_ ? $$_ : $_} @list;
}

sub entmacro_value_selected {
  (my MY $self, my $node) = @_;
  my (@list) = $self->gen_entlist(undef, entx($node));
  unless (@list == 2) {
    die $self->generror("Invalid number of args: value_selected(VALUE, HASH)");
  }
  sprintf q|YATT::Lite::Util::value_selected(%s)|
    , join ", ", map {ref $_ ? $$_ : $_} @list;
}

sub entmacro_lexpand {
  (my MY $self, my $node) = @_;
  q|@{|.$self->gen_entpath(undef, map {lxnest($_)} entx($node)).q|}|;
}

sub entmacro_render {
  (my MY $self, my $node) = @_;
  my ($wname, @expr) = $self->gen_entlist(undef, entx($node));
  \ sprintf q{YATT::Lite::Util::safe_render($this, $CON, %s, %s)}
    , $wname, join(", ", @expr);
}

sub entmacro_dispatch_all {
  (my MY $self, my $node) = @_;
  my ($prefix, $nargs, @list) = $self->gen_entlist(undef, entx($node));
  \ sprintf q{YATT::Lite::Util::dispatch_all($this, $CON, %s, %s, %s)}
    , $prefix, $nargs, join(", ", @list);
}

sub entmacro_dispatch_one {
  (my MY $self, my $node) = @_;
  my ($prefix, $nargs, @list) = $self->gen_entlist(undef, entx($node));
  \ sprintf q{YATT::Lite::Util::dispatch_one($this, $CON, %s, %s, %s)}
    , $prefix, $nargs, join(", ", @list);
}

sub entmacro___WIDGET__ {
  (my MY $self, my $node) = @_;
  my Widget $widget = $self->{curwidget};
  qtext($widget->{cf_name});
}

sub entmacro_show_expr {
  (my MY $self, my $node) = @_;
  require YATT::Lite::LRXML::FormatEntpath;
  my (@pipe) = entx($node);
  \ sprintf q{$this->YATT->render_into($CON, %s, [%s, %s])}
    , qtext('show_expr')
    , qtext(YATT::Lite::LRXML::FormatEntpath::format_entpath(@pipe))
    , join(", ", $self->gen_entpath(undef, @pipe));
}

use YATT::Lite::Breakpoint qw(break_load_cgen break_cgen);
break_load_cgen();

1;
