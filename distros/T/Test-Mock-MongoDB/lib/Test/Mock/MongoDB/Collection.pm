package Test::Mock::MongoDB::Collection;

use strict;
use warnings;

require Test::Mock::Signature;
our @ISA = qw(Test::Mock::Signature);

our $CLASS = qw( MongoDB::Collection );

sub init {
    my $mock = shift;
    return if exists $mock->{'skip_init'};

    $mock->method('get_collection')->callback(
        sub {
            return bless({}, 'MongoDB::Collection')
        }
    );

    $mock->method('find')->callback(
        sub {
            return bless({}, 'MongoDB::Cursor')
        }
    );
}

42;

__END__

=head1 NAME

Test::Mock::MongoDB::Collection - mock module for MongoDB::Collection class.

=head1 SYNOPSIS

You can get test mock object like so:

    use Test::Mock::MongoDB qw( any );

    my $mock         = Test::Mock::MongoDB->new;
    my $m_collection = $mock->get_collection;

=head1 DESCRIPTION

Current module mocks MongoDB::Collection class.

=head1 METHODS

=head2 init()

By default mocks methods C<get_collection()> and C<find()>. Or skips this
method if C<skip_init> passed as true.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

L<Test::Mock::MongoDB>

=cut
