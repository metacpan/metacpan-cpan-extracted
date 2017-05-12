use strict;
use Test::More;

use vars qw(%modules);
BEGIN {
  $modules{pureperl} = \&run_pureperl;
  eval { require XML::XPath; $XML::XPath::VERSION >= 1.13 and $modules{xpath} = \&run_xpath };
  eval { require XML::LibXML; $modules{libxml} = \&run_libxml };
};

sub main::runtests {
  my ($count,$code) = @_;
  my @candidates = (sort keys %modules);

  plan( tests => 1+ $count * scalar @candidates );
  use_ok('Test::HTML::Content');

  for my $implementation (@candidates) {
    my $test = $modules{$implementation};
    $test->($count,$code);
  };
};

sub run_libxml {
  my ($count,$code) = @_;
  Test::HTML::Content::install_libxml();
  $code->('XML::LibXML');
};

sub run_xpath {
  my ($count,$code) = @_;
  Test::HTML::Content::install_xpath();
  $code->('XML::XPath');
};

sub run_pureperl {
  my ($count,$code) = @_;
  Test::HTML::Content::install_pureperl();
  $code->('PurePerl');
};

1;
