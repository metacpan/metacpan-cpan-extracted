# -*- mode: perl; coding: utf-8 -*-
package YATT::Translator::Perl; use YATT::Inc;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

#========================================

our %TYPE_MAP;

use base qw(YATT::Registry);
use YATT::Fields [cf_mode => 'render']
  , [cf_product => sub {[]}]
  , qw(target_cache
       delayed_target
       generating_widget
       cf_pagevars
       cf_debug_translator);

BEGIN {require Exporter; *import = \&Exporter::import}
our @EXPORT_OK = qw(qqvalue qparen);
our @EXPORT = @EXPORT_OK;

use YATT::Registry::NS;
use YATT::Widget;
use YATT::Util qw(checked_eval add_arg_order_in terse_dump coalesce);
use YATT::LRXML::Node qw(node_path node_body node_name
			 node_size node_flag
			 node_children
			 create_node
			 stringify_node
			 TEXT_TYPE ELEMENT_TYPE ENTITY_TYPE);

use YATT::LRXML::EntityPath;
use YATT::Util::Taint;
use YATT::Util::Symbol qw(declare_alias);
require YATT::ArgMacro;

#========================================

sub qqvalue ($);
sub qparen ($);

#========================================

sub after_configure {
  my MY $trans = shift;
  $trans->SUPER::after_configure;
  $trans->{cf_type_map} ||= \%TYPE_MAP;
}

sub emit {
  my MY $gen = shift;
  my $script = join "", @{$gen->{cf_product}};
  $gen->{cf_product} = [];
  $script;
}

#========================================

sub call_handler {
  (my MY $trans, my ($method, $widget_path)) = splice @_, 0, 3;
  my ($handler, $pkg) = $trans->get_handler_to
    ($method, ref $widget_path ? @$widget_path : split /[:\.]/, $widget_path);
  &YATT::break_handler;
  $handler->($pkg, @_);
}

sub parse_elempath {
  my ($pack, @elpath) = @_;
  if (@elpath == 1) {
    if (ref $elpath[0]) {
      @elpath = @{$elpath[0]};
    } else {
      @elpath = split '/', $elpath[0];
    }
  }

  # root dir should be ignored.
  shift @elpath if !defined $elpath[0] || $elpath[0] eq '';

  @elpath;
}

sub get_handler_to {
  (my MY $trans, my ($method)) = splice @_, 0, 2;
  my @elpath = $trans->parse_elempath(@_);

  my @result;
  if (wantarray) {
    @result = $trans->lookup_handler_to($method, @elpath);
  } else {
    $result[0] = $trans->lookup_handler_to($method, @elpath);
  }

  unless (@result) {
    croak "Can't find widget: " . join(":", @elpath);
  }

  wantarray ? @result : $result[0];
}

sub lookup_handler_to {
  (my MY $trans, my ($method, @elpath)) = @_;

  $trans->{cf_mode} = $method; # XXX: local
  @{$trans->{cf_product}} = ();

  my Widget $widget = $trans->get_widget(@elpath)
    or return;

  $trans->ensure_widget_is_generated($widget);
  if (my $script = $trans->emit) {
    print STDERR $script if $trans->{cf_debug_translator};
    $trans->checked_eval
      (join(";"
	    , 'use strict'
	    , 'use warnings FATAL => qw(all)'
	    # XXX: 何が redefine されるかは分からないから…
	    , 'no warnings "redefine"'
	    , untaint_any($script)));

  }
  my ($pkg, $funcname) = $trans->get_funcname_to($method, $widget);
  my $handler = $pkg->can($funcname);

  return $handler unless wantarray;
  ($handler
   , scalar $trans->get_package_from_widget($widget)
  , $widget);
}

sub get_funcname_to {
  (my MY $trans, my ($mode), my Widget $widget) = @_;
  my $pkg = $trans->get_package_from_widget($widget);
  my $fname = "${mode}_$$widget{cf_name}";
  wantarray ? ($pkg, $fname) : join("::", $pkg, $fname);
}

sub get_package_from_widget {
  (my MY $trans, my Widget $widget) = @_;
  my $primary = $trans->get_package
    (my Template $tmpl = $trans->nsobj($widget->{cf_template_nsid}));

  return $primary unless wantarray;
  ($primary, $trans->get_rc_package_from_template($tmpl));
}

sub get_rc_package_from_template {
  (my MY $trans, my Template $tmpl) = @_;
  $trans->get_package($trans->nsobj($tmpl->{cf_parent_nsid}));
}

#----------------------------------------

sub generate {
  my MY $gen = shift;
  foreach my $elempath (@_) {
    if (my $widget = $gen->get_widget(@$elempath)) {
      $gen->ensure_widget_is_generated($widget);
    } elsif (my $ns = $gen->get_ns($elempath)) {
      $gen->ensure_ns_is_generated($ns);
    } else {
      croak "Invalid widget path: " . join(":", @$elempath);
    }
  }
  $gen->emit;
}

sub mark_delayed_target {
  (my MY $gen, my Widget $widget) = @_;
  $gen->{delayed_target}{$widget->{cf_template_nsid}}++;
}

sub ensure_widget_is_generated {
  (my MY $gen, my Widget $widget) = @_;
  $gen->ensure_template_is_generated($widget->{cf_template_nsid});
}

sub ensure_template_is_generated {
  #  (my MY $gen, my $tmplid) = @_;
  #  $tmplid = $tmplid->cget('nsid') if ref $tmplid;
  (my MY $gen, my $id_or_obj) = @_;
  (my $tmplid, my Template $tmpl) = do {
    if (ref $id_or_obj) {
      ($id_or_obj->cget('nsid'), $id_or_obj)
    } else {
      ($id_or_obj, $gen->nsobj($id_or_obj));
    }
  };
  if (my $baseid = $tmpl->{cf_base_template}) {
    $gen->ensure_template_is_generated($baseid);
  }
  unless ($gen->{target_cache}{$tmplid}++) {

    # eval は？
    push @{$$gen{cf_product}}
      , $gen->generate_template($gen->nsobj($tmplid));
  }
  if (my @delayed = keys %{$gen->{delayed_target}}) {
    foreach my $nsid (@delayed) {
      next if $gen->{target_cache}{$nsid};
      delete $gen->{delayed_target}{$nsid};
      $gen->ensure_template_is_generated($nsid);
    }
  }
}

sub forget_template {
  (my MY $gen, my $tmplid) = @_;
  $tmplid = $tmplid->cget('nsid') if ref $tmplid;
  delete $gen->{target_cache}{$tmplid} ? 1 : 0;
}

my %calling_conv;

sub generate_template {
  (my MY $gen, my Template $tmpl) = @_;
  print STDERR "Generate: $tmpl->{cf_loadkey}\n"
    if $gen->{cf_debug_translator};
  my $metainfo = $tmpl->metainfo;
  my @use = map {
    unless (defined $_) {
      ()
    } else {
      map {"use $_;"} ref $_ ? @$_ : $_
    }
  } $gen->{cf_use};
  my @file_scope = do {
    if ($gen->{cf_pagevars}) {
      $gen->checked_eval(qq{require $gen->{cf_pagevars}});
      push @use, "use $gen->{cf_pagevars} (qw($tmpl->{cf_name}), 1);";
      ($gen->{cf_pagevars}->build_scope_for($gen, $tmpl->{cf_name})
       , [\%calling_conv]);
    } else {
      \%calling_conv;
    }
  };
  my @script;
  foreach my $widget (@{$tmpl->widget_list}) {
    push @script, $gen->generate_widget($widget, $metainfo, \@file_scope);
  }
  join("", q{package } . $gen->get_package($tmpl) . ';'
       , join("",@use)
       , @script);
}

