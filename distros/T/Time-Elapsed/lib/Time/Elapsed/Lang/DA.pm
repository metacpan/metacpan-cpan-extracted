package Time::Elapsed::Lang::DA;
use strict;
use warnings;
use utf8;
use vars qw( $VERSION );

$VERSION = '0.32';

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

=encoding utf8

=head1 NAME

Time::Elapsed::Lang::DA - Danish language file.

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.32> of C<Time::Elapsed::Lang::DA>
released on C<5 July 2016>.

Private module.

=head1 METHODS

=head2 singular

=head2 plural

=head2 other

=head1 SEE ALSO

L<Time::Elapsed>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2007 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
