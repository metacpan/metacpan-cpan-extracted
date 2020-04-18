package WARC::Record::Replay::Test1;				# -*- CPerl -*-

use strict;
use warnings;

=for autoload
[WARC::Record::Replay]
field(Content-Type)=^test/type-1

=cut

our $Loaded = 1;

require WARC::Record::Replay;

WARC::Record::Replay::register { $_->field('Content-Type') eq 'test/type-1' }
  sub { 'type-1' };

1;
__END__

=head1 NAME

WARC::Record::Replay::Test1 - sample extension point for testing

=head1 SYNOPSIS

  ...

=head1 DESCRIPTION

This is a dummy module for testing extension autoloading.

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
