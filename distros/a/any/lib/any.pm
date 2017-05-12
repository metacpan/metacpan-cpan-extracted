package any;

use strict;
use warnings;

use Carp;
use version;our $VERSION = qv('0.0.1');

our @module;
our $failed = {};

sub import {
    shift;
    local $UNIVERSAL::Level = $UNIVERSAL::Level + 1; 
    local $Carp::CarpLevel  = $Carp::CarpLevel  + 1;

    my @flags = map { $_ if $_ ne '-croak' } grep(/^-/, @_);
    @module = ();
    $failed = {};
    
    for my $mod (grep(!/^-/, @_)) {
        use first $mod, @flags;   
        push @module, $first::module if $first::module;
        $failed->{ $mod } = $first::failed->{ $mod } if exists $first::failed->{ $mod };
    }
}

1;

__END__

=head1 NAME

any - use any modules in the list that are available

=head1 SYNOPSIS

  use any 'Foo', 'Bar', 'Baz';

=head1 DESCRIPTION

Given a list of modules (see L<first> for what arguments it can take, ignores '-croak') it attempts to load each one.

The successful ones are in @any::module and the failed ones are in the $any::failed hashref which is the same as $first::failed

=head1 SEE ALSO

L<first>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut