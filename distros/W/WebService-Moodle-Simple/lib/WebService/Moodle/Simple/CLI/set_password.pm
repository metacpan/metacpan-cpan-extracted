package WebService::Moodle::Simple::CLI::set_password;

use strict;
use warnings;
use Data::Dumper;
use feature 'say';
use WebService::Moodle::Simple;


sub run {
  my $opts = shift;
  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->set_password(
    password  => $opts->{password},
    username  => $opts->{username},
    token     => $opts->{token},
  );

  say Dumper $resp;

}


1;
