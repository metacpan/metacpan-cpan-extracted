package Time::Elapsed::Lang::EN;
$Time::Elapsed::Lang::EN::VERSION = '0.33';
use strict;
use warnings;
use utf8;

sub singular {
   return qw/
   second  second
   minute  minute
   hour    hour
   day     day
   week    week
   month   month
   year    year
   /
}

sub plural {
   return qw/
   second  seconds
   minute  minutes
   hour    hours
   day     days
   week    weeks
   month   months
   year    years
   /
}

sub other {
   return qw/
   and     and
   ago     ago
   /,
   zero => q{zero seconds},
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Elapsed::Lang::EN

=head1 VERSION

version 0.33

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Time::Elapsed::Lang::EN - English language file.

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
