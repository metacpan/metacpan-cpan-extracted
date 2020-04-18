package WARC::Record::Replay::Bogus1;				# -*- CPerl -*-

use strict;
use warnings;

=for autoload
[WARC::Record::Replay]
no_such_method(bogus)=bogus

=cut

our $Loaded = 1;

require WARC::Record::Replay;

WARC::Record::Replay::register { $_->field('Content-Type') eq 'test/bogus' }
  sub { 'bogus!' };

1;
__END__

=head1 NAME

WARC::Record::Replay::Bogus1 - sample extension point for testing

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

This is a dummy module for testing extension autoloading.  The autoloading
test causes an exception to be thrown to verify handling exceptions.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
