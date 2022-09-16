package # hide from PAUSE
  Catalyst::ActionRole::ReceiveArgs;

use Moose::Role;
use Catalyst::Utils;

requires 'execute', 'dispatch';

our $VERSION = '0.001';

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  my @received = grep { defined $_ } @{ delete($ctx->stash->{__received_args})||[] };
  push @args, @received if @received;
  return $self->$orig($controller, $ctx, @args);
};

1;

=head1 NAME

Catalyst::ActionRole::ReceiveArgs - Pass args between actions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS
 
This role contains the following methods.

=head2 dispatch
 

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>

 
=head1 COPYRIGHT
 
Copyright (c) 2021 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
