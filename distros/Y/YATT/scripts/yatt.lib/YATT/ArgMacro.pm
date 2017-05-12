# -*- mode: perl; coding: utf-8 -*-
package YATT::ArgMacro; use YATT::Inc;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::Configurable);
use Carp;

use YATT::Util qw(checked_eval);
use YATT::Util::Symbol qw(globref fields_hash_of_class define_const);
use YATT::LRXML::Node qw(copy_array copy_node_renamed_as
			 create_node_from node_name node_size);

use YATT::Fields 'spec', [disabled => 0];

sub initargs { qw(spec) }

use YATT::Types
  [Spec => [qw(cf_name cf_classname
	       cf_base
	       cf_in
	       cf_out
	       cf_edit
	       cf_rename_spec
	       cf_disabled
	       trigger
	       output
	       output_map
	       prototype
	     )]]
  , [Slot => [qw(cf_name cf_classname cf_call_spec
		 cf_spec cf_mode cf_type cf_doc)]]
  ;

#========================================

sub handle {
  my ($macro, $trans, $scope, $node, $widget) = @_;
  $macro->accept($trans, $scope, $node, $widget);
  $node;
}

sub expand_all_macros {
  my ($pack, $trans, $scope, $node, $widget, $trigger, $order) = @_;
  my $copy = $node->variant_builder;
  $copy->add_filtered_copy($node->clone, [\&filter, $trigger, \ my %found]);
  if (%found) {
    foreach my Spec $spec (@$order) {
      my MY $macro = $found{$spec->refid} or next;
      # XXX: disabled だけれど、他にも config がある場合は、エラーにすべき。
      if ($macro->{disabled}) {
	$spec->revert_into($copy, $macro);
	next;
      }
      $copy = $macro->handle($trans, $scope, $copy, $widget);
    }
    $copy;
  } else {
    $node;
  }
}

sub filter {
  my ($trigger, $unique, $name, $value) = @_;
  if (my Slot $slot = $trigger->{$name}) {
    # ここで、rename が関係する
    my MY $macro = $unique->{$slot->{cf_spec}->refid}
      ||= $slot->{cf_classname}->new($slot->{cf_spec});
    if ($macro->{disabled} or my $out = $slot->is_output) {
      # 出力引数が明示的に与えられていた場合は、disabled モードにする。
      $macro->{disabled} = 1;
      # 元の引数を残す
      # rename 済みの override を返す。
      unless ($out) {
	copy_array($value);
      } elsif (node_size($value)) {
	# label_list=lh ===> label=lh
	MY->copy_node_renamed_as($macro->output_name, $value);
      } else {
	# header_list   ===> header=header_list
	MY->create_node_from($value
			     , $macro->output_name
			     , node_name($value));
      }
    } else {
      # text になってないと、不便では?
      # ← でも、<:att>....</:att> の場合も有る。
      $macro->configure($slot->{cf_name} => copy_array($value));
      ();
    }
  } else {
    copy_array($value);
  }
}

#========================================

#
# use YATT::ArgMacro AM => out => ['name=type'], in => [qw(x y z ...)];
#  => creates new class AM.
#
sub import {
  my ($pack, $macro_name) = splice @_, 0, 2;
  my ($callpack) = caller;
  my $class_name = "${callpack}::$macro_name";
  my Spec $spec = Spec->new(name => $macro_name, classname => $class_name
			    , @_);

  my $base = $spec->{cf_base} || __PACKAGE__;
  my @fields = $spec->fields;

  my $script = <<END;
package $class_name;
use strict;
use base qw($base);
use YATT::Fields qw(@fields);

sub $class_name () {'$class_name'}
END

  # print STDERR $script;
  $pack->checked_eval($script);

  define_const(globref($class_name, 'macro_spec'), $spec);
}

#
# Instanciate and register ArgMacro Spec in given widget's argument list.
#

sub register_in {
  my ($pack, $registry, $node, $widget, $rename_spec) = @_;
  my Spec $spec = $pack->macro_spec
    ->clone_with_renaming($rename_spec, $registry, $node);

  my ($dict, $order) = $widget->macro_specs;
  push @$order, $spec;

  foreach my Slot $slot ($spec->{output} ? $spec->{output}
			 : @{$spec->{cf_out}}) {
    $widget->add_arg($slot->{cf_name} => $registry->create_var
		     ($slot->{cf_type}, undef, varname => $slot->{cf_name}));
  }

  foreach my $name (keys %{$spec->{trigger}}) {
    my Slot $slot = $spec->{trigger}{$name};
    if (my Slot $old = $dict->{$name}) {
      die $registry->node_error
	($node, "ArgMacro %s conflicts with %s for %s"
	 , $spec->call_spec(1)
	 , $old->{cf_call_spec}, $name);
    }
    $dict->{$name} = $slot;
  }
}

#
# Directly instanciate ArgMacro spec.
#

