package Valiant::HTML::FormBuilder::Renderer::TextField;

use Moo;

has field_model => (
  is => 'ro',
  required => 1,
);

has _active => (
  is => 'ro',
  init_arg => 'active',
  required => 1,
  lazy => 1,
  builder => '_build_active',
);

  sub _build_active { return 1 }
  sub active { return shift->_active }

has ['html_attrs', 'options'] => (is=>'ro', required=>1, default=>sub { +{} });

sub type { return 'text' }


sub render {
  my ($self, %args) = @_;
  return unless $elf->active;
  my $html = $self->render_template($html_attrs, ;
}


1;

=head1 NAME

Valiant::HTML::FormBuilder::Model::TextField - An HTML Input Text Model

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO
 
L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

