use strict;

package MySAX;
use base qw (XML::SAX::Base);

sub start_element {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} =~ /^(file|directory)$/) {
    $self->{'__level'} ++;

    map { print " "; } (0..$self->{'__level'});
    print "$data->{Name} $data->{Attributes}->{'{}name'}->{Value}\n";
  }
}

sub end_element {
  my $self = shift;
  my $data = shift;

  if ($data->{Name} =~ /^(file|directory)$/) {
    $self->{'__level'} --;
  }

}

BEGIN { $| = 1; print "1..4\n"; }

use XML::Directory::SAX;
use XML::Filter::XML_Directory_Pruner;

my $mysax     = undef;
my $pruner    = undef;
my $directory = undef;

my $dir    = $INC[2];
my $depth  = 1;
my $detail = 1;

if (&t4(&t3(&t2(&t1())))) {
  print "Passed all tests\n";
}

sub t1 {
  $mysax = MySAX->new();

  if ($mysax) {
    print "ok 1\n";
    return 1;
  }

  print "not ok 1\n";
  return 0;
}

sub t2 {
  my $last = shift;

  if (! $last) {
    print "not ok 2\n";
    return 0;
  }

  $pruner = XML::Filter::XML_Directory_Pruner->new(Handler=>$mysax);

  if ($pruner) {
    print "ok 2\n";
    return 1;
  }

  print "not ok 2\n";
  return 0;
}

sub t3 {
  my $last = shift;

  if (! $last) {
    print "not ok 3\n";
    return 0;
  }

  $directory = XML::Directory::SAX->new(Handler=>$pruner,detail=>$detail,depth=>$depth);

  if ($directory) {
    print "ok 3\n";
    return 1;
  }

  print "not ok 3\n";
  return 0;

}

sub t4 {
  my $last = shift;

  if (! $last) {
    print "not ok 4\n";
    return 0;
  }

  $pruner->exclude(matching=>"(.*)\\.ph\$");
  $pruner->include(ending=>[".pm"]);

  print "Parsing '$dir'\n";
  my $ok = $directory->parse_dir($dir);

  if ($ok) {
    print "ok 4\n";
    return 1;
  }

  print "not ok 4\n";
  return 0;

}
