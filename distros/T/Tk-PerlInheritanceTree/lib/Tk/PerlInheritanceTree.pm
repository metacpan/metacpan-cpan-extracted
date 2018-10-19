#!/usr/bin/perl

=head1 NAME

Tk::PerlInheritanceTree - Display a graphical representation of the inheritance tree for a given class-name.

=head1 SYNOPSIS


  require Tk::PerlInheritanceTree;
  ...
  my $inheritance_tree = $main_window->PerlInheritanceTree()->pack;

  $inheritance_tree->classname('Tk::MainWindow');



=head1 DESCRIPTION

Tk::PerlInheritanceTree displays a graphical representation of the inheritance tree for a given class(package)-name. The nodes representing classnames have mouseclick bindings to open a Tk::PerlMethodList - widget. Tk::PerlInheritanceTree is a Tk::Frame-derived widget.

PerlInheritanceTree.pm can be run as stand-alone application (see Examples section)



=head1 SEE ALSO

Documentation of Tk::PerlMethodList.

=head1 METHODS

B<Tk::PerlInheritanceTree> supports the following methods:

=over 4

=item B<classname(>'A::Classname'B<)>

Set the Classname-Entry to 'A::Classname' and show_classtree.

=item B<show_classtree()>

Display a tree for the given classname

=back


=head1 OPTIONS

B<Tk::PerlInheritanceTree> supports the following options:

=over 4

=item B<-classname>

configure(-classname=>'A::Classname') 
same as method classname()

=item B<-gridsize>

configure(-gridsize=>$size) 
Set the distance between nodes to $size pixels. Defaults to 120.

=item B<-multiple_methodlists>

configure(-multiple_methodlists=>bool) 
Allows multiple instances of PerlMethodList to be opened if set to a true value. Defaults to 0.

=back


=head1 EXAMPLES

  Run PerlInheritanceTree from the console:

  perl -MTk::PerlInheritanceTree -e'Tk::PerlInheritanceTree::_test_'

  or:

  perl -MTk::PerlInheritanceTree -e'Tk::PerlInheritanceTree::_test_(shift)' Tk::Menu



=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.



=cut
package Tk::PerlInheritanceTree;
our $VERSION = 0.06;
use warnings;
use strict;
require Class::Inspector;

require Tk;
require Tk::NumEntry;
require Tk::GraphItems::TextBox;
require Tk::GraphItems::Connector;
require Tk::PerlMethodList;
use base 'Tk::Frame';

use Data::Dumper;

Tk::Widget->Construct('PerlInheritanceTree');
unless (caller()){_test_()}

sub Populate{
  my ($self,$args)=@_;
  $self->SUPER::Populate($args);
  my $can = $self->Scrolled('Canvas',
                            -scrollregion=> [qw/0 0 200 200/]
                        )->pack(-expand =>1,
                                -fill   =>'both'
                            );
  my $c = $can->Subwidget('scrolled');
  $self->{canvas}=$c;

  $self -> _setup_bindings;
  my $bottom_f  = $self->Frame->pack(-fill   => 'x',
                                #     -expand => 1,
                                 );

  $self -> Label(-textvariable=>\$self->{status},
                 -relief      =>'sunken'
             )->pack(-fill   => 'x',
                      #   -expand => 1,
                         -padx   => 10
                     );
  my $bottom_left  = $bottom_f->Frame->pack(-side => 'left',
                                            -padx => 10,
                                        );
  my $bottom_right = $bottom_f->Frame->pack(-side => 'left',
                                            -padx => 10,
                                        );

  my $en = $bottom_left->Entry(-textvariable=>\$self->{class}
                           )->pack(-side =>'left',
                             );
  my $bt = $bottom_left->Button(-text    => 'Classtree',
                                -command => sub {$self->show_classtree()}
                       )->pack(-side =>'left',
                               -padx => 10,
                           );
  $bottom_right->Label(-text => 'Gridsize:',
                   )->pack(-side => 'left',
                           -padx => 5,
                       );
  $self->{gridsize} =$args->{'-gridsize'} ||= 120;
  my $ne;
  $ne = $bottom_right->NumEntry(-minvalue     => 80,
                                -maxvalue     => 200,
                                -increment    => 20,
                                -width        => 4,
                                -readonly     => 1,
                                -textvariable => \$self->{gridsize},
                                -browsecmd    => [$bt,'invoke'],
                                )->pack(-side => 'left',
                                    );

  $en->bind('<Return>',sub{$bt->Invoke});
  $self->ConfigSpecs(-background          => [$c],
                     -classname           => ['METHOD'],
                     -multiple_methodlists=> ['PASSIVE','','',0],
                     -gridsize            => ['METHOD','','',$self->{gridsize}],
                     DEFAULT              => [$c],
                 );

  $self;
}

