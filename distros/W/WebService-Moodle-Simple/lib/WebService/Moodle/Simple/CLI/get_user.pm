package WebService::Moodle::Simple::CLI::get_user;
$WebService::Moodle::Simple::CLI::get_user::VERSION = '0.06';
use strict;
use warnings;
use Data::Dump 'pp';
use feature 'say';
use WebService::Moodle::Simple;

# ABSTRACT: moodlews get_user method

sub run {
  my $opts = shift;
  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->get_user(
    username  => $opts->{username},
  );

  say pp($resp);

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Moodle::Simple::CLI::get_user - moodlews get_user method

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Solomon

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Copyright 2014- Andrew Solomon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
