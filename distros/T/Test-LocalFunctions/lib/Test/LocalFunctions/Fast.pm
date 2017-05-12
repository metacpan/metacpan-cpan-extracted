package Test::LocalFunctions::Fast;

use strict;
use warnings;
use Test::LocalFunctions::Util;
use Test::LocalFunctions::Receptor;
use parent qw/Test::Builder::Module/;

BEGIN {
    eval { require Compiler::Lexer };
    if ($@) {
        $ENV{TEST_LOCALFUNCTIONS_TEST_PHASE} or die $@;
    }
}

our @EXPORT = qw/all_local_functions_ok local_functions_ok/;

use constant _VERBOSE => ( $ENV{TEST_VERBOSE} || 0 );

sub all_local_functions_ok {
    my ($args) = @_;
    return Test::LocalFunctions::Receptor::all_local_functions_ok( __PACKAGE__, $args );
}

sub local_functions_ok {
    my ( $lib, $args ) = @_;
    return Test::LocalFunctions::Receptor::local_functions_ok( __PACKAGE__, $lib, $args );
}

sub is_in_use {
    my ( undef, $builder, $file, $args ) = @_;

    my $ignore_functions = $args->{ignore_functions};
    my $module           = Test::LocalFunctions::Util::extract_module_name($file);
    my @local_functions  = Test::LocalFunctions::Util::list_local_functions($module);
    my @tokens           = _fetch_tokens($file);

    my $fail = 0;
    LOCAL_FUNCTION: for my $local_function (@local_functions) {
        for my $token (@tokens) {
            next LOCAL_FUNCTION if ( $token->{data} eq $local_function );
        }

        unless ( grep { $local_function =~ $_ } @$ignore_functions ) {
            $builder->diag("Test::LocalFunctions failed: '$local_function' is not used.");
            $fail++;
        }
    }

    return $fail;
}

sub _fetch_tokens {
    my $file = shift;

    open( my $fh, '<', $file ) or die("Can not open the file: $!");
    my $code   = do { local $/; <$fh> };
    my $lexer  = Compiler::Lexer->new($file);
    my @tokens = grep { _remove_tokens($_) } @{$lexer->tokenize($code)};
    close($fh);

    return @tokens;
}

sub _remove_tokens {
    my $token = shift;

    return 1 if ( $token->{name} eq 'Key' || $token->{name} eq 'Call' );
    return 0;
}
1;
__END__

=encoding utf-8

=head1 NAME

Test::LocalFunctions::Fast - Detects unused local function by Compiler::Lexer


=head1 SYNOPSIS

    # check modules that are listed in MANIFEST
    use Test::LocalFunctions::Fast;
    use Test::More;

    all_local_functions_ok();
    done_testing;

    # you can also specify individual file
    use Test::LocalFunctions::Fast;
    use Test::More;

    local_functions_ok('/path/to/your/module_or_script');
    done_testing;


=head1 DESCRIPTION

Test::LocalFunctions::Fast is finds unused local functions to clean up the source code. (Local function means the function which name starts from underscore.)

This module is faster than Test::LocalFunction::PPI, because this module uses Compiler::Lexer as lexical tokenizer.


=head1 METHODS

=over 4

=item * all_local_functions_ok

This is a test function which finds unused variables from modules that are listed in MANIFEST file.

=item * local_functions_ok

This is a test function which finds unused variables from specified source code.
This function requires an argument which is the path to source file.

=back


=head1 DEPENDENCIES

=over 4

=item * Compiler::Lexer (version 0.12 or later)

=item * Sub::Identify (version 0.04 or later)

=item * Test::Builder::Module (version 0.98 or later)

=item * Test::Builder::Tester (version 1.22 or later)

=back


=head1 SEE ALSO

L<Test::LocalFunctions>

L<Test::LocalFunctions::PPI>

=cut