sub create_from {
  my ($pack, $trans, $scope, $orig, $rename_spec) = @_;
  my Spec $spec = $pack->macro_spec
    ->clone_with_renaming($rename_spec, $trans, $orig);

  my $copy = $orig->variant_builder;
  my ($name, $slot, @config);
  for (my $n = $orig->clone; $n->readable; $n->next) {
    unless ($n->is_attribute and $name = $n->node_name
	    and $slot = $spec->{trigger}{$name}
	    and not $slot->is_output) {
      $copy->add_node(copy_array($n->current));
      next;
    }
    push @config, $slot->{cf_name} => $n->current;
  }
  if (@config) {
    my $macro = $pack->new($spec, @config);
    $macro->accept($trans, $scope, $copy); # To avoid return value confusion.
    ($macro, $copy)
  } else {
    (undef, $orig->rewind);
  }
}

#========================================

foreach my $mode (qw(in out edit)) {
  Spec->define("configure_$mode", sub {
		 spec_configure_slot(shift, "cf_$mode", $mode, @_);
	       });
}

# 分かった、これが use YATT::ArgMacro と clone の両方の configure
# から呼ばれる。一方では生の list, 他方では Spec の list だ。
sub spec_configure_slot {
  (my Spec $spec, my ($name, $mode, $list)) = @_;
  $spec->{$name} = [map {
    Slot->create($_, mode => $mode, classname => $spec->{cf_classname})
  } @$list];
  if ($mode eq 'out' && @{$spec->{$name}} == 1) {
    # Only if 1 output var exists.
    $spec->{output} = $spec->{$name}[0];
  }
}

Spec->define(fields => \&spec_fields);
sub spec_fields {
  my Spec $spec = shift;
  if ($spec->{cf_base}) {
    croak "ArgMacro base= is not yet implemented";
  }
  my @fields;
  foreach my $list ($spec->{cf_in}, $spec->{cf_edit}) {
    foreach my Slot $slot (@$list) {
      push @fields, 'cf_' . $slot->{cf_name};
    }
  }
  foreach my Slot $slot (@{$spec->{cf_out}}) {
    push @fields, 'out_' . $slot->{cf_name};
  }
  @fields;
}

Spec->define(call_spec => \&spec_call_spec);
sub spec_call_spec {
  (my Spec $spec, my ($user)) = @_;
  my @args = grep {defined $_}
    map { ref $_ ? @$_ : $_ } $spec->{cf_rename_spec};
  '%'.join("", grep {defined $_}
       ($user ? $spec->{cf_name} : $spec->{cf_classname})
       , (@args ? ('('.join("=", @args).')') : ())).';';
}

Spec->define(clone_with_renaming => \&spec_clone_with_renaming);
sub spec_clone_with_renaming {
  (my Spec $orig, my ($rename, $registry, $node)) = @_;
  my Spec $new = $orig->clone(rename_spec => $rename);
  $new->{prototype} = $orig;
  $new->{trigger} = \ my %trigger;

  my ($prefix, $short_name, $from) = ('');
  if ($rename) {
    die $registry->node_error($node, "ArgMacro: No output is defined")
      unless $new->{cf_out} && @{$new->{cf_out}};
    die $registry->node_error($node, "ArgMacro: Can't rename multiple output")
      if @{$new->{cf_out}} > 1;

    ($short_name, $from) = ref $rename ? @$rename : $rename;
    $prefix = $short_name . '_';

    my Slot $orig = $new->{cf_out}[0];
    $new->{output} = $orig->clone(name => $short_name);
    $new->{output_map}{$orig->{cf_name}} = $short_name;
  }

  my $call_spec = $new->call_spec(1);
  foreach my $list (grep {defined $_}
		    $new->{cf_in}, $new->{cf_edit}, $new->{cf_out}) {
    foreach my Slot $slot (@$list) {
      $trigger{$prefix . $slot->{cf_name}}
	= $slot->clone(spec => $new, call_spec => $call_spec);
    }
  }

  if ($from) {
    unless (my Slot $major = $trigger{$prefix . $from}) {
      die $registry->node_error($node, "Unknown parameter: %s", $from);
    } else {
      $trigger{$short_name} = $major;
    }
  }
  $new;
}

Spec->define(revert_into => \&spec_revert_into);
sub spec_revert_into {
  (my Spec $spec, my $node, my MY $macro) = @_;
  foreach my Slot $slot (map {ref $_ ? @$_ : ()} $spec->{cf_edit}) {
    my $name = "cf_$slot->{cf_name}";
    defined(my $expr = $macro->{$name})
      or next;
    $node->add_node($expr);
  }
}

sub output_name {
  (my MY $macro) = @_;
  my Spec $spec = $macro->{spec};
  my Slot $out = $spec->{output};
  $out->{cf_name};
}

#========================================
Slot->define(create => \&slot_create);
sub slot_create {
  my ($pack, $item, @rest) = @_;
  my ($name, @args) = do {
    unless (ref $item) {
      my ($n, $t) = split /=/, $item, 2;
      ($n, type => $t);
    } elsif (UNIVERSAL::isa($item, Slot)) {
      return $item->clone;
    } else {
      @$item
    }
  };
  $pack->new(name => $name, @args, @rest);
}

Slot->define(is_output => \&slot_is_output);
sub slot_is_output {
  my Slot $slot = shift;
  $slot->{cf_mode} eq 'out';
}

1;
