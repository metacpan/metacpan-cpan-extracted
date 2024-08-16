package YATT::Lite::Partial::MarkAfterNew;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';
use YATT::Lite::MFields qw/__after_new_is_called__/;
sub MY () {__PACKAGE__}
use YATT::Lite::Util qw/globref/;

use constant DEBUG => $ENV{DEBUG_YATT_IMPORT} // 0;

#========================================

sub after_new {
  (my MY $self) = @_;
  $self->{__after_new_is_called__} = 1;
  &maybe::next::method;
}

sub after_new_is_called {
  (my MY $self) = @_;
  $self->{__after_new_is_called__};
}

#========================================
# XXX: use YATT::Lite::Util::AsBase qw/-as_base import/; was not ok...

sub import {
  my ($pack, @args) = @_;
  return unless @args;
  if (@args == 1 and $args[0] and $args[0] =~ /^-(\w+)/
        and my $sub = $pack->can("declare_$1")) {
    my $callpack = caller;
    $sub->($pack, $callpack);
  } else {
    Carp::croak("Invalid use spec: ", @args);
  }
}

sub declare_as_base {
  my ($myPack, $callpack) = @_;
  print STDERR "$myPack->declare_as_base($callpack)\n" if DEBUG;

  {
    my $sym = globref($callpack, 'ISA');
    my $isa;
    unless ($isa = *{$sym}{ARRAY}) {
      *$sym = $isa = [];
    }
    mro::set_mro($callpack, 'c3');
    unless (grep {$_ eq $myPack} @$isa) {
      unshift @$isa, $myPack;
      print STDERR " => $callpack isa: @$isa\n" if DEBUG;
    }
  }
}

1;
