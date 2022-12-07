package Catalyst::ActionRole::RenderView;

{
  package Catalyst::ActionRole::RenderView::Utils::NoView;
   
  use Moose;
  with 'CatalystX::Utils::DoesHttpException';
   
  sub status_code { 500 }
  sub error { "No View can be found to render." }

  __PACKAGE__->meta->make_immutable;
}

use Moose::Role;
use Catalyst::ActionRole::RenderView::Utils::NoView;

requires 'execute';

around 'execute', sub {
  my ($orig, $self, $controller, $c, @args) = @_;
  my @return = $self->$orig($controller, $c, @args);

  return 1 if $c->req->method eq 'HEAD';                  # Don't need a response for a HEAD request
  return 1 if defined $c->response->body;                 # Don't need a response if we have one
  return 1 if scalar @{ $c->error };                      # Don't try to make a response if there's an unhandled error
  return 1 if $c->response->status =~ /^(?:204|3\d\d)$/;  # Don't response if its a redirect or 'No Content' response
  
  # This will either be the default_view (from config) or the 'current' view, as set by
  # stash flags 'current_view' or 'current_view_instance'.

  my $view = $c->view() || Catalyst::ActionRole::RenderView::Utils::NoView->throw;
  $c->forward($view);

  return @return;
};

1;

=head1 NAME

Catalyst::ActionRole::RenderView - Call the default view

=head1 SYNOPSIS

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub end : Action Does(RenderView) {}

=head1 DESCRIPTION

This is basically L<Catalyst::Action::RenderView> done as an action role (basically a L<Moose>
role) rather than as a base class.  This is a bit more flexible if you plan to do fancy
stuff with your end action.

Two things it doesn't do that the classic L<Catalyst::Action::RenderView> does is it doesn't
set a default content type if none is found (old one just set C<text/html> which was probably
ok back in the 'Aughts but not always true now) and we don't support the C<dump_info> when in
debug mode since I really think something like that belongs in another part of the stack.

I'm willing to be proven wrong, just send me your use cases and patches.

=head1 EXCEPTIONS

This class can throw the following exceptions which are compatible with L<CatalystX::Errors>

=head2 Now View found

If there's no view found when calling '$c->view()' we throw L<Catalyst::ActionRole::RenderView::Utils::NoView>

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2022 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
