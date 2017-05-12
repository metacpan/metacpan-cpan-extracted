package Test::Valgrind::Util;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Util - Utility routines for Test::Valgrind.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This module contains some helpers used by Test::Valgrind.
It is not really designed to be used anywhere else.

=head1 FUNCTIONS

=head2 C<validate_subclass>

    my ($validated_type, $error_msg) = validate_subclass($type);

Try to interpret C<$type> as a subclass of the caller package, and load it if its C<@ISA> is empty.
Returns the validated type, or C<undef> and the relevant error message.

=cut

sub validate_subclass {
 my ($type) = @_;

 my $base = (caller 0)[0];

 $type =~ s/[^A-Za-z0-9_:]//g;
 $type =  "${base}::$type" if $type !~ /::/;

 my $stash = do { no strict 'refs'; \%{"${type}::"} };
 my $ISA   = ($stash && $stash->{ISA}) ? *{$stash->{ISA}}{ARRAY} : undef;

 unless ($ISA and @$ISA >= 1) {
  local $@;
  eval "require $type; 1" or return (undef, "Could not load subclass: $@");
 }

 return (undef, "$type is not a subclass of $base") unless $type->isa($base);

 return $type;
}

=head1 EXPORT

This module does not export anything.

=head1 SEE ALSO

L<Test::Valgrind>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Component

=head1 COPYRIGHT & LICENSE

Copyright 2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Util
