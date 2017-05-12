package WWW::Mechanize::FormFiller::Value::Random::Word;
use base 'WWW::Mechanize::FormFiller::Value';

use vars qw( $VERSION );
use Data::Random qw(rand_words);
$VERSION = '0.12';

sub new {
  my ($class,$name,@args) = @_;
  my $self = $class->SUPER::new($name);
  @args = (size => 1) unless scalar @args;
  $self->{args} = [ @args ];
  $self;
};

sub value {
  my ($self,$input) = @_;
  return join " ", @{rand_words( @{$self->{args}} )};
};

1;

__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value::Random::Word - Fill a word into an HTML form field

=head1 SYNOPSIS

=for example begin

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random::Word;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "login"
  my $login = WWW::Mechanize::FormFiller::Value::Random::Word->new( login => size => 1 );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $password = $f->add_filler( password => Random::Word => size => 1 );

  # Spew some bogus text into the comments field
  my $comments = $f->add_filler( comments => Random::Word => size => 10 );

=for example end

=for example_testing
  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login />
  <input type=text name=password />
  <input type=text name=comments />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  like( $form->value('login'), qr/^(\w+)$/, "Login gets set");
  like( $form->value('password'), qr/^(\w+)$/, "Password gets set");
  my @words = split(" ", $form->value('comments'));
  is( scalar @words, 10, "Comments get set")
    or diag "Words found : ",$form->value('comments');

=head1 DESCRIPTION

This class provides a way to write a randomly chosen value into a HTML field.

=over 4

=item new NAME, LIST

Creates a new value which will correspond to the HTML field C<NAME>. The C<LIST>
is the list of arguments passed to Data::Random::rand_words. If the list is
empty, C<< size => 1 >> is assumed.

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
