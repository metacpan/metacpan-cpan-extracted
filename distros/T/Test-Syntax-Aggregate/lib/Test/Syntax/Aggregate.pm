package Test::Syntax::Aggregate;

use 5.008;
use strict;
use warnings;
use parent qw(Test::Builder::Module Exporter);
use IPC::Open2;

our $VERSION = '0.03';

our @EXPORT = ('check_scripts_syntax');

=head1 NAME

Test::Syntax::Aggregate - Check syntax of multiple scripts

=head1 SYNOPSIS

This module allows you to check syntax of multiple scripts using the same common module.

    use Test::Syntax::Aggregate;
    check_scripts_syntax(
        preload => [ @modules ],
        scripts => [ @scripts ],
    );

=head1 DESCRIPTION

Suppose you have a lot of cgi scripts that use the same set of preloaded
modules. If you running syntax check on these scripts it may take a lot of time
mostly because of loading perl and common modules for every single script. This
module borrows idea and some code from L<Test::Aggregate> and
L<ModPerl::Registry>. It preloads specified modules first, and when compiles
scripts wrapping them into functions.

=head1 SUBROUTINES

=head2 check_scripts_syntax(%parameters)

Runs syntax checks for all specified files. Accepts following parameters:

=over 4

=item preload

Reference to array with list of modules that must be preloaded before testing.
Preloading modules allows you significantly speedup testing.

=item scripts

Reference to array containing list of scripts to check syntax.

=item libs

List of directories to look for modules files. Defaults to I<@INC>.

=item hide_warnings

Hide any warnings produced by scripts during checks unless check failed.

=back

=cut

sub check_scripts_syntax {
    my %params  = @_;

    my @libs    = $params{libs} ? @{ $params{libs} } : @INC;
    my @modules = $params{preload} ? @{ $params{preload} } : ();
    push @modules, "Test::Syntax::Aggregate::Checker";
    my @scripts = @{ $params{scripts} };
    my $hide_warnings = $params{hide_warnings} ? 1 : 0;

    my $subtest = __PACKAGE__->builder->child( $params{name} ? $params{name} : "Scripts syntax" );
    $subtest->plan( tests => 0 + @scripts );
    
    # This child will actually check scripts
    my ( $wrfd, $rdfd );
    my $pid = open2( $rdfd, $wrfd, $^X, (map { "-I$_" } @libs), (map { "-M$_" } @modules), "-e", "Test::Syntax::Aggregate::Checker->run(hide_warnings => $hide_warnings)" );
    $wrfd->autoflush;

    for (@scripts) {
        if ( -r $_ ) {
            print $wrfd "$_\n";
            chomp( my $result = <$rdfd> );
            if ( $result =~ /^ok/ ) {
                $subtest->ok( 1, $_ );
            }
            elsif ( $result =~ /^not ok/ ) {
                $subtest->ok( 0, $_ );
            }
            else {
                die "Got invalid response from checker process: $result";
            }
        }
        else {
            warn "Can't read $_\n";
            $subtest->ok( 0, $_ );
        }
    }
    close $wrfd;
    waitpid $pid, 0;

    return $subtest->finalize;
}

1;

__END__

=head1 EXPORT

It exports check_scripts_syntax function.

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 BUGS

It modifies scripts, so it is possible that it will introduce syntax errors to
some of them or fix and miss existing errors in other cases.

=head1 SEE ALSO

L<Test::Strict>

=head1 ACKNOWLEDGEMENTS

This module borrows idea from L<Test::Aggregate> and some code from L<ModPerl::RegistryCooker>.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
