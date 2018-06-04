#
# This file is part of Tie-IxHash-FixedSize
#
# This software is copyright (c) 2018 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package Tie::IxHash::FixedSize;
$Tie::IxHash::FixedSize::VERSION = '1.02';
# ABSTRACT: Tie::IxHash with a fixed maximum size

use 5.008;
use strict;
use warnings;
use parent 'Tie::IxHash';

# location of size field in @$self. Tie::IxHash uses 0-3
use constant SIZE_IX => 4;

sub TIEHASH {
    my $class = shift;
    my $conf = shift if ref $_[0] eq 'HASH';

    $conf ||= {};

    my $self = $class->SUPER::TIEHASH(@_);

    if ($conf->{size}) {
        $self->[SIZE_IX] = $conf->{size};
    }

    return $self;
}

sub STORE {
    my $self = shift;

    $self->SUPER::STORE(@_);

    if (my $max_size = $self->[SIZE_IX]) {
        while ($self->Keys > $max_size) {
            $self->Shift;
        }
    }
}

1;

__END__

=pod

=head1 NAME

Tie::IxHash::FixedSize - Tie::IxHash with a fixed maximum size

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use Tie::IxHash::FixedSize;

  tie my %h, 'Tie::IxHash::FixedSize', {size => 3},
    one   => 1,
    two   => 2,
    three => 3;

  print join ' ', keys %h;   # prints 'one two three'

  $h{four} = 4;  # key 'one' is removed, 'four' is added

  print join ' ', keys %h;   # prints 'two three four'

=head1 DESCRIPTION

Hashes tied with Tie::IxHash::FixedSize behave exactly like normal Tie::IxHash
hashes, except the maximum number of keys that can be held by the hash is
limited by a specified C<size>.  Once the number of keys in the hash exceeds
this size, the oldest keys in the hash will automatically be removed.

The C<size> parameter to C<tie()> specifies the maximum number of keys that the
hash can hold. When the hash exceeds this number of keys, the first entries in
the hash will automatically be removed until the number of keys in the hash
does not exceed the size parameter.  If no size parameter is given, then the
hash will behave exactly like a plan Tie::IxHash, and the number of keys will
not be limited.

=head1 SEE ALSO

L<Tie::IxHash>

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/tie-ixhash-fixedsize>
and may be cloned from L<git://https://github.com/mschout/tie-ixhash-fixedsize.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/tie-ixhash-fixedsize/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
