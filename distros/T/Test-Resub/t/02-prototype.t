#!/usr/bin/env perl

use strict;

use Test::More;
if (can_set_prototype()) {
    plan tests => 8;
} else {
    plan skip_all => "Can't set prototypes without Scalar::Util::set_prototype";
}

use lib 't/lib';
use lib 'lib';
use lib '../lib';

use Test::Resub;

sub can_set_prototype {
    local $@;
    eval { require Scalar::Util; Scalar::Util->import('set_prototype') };
    return not $@;
}

# Match prototypes
{
  {
    package Prototypical;

    sub prototypeless {}
    sub empty_prototype () { 1 if $] }
    sub maplike (&@) {}
    sub optional_prototype_part ($;$) {}
  }

  is( prototype('Prototypical::prototypeless'), undef, 'Sanity check 1' );
  is( prototype('Prototypical::empty_prototype'), '', 'Sanity check 2' );
  is( prototype('Prototypical::maplike'), '&@', 'Sanity check 3' );

  my $rs = Test::Resub->new({
    name => 'Prototypical::prototypeless',
    call => 'optional',
  });
  is( prototype('Prototypical::prototypeless'), undef, 'no prototype' );
    
  {
    $rs = Test::Resub->new({
      name => 'Prototypical::maplike',
      call => 'optional',
    });
    is( prototype('Prototypical::maplike'), '&@', 'maplike' );
  }
  is( prototype('Prototypical::maplike'), '&@', 'maplike goes back' );

  $rs = Test::Resub->new({
    name => 'Prototypical::empty_prototype',
    call => 'optional',
  });
  is( prototype('Prototypical::empty_prototype'), '', 'empty prototype' );
}

# If you can't read the prototype, don't die.
{
  local $@;
  my $rs;
  eval {
    $rs = Test::Resub->new({
      name => 'CORE::GLOBAL::select',
      call => 'optional',
      create => 1,
    });
  };
  is( $@, '', 'no error on CORE::GLOBAL::select' );
}
