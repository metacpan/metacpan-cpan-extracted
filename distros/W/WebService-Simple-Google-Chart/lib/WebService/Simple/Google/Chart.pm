package WebService::Simple::Google::Chart;
use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::Simple);
__PACKAGE__->config(
    base_url      => "http://chart.apis.google.com/chart",
    request_param => {},
);

sub get_url {
    my ( $self, $param, $data ) = @_;
    $self->{request_param} = $param;
    $self->_set_data_param($data);
    return $self->request_url( ( params => $self->{request_param}, url => $self->{base_url} ) );
}

sub render_to_file {
    my ( $self, $filename, $param, $data ) = @_;
    if ($param) {
        $self->{request_param} = $param;
        $self->_set_data_param($data);
    }
    $self->SUPER::get( $self->{request_param}, ":content_file" => $filename );
}

sub _set_data_param {
    my ($self, $data) = @_;
    my ( @label, @value, $total_count );
    $total_count = 0;
    map { $total_count += $data->{$_} } keys %$data;
    foreach my $key ( keys %$data ) {
        push( @label, $key );
        my $percent = int( $data->{$key} / $total_count * 100 + 0.5 );
        push( @value, $percent );
    }
    my $data_param = {};
    $self->{request_param}->{chl} = join( "|", @label );
    $self->{request_param}->{chd} = "t:" . join( ",", @value );
}

1;

__END__

=head1 NAME

WebService::Simple::Google::Chart - Get Google Chart URL and image file

=head1 SYNOPSIS

  use WebService::Simple::Google::Chart;

  my $chart = WebService::Simple::Google::Chart->new;
  my $url   = $chart->get_url(
      {
          chs => "250x100",
          cht => "p3",
      },
      { foo => 200, bar => 130, hoge => 70 },
  );
  print $url;
  $chart->render_to_file("foo.png");


=head1 DESCRIPTION

=head1 METHOS

=head2 get_url

=head2 render_to_file

=head1 AUTHOR

Yusuke Wada <yusuke@kamawada.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut


