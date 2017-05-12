package Test::Import;
{
  $Test::Import::VERSION = '0.004';
}
# ABSTRACT: Test functions to ensure modules import things

use strict;
use warnings;

use base 'Test::Builder::Module';
use Test::More;
use Capture::Tiny qw( capture_merged );
our @EXPORT_OK = qw( :all does_import_strict does_import_warnings does_import_sub does_import_class );
our %EXPORT_TAGS = (
    'all' => [ grep { !/^:/ } @EXPORT_OK ], # All is everything except tags
);


## no critic ( ProhibitSubroutinePrototypes )
sub does_import_strict($) {
    my ( $module ) = @_;
    my $tb = __PACKAGE__->builder;
    return $tb->subtest( "$module imports strict" => sub {
        # disable strict so module has to explicitly re-enable it
        # pragmas cannot be hidden by a package statement, but some
        # modules may try to muck around with the calling package,
        # so hide ourselves from those evil import statements
        ## no critic ( ProhibitStringyEval ProhibitNoStrict )
        no strict;
        eval qq{package ${module}::strict; use $module; } . q{@m = ( "one" );};
        ok $@, 'code that fails strict dies';
        like $@, qr{explicit package name}, 'dies with the right error message';
    } );
}


sub does_import_warnings($) {
    my ( $module ) = @_;
    my $tb = __PACKAGE__->builder;
    return $tb->subtest( "$module imports warnings" => sub {
        # disable warnings so module has to explicitly re-enable it
        # pragmas cannot be hidden by a package statement, but some
        # modules may try to muck around with the calling package,
        # so hide ourselves from those evil import statements
        ## no critic ( ProhibitStringyEval ProhibitNoWarnings )
        no warnings;
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval qq{package ${module}::warnings; use $module;} . q{my $foo = "one" . undef;};
        is scalar @warnings, 1, 'got the one warning we expected';
        like $warnings[0], qr/uninitialized/, 'we forced an uninitialized warning';
    } );
}


sub does_import_sub($$$) {
    my ( $module, $imported_module, $imported_sub ) = @_;
    my $tb = __PACKAGE__->builder;
    return $tb->subtest( "$module imports $imported_module sub $imported_sub" => sub {
        ## no critic ( ProhibitStringyEval )
        ok eval "package ${module}::${imported_module}; use $module; return __PACKAGE__->can('$imported_sub')",
            'eval succeeded and expected sub was imported';
        ## no critic ( ProhibitMixedBooleanOperators )
        ok !$@, 'eval did not throw an error' or diag $@;
    } );
}


sub does_import_class($$) {
    my ( $module, $imported_class ) = @_;
    my $tb = __PACKAGE__->builder;
    return $tb->subtest( "$module imports $imported_class" => sub {
        # Do the module name to file path dance!
        my $imported_path = $imported_class;
        $imported_path =~ s{::}{/}g;
        $imported_path .= '.pm';

        # Pretend the module has not been loaded
        delete local $INC{$imported_path}; # delete local added in 5.12.0

        # Capture to hide the warnings about subroutines redefined
        # Doing 'no warnings qw(redefine)" does not work if the module we're loading
        # also imports warnings
        my ( $output, $retval ) = capture_merged {
            ## no critic ( ProhibitStringyEval )
            return eval "package ${module}::${imported_class}; use $module; return exists \$INC{'$imported_path'}";
        };
        ok $retval, 'eval succeeded and expected path exists in %INC' or diag $output;
        ## no critic ( ProhibitMixedBooleanOperators )
        ok !$@, 'eval did not throw an error' or diag $@;
    } );
}

1;

__END__

=pod

=head1 NAME

Test::Import - Test functions to ensure modules import things

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Test::Import qw( :all );

    # Ensure our base module imports strict
    does_import_strict 'My::Base';

    # Ensure our base module imports warnings
    does_import_warnings 'My::Base';

    # Ensure our base module imports a sub from another module
    does_import_sub 'My::Base', 'Scalar::Util', 'blessed';

    # Ensure our base module loads a class
    does_import_class 'My::Base', 'File::Spec';

=head1 DESCRIPTION

This module encapsulates a bunch of tests for testing base or boilerplate
modules (e.g. modules that use Import::Into to force things into the calling
namespace). These tests ensure that the base module imports what it says it
imports.

=head1 EXPORTED FUNCTIONS

=head2 does_import_strict 'My::Module'

Ensure My::Module forces strict into the calling namespace.

=head2 does_import_warnings 'My::Module'

Ensure My::Module forces warnings into the calling namespace.

=head2 does_import_sub 'My::Module', 'Imported::Module', 'imported_sub'

Ensure that My::Module exports 'imported_sub' from Imported::Module into the calling
namespace.

=head2 does_import_class 'My::Module', 'Imported::Class'

Ensure that My::Module loads Imported::Class.

=head1 SEE ALSO

=over 4

=item *

L<Test::Exports>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
