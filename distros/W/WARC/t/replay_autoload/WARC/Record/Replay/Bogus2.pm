package WARC::Record::Replay::Bogus2;				# -*- CPerl -*-

use strict;
use warnings;

=for autoload
[WARC::Record::Replay]
field(Content-Type)=^test/bogus

=cut

our $Loaded = 1;

1;
__END__

=head1 NAME

WARC::Record::Replay::Bogus2 - sample extension point for testing

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

This is a dummy module for testing extension autoloading.  This module
matches for autoloading, but does not actually register a handler.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
