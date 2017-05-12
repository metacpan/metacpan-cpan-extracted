package WebService::Cmis::Property::Integer;

=head1 NAME

WebService::Cmis::Property::Integer

Representation of a propertyInteger of a cmis object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use WebService::Cmis::Property ();
use POSIX ();
our @ISA = qw(WebService::Cmis::Property);

=head1 METHODS

=over 4

=item parse($string) -> $integer

convert the given string into integer

=cut

sub parse {
  return int(POSIX::strtol($_[1]||''));
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
