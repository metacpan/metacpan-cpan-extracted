package X86::Udis86::Operand;

use 5.008000;
use strict;
use warnings;
use Carp;

use Devel::Peek;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use X86::Udis86 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
$udis_types
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '1.7.2.3';

our $udis_types = [ qw(
  UD_NONE
  UD_R_AL
  UD_R_CL
  UD_R_DL
  UD_R_BL
  UD_R_AH
  UD_R_CH
  UD_R_DH
  UD_R_BH
  UD_R_SPL
  UD_R_BPL
  UD_R_SIL
  UD_R_DIL
  UD_R_R8B
  UD_R_R9B
  UD_R_R10B
  UD_R_R11B
  UD_R_R12B
  UD_R_R13B
  UD_R_R14B
  UD_R_R15B
  UD_R_AX
  UD_R_CX
  UD_R_DX
  UD_R_BX
  UD_R_SP
  UD_R_BP
  UD_R_SI
  UD_R_DI
  UD_R_R8W
  UD_R_R9W
  UD_R_R10W
  UD_R_R11W
  UD_R_R12W
  UD_R_R13W
  UD_R_R14W
  UD_R_R15W
  UD_R_EAX
  UD_R_ECX
  UD_R_EDX
  UD_R_EBX
  UD_R_ESP
  UD_R_EBP
  UD_R_ESI
  UD_R_EDI
  UD_R_R8D
  UD_R_R9D
  UD_R_R10D
  UD_R_R11D
  UD_R_R12D
  UD_R_R13D
  UD_R_R14D
  UD_R_R15D
  UD_R_RAX
  UD_R_RCX
  UD_R_RDX
  UD_R_RBX
  UD_R_RSP
  UD_R_RBP
  UD_R_RSI
  UD_R_RDI
  UD_R_R8
  UD_R_R9
  UD_R_R10
  UD_R_R11
  UD_R_R12
  UD_R_R13
  UD_R_R14
  UD_R_R15
  UD_R_ES
  UD_R_CS
  UD_R_SS
  UD_R_DS
  UD_R_FS
  UD_R_GS
  UD_R_CR0
  UD_R_CR1
  UD_R_CR2
  UD_R_CR3
  UD_R_CR4
  UD_R_CR5
  UD_R_CR6
  UD_R_CR7
  UD_R_CR8
  UD_R_CR9
  UD_R_CR10
  UD_R_CR11
  UD_R_CR12
  UD_R_CR13
  UD_R_CR14
  UD_R_CR15
  UD_R_DR0
  UD_R_DR1
  UD_R_DR2
  UD_R_DR3
  UD_R_DR4
  UD_R_DR5
  UD_R_DR6
  UD_R_DR7
  UD_R_DR8
  UD_R_DR9
  UD_R_DR10
  UD_R_DR11
  UD_R_DR12
  UD_R_DR13
  UD_R_DR14
  UD_R_DR15
  UD_R_MM0
  UD_R_MM1
  UD_R_MM2
  UD_R_MM3
  UD_R_MM4
  UD_R_MM5
  UD_R_MM6
  UD_R_MM7
  UD_R_ST0
  UD_R_ST1
  UD_R_ST2
  UD_R_ST3
  UD_R_ST4
  UD_R_ST5
  UD_R_ST6
  UD_R_ST7
  UD_R_XMM0
  UD_R_XMM1
  UD_R_XMM2
  UD_R_XMM3
  UD_R_XMM4
  UD_R_XMM5
  UD_R_XMM6
  UD_R_XMM7
  UD_R_XMM8
  UD_R_XMM9
  UD_R_XMM10
  UD_R_XMM11
  UD_R_XMM12
  UD_R_XMM13
  UD_R_XMM14
  UD_R_XMM15
  UD_R_RIP
  UD_OP_REG
  UD_OP_MEM
  UD_OP_PTR
  UD_OP_IMM
  UD_OP_JIMM
  UD_OP_CONST
) ];

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&X86::Udis86::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

# Preloaded methods go here.

sub dump {
  my $self = shift;
  use Data::Dumper;
  
  print "OP is ",Data::Dumper->Dump([$self]),"\n";
}

sub type_as_string {
  my $self = shift;
  return $udis_types->[$self->type];
}

sub base_as_string {
  my $self = shift;
  return $udis_types->[$self->base];
}

sub index_as_string {
  my $self = shift;
  return $udis_types->[$self->index];
}

sub info {
  my $self = shift;
  my $index = shift;

  print "Op $index type is ",$self->type_as_string,"\n";
  print "Op $index size is ",$self->size,"\n";
  if ($self->type_as_string eq "UD_OP_REG") {
    print "Op $index base is ",$self->base_as_string,"\n";
  }
  if ($self->type_as_string eq "UD_OP_MEM") {
    print "Op $index base is ",$self->base_as_string,"\n";
    if ($self->index_as_string ne "UD_NONE") {
      print "Op $index index is ",$self->index_as_string,"\n";
    }
    if ($self->scale) {
      print "Op $index scale is ",$self->scale,"\n";
    }
    if ($self->offset) {
      print "Op $index offset is ",$self->offset,"\n";
    }
    $self->lval_info;
  }
  if ($self->type_as_string eq "UD_OP_PTR") {
  }
  if (($self->type_as_string eq "UD_OP_IMM") 
   or ($self->type_as_string eq "UD_OP_JIMM") 
   or ($self->type_as_string eq "UD_OP_CONST")) {
     $self->lval_info;
  }
}

sub lval_info {
  my $self = shift;

#  print "Op sbyte : raw is ",$self->lval_sbyte, " and ord is ",ord($self->lval_sbyte), " or hex ord is ",sprintf("%#x", ord($self->lval_sbyte)),"\n";
  print "Op sbyte : ",sprintf("%#x", ord($self->lval_sbyte)),"\n";
  print "Op ubyte is ",$self->lval_ubyte,"\n";
  print "Op sword is ",$self->lval_sword,"\n";
  print "Op uword is ",$self->lval_uword,"\n";
  print "Op sdword is ",$self->lval_sdword,"\n";
  print "Op udword is ",$self->lval_udword,"\n";
  print "Op sqword is ",$self->lval_sqword,"\n";
  print "Op uqword is ",$self->lval_uqword,"\n";
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

X86::Udis86::Operand - Perl extension for Udis86 operands.

=head1 SYNOPSIS

  use X86::Udis86::Operand;

=head1 DESCRIPTION

This provides methods for accessing operands in Udis86.

=head2 EXPORT

None by default.

=head1 AUTHOR

Bob Wilkinson, E<lt>bob@fourtheye.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2013 by Bob Wilkinson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
