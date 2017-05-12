package Tie::IxHash::FixedSize;

use 5.006;
use strict;
use base 'Tie::IxHash';

our $VERSION = '1.01';

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

=head1 NAME

Tie::IxHash::FixedSize - Tie::IxHash with a fixed maximum size

=head1 SYNOPSIS

  use Tie::IxHash::FixedSize;

  tie my %h, 'Tie::IxHash::FixedSize', {size => 3},
    one   => 1,
    two   => 2,
    three => 3;

  print join ' ', keys %h;   # prints 'one two three'

  $h{four} = 4;  # key 'one' is removed, 'four' is added

  print join ' ', keys %h;   # prints 'two three four'

=head1 ABSTRACT

Hashes tied to Tie::IxHash::FixedSize will only hold a fixed maximum number of
keys before automatically removing old keys.

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

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/tie-ixhash-fixedsize

 git clone git://github.com/mschout/tie-ixhash-fixedsize.git

=head1 BUGS

Please report any bugs or feature requests to
bug-tie-ixhash-fixedsize@rt.cpan.org, or through the web interface at
http://rt.cpan.org/.

=head1 AUTHOR

Michael Schout E<lt>mschout@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Michael Schout

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

=head1 SEE ALSO

L<Tie::IxHash>

