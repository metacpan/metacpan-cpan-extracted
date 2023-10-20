package Example::View::JS;

use Moo;
use Example::Syntax;
use Valiant::JSON::Util ();

extends 'Catalyst::View::MojoTemplate::PerContext';

sub escape_javascript($self, $string) {
  return Valiant::JSON::Util::escape_javascript($string);
}

__PACKAGE__->config(
  content_type => 'application/javascript',
  file_extension => 'js'
);

__DATA__
% my ($self) = @_;
