package WWW::Mechanize::FormFiller::Value::Random::Chars;
use base 'WWW::Mechanize::FormFiller::Value';
use strict;

use vars qw( $VERSION );
use Data::Random qw(rand_chars);
$VERSION = '0.12';

sub new {
  my ($class,$name,@args) = @_;
  my $self = $class->SUPER::new($name);
  @args = (set => 'alpha', min => 5, max => 8) unless scalar @args;
  $self->{args} = [ @args ];
  $self;
};

sub value {
  my ($self,$input) = @_;
  join "", (rand_chars( @{$self->{args}} ));
};

1;

__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value::Random::Chars - Fill characters into an HTML form field

=head1 SYNOPSIS

=for example begin

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random::Chars;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "login"

  my $login = WWW::Mechanize::FormFiller::Value::Random::Chars->new(
                       login => set => 'alpha', min => 3, max => 8 );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $password = $f->add_filler( password => 'Random::Chars' );

=for example end

=for example_testing
  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login />
  <input type=text name=password />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  like( $form->value('login'), qr/^([a-zA-Z]+)$/, "Login gets set");
  like( $form->value('password'), qr/^([a-zA-Z]+)$/, "Password gets set");

=head1 DESCRIPTION

This class provides a way to write a randomly chosen value into a HTML field.

=over 4

=item new NAME, LIST

Creates a new value which will correspond to the HTML field C<NAME>. The C<LIST>
is the list of arguments passed to Data::Random::rand_chars. If the list is
empty, C<< set => 'alpha', min => 5, max => 8 >> is assumed.

=item name [NEWNAME]

Gets and sets the name of the HTML field this value corresponds to.

=item value FIELD

Returns the value to put into the HTML field.

=back

=head2 EXPORT

None by default.

=head2 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2002,2003 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

=head1 SEE ALSO

L<Data::Random>,
L<WWW::Mechanize>, L<WWW::Mechanize::Shell>, L<WWW::Mechanize::FormFiller>, L<WWW::Mechanize::FormFiller::Value::Value>,
L<WWW::Mechanize::FormFiller::Value::Default>, L<WWW::Mechanize::FormFiller::Value::Fixed>, L<WWW::Mechanize::FormFiller::Value::Interactive>
