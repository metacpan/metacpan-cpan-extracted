package Time::Elapsed::Lang::FR;
$Time::Elapsed::Lang::FR::VERSION = '0.33';
use strict;
use warnings;
use utf8;

sub singular {
   return qw/
   second  seconde
   minute  minute
   hour    heure
   day     jour
   week    semaine
   month   mois
   year    an
   /
}

sub plural {
   return qw/
   second  secondes
   minute  minutes
   hour    heures
   day     jours
   week    semaines
   month   mois
   year    ans
   /
}

sub other {
   return qw/
   and     et
   /,
   zero => q{zéro seconde},
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Elapsed::Lang::FR

=head1 VERSION

version 0.33

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Time::Elapsed::Lang::FR - French language file.

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
