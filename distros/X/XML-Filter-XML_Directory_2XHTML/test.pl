#!/usr/local/bin/perl
use strict;

package MySAX;
use base qw (XML::SAX::Base);

sub parse_uri {
  my $self = shift;
  print STDERR "Package ".__PACKAGE__." is parsing $_[0]\n";
  return 1;
}

package main;

BEGIN { $| = 1; print "1..3\n"; }

use XML::SAX::Writer;

use XML::Directory::SAX;
use XML::Filter::XML_Directory_2XHTML;

my $output = "";
my $writer = undef;
my $filter = undef;

if (&t3(&t2(&t1()))) {
  print "Passed all tests\n";
  print $output,"\n";
}

sub t1 {

  $writer = XML::SAX::Writer->new(Output=>\$output);

  if (! $writer) {
    print "Failed to create XML::SAX::Writer object, $!\n";
    print "not ok 1\n";
    return 0;
  }

  $filter = XML::Filter::XML_Directory_2XHTML->new(Handler=>$writer);

  if (! $filter) {
    print "Failed to create XML::Filter::XML_Directory_2XHTML object, $!\n";
    print "not ok 1\n";
    return 0;
  }

  print "ok 1\n";
  return 1;
}

sub t2 {
  my $last = shift;

  if (! $last) {
    print "not ok 2\n";
    return 0;
  }

  if (! $filter->set_callbacks({
				link  => sub { return "file://".$_[0]; },
				title => sub { return "woot woot woot"; },
			       })) {
    print "not ok 2\n";
    return 0;
  }
  
  my $handler = MySAX->new(Handler=>$writer);

  if (! $filter->set_handlers({file => $handler})) {
    print "not ok 2\n";
    return 0;
  }

  $filter->set_lang("en-uk");

  if (! $filter->set_images({
			     directory   => {src=>"/icons/dir.gif",height=>20,width=>20},
			     application => {src=>"/icons/generic.gif",height=>20,width=>20},
			     file        => {src=>"/icons/image3.gif",height=>20,width=>20},
			    })) {
    print "not ok 2\n";
    return 0;
  }

  if (! $filter->exclude(exclude=>["CVS"],ending=>["~"])) {
    print "no ok 2\n";
    return 0;
  }

  print "ok 2\n";
  return 1;
}

sub t3 {
  my $last = shift;

  if (! $last) {
    print "not ok 3\n";
    return 0;
  }

  my $directory = XML::Directory::SAX->new(depth=>1,detail=>2,Handler=>$filter);

  if (! $directory) {
    print "Failed to create XML::Directory::SAX object, $!\n";
    print "not ok 3\n";
    return 0;
  }

  $directory->order_by("a");
  eval { $directory->parse_dir($INC[$#INC]); };
 
  if ($@) {
    print $@;
    print "not ok 3\n";
    return 0;
  }

  print "ok 3\n";
  return 1;
}
