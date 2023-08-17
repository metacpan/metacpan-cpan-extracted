package WebService::OpenSky::Moose;

# ABSTRACT: MooseX::Extended::Custom for WebService::OpenSky

use MooseX::Extended::Custom;
use PerlX::Maybe 'provided';
our $VERSION = '0.4';

# If $^P is true, we're running under the debugger.
#
# When running under the debugger, we disable __PACKAGE__->meta->make_immutable
# because the way the debugger works with B::Hooks::AtRuntime will cause
# the class to be made immutable before the we apply everything we need. This
# causes the code to die.
sub import ( $class, %args ) {
    MooseX::Extended::Custom->create(
        includes => 'method',
        provided $^P, excludes => 'immutable',
        %args    # you need this to allow customization of your customization
    );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Moose - MooseX::Extended::Custom for WebService::OpenSky

=head1 VERSION

version 0.4

=head1 DESCRIPTION

No user-serviceable parts inside.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
