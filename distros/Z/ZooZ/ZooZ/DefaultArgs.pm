
package ZooZ::DefaultArgs;

use strict;

our %defaultWidgetArgs = (
			  'Image' => sub {
			    return {-image => 'image-zooz'};
			  },
			  'Label' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Button' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Checkbutton' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Radiobutton' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Labelframe' => sub {
			    my $n = shift;
			    return {-text     => $n };
			  },
			  Optionmenu => sub {
			    return {-textvariable => undef};
			  },
			  #			  Frame        => sub {  # Pane .. really
			  #			    return {
			  #				    #-gridded => 'xy',
			  #				    -sticky  => 'nsew',
			  #				    -width   => 200,
			  #				    -height  => 200,
			  #				   },
			  #			},
			 );

our %defaultPlacementArgs = (
			     Frame => {
				       -sticky => 'nsew',
				      },
			    );

sub getDefaultWidgetArgs {
  my ($class, $w, $n) = @_;

  return exists $defaultWidgetArgs{$w} ?
    $defaultWidgetArgs{$w}->($n) : {};
}

sub getDefaultPlacementArgs {
  my ($class, $w) = @_;

  return exists $defaultPlacementArgs{$w} ?
    $defaultPlacementArgs{$w} : {};
}
