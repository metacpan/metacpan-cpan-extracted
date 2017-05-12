package WWW::Hashbang::Pastebin::Schema;
use strict;
use warnings;
use base qw(DBIx::Class::Schema);
our $VERSION = '0.004'; # VERSION
# ABSTRACT: Database schema for WWW::Hashbang::Pastebin

__PACKAGE__->load_namespaces();

1;

__END__
=pod

=encoding utf-8

=head1 NAME

WWW::Hashbang::Pastebin::Schema - Database schema for WWW::Hashbang::Pastebin

=head1 VERSION

version 0.004

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/WWW-Hashbang-Pastebin/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/WWW::Hashbang::Pastebin/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/WWW-Hashbang-Pastebin>
and may be cloned from L<git://github.com/doherty/WWW-Hashbang-Pastebin.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/WWW-Hashbang-Pastebin/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

