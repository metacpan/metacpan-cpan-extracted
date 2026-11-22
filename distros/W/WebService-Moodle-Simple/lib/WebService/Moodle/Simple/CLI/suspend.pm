package WebService::Moodle::Simple::CLI::suspend;
$WebService::Moodle::Simple::CLI::suspend::VERSION = '0.07';
use strict;
use warnings;
use Data::Dump 'pp';
use feature 'say';
use WebService::Moodle::Simple;

# ABSTRACT: moodlews suspend method

sub run {
  my $opts = shift;
  my $moodle = WebService::Moodle::Simple->new( %$opts );

  my $resp = $moodle->suspend_user(
    username  => $opts->{username},
    suspend   => $opts->{undo} ? 0 : 1,
  );

  say pp($resp);

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Moodle::Simple::CLI::suspend - moodlews suspend method

=head1 VERSION

version 0.07

=head1 AUTHOR

Andrew Solomon <andrew@geekuni.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Andrew Solomon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
