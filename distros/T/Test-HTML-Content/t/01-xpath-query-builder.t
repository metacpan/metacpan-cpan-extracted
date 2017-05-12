#!/usr/bin/perl -w
use strict;
use Test::More;
use lib 't';
use testlib;

# This test file tests the generation of the XPath queries
# The XPath queries have to work for both, XML::XPath
# and XML::LibXML, so not all features of XML::XPath
# can be used ...

my (@cases);
BEGIN {
  @cases=(
  [ tag => {href => 'http://www.perl.com', alt =>"foo"} => '//tag[@alt = "foo" and @href = "http://www.perl.com"]' ],
  [ tag => {href => qr'http://', alt =>"foo"} => '//tag[@alt = "foo" and @href]' ],
  [ tag => {href => qr'http://', alt => undef} => '//tag[not(@alt) and @href]' ],
  [ tag2 => {href => qr'http://', alt => undef} => '//tag2[not(@alt) and @href]' ],
  );
  # plan( tests => scalar @cases +1 );
};

sub run_case {
  my ($tag,$attr,$result) = @_;
  my ($query,$code) = Test::HTML::Content::__build_xpath_query("//".$tag,$attr);
  is( $query, $result, $query );
};

sub run {
  for my $case (@cases) {
    run_case( @$case );
  };
};

runtests( scalar @cases, \&run );
