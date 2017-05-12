#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

BEGIN { eval q{ use Test::More skip_all => 'Mouse is required' } if not eval { require Mouse } };

use Test::More tests => 4;

use lib 't';
use tlib;


eval q{
  package My::MouseClass;

  use Mouse;

  use namespace::functions -except => 'meta';

  sub my_method {
      my ($self, $arg) = @_;
      return blessed $self;
  };

  no namespace::functions;

  # The My::MouseClass now provides "my_method" and "meta" only.
};
is($@, '', 'My::MouseClass is ok');

my $obj = My::MouseClass->new;
isa_ok( $obj, 'My::MouseClass', '$obj isa My::MouseClass' );
ok( $obj->my_method, '$obj->my_method is ok' );
is_deeply( list_subroutines("My::MouseClass"), [ qw( meta my_method ) ], 'namespace is ok' );
