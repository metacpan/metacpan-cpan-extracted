$Tk::LineGraphDataset::VERSION = '0.01';

package LineGraphDataset;
# This is a LineGraphDataset object. 
# It can be graphed by LineGraph 

$DataSetCount = 0;  

sub new {
# create a new LineGraphDataset object
  my($class, %args) = @_;
  bless(\%args, $class);
  my $self = \%args;
  $self->{-index} = $DataSetCount++;
  $self->{-active} = 1;  # yes, active
  $self->{-color} = "none" if($self->{-color} eq undef);
  $self->{-y1} = 0         if($self->{-y1}    eq undef);
  $self->{-yAxis} = "Y"    if($self->{-yAxis} eq undef);
  die "Each LineGraphDataset requires a name.\n"  if($self->{-name}  eq undef);
  die "Each LineGraphDataset requires a Y array of data points.\n"  if($self->{-yArray} ne undef);
  my @ya;
  if($self->{-yArray} ne undef) {
      foreach my $e (@{$self->{-yArray}}) {
	  push @ya, $e;
      }
      $self->{-yArray} = \@ya; # now the dataset owns the data
  }
  my @xa;
  if($self->{-xArray} ne undef) {
      foreach my $e (@{$self->{-xArray}}) {
	  push @xa, $e;
      }
      $self->{-yArray} = \@xa; # now the dataset owns the data
  } 
  return($self);
}

sub get {
  # get any attribute
  my($self,$attr) = @_;
  return($self->{$attr});
}

sub set { 
    # set/defind an attribute
    # -att => value is the format
    # print "args for set @_ \n";
    my($self, %att) = @_;
    foreach my $k (keys(%att) ) {
	$self->{$k} = $att{$k};
    }
    foreach my $k (keys(%$self) ) {
	# print "LineGraphDataset hash <$k> <$self->{$k}> \n";
    }
}

1;
=head1 NAME

  LinePlotDataset - An Object into which to store data to be plotted by the LineGraph widget.

=head1 DESCRIPTION

LinePlotDataset is an object into which data and meta data can be stored.  
This object can be plotted by the LineGraph widget.

=head1 CONSTRUCTOR

new(-yArray => Y data array
    -name => dataset name,
    -yAxis => "Y|Y1",
    -color => line Color,
    -xArray => X data array);

The Y array data and the dataset name are required.  Other parameters are optional.
The yAxis defaults to the Y (left hand) axis.  The color for the graph of the dataset defaults
to one the plot default colors.  The X array data defaults to the integers (0 .. size of yArray).

The Dataset objects copies the data arrays. 


=head1 EXAMPLE

     use Tk;
     use Tk::LineGraph;
     use Tk::LineGraphDataset;

     my $mw = MainWindow->new;

     my $cp = $mw->LineGraph(-width=>500, -height=>500, -background => snow)->grid;

     my @yArray = (1..5,11..18,22..23,99..300,333..555,0,0,0,0,600,600,600,600,599,599,599);
     my $ds = LineGraphDataset->new(-yData=>\@yArray,-name=>"setOne");
     $cp->linePlot(-dataset=>$ds);

     MainLoop;


=head1 METHODS

=item B<get(option);>
 
    Returns the current value of the option.   Options are listed in the constructor.

=item B<set(option , value);>

    Sets the option to value.  Options are listed in the constructor.

=head1 AUTHOR

Tom Clifford (Still_Aimless@yahoo.com)

Copyright (C) Tom Clifford.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

Graph 2D Axis Graph Dataset

=cut