sub generate_lineinfo {
  (my MY $gen, my Widget $widget, my ($start, $prefix)) = @_;
  return if $gen->{cf_no_lineinfo};
  sprintf qq{%s#line %d "%s"\n}, $prefix || ''
    , $start, $widget->{cf_filename};
}

sub generating_widget {
  my MY $gen = shift;
  $gen->{generating_widget}[0];
}

sub generate_widget {
  (my MY $gen, my Widget $widget, my ($metainfo, $file_scope)) = @_;
  local $gen->{generating_widget}[0] = $widget;
  my @body = $gen->generate_body
    ([{}, $widget->widget_scope($file_scope)]
     , $widget->cursor(metainfo => $metainfo->clone
		       (startline => $widget->{cf_body_start}
			, caller_widget => $widget)));
  # body が空の場合もありうる。
  return unless @body;
  my ($pkg, $funcname) = $gen->get_funcname_to($gen->{cf_mode}, $widget);
  join(""
       , $gen->generate_lineinfo($widget, $widget->{cf_decl_start}, "\n")
       , $gen->generate_getargs($widget, $metainfo)
       , $gen->generate_lineinfo($widget, $widget->{cf_body_start})
       , $gen->as_sub
       ($funcname
	, $gen->genprolog($widget)
	, $gen->as_statement_list(@body))
       , "\n");
}

sub generate_getargs {
  (my MY $gen, my Widget $widget, my ($metainfo)) = @_;
  $gen->as_sub("getargs_$$widget{cf_name}", sprintf q{
   my ($call) = shift;
   $_[0] = shift @$call; shift;
   my $args = $_[0] = shift @$call; shift;
   if (ref $args eq 'ARRAY') {
%s} else {
%s
}
}
	       , $gen->gen_getargs_static($widget, $metainfo)
	       , $gen->gen_getargs_dynamic($widget, $metainfo));
}

sub genprolog {
  (my MY $gen, my Widget $widget) = @_;
  my @args = qw($this $args);
  if ($widget->{arg_order} && @{$widget->{arg_order}}) {
    foreach my $name (@{$widget->{arg_order}}) {
      push @args, $widget->{arg_dict}{$name}->as_lvalue
    }
  }
  sprintf q{getargs_%s(\@_, my (%s))}
    , $$widget{cf_name}, join(", ", @args);
}

sub generate_body {
  (my MY $gen, my ($scope, $cursor)) = @_;
  my @code;
  for (; $cursor->readable; $cursor->next) {
    if (my $sub = $gen->can("trans_" . (my $t = $cursor->node_type_name))) {
      push @code, $sub->($gen, $scope, $cursor);
    } else {
      die $gen->node_error($cursor, "Can't handle node type: %s", $t);
    }
  }
  @code;
}

sub as_sub {
  my ($gen, $func_name) = splice @_, 0, 2;
  "sub $func_name ". $gen->as_block(@_);
}

sub as_block {
  my ($gen) = shift;
  return '{}' unless @_;
  my $last = pop;
  $last .= do {
    if ($last =~ s/(\n+)$//) {
      "}$1";
    } else {
      '}';
    }
  };
  '{ '.join("; ", @_, $last);
}

sub as_join {
  my MY $gen = shift;
  my (@result);
  foreach my $trans (@_) {
    if (ref $trans) {
      push @result, qq(YATT::capture {$$trans});
    } else {
      push @result, $trans;
    }
  }
  sprintf q{join('', %s)}, join ", ", @result;
}

use YATT::Types
  [queued_joiner => [qw(queue printable last_ws)]];

sub YATT::Translator::Perl::queued_joiner::joiner {
  # 行が変わらない限り、一つの print に入れる。
  # 行が変われば、別の print にする。
  # 印字可能要素が無いなら、空白をそのまま入れる。
  (my queued_joiner $me, my ($head)) = splice @_, 0, 2;
  my ($line, $prenl, @result, $argc, $nlines) = ('', '');
  foreach my $i (@_) {
    unless ($i =~ /\S/) {
      push @result, $i
	and next;
    }
    if ($line eq '') {
      # 先頭
      if ($i =~ s/^(\s+)//) {
	$prenl .= $1;
      }
      if ($i ne '') {
	$line .= $prenl . $head . $i;
      }
    } else {
      # 残り
      $line .= ', ' . $i;
    }
    if ($i =~ /\n/) {
      push @result, $line;
      $line = '';
      $prenl = '';
    }
  }
  push @result, $line if $line ne '';
  @result;
}

sub YATT::Translator::Perl::queued_joiner::add {
  (my queued_joiner $me, my $str) = @_;
  push @{$me->{queue}}, $str;
  if ($str =~ /\S/) {
    $me->{printable}++;
    undef $me->{last_ws};
  } else {
    $me->{last_ws} = 1;
  }
}

sub YATT::Translator::Perl::queued_joiner::emit_to {
  (my queued_joiner $me, my ($result)) = @_;
  if ($me->{printable}) {
    my $ws; $ws = pop @{$me->{queue}} if $me->{last_ws};
    push @$result, $me->joiner('print ', @{$me->{queue}}) if @{$me->{queue}};
    $result->[-1] .= $ws if $me->{last_ws};
  } else {
    push @$result, @{$me->{queue}} if $me->{queue};
  }
  undef @{$me->{queue}};
  undef $me->{printable};
  undef $me->{last_ws};
}

sub as_statement_list {
  my MY $gen = shift;
  my queued_joiner $queue = queued_joiner->new;
  my (@result);
  foreach my $trans (@_) {
    if (ref $trans) {
      $queue->emit_to(\@result);
      push @result, $$trans;
    } else {
      $queue->add($trans);
    }
  }
  $queue->emit_to(\@result);
  wantarray ? @result : join('', @result);
}

#----------------------------------------
# trans_zzz

sub trans_comment {
  (my MY $trans, my ($scope, $node)) = @_;
  \ ("\n" x $node->node_nlines);
}

sub trans_text {
  (my MY $trans, my ($scope, $node)) = @_;
  my $body = $node->current;
  my ($pre, $post) = ('', '');
  my $CRLF = qr{\r?\n};
  if ($node->node_is_beginning) {
    $pre = $1 if $body =~ s/^($CRLF+)//;
  } elsif ($node->node_is_end) {
    if (not $node->has_parent
	and $node->metainfo->caller_widget->no_last_newline) {
      $body =~ s/($CRLF+)$//s;
    } else {
      $post = $2 if $body =~ s/($CRLF)($CRLF+)$/$1/s;
    }
  }
  $pre.do {
    if ($body eq '') {
      ''
    } elsif ($body =~ /^$CRLF$/) {
      sprintf qq{"%s"\n}, qcrlf($body);
    } else {
      qparen($body);
    }
  }.$post;
}

sub trans_pi {
  (my MY $trans, my ($scope, $node)) = @_;

  # XXX: 処理を許すかどうか、選べるようにすべき。あるいは、mapping が欲しい。
  if ($node->node_nsname ne 'perl') {
    return '';
  }

  my $body = $trans->genexpr_node($scope, 0, $node->open);
  unless ($body =~ s/^(=+)//) {
    \ $body;
  } elsif (length($1) >= 3) {
    # print without escaping.
    \ qq{print $body};
  } else {
    qq{YATT::escape(do {$body})}
  }
}

sub genexpr_node {
  (my MY $trans, my ($scope, $early_escaped, $node)) = @_;
  join("", map { ref $_ ? $$_ : $trans->dots_for_arrows(my $cp = $_) }
       $trans->mark_vars($scope, $early_escaped, $node));
}

#========================================

use YATT::Util::Enum -prefix => 'ENT_', qw(RAW ESCAPED PRINTED);

sub trans_entity {
  (my MY $trans, my ($scope, $node)) = @_;
  $trans->generate_entref($scope, ENT_PRINTED, $node);
}

sub trans_html {
  (my MY $trans, my ($scope, $node)) = @_;
  my $tag = $node->node_name;
  my ($string, $tagc, $end) = do {
    if ($node->is_empty_element) {
      ("<$tag", " />", '');
    } else {
      ("<$tag", ">", "</$tag>");
    }
  };

  my $item = $node->open;
  my @script;
  for (; $item->readable; $item->next) {
    last unless $item->is_primary_attribute;
    my $name = $item->node_name;
    if (my $var = $trans->has_pass_through_var($scope, $item, $name)) {
      push @script, qparen($string), $var->as_escaped;
      $string = '';
      next;
    }
    $string .= ' ';
    my ($open, $close) = $item->node_attribute_format;
    $string .= $open;
    # XXX: quote されてないとき、変数推測をしても良いかも。
    for (my $frag = $item->open; $frag->readable; $frag->next) {
      my $type = $frag->node_type;
      if ($type == TEXT_TYPE) {
	$string .= $frag->current;
      } elsif ($type == ENTITY_TYPE) {
	# should be entity
	push @script, qparen($string)
	  , $trans->generate_entref($scope, ENT_ESCAPED, $frag);
	$string = '';
      } else {
	die $trans->node_error($frag, "Invalid node in html attribute");
      }
    }
    $string .= $close;
  }

  $string .= $tagc if $tagc ne '';
  for (; $item->readable; $item->next) {
    if ($item->node_type == TEXT_TYPE) {
      $string .= $item->current;
    } else {
      push @script, qparen($string), $trans->generate_body($scope, $item);
      $string = '';
    }
  }
  $string .= $end if $end;
  push @script, qparen($string) if $string ne '';
  @script;
}

#========================================

my %control = (if => undef, unless => undef);
sub trans_element {
  (my MY $trans, my ($scope, $node)) = @_;
  my $tmpl = $trans->get_template_from_node($node);

  # ■ 最初に要素マクロ ← RC から検索。
  if (my $macro = $trans->has_element_macro($tmpl, $node, $node->node_path)) {
    # XXX: ssri:foreach → yatt:foreach も。
    return $macro->($trans, $scope, $node->open);
  }

  # ■ 次に if/unless/else,
  if (my @arm = $trans->collect_arms($node, else => \%control)) {
    return $trans->gencall_conditional($scope, @arm);
  }

  # ■ 無条件呼び出し
  $trans->gencall_always($scope, $node);
}

sub gencall_conditional {
  (my MY $trans, my ($scope, $ifunless, @elses)) = @_;
  my $pkg;
  my $script = do {
    my ($cond, $action) = @$ifunless; # (node, cursor)
    sprintf(q{%s (%s) {%s}}
	    , $cond->node_name
	    , $trans->genexpr_node($scope, 0, $cond->open)
	    , ${ $trans->gencall_always($scope, $action->make_wrapped) });
  };

  foreach my $arm (@elses) {
    my ($cond, $action) = @$arm;
    $script .= do {
      if ($cond) {
	sprintf q{ elsif (%s) }
	  , $trans->genexpr_node($scope, 0, $cond->open);
      } else {
	q{ else }
      }
    };
    $script .= sprintf q{{%s}}
      , ${ $trans->gencall_always($scope, $action->make_wrapped) };
  }
  \ $script;
}

sub gencall_always {
  (my MY $trans, my ($scope, $node)) = @_;

  my $tmpl = $trans->get_template_from_node($node);
  my @elempath = $node->node_path or do {
    die $trans->node_error($node, "Empty element path");
  };

  # ■ 局所引数… これも、型の固有処理に任せる. delegate もここで。
  if (my $codevar = $trans->find_codearg($scope, @elempath)) {
    # ← 特に、親の call の body の中で、<yatt:body foo=bar/> で
    # 呼ばれるとき, だよね？
    return $codevar->gen_call($trans, $scope, $node);
  }

  # ■ さもなければ、通常の Widget の呼び出し
  my Widget $widget = $trans->get_widget_from_template($tmpl, @elempath);
  unless ($widget) {
    die $trans->node_error($node, "No such widget");
  }
  $trans->gencall($widget, $scope, $node->open);
}

sub has_unique_argmacro {
  (my MY $trans, my Widget $callee, my Widget $caller) = @_;
  return unless $callee->{argmacro_dict};
  # 現状では、name の重複は無いはず。
  my %suppress; $suppress{$_->call_spec} = 1 for @{$caller->{argmacro_order}};
  my @order = grep {not $suppress{$_->call_spec}} @{$callee->{argmacro_order}}
    or return;
  my %dict;
  foreach my $arg (keys %{$callee->{argmacro_dict}}) {
    $dict{$arg} = $callee->{argmacro_dict}{$arg};
  }
  (\%dict, \@order);
}

sub gencall {
  (my MY $trans, my Widget $widget, my ($scope, $node)) = @_;
  $trans->ensure_widget_is_generated($widget);

  # 引数マクロの抜き出し
  if (my ($dict, $order) = $trans->has_unique_argmacro
      ($widget, $node->metainfo->caller_widget)) {
    $node = YATT::ArgMacro->expand_all_macros
      ($trans, $scope, $node, $widget, $dict, $order);
  }

  my $func = $trans->get_funcname_to($trans->{cf_mode}, $widget);
  # actual 一覧の作成
  my ($post, @args) = $trans->genargs_static
    ($scope, $node, $widget->arg_specs);

  # XXX: calling convention 周り
  return \ sprintf(' %s($this, [%s])%s', $func
		   , join(", ", map {defined $_ ? $_ : 'undef'} @args)
		   , $post);
}

sub has_single_bare_varexpr {
  (my MY $trans, my ($scope, $node)) = @_;
  my $clone = $node->clone($node->clone_path);
  my $parent = $clone->parent;
  return unless $parent->is_bare_attribute and $parent->node_size == 1;
  my (@expr) = ($trans->mark_vars($scope, ENT_RAW, $clone));
  return unless @expr and ref $expr[0] eq 'SCALAR';
  $expr[0];
}

sub has_pass_through_var {
  (my MY $trans, my ($scope, $args, $name)) = @_;
  return if $args->node_size >= 2;
  if ($args->node_size == 1 and ($args->node_flag || 0) == 0) {
    # bareword 渡し。
    $trans->find_var($scope, $args->node_body);
  } elsif ($args->node_size == 0) {
    # value less 渡し
    $trans->find_var($scope, $name);
  }
}

sub genargs_static {
  (my MY $trans, my ($scope, $args, $arg_dict, $arg_order, $delegate_vars)) = @_;
  my ($body, @actual) = $args->variant_builder;
  my ($postnl, $startline) = ('', $args->linenum);
  for (my $nth = 0; $args->readable; $args->next) {
    unless ($args->is_attribute) {
      $body->add_node($args->current);
      next;
    }

    my ($name, $typename) = $trans->arg_name_types($args);
    unless (defined $name) {
      $name = $arg_order->[$nth++]
	or die $trans->node_error($args, "Too many args");
    }
    my $argdecl = $arg_dict->{$name};
    unless ($argdecl) {
      die $trans->node_error($args, "Unknown arg '%s'", $name);
    }
    # XXX: $typename (attname:type の type) を活用していない。
    # XXX: code 型引数を primary で渡したときにまで、 print が作られてる。
    # $args->is_quoted_by_element で判別せよ。
    $actual[$argdecl->argno] = do {
      if (my $var = $trans->has_pass_through_var($scope, $args, $name)) {
	# XXX: early_escaped が一致するか、検査せよ。
	$argdecl->early_escaped ? $var->as_escaped : $var->as_lvalue;
      } elsif (defined $args->node_body) {
	$argdecl->gen_assignable_node($trans, $scope, $args);
      } elsif ($argdecl->isa($trans->t_scalar)) {
	$argdecl->quote_assignable(my $copy = 1);
      } else {
	die $trans->node_error($args, "valueless arg '%s'", $name);
      }
    };
  }
  if ($body->array_size
      and my $bodydecl = $arg_dict->{body}) {
    # if $actual[$bodydecl->argno]; なら、エラーを報告すべきでは?
    # code か、html か。
    $actual[$bodydecl->argno]
      = $bodydecl->gen_assignable_node($trans, $scope, $body, 1);
  }

  for (my $i = 0; $i < @$arg_order; $i++) {
    next if defined $actual[$i];
    my $name = $arg_order->[$i];
    if ($delegate_vars->{$name}) {
      # delegate 宣言では、型は同じになるはず。
      # XXX: 引数rename
      $actual[$i] = $arg_dict->{$name}->as_lvalue;
    } elsif ($arg_dict->{$name}->is_required) {
      die $trans->node_error($args->parent
			     , "Argument '%s' is missing", $name);
    }
  }

  if ($args->parent->is_empty_element) {
    my $diff = $args->parent->linenum(+1)
      - $startline - $args->count_lines_of(@actual);
    $postnl = "\n" x $diff if $diff;
  } else {
    # XXX: どうする？
  }
  ($postnl, @actual);
}

sub collect_arms {
  my ($pack, $call, $key, $dict) = @_;
  my ($type, $name) = $call->node_headings;
  my $args = $call->open;
  my ($cond, $body) = $pack->consume_arm($args, $dict, $type, $name
					 , primary_only => 1);
  return unless $cond;
  my @case = [$cond, $body];
  for (; $args->readable; $args->next) {
    if ($args->is_attribute && $args->node_name eq $key) {
      push @case, [$pack->consume_arm($args->open, $dict, $type, $name)];
    } else {
      # XXX: 多分、$case[0] (== $body)
      $case[-1][-1]->add_node($args->current);
    }
  }
  @case;
}

sub consume_arm {
  my ($trans, $node, $dict, $type, $name, @opts) = @_;
  my $arm = $node->variant_builder($type, $name);
  my @cond = $arm->filter_or_add_from($node, $dict, @opts);
  if (@cond >= 2) {
    die $trans->node_error
      ($node, "Too many condtitions: %s"
       , join("", map {stringify_node($_)} @cond));
  }
  # $cond[0] は undef かもしれない。 ex. <:else/>

  my $cond; $cond = $trans->fake_cursor_from($arm, $cond[0]) if defined $cond[0];
  ($cond, $arm);
}

#----------------------------------------

sub has_element_macro {
  (my MY $trans, my Template $tmpl, my ($node, @elempath)) = @_;
  # XXX: macro の一覧は、ちゃんと取り出せるか?

  if (@elempath > 2) {
    # Not implemented.
    return;
  }

  my $pkg = $trans->get_rc_package_from_template($tmpl);
  my $ns;
  foreach my $shift (0, 1) {
    $ns = $trans->strip_ns(\@elempath) if $shift;
    my $macro_name = join("_", macro => @elempath);
    if (my $sub = $pkg->can($macro_name) || $trans->can($macro_name)) {
      return $sub;
    }
  }
}

#========================================
# 宣言関連

# XXX: use は perl 固有だから、ここに持たせるのは理にかなう。
sub declare_use {
}

sub attr_declare_delegate {
  (my MY $trans, my ($widget, $args, $argname, $subtype, @param)) = @_;
  my @elempath = $subtype ? @$subtype : $argname;
  my Template $tmpl = $trans->get_template_from_node($args);
  my Widget $base = $trans->get_widget_from_template($tmpl, @elempath);
  unless ($base) {
    die $trans->node_error($args, "No such widget %s"
			   , join(":", @elempath));
  }
  if ($tmpl->{cf_nsid} != $base->template_nsid) {
    $trans->mark_delayed_target($base);
  }

  if ($base->{arg_dict}{$argname}) {
    die $trans->node_error($args, q{delegate '%1$s' hides argument '%1$s' of widget %2$s}
			   , $argname, join(":", @elempath));
  }

  # pass thru する変数名の一覧。
  # でも、未指定なものだけね。
  # XXX: 引数rename
  my %vars; $vars{$_} = 1 for $widget->copy_specs_from($base);

  #
  # arg とは別の、コンパイル時のみの仮想的な変数として登録。
  #
  if ($widget->has_virtual_var($argname)) {
    die $trans->node_error($args, "Duplicate delegate? %s", $argname);
  }
  $widget->add_virtual_var
    ($argname, $trans->create_var(delegate => $args
				  , base_path => \@elempath
				  , base_widget => $base
				  , delegate_vars => \%vars, @param));
}

sub after_define_args {
  (my MY $trans, my ($target)) = @_;
  unless ($target->has_arg('body')) {
    $target->add_arg(body => $trans->create_var('code'));
  }
  $trans;
}

sub decode_decl_entpath {
  (my MY $trans, my $node) = @_;
  my ($has_body, @entpath)
    = $trans->decode_entpath($node, my $entns = [$node->node_path]);

  unless ($has_body) {
    return $node->node_nsname('', '_');
  }

  my (@macro_name, $rename_spec);
  while (@entpath) {
    my ($type, $name, @args) = @{shift @entpath};
    if ($type eq 'var') {
      if (@args) {
	# foo{name,name,...} case.
	die $trans->node_nimpl($node);
      } else {
	push @macro_name, $name;
      }
    } elsif ($type eq 'call') {
      push @macro_name, $name;
      foreach my $arg (@args) {
	my ($type, $name, @args) = @$arg;
	if ($type ne 'text') {
	  die $trans->node_nimpl($node);
	} elsif ($rename_spec) {
	  die $trans->node_nimpl($node); # Error: ()()
	} else {
	  $rename_spec = [split /=/, $name, 2];
	}
      }
    } else {
      die $trans->nimpl($node);
    }
  }

  (join("_", @macro_name), $rename_spec);
}

# For ArgMacro
sub add_decl_entity {
  (my MY $trans, my Widget $widget, my ($node)) = @_;

  # Widget の configure を呼ぶだけ、のケース ← config(value) でどう？
  {
    my $is_sysns = $trans->shift_ns_by(yatt =>
				       my $entns = [$node->node_path]);
    if ($is_sysns && @$entns == 1) {
      if ($widget->can_configure($entns->[0])) {
	$widget->configure($entns->[0], 1);
	return;
      }
    }
  }

  {
    my ($macro_name, @args) = $trans->decode_decl_entpath($node);

    foreach my $pkg ($trans->get_package_from_widget($widget)) {
      my $macro_class = do {
	my $sub = $pkg->can($macro_name)
	  or next;
	$sub->();
      };
      unless ($macro_class->can('handle')) {
	die $trans->node_error
	  ($node, "ArgMacro doesn't implement ->handle method: %s"
	   , $node->node_name);
      }
      return $macro_class->register_in($trans, $node, $widget, @args);
    }
  }
  die $trans->node_error($node, "No such ArgMacro: %s"
			 , $node->node_nsname);
}

#========================================
# 変数関連

use YATT::Types [VarType =>
		 [qw(cf_varname ^cf_argno ^cf_subtype
		     cf_default cf_default_mode
		     cf_filename cf_linenum
		   )]]
  , qw(:export_alias);

sub find_var {
  (my MY $trans, my ($scope, $varName)) = @_;
  for (; $scope; $scope = $scope->[1]) {
    croak "Undefined varName!" unless defined $varName;
    if (defined (my $value = $scope->[0]{$varName})) {
      return $value;
    }
  }
  return;
}

sub find_codearg {
  (my MY $trans, my ($scope, @elempath)) = @_;
  return if @elempath >= 3;
  $trans->strip_ns(\@elempath);
  return unless @elempath == 1;
  my $var = $trans->find_var($scope, $elempath[0])
    or return;
  return unless ref $var and $var->can('arg_specs');
  $var;
}

sub gen_getargs_static {
  (my MY $gen, my Widget $widget, my ($metainfo)) = @_;
  my (@args, %scope);
  foreach my $name ($widget->{arg_order} ? @{$widget->{arg_order}} : ()) {
    my VarType $var = $widget->{arg_dict}{$name};
    $scope{$name} = $var;
    my $decl = sprintf q{my %s = $_[%d]}, $var->as_lvalue, $$var{cf_argno};
    my $value = $var->gen_getarg
      ($gen, [\%scope], $widget, $metainfo, qq{\$args->[$$var{cf_argno}]});
    push @args, "$decl = $value;\n";
  }
  join "", @args;
}

sub gen_getargs_dynamic {
  '';
}

sub gen_pass_through_arg_typed {
  (my MY $gen, my ($type, $scope, $baseNC, $targetNode)) = @_;
  my $node = $targetNode
    ? $gen->fake_cursor_from($baseNC, $targetNode)
      : $baseNC;
  my $name = $node->node_name;
  if (my $var = $gen->has_pass_through_var($scope, $node, $name)) {
    $var->as_lvalue;
  } else {
    $gen->faked_gentype($type => $scope, $node)
  }
}

sub try_pass_through {
  (my MY $trans, my ($scope, $cursor, $rawNode, $defaultFlag)) = @_;
  if (node_size($rawNode) == 1 and node_flag($rawNode) == 0
     and (my $nm = node_body($rawNode)) =~ /^\w+$/) {

    # [name=bareword_ident]
    # Must be an existing variable.
    if (my $var = $trans->find_var($scope, $nm)) {
      $var->as_lvalue;
    } else {
      die $trans->node_error($cursor, "No such variable '%s'", $nm);
    }
  } elsif (node_size($rawNode) == 0) {

    # [name]
    # variable or flag.
    if (my $var = $trans->find_var($scope, my $nm = node_name($rawNode))) {
      $var->as_lvalue;
    } elsif (defined $defaultFlag) {
      $defaultFlag
    } else {
      die $trans->node_error($cursor, "No such variable '%s'", $nm);
    }
  } else {
    undef;
  }
}

sub mark_vars {
  (my MY $trans, my ($scope, $early_escaped, $node)) = @_;
  my @result;
  for (; $node->readable; $node->next) {
    if ($node->node_type == TEXT_TYPE) {
      # XXX: dots_for_arrows
      push @result, $node->current;
    } elsif ($node->node_type == ELEMENT_TYPE) {
      push @result, \ $trans->generate_captured($scope, $node);
    } else {
      push @result, \ $trans->generate_entref($scope, $early_escaped, $node);
    }
  }
  @result;
}

sub feed_array_if {
  (my MY $trans, my ($name, $array)) = @_;
  return unless @$array >= 1;
  return unless $array->[0][0] eq $name;
  my $desc = shift @$array;
  wantarray ? @{$desc}[1..$#$desc] : $desc;
}

# $node の情報を借りながら、@_ を generate.
sub gen_entref_list {
  (my MY $trans, my ($scope, $node)) = splice @_, 0, 3;
  my @result;
  foreach my $item (@_) {
    push @result, $trans->gen_entref_path
      ($scope, $node
       , is_nested_entpath($item) ? @$item : $item);
  }
  @result;
}

sub gen_entref_path {
  (my MY $trans, my ($scope, $node)) = splice @_, 0, 3;
  my $var;
  my @expr = do {
    if (my ($name, @args) = $trans->feed_array_if(call => \@_)) {
      my $pkg = $trans->get_package_from_node($node);
      my $dont_call;
      my $call = do {
	# XXX: codevar は、path の先頭だけ。
	# 引数にも現れるから、
	if ($pkg->can(my $en = "entity_$name")) {
	  sprintf('%s->%s', $pkg, $en);
	} elsif ($var = $trans->find_codearg($scope, $name)) {
	  sprintf('%1$s && %1$s->', $var->as_lvalue);
	} elsif ($var = $trans->find_var($scope, $name)) {
	  if (my $handler = $var->can("entmacro_")) {
            $dont_call++;
	    $handler->($var, $trans, $scope, $node, \@_, [], @args);
	  } else {
	    # XXX: 本当は $pkg よりもファイル名を出すべき。
	    die $trans->node_error
	      ($node, "not implemented call '%s' for %s in %s"
	       , $name, $pkg, $node->node_body);
	  }
	} elsif (my $handler = $trans->can("entmacro_$name")) {
	  # XXX: $pkg->can の方が、拡張向きで良いのだが…
	  # 予約語も持ちたい。
          $dont_call++;
	  $handler->($pkg, $trans, $scope, $node, \@_, [], @args);
	} else {
	  die $trans->node_error($node, "not implemented call '%s' in %s"
				 , $name, $node->node_body);
	}
      };

      ($dont_call || ref $call) ? $call : sprintf q{(%s(%s))}, $call, join ", "
	, $trans->gen_entref_list($scope, $node, @args);
    } elsif (($name) = $trans->feed_array_if(var => \@_)) {
      unless ($var = $trans->find_var($scope, $name)) {
	die $trans->node_error($node, "No such variable '%s'", $name);
      } else {
	$var->as_lvalue;
      }
    } elsif (($name) = $trans->feed_array_if(expr => \@_)) {
      $name;
    } elsif (my @items = $trans->feed_array_if(array => \@_)) {
      '['.join(", ", $trans->gen_entref_list($scope, $node, @items)).']';
    } elsif (my @pairs = $trans->feed_array_if(hash => \@_)) {
      # XXX: '=>' is better.
      '{'.join(", ", $trans->gen_entref_list($scope, $node, @pairs)).'}';
    } elsif (($name) = $trans->feed_array_if(text => \@_)) {
      qqvalue($name);
    } else {
      die $trans->node_error($node, "NIMPL(%s)", terse_dump(@_));
    }
  };

  while (@_) {
    my $item = shift;
    push @expr, do {
      my ($type, $name, @args) = @$item;
      if ($type eq 'call') {
	# 先頭の変数が確定している場合の、特殊処理。
	# XXX: 同じ名前のメソッドが呼べなくなる、というデメリットが有る。
	if ($var and not ref $name
	    and my $handler = $var->can("entmacro_$name")) {
	  # ここまでの式を reset する必要が有る時がある。
	  $handler->($var, $trans, $scope, $node, \@_, \@expr, @args);
	} else {
	  sprintf q{%s(%s)}, $name, join ", "
	    , $trans->gen_entref_list($scope, $node, @args);
	}
      } elsif ($type eq 'var') {
	sprintf '{%s}', join ", ", ref $name
	  ? $trans->gen_entref_list($scope, $node, $name, @args)
	    : qqvalue($name);
      } elsif ($type eq 'aref') {
	# list は本来冗長だが、nest の処理のため。
	sprintf '[%s]', join", ", ref $name
	  ? $trans->gen_entref_list($scope, $node, $name, @args)
	    : $name;
      } else {
	die $trans->node_error($node, "NIMPL(type=$type)");
      }
    };
  }

  @expr > 1 ? join("->", @expr) : $expr[0];
}

sub find_if_codearg {
  (my MY $trans, my ($scope, $node, $entpath)) = @_;
  my @entns = $node->node_path;
  return unless $trans->strip_ns(\@entns);
  return if @entns;
  return unless @$entpath == 1;
  return unless $entpath->[0][0] eq 'call';
  my ($op, $name, @args) = @{$entpath->[0]};
  my $codearg = $trans->find_codearg($scope, $name)
    or return;
  ($codearg, @args);
}

sub decode_entpath {
  (my MY $trans, my ($node, $entns)) = @_;
  my $has_entns = defined $entns;
  unless ($has_entns) {
    $trans->strip_ns($entns = [$node->node_path]);
  }
  my $body = $node->node_body;
  substr($body, 0, 0) = ':' if defined $body and not defined $node->node_name;
  my @entpath = $trans->parse_entpath(join('', map {':'.$_} @$entns)
				      . coalesce($body, '')
				      , $trans, $node);

  my $has_body = $body ? 1 : 0;

  $has_entns ? ($has_body, @entpath) : ($entns, $has_body, @entpath);
}

sub generate_entref {
  (my MY $trans, my ($scope, $escaped, $node)) = @_;

  my ($entns, $has_body, @entpath) = $trans->decode_entpath($node);

  # 特例。&yatt:codevar(); は、副作用で print.
  if ($escaped == ENT_PRINTED
      and my ($codearg, @args)
      = $trans->find_if_codearg($scope, $node, \@entpath)) {
    return \ sprintf('%1$s && %1$s->(%2$s)', $codearg->as_lvalue
		     , join(", ", map {
		       $trans->gen_entref_path($scope, $node, $_)
		     } @args));
    # 引数。
  }
  if ($has_body || @$entns > 1) {
    # path が有る。
    my $expr = $trans->gen_entref_path($scope, $node, @entpath);
    # XXX: sub { print } なら \ $expr にすべきだが、
    #  sub { value } などは、むしろ YATT::escape(do {$expr}) すべき。
    return $expr if ref $expr;
    return $escaped ? qq(YATT::escape($expr)) : $expr;
  }

  my $varName = shift @$entns;
  unless (my $vardecl = $trans->find_var($scope, $varName)) {
    die $trans->node_error($node, "No such variable '%s'", $varName);
  } else {
    $escaped ? $vardecl->as_escaped : $vardecl->as_lvalue;
  }
}

#========================================
# マクロなどで、cursor になっていない targetNode を入手した後で、
# それを再び cursor にして、指定の型のソースを生成する仕組み。

# デフォルト値を最初に指定。
sub default_gentype {
  (my MY $trans, my ($default, $type, $scope, $baseNC, $targetNode)) = @_;
  if (ref $type) {
    croak "Type mismatch: \$type should be string for default_gentype: $type";
  }
  unless (defined $targetNode and node_body($targetNode)) {
    return $default;
  }
#  my $name = node_name($targetNode);
#  if (my $var
#      = $trans->has_pass_through_var($scope, $targetNode, $name)) {
#    $var->as_lvalue;
#  } else {
    $trans->faked_gentype($type, $scope, $baseNC, $targetNode);
#  }
}

sub faked_gentype {
  (my MY $trans, my ($type, $scope, $baseNC, $targetNode)) = @_;
  my $node = $targetNode ? $trans->fake_cursor_from($baseNC, $targetNode)
    : $baseNC;
  my $sub = $trans->can("t_$type")
    or die $trans->node_error($node, "No such argtype: %s", $type);
  $sub->()->gen_assignable_node($trans, $scope, $node);
}

# expr 専用。デフォルト値も渡せる。
sub faked_genexpr {
  (my MY $trans, my ($scope, $baseNC, $targetNode, $default, $ent_flag)) = @_;
  unless (defined $targetNode and node_body($targetNode)) {
    return $default;
  }
  # open するのが、faked_gentype(scalar) とも違う所、のはず。
  my $nc = $trans->fake_cursor_from($baseNC, $targetNode)->open;
  $trans->genexpr_node($scope, defined $ent_flag ? $ent_flag : ENT_RAW
		       , $nc);
}

#========================================

sub YATT::Translator::Perl::VarType::gen_getarg {
  (my VarType $var, my MY $gen
   , my ($scope, $widget, $metainfo, $actual)) = @_;
  return $actual unless defined $var->{cf_default}
    and defined (my $mode = $var->{cf_default_mode});

  if ($mode eq "!") {
    return qq{defined $actual ? $actual : }
      . qq{die "Argument '$var->{cf_varname}' is undef!"}
  }

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

  my $default = $var->gen_assignable_node
    ($gen, $scope
     , $gen->fake_cursor($widget, $metainfo
			 , map {ref $_ ? @$_ : $_} $var->{cf_default})
     , 1);

  qq{($cond ? $actual : $default)};
}

sub YATT::Translator::Perl::VarType::gen_assignable_node {
  (my VarType $var, my MY $trans, my ($scope, $node, $is_opened)) = @_;
  # early escaped な変数への代入値は、代入前に escape される。
  my $escaped = $var->early_escaped;
  $var->quote_assignable
    ($trans->mark_vars($scope, $escaped, $is_opened ? $node : $node->open));
}

sub YATT::Translator::Perl::VarType::is_required {
  my VarType $var = shift;
  defined $var->{cf_default_mode} && $var->{cf_default_mode} eq '!';
}

sub YATT::Translator::Perl::VarType::can_call { 0 }
sub YATT::Translator::Perl::VarType::early_escaped { 0 }
sub YATT::Translator::Perl::VarType::lvalue_format {'$%s'}
sub YATT::Translator::Perl::VarType::as_lvalue {
  my VarType $var = shift;
  sprintf $var->lvalue_format, $var->{cf_varname};
}

sub YATT::Translator::Perl::VarType::escaped_format {'YATT::escape($%s)'}

sub YATT::Translator::Perl::VarType::as_escaped {
  my VarType $var = shift;
  sprintf $var->escaped_format, $var->{cf_varname};
}

sub YATT::Translator::Perl::VarType::as_typespec {
  shift->type_name;
}

sub YATT::Translator::Perl::VarType::as_argspec {
  (my VarType $var) = @_;
  my $spec = $var->as_typespec;
  if (my $mode = $var->{cf_default_mode}) {
    $spec .= $mode;
    if (defined (my $default = $var->{cf_default})) {
      $spec .= join "", map {
	ref $_ ? map(ref $_ ? stringify_node($_) : $_, @$_) : $_
      } $default;
    }
  }
  $spec;
}

use YATT::ArgTypes
  (-type_map => \%TYPE_MAP
   , -base => VarType
   , -type_fmt => join("::", MY, 't_%s')
   , [text => -alias => '']
   , [html => \ lvalue_format => '$html_%s', \ early_escaped => 1]
   , [scalar => -alias => ['value', 'flag']]
   , ['list']
   , [attr => -base => 'text']
   , [code   => -alias => 'expr', \ can_call => 1
      # 引数の型情報
      , -fields => [qw(arg_dict arg_order)]]
   , [delegate => -fields => [qw(cf_base_path
				 cf_base_widget
				 cf_delegate_vars)]]
   , qw(:type_name)
  );

$calling_conv{this} = t_scalar->new(varname => 'this');
$calling_conv{args} = t_scalar->new(varname => 'args');
$calling_conv{_} = t_scalar->new(varname => '_');

sub YATT::Translator::Perl::t_text::quote_assignable {
  shift;
  my ($nvars);
  my @items = map {
    if (ref $_) {
      $nvars++;
      $$_
    } else {
      # $var is prohibited.
      qparen($_);
    }
  } @_;
  if (@items == 1 && !$nvars) {
    $items[0];
  } else {
    MY->as_join(@items);
  }
}

# XXX: 本当に良いのか?
sub YATT::Translator::Perl::t_html::quote_assignable {
  shift;
  sprintf q{YATT::escape(%s)}, t_text->quote_assignable(@_);
}

sub YATT::Translator::Perl::t_html::escaped_format {shift->lvalue_format}

sub YATT::Translator::Perl::t_html::gen_assignable_node {
  (my VarType $var, my MY $trans, my ($scope, $node, $is_opened)) = @_;
  # XXX: フラグがダサい。
  my $n = $is_opened ? $node : $node->open;
  if (my $expr = $trans->has_single_bare_varexpr($scope, $n)) {
    t_scalar->quote_assignable($expr);
  } else {
    $trans->as_join($trans->generate_body($scope, $n));
  }
}

sub YATT::Translator::Perl::t_attr::as_typespec {
  my t_attr $var = shift;
  join(":", $var->type_name, $var->{cf_subtype} || $var->{cf_varname});
}


sub YATT::Translator::Perl::t_attr::entmacro_ {
  (my t_attr $var, my MY $trans
   , my ($scope, $node, $restExpr, $queue, @args)) = @_;
  if (@$restExpr) {
    die $trans->node_error($node, "attr() should be last call.");
  }
  if (ref $var->{cf_subtype}) {
    die $trans->node_error($node, "nested subtype for attr");
  }
  my @expr = $trans->gen_entref_list($scope, $node, @args);
  sprintf(q{YATT::attr('%s', %s)}
	    , $var->{cf_subtype} || $var->{cf_varname}
	    , join(", ", $var->as_lvalue, @expr));
}

sub YATT::Translator::Perl::t_attr::as_escaped {
  my t_attr $var = shift;
  if (ref $var->{cf_subtype}) {
    die "nested subtype for attr: $var->{cf_varname}";
  }
  my $realvar = sprintf $var->lvalue_format, $var->{cf_varname};
  sprintf(q{YATT::named_attr('%s', %s)}
	  , $var->{cf_subtype} || $var->{cf_varname}
	  , $realvar);
}

sub YATT::Translator::Perl::t_scalar::quote_assignable {
  shift;
  'scalar(do {'.join("", map { ref $_ ? $$_ : $_ } @_).'})';
}

sub YATT::Translator::Perl::t_list::quote_assignable {
  shift;
  '['.join("", map { ref $_ ? $$_ : $_ } @_).']';
}

sub YATT::Translator::Perl::t_list::entmacro_expand {
  (my t_list $var, my MY $trans
   , my ($scope, $node, $restExpr, $queue, @args)) = @_;
  my $was = join "->", splice @$queue, 0;
  sprintf q{map($_ ? @$_ : (), %s)}, $was;
}

sub YATT::Translator::Perl::t_list::entmacro_size {
  (my t_list $var, my MY $trans
   , my ($scope, $node, $restExpr, $queue, @args)) = @_;
  my $was = join "->", splice @$queue, 0;
  sprintf q{scalar(map(defined $_ ? @$_ : (), %s))}, $was;
}

# XXX: head($n), tail($n)

sub YATT::Translator::Perl::t_list::entmacro_head {
  (my t_list $var, my MY $trans
   , my ($scope, $node, $restExpr, $queue, @args)) = @_;
  my $was = join "->", splice @$queue, 0;
  sprintf q{map($_ ? $$_[0] : (), %s)}, $was;
}

sub YATT::Translator::Perl::t_list::entmacro_tail {
  (my t_list $var, my MY $trans
   , my ($scope, $node, $restExpr, $queue, @args)) = @_;
  my $was = join "->", splice @$queue, 0;
  sprintf q{map($_ ? @{$_}[1..$#$_] : (), %s)}, $was;
}

sub YATT::Translator::Perl::t_code::gen_call {
  (my t_code $argdecl, my MY $trans, my ($scope, $node)) = @_;
  my ($post, @args) = $trans->genargs_static
    ($scope, $node->open, $argdecl->arg_specs);
  # XXX: こっちを () しなくて済むのはなぜ? => <yatt:tag/> の call だから?
  return \ sprintf '%1$s && %1$s->(%2$s)%3$s', $argdecl->as_lvalue
    , join(", ", @args), $post;
}

sub YATT::Translator::Perl::t_code::arg_specs {
  my t_code $argdecl = shift;
  ($argdecl->{arg_dict} ||= {}, $argdecl->{arg_order} ||= []);
}

sub YATT::Translator::Perl::t_code::gen_args {
  (my t_code $argdecl) = @_;
  return unless $argdecl->{arg_order}
    && (my @args = @{$argdecl->{arg_order}});
  \ sprintf('my (%s) = @_', join(", ", map {
    $argdecl->{arg_dict}{$_}->as_lvalue;
  } @args));
}

sub YATT::Translator::Perl::t_code::gen_body {
  (my t_code $argdecl, my MY $trans, my ($scope, $is_expr, $node)) = @_;
  return unless $node->array_size;
  if ($is_expr) {
    $trans->genexpr_node($scope, ENT_RAW, $node);
  } else {
    $trans->as_statement_list
      ($argdecl->gen_args
       , $trans->generate_body([{}, [$argdecl->{arg_dict}, $scope]], $node));
  }
}

sub YATT::Translator::Perl::t_code::gen_assignable_node {
  (my t_code $argdecl, my MY $trans, my ($scope, $node, $is_opened)) = @_;
  my $is_expr = !$is_opened && !$node->is_quoted_by_element;
  $trans->as_sub('', $argdecl->gen_body($trans, $scope, $is_expr
					, $is_opened ? $node : $node->open));
}

sub YATT::Translator::Perl::t_code::has_arg {
  (my t_code $argdecl, my ($name)) = @_;
  defined $argdecl->{arg_dict}{$name};
}

sub YATT::Translator::Perl::t_code::add_arg {
  (my t_code $codevar, my ($name, $arg)) = @_;
  add_arg_order_in($codevar->{arg_dict}, $codevar->{arg_order}, $name, $arg);
  $codevar;
}

sub YATT::Translator::Perl::t_code::clone {
  (my t_code $orig) = @_;
  my t_code $new = $orig->SUPER::clone;
  my ($dict, $order) = $orig->arg_specs;
  foreach my $name (@$order) {
    $new->add_arg($name, $dict->{$name}->clone);
  }
  $new
}

# code 型の変数宣言の生成
sub create_var_code {
  (my MY $trans, my ($node, @param)) = @_;
  my t_code $codevar = $trans->t_code->new(@param);
  $trans->define_args($codevar, $node->open) if $node;
  $codevar;
}

sub YATT::Translator::Perl::t_delegate::gen_call {
  (my t_delegate $argdecl, my MY $trans, my ($scope, $node)) = @_;
  my $func = $trans->get_funcname_to($trans->{cf_mode}
				     , $argdecl->{cf_base_widget});
  # XXX: テストを書け。body が code か html か、だ。
  # my $body_dict = $argdecl->{cf_base_widget}->get_arg_spec(body => undef);
  my $body_spec = $argdecl->{cf_base_widget}->{arg_dict}->{body};
  my $body_scope = do {
    if ($body_spec->type_name eq 'code') {
      [$body_spec->{arg_dict}, $scope]
    } else {
      $scope
    }
  };
  my ($post, @args) = $trans->genargs_static
    ([{}, $body_scope]
     , $node->open, $argdecl->arg_specs);
  return \ sprintf(' %s($this, [%s])%s', $func
		   , join(", ", map {defined $_ ? $_ : 'undef'} @args)
		   , $post);
}

sub YATT::Translator::Perl::t_delegate::arg_specs {
  my t_delegate $argdecl = shift;
  ($argdecl->{cf_base_widget}->arg_specs
   , $argdecl->{cf_delegate_vars});
}

#========================================

sub make_arg_spec {
  my ($dict, $order) = splice @_, 0, 2;
  foreach my $name (@_) {
    $dict->{$name} = @$order;
    push @$order, $name;
  }
}

sub arg_name_types {
  (my MY $trans, my ($args)) = @_;
  my (@path) = $args->node_path;
  if ($args->is_attribute and $args->is_quoted_by_element) {
    shift @path;
  }
  my ($name) = shift @path;
  @path >= 2 ? ($name, \@path) : ($name, $path[0]);
}

# macro の、 my:type=var など専用。
sub feed_arg_spec {
  (my MY $trans, my ($args, $arg_dict, $arg_order)) = splice @_, 0, 4;
  my $found;
  for (my $nth = 0; $args->readable; $args->next) {
    last unless $args->is_primary_attribute;
    my ($name, @ext) = $args->node_path;
    unless (defined $name) {
      $name = $arg_order->[$nth++]
	or die $trans->node_error($args, "Too many args");
    }
    defined (my $argno = $arg_dict->{$name})
      or die $trans->node_error($args, "Unknown arg '%s'", $name);

    $_[$argno] = $args->current;
    $found++;
  }
  $found;
}

{
  # list=list/value, my=text, ith=text
  make_arg_spec(\ my %arg_dict, \ my @arg_order
		, qw(list my ith));

  declare_alias macro_yatt_foreach => \&macro_foreach;
  sub macro_foreach {
    (my MY $trans, my ($scope, $args, $fragment)) = @_;

    $trans->feed_arg_spec($args, \%arg_dict, \@arg_order
			  , my ($list, $my, $ith))
      or die $trans->node_error($args, "Not enough arguments");

    unless (defined $list) {
      die $trans->node_error($args, "no list= is given");
    }

    # $ith をまだ使っていない。
    my %local;
    my $loopvar = do {
      if ($my) {
	my ($x, @type) = node_path($my);
	my $varname = node_body($my);
	$local{$varname} = $trans->create_var
	  ($type[0] || '', undef, varname => $varname);
	'my $' . $varname;
      } else {
	# _ は？ entity 自体に処理させるか…
	''
      }
    };

    my $fmt = q{foreach %1$s (%2$s) %3$s};
    my $listexpr = do {
      if (0) {
	print STDERR "# foreach list: "
	  , YATT::LRXML::Node::stringify_node($list), "\n";
      }
      # XXX: 何故使い分けが必要になってしまうのか?
      # my $fc = $args->adopter_for($list);
      # my $fc = $trans->fake_cursor_from($args, $list);
      if (my $var = $trans->has_pass_through_var
	  ($scope, my $fc = $trans->fake_cursor_from($args, $list), 'list')) {
	unless ($var->type_name eq 'list') {
	  my $path = $args->parent->node_path;
	  die $trans->node_error($fc, "$path - should be list type")
	}
	'@'.$var->as_lvalue;
      } else {
	$trans->genexpr_node($scope, 0, $args->adopter_for($list));
      }
    };
    my @statements = $trans->as_statement_list
      ($trans->generate_body([\%local, $scope], $args));

    if ($fragment) {
      ($fmt, $loopvar, $listexpr, \@statements);
    } else {
      \ sprintf $fmt, $loopvar, $listexpr, $trans->as_block(@statements);
    }
  }
}

{
  # if
  make_arg_spec(\ my %arg_dict, \ my @arg_order
		, qw(if unless));
  sub gen_macro_if_arm {
    (my MY $trans, my ($scope, $primary, $pkg, $if, $unless, $body)) = @_;
    my $header = do {
      if ($primary) {
	my ($kw, $cond) = do {
	  if ($if) { (if => $if) }
	  elsif ($unless) { (unless => $unless) }
	  else { die "??" }
	};
	sprintf q{%s (%s) }, $kw
	  , $trans->genexpr_node($scope, 0
				 , $trans->fake_cursor_from($body, $cond, 1));
      } else {
	my ($cond, $true) = do {
	  if ($if) { ($if, 1) }
	  elsif ($unless) { ($unless, 0) }
	  else {}
	};
	unless (defined $cond) {
	  q{else }
	} else {
	  my $expr = $trans->genexpr_node
	    ($scope, 0
	     , $trans->fake_cursor_from($body, $cond, 1));
	  sprintf q{elsif (%s) }, $true ? $expr : qq{not($expr)};
	}
      }
    };
    $header . $trans->as_block
      ($trans->as_statement_list
       ($trans->generate_body($scope, $body)));
  }

  declare_alias macro_yatt_if => \&macro_if;
  sub macro_if {
    (my MY $trans, my ($scope, $args)) = @_;

    my @case = do {
      $trans->feed_arg_spec($args, \%arg_dict, \@arg_order
			    , my ($if, $unless))
	or die $trans->node_error($args, "Not enough arguments");
      ([$if, $unless, $args->variant_builder]);
    };
    for (; $args->readable; $args->next) {
      if ($args->is_attribute && $args->node_name eq 'else') {
	my $kid = $args->open;
	$trans->feed_arg_spec($kid, \%arg_dict, \@arg_order
			      , my ($if, $unless));
	push @case, [$if, $unless, $kid];
      } else {
	# XXX: 多分、$case[0]
	$case[-1][-1]->add_node($args->current);
      }
    }

    my $pkg = $trans->get_package_from_node($args);
    my @script = $trans->gen_macro_if_arm($scope, 1, $pkg, @{shift @case});
    while (my $arm = shift @case) {
      push @script, $trans->gen_macro_if_arm($scope, 0, $pkg, @$arm);
    }
    \ join " ", @script;
  }
}

{
  declare_alias macro_yatt_block => \&macro_block;
  sub macro_block {
    (my MY $trans, my ($scope, $args)) = @_;
    \ $trans->as_block
      ($trans->as_statement_list
       ($trans->generate_body([{}, $scope], $args)));
  }

  declare_alias macro_yatt_my => \&macro_my;
  sub macro_my {
    (my MY $trans, my ($scope, $args)) = @_;
    my @assign;
    my $filename = $args->metainfo->filename;
    for (; $args->readable; $args->next) {
      last unless $args->is_primary_attribute;
      my ($name, $typename) = $trans->arg_name_types($args);
      $typename ||= $args->next_is_body ? 'html' : 'text';
      if (my VarType $old = $scope->[0]{$name}) {
	die $trans->node_error
	  ($args, "Variable '%s' redefined (previously at file %s line %s)"
	   , $name, $old->{cf_filename} || '(unknown)'
	   , $old->{cf_linenum} || '(unknown)');
      }
      my $var = $scope->[0]{$name}
	= $trans->create_var($typename, $args
			     , varname => $name
			     , filename => $filename
			     , linenum  => $args->linenum);

      push @assign, [$var, $args->node_size
		     ? $var->gen_assignable_node($trans, $scope, $args)
		     : ()];
    }

    if ($args->readable) {
      my $var = $assign[-1][0];
      $assign[-1][1] ||= $var->gen_assignable_node($trans, $scope, $args, 1);
    }

    my @script;
    foreach my $desc (@assign) {
      my ($var, $value) = @$desc;
      my $script = sprintf q{my %s}, $var->as_lvalue;
      $script .= q{ = } . $value if defined $value;
      push @script, \ $script;
    }
    @script;
  }
}

{
  declare_alias macro_yatt_format => \&macro_format;
  sub macro_format {
    (my MY $trans, my ($scope, $args)) = @_;

    unless ($args->readable && $args->is_primary_attribute) {
      die $trans->node_error($args, "format parameter is missing");
    }

    my $name = $args->node_name;

    my $format = do {
      if (my $var = $trans->has_pass_through_var($scope, $args, $name)) {
	$var->as_lvalue;
      } else {
	$trans->faked_gentype(text => $scope, $args);
      }
    };

    $args->next;

    sprintf(q|sprintf(%s, %s)|
	    , $format
	    , $trans->as_join($trans->generate_body([{}, $scope], $args)));
  }
}

sub macro_dbfetch {
  require YATT::Translator::Perl::macro_dbfetch;
  shift->YATT::Translator::Perl::macro_dbfetch::macro(@_);
}

sub feed_arg_or_make_hash_of {
  (my $trans
   , my ($type, $scope, $args, $arg_dict, $arg_order)) = splice @_, 0, 6;
  my (@primary, @secondary);
  for (my $nth = 0; $args->readable; $args->next) {
    last unless $args->is_primary_attribute;
    my ($name, @ext) = $args->node_path;
    unless (defined $name) {
      $name = $arg_order->[$nth++]
	or die $trans->node_error($args, "Too many args");
    }
    if ($name =~ /^-(.*)/) {
      # XXX: そもそも -name=[...] で構造化したかった
      push @secondary, [$name, $trans->faked_gentype
			($type => $scope, $args, $args->current)];
      next;
    }
    defined (my $argno = $arg_dict->{$name}) or do {
      push @primary, [$name, $trans->faked_gentype
			($type => $scope, $args, $args->current)];
      next;
    };

    $_[$argno] = $args->current;
  }
  grep {@$_ ? $_ : ()} (\@primary, \@secondary);
}

#========================================
sub entmacro_if {
  my ($this, $trans
      , $scope, $node, $restExpr, $queue, @args) = @_;
  # XXX: $cond を文字列にするのは不便。
  my ($cond, $then, $else)
    = $trans->gen_entref_list($scope, $node, @args);
  # XXX: 三項演算だと、狂いが出そうな。
  sprintf q{((%s) ? %s : %s)}
    , map {ref $_ ? $$_ : $_} $cond, $then, $else || q{''};
};

sub entmacro_render {
  my ($this, $trans
      , $scope, $node, $restExpr, $queue, @args) = @_;
  my ($type, @expr)
    = $trans->gen_entref_list($scope, $node, @args);
  \ sprintf q{__PACKAGE__->can('render_'.%s)->($this, [%s])}
    , $type, join(", ", @expr);
};
#========================================

sub paren_escape ($) {
  unless (defined $_[0]) {
    confess "Undefined text";
  }
  $_[0] =~ s{([\(\)\\])}{\\$1}g;
  $_[0]
}

sub qparen ($) {
  'q('.paren_escape($_[0]).')'
}

sub qqvalue ($) {
  'q'.qparen($_[0]);
}

{
  my %map = ("\r", "r", "\n", "n");
  sub qcrlf ($) {
    my ($crlf) = @_;
    $crlf =~ s{([\r\n])}{\\$map{$1}}g;
    $crlf;
  }
}

sub dots_for_arrows {
  shift;
  return unless defined $_[0];
  $_[0] =~ s{\b\.(?=\w+\()}{->}g;
  $_[0];
}

1;
