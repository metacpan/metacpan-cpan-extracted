package WebService::Moodle::Simple::CLI::get_users;

use strict;
use warnings;
use Data::Dumper;
use feature 'say';
use WebService::Moodle::Simple;


sub run {
  my $opts = shift;
  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->get_users(
    token     => $opts->{token},
  );

  say Dumper $resp;

}


1;
