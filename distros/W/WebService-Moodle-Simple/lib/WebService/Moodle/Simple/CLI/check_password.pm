package WebService::Moodle::Simple::CLI::check_password;
$WebService::Moodle::Simple::CLI::check_password::VERSION = '0.06';
use strict;
use warnings;
use Data::Dump 'pp';
use feature 'say';
use WebService::Moodle::Simple;

# ABSTRACT: moodle check_password method

sub run {
  my $opts = shift;
  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->check_password(
    password  => $opts->{password},
    username  => $opts->{username},
  );

  say pp($resp);

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Moodle::Simple::CLI::check_password - moodle check_password method

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Solomon

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Copyright 2014- Andrew Solomon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
