################################################################################
#
# $Project: /Tk-DataTree $
# $Author: mhx $
# $Date: 2008/01/11 00:18:49 +0100 $
# $Revision: 6 $
# $Snapshot: /Tk-DataTree/0.06 $
# $Source: /t/101_base.t $
#
################################################################################
#
# Copyright (c) 2004-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
BEGIN { plan tests => 38 }

use Tk;
use Tk::DataTree;

eval {
  require Scalar::Util;
  *dualvar = \&Scalar::Util::dualvar;
};

if ($@) {
  print "# Scalar::Util not installed\n";
  *dualvar = sub { "$_[1] ($_[0])" };
}

my $sleep = $ENV{DATATREE_TEST_SLEEP} || 0;

my $mw = new MainWindow;
$mw->geometry("480x320");

my $dt = $mw->DataTree(-typename => "my_type", -activecolor => 'blue')
            ->pack(-fill => 'both', -expand => 1);

$mw->idletasks;

while( <DATA> ) {
  s/^\s*#.*//;
  /\S/ or next;
  eval $_;
  $mw->idletasks;
  ok($@,'');
  select undef, undef, undef, $sleep;
}

__DATA__

$dt->configure(-typename => 'nothing');

$dt->data( { foo => { bar => [ 1 ] } } );

$dt->data( undef );
$dt->configure(-typename => 'typeA');
$dt->data( 'foo' );
$dt->configure(-typename => 'typeB');
$dt->data( 123 );
$dt->configure(-typename => 'typeC');
$dt->data( 3.14159 );

$dt->configure( -data => { foo => { bar => [ 1 ] } } );
$dt->configure( -data => { foo => { bar => [ 1, 2 ] } } );
$dt->configure( -data => { foo => { bar => [ 1, 2, 3 ] } } );
$dt->configure( -data => { foo => { bar => [ 1, 2, 3 ] }, xyz => 123 } );

$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => 123 } );
$dt->data( { foo => { bar => [ 1, 3, 3 ], baz => "xxx" }, xyz => 123 } );
$dt->data( { foo => { bar => [ 1, 3, 3 ], baz => "xx" }, xyz => 123 } );
$dt->data( { foo => { bar => [ 1, 3, 3 ], baz => "xx" }, xyz => 42 } );
$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => 123 } );
$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => 123 } );

$dt->configure(-activecolor => '#00A000', -typename => 'foobar');

$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => dualvar(123, 'Hello') } );
$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => dualvar(123, 'World') } );
$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => dualvar(456, 'World') } );
$dt->data( { foo => { bar => [ 1, 2, 3 ], baz => "xxx" }, xyz => 'World' } );
$dt->data( { foo => { bar => [ 1, [2, 3], {four => 4, five => 5} ], baz => "xxx" }, xyz => 123 } );

$dt->configure(-activecolor => '#A000A0');
$dt->Subwidget('normalstyle')->configure(-fg => '#FFFFFF');
$dt->Subwidget('nodestyle')->configure(-fg => '#0000FF');

$dt->data( { foo => { bar => [ 1, [2], {four => 4} ], baz => "xxx" }, xyz => 123 } );
$dt->data( { foo => { bar => [ 1, [2], {four => 4} ] }, xyz => 123 } );
$dt->data( { foo => { bar => [ 1, [2], {four => 4} ] } } );
$dt->data( { foo => { bar => [ 1, [2] ] } } );
$dt->data( { foo => { bar => [ 1 ] } } );

$dt->data( { foo => { bar => [ 1, undef ] } } );
$dt->data( { foo => { bar => [ 1, undef ] }, baz => undef } );

$dt->configure(-undefcolor => '#A0A000');

$dt->data( { foo => { bar => [ 1 ] }, baz => undef } );
$dt->data( { baz => undef } );

