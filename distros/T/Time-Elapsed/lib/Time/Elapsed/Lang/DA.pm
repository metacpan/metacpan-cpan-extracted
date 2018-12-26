package Time::Elapsed::Lang::DA;
$Time::Elapsed::Lang::DA::VERSION = '0.33';
use strict;
use warnings;
use utf8;

sub singular {
   return qw/
   second  sekund
   minute  minut
   hour    time
   day     dag
   week    uge
   month   måned
   year    år
   /
}

sub plural {
   return qw/
   second  sekunder
   minute  minutter
   hour    timer
   day     dage
   week    uger
   month   måneder
   year    år
   /
}

sub other {
   return qw/
   and    og
   since  siden
   /,
   zero => q{nul sekunder},
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Elapsed::Lang::DA

=head1 VERSION

version 0.33

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Time::Elapsed::Lang::DA - Danish language file.

=head1 METHODS

=head2 singular

=head2 plural

=head2 other

=head1 SEE ALSO

L<Time::Elapsed>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
