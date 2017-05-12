package Test::LocalFunctions;

use strict;
use warnings;
use Test::LocalFunctions::Receptor;
use Module::Load;
use parent qw/Test::Builder::Module/;

our $VERSION = '0.23';
our @EXPORT  = qw/all_local_functions_ok local_functions_ok which_module_is_used/;

my $backend_module;
BEGIN {
    my $select_backend_module = sub {
        eval { require Compiler::Lexer };
        return 'Test::LocalFunctions::PPI' if ( $ENV{T_LF_PPI} || $@ || $Compiler::Lexer::VERSION < 0.13 );
        return 'Test::LocalFunctions::Fast';
    };
    $backend_module = $select_backend_module->();
    load $backend_module;
}

sub all_local_functions_ok {
    my ($args) = @_;
    return Test::LocalFunctions::Receptor::all_local_functions_ok( $backend_module, $args );
}

sub local_functions_ok {
    my ( $lib, $args ) = @_;
    return Test::LocalFunctions::Receptor::local_functions_ok( $backend_module, $lib, $args );
}

sub which_backend_is_used {
    return $backend_module;
}
1;
__END__

=encoding utf8

=head1 NAME

Test::LocalFunctions - Detects unused local functions


=head1 VERSION

This document describes Test::LocalFunctions version 0.23


=head1 SYNOPSIS

    # check modules that are listed in MANIFEST
    use Test::LocalFunctions;
    use Test::More;
    all_local_functions_ok();
    done_testing;

    # you can specify modules to ignore the test
    use Test::LocalFunctions;
    use Test::More;
    all_local_functions_ok({ignore_modules => ['Wanna::Ignore::Module']}); # Wanna::Ignore::Module will be ignored to testing
    done_testing;

    # you can also specify individual file
    use Test::LocalFunctions;
    use Test::More;
    local_functions_ok('/path/to/your/module_or_script');
    done_testing;

    # you can specify functions to exclude from test by regex.
    use Test::LocalFunctions;
    use Test::More;
    local_functions_ok('/path/to/your/module_or_script', {ignore_functions => [qr/_wanna_ignore_function/]}); # _wanna_ignore_function() will be ignored to testing.
    # all_local_functions_ok({ignore_functions => [qr/_wanna_ignore_function/]}); # <= also ok!
    done_testing;


=head1 DESCRIPTION

Test::LocalFunctions finds unused local functions to clean up the source code.
(Local function means the function which name starts from underscore.)

This module decides back end module automatically. If `Compiler::Lexer` has been
installed in target environment, this module will use `Test::LocalFunctions::Fast` as back end.
Otherwise this module will use `Test::LocalFunctions::PPI`. Which uses `PPI` for lexical analysis.

`PPI` is not fast, but `Compiler::Lexer` is fast.
So I recommend you to install `Compiler::Lexer`.


=head1 METHODS

=over 4

=item * all_local_functions_ok

This is a test function which finds unused variables from modules that are listed in MANIFEST file.

=item * local_functions_ok

This is a test function which finds unused variables from specified source code.
This function requires an argument which is the path to source file.

=item * which_backend_is_used

This function returns the used module as back end.
It will returns `Test::LocalFunctions::PPI` or `Test::LocalFunctions::Fast`.

=back


=head1 CONFIGURATION AND ENVIRONMENT

=over 4

=item * T_LF_PPI (environment variable)

This module uses `Test::LocalFunctions::PPI` as back end forcedly if this environment variable is set any value.

=back


=head1 DEPENDENCIES

=over 4

=item * PPI (version 1.215 or later)

=item * Sub::Identify (version 0.04 or later)

=item * Test::Builder::Module (version 0.98 or later)

=item * Test::Builder::Tester (version 1.22 or later)

=back


=head1 RECOMMENDED

=over 4

=item * Compiler::Lexer (version 0.12 or later)

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-localfunctions@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>

papix


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
