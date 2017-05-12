package the;
use 5.006001;
no warnings 'redefine';
our $VERSION = '0.15';

sub import {
    my $package = caller;
    *{"${package}::$_"} = sub { return wantarray ? @_ : $_[0] }
        for qw(a an teh the more);
    my ($class, $module) = @_;
    if ($module) {
        eval "require $module";
        die $@ if $@;
        splice @_, 0, 1;
        my $import = $module->can('import')
            or return;
        goto &$import;
    }
}

sub unimport {
    my $package = caller;
    *{"${package}::$_"} = sub { return wantarray ? @_ : $_[0] }
        for qw(a an teh the more);
    my ($class, $module) = @_;
    if ($module) {
        eval "require $module";
        die $@ if $@;
        splice @_, 0, 1;
        my $unimport = $module->can('unimport')
            or return;
        goto &$unimport;
    }
}


*{"a::"} =
*{"an::"} =
*{"more::"} =
*{"teh::"} =
*{"the::"};

1;

=encoding utf8

=head1 NAME

the - This is teh, best module evar!

=head1 SYNOPSIS

    use the Moose;

    has teh stuffz => (is => a 'rw');

    the my an $a = teh $b + a $c;

    no more 'Moose';

=head1 DESCRIPTION

teh module exports the subroutine and the module exports a subroutine.
Just use an module, then use more subroutine.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
