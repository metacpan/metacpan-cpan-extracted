package Test::MethodName;
use strict;
use warnings;
use Test::More qw//;
use Module::Pluggable::Object;
use List::MoreUtils qw/any/;
use Module::Functions qw//;

our $VERSION = '0.01';

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/method_ok all_methods_ok/;

sub method_ok {
    my ($module, $test_code) = @_;

    eval "require $module"; ## no critic
    if (my $e = $@) {
        Test::More::fail("fail to require $module: $e");
        return;
    }

    Test::More::note("test methods in $module");

    for my $function ( Module::Functions::get_full_functions($module) ) {
        Test::More::ok( $test_code->($function), "function: $function" );
    }
}

sub all_methods_ok {
    my ($search_path, $test_code, %param) = @_;

    # this code was borrowed from Test::LoadAllModules
    unless ($search_path) {
        Test::More::plan skip_all => 'no search path';
        exit;
    }
    Test::More::plan('no_plan');
    my @exceptions = @{ $param{except} || [] };
    my @lib = @{ $param{lib} || [ 'lib' ] };
    foreach my $module (
        grep { !_is_excluded( $_, @exceptions ) }
        sort do {
            local @INC = @lib;
            my $finder = Module::Pluggable::Object->new(
                search_path => $search_path );
            ( $search_path, $finder->plugins );
        }
        )
    {
        method_ok($module, $test_code);
    }
}

sub _is_excluded {
    my ( $module, @exceptions ) = @_;
    any { $module eq $_ || $module =~ /$_/ } @exceptions;
}

1;

__END__

=head1 NAME

Test::MethodName - test method name


=head1 SYNOPSIS

    use Test::MethodName;

    method_ok(
        $module => sub {
            my $method = shift;
            return ( $method =~ m!check! ) ? undef : 'pass';
        },
    );

    # or check methods in all modules

    all_methods_ok(
        'MyApp' => sub {
            my $method = shift;
            return ( $method =~ m!check! ) ? undef : 'pass';
        },
        except => [
            'MyApp::Foo',
            qr/MyApp::Bar::.*/,
        ],
    );


=head1 DESCRIPTION

Test::MethodName can define prohibited rules for method name.


=head1 METHODS

=head2 method_ok($module => sub { 'ok' })

=head2 all_methods_ok($search_path => sub { 'ok' })


=head1 REPOSITORY

Test::MethodName is hosted on github
<http://github.com/bayashi/Test-MethodName>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
