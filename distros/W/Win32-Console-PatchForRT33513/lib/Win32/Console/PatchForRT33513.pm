package Win32::Console::PatchForRT33513;

use strict;
use warnings;

our $VERSION = '0.008';

use Win32::Console qw( );

{
    my $old_new = Win32::Console->can('new');
    my $new_new = sub {
        my ($class, $param1, $param2) = @_;
        my $self = $old_new->(@_);
        $self->{handle_is_std} = 1
            if defined($param1)
               && (  $param1 == Win32::Console::constant("STD_INPUT_HANDLE",  0)
                  || $param1 == Win32::Console::constant("STD_OUTPUT_HANDLE", 0)
                  || $param1 == Win32::Console::constant("STD_ERROR_HANDLE",  0)
                  );

        return $self;
    };

    no warnings qw( redefine );
    *Win32::Console::new = $new_new;
}

{
    my $old_DESTROY = Win32::Console->can('DESTROY');
    my $new_DESTROY = sub {
        my ($self) = @_;
        Win32::Console::_CloseHandle($self->{handle}) if !$self->{handle_is_std};
    };

    no warnings qw( redefine );
    *Win32::Console::DESTROY = $new_DESTROY;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Win32::Console::PatchForRT33513 - Patch for RT33513.

=head1 VERSION

Version 0.008

=cut

=head1 SYNOPSIS

    use Win32::Console::PatchForRT33513;

    use Win32::Console qw(STD_OUTPUT_HANDLE);

    my $c = Win32::Console->new(STD_OUTPUT_HANDLE);

=head1 DESCRIPTION

Patch for L<RT33513|https://rt.cpan.org/Public/Bug/Display.html?id=33513>.

Link to the L<patch|https://rt.cpan.org/Public/Bug/Display.html?id=33513#txn-577224>.

The code for this module is from this L<stackoverflow answer|https://stackoverflow.com/a/51909554/198183>.

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2022 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
