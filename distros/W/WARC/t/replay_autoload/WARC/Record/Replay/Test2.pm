package WARC::Record::Replay::Test2;				# -*- CPerl -*-

use strict;
use warnings;

=for autoload
[Acme::Something::Else]
test=abc def
[WARC::Record::Replay]
field(Content-Type)=^test/type-2
[Acme::Something::Else::Other]
test(foo)=bar baz

=cut

our $Loaded = 1;

require WARC::Record::Replay;

WARC::Record::Replay::register { $_->field('Content-Type') eq 'test/type-2' }
  sub { 'type-2' };

1;
__END__

=head1 NAME

WARC::Record::Replay::Test2 - sample extension point for testing

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
