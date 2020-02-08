package Text::VisualPrintf::IO;

use v5.10;
use strict;
use warnings;

use IO::Handle;
use Text::VisualPrintf;

our @EXPORT_OK = qw(printf vprintf);

sub import {
    my $pkg = shift;
    for my $func (@_) {
	unless (grep { $func eq $_ } @EXPORT_OK) {
            require Carp;
            Carp::croak "\"$func\" is not exported";
	}
	no strict 'refs';
	no warnings 'once', 'redefine';
	*{"IO::Handle::$func"} = \&Text::VisualPrintf::printf;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf::IO - IO::Handle interface using Text::VisualPrintf

=head1 SYNOPSIS

    use IO::Handle;
    use Text::VisualPrintf::IO qw(printf vprintf);

    FILEHANDLE->printf(FORMAT, LIST);

=head1 DESCRIPTION

This module (re)define C<printf> and/or C<vprintf> method in
C<IO::Handle> class as C<Text::VisualPrintf::printf> function.  So you
can use these methods from C<IO::File> class or such.

=head1 SEE ALSO

L<Text::VisualPrintf>

L<https://github.com/kaz-utashiro/Text-VisualPrintf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
