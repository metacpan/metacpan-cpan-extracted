#!/opt/perl58/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'lib/WWW/Mechanize/FormFiller/Value/Random.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module WWW::Mechanize::FormFiller
  eval { require WWW::Mechanize::FormFiller };
  skip "Need module WWW::Mechanize::FormFiller to run this test", 1
    if $@;

  # Check for module WWW::Mechanize::FormFiller::Value::Random
  eval { require WWW::Mechanize::FormFiller::Value::Random };
  skip "Need module WWW::Mechanize::FormFiller::Value::Random to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 40 lib/WWW/Mechanize/FormFiller/Value/Random.pm

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "login"

  my $login = WWW::Mechanize::FormFiller::Value::Random->new( login => "root","administrator","corion" );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $password = $f->add_filler( password => Random => "foo","bar","baz" );




;

  }
};
is($@, '', "example from line 40");

};
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Form
  eval { require HTML::Form };
  skip "Need module HTML::Form to run this test", 1
    if $@;

  # Check for module WWW::Mechanize::FormFiller
  eval { require WWW::Mechanize::FormFiller };
  skip "Need module WWW::Mechanize::FormFiller to run this test", 1
    if $@;

  # Check for module WWW::Mechanize::FormFiller::Value::Random
  eval { require WWW::Mechanize::FormFiller::Value::Random };
  skip "Need module WWW::Mechanize::FormFiller::Value::Random to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 40 lib/WWW/Mechanize/FormFiller/Value/Random.pm

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "login"

  my $login = WWW::Mechanize::FormFiller::Value::Random->new( login => "root","administrator","corion" );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $password = $f->add_filler( password => Random => "foo","bar","baz" );




  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login />
  <input type=text name=password />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  like( $form->value('login'), qr/^(root|administrator|corion)$/, "Login gets set");
  like( $form->value('password'), qr/^(foo|bar|baz)$/, "Password gets set");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
