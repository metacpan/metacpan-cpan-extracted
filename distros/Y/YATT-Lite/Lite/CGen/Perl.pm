package YATT::Lite::CGen::Perl;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

require 5.010; # For named capture.

use constant DEBUG_MRO => $ENV{DEBUG_YATT_MRO};

use YATT::Lite::Core qw(Folder Template Part Widget Action Entity ArgMacro Import);
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
  use YATT::Lite::Util qw(lexpand numLines globref terse_dump catch ckrequire);
  use YATT::Lite::ConnectionProxy;
  use Carp;
  #========================================
  sub list_inheritance {
    (my MY $self, my Template $tmpl) = @_;
    # XXX: Duplicate detection should be handled higer layer.
    my %dup;
    map {
      my Folder $f = $_;
      unless (defined $f->{entns}) {
	die "BUG: EntNS is empty for ".terse_dump($f->{name})."!";
      }
      if ($dup{$f->{entns}}++) {
	()
      } else {
	$f->{entns}
      }
    } $tmpl->list_base
  }
  sub setup_inheritance_for {
    (my MY $self, my $spec, my Template $tmpl) = @_;
    unless (defined $tmpl->{entns}) {
      die "BUG: EntNS is empty for '$tmpl->{name}'!";
    }
    my $glob = globref($$tmpl{entns}, 'ISA');
    # XXX: base change should be reflected when reloaded, but...
    unless (defined $glob) {
      die "BUG: ISA glob for '$tmpl->{name}' is empty!";
    }
    $self->ensure_generated_for_folders($spec, $tmpl->list_base);
    my @isa = $self->list_inheritance($tmpl);
    if (grep {not defined} @isa) {
      die "BUG: ISA for '$tmpl->{name}' contains undef!";
    }
    if (my $err = catch {
      *$glob = \@isa;
    }) {
      die $self->generror("Can't set ISA for '%s' as [%s]: %s"
			  , $tmpl->{name}
			  , join(", ", @isa)
			  , $err
			);
    }
  }
  sub generate_inheritance {
    (my MY $self, my Template $tmpl) = @_;
    my @isa = $self->list_inheritance($tmpl);
    my $mro = mro::get_mro($tmpl->{entns});
    print STDERR "($mro) [$tmpl->{path}] $tmpl->{entns}::ISA = @isa\n"
      if DEBUG_MRO;
    sprintf q{use mro '%s'; our @ISA = qw(%s); }, $mro, join " ", @isa;
  }
  #========================================
  sub generate_page_scope {
    (my MY $self, my Template $tmpl) = @_;
    my $scope = {};
    if ($self->{pagevars} and defined (my $page_name = $tmpl->page_name)) {
      # XXX: mtime check → auto termination
      ckrequire($self->{pagevars});
      my $vars = $self->{pagevars}->find_consts($page_name);
      foreach my $name (keys %$vars) {
        my $type = $self->{pagevars}->const_type($vars->{$name});
        $scope->{$name} = $self->mkvar_at(undef, $type => $name);
      }
    }
    $scope;
  }
  sub generate_preamble {
    (my MY $self, my Template $tmpl) = @_;
    $tmpl ||= $self->{_curtmpl};
    my @stats;
    unless ($self->{no_lineinfo}) {
      my $line = qq{#line }. $self->{_curline};
      if (defined(my $fn = $tmpl->fake_filename)) {
	# name is dummy filename (if path is undef).
	$line .= qq{ "$fn"};
      }
      push @stats, $line .= "\n";
    }
    push @stats, sprintf q{package %s; use strict; use warnings; use 5.010; }
      , $$tmpl{entns};
    if ($self->{pagevars} and defined (my $page_name = $tmpl->page_name)) {
      push @stats, "use $self->{pagevars} (qw($page_name), missing_ok => 1);";
    }
    push @stats, $self->generate_inheritance($tmpl);
    push @stats, "use utf8; " if $$tmpl{utf8};
    push @stats, q|no warnings qw(redefine); | if $$tmpl{age}++;
    push @stats, sprintf q|sub filename {__FILE__}; |;
    @stats
  }
  sub generate_page {
    # XXX: 本物へ。 public フラグ?
    shift->generate_widget(@_);
  }
  sub generate_widget {
    (my MY $self, my Widget $widget, my ($widget_name, $tmpl_path)) = @_;
    if ($widget->{suppressed}) {
      # Implicit default widget which contains no content.
      return $self->sync_curline($widget->{endln});
    }
    break_cgen();
    local $self->{_curwidget} = $widget;
    # XXX: calling convention 周り, body の code 型
    local $self->{_scope} = $self->mkscope
      ({}, $widget->{_var_dict}, $widget->{_arg_dict} ||= {}
       , {this => $self->mkvar_at(undef, text => 'this')
	  , 'CON' => $self->mkvar_at(undef, text => 'CON')
	  , '_' => $self->mkvar_at(undef, text => '_')}
       , $self->{_scope} # page global scope
      );
    local $self->{_curtoks} = [@{$widget->{_tree}}];
    ($self->sync_curline($widget->{startln})
     , "sub render_$$widget{name} {"
     , $self->gen_preamble($widget)
     , $self->gen_getargs($widget, not $widget->{implicit})
     , $self->as_print("}")
    );
  }
  sub generate_action {
    (my MY $self, my Action $action) = @_;
    # XXX: 改行の調整が必要。
    my @src = ($self->sync_curline($action->{startln})
               , "sub do_$$action{name} {");
    my $src = $self->{_curtmpl}->part_body_source($action);

    if (lexpand($action->{_arg_order})
        or $src !~ m{^([\ \t\r\n]*)my\s*\([^;\)]+\)\s*=\s*\@_\s*;}) {
      # If an action has no arguments
      # and its source doesn't start with my (...) = @_;,
      # insert preamble and getargs.
      push @src, $self->gen_preamble($action)
        , $self->gen_getargs($action, not $action->{implicit});
    }

    my $has_nl = $src =~ s/\r?\n\Z//;
    $self->{_curline} = $action->{bodyln} + numLines($src)
      + ($has_nl ? 1 : 0);
    (@src, $src, "}");
  }

  # XXX: As you see, dup code.
  # XXX: Should define common base class for Action and Entity.
  sub generate_entity {
    (my MY $self, my Entity $entity) = @_;
    # XXX: 改行の調整が必要。
    my @src = ($self->sync_curline($entity->{startln})
               , "sub entity_$$entity{name} {");
    my $src = $self->{_curtmpl}->part_body_source($entity);

    if (lexpand($entity->{_arg_order})
        or $src !~ m{^([\ \t\r\n]*)my\s*\([^;\)]+\)\s*=\s*\@_\s*;}) {
      # If an entity has no arguments
      # and its source doesn't start with my (...) = @_;,
      # insert preamble and getargs.
      push @src, q{ my ($this) = shift; my $CON = $this->CON;}
        , $self->gen_getargs($entity, not $entity->{implicit});
    }

    my $has_nl = $src =~ s/\r?\n\Z//;
    $self->{_curline} = $entity->{bodyln} + numLines($src)
      + ($has_nl ? 1 : 0);
    (@src, $src, "}");
  }

  # <!yatt:import> の alias Part は glob 代入として生成する。GH-256
  # coderef コピー (\&) にするとソース再コンパイルへ追随できないので必ず glob。
  sub generate_import {
    (my MY $self, my Import $import) = @_;
    my Template $tmpl = $self->{_curtmpl};
    my Part $src = $import->resolve_alias($self->{vfs});
    my Template $srcTmpl = $src->{folder};
    ($self->sync_curline($import->{startln})
     , sprintf(q{*%s::%s = *%s::%s; }
               , $tmpl->{entns}, $import->method_name
               , $srcTmpl->{entns}, $src->method_name));
  }

  #========================================
  sub gen_preamble {q{ my ($this, $CON) = splice @_, 0, 2;}}
  sub gen_getargs {
    (my MY $self, my Widget $widget, my $for_decl) = @_;
    my @res;
    foreach my $argName (lexpand($widget->{_arg_order})) {
      # デフォルト値と、型と。
      my $var = $widget->{_arg_dict}{$argName};
      push @res, $for_decl ? $self->sync_curline($var->lineno) : ()
	, sprintf q{ my %s = %s;}, $self->as_lvalue($var)
	  , $self->as_getarg($var);
      # shift しない方が、debug 時に stack trace に引数値が見えて嬉しい。
    }
    # <!yatt:widget ...> 末尾の改行
    push @res, "\n" and $self->{_curline}++ if $for_decl;
    (@res, $self->sync_curline($widget->{bodyln})
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
    push @{$self->{_curtoks}}, @$localtoks if $localtoks;
    local $self->{_needs_escaping} = 1;
    my (@result, @queue) = '';
    # curline は queue 詰めの外側で操作する。
    # $last は一回だけ出力するように、undef が必要。
    my $flush = sub {
      my ($has_nl, $task, $pad) = @_;
      push @result, $pad if defined $pad;
      push @result, q{print $CON (}.join(", ", @queue).");" if @queue;
      # もう token が残っていなくて、かつ $last が与えられていたら、 $last を足す。
      push @result, $task->() if $task;
      $result[-1] .= $last and undef $last if $last and not @{$self->{_curtoks}};
      # 明示 "\n" が来ていた場合は、 ";" と同時に改行する。
      $result[-1] .= "\n" if $has_nl;
      undef @queue;
    };
    while (@{$self->{_curtoks}}) {
      my $node = shift @{$self->{_curtoks}};
      unless (ref $node) {
        # 次が element な時は、先行する indent を捨てる
        if (@{$self->{_curtoks}} and ref $self->{_curtoks}[0]
              and $self->{_curtoks}[0][0] == TYPE_ELEMENT
              and $node =~ /^[\ \t]+\z/
          ) {
          next;
        }
	# text node の末尾が改行で終わっている場合、 明示的に "\n" を生成する
	my $has_nl = $node =~ s/\r?\n\Z//s;
	push @queue, qtext($node) if $node ne ''; # 削ったら空になるかも。
	$self->{_curline} += numLines($node);
	$self->{_curline}++ if $has_nl;
	push @queue, q{"\n"} if $has_nl
	  and @{$self->{_curtoks}} || not $self->{yatt_no_last_newline};
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
      # if (@{$self->{_curtoks}} and $self->{_curtoks}[0] eq "\n") {
      #   shift @{$self->{_curtoks}};
      # }
    }
    $flush->();
    join " ", @result;
  }
  sub gen_as {
    (my MY $self, my ($type, $dispatch, $escape, $text_quote))
      = splice @_, 0, 5;
    local $self->{_needs_escaping} = $escape;
    my (@result);
    # Empty expr (ie <:yatt:arg></:yatt:arg>) should generate q|| as code.
    if (not @_ and $text_quote) {
      push @result, qtext('');
    }
    while (@_) {
      my $node = shift;
      unless (ref $node) {
	push @result, ($text_quote ? qtext($node) : $node);
	$self->{_curline} += numLines($node);
	next;
      }
      # 許されるのは entity だけでは？ でもないか。 element 引数の時は、capture したいはず。
      my $sub = $dispatch->[$node->[0]] or do {
        die $self->generror("gen_as %s: Unknown node type: %d"
                            , $type, $node->[0]);
      };
      my $expr = $sub->($self, $node);
      next unless defined $expr;
      if (ref $expr and not wantarray) {
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
  $AS_TEXT[TYPE_PI]       = \&from_pi;
  $AS_TEXT[TYPE_ELEMENT]  = \&from_element; # XXX: ?? Used??
  $AS_TEXT[TYPE_ATT_NESTED]  = sub {undef}; # gen_as が scalar 受けゆえ
  # as_text は、escape 不要。なぜなら、 print 時に escape されるから。
  # でも、 escape 有無を flag で渡せた方が、 html 型にも使えて便利では?
  # というか、 html 型には capture が必要か。 capture は buffering したいよね？
  sub as_text {
    my ($self, @rest) = @_;
    local $self->{_scope} = $self->mkscope({}, $self->{_scope});
    my @expr = $self->gen_as(text => \@AS_TEXT, 0, 1, @rest);
    $self->gen_maybe_captured(@expr);
  }

  our @AS_LIST;
  $AS_LIST[TYPE_ENTITY]   = \&from_entity;
  $AS_LIST[TYPE_PI]       = \&list_from_pi;
  $AS_LIST[TYPE_ELEMENT]  = \&list_from_element;
  $AS_LIST[TYPE_ATT_NESTED] = sub {undef}; # XXX: 微妙
  sub as_list {
    shift->gen_as(list => \@AS_LIST, 0, 0, @_);
  }
  # as_list は式だけを受け取る。要素や <?perl ?> は、出力を捕捉できる
  # text/html の値の中でだけ使える (as_text, as_cast_to_html)。
  sub list_from_element {
    (my MY $self, my $node) = @_;
    die $self->generror_at($node->[NODE_LNO]
                           , q{Element <%s> is not allowed in expression}
                           . q{ (only in text or html value)}
                           , join(":", @{$node->[NODE_PATH]}));
  }
  sub list_from_pi {
    (my MY $self, my $node) = @_;
    die $self->generror_at($node->[NODE_LNO]
                           , q{<?%s ?> is not allowed in expression}
                           . q{ (only in text or html value)}
                           , $node->[NODE_PATH][0]);
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
  # 捕捉中の $CON は、元の CON に delegate する proxy (GH-295)
  sub gen_captured {
    (my MY $self, my $statements) = @_;
    sprintf q{(YATT::Lite::ConnectionProxy->capture($CON, sub {my ($CON) = @_; %s}))}
      , $statements;
  }
  sub gen_maybe_captured {
    my ($self, @expr) = @_;
    if (grep {ref} @expr) {
      # XXX: as_print と違って、行番号の狂いが生じる可能性がある
      # → 個々の要素の生成の段階で、改行を \"\n" みたいに生成しておく？？
      my @stmt;
      foreach my $expr (@expr) {
        if (ref $expr) {
          push @stmt, $$expr.";";
        } else {
          push @stmt, q{print $CON (}, $expr, q{);};
        }
      }
      $self->gen_captured(join "", @stmt);
    } else {
      join '.', @expr;
    }
  }

  sub gen_call {
    (my MY $self, my ($node, @path)) = @_;
    if (my ($kw, $condNode, $stripped) = $self->cut_conditional_arg($node)) {
      # Generate the condition before the call, like macro_if does.
      my $cond = $self->as_list(lexpand(argValue($condNode)));
      my $call = $self->gen_call($stripped, @path);
      return \ sprintf(q{%s %s (%s)}, $$call, $kw, $cond);
    }
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

    $self->ensure_generated(perl => my Template $tmpl = $widget->{folder});
    my $use_this = $tmpl == $self->{_curtmpl};
    unless ($use_this) {
      $self->{_curtmpl}->add_dependency($wname, $tmpl);
    }
    my $that = $use_this ? '$this' : $tmpl->{entns};
    \ sprintf(q{%s->render_%s($CON, %s)}
	      , $that, $widget->{name}
	      , $self->gen_putargs($widget, $node)
	     );
  }
  # `<yatt:foo if="COND">` (or unless=) makes the call conditional,
  # like Perl's postfix if/unless. Note this always wins over formal args
  # named if/unless, as in original yatt (yatt-pm).
  sub cut_conditional_arg {
    (my MY $self, my $node) = @_;
    return if $self->{no_conditional_call};
    my $attlist = $node->[NODE_ATTLIST];
    return unless $attlist and ref $attlist eq 'ARRAY';
    my ($kw, $condNode, @rest);
    foreach my $arg (@$attlist) {
      my $name = $arg->[NODE_PATH];
      if (defined $name and not ref $name
          and ($name eq 'if' or $name eq 'unless')) {
        if ($condNode) {
          die $self->generror(q{Too many conditions in one call: %s and %s}
                              , $kw, $name);
        }
        defined argValue($arg)
          or die $self->generror(q{Condition '%s' requires a value}, $name);
        ($kw, $condNode) = ($name, $arg);
      } else {
        push @rest, $arg;
      }
    }
    return unless $condNode;
    my $stripped = [@$node];
    $stripped->[NODE_ATTLIST] = \@rest;
    ($kw, $condNode, $stripped);
  }

  sub gen_putargs {
    (my MY $self, my Widget $widget, my $node, my $delegate_vars) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);
    return '' if not $delegate_vars and not $widget->{_has_required_arg}
      and not $primary and not $body;

    if ($widget->{_argmacro_instance_list}) {
      $primary = YATT::Lite::CGen::ArgMacro->expand_all_argmacro(
        $self, $widget, $primary, $node,
      );
    }

    my $wname = join ":", @$path;
    my ($posArgs, $actualNo, @argOrder);
    my $add_arg = sub {
      my ($name) = @_;
      my $formal = $widget->{_arg_dict}{$name} or do {
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
	  defined($name = $widget->{_arg_order}[$posArgs //= 0])
	    or die $self->generror("Too many arguments for widget <%s>", $wname); # [code x] など、body の無い widget で起きる (GH-296)

          # Positional arguments should not be treated as body argument.
          if ($widget->{_arg_dict}{$name}->is_body_argument) {
            die $self->generror(
              "Too many arguments for widget <%s>: %s", $wname
              , $self->{_curtmpl}->source_region($primary->[$posArgs][NODE_BEGIN],
                                                $primary->[$#$primary][NODE_END])
            );
          }

          $posArgs++;
	}

	my $formal = $add_arg->($name);
	unless (my $passThruVar = passThruVar($_)) {
	  $self->as_cast_to($formal, argValue($_));
	} elsif (my $actual = $self->find_var($passThruVar)) {
	  $self->ensure_callable_type_match($formal, $passThruVar, $actual);
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
      if ($formal->is_type('expr')) {
        die $self->generror(q{expr argument '%s' can't be given as an element}
                             , $formal->varname);
      }
      push @argExpr, ", ", $self->as_cast_to($formal, $expr);
    }

    # delegate の補間と、必須引数検査
    foreach my $i (0 .. $#{$widget->{_arg_order}}) {
      next if defined $argOrder[$i];
      my $argName = $widget->{_arg_order}[$i];
      if (my $inherit = $delegate_vars->{$argName}) {
	push @argExpr, ', '. $self->as_lvalue($inherit);
	$argOrder[$inherit->argno] = ++$actualNo;
      } elsif ($widget->{_arg_dict}{$argName}->is_required) {
	die $self->generror("Argument '%s' is missing", $argName);
      }
    }
    # 引数の無い [code] (GH-296)。実引数があれば、上で既にエラーになっている。
    return '' unless @{$widget->{_arg_order} // []};
    sprintf q{(undef%s)[%s]}
      , join("", @argExpr), join(", ", map {defined $_ ? $_ : 0}
				 @argOrder[0 .. $#{$widget->{_arg_order}}]);
  }
  # code (出力する renderer) と expr (値を返す関数) は、受け渡しで取り違えない (GH-294)
  sub ensure_callable_type_match {
    (my MY $self, my ($formal, $actualName, $actual)) = @_;
    my ($want, $got) = map {$_->type->[0]} $formal, $actual;
    return if $want eq $got;
    return unless $want =~ /^(?:code|expr)\z/ and $got =~ /^(?:code|expr)\z/;
    die $self->generror(q{Type mismatch for argument '%s': expected %s, but '%s' is %s}
                        , $formal->varname, $want, $actualName, $got);
  }
  #========================================
  # argmacro の on_expand で、in 引数の node から式を組み立てるためのメソッド。
  # 代入先 (formal) の変数宣言が無い所で使う。
  # (旧 YATT の try_pass_through, faked_gentype, faked_genexpr に相当)
  #
  #   my $expr = $cgen->try_pass_through($args->{file})
  #     // $cgen->as_cast_node_to(text => $args->{file});
  #

  # $arg が変数の pass through (file=var の bare、または値無しの file) なら、
  # 呼び出し側 scope のその変数の式を返す。値無しで変数が無ければ
  # $default (Perl 式) を返す。それ以外の node なら undef。
  sub try_pass_through {
    (my MY $self, my ($arg, $default)) = @_;
    my $varName = passThruVar($arg)
      or return undef;
    # ns 付きの名前 (値無しの yatt:foo 等) は変数ではない
    return undef if ref $varName;
    if (my $var = $self->find_var($varName)) {
      $self->as_lvalue($var);
    } elsif ($arg->[NODE_TYPE] == TYPE_ATT_NAMEONLY and defined $default) {
      $default;
    } else {
      die $self->generror_at($arg->[NODE_LNO]
                             , q{No such variable '%s'}, $varName);
    }
  }

  # $arg の値を、型 $type (text, html, value, list ...) の値の式にする。
  # (code, delegate は宣言 var が必要なので不可)
  sub as_cast_node_to {
    (my MY $self, my ($type, $arg)) = @_;
    my $realType = $self->{_type_alias}{$type} // $type;
    my $sub = $realType !~ /^(?:code|delegate)\z/
      && $self->can("as_cast_to_$realType")
      or die $self->generror_at($arg->[NODE_LNO]
                                , q{No such argtype: %s}, $type);
    $sub->($self, undef, argValue($arg) // '');
  }

  # $arg の値を、そのまま Perl 式にする (entity は escape しない)。
  # 値が無いか空なら $default。
  sub as_expr_node {
    (my MY $self, my ($arg, $default)) = @_;
    my @value = lexpand(argValue($arg));
    return $default if not @value or @value == 1 and not ref $value[0]
      and $value[0] eq '';
    scalar $self->as_list(@value);
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
  # code 型は renderer。widget と同じく $CON を第一引数で受け取る (GH-293)
  sub as_varcall_code {
    (my MY $self, my ($codeVar, $node)) = @_;
    return \ sprintf q{$%1$s && $%1$s->(%2$s)}, $codeVar->varname
      , join(", ", '$CON', $self->gen_putargs($codeVar->widget, $node) || ());
    # XXX: デフォルト body のように、引数宣言が無いケースも考慮せよ。
  }
  # expr は値を返す関数で、widget ではない (GH-294)
  sub as_varcall_expr {
    (my MY $self, my ($var, $node)) = @_;
    my ($path) = nx($node);
    die $self->generror(q{expr variable '%s' can't be called as an element. Use &%s();}
                        , $var->varname, join(":", @$path));
  }
  sub as_varcall_delegate {
    (my MY $self, my ($var, $node)) = @_;
    my Widget $delegate = $var->widget;
    unless (defined $delegate) {
      Carp::croak "delegate target widget is empty!";
    }
    $self->ensure_generated(perl => my Template $tmpl = $delegate->{folder});
    my $that = $tmpl == $self->{_curtmpl} ? '$this' : $tmpl->{entns};
    \ sprintf(q{%s->render_%s($CON, %s)}
	      , $that, $delegate->{name}
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
      $self->{_curline} += numLines($value);
      return qtext($value);
    }
    local $self->{_scope} = $self->mkscope({}, $self->{_scope});
    my @expr = $self->gen_as(text => \@AS_TEXT, 1, 1, @$value);
    $self->gen_maybe_captured(@expr);
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
    local $self->{_curtoks} = [@$value];
    my Widget $virtual = $var->widget;
    local $self->{_scope} = $self->mkscope
      ({}, $virtual->{_arg_dict} ||= {}, $self->{_scope});
    local $self->{yatt_no_last_newline} = 1;
    q|sub { my $CON = shift;|. join('', $self->gen_getargs($virtual)
		   , $self->as_print("}"));
  }
  # expr 型は、値を返す closure。属性値は print せず、式として評価する (GH-294)
  sub as_cast_to_expr {
    (my MY $self, my ($var, $value)) = @_;
    my Widget $virtual = $var->widget;
    my $dict = $virtual ? ($virtual->{_arg_dict} ||= {}) : {};
    local $self->{_scope} = $self->mkscope({}, $dict, $self->{_scope});
    my @getargs = do {
      # gen_getargs の cut_next_nl が、呼び出し側の改行を消さないように
      local $self->{_curtoks} = [];
      $virtual ? $self->gen_getargs($virtual) : ();
    };
    q|sub {|. join('', @getargs, ' ', ref $value ? $self->as_list(@$value) : $value)
      . '}';
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
    $self->{_curline} += $nlines;
    return \ ("\n" x $nlines);
  }
  sub from_lcmsg {
    (my MY $self, my $node) = @_;
    my ($path, $body) = nx($node);
    # $body is list of tokenlist.
    my $place = $self->{_curtmpl}->fake_filename . ":" . $node->[NODE_LNO];

    # XXX: builtin xgettext
    if (@$body >= 2 or @$path >= 2) {
      # ngettext
      my ($uniq, $args, $numexpr) = ({}, []);
      my ($msgid, @plural) = map {
	scalar $self->gen_lcmsg($node, $_, $uniq, $args, \$numexpr);
      } @$body;
      if (my $sub = $self->{lcmsg_sink}) {
	$sub->($place, $msgid, \@plural, $args);
      }
      sprintf q{sprintf($CON->ngettext(%s, %s), %s)}
	, join(", ", map {qtext($_)} ($msgid, @plural))
	  , $numexpr, join(", ", @$args);
    } else {
      my ($msgid, @args) = $self->gen_lcmsg($node, $body->[0]);
      if (my $sub = $self->{lcmsg_sink}) {
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
    $self->gen_entpath($self->{_needs_escaping}, @pipe);
  }

  # XXX: lxnest を caller が呼ぶ必要が有る...が、それって良いことなのか...
  sub gen_entpath {
    (my MY $self, my ($escape_now)) = splice @_, 0, 2;
    return '' unless @_;
    local $self->{_needs_escaping} = 0;
    if (@_ == 1 and ($_[0][0] eq 'call'
		       or $_[0][0] eq 'var' and $self->{prefer_call_for_entity})
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
    my Template $tmpl = $self->{_curtmpl};
    $tmpl->{_Item}{Entity->item_key_for($name)}
      // $tmpl->{entns}->can(Entity->method_name_for($name));
  }
  sub ensure_entity_is_declared {
    (my MY $self, my ($name)) = @_;
    my Template $tmpl = $self->{_curtmpl};
    if ($tmpl->{_Item}{Entity->item_key_for($name)}) {
      # Found embedded entity definition.
      return;
    }
    unless ($tmpl->{entns}->can(Entity->method_name_for($name))) {
      die $self->generror(q!No such entity in namespace "%s": %s!
			  , $tmpl->{entns}, $name);
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
  sub as_expr_call_var_code {
    (my MY $self, my ($var, $name, @args)) = @_;
    \ sprintf q{$%1$s && $%1$s->(%2$s)}, $name
      , join(", ", '$CON', $self->gen_entlist(undef, @args));
  }
  sub as_expr_call_var_attr {
    (my MY $self, my ($var, $name, @args)) = @_;
    (undef, my $attname) = @{$var->type};
    sprintf q|YATT::Lite::Util::named_attr('%s', %s)|
      , $attname // $name
	, join ", ", "\$".$name, $self->gen_entlist(undef, @args);
  }
  # expr の呼び出しは値の式。出力位置では escape して print される (GH-294)
  sub as_expr_call_var_expr {
    (my MY $self, my ($var, $name, @args)) = @_;
    sprintf q{($%1$s && $%1$s->(%2$s))}, $name
      , scalar $self->gen_entlist(undef, @args);
  }
  # delegate は要素形式のみ。entity 形式では引数の補間も検査もできない (GH-304)
  sub as_expr_call_var_delegate {
    (my MY $self, my ($var, $name, @args)) = @_;
    die $self->generror(q{delegate variable '%s' can't be called as an entity. Use <yatt:%s/>}
                        , $name, $name);
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
    if ($self->{prefer_call_for_entity}) {
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
                           , $trans->{_curtmpl}->node_outer_source($arg));
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
      local $self->{_scope} = $self->mkscope({}, $self->{_scope});
      local $self->{_curtoks} = [@body];
      (defined $guard
       ? sprintf($fmt, scalar $self->as_list(lexpand($guard))) : $fmt)
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
  sub make_arg_adder {
    (my MY $self, my $node) = @_;
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
	my $var = $self->mkvar_at(undef, $typename, $name)
	  or die $self->generror("Unknown type '%s' for variable '%s'"
				 , $typename, $name);
	# typename == source の時が問題だ。
	my $expr = 'my '.$self->as_lvalue($var);
	my $value = argValue($valNode);
	$expr .= defined $value ? (' = '.$self->as_cast_to($var, $value)) : ';';
        $self->{_scope}[0]{$name} = $var;
        $expr;
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
          my $var = $self->{_scope}[0]{$name}
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
  }

  sub macro_my {
    (my MY $self, my $node) = @_;
    my ($path, $body, $maybeWrappedAttlist, $head, $foot) = nx($node);
    my $has_body = $body && @$body ? 1 : 0;
    my $adder = $self->make_arg_adder($node);
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
  # 変数の登録は、初期値を生成した後に行う (自分の初期値の中からは見えない)。
  # 本体は Perl の sub になるので、YATT のスコープも作る (as_cast_to_code と同じ)。
  sub _macro_my_code {
    (my MY $self, my ($node, $name, $valNode)) = @_;
    my $var = $self->mkvar_at(undef, code => $name);
    my $expr = do {
      local $self->{_curtoks} = [lexpand(argValue($valNode))];
      local $self->{_scope} = $self->mkscope({}, $self->{_scope});
      'my '.$self->as_lvalue($var).' = '.q|sub { my $CON = shift;| . $self->as_print('}');
    };
    $self->{_scope}[0]{$name} = $var;
    $expr;
  }
  sub _macro_my_expr {
    (my MY $self, my ($node, $name, $valNode)) = @_;
    my (undef, $body) = nx($node);
    if ($body and $valNode == $body) {
      die $self->generror(q{expr variable '%s' can't have a body}, $name);
    }
    my $var = $self->mkvar_at(undef, expr => $name);
    my $value = argValue($valNode);
    my $expr = 'my '.$self->as_lvalue($var)
      .(defined $value ? ' = '.$self->as_cast_to_expr($var, $value) : ';');
    $self->{_scope}[0]{$name} = $var;
    $expr;
  }
  sub _macro_my_source {
    (my MY $self, my ($node, $name, $valNode)) = @_;
    my $var = $self->mkvar_at(undef, text => $name);
    my $expr = 'my '.$self->as_lvalue($var).' = '
      .join(q|."\n".|, map {qtext($_)}
	    split /\n/, $self->{_curtmpl}->node_body_source($node));
    $self->{_scope}[0]{$name} = $var;
    $expr;
  }

  sub macro_block {
    (my MY $self, my $node) = @_;
    my ($path, $body, $maybeWrappedAttlist, $head, $foot) = nx($node);
    local $self->{_scope} = $self->mkscope(+{}, $self->{_scope});
    my $adder = $self->make_arg_adder($node);
    my $primary = $self->node_unwrap_attlist($maybeWrappedAttlist);
    my @assign;
    foreach my $arg (@$primary) {
      push @assign, $adder->(text => $arg, $arg);
    }
    # $self->macro_scoped_block_of_tokens(+{}, @{argValue($body)});
    local $self->{_curtoks} = [@{argValue($body)}];
    \ ('{'.join("; ", @assign, "").$self->as_print('}'));
  }

  sub macro_scoped_block_of_tokens {
    (my MY $self, my ($scope, @tokens)) = @_;
    local $self->{_scope} = $self->mkscope($scope, $self->{_scope});
    local $self->{_curtoks} = \@tokens;
    \ ('{'.$self->as_print('}'));
  }
}

{
  MY->make_arg_spec(\ my %args, \ my @args, qw(list nth));
  sub macro_foreach {
    (my MY $self, my ($node, $opts)) = @_;
    my ($path, $body, $primary, $head, $foot) = nx($node);
    my @primary = lexpand($primary)
      or die $self->generror("Not enough arguments for <yatt:foreach>!");

    my ($varDecl, $list, $nth) = do {
      if (@primary == 1) {
        my $name = $primary[0][NODE_PATH];
        if (defined $name and $name ne 'list') {
          die $self->generror("Invalid list argument for <yatt:foreach>!");
        }
        (undef, $primary[0], undef)
      } else {
        my $declArg = shift @primary;
        $self->feed_arg_spec(\@primary, \%args, \@args
                             , my ($list, $nth));
        ($declArg, $list, $nth);
      }
    };

    my ($prologue, $continue, $epilogue) = ('', '', '');

    unless (defined $list) {
      die $self->generror("no list= is given");
    }

    my %local;
    my $loopvar = do {
      if (not $varDecl) {
        # _ は？ entity 自体に処理させるか…
        ''
      }
      else {
        my ($varName, $typeName) = do {
          my ($head, @rest) = lexpand($varDecl->[NODE_PATH]);
          my $valuePart = $varDecl->[NODE_VALUE];
          if ($head eq 'my') {
            ($valuePart, $rest[0] || '');
          }
          elsif (not $valuePart) {
            ($head, $rest[0]);
          }
          elsif (not $rest[0]) {
            ($head, $valuePart);
          }
          else {
            die $self->generror("conflicting typespec: $rest[0] vs $valuePart")
          }
        };
        $local{$varName} = $self->mkvar_at(undef, $typeName || '' => $varName);
        "my \$" . $varName;
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

    local $self->{_curtoks} = [@{argValue($body)}];

    # <yatt:foreach ..>\n
    #                  ↑This newline should be removed.
    my $statements = "{";
    if (my $nl = $self->cut_next_nl) {
      $statements .= $nl;
    }

    # ___</yatt:foreach>
    # ↑ This indent is messy too.
    if (@{$self->{_curtoks}} and $self->{_curtoks}[-1] =~ /^[\ \t]+\z/) {
      pop @{$self->{_curtoks}};
    }

    #    ...\n         ← not to remove this newline.
    # </yatt:foreach>
    local $self->{yatt_no_last_newline} = 0;

    local $self->{_scope} = $self->mkscope(\%local, $self->{_scope});
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
      local $self->{_scope} = $self->mkscope({}, $self->{_scope});
      local $self->{_curtoks} = [lexpand($body->[NODE_VALUE])];
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
  unless (@list >= 2 and @list <= 3) {
    die $self->generror("Invalid number of args: value_checked(VALUE, HASHorARRAY,?is_default?)");
  }
  sprintf q|YATT::Lite::Util::value_checked(%s)|
    , join ", ", map {ref $_ ? $$_ : $_} @list;
}

sub entmacro_value_selected {
  (my MY $self, my $node) = @_;
  my (@list) = $self->gen_entlist(undef, entx($node));
  unless (@list >= 2 and @list <= 3) {
    die $self->generror("Invalid number of args: value_selected(VALUE, HASHorARRAY,?is_default?)");
  }
  sprintf q|YATT::Lite::Util::value_selected(%s)|
    , join ", ", map {ref $_ ? $$_ : $_} @list;
}

sub entmacro_lexpand {
  (my MY $self, my $node) = @_;
  q|@{|.$self->gen_entpath(undef, map {lxnest($_)} entx($node)).q| // []}|;
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
  my Widget $widget = $self->{_curwidget};
  qtext($widget->{name});
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
