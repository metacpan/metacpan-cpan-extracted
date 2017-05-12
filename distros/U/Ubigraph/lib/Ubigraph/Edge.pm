package Ubigraph::Edge;

use 5.006;
use strict;
use warnings;
use Frontier::Client;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $ubigraph = shift;
    my $vertex_a = shift;
    my $vertex_b = shift;
    my $self = {
	edge => $ubigraph->{client}->call('ubigraph.new_edge',$vertex_a->{vertex},$vertex_b->{vertex}),
	client => $ubigraph->{client}
    };

    my %param = @_;
    foreach my $name (keys %param){
	if ($name eq 'arrow_position' || $name eq 'arrow_radius' || $name eq 'arrow_length' || $name eq 'label' || $name eq 'fontsize' || $name eq 'strength' || $name eq 'width') {
	    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},$name,$param{$name}." ");
	} else {
	    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},$name,$param{$name});
	}
    }
    return bless $self,$class;
}

sub remove {
    my $self = shift;
    $self->{client}->call('ubigraph.remove_edge',$self->{edge});
}

sub arrow {
    ## [default] "false" ("true"/"false")
    my $self = shift;
    my $arrow = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'arrow',$arrow);
}

sub arrow_position {
    ## [default] 0.5 (0.0 ~ 1.0)
    my $self = shift;
    my $arrow_position = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'arrow_position',$arrow_position." ");
}

sub arrow_radius {
    ## [default] 1.0
    my $self = shift;
    my $arrow_radius = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'arrow_radius',$arrow_radius." ");
}
sub arrow_length {
    ## [default] 1.0
    my $self = shift;
    my $arrow_length = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'arrow_length',$arrow_length." ");
}
sub arrow_reverse {
    ## [default] "false" ("true"/"false")
    my $self = shift;
    my $arrow_reverse = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'arrow_reverse',$arrow_reverse);
}

sub color {
    ## [default] "#0000ff"
    my $self = shift;
    my $color = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'color',$color);
}

sub label {
    ## [default] ""
    my $self = shift;
    my $label = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'label',$label." ");
}

sub fontcolor {
    ## [default] "#ffffff"
    my $self = shift;
    my $font_color = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'fontcolor',$font_color);
}

sub fontfamily {
    ## [default] "Helvetica" ("Helvetica","Times Roman")
    my $self = shift;
    my $font_family = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'fontfamily',$font_family);
}

sub fontsize {
    ## [default] "12"
    my $self = shift;
    my $font_size = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'fontsize',$font_size." ");
}

sub oriented {
    ## [default] "false" ("true"/"false")
    my $self = shift;
    my $oriented = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'oriented',$oriented);
}
sub spline {
    ## [default] "false" ("true"/"false")
    my $self = shift;
    my $spline = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'spline',$spline);
}

sub showstrain {
    ## [default] "false" ("true"/"false")
    my $self = shift;
    my $showstrain = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'showstrain',$showstrain);
}

sub stroke {
    ## [default] "solid" ("solid","dashed","dotted","none")
    my $self = shift;
    my $stroke = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'stroke',$stroke);
}

sub strength {
    ## [default] 1.0
    my $self = shift;
    my $strength = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'strength',$strength." ");
}

sub visible {
    ## [default] "true" ("true"/"false")
    my $self = shift;
    my $visible = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'visible',$visible);
}

sub width {
    ## [default] "1.0"
    my $self = shift;
    my $width = shift;
    $self->{client}->call('ubigraph.set_edge_attribute',$self->{edge},'width',$width." ");
}

1;
