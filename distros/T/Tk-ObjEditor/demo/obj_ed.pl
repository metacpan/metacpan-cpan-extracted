#
# This file is part of Tk-ObjEditor
#
# This software is copyright (c) 2014 by Dominique Dumont.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# ObjEditor - A widget to edit data and object

use Tk ;
use Tk::ObjEditor ;

# sample object to edit
package Toto ;

sub new
  {
    my $type = shift ;
    my $tkstuff = shift ;
    my $scalar = 'dummy scalar ref value';
    my $self = 
      {
       'key1' => 'value1',
       'array' => [qw/a b sdf/, {'v1' => '1', 'v2' => 2},'dfg'],
       'key2' => {
                  'sub key1' => 'sv1',
                  'sub key2' => 'sv2'
                 },
       'piped|key' => {a => 1 , b => 2},
       'scalar_ref_ref' => \\$scalar,
       'empty string' => '',
       'pseudo hash' => [ { a => 1, b => 2}, 'a value', 'bvalue'],
       'non_empty string' => ' ',
       'long' => 'very long line'.'.' x 80 ,
       'is undef' => undef,
       'some text' => "some \n dummy\n Text\n",
      } ;
    bless $self,$type;
  }


package main;

sub obj_ed
  {
    my($demo) = @_;
    $TOP = $MW->WidgetDemo
      (
       -name => $demo,
       -text => 'ObjEditor - data and object editor.',
       -geometry_manager => 'grid',
       -title => 'A widget to edit data or object',
       -iconname => 'ObjEditorDemo'
      ) ;

    $TOP->Label(text => "Please click on right button on any item to modify the data")->pack ;

    my $dummy = new Toto ();

    $TOP -> ObjEditor 
      (
       caller => $dummy, 
       direct => 1,
       destroyable => 0
      ) -> pack;

  }


