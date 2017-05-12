package WWW::Freshmeat::Project::URL;
use Mouse;
use Carp;

our $VERSION = '0.22';

has 'url' => (is => 'rw', isa => 'Str', 'builder'=>'_find_url','lazy'=>1);
has 'label' => (is => 'rw', isa => 'Str',required=>1);
has 'redirector' => (is => 'rw', isa => 'Str');
has 'host' => (is => 'rw', isa => 'Str');
has 'www_freshmeat' => (is => 'rw', isa => 'WWW::Freshmeat',required=>1);

no Mouse;

sub _find_url {
  my $self=shift || die;
  croak "No 'redirector' field" unless $self->redirector;
  my $u=$self->www_freshmeat->redir_url($self->redirector);
  if (substr($u,0,25) eq 'http://freecode.com/urls/') {
    $u=$self->www_freshmeat->redir_url($u);
  }
  return $u;
}

1;
