use strict;

package MySAX;
use base qw (XML::SAX::Base);

sub parse_uri {
  my $self = shift;
  $self->SUPER::characters({Data=>"The description handler says hello."});
}

package main;

BEGIN { $| = 1; print "1..4\n"; }

use XML::SAX::Writer;
use XML::Directory::SAX;
use XML::Filter::XML_Directory_2RSS;
use XML::Parser;

my $output = "";
my $writer = undef;
my $rss    = undef;

if (&t4(&t3(&t2(&t1())))) {
  print "Passed all tests\n";
}

sub t1 {
  $writer = XML::SAX::Writer->new(Output=>\$output);

  if (! $writer) {
    print "Failed to create XML::SAX::Writer object, $!\n";
    print "not ok 1\n";
    return 0;
  }

  $rss = XML::Filter::XML_Directory_2RSS->new(Handler=>$writer);

  if (! $writer) {
    print "Failed to create XML::Filer::XML_Directory_2RSS object, $!\n";
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

  $rss->uri("http://foo.com/my_rss_file.xml");

  $rss->generator($0);
  $rss->exclude(exclude=>["auto"]);
  
  $rss->callbacks({link=>\&foo}); 
  $rss->handlers({description=>MySAX->new(Handler=>$writer)});

  $rss->image({title=>"foop",link=>"http://www.foop.com"});

  print "ok 2\n";
  return 1;
}

sub t3 {
  my $last = shift;

  if (! $last) {
    print "not ok 3\n";
    return 0;
  }

  my $directory = XML::Directory::SAX->new(Handler=>$rss,detail=>2,depth=>1);

  if (! $directory) {
    print "Failed to create XML::Directory::SAX object, $!\n";
    print "not ok 3\n";
    return 0;
  }

  $directory->order_by("a");
  eval { $directory->parse_dir($INC[1]); };

  if ($@) {
    print $@,"\n";
    print "not ok 3\n";
    return 0;
  }

  print "ok 3\n";
  return 1;
}

sub t4 {
  my $last = shift;

  if (! $last) {
    print "not ok 4\n";
    return 0;
  }

  my $parser = XML::Parser->new(Style=>"Debug");

  if (! $parser) {
    print "Failed to create XML::Parser object, $!\n";
    print "not ok 4\n";
    return 0;
  }

  eval { $parser->parse($output); };
  
  if ($@) {
    print $@,"\n";
    print "not ok 4\n";
    return 0;
  }

  print "ok 4\n";
  return 1;
}

sub foo{my $link = shift; return "file://$link"; };

