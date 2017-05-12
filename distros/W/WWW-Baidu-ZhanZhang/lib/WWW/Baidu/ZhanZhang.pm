package WWW::Baidu::ZhanZhang;

use strict;
use 5.008_005;
our $VERSION = '0.01';
use Carp qw/croak/;
use Mojo::UserAgent;

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };

    # validate
    $args->{site}  or croak 'site is required';
    $args->{token} or croak 'token is required';

    unless ( $args->{ua} ) {
        my $ua_args = delete $args->{ua_args} || {};
        $args->{ua} = Mojo::UserAgent->new(%$ua_args);
    }

    bless $args, $class;
}

sub post_urls {
    my ($self, @urls) = @_;

    my $url = "http://data.zz.baidu.com/urls?site=" . $self->{site} . "&token=" . $self->{token};
    $url .= "&type=" . $self->{type} if $self->{type};

    my $tx = $self->{ua}->post($url => { 'Content-Type' => 'text/plain' } => join("\n", @urls));
    if (my $res = $tx->success) {
        return $res->json;
    } else {
        my $err = $tx->error;
        croak "$err->{code} response: $err->{message}" if $err->{code};
        croak "Connection error: $err->{message}";
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Baidu::ZhanZhang - Baidu ZhanZhang push links

=head1 SYNOPSIS

  use WWW::Baidu::ZhanZhang;

  my $zz = WWW::Baidu::ZhanZhang->new(
    site  => 'betsapi.com',
    token => 'abc'
  );

  my $data = $zz->post_urls('http://betsapi.com/c/Soccer', 'http://betsapi.com/c/Tennis');


=head1 DESCRIPTION

you can get the token from L<http://zhanzhang.baidu.com/linksubmit/index>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
