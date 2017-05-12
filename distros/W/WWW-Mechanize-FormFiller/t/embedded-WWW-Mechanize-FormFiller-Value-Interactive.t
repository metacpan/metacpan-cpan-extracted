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

my $Original_File = 'lib/WWW/Mechanize/FormFiller/Value/Interactive.pm';

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

  # Check for module WWW::Mechanize::FormFiller::Value::Interactive
  eval { require WWW::Mechanize::FormFiller::Value::Interactive };
  skip "Need module WWW::Mechanize::FormFiller::Value::Interactive to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 36 lib/WWW/Mechanize/FormFiller/Value/Interactive.pm

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




;

  }
};
is($@, '', "example from line 36");

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

  # Check for module WWW::Mechanize::FormFiller::Value::Interactive
  eval { require WWW::Mechanize::FormFiller::Value::Interactive };
  skip "Need module WWW::Mechanize::FormFiller::Value::Interactive to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 36 lib/WWW/Mechanize/FormFiller/Value/Interactive.pm

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




  require HTML::Form;
  BEGIN { no warnings 'redefine'; *WWW::Mechanize::FormFiller::Value::Interactive::ask_value = sub {'fixed'}};
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login value=foo />
  <input type=text name=password value=bar />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  is( $form->value('login'), "fixed", "Login gets set");
  is( $form->value('password'), "fixed", "Password gets set");

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
