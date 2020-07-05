package Translate::Fluent::Elements::BlockText;

use Moo;
extends 'Translate::Fluent::Elements::Base';

has text => (
  is  => 'ro',
  default => sub { undef },
);


around BUILDARGS => sub {
  my ($orig, $class, %args) = @_;

  my $text = ($args{indented_char}//'').($args{inline_text}//'');

  $class->$orig( text => $text );
};

sub translate {
  return "\n".$_[0]->text;
}

1;

__END__

=head1 NOTHING TO SEE HERE

This file is part of L<Translate::Fluent>. See its documentation for more
information.

=head2 translate

This package implements a translate method, but is not that interesting;

=cut

