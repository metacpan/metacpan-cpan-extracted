package WARC::Index::File::SDBM::Entry;				# -*- CPerl -*-

use strict;
use warnings;

require WARC::Index::Entry;
our @ISA = qw(WARC::Index::Entry);

require WARC; *WARC::Index::File::SDBM::Entry::VERSION = \$WARC::VERSION;

=head1 NAME

WARC::Index::File::SDBM::Entry - SDBM WARC index entries

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=cut

1;
__END__

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index::Entry>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
