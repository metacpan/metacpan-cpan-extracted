package WWW::Mechanize::FormFiller::Value::Callback;
use base 'WWW::Mechanize::FormFiller::Value';
use strict;

use vars qw( $VERSION );
$VERSION = '0.12';

sub new {
  my ($class,$name,$coderef) = @_;
  my $self = $class->SUPER::new($name);
  
  $self->{callback} = $coderef;

  $self;
};

sub value {
  my ($self,$input) = @_;
  no strict 'refs';
  $self->{callback}->($self,$input);
};

1;

__END__

=head1 NAME

WWW::Mechanize::FormFiller::Value::Callback - Call Perl code to fill out a HTML form field

=head1 SYNOPSIS

=for example begin

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Callback;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a default value for the HTML field "login"
  # This will put the current login name into the login field

  sub find_login {
    getlogin || getpwuid($<) || "Kilroy";
  };

  my $login = WWW::Mechanize::FormFiller::Value::Callback->new( login => \&find_login );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # "If there is no password, put a nice number there
  my $password = $f->add_filler( password => Callback => sub { int rand(90) + 10 } );

=for example end

=for example_testing
  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login />
  <input type=text name=password />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  my $login_str = getlogin || getpwuid($<) || "Kilroy";
  is( $form->value('login'), $login_str, "Login gets set");
  cmp_ok( $form->value('password'), '<', 100, "Password gets set");
  cmp_ok( $form->value('password'), '>', 9, "Password gets set");

=head1 DESCRIPTION

This class provides a way to write a value returned by Perl code into a HTML field.

=over 4

=item new NAME, CODE

Creates a new value which will correspond to the HTML field C<NAME>. The C<CODE>
is a code reference that will return the value to be written into the HTML field.
The code reference will be called with two parameters, the object and the
HTML::Form::Input object.

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

L<WWW::Mechanize>, L<WWW::Mechanize::Shell>, L<WWW::Mechanize::FormFiller>,
L<WWW::Mechanize::FormFiller::Value::Value>,
L<WWW::Mechanize::FormFiller::Value::Default>, L<WWW::Mechanize::FormFiller::Value::Random>,
L<WWW::Mechanize::FormFiller::Value::Interactive>
