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

my $Original_File = 'lib/WWW/Mechanize/FormFiller/Value/Default.pm';

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

  # Check for module WWW::Mechanize::FormFiller::Value::Default
  eval { require WWW::Mechanize::FormFiller::Value::Default };
  skip "Need module WWW::Mechanize::FormFiller::Value::Default to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 32 lib/WWW/Mechanize/FormFiller/Value/Default.pm

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Default;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a default value for the HTML field "login"
  # This will put "Corion" into the login field unless
  # there already is some other text.
  my $login = WWW::Mechanize::FormFiller::Value::Default->new( login => "Corion" );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # "If there is no password, put 'secret' there"
  my $password = $f->add_filler( password => Default => "secret" );




;

  }
};
is($@, '', "example from line 32");

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

  # Check for module WWW::Mechanize::FormFiller::Value::Default
  eval { require WWW::Mechanize::FormFiller::Value::Default };
  skip "Need module WWW::Mechanize::FormFiller::Value::Default to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 32 lib/WWW/Mechanize/FormFiller/Value/Default.pm

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Default;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a default value for the HTML field "login"
  # This will put "Corion" into the login field unless
  # there already is some other text.
  my $login = WWW::Mechanize::FormFiller::Value::Default->new( login => "Corion" );
  $f->add_value( login => $login );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # "If there is no password, put 'secret' there"
  my $password = $f->add_filler( password => Default => "secret" );




  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login />
  <input type=text name=password />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  is( $form->value('login'), "Corion", "Login gets set");
  is( $form->value('password'), "secret", "Password gets set");
  $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=login value=Test />
  <input type=text name=password value=geheim />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  is( $form->value('login'), "Test", "Login gets not overwritten");
  is( $form->value('password'), "geheim", "Password gets not overwritten");

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
