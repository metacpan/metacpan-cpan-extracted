=pod

=encoding utf-8

=head1 NAME

MockServer - Very minimal mock server to test the Solid tests

=head1 SYNOPSIS

 my $server = MockServer->new;
 my $suite = InitializeClientHere->new(base_uri => $server->base_uri);
 $suite->run_tests;
 $server->kill;


=head1 DESCRIPTION

L<HTTP::Server::Simple::PSGI>-based Web Server that starts the L<MockSolid> server in the background.

=head2 METHODS AND ATTRIBUTES

=over

=item * C<< pid >>

The process ID of the server.

=item * C<< base_uri >>

Will actually start the server and return the base URI of the server.

=item * C<< kill >>

Will kill the server with the C<pid>.

=back

=head1 TODO

Start the server in the constructor rather than in C<base_uri>.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=cut

use strict;
use warnings;
use Plack::Request;

package MockServer;
use Moo;
use HTTP::Server::Simple::PSGI;
use Net::EmptyPort qw(empty_port);
use Types::Standard qw(Int);
use MockSolid;

has pid => ( is => 'rw',
				 isa => Int
			  );

sub base_uri {
  my $self = shift;
  my $port=empty_port();
  my $host='127.0.0.1';

  my $server = HTTP::Server::Simple::PSGI->new($port);
  $server->host($host);

  my $app = MockSolid->to_psgi_app(@_) ;
  $server->app($app);
  $self->pid($server->background);
  return "http://$host:$port/";
}

sub kill {
  my $self = shift;
  kill 9, $self->pid;
}



1;
