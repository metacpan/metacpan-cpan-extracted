package YATT::Lite::CGen::ArgMacro;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

sub MY () {'YATT::Lite::CGen::ArgMacro'}

use base qw(YATT::Lite::CGen::Perl);
use YATT::Lite::MFields;

use YATT::Lite::Core qw(ArgMacro Part Template);
use YATT::Lite::Constants;

sub expand_all_argmacro {
  my ($class, $cgen, $primary, $triggers, $macroList, $macroDict) = @_;
  my (%found, @rest);
  foreach my $arg (@$primary) {
    my $argName = YATT::Lite::CGen::Perl::argName($arg);
    if (my $spec = $triggers->{$argName}) {
      my ($instName, $formalArgName) = @$spec;
      $found{$instName}{$formalArgName} = $arg;
    } else {
      push @rest, $arg;
    }
  }
  return $primary if not %found;

  [(map {
    if (my $args = $found{$_}) {

      $class->apply_argmacro($cgen, $macroDict->{$_}, $args);

    } else {
      ()
    }
  } @$macroList), @rest];
}

sub apply_argmacro {
  (my $class, my $cgen, my ArgMacro $argmacro, my $args) = @_;

  my $result = $argmacro->{on_expand}->($cgen, $args, $argmacro->{arg_dict}, $argmacro);
  return if not keys %$result;

  map {
    my $attName = $_->[NODE_PATH];
    my $node = [];
    $node->[NODE_TYPE] = TYPE_ATT_TEXT;
    $node->[NODE_PATH] = $attName;
    $node->[NODE_BODY] = $result->{$argmacro->{cf_resolve_map}{$attName}};
    $node;
  } @{$argmacro->{cf_output_args}}

}

sub generate_on_declare {
  (my MY $self, my ArgMacro $argmacro) = @_;

  my $script = $self->generate_on_expand($argmacro);
  my $code = YATT::Lite::Util::ckeval($script);
  $argmacro->{on_expand} = $code;

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

    my $instName = join(":", $argmacro->{cf_namespace}, $argmacro->{cf_name}
                        , ($toName ? $toName : ()));
    my ArgMacro $instance = $argmacro->clone_with_renamespec($toName, $fromName);
    foreach my $outArg (@{$instance->{cf_output_args}}) {
      my $formalName = $outArg->[NODE_PATH];
      if ($toName) {
        my $actualName = _apply_rename($formalName, $toName, $fromName);
        $instance->{cf_rename_map}{$formalName} = $actualName;
        $instance->{cf_resolve_map}{$actualName} = $formalName;
      } else {
        $instance->{cf_rename_map}{$formalName} = $formalName;
        $instance->{cf_resolve_map}{$formalName} = $formalName;
      }
    }

    if ($part->{argmacro_instance_dict}{$instName}) {
      $self->synerror_at($node->[NODE_LNO],
                         "Duplicate use of argmacro '%s'", $instName);
    }
    $part->{argmacro_instance_dict}{$instName} = $instance;
    push @{$part->{argmacro_instance_list}}, $instName;

    foreach my $argName (@{$argmacro->{arg_order}}) {
      my $actualName = _apply_rename($argName, $toName, $fromName);
      $part->{argmacro_trigger_dict}{$actualName} = [$instName, $argName];
    }

    $parser->add_args(
      $part,
      map {
        my $formalName = $_->[NODE_PATH];
        $_->[NODE_PATH] = $instance->{cf_rename_map}{$formalName};
        $_;
      } @{$instance->{cf_output_args}}
    );

    return $part; # debugging aid
  };
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

  my Template $tmpl = $self->{curtmpl};

  my $cgenType = ref $self;
  my $macroType = ArgMacro;
  my $argsType = "$tmpl->{cf_entns}::args_$argmacro->{cf_name}";
  my $varsType = "$tmpl->{cf_entns}::vars_$argmacro->{cf_name}";
  my $resultType = "$tmpl->{cf_entns}::result_$argmacro->{cf_name}";

  my @output_names = map {
    $_->[NODE_PATH];
  } @{$argmacro->{cf_output_args}};

  my @script;
  push @script, q(use YATT::Lite::Constants; );
  push @script, sprintf(
    qq{{package %s; use fields qw(%s)}},
    $resultType,
    join(" ", @output_names),
  );
  push @script, sprintf(
    qq{{package %s; use fields qw(%s)}},
    $argsType,
    join(" ", @{$argmacro->{arg_order} // []}),
  );
  push @script, sprintf(
    qq{{package %s; use fields qw(%s)}},
    $varsType,
    join(" ", @{$argmacro->{arg_order} // []}),
  );
  push @script, sprintf(
    q{(my %s $cgen, my %s $args, my %s $vars, my %s $argmacro) = @_; my %s $result = +{};},
    $cgenType, $argsType, $varsType, $macroType, $resultType
  );

  push @script, @{$argmacro->{toks}};
  push @script, q(return $result);

  my $script = sprintf(q{use strict; use warnings; sub {%s}}, join "", @script);

  if ($ENV{DEBUG}) {
    print $script, "\n";
  }

  $script;
}

1;
