package Valiant::HTML::ContentComponent;

use Moo::Role;
use Valiant::HTML::SafeString 'concat';
use Scalar::Util 'blessed';

with 'Valiant::HTML::BaseComponent';

has content => (is=>'ro', predicate=>'has_content');

sub prepare_render_args {
  my ($self, @args) = @_;
  my $content = $self->expand_content;
  return $content ? ( $content, @args) : @args;
}

sub expand_content {
  my $self = shift;
  return unless $self->has_content;

  local $Valiant::HTML::BaseComponent::SELF = $self;

  my $content = $self->content;
  my @content = ();
  if((ref($content)||'') eq 'CODE') {
    @content = $content->($self->content_args);
  } elsif( ((ref(\$content)||'') eq 'SCALAR') || blessed($content) ) {
    @content = ($content);
  } elsif((ref($content)||'') eq 'ARRAY') {
    @content = @$content;
  }

  return concat map { 
    (blessed($_) && $_->can('render')) ? 
      $_->render : 
      $_
    } @content;
}

sub content_args {
  my $self = shift;
  return $self;
}

1;
