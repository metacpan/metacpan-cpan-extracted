package # hide from PAUSE
  Catalyst::ActionRole::RenderView;

{
  package Catalyst::ActionRole::RenderView::Utils::NoView;
   
  use Moose;
  use namespace::clean -except => 'meta';
    
  extends 'CatalystX::Utils::HttpException';
  
  has '+status' => (is=>'ro', init_arg=>undef, default=>sub {500});
  has '+errors' => (
    is=>'ro',
    init_arg=>undef, 
    default=>sub { ["No View can be found to render."] },
  );
   
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

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2021 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
