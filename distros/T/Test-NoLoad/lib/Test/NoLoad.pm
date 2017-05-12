package Test::NoLoad;
use strict;
use warnings;
use Test::More qw//;

our $VERSION = '0.03';

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/check_no_load load_ok/;

sub check_no_load {
    my @list = @_;

    for my $element (@list) {
        Test::More::ok(
            ref($element) eq 'Regexp' ? !_match($element) : !_loaded($element),
            "no_load: $element",
        );
    }
}

sub _match {
    my $regexp = shift;

    my $match;
    for my $module (keys %INC) {
        $module = _path2class($module);
        if ($module =~ m!$regexp!) {
            Test::More::note("$module was loaded");
            $match = 1;
        }
    }
    return $match;
}

sub _loaded {
    my $module = shift;
    $module =~ s!::!/!g;
    if ( defined( $INC{"$module\.pm"} ) ) {
        Test::More::note("$module was loaded");
        return 1;
    }
}

sub load_ok {
    my @modules = @_;

    for my $module (@modules) {
        Test::More::ok( _loaded($module), "load ok: $module" );
    }
}


sub dump_modules {
    my $msg = '---[loaded modules]-----';
    Test::More::note($msg);
    for my $module (sort keys %INC) {
        Test::More::note( _path2class($module) );
    }
    Test::More::note( '-' x length($msg) );
}

sub _path2class {
    my $module = shift;
    $module =~ s!/!::!g;
    $module =~ s!\.pm$!!;
    return $module;
}

1;

__END__

=head1 NAME

Test::NoLoad - Fail, if the module was loaded


=head1 SYNOPSIS

    use Test::AllModules;
    use Test::NoLoad;

    BEGIN {
        all_ok(
            search_path => 'MyApp',
            check => sub {
                my $class = shift;
                eval "use $class;1;";
            },
        );
    }

    check_no_load(
        qw/ Class::ISA Pod::Plainer Switch /,
        qr/Acme::.+/,
    );


=head1 DESCRIPTION

Test::NoLoad export the function `check_no_load`.
It will be fail, if the module was loaded.


=head1 EXPORTED FUNCTIONS

=head2 check_no_load(@modules)

=head2 load_ok(@modules)


=head1 OTHER FUNCTIONS

=head2 dump_modules

show the list of modules: already loaded them when this function just call.


=head1 REPOSITORY

Test::NoLoad is hosted on github
<http://github.com/bayashi/Test-NoLoad>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
