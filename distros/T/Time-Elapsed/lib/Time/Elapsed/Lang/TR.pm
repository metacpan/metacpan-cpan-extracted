package Time::Elapsed::Lang::TR;
$Time::Elapsed::Lang::TR::VERSION = '0.33';
use strict;
use warnings;
use vars qw( $VERSION        );
use subs qw( singular plural );
use utf8;

*plural = \&singular;

sub singular {
   return qw/
   second  saniye
   minute  dakika
   hour    saat
   day     gün
   week    hafta
   month   ay
   year    yıl
   /
}

sub other {
   return qw/
   and     ve
   ago     önce
   /,
   zero => q{sıfır saniye},
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Elapsed::Lang::TR

=head1 VERSION

version 0.33

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Time::Elapsed::Lang::TR - Turkish language file.

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
