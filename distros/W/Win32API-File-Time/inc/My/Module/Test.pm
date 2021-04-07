package My::Module::Test;

use 5.006002;

use strict;
use warnings;

use Exporter ();
our @ISA = qw{ Exporter };

use Carp;
use Test::More 0.88;

our $VERSION = '0.011';

our %EXPORT_TAGS = (
    const	=> [ qw{ IS_WINDOWS } ],
    file_time	=> [ qw{
	    get_atime get_mtime get_ctime
	    get_sys_atime get_sys_mtime get_sys_ctime
	} ],
    time	=> [ qw{ file_time sys_time } ],
    trace	=> [ qw{ check_trace set_up_trace } ],
);
our @EXPORT_OK = map { @{ $_ } } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

use constant IS_WINDOWS => +{
    map { $_ => 1 } qw{ cygwin MSWin32 } }->{$^O};

unless ( IS_WINDOWS ) {

    require lib;
    lib->import( 'inc/mock' );

}

sub get_atime ($) {
    $_[1] = 8;
    goto &_get_file_time;
}

sub get_mtime ($) {
    $_[1] = 9;
    goto &_get_file_time;
}

sub get_ctime ($) {
    $_[1] = 10;
    goto &_get_file_time;
}

sub get_sys_atime ($) {
    my ( $fn ) = @_;
    return _ft_2_st( get_atime( $fn ) );
}

sub get_sys_mtime ($) {
    my ( $fn ) = @_;
    return _ft_2_st( get_mtime( $fn ) );
}

sub get_sys_ctime ($) {
    my ( $fn ) = @_;
    return _ft_2_st( get_ctime( $fn ) );
}

sub file_time ($) {
    my ( $pt ) = @_;
    return pack 'LL', 0, $pt;
}

sub sys_time ($) {
    my ( $pt ) = @_;
    my @tm = localtime $pt;
    return pack 'ssssssss', $tm[5] + 1900, $tm[4] + 1, 0,
	@tm[3, 2, 1, 0], 0;
}

# This largely duplicates GetFileTime in the mock Win32::API.
sub _ft_2_st {
    my ( $ft ) = @_;
    IS_WINDOWS
	and return;
    my ( undef, $pt ) = unpack 'LL', $ft;
    my @local = localtime $pt;
    @local = reverse @local[0..5];
    $local[0] += 1900;
    $local[1] += 1;
    splice @local, 2, 0, 0;
    push @local, 0;
    return pack 'ssssssss', @local;
}

sub _get_file_time {
    my ( $fn, $inx ) = @_;
    IS_WINDOWS
	and return;
    my @stat = stat $fn
	or croak "Can not stat $fn: $!";
    return pack 'LL', 0, $stat[$inx];
}

sub check_trace ($$) {
    my ( $want, $name ) = @_;
    my $code = Win32::API->can( '__mock_get_trace' )
	or return;
    my $got = $code->();
    if ( 'ARRAY' eq ref $want && @{ $want } ) {
	@_ = ( $got, $want, $name );
	goto &is_deeply;
    } else {
	require Data::Dumper;
	local $Data::Dumper::Useqq = 1;
	note "$name: ", Data::Dumper::Dumper( $got );
    }
    return;
}

sub set_up_trace () {
    my $code = Win32::API->can( '__mock_clear_trace' )
	or return;
    $code->();
    return;
}

1;

__END__

=head1 NAME

My::Module::Test - Test C<Win32API::File::Time>.

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test;

=head1 DESCRIPTION

This module is private to the C<Win32API-File-Time> distribution. It can
be changed or retracted without notice.

This module provides testing functionality for C<Win32API::File::Time>.
This includes making mock Windows code available under non-Windows
systems.

=head1 METHODS

This class supports the following public methods:

=head1 ATTRIBUTES

This class has the following attributes:

=head1 SEE ALSO

<<< replace or remove boilerplate >>>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Win32API-File-Time>,
L<https://github.com/trwyant/perl-Win32API-File-Time/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017, 2019-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
