package vptk_w::Project;

=head1 Name

  vptk_w::Project - base class for project elements

=head1 Synopsis

  # general use of top-class
  use vptk_w::Project;
  my $project = vptk_w::Project->new();

  my $project_header = vptk_w::Project::Header->new();
  $project->push('Header'=>$project_header);

  $project_header->push('perl executable' => $perl_exe);
  my $pe = $project_header->get('perl executable');

  foreach my $element ( @{$project->elements()} ) {
    print OUTPUT $element->print
      if $element->can('print');
  } 

  # extended sub-class
  my $widgets_data = vptk_w::Project::Widgets->new();
  $widgets_data->add($path,$name,$object);
  my $data = $widgets_data->get_by_path($path);

=head1 Description

  The goal of this class is to unify I/O and access operations for
  project elements. As 'built-in' feature we allow by-name access
  along with order relation between elements.

  Typical project consists of:
  - Options (perl executable, use strict, all Tk components 'use')
  - Widgets (main part of the project)
  - Code (user-defined code placed after MainLoop)
=cut

use strict;

sub new { # default constructor
  my $class = shift;
  my $this  = {list=>[],data=>{}};

  bless $this => $class;
}

sub init { # just clean all
  my $this = shift;
  my $pData = shift;
  $this->{list}=[];
  $this->{data}={};
  map ($this->push($_,$pData->{$_}), keys %$pData) if ref $pData;
}

sub push { # default putter
  my $this = shift;
  my $id   = shift;
  my $data = shift;
  push(@{$this->{list}},$id) unless exists $this->{data}->{$id};
  $this->{data}->{$id} = $data;
}

sub set { # by-name setter
  my $this = shift;
  my $id   = shift;
  my $value = shift;
  return undef unless exists $this->{data}->{$id};
  $this->{data}->{$id}=$value;
}

sub get { # by-name getter
  my $this = shift;
  my $id   = shift;
  return undef unless exists $this->{data}->{$id};
  return $this->{data}->{$id};
}

sub del { # element eraser
  my $this = shift;
  my $id   = shift;
  
  return undef unless exists $this->{data}->{$id};
  my $data = $this->{data}->{$id};
  @{$this->{list}} = grep($_ ne $id, @{$this->{list}});
  return $data;
}

sub elements { # all data (in-order) getter
  my $this = shift;

  return map($this->{data}->{$_}, @{$this->{list}});
}

sub keys { # all keys getter (in order)
  my $this = shift;

  return @{$this->{list}};
}

sub data { # return data hash pointer
  my $this = shift;

  return $this->{data};
}

sub print { # return ready-to-print array for all elements
  my $this = shift;
  my @result;

  foreach my $element ( $this->elements ) {
    CORE::push (@result,$element->print($this,@_)) if $element->can('print');
  }
  return @result;
}

1;#)
