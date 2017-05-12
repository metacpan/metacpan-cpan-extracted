use strict;

package MySAX;
use base qw (XML::Filter::XML_Directory_2::Base);

sub start_element {
  my $self = shift;
  my $data = shift;

  $self->on_enter_start_element($data)
    || return;

  map { print STDERR " "; } (0..$self->current_level());
  print STDERR "[".$self->current_level()."] $data->{'Name'}\n";

  return 1;
}

sub end_element {
  my $self = shift;
  my $data = shift;

  $self->on_enter_end_element($data);
  $self->on_exit_end_element($data);
}

sub characters {}

package main;

BEGIN { $| = 1; print "1..2\n"; }

use XML::SAX::Writer;
use XML::Directory::SAX;

my $output    = "";
my $writer    = undef;
my $filter    = undef;
my $directory = undef;

if (&t2(&t1())) {
  print "Passed all tests\n";;
}

sub t1 {
  $writer = XML::SAX::Writer->new(Output=>\$output);
  if (! $writer) {
    print "Failed to create XML::SAX::Writer object, $!\n";
    print "not ok 1\n";
  }

  $filter = MySAX->new(Handler=>$writer);

  if (! $filter) {
    print "Failed to create filter object, $!\n";
    print "not ok 1\n";
  }

  $directory = XML::Directory::SAX->new(depth=>1,detail=>2,Handler=>$filter);
  
  if (! $directory) {
    print "Failed to create XML::Directory::SAX object, $!\n";
    print "not ok 1\n";
  }

  print "ok 1\n";
  return 1;
}

sub t2 {
  if (! $_[0]) {
    print "not ok 2\n";
    return 0;
  }
  
  $directory->order_by("a");
  eval { $directory->parse_dir($INC[$#INC]); };

  if ($@) {
    print $@;
    print "not ok 2\n";
    return 0;
  }

  print "ok 2\n";
  return 1;
}
