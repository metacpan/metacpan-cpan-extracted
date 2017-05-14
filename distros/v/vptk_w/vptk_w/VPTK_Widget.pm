=head1 NAME

 VPTK_Widget -- abstract vptk_w widget class

=head1 Description

 This is an abstract class that wrap all editor object classes.
 It supply several generic methods (including constructor) but JustDraw method
 must be implemented in derived class

 Details see in examplary class 'Label'

=cut

package vptk_w::VPTK_Widget;

use strict;
use Exporter 'import';
our @EXPORT = qw(HaveGeometry WidgetIconName AllWidgetsNames EditorProperties DefaultParams TkClassName);

use vptk_w::VPTK_Geometry;
my @widget_types;

BEGIN {
# here we are going to load all sub-classes that placed under this class directory
  my ($path) = ($0 =~ m#(.*[/\\])#);
  $path = '.' unless $path;
  my $package = __PACKAGE__;
  $package =~ s#::#/#g;
  $package = "$path/$package";
  opendir(DIR,$package) || die "$0 dir $package read - $!";
  foreach (grep(/\.pm$/,readdir(DIR))) {
    require "$package/$_";
    s/\.pm$//;
    s/^mtk//; # name correction for 'artificial' class names (see constructor comment)
    push(@widget_types,$_);
  }
  closedir DIR;
}

# Public methods wrapping derived classes implementation
sub AllWidgetsNames { return @widget_types }

# Constructor (non-virtual)
# Automatically builds sub-class object with standard content
# Usage: 
#   my $object = vptk_w::VPTK_Widget->new( subclassname [, args ] );
sub new { 
  my $class = shift;
  my $sub_class = shift;

  die "ERROR: missing arg(s) ($class,$sub_class)"
    unless $sub_class;
  # Re-naming sub-class (dirty trick to overcome M$ Wind0Ze file naming limitation)
  # Issue description: like in old DOS times contemporary M$ filesystem does not
  # support co-existance of more than one file with same letters set but in
  # different lettercase (radiobutton.pm vs Radiobatton.pm)
  $sub_class = "mtk$sub_class"
    unless (eval $class.'::'.$sub_class."->can('JustDraw')");
  $class = $class.'::'.$sub_class;
  die "ERROR: missing 1st arg"
    unless $class;
  my @args = @_;

  die "ERROR: wrong parameters number (@args) in ".(caller(0))[3]."\n"
    if scalar(@args) % 2;
  push (@args, 
    -instance_data => {-widget_data=>{},-geometry_data=>{}}
  );
  return bless { @args } => $class;
}

# putter/getter method for '-instance_data' property
# When called without args retrieves object's parameters
sub InstanceData {
  my $this = shift;
  die "ERROR: wrong this/missing ($this) in ".(caller(0))[3]."\n"
    unless ref $this;
  
  if(@_) {
    $this->{'-instance_data'} = {@_};
  }
  else {
    return $this->{'-instance_data'};
  }
}

sub Draw {
  my ($this,$parent) = @_;
  die "ERROR: missing or wrong arg(s) (@_)"
    unless ref $this && ref $parent;
  $this->{'-parent_object'} = $parent;
  my @args = %{$this->InstanceData()->{'-widget_data'}};
  my $result;
  my $scrolled = 0;
  if(grep($_ eq '-scrolled',@args)) {
    $scrolled = 1;
    my %args = @args;
    delete $args{'-scrolled'};
    @args = %args;
  }
  if($scrolled) {
    $result = $parent->Scrolled($this->PrintTitle()=>@args);
  }
  else {
    $result=$this->JustDraw($parent,@args);
  }
  if($this->HaveGeometry) {
    my $geometry = vptk_w::VPTK_Geometry->new( %{$this->InstanceData()->{'-geometry_data'}} );
    $geometry->ApplyGeometry($result);
  }
  $this->{'-visual_object'} = $result;
  return $result;
}

sub DefaultParams    { &enquire_from_subclass('DefaultParams'   => @_) }
sub HaveGeometry     { &enquire_from_subclass('HaveGeometry'    => @_) }
sub TkClassName      { 
  return undef
    unless grep ($_[0] eq $_,@widget_types);
  &enquire_from_subclass('TkClassName'          => @_);
}
sub PrintTitle       { &enquire_from_subclass('PrintTitle'      => @_) }
sub EditorProperties { &enquire_from_subclass('EditorProperties'=> @_) }
sub WidgetIconName   { &enquire_from_subclass('AssociatedIcon'=> @_) }

sub enquire_from_subclass {
  shift if ref $_[0]; # no 'instance' methods allowed!
  my $method = shift || die "missing method name";
  my $sub_class = shift || die "missing sub-class argument";
  $sub_class = __PACKAGE__ . "::$sub_class";
  unless (eval $sub_class."->can('$method')") {
    $sub_class =~ s/(.*::)/$1mtk/; # attempt to re-name class
    # (see comment in constructor method for details)
  }
  unless (eval $sub_class."->can('$method')") {
    warn "subclass $sub_class don't know how to run $method";
    return undef
  }
  
  return eval ($sub_class."::$method(".join(',',map("'$_'",@_)).");");
}

# Virtual method
sub JustDraw         { die "Virtual function called" }

1;#)
