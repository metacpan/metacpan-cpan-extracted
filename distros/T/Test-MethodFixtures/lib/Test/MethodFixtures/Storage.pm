package Test::MethodFixtures::Storage;

use strict;
use warnings;

our $VERSION = '0.08';

use Carp;

use base 'Class::Accessor::Fast';

sub store     { croak "store() not implemented" }
sub retrieve  { croak "retrieve() not implemented" }

1;

__END__

=pod

=head1 NAME

Test::MethodFixtures::Storage - Base class for storage of data for methods mocked with Test::MethodFixtures 

=head1 SYNOPSIS

Subclasses should implement the following interface:

    $storage->store(
        {   method => 'My::Module::mocked_method',
            key    => ...,
            input  => ...,
            output => ...,

            # optional:
            'Test::MethodFixtures' => $version,
            'My::Storage::Class' => $storage_version,

        }
    );

    # should die if nothing stored for that key
    my $stored = $storage->retrieve(
        {   method => 'My::Module::mocked_method',
            key    => ...,
        }
    );

=head1 DESCRIPTION

Base class for storage objects for L<Test::MethodFixtures>

=head1 METHODS

The following methods should be implemented by any subclass.

=head2 store

=head2 retrieve

=cut

