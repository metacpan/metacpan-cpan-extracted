package Test::Mock::MongoDB::Cursor;

use strict;
use warnings;

require Test::Mock::Signature;
our @ISA = qw(Test::Mock::Signature);

our $CLASS = qw( MongoDB::Cursor );

42;

__END__

=head1 NAME

Test::Mock::MongoDB::Cursor - mock module for MongoDB::Cursor class.

=head1 SYNOPSIS

You can get test mock object like so:

    use Test::Mock::MongoDB qw( any );

    my $mock         = Test::Mock::MongoDB->new;
    my $m_cursor     = $mock->get_cursor;

=head1 DESCRIPTION

Current module mocks MongoDB::Cursor class.

=head1 METHODS

No methods defined at the moment.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

L<Test::Mock::MongoDB>

=cut
