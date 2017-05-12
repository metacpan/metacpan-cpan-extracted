package WWW::Mechanize::FormFiller::Value::Fixed;
use base 'WWW::Mechanize::FormFiller::Value';
use strict;

use vars qw( $VERSION );
$VERSION = '0.12';

sub new {
  my ($class,$name,$value) = @_;
  my $self = $class->SUPER::new($name);
  $self->{value} = $value;

  $self;
};

sub value { $_[0]->{value} };

1;
__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value::Fixed - Fill a fixed value into an HTML form field

=head1 SYNOPSIS

=for example begin

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Fixed;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a fixed value for the HTML field "login"
  my $fixed = WWW::Mechanize::FormFiller::Value::Fixed->new( login => "Corion" );
  $f->add_value( login => $fixed );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :
  my $password = $f->add_filler( password => Fixed => "secret" );

=for example end

=for example_testing
  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login value=foo />
  <input type=text name=password value=bar />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  is( $form->value('login'), "Corion", "Login gets set");
  is( $form->value('password'), "secret", "Password gets set");

=head1 DESCRIPTION

This class provides a way to write a fixed value into a HTML field.

=over 4

=item new NAME, VALUE

Creates a new value which will correspond to the HTML field C<NAME>. The C<VALUE>
is the value to be written into the HTML field.

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

L<WWW::Mechanize>, L<WWW::Mechanize::Shell>, L<WWW::Mechanize::FormFiller>, L<WWW::Mechanize::FormFiller::Value::Value>,
L<WWW::Mechanize::FormFiller::Value::Default>, L<WWW::Mechanize::FormFiller::Value::Random>, L<WWW::Mechanize::FormFiller::Value::Interactive>
