package WebService::Moodle::Simple::CLI::login;

use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use WebService::Moodle::Simple;
 
sub run {
  my $opts = shift;

  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->login(
    username  => $opts->{username},
    password  => $opts->{password},
  );

  say Dumper $resp;

}


1;
