package Test::MockPackages::Returns;
use strict;
use warnings;
use utf8;

our $VERSION = '1.00';

use English qw(-no_match_vars);
use Exporter qw(import);

our @EXPORT_OK = qw(returns_code);

sub returns_code(&) {    ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my ( $coderef ) = @ARG;

    return bless $coderef, __PACKAGE__;
}

1;

__END__

=head1 NAME

Test::MockPackages::Returns - provides a helper subroutine for creating custom returns

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

 use Test::MockPackages::Returns qw(returns_code);
 ...
 $m->expects( $arg1, $arg2 )
   ->returns( returns_code {
       my (@args) = @ARG;

        return join ', ', @args;
   } );

=head1 DESCRIPTION

This package contains the C<returns_code> subroutine which provides the capability to have a CODE executed to return a
custom value in a returns expectation.

=head1 SUBROUTINES

=head2 returns_code(&)( CodeRef $coderef ) : Test::MockPackages::Returns

Returns a new Test::MockPackages::Returns object. Under the hood, it's really just the same CodeRef which has been blessed into this package.

This subroutine is exported using C<@EXPORT_OK>.

Return value: a blessed CodeRef.

=head1 AUTHOR

Written by Tom Peters <tpeters at synacor.com>.

=head1 COPYRIGHT

Copyright (c) 2016 Synacor, Inc.

=cut
