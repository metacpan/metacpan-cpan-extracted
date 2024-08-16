package YATT::Lite::VarMaker; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Lite::Object);
use YATT::Lite::MFields qw/type_alias
	      curline/;

use YATT::Lite::VarTypes qw(:type :VSLOT);
use YATT::Lite::Util qw(lexpand default);

# XXX: Should integrated to VarTypes.
sub default_arg_type {'text'}
sub default_type_alias {
  qw(value scalar
     flag    bool
     boolean bool
     expr code);
}

sub after_new {
  my MY $self = shift;
  $self->SUPER::after_new;
  $self->{type_alias} = { $self->default_type_alias };
  $self;
}

# Note: To use mkvar_at(), derived class must implement
# _error() and _tmpl_file_line().
# Currently, YATT::Lite::LRXML and YATT::Lite::CGen uses this.
sub mkvar_at {
  (my MY $self, my ($lineno, $type, $name, @args)) = @_;

  my ($typerec, $sub) = $self->_mk_typerec($type, $lineno, $name);

  my $var = $sub->()->new($typerec, $name, @args);
  $var->[VSLOT_LINENO] //= $lineno //= $self->{curline};
  $var;
}

sub set_var_type {
  (my MY $self, my ($var, $type)) = @_;
  $var->type(scalar $self->_mk_typerec($type));
}

sub _mk_typerec {
  (my MY $self, my ($type, $lineno, $name)) = @_;

  ($type, my @subtype) = ref $type ? lexpand($type) : split /:/, $type || '';
  #
  $type ||= $self->default_arg_type;
  $type = default($self->{type_alias}{$type}, $type);

  my $typerec = [$type, @subtype];

  wantarray ? ($typerec, do {
    my $sub = $self->can("t_$type") or do {
      my %opts = ($self->_tmpl_file_line($lineno));
      die $self->_error(\%opts, q|Unknown type '%s' for variable '%s'|
                        , $type, $name);
    };
  }) : $typerec;
}

sub parse_type_dflag_default {
  split m{([|/?!])}, $_[1] || '', 2;
}

sub set_dflag_default_to {
  (my MY $self, my ($var, $dflag, $default)) = @_;
  if (not $dflag) {
    ($dflag, $default) = $var->default_dflag_default;
  }
  $var->[VSLOT_DFLAG] = $dflag if $dflag;
  if (defined $default) {
    $var->[VSLOT_DEFAULT] = $self->_parse_text_entities($default);
  }
}

1;
