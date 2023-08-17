package Example::View::JS;

use Moo;
use Example::Syntax;
extends 'Catalyst::View::MojoTemplate::PerContext';

__PACKAGE__->config(
  content_type => 'application/javascript',
  file_extension => 'js'
);

__DATA__
% my ($self) = @_;
