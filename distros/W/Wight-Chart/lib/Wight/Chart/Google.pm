package Wight::Chart::Google;

#ABSTRACT: Save google charts to images using phantomjs

our $VERSION = '0.003'; # VERSION

use Moo;
use JSON::XS;
use Encode;
extends 'Wight::Chart';
sub src_html { 'google.html' }

#TODO: import roles for each type for more options
my $types = {
  line => "LineChart",
  area => "AreaChart",
  bar => "BarChart",
  pie => "PieChart",
  spark => 'ImageSparkLine',
};

has 'type' => ( is => 'rw', required => 1, isa => sub { $types->{$_[0]} } );
has 'border' => ( is => 'rw', default => 100 );

sub render {
  my ($self) = @_;
  my $w = $self->wight;
  my $options = {
    chartArea => {
      width => $self->width - $self->border,
      height => $self->height - $self->border,
    },
    %{$self->options}
  };

  my $args = decode_utf8(encode_json({
    options => $options,
    type => $types->{$self->type},
    rows => $self->rows,
    columns => $self->columns,
  }));
  #warn $args;
  $w->evaluate("drawChart($args)");
  $w->render($self->output);
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Wight::Chart::Google - Save google charts to images using phantomjs

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Wight::Chart::Google;

  my $chart = Wight::Chart::Google->new(
    type => "area",
    width => 900,
    height => 500,
    options => {
      backgroundColor => 'transparent',
      hAxis => { gridlines => { color => "#fff" } },
      vAxis => { gridlines => { color => "#fff" } },
      legend => { position => 'none' },
    }
  );
  $chart->columns([
    { name => 'Day', type => 'string' },
    { name => 'Amount', type => 'number' },
  ]);
  $chart->rows([['1st',100], ['2nd',150], ['3rd',50], ['4th',70]]);
  $chart->render();

=head1 NAME

Wight::Chart::Google - Generate static google charts

=head1 AUTHOR

Simon Elliott <simon@papercreatures.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Simon Elliott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
