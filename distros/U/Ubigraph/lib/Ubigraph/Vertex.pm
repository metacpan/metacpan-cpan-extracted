package Ubigraph::Vertex;

use 5.006;
use strict;
use warnings;
use Frontier::Client;

our $VERSION = '0.04';

sub new {
    my $class = shift;
    my $ubigraph = shift;
    my $self = {
	vertex => $ubigraph->{client}->call('ubigraph.new_vertex'),
        client => $ubigraph->{client}
    };
    my %param = @_;
    foreach my $name (keys %param){
	if ($name eq 'shapedetail' || $name eq 'label' || $name eq 'size' || $name eq 'fontsize') {
	    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},$name,$param{$name}." ");
	} else {
	    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},$name,$param{$name});
	}
    }

    return bless $self,$class;
}

sub remove {
    my $self = shift;
    $self->{client}->call('ubigraph.remove_vertex',$self->{vertex});
}

sub color {
    ## [default] "#0000ff"
    my $self = shift;
    my $color = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'color',$color);
}

sub shape {
    ## [default] "cube" ("cone","cube","dodecahedron","icosahedron","octahedron","sphere","octahedron","torus")
    my $self = shift;
    my $shape = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'shape',$shape);
}

sub shapedetail {
    ## [default] "10"
    my $self = shift;
    my $detail = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'shapedetail',$detail." ");
}

sub label {
    ## [default] ""
    my $self = shift;
    my $label = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'label',$label." ");
}

sub size {
    ## [defaulr] "1.0"
    my $self = shift;
    my $size = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'size',$size." ");
}

sub fontcolor {
    ## [default] "#ffffff"
    my $self = shift;
    my $font_color = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'fontcolor',$font_color);
}

sub fontfamily {
    ## [default] "Helvetica" ("Helvetica","Times Roman")
    my $self = shift;
    my $font_family = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'fontfamily',$font_family);
}

sub fontsize {
    ## [default] "12"
    my $self = shift;
    my $font_size = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'fontsize',$font_size." ");
}

sub visible {
    ## [default] "true" ("true"/"false")
    my $self = shift;
    my $visible = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'visible',$visible);
}

sub callback_left_doubleclick {
    ## [default] "" (http://yourhostname.net/mothod_name)
    my $self = shift;
    my $double_click = shift;
    $self->{client}->call('ubigraph.set_vertex_attribute',$self->{vertex},'callback_left_doubleclick',$double_click);
}

1;
