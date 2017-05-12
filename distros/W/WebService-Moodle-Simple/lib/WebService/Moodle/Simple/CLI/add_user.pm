package WebService::Moodle::Simple::CLI::add_user;

use strict;
use warnings;
use Data::Dumper;
use feature 'say';
use WebService::Moodle::Simple;


sub run {
  my $opts = shift;

  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->add_user(
    firstname => $opts->{firstname},
    lastname  => $opts->{lastname},
    email     => $opts->{email},
    password  => $opts->{password},
    username  => $opts->{username},
    token     => $opts->{token},
  );

  say Dumper $resp;

}


1;
