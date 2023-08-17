package Example::Controller;

use Scalar::Util;
use String::CamelCase;
use Moose;

extends 'Catalyst::ControllerPerContext';
with 'Catalyst::ControllerRole::At';

around gather_default_action_roles => sub {
  my ($orig, $self, %args) = @_;
  my @roles = $self->$orig(%args);
  push @roles, 'Catalyst::ActionRole::RequestModel'
    if $args{attributes}->{RequestModel} || 
      $args{attributes}->{QueryModel} || 
      $args{attributes}->{BodyModel} ||
      $args{attributes}->{BodyModelFor}; 
  return @roles;
};


## This stuff will go into a role sooner or later

sub view {
  my ($self, @args) = @_;
  return $self->ctx->stash->{current_view_instance} if exists($self->ctx->stash->{current_view_instance}) && !@args;
  return $self->view_for($self->ctx->action, @args);
}

sub view_for {
  my ($self, $action_proto, @args) = @_;
  my $action = Scalar::Util::blessed($action_proto) ?
    $action_proto :
      $self->action_for($action_proto);

  return die "No action for $action_proto" unless $action;

  my $action_namepart = $self->_action_namepart_from_action($action);
  my $view = $self->_build_view_name($action_namepart);

  $self->ctx->log->debug("Initializing View: $view") if $self->ctx->debug;
  return $self->ctx->view($view, @args);
}

sub _action_namepart_from_action {
  my ($self, $action) = @_;
  my $action_namepart = String::CamelCase::camelize($action->reverse);
  $action_namepart =~s/\//::/g;
  return $action_namepart;
}

sub _build_view_name {
  my ($self, $action_namepart) = @_;

  my $accept = $self->ctx->request->headers->header('Accept');
  my $available_content_types = $self->_content_negotiation->{content_types};
  my $content_type = $self->_content_negotiation->{negotiator}->choose_media_type($available_content_types, $accept);
  my $matched_content_type = $self->_content_negotiation->{content_types_to_prefixes}->{$content_type};

  $self->ctx->log->warn("no matching type for $accept") unless $matched_content_type;
  $self->ctx->detach_error(406, +{error=>"Requested not acceptable."}) unless $matched_content_type;
  $self->ctx->log->debug( "Content-Type: $content_type, Matched: $matched_content_type") if $self->ctx->debug;

  my $view = $self->_view_from_parts($matched_content_type, $action_namepart);
  return $view;
}

sub _view_from_parts {
  my ($self, @view_parts) = @_;
  my $view = join('::', @view_parts);
  $self->ctx->log->debug("Negotiated View: $view") if $self->ctx->debug;
  return $view;
}

has '_content_negotiation' => (is => 'ro', required=>1);

sub process_component_args {
  my ($class, $app, $args) = @_;

  my $n = HTTP::Headers::ActionPack->new->get_content_negotiator;
  my %content_prefixes = %{ delete($args->{content_prefixes}) || +{} };
  my @content_types = map { @$_ } values %content_prefixes;
  my %content_types_to_prefixes = map {
    my $prefix = $_; 
    map {
      $_ => $prefix
    } @{$content_prefixes{$prefix}}
  } keys %content_prefixes;

  return +{
    %$args,
    _content_negotiation => +{
      content_prefixes => \%content_prefixes,
      content_types_to_prefixes => \%content_types_to_prefixes,
      content_types => \@content_types,
      negotiator => $n,
    },
  };
}

our %content_prefixes = (
  'HTML' => ['application/xhtml+xml', 'text/html'],
  'JSON' => ['application/json'],
  'XML' => ['application/xml', 'text/xml'],
  'JS' => ['application/javascript', 'text/javascript'],
);

__PACKAGE__->config(
  content_prefixes => \%content_prefixes,
);

__PACKAGE__->meta->make_immutable;