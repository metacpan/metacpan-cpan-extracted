package Wight::Chart::ChartJS;

use Moo;
use JSON::XS;
use Encode;
use Graphics::Color::RGB;
extends 'Wight::Chart';

our $VERSION = '0.003'; # VERSION

#TODO: import roles for each type for more options
my $types = {
  line => { cls => "Line" },
  area => { cls => "Line" },
  spark => { cls => "Line", config => {
    scaleShowLabels => JSON::XS::false,
    pointDot => JSON::XS::false,
    scaleShowGridLines => JSON::XS::false,
  }},
  bar => { cls => "Bar" },
  radar => { cls => "Radar" } ,
  polararea => { cls => 'PolarArea' },
  pie => { cls => 'Pie' },
  doughnut => { cls => 'Doughnut' },
};

has 'type' => ( is => 'rw', required => 1, isa => sub { $types->{$_[0]} } );

has '_colour' => ( is => 'rw', default => sub {
  Graphics::Color::RGB->new({ red => .3, blue => 1, green => .3 })
});

has 'colour' => ( is => 'rw', trigger => 1 );
sub _trigger_colour {
  my $self = shift;
  my $value = shift;
  $self->_colour(Graphics::Color::RGB->from_hex_string($value));
}

sub src_html { 'chartjs.html' }
sub rgba {
  my $self = shift;
  my $alpha = shift;
  $self->_colour->alpha($alpha);
  return "rgba(" . $self->_colour->as_integer_string . ")";
}

sub render {
  my ($self, $local_config) = @_;
  my $w = $self->wight;

  my $src = $types->{$self->type};

  my $config = {
    animation => JSON::XS::false,
    %{$src->{config} || {} },
    %{$local_config || {} },
  };

  #if type is spark, clear columns
  if($self->type eq 'spark') { $self->columns([('') x scalar @{$self->columns}]) }
  my $args = decode_utf8(encode_json({
    config => $config,
    type => $src->{cls},
    width => $self->width,
    height => $self->height,
    data => {
      labels => $self->columns,
      datasets => [ {
        fillColor => $self->rgba(.5),
        strokeColor => $self->rgba(1),
        pointColor => $self->rgba(1),
        pointStrokeColor => "#fff",
        data => $self->rows,
      } ]
    }
  }));

  $w->evaluate("drawChart($args)");
  $w->sleep(.1);
  $w->render($self->output);
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Wight::Chart::ChartJS

=head1 VERSION

version 0.003

=head1 SYNOPSIS

See tests.

=head1 NAME

Wight::Chart::ChartJS - Generate static charts using chart.js

=head1 AUTHOR

Simon Elliott <simon@papercreatures.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Simon Elliott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
