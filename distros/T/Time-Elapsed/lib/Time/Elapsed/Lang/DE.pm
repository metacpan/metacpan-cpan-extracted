package Time::Elapsed::Lang::DE;
$Time::Elapsed::Lang::DE::VERSION = '0.33';
use strict;
use warnings;
use utf8;

sub singular {
   return qw/
   second  Sekunde
   minute  Minute
   hour    Stunde
   day     Tag
   week    Woche
   month   Monat
   year    Jahr
   /
}

sub plural {
   return qw/
   second  Sekunden
   minute  Minuten
   hour    Stunden
   day     Tage
   week    Wochen
   month   Monate
   year    Jahre
   /
}

sub other {
   return qw/
   and     und
   ago     vor
   /,
   zero => q{Nullsekunden},
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Elapsed::Lang::DE

=head1 VERSION

version 0.33

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Time::Elapsed::Lang::DE - German language file.

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
