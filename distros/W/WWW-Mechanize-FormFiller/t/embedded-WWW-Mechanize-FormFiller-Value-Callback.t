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

my $Original_File = 'lib/WWW/Mechanize/FormFiller/Value/Callback.pm';

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

  # Check for module WWW::Mechanize::FormFiller::Value::Callback
  eval { require WWW::Mechanize::FormFiller::Value::Callback };
  skip "Need module WWW::Mechanize::FormFiller::Value::Callback to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 34 lib/WWW/Mechanize/FormFiller/Value/Callback.pm

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




;

  }
};
is($@, '', "example from line 34");

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

  # Check for module WWW::Mechanize::FormFiller::Value::Callback
  eval { require WWW::Mechanize::FormFiller::Value::Callback };
  skip "Need module WWW::Mechanize::FormFiller::Value::Callback to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 34 lib/WWW/Mechanize/FormFiller/Value/Callback.pm

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
