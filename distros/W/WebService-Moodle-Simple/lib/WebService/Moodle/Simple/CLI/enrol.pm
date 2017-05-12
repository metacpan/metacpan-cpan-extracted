package WebService::Moodle::Simple::CLI::enrol;

use strict;
use warnings;
use Data::Dumper;
use feature 'say';
use WebService::Moodle::Simple;


sub run {
  my $opts = shift;
  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->enrol_student(
    token     => $opts->{token},
    username  => $opts->{username},
    course => $opts->{course},
  );

  say Dumper $resp;

}


1;
