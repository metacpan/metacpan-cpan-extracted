#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::Refcount;

use Tickit::Pen;

# Immutable pens
{
   my $pen = Tickit::Pen::Immutable->new( fg => 3 );

   isa_ok( $pen, "Tickit::Pen", '$pen isa Tickit::Pen' );

   is( "$pen", "Tickit::Pen::Immutable{fg=3}", '"$pen"' );

   is_deeply( { $pen->getattrs }, { fg => 3 }, '$pen attrs' );

   ok( $pen->hasattr( 'fg' ), '$pen has fg' );
   is( $pen->getattr( 'fg' ), 3, '$pen fg' );

   ok( !$pen->hasattr( 'bg' ), '$pen has no bg' );
   is( $pen->getattr( 'bg' ), undef, '$pen bg undef' );

   ok( $pen->equiv( $pen ), '$pen is equiv to itself' );
   ok( $pen->equiv( Tickit::Pen::Immutable->new( fg => 3 ) ), '$pen is equiv to another one the same' );

   my $pen2 = Tickit::Pen::Immutable->new( fg => 3, b => 1 );

   ok( $pen->equiv_attr( $pen2, 'fg' ), '$pen has equiv_attr fg another' );
   ok( !$pen->equiv( $pen2 ), '$pen is not equiv to a different one' );
}

# Mutable pens
{
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= join " ", @_ };

   my $pen = Tickit::Pen::Mutable->new;

   is( "$pen", "Tickit::Pen::Mutable{}", '"$pen" empty' );

   is_deeply( { $pen->getattrs }, {}, '$pen initial attrs' );
   ok( !$pen->hasattr( 'fg' ), '$pen initially lacks fg' );
   is( $pen->getattr( 'fg' ), undef, '$pen fg initially undef' );

   $pen->chattr( fg => 3 );

   is_deeply( { $pen->getattrs }, { fg => 3 }, '$pen attrs after chattr' );
   ok( $pen->hasattr( 'fg' ), '$pen now has fg' );
   is( $pen->getattr( 'fg' ), 3, '$pen fg after chattr' );

   is( "$pen", "Tickit::Pen::Mutable{fg=3}", '"$pen" after chattr' );

   is_deeply( { $pen->as_mutable->getattrs }, { $pen->getattrs }, '$pen->as_mutable attrs' );

   $pen->chattr( fg => "blue" );

   is_deeply( { $pen->getattrs }, { fg => 4 }, '$pen attrs fg named' );
   is( $pen->getattr( 'fg' ), 4, '$pen fg named' );

   $pen->chattr( fg => "hi-blue" );

   is_deeply( { $pen->getattrs }, { fg => 12 }, '$pen attrs fg named high-intensity' );
   is( $pen->getattr( 'fg' ), 12, '$pen fg named high-intensity' );

   $pen->delattr( 'fg' );

   is_deeply( { $pen->getattrs }, {}, '$pen attrs after delattr' );
   is( $pen->getattr( 'fg' ), undef, '$pen fg after delattr' );

   my %attrs = ( b => 1, na => 5 );

   $pen->chattrs( \%attrs );

   is_deeply( { $pen->getattrs }, { b => 1 }, '$pen attrs after chattrs' );
   is_deeply( \%attrs, { na => 5 }, '%attrs after chattrs' );

   $pen->chattr( fg => "red" );
}

my $bluepen  = Tickit::Pen::Immutable->new( fg => 4 );
my $otherpen = Tickit::Pen::Immutable->new( fg => 1, bg => 2 );

{
   my $copy = $bluepen->as_mutable;

   is_deeply( { $copy->copy_from( $otherpen )->getattrs },
              { fg => 1, bg => 2 },
              'pen ->copy_from overwrites attributes' );
}

{
   my $copy = $bluepen->as_mutable;

   is_deeply( { $copy->default_from( $otherpen )->getattrs },
              { fg => 4, bg => 2 },
              'pen ->default_from does not overwrite attributes' );
}

my $norv_pen = Tickit::Pen->new( rv => 0 );
$norv_pen->default_from( Tickit::Pen->new( rv => 1 ) );
is_deeply( { $norv_pen->getattrs },
           { rv => '' },
           'pen ->default_from does not overwrite defined-but-false attributes' );

done_testing;
