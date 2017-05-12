package Test::MockObject::Chain;

use 5.010000;
use strict;
use warnings;
use Want;
use vars '$AUTOLOAD';
use Carp;
use Scalar::Util qw( blessed );

our $VERSION = '1.00';

sub _new {
    shift;
    my %args = @_;
    $args{type} ||= {};
    $args{class} ||= "Test::MockObject::Chain";

    my $object = $args{object} || bless $args{type}, $args{class};
    $object->{_methods_} = {};

    return $object;
}


sub AUTOLOAD: lvalue {
  my $self = shift;

  unless( blessed($self)) {
    $self = $self->_new() ;
    return $self;
  }  

  ( my $method = $AUTOLOAD ) =~ s{.*::}{};
  my @params = @_;

  my $key = $self->_key(\@params);

  if(not $self->_method_exists( $method, $key ) ) {
    if(want('OBJECT')) {
      $self->_add_method($method, \@_, Test::MockObject::Chain->_new() );
    }
    else {
      carp "Attempt to read uninitialised method $method with key $key" unless want('LVALUE');
    }
  }

  $self->{_methods_}->{$method}->{$key};

}

sub _method_exists {
  my $self = shift;
  my $method = shift;
  my $key = shift;

  return exists($self->{_methods_}->{$method}->{$key}) ;
}

sub _key {
  my $self = shift;
  my $params = shift;

  return join chr(28), @$params;
}


sub _add_method {
  my $self = shift;
  my $method = shift;
  my $params = shift;
  my $response = shift;

  $self->{_methods_}->{$method} ||= {};
  $self->{_methods_}->{$method}->{join chr(28),@$params} = $response;

  return $response;
}


sub DESTROY {}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::MockObject::Chain - Perl extension for quickly mocking your terrible law of demeter failing code

=head1 SYNOPSIS

  use Test::MockObject::Chain;
  my $user = Test::MockObject::Chain->new();
  $user->orders()->find(newest => 1)->total_cost_in_pence() = 1000; 


=head1 DESCRIPTION

Quickly mock out chained objects in your tests. You should probably refactor instead of using this.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jonathan Taylor, E<lt>jon@localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
