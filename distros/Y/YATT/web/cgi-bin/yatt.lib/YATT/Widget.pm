# -*- mode: perl; coding: utf-8 -*-
package YATT::Widget;
use strict;
use warnings qw(FATAL all NONFATAL misc);

BEGIN {require Exporter; *import = \&Exporter::import}

use base qw(YATT::Class::Configurable);
use YATT::Fields qw(^=arg_dict
		    ^=arg_order
		    ^=virtual_var_dict
		    ^=argmacro_dict
		    ^=argmacro_order
		    ^cf_root
		    ^cf_name
		    ^cf_filename
		    ^cf_declared
		    ^cf_public
		    cf_decl_start
		    cf_body_start
		    ^cf_template_nsid
		    ^cf_no_last_newline
		  );

use YATT::Types qw(:export_alias)
  , -alias => [Cursor => 'YATT::LRXML::NodeCursor'
	       , Widget => __PACKAGE__];
use YATT::LRXML::Node qw(create_node);
use YATT::Util qw(add_arg_order_in call_type);

use Carp;

sub after_configure {
  my MY $widget = shift;
  $widget->{cf_root} ||= $widget->create_node('root');
}

sub cursor {
  my Widget $widget = shift;
  $widget->call_type(Cursor => new_opened => $widget->{cf_root}, @_);
}

sub add_arg {
  (my Widget $widget, my ($name, $arg)) = @_;
  add_arg_order_in($widget->{arg_dict}, $widget->{arg_order}, $name, $arg);
  $widget;
}

sub has_arg {
  (my Widget $widget, my ($name)) = @_;
  defined $widget->{arg_dict}{$name};
}

sub has_virtual_var {
  (my Widget $widget, my ($name)) = @_;
  $widget->{virtual_var_dict}{$name}
}

sub add_virtual_var {
  (my Widget $widget, my ($name, $var)) = @_;
  $widget->{virtual_var_dict}{$name} = $var;
}

sub widget_scope {
  (my Widget $widget, my ($outer)) = @_;
  my $args = $widget->{arg_dict} ||= {};
  if ($widget->{virtual_var_dict} and keys %{$widget->{virtual_var_dict}}) {
    [$args, [$widget->{virtual_var_dict}, $outer]];
  } else {
    [$args, $outer];
  }
}

sub copy_specs_from {
  (my Widget $this, my Widget $from) = @_;
  my @names;
  {
    my ($dict, $order) = $from->arg_specs;
    foreach my $name (@$order) {
      unless ($this->has_arg($name)) {
	$this->add_arg($name, $dict->{$name}->clone);
      }
      push @names, $name;
    }
  }
  {
    # XXX: 深く考え切れてない。
    # order には Spec object が入っている。
    # dict  には Slot object が入っている
    my ($dst_dict, $dst_order) = $this->macro_specs;
    my ($src_dict, $src_order) = $from->macro_specs;
    push @$dst_order, @$src_order;
    foreach my $trigger (keys %$src_dict) {
      $dst_dict->{$trigger} ||= $src_dict->{$trigger};
    }
  }
  @names;
}

sub arg_specs {
  (my Widget $widget) = @_;
  my @list = ($widget->{arg_dict} ||= {}
	      , $widget->{arg_order} ||= []);
  wantarray ? @list : \@list;
}

sub get_arg_spec {
  (my Widget $widget, my ($name, $default)) = @_;
  my $dict = $widget->{arg_dict}
    or return $default;
  defined (my $spec = $dict->{$name})
    or return $default;
  return $default unless exists $spec->{arg_dict};
  $spec->{arg_dict};
}

sub macro_specs {
  (my Widget $widget) = @_;
  my @list = ($widget->{argmacro_dict} ||= {}
	      , $widget->{argmacro_order} ||= []);
  wantarray ? @list : \@list;
}

sub reorder_params {
  (my Widget $widget, my ($params)) = @_;
  my @params;
  foreach my $name (map($_ ? @$_ : (), $widget->{arg_order})) {
    push @params, delete $params->{$name};
  }
  if (keys %$params) {
    die "Unknown args for $widget->{cf_name}: " . join(", ", keys %$params);
  }
  wantarray ? @params : \@params;
}

sub reorder_cgi_params {
  (my Widget $widget, my ($cgi, $list)) = @_;
  $list ||= [];
  foreach my $name ($cgi->param) {
    my $argdecl = $widget->{arg_dict}{$name}
      or die "Unknown args for widget '$widget->{cf_name}': $name";
    my @value = $cgi->multi_param($name);
    $list->[$argdecl->argno] = $argdecl->type_name eq 'list'
      ? \@value : $value[0];
  }
  $list;
}

1;
