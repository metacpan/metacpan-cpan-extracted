# BW::Common.pm
# Common methods for BW::* modules
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History

package BW::Common;
use strict;
use warnings;

use BW::Constants;
use IO::File;
use base qw( BW::Base );

our $VERSION = "0.5";

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    return SUCCESS;
}

# _setter_getter entry points
sub stub { BW::Base::_setter_getter(@_); }

# read a file up to length bytes (defaults to 1MB)
# binmode defaults to ":raw"
sub readfile
{
    my $fn = shift;
    $fn = shift if ref($fn);      # accept object or non-object calls
    my $length = shift || ( 1024 * 1024 );
    my $layer = shift || ":raw";
    my $buf;

    my $fh = IO::File->new( $fn, 'r' ) or return FAILURE;
    $fh->binmode($layer);
    my $rc = $fh->read( $buf, $length );
    return FAILURE unless defined $rc;
    $fh->close;

    return $buf;
}

sub comma
{
    my $n = shift;
    $n = shift if ref($n);      # accept object or non-object calls

    while ( $n =~ s/^(-?\d+)(\d{3})/$1,$2/ ) {}
    return $n;
}

sub trim
{
    my $s = shift;
    $s = shift if ref($s);      # accept object or non-object calls

    $s =~ /^\s*(.*?)\s*$/;
    return $1;
}

sub basename
{
    my $s = shift;
    $s = shift if ref($s);      # accept object or non-object calls

    $s = ( split( m|[/\\]|, $s ) )[-1];
    return $s;
}

sub normalize_newlines
{
    my $s = shift;
    $s = shift if ref($s);      # accept object or non-object calls

    $s =~ s/\x0d\x0a|\x0d/\n/gsm;
    return $s;
}

1;

=head1 NAME

BW::Common - Some common utility functions

=head1 SYNOPSIS

    use BW::Common
    my $o = BW::Common->new;

=head1 METHODS

=over 4

=item B<new>

Constructs a new BW::Common object. 

Returns a blessed BW::Common object reference.
Returns undef (VOID) if the object cannot be created. 

=item B<comma> number

Returns a comma-fied string from number. 

=item B<trim> string

Returns the string with leaading and trailing spaces removed

=item B<basename> string

Returns the string with basename of a filename.

=item B<normalize_newlines> string

Returns the string with CRs and CRLF pairs normalized to NLs. 

=item B<readfile> filename, [max_length], [layer]

Read a file and return as a string. 

max_length is the maximum length to read. It defaults to 1MB (1024 * 1024). 

layer is the LAYER string passed to binmode. It defaults to ":raw" (for binary files). 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-03-08 bw   -- updated basename to work with backslash for MS Win
    2010-02-02 bw   -- first CPAN release
    2009-12-22 bw   -- added readfile
    2009-11-25 bw   -- initial version.

=cut