sub _setup_bindings{
  my $self = shift;
  my $c =  $self->{canvas};

  ####create a Tk::GraphItems instance to set bindings###
  my $dummy = Tk::GraphItems::TextBox->new(text=>'',
                                           x   =>0,
                                           y   =>0,
                                           canvas=>$c);
  $dummy->bind_class('<3>',sub{$self->node_clicked($_[0])});
  $dummy->bind_class('<ButtonRelease-1>',sub{$self->node_clicked($_[0])
                                                 unless $_[0]->was_dragged});
}

sub _build_classtree{
  my ($self,$row,$nr_nodes,$class,$succ,$succ_node) = @_;

  $succ ||= $self->{tree}||={};
  $succ->{$class}={};
  $self->{nodes}[$row]||=[];
  my $col = (scalar@{$self->{nodes}[$row]}) +1;
  my $node = Tk::GraphItems::TextBox->new(canvas =>  $self->{canvas},
                                          text   =>  $class,
                                          y      => 150,
                                          x      => 150,
                                      );

  push @{$self->{nodes}[$row]} , $node;
  if ($node && $succ_node){
    Tk::GraphItems::Connector->new(source => $node,
                                   target => $succ_node)
  }
  no strict 'refs';
  my @parents = @{$class."::ISA"};
  use strict;
  $row++;
  for my $parent(@parents){
    $self->_build_classtree($row,scalar@parents,$parent,$succ->{$class},$node);
  }
}
sub _place_nodes{
  my $self = shift;
  my $rows = @{$self->{nodes}};
  my $gridsz = $self->cget('-gridsize');
  my $bottom = ($rows-0.5)*$gridsz;
  my $max_cols= 1 ;
  for my $row(@{$self->{nodes}}){
    $max_cols = @$row if @$row>$max_cols;
  }
  my $center = ($max_cols+1) /2 *$gridsz;
  my $row = 0;
  for my $nodes ( @{$self->{nodes}}){
    my $cols = @$nodes;
    my $col = 0;
    for my $node(@$nodes){
      $node->set_coords($center +(($col-($cols-1)/2)* $gridsz),
                        $bottom - $row * $gridsz);
      $col++;
    }
    $row++;
  }
  $self->{canvas}->configure(-scrollregion=>[0,
                                             0,
                                             $center*2,
                                             $bottom+ .5*$gridsz]);
}
sub classname{
  my ($self,$class) = @_;
  $self->{class} = $class;
  $self->show_classtree;
}
sub gridsize{
    my $self = shift;
    $self->{gridsize} = $_[0] if ($_[0]);
    return $self->{gridsize};
}
sub show_classtree{
    my ($self) = @_;
    my $class = $self->{class};
    return unless ($class);
    eval "require $class";

        unless (Class::Inspector->loaded($class)){
        $self->{status} = "Error: Package '$class' not found !";
        return;
    }

    $self->{status} = "Showing inheritance tree for class '$class'";
    $self->{tree} = {};
    $self->{nodes}= [];
    $self->_build_classtree(0,1,$class);
    $self->_place_nodes;
    $self->_place_nodes;
}
sub node_clicked{
  my ($self,$node) = @_;
  my $text = $node->text;
  my $mml = $self->cget('-multiple_methodlists');
  my $ml = $self->{m_list};
  unless ($ml && $ml->Exists){
    $ml = $self->PerlMethodList;
  }
  
  $ml->configure(-classname=>$text,
                 -filter   =>'');
  $ml->show_methods;
  $ml->deiconify;
  $ml->focus;
  if (!$mml){
    $ml->protocol("WM_DELETE_WINDOW",sub{$ml->withdraw});
    $self->{m_list} = $ml;
  }else{
    $ml->protocol("WM_DELETE_WINDOW",'');
  }
}

sub _test_{

  my $mw = Tk::tkinit();
  my @cln;
  @cln = (-classname => $_[0]) if $_[0];
  my $cg =$mw->PerlInheritanceTree(@cln)
    ->pack(-fill   => 'both',
           -expand => 1);
  Tk::MainLoop();
}
1;
__END__



