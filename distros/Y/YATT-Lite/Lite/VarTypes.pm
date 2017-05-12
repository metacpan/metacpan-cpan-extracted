package YATT::Lite::VarTypes; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Exporter qw(import);

sub Base () {'YATT::Lite::VarTypes::Base'}
use YATT::Lite::Util qw(globref define_const);
require Scalar::Util;
our @EXPORT_OK;
our %EXPORT_TAGS;

sub add_slot_to {
  my ($pkg, $name, $i) = @_;
  *{globref($pkg, $name)} = sub {
    my $self = shift;
    if (@_) { $self->[$i] = shift; $self; } else { $self->[$i] }
  };
  my $constName = 'VSLOT_'.uc($name);
  my $sub = define_const(globref($pkg, $constName), $i);
  ($constName => $sub);
}

BEGIN {
  our @fields = qw(type
		   varname argno
		   lineno quote dflag default);
  my $slotNum = 0;
  foreach my $name (@fields) {
    # accessor
    my ($constName, $sub) = add_slot_to(Base, $name, $slotNum);
    # constant
    push @EXPORT_OK, $constName;
    push @{$EXPORT_TAGS{VSLOT}}, $constName;
    *{globref(MY, $constName)} = $sub;
  } continue {
    $slotNum++;
  }
  # our @EXPORT = our @EXPORT_OK;
}

{
  # new(\@type
  #    , $varname, $argno
  #    , $quote, $dflag, $default, widget)
  sub YATT::Lite::VarTypes::Base::new {
    my $pack = shift;
    bless [@_], $pack;
  }
  sub YATT::Lite::VarTypes::Base::is_required {
    my $dflag = shift->[VSLOT_DFLAG];
    return 1 if defined $dflag and $dflag eq '!';
  }

  sub YATT::Lite::VarTypes::Base::flag { undef }
  sub YATT::Lite::VarTypes::Base::callable { 0 }
  sub YATT::Lite::VarTypes::Base::already_escaped { 0 }
  sub YATT::Lite::VarTypes::Base::is_type {
    my $type = shift->[VSLOT_TYPE];
    my $want = shift;
    $type->[0] eq $want;
  }
}

BEGIN {
  # export する理由は無い?
  our @types = (qw(text list scalar)
		, [attr => {callable => 1}]
		, [bool => {flag => 1}]
		, [html => {already_escaped => 1}]
		, [code => {callable => 1}, qw(widget)]
		, [delegate => {callable => 1}, qw(widget delegate_vars)]);
  foreach my $spec (@types) {
    my ($type, $consts, @slots) = ref $spec ? @$spec : $spec;
    my $shortName = "t_$type";
    my $fullName = join '::', MY, $shortName;
    *{globref($fullName, 'ISA')} = [Base];
    define_const(globref(MY, $shortName), $fullName);
    push @EXPORT_OK, $shortName;
    push @{$EXPORT_TAGS{type}}, $shortName;
    if ($consts) {
      foreach my $key (keys %$consts) {
	my $val = $consts->{$key};
	my $glob = *{globref($fullName, $key)};
	if (ref $val eq 'CODE') {
	  *glob = $val
	} else {
	  define_const($glob, $val);
	}
      }
    }
    if (@slots) {
      my $i = our @fields;
      foreach my $name (@slots) {
	add_slot_to($fullName, $name, $i);
      } continue { $i++ }
    }
  }
}

# widget だけ lvalue sub にするのも、一つの手ではないか?
{
  package YATT::Lite::VarTypes::t_delegate;
  sub weakened_set_widget {
    my $self = shift;
    $self->[VSLOT_WIDGET] = shift;
    Scalar::Util::weaken($self->[VSLOT_WIDGET])
	if $self->[VSLOT_WIDGET]->{cf_folder};
    $self;
  }
}

1;
