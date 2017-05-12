package Unicode::Collate::Standard::V3_1_1;

use strict;
require Exporter;

use vars qw ($VERSION @EXPORT @ISA);
$VERSION = '0.1';
@EXPORT  = qw( &V3_1_1_COLLATION );
@ISA     = qw( Exporter );

use File::Spec;


sub V3_1_1_COLLATION {
    File::Spec->catfile("Standard", "V3_1_1.txt");
}

1;

__END__

=head1 NAME

Unicode::Collate::Standard::V3_1_1 - Thin Perl wrapper to allow easy
installation of the Unicode collation database that Unicode::Collate
uses to sort Unicode data.

=head1 SYNOPSIS

use Unicode::Collate::Standard::V3_1_1;
use Unicode::Collate;

my $col = Unicode::Collate->new(table => V3_1_1_COLLATION);


=head1 DESCRIPTION

Because the C<Unicode::Collate> module does not come with a collation
table (e.g. C<http://www.unicode.org/reports/tr10/allkeys.txt> it will
cause a run-time error unless someone has manually installed the
rules, since C<Unicode::Collate> is part of perl core, it is unlikely
that people will see the message to get that file.

This module allows someone who wishes to use the module to require
that the collation rules for a particular version of Unicode be
installed so that C<Unicode::Collate> does not throw a run time error
because the rules are not present.

=head1 USAGE

By default this module exports the subroutine C<3_1_1_COLLATION> which
gives the relative path to the collation rules for that version of
Unicode.  This is only meaningful to the C<table> argument to
C<Unicode::Collate->new()>.

=head1 AUTHOR

Ben Bennett <fiji at limey dot net>

=head1 COPYRIGHT

Copyright (c) 2003 Ben Bennett.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

Portions of the code in this distribution are derived from other
works.  Please see the CREDITS file for more details.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

perl-unicode@perl.org mailing list C<http://lists.perl.org/showlist.cgi?name=perl-unicode>

=cut
