package Test::LocalFunctions::PPI;

use strict;
use warnings;
use Test::LocalFunctions::Util;
use Test::LocalFunctions::Receptor;
use PPI::Document;
use PPI::Dumper;
use parent qw/Test::Builder::Module/;

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
    my ( undef, $builder, $file, $args ) = @_;    # append $args later?

    my $ignore_functions = $args->{ignore_functions};
    my $module           = Test::LocalFunctions::Util::extract_module_name($file);
    my @local_functions  = Test::LocalFunctions::Util::list_local_functions($module);
    my $ppi_document     = _generate_PPI_document($file);

    my $fail = 0;
    foreach my $local_function (@local_functions) {
        unless ( $ppi_document =~ /$local_function\'/ ) {
            unless ( grep { $local_function =~ $_ } @$ignore_functions ) {
                $builder->diag("Test::LocalFunctions failed: '$local_function' is not used.");
                $fail++;
            }
        }
    }

    return $fail;
}

sub _generate_PPI_document {
    my $file = shift;

    my $document = PPI::Document->new($file);
    my $dumper   = PPI::Dumper->new(_prune_PPI_tokens($document));
    return _remove_declarations_sub( $dumper->string() );
}

sub _remove_declarations_sub {
    my $document = shift;

    $document =~ s/
        PPI::Statement::Sub \n
            \s*? PPI::Token::Word \s* \'sub\' \n
            \s*? PPI::Token::Whitespace .*? \n
            \s*? PPI::Token::Word .*? \n
    //gxm;

    return $document;
}

sub _prune_PPI_tokens {
    my $document = shift;

    my @surplus_tokens = (
        'Operator',  'Number', 'Comment', 'Pod',
        'BOM',       'Data',   'End',     'Prototype',
        'Separator', 'Quote',
    );

    foreach my $surplus_token (@surplus_tokens) {
        $document->prune( 'PPI::Token::' . $surplus_token );
    }

    return $document;
}
1;
__END__

=encoding utf8

=head1 NAME

Test::LocalFunctions::PPI - Detects unused local functions by PPI


=head1 SYNOPSIS

    # check modules that are listed in MANIFEST
    use Test::LocalFunctions::PPI;
    use Test::More;

    all_local_functions_ok();
    done_testing;

    # you can also specify individual file
    use Test::LocalFunctions::PPI;
    use Test::More;

    local_functions_ok('/path/to/your/module_or_script');
    done_testing;


=head1 DESCRIPTION

Test::LocalFunctions::PPI finds unused local functions to clean up the source code.
(Local function means the function which name starts from underscore.)

This module uses PPI as lexical analyzer.


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

=item * PPI (version 1.215 or later)

=item * Sub::Identify (version 0.04 or later)

=item * Test::Builder::Module (version 0.98 or later)

=item * Test::Builder::Tester (version 1.22 or later)

=back


=head1 SEE ALSO

L<Test::LocalFunctions>

L<Test::LocalFunctions::Fast>

=cut
