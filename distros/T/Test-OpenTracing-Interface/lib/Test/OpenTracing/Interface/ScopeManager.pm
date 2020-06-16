package Test::OpenTracing::Interface::ScopeManager;

=head1 NAME

Test::OpenTracing::Interface::ScopeManager - compliance testing

=head1 SYNOPSIS

=head1 SYNOPSIS

    use Test::OpenTracing::Interface::ScopeManager qw/:all/;
    
    can_all_ok 'MyImplementation::ScopeManager',
        "MyImplementation class does have all subs defined, well done!";
    
    my $test_thing = MyImplementation::ScopeManager->new( ... );
    
    can_all_ok( $test_thing,
        "An object constructed by 'new' has all required subs defined"
    );

=cut

use strict;
use warnings;

our $VERSION = 'v0.22.0';


use Test::OpenTracing::Interface;

use Exporter qw/import/;

our @EXPORT_OK = qw/can_all_ok/;
our %EXPORT_TAGS = ( all => [qw/can_all_ok/] );

use syntax qw/maybe/;



=head1 DESCRIPTION

This package will provide the tests as described in
L<Test::OpenTracing::Interface>.



=head1 EXPORTED SUBROUTINES

=cut



=head2 C<can_all_ok>

Test that all methods mentioned in L<OpenTracing::Interface::ScopeManager>
are defined.

=cut

sub can_all_ok {
    my $thing   = shift;
    my $message = shift;
    
    my $Test = Test::OpenTracing::Interface::CanAll->new(
        test_this           => $thing,
        interface_name      => 'ScopeManager',
        interface_methods   => [
            'activate_span',
            'get_active_scope'
        ],
        maybe
        message             => $message,
    );
    
    return $Test->run_tests;
}



=head1 SEE ALSO

=over

=item L<Test::OpenTracing::Interface>

Test OpenTracing::Interface compliance.

=item L<OpenTracing::Interface::ScopeManager>

Defines the ContextReference.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'Test OpenTracing' is Copyright (C) 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This library is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.



=cut

1;
