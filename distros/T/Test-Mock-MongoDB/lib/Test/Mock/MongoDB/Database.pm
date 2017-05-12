package Test::Mock::MongoDB::Database;

use strict;
use warnings;

require Test::Mock::Signature;
our @ISA = qw(Test::Mock::Signature);

our $CLASS = qw( MongoDB::Database );

sub init {
    my $mock = shift;
    return if exists $mock->{'skip_init'};

    $mock->method('get_collection')->callback(
        sub {
            return bless({}, 'MongoDB::Collection')
        }
    );
}

42;

__END__

=head1 NAME

Test::Mock::MongoDB::Database - mock module for MongoDB::Database class.

=head1 SYNOPSIS

You can get test mock object like so:

    use Test::Mock::MongoDB qw( any );

    my $mock         = Test::Mock::MongoDB->new;
    my $m_database   = $mock->get_database;

=head1 DESCRIPTION

Current module mocks MongoDB::Database class.

=head1 METHODS

=head2 init()

By default mocks method C<get_collection()>. Or skips this method if
C<skip_init> passed as true.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

L<Test::Mock::MongoDB>

=cut
