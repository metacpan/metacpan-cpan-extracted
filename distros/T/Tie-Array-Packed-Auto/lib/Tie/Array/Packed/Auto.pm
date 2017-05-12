package Tie::Array::Packed::Auto;

use strict;
use warnings;
use Carp;

our $VERSION = '0.03';

our $force_pure_perl_backend;

if ($force_pure_perl_backend or
    not eval { require Tie::Array::Packed }) {

    our @ISA = 'Tie::Array::Packed';

    require Tie::Array::PackedC;

    my @short = qw(c C F f d i I i! I! s! S! l! L! n N v V);

    my %map = ( Char => 'c',
                UnsignedChar => 'C',
                NV => 'F',
                Number => 'F',
                FloatNative => 'f',
                DoubleNative => 'd',
                Integer => 'i',
                UnsignedInteger => 'I',
                IntegerNative => 'i!',
                UnsignedIntegerNative => 'I!',
                ShortNative => 's!',
                UnsignedShortNative => 'S!',
                LongNative => 'l!',
                UnsignedLongNative => 'L!',
                UnsignedShortNet => 'n',
                UnsignedShortBE => 'n',
                UnsignedLongNet => 'N',
                UnsignedLongBE => 'N',
                UnsignedShortVax => 'v',
                UnsignedShortLE => 'v',
                UnsignedLongVax => 'V',
                UnsignedLongLE => 'V' );

    @map{@short} = @short;

    for my $name (keys %map) {
        my $type = $map{$name};

        no strict 'refs';
        @{"Tie::Array::Packed::${name}::ISA"} = __PACKAGE__;
        *{"Tie::Array::Packed::${name}::packer"} = sub { $type };
    }

}

my $next_id = 'TieArrayPackedAuto0000';
my %id;
my %class;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $class = ref $self || $self;
    $class{$class} and croak qq(Can't locate object method "$AUTOLOAD" via package "$class");
    $class{$class} = 1;
    my $packer = $self->packer;
    unless ($id{$packer}) {
        $next_id++;
        $id{$packer} = $next_id;
        Tie::Array::PackedC->import($id{$packer}, $packer);

        my $parent =  "Tie::Array::PackedC::$id{$packer}";
        no strict 'refs';
        *{$parent.'::_TieArrayPackedAuto_TIEARRAY'} = *{$parent.'::TIEARRAY'};
    }
    no strict 'refs';
    push @{$class.'::ISA'}, "Tie::Array::PackedC::$id{$packer}";
    $self->$AUTOLOAD(@_);
}

sub make {
    my $class = shift;
    tie my(@self), $class, '', @_;
    return \@self
}

sub make_with_packed {
    my $class = shift;
    tie my(@self), $class, @_;
    return \@self
}

sub TIEARRAY {
    # local $_[1] = $_[1];
    # shift->_TieArrayPackedAuto_TIEARRAY(@_);

    my $class = shift;
    my $str = shift;
    $class->_TieArrayPackedAuto_TIEARRAY($str, @_);
}

1;

__END__


=head1 NAME

Tie::Array::Packed::Auto - auto uses Tie::Array::Packed or Tie::Array::PackedC

=head1 SYNOPSIS

  use Tie::Array::Packed::Auto;
  tie @foo, Tie::Array::Packed::Integer;
  tie @bar, Tie::Array::Packed::DoubleNative;

  $foo[12] = 13;
  $bar[1] = 4.56;

  pop @foo;
  @some = splice @bar, 1, 3, @foo;

=head1 DESCRIPTION

This package loads L<Tie::Array::Packed> when it is available.

Otherwise, it loads L<Tie::Array::PackedC> and sets up some wrappers in
order to provide an API identical to that of L<Tie::Packed::Array>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2007 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
