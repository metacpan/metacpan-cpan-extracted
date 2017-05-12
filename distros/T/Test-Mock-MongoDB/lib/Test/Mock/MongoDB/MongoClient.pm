package Test::Mock::MongoDB::MongoClient;

use strict;
use warnings;

require Test::Mock::Signature;
our @ISA = qw(Test::Mock::Signature);

our $CLASS = qw( MongoDB::MongoClient );

sub init {
    my $mock = shift;
    return if exists $mock->{'skip_init'};

    $mock->method('new')->callback(
        sub {
            return bless({}, 'MongoDB::MongoClient')
        }
    );

    $mock->method('get_database')->callback(
        sub {
            return bless({}, 'MongoDB::Database')
        }
    );
}

42;

__END__

=head1 NAME

Test::Mock::MongoDB::MongoClient - mock module for MongoDB::MongoClient class.

=head1 SYNOPSIS

You can get test mock object like so:

    use Test::Mock::MongoDB qw( any );

    my $mock         = Test::Mock::MongoDB->new;
    my $m_client     = $mock->get_client;

=head1 DESCRIPTION

Current module mocks MongoDB::MongoClient class.

=head1 METHODS

=head2 init()

By default mocks methods C<new()> and C<get_database()>. Or skips this method
if C<skip_init> passed as true.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

L<Test::Mock::MongoDB>

=cut
