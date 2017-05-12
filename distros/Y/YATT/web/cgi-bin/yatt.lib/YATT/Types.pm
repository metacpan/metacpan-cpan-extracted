# -*- mode: perl; coding: utf-8 -*-
package YATT::Types;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Util::Symbol;
use YATT::Util qw(terse_dump);
require YATT::Inc;

sub Base () { 'YATT::Class::Configurable' }
use base Base;
use YATT::Fields qw(
		    classes
		    aliases
		    default_methods
		    cf_rules
		  )
  , [cf_base => Base]
  , qw(cf_callpack
       cf_export_alias
       cf_type_name
       cf_debug
     );

#========================================

sub import {
  my $pack = shift;
  my ($callpack) = caller;
  my %rules = (struct => [], inheritance => []);
  $pack->parse_args(\@_, \my @conf, \%rules, 'struct');
  # use Data::Dumper; print Dumper(\%rules), "\n";
  $pack->new(callpack => $callpack, @conf, rules => \%rules)
    ->export;
}

# XXX: 交互でも行けるようになったはず。テストを。
# XXX: -constant も欲しい ← @EXPORT に入れない。
# XXX: \inheritance も。

sub parse_args {
  my ($pack, $arglist, $conflist, $taskqueue, $default_task) = @_;
  while (@$arglist) {
    if (ref $arglist->[0]) {
      my ($task_name, $task_arg) = do {
	if (ref $arglist->[0] eq 'ARRAY') {
	  ($default_task, shift @$arglist);
	} elsif (ref $arglist->[0] eq 'SCALAR') {
	  (${shift @$arglist}, shift @$arglist);
	} else {
	  croak "Invalid option '$arglist->[0]'";
	}
      };
      unless (defined $taskqueue->{$task_name}) {
	croak "Invalid task: $task_name";
      }
      push @{$taskqueue->{$task_name}}, $task_arg;
    } elsif (my ($flag, $key) = $arglist->[0] =~ /^([\-:])(\w+)/) {
      shift @$arglist;
      my $value = $flag eq ':' ? 1 : shift @$arglist;
      push @$conflist, $key, $value;
    } else {
      croak "Invalid option '$arglist->[0]'";
    }
  }
}

sub export {
  my MY $opts = shift;
  my $script = $opts->make;
  print STDERR $script if $opts->{cf_debug};
  eval $script;
  die $@ if $@;
}

#----------------------------------------

sub configure_base {
  (my MY $opts, my ($value)) = @_;
  if (ref $value) {
    push @{$$opts{aliases}}, $value;
    $opts->{cf_base} = $value->[1];
  } else {
    $opts->{cf_base} = $value;
  }
  $opts;
}

sub configure_alias {
  (my MY $opts, my ($value)) = @_;
  push @{$opts->{aliases}}, chunklist($value);
  $opts;
}

sub configure_default {
  (my MY $opts, my ($value)) = @_;
  push @{$opts->{default_methods}}, chunklist($value);
  $opts;
}

#========================================

sub make {
  my MY $opts = shift;
  my $script;
  # 順番が有る。
  foreach my $rule (qw(struct inheritance)) {
    next unless my $descs = $opts->{cf_rules}{$rule};
    next unless @$descs;
    $script .= $opts->can("make_$rule")->($opts, @$descs);
  }
  $script .= $opts->make_class_aliases;
  $script .= $opts->make_default_methods;
  $script;
}

sub make_struct {
  my MY $opts = shift;
  my @result;
  foreach my $desc (@_) {
    push @result, $opts->make_class_nesting
      ($desc, $$opts{cf_callpack} . '::'
       , $$opts{cf_base} || $opts->Base);
  }
  join "", @result;
}

sub list_aliases {
  my MY $opts = shift;
  map {$$_[0]} @{$$opts{classes}}, @{$$opts{aliases}};
}

sub make_class_aliases {
  my MY $opts = shift;
  my $aliases = join "\n ", $opts->list_aliases;
  my $script = <<END;
package $$opts{cf_callpack};
push our \@EXPORT_OK, qw($aliases);
END

  $script .= <<END if $$opts{cf_export_alias};
push our \@EXPORT, qw($aliases);
END

  my $stash = *{globref($$opts{cf_callpack}, '')}{HASH};
  print STDERR "# [$$opts{cf_callpack} has] "
    , join(" ", sort keys %$stash), "\n"
      if $opts->{cf_debug};
  foreach my $classdef (@{$$opts{classes}}, @{$$opts{aliases}}) {
    # Ignore if alias is already defined.
    my $entry = $stash->{$classdef->[0]};
    next if defined $entry and $entry->{CODE};

    $script .= qq{sub $classdef->[0] () {'$classdef->[1]'}\n};
  }

  $script;
}

sub make_class_nesting {
  (my MY $opts, my ($desc, $prefix, $super)) = @_;
  my ($class, $slots) = splice @$desc, 0, 2;
  push @{$$opts{classes}}, [$class, $prefix.$class];
  my $script = $opts->make_class($prefix.$class, $super
				 , terse_dump(@$slots
					      , map {ref $_ ? $$_[0] : $_}
					      @$desc));

  $script .= <<END if $opts->{cf_type_name};
sub $prefix${class}::type_name () {'$class'}
END

  foreach my $child (@$desc) {
    next unless ref $child;
    $script .= $opts->make_class_nesting($child, $prefix, $super);
  }
  $script;
}

sub make_class {
  my ($self, $class, $super, $slots) = @_;
  YATT::Inc->add_inc($class);
  <<END . ($super ? <<END : "") . ($slots ? <<END : "") . "\n";
package $class;
END
use base qw($super);
END
use YATT::Fields $slots;
END
}

sub make_default_methods {
  my MY $opts = shift;
  join "", map {<<END} @{$$opts{default_methods}};
sub default_$$_[0] {'$$_[1]'}
END

}

#----------------------------------------

sub chunklist {
  my ($arg) = @_;
  my @list;
  if (ref $arg eq 'ARRAY') {
    push @list, [splice @$arg, 0, 2] while @$arg;
  } elsif (ref $arg eq 'HASH') {
    while (my ($k, $v) = each %$arg) {
      push @list, [$k, $v];
    }
  } else {
    croak "Invalid arg for -alias";
  }
  wantarray ? @list : \@list;
}

1;
