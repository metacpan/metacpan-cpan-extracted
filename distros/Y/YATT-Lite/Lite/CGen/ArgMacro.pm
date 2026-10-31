package YATT::Lite::CGen::ArgMacro;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

sub MY () {'YATT::Lite::CGen::ArgMacro'}

use base qw(YATT::Lite::CGen::Perl);
use YATT::Lite::MFields;

use YATT::Lite::Core qw(ArgMacro Part Template);
use YATT::Lite::Constants;

#
# widget 呼び出しの引数リスト $primary に含まれる argmacro を展開する。
# (instance と対応表は make_on_declare が widget に登録したもの)
#
sub expand_all_argmacro {
  (my $class, my $cgen, my Part $widget, my $primary, my $node) = @_;
  my ($newPrimary) = $class->expand_args(
    $cgen, $primary, $node, $widget,
    $widget->{_argmacro_instance_list},
    $widget->{_argmacro_instance_dict},
    $widget->{_argmacro_trigger_dict},
    $widget->{_argmacro_output_dict} // {},
  );
  $newPrimary;
}

#
# 引数リスト $primary に、argmacro の instance 群を展開する。
# widget 呼び出しと、通常のマクロの要素 (expand_element) で共用。
#
#  - in はトリガー。instance 毎に集めて取り除き、on_expand に渡す
#  - refer は取り除かず、$args/$vars で参照させるだけ
#    ($widget が無ければ $vars は undef)
#  - out (rename 後の実名) が明示された instance は bypass (展開しない)。
#    同じ instance の in も有ればエラー
#  - 出力は、残りの引数の後ろに置く (要素マクロの先頭の宣言を崩さないため)
#
# $triggers, $outputs は 実名 => [$instName, $formalName]
# 戻り値: ($newPrimary, {$instName => $result})
#
sub expand_args {
  (my $class, my $cgen, my $primary, my $node, my Part $widget
   , my ($instList, $instDict, $triggers, $outputs)) = @_;
  my (%found, %firstInput, %bypass, %byName, @rest);
  foreach my $arg (@$primary) {
    my $argName = YATT::Lite::CGen::Perl::argName($arg);
    if (defined $argName and not ref $argName
        and my $spec = $triggers->{$argName}) {
      my ($instName, $formalArgName) = @$spec;
      $found{$instName}{$formalArgName} = $arg;
      $firstInput{$instName} //= $argName;
      next;
    }
    if (defined $argName and not ref $argName) {
      $byName{$argName} //= $arg;
      if (my $spec = $outputs->{$argName}) {
        $bypass{$spec->[0]} //= $argName;
      }
    }
    push @rest, $arg;
  }
  return $primary if not %found;

  foreach my $instName (@$instList) {
    next unless $found{$instName} and $bypass{$instName};
    die $cgen->generror_at(
      $node && $node->[NODE_LNO],
      qq{argmacro %s is bypassed by explicit output '%s'; input '%s' can\'t be given}
      , $instDict->{$instName}->call_spec
      , $bypass{$instName}, $firstInput{$instName}
    );
  }

  my (@outputs, %results);
  foreach my $instName (@$instList) {
    my $args = $found{$instName} or next;
    my ($result, @nodes) = $class->apply_argmacro(
      $cgen, $instDict->{$instName}, $args, $widget, \%byName, $node
    );
    $results{$instName} = $result;
    push @outputs, @nodes;
  }

  ([@rest, @outputs], \%results);
}

# 戻り値: ($result, @output_nodes)
sub apply_argmacro {
  (my $class, my $cgen, my ArgMacro $argmacro, my $args
   , my Part $widget, my $byName, my $node) = @_;

  my $vars = $argmacro->{_arg_dict};
  if (my $refer = $argmacro->{refer_names}) {
    $vars = +{%{$vars // {}}};
    foreach my $name (@$refer) {
      $args->{$name} = $byName->{$name} if $byName->{$name};
      $vars->{$name} = $widget ? $widget->{_arg_dict}{$name} : undef;
    }
  }

  my $result = $argmacro->{_on_expand}->($cgen, $args, $vars, $argmacro, $node);
  return $result if not keys %$result;

  ($result, map {
    my $attName = $_->[NODE_PATH];
    my $value = $result->{$argmacro->{resolve_map}{$attName}};
    # 引数 node が返されたら、出力名に付け替えて渡す
    # (pass through の扱いは受け手に任せる)
    ref $value eq 'ARRAY'
      ? copy_attribute_renamed_as($value, $attName)
      : create_attribute($attName, $value);
  } @{$argmacro->{output_args}});
}

sub generate_on_declare {
  (my MY $self, my ArgMacro $argmacro) = @_;

  my $script = $self->generate_on_expand($argmacro);
  my $code = YATT::Lite::Util::ckeval($script);
  $argmacro->{_on_expand} = $code;

  $self->make_on_declare($argmacro);
}

# Builds the closure which is called for each %macro; in widget declarations.
# This is shared by template-defined and module-defined (YATT::Lite::ArgMacro)
# argmacros.
sub make_on_declare {
  (my $self_or_class, my ArgMacro $argmacro) = @_;

  return sub {
    (my MY $self, my $parser, my Part $part, my $node) = @_;

    my ($toName, $fromName) = do {
      if (not (my $body = $node->[NODE_BODY])) {
        ()
      } elsif (not $body->[2]) {
        ()
      } else {
        my (undef, $macroName, $pathItem) = @$body;
        my (undef, $renameSpec) = @$pathItem;

        my @match = $renameSpec =~ m{^(\w+)=(\w+)}
          or $parser->synerror_at($node->[NODE_LNO],
                                  "Invalid rename spec '%s'", $renameSpec);
        @match;
      }
    };

    my ($instName, $instance, $triggers, $outputs)
      = MY->instantiate($argmacro, $toName, $fromName);

    if ($part->{_argmacro_instance_dict}{$instName}) {
      $self->synerror_at($node->[NODE_LNO],
                         "Duplicate use of argmacro '%s'", $instName);
    }
    $part->{_argmacro_instance_dict}{$instName} = $instance;
    push @{$part->{_argmacro_instance_list}}, $instName;
    foreach my $actualName (keys %$outputs) {
      $part->{_argmacro_output_dict}{$actualName}
        = [$instName, $outputs->{$actualName}];
    }
    foreach my $actualName (keys %$triggers) {
      $part->{_argmacro_trigger_dict}{$actualName}
        = [$instName, $triggers->{$actualName}];
    }

    $parser->add_args($part, @{$instance->{output_args}});

    return $part; # debugging aid
  };
}

#
# argmacro を rename ($toName, $fromName) して instance を作る。
# 戻り値: ($instName, $instance, \%triggers, \%outputs)
#   %triggers: 実引数名 => formal 入力名
#   %outputs:  実出力名 => formal 出力名
# instance の output_args の NODE_PATH は実名に付け替える。
#
sub instantiate {
  (my $class, my ArgMacro $argmacro, my ($toName, $fromName)) = @_;

  my $instName = join(":", $argmacro->{namespace}, $argmacro->{name}
                      , ($toName ? $toName : ()));
  my ArgMacro $instance = $argmacro->clone_with_renamespec($toName, $fromName);

  my (%triggers, %outputs);
  foreach my $outArg (@{$instance->{output_args}}) {
    my $formalName = $outArg->[NODE_PATH];
    my $actualName = _apply_rename($formalName, $toName, $fromName);
    $instance->{rename_map}{$formalName} = $actualName;
    $instance->{resolve_map}{$actualName} = $formalName;
    $outputs{$actualName} = $formalName;
    $outArg->[NODE_PATH] = $actualName;
  }
  foreach my $argName (@{$argmacro->{_arg_order}}) {
    $triggers{_apply_rename($argName, $toName, $fromName)} = $argName;
  }

  ($instName, $instance, \%triggers, \%outputs);
}

sub _apply_rename {
  my ($argName, $toName, $fromName) = @_;
  if (not $toName) {
    $argName
  } elsif (defined $fromName and $argName eq $fromName) {
    $toName
  } else {
    $toName.'_'.$argName;
  }
}

sub generate_on_expand {
  (my MY $self, my ArgMacro $argmacro) = @_;

  my Template $tmpl = $self->{_curtmpl};

  my $cgenType = ref $self;
  my $macroType = ArgMacro;
  my $argsType = "$tmpl->{entns}::args_$argmacro->{name}";
  my $varsType = "$tmpl->{entns}::vars_$argmacro->{name}";
  my $resultType = "$tmpl->{entns}::result_$argmacro->{name}";

  my @output_names = map {
    $_->[NODE_PATH];
  } @{$argmacro->{output_args}};

  require YATT::Lite::ArgMacro;
  YATT::Lite::ArgMacro->define_record_class($resultType, @output_names);
  YATT::Lite::ArgMacro->define_record_class(
    $_, @{$argmacro->{_arg_order} // []}
  ) for $argsType, $varsType;

  my @script;
  push @script, q(use YATT::Lite::Constants; );
  push @script, sprintf(
    q{(my %s $cgen, my %s $args, my %s $vars, my %s $argmacro, my $node) = @_; my %s $result = +{};},
    $cgenType, $argsType, $varsType, $macroType, $resultType
  );

  push @script, @{$argmacro->{_toks}};
  push @script, q(return $result);

  my $script = sprintf(q{use strict; use warnings; sub {%s}}, join "", @script);

  if ($ENV{DEBUG}) {
    print $script, "\n";
  }

  $script;
}

1;
