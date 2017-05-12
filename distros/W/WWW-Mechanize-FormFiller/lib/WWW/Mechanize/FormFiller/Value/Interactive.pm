package WWW::Mechanize::FormFiller::Value::Interactive;
use base 'WWW::Mechanize::FormFiller::Value::Callback';
use strict;

use vars qw( $VERSION );
$VERSION = '0.12';

sub new {
  my ($class,$name) = @_;
  my $self = $class->SUPER::new($name, \&ask_value);

  $self;
};

sub ask_value {
  my ($self,$input) = @_;
  print $input->name,"> ","[",$input->value,"]";
  my $result = <>;
  chomp $result;
  $result = $input->value if $result eq "";
  $result;
};

1;


__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value::Interactive - Ask the user to fill out a HTML form field

=head1 SYNOPSIS

=for example begin

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Interactive;

  my $f = WWW::Mechanize::FormFiller->new();

  # Ask the user for the "login"
  my $login = WWW::Mechanize::FormFiller::Value::Interactive->new( 'login' );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # "Ask the user for the password"
  my $password = $f->add_filler( password => 'Interactive' );

=for example end

=for example_testing
  require HTML::Form;
  BEGIN { no warnings 'redefine'; *WWW::Mechanize::FormFiller::Value::Interactive::ask_value = sub {'fixed'}};
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login value=foo />
  <input type=text name=password value=bar />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  is( $form->value('login'), "fixed", "Login gets set");
  is( $form->value('password'), "fixed", "Password gets set");

=head1 DESCRIPTION

This class provides a way to write a value read from STDIN into a HTML field.

=over 4

=item new NAME

Creates a new value which will correspond to the HTML field C<NAME>.

=item name [NEWNAME]

Gets and sets the name of the HTML field this value corresponds to.

=item value FIELD

Returns the value to put into the HTML field. The value will be read from
STDIN. The name of the HTML field to be read and the current value will
be printed to STDOUT. An empty string will use the given default. There
currently is no way to enter an empty string if there is a different
default string.

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

L<WWW::Mechanize>, L<WWW::Mechanize::Shell>, L<WWW::Mechanize::FormFiller>, L<WWW::Mechanize::FormFiller::Value::Value>,
L<WWW::Mechanize::FormFiller::Value::Default>, L<WWW::Mechanize::FormFiller::Value::Random>, L<WWW::Mechanize::FormFiller::Value::Fixed>
