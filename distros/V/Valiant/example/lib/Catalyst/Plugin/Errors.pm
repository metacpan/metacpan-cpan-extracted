package Catalyst::Plugin::Errors;

use Moose;
use MRO::Compat;
use HTTP::Headers::ActionPack;
use Catalyst::Utils;

our $VERSION = '0.001';
our %DEFAULT_ERROR_VIEWS = (
  'text/html'   => 'View::Errors::HTML',
  'text/plain'  => 'View::Errors::Text',
  'application/json' => 'View::Errors::JSON',
);

my $cn = HTTP::Headers::ActionPack->new->get_content_negotiator;
my %views = %DEFAULT_ERROR_VIEWS;
my @accepted = ();
my $default_media_type = 'text/plain';

my $normalize_args = sub {
  my $c = shift;
  my %args = (ref($_[0])||'') eq 'HASH' ? %{$_[0]} : @_;
  return %args;
};

sub finalize_error_args {
  my ($c, $code, %args) = @_;
  return (
    template => $code,
    uri => $c->req->uri,
    %args );
}
 
sub setup {
  my $app = shift;
  my $ret = $app->maybe::next::method(@_);
  my $config = $app->config->{'Plugin::Error'};

  %views = %{$config->{views}} if $config->{views};
  $default_media_type = $config->{default_media_type} if $config->{views};
  @accepted = keys %views;

  return $ret;
}

sub setup_components {
  my ($app, @args) = @_;
  my $ret = $app->maybe::next::method(@_);

  my $namespace = "${app}::View::Errors";
  my %views_we_have = map { Catalyst::Utils::class2classsuffix($_) => 1 }
    grep { m/$namespace/ }
    keys %{ $app->components };

  foreach my $view_needed (values %views) {
    next if $views_we_have{$view_needed};
    $app->log->debug("Injecting Catalyst::${view_needed}") if $app->debug;
    Catalyst::Utils::ensure_class_loaded("Catalyst::${view_needed}");
    Catalyst::Utils::inject_component(
      into => $app,
      component => "Catalyst::${view_needed}",
      as => $view_needed );
  }

  return $ret;
}

sub dispatch_error_code {
  my ($c, $code, @args) = @_;

  my %args = $c->finalize_error_args($code, $c->$normalize_args(@args));
  my $chosen_media_type = $cn->choose_media_type(\@accepted, $c->request->header('Accept')) ||  $default_media_type;
  my $chosen_view = $views{$chosen_media_type};
  my $view_obj = $c->view($chosen_view);

  $c->stash(%args);

  if(my $sub = $view_obj->can("http_${code}")) {
    $view_obj->sub($c, %args);
  } elsif($view_obj->can('http_default')) {
    $view_obj->http_default($c, $code, %args);
  } else {
    $c->forward($view_obj);
  }
}

sub detach_error_code {
  my $c = shift;
  $c->dispatch_error_code(@_);
  $c->detach;
}

__PACKAGE__->meta->make_immutable;
