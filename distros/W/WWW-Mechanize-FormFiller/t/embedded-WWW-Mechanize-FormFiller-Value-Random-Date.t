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

my $Original_File = 'lib/WWW/Mechanize/FormFiller/Value/Random/Date.pm';

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

  # Check for module WWW::Mechanize::FormFiller::Value::Random::Date
  eval { require WWW::Mechanize::FormFiller::Value::Random::Date };
  skip "Need module WWW::Mechanize::FormFiller::Value::Random::Date to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 56 lib/WWW/Mechanize/FormFiller/Value/Random/Date.pm

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random::Date;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "born"

  my $born = WWW::Mechanize::FormFiller::Value::Random::Date->new(
    born => string => '%Y%m%d', min => '20000101', max => '20373112' );
  $f->add_value( born => $born );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $last_here = $f->add_filler( last_here => Random::Date => string => '%H%M%S', min => '000000', max => 'now');




;

  }
};
is($@, '', "example from line 56");

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

  # Check for module WWW::Mechanize::FormFiller::Value::Random::Date
  eval { require WWW::Mechanize::FormFiller::Value::Random::Date };
  skip "Need module WWW::Mechanize::FormFiller::Value::Random::Date to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 56 lib/WWW/Mechanize/FormFiller/Value/Random/Date.pm

  use WWW::Mechanize::FormFiller;
  use WWW::Mechanize::FormFiller::Value::Random::Date;

  my $f = WWW::Mechanize::FormFiller->new();

  # Create a random value for the HTML field "born"

  my $born = WWW::Mechanize::FormFiller::Value::Random::Date->new(
    born => string => '%Y%m%d', min => '20000101', max => '20373112' );
  $f->add_value( born => $born );

  # Alternatively take the following shorthand, which adds the
  # field to the list as well :

  # If there is no password, put a random one out of the list there
  my $last_here = $f->add_filler( last_here => Random::Date => string => '%H%M%S', min => '000000', max => 'now');




  require HTML::Form;
  my $form = HTML::Form->parse('<html><body><form method=get action=/>
  <input type=text name=born />
  <input type=text name=last_here />
  </form></body></html>','http://www.example.com/');
  $f->fill_form($form);
  like( $form->value('born'), qr/^(\d{8})$/, "born gets set");
  like( $form->value('last_here'), qr/^(\d{6})$/, "last_here gets set");

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
