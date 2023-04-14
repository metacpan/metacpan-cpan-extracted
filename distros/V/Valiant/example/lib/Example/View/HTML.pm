package Example::View::HTML;

use Moo;
use Example::Syntax;
use Catalyst::View::Valiant -tags => qw(p);

sub formbuilder_class { 'Example::FormBuilder' }

sub the_time :Renders ($self) {
  return p {class=>'timestamp'}, scalar localtime;
}

__PACKAGE__->meta->make_immutable();

__END__

around 'form_for' => sub {
  my ($orig, $model) = (shift, shift); # required
  my $cb = pop; # required
  my $attrs = shift || +{}; # optional
  $attrs->{builder} ||= 'Example::FormBuilder';
  $orig->($model, $attrs, $cb);
};