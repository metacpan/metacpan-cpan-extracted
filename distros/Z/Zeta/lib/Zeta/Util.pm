##############################################################################
#
# NAME: Zeta::Util
# Author: Gregory S. Youngblood <zeta@cpan.org> 
# Copyright 1995-2012 Gregory S. Youngblood, all rights reserved.
#
##############################################################################
package Zeta::Util;

=head1 NAME

Zeta::Util

=cut

##############################################################################
# Version
##############################################################################

=head1 VERSION

Version 0.02

=cut

BEGIN {
	our $VERSION = '0.02';
}

##############################################################################
# Description
##############################################################################

=head1 SYNOPSIS

	use Zeta::Util qw(:ALL);
	...
	sub example {
		my %opts = get_opts(@_);
		...
	}
	
=cut

##############################################################################
# Pull in additional modules
##############################################################################

use strict;
use warnings;
use Carp;

use B qw(svref_2object);
use Fcntl qw(:mode);
use File::Basename;

##############################################################################
# Define Exports
##############################################################################
use Exporter 'import';
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT = ();
@EXPORT_OK = (qw(
	TRUE
	FALSE
	get_opts
	is_numeric is_float is_int is_string
	is_type_float is_type_int is_type_string
	get_file_details
	is_mod_perl
	is_empty is_blank no_undef
));
%EXPORT_TAGS = (
	ALL       => [ @EXPORT, @EXPORT_OK ],
	BOOL      => [ qw(TRUE FALSE) ],
	DATATYPE  => [ qw(is_numeric is_float is_int is_string) ],
	PERLTYPE  => [ qw(is_type_string is_type_int is_type_float ) ],
	FILE      => [ qw(get_file_details) ],
	ENV       => [ qw(is_mod_perl) ],
	STRING    => [ qw(is_empty is_blank no_undef) ],
);

=head1 EXPORT

Nothing is exported by default. The following items are available:

=cut

##############################################################################
# Set Defaults, declare globals, etc.
##############################################################################

# constants
use constant TRUE  => 1;
use constant FALSE => 0;

# scalars
our $get_opts_scalar_key = 'arg1';

# arrays/lists

# hashes
our %FILE_TYPES = (
	S_IFBLK,  'block',   # -b
	S_IFCHR,  'char',    # -c
	S_IFDIR,  'dir',     # -d
	S_IFREG,  'file',    # -f
	S_IFLNK,  'link',    # -l
	S_IFIFO,  'pipe',    # -p
	S_IFSOCK, 'socket',  # -S
);

##############################################################################
#
# Module Code
#
##############################################################################

##############################################################################
=head1 FUNCTIONS
##############################################################################

=head2 get_opts

Generic method of getting arguments passed to a function as a hash or an array.
Automatically converts a hash reference into a hash. If a single scalar
argument or an object reference is passed then it will be returned as a hash 
using the key defined by $Zeta::Util::get_opts_scalar_key (default:arg1).
An array reference or an odd number of arguments will be converted and returned
as a list (array).

NOTE: If an odd number of arguments are passed and returned as a list (array),
and a hash is expected, and warnings are enabled (use warnings), then the
warning "Odd number of elements in hash assignment" will be displayed.

If called in scalar context, get_opts will return a hash ref. Otherwise
get_opts returns a hash.

=cut

sub get_opts {
	if (scalar(@_) == 1) {
		# detected only one argument
		# is it a scalar, arrayref, or hashref?
		my $reftype = ref($_[0]);
		if (not $reftype) {
			# scalar
			my %hash = ($get_opts_scalar_key, $_[0]);
			# returns either the hash with a default key
			# or if called in scalar context returns the
			# opt directly... presumes a single opt was
			# intentional and should be maintained
			return wantarray ? %hash : $_[0];
		} elsif ($reftype eq 'ARRAY') {
			# array ref
			my @arr = @{$_[0]};
			# returns either array as a list or as the
			# original arrayref passed in
			return wantarray ? @arr : $_[0];
		} elsif ($reftype eq 'HASH') {
			# hash ref
			my %hash = %{$_[0]};
			# returns either the hash or the original
			# hash ref depending on context for return
			return wantarray ? %hash : $_[0];
 		} else {
 			# probably an object
			my %hash = ($get_opts_scalar_key, $_[0]);
			# returns either the hash with a default key
			# the object itself depending on the context
			return wantarray ? %hash : $_[0];
		}
	} else {
		# detected more than one argument
		if (scalar(@_) % 2 == 1) {
			# odd number of arguments, treat as an array
			my @arr = @_;
			# return either list or array ref based on context
			return wantarray ? @arr : \@arr;
		} else {
			# even number of arguments, treat as a hash
			my %hash = @_;
			# return hash or hash ref based on context
			return wantarray ? %hash : \%hash;
		}
	}
	# safety, we should never get here but just in case
	return wantarray ? @_ : [@_];
}

##############################################################################
# Numeric and Data Type Tests
##############################################################################

=head2 _b_cmp_flags

Internal procedure, not meant to be used outside this module, not in export_ok

=cut

sub _b_cmp_flags($$) {
	my $ref   = shift();
	my $flags = shift();
	return $flags & svref_2object($ref)->FLAGS ? TRUE : FALSE;
}

=head2 is_type_string

=cut

sub is_type_string($) {
	return _b_cmp_flags(\$_[0], B::SVf_POK | B::SVp_POK);
}

=head2 is_type_int

=cut

sub is_type_int($) {
	return _b_cmp_flags(\$_[0], B::SVf_IOK | B::SVp_IOK);
}

=head2 is_type_float

=cut

sub is_type_float($) {
	return _b_cmp_flags(\$_[0], B::SVf_NOK | B::SVp_NOK);
}

=head2 is_string

=cut

sub is_string($) {
	# since anything can be a string, we'll fake it say yes
	# provided of course it's not a ref
	my $str  = FALSE;
	if (not ref($_[0])) {
		$str = TRUE;
	}
	return $str;
}

=head2 is_int

=cut

sub is_int($) {
	my $value = $_[0];
	my $response;
	no warnings 'numeric';
	if ($value =~ /^[0-9]+\.$/) {
		# fix problem where 2. doesn't get recognized as int
		# by trimming trailing decimal point before testing.
		$value =~ s/\.$//;
	}
	$response = is_type_int($value+0);
	return (($response) and ($value eq ($value+0)));
}

=head2 is_float

=cut

sub is_float($) {
	my $value = $_[0];
	my $response;
	no warnings 'numeric';
	if ($value =~ /^[0-9]*\.0+$/) {
		# fix problem where 2.00 doesn't get recognized as float
		# by making sure a non-zero decimal exists for numbers that
		# have a decimal and 1 or more 0s
		$value += 0.01;
		$response = is_type_float($value);
		$value -= 0.01;
	} else {
		$response = is_type_float($value+0.0);
	}
	return (($response) and ($value eq ($value+0.0)));
}

=head2 is_numeric

=cut

sub is_numeric($) {
	no warnings 'numeric';
	return is_int($_[0]) | is_float($_[0]);
}

##############################################################################
# File and Path methods 
##############################################################################

=head2 get_file_details

Returns a hashref containing details about the specified file. Returns undef
if the file is not defined, does not exist, or is not readable.

Example of returned hashref:
$VAR1 = {
          'filetype' => 'file',
          'blocks' => 8,
          'blocksize' => 4096,
          'mode' => '0664',
          'size' => 387,
          'hardlinks' => 1,
          'file_name' => '05-fileinfo',
          'mode_dec' => 436,
          'ctime' => 1334455408,
          'rdev' => 0,
          'filetype_dec' => 32768,
          'uid' => 501,
          'mtime' => 1334455408,
          'file_extension' => 't',
          'path' => 't/',
          'device' => 234881027,
          'inode' => 6282915,
          'filename' => '05-fileinfo.t',
          'fullname' => 't/05-fileinfo.t',
          'atime' => 1334455410,
          'gid' => 20
        };

=cut 

sub get_file_details {
	my $filename = shift();
	if ((defined $filename) and (-e $filename) and (-r $filename)) {
		my $details = {};
		if (-l $filename) {
			@{$details}{
				'device','inode','mode','hardlinks','uid','gid','rdev',
				'size','atime','mtime','ctime','blocksize','blocks'
			} = lstat($filename);
			$details->{'link_target'} = readlink($filename);
		} else {
			@{$details}{
				'device','inode','mode','hardlinks','uid','gid','rdev',
				'size','atime','mtime','ctime','blocksize','blocks'
			} = stat($filename);
		}
		my ($fname, $fpath, $fext) = fileparse($filename, qw/\.[^.]*/);
		$fext =~ s/^\.//;
		my $mode = $details->{'mode'};
		$details->{'mode_dec'} = S_IMODE($mode);
		$details->{'filetype_dec'} = S_IFMT($mode);
		$details->{'mode'} = sprintf("%04o", $details->{'mode_dec'});
		$details->{'filetype'} = $FILE_TYPES{$details->{'filetype_dec'}};
		$details->{'path'} = $fpath;
		# fix bug where filenames without extensions had a period 
		# added to their filename.
		if ((not defined $fext) or
			($fext =~ /^\s*$/)) {
			# fix edge case where filename ending with period
			# would have period dropped
			if ($filename =~ /\.$/) {
				$fname .= '.';
			}
			$details->{'filename'} = $fname;
		} else {
			$details->{'filename'} = $fname . '.' . $fext;
		}
		$details->{'file_name'} = $fname;
		$details->{'file_extension'} = $fext;
		$details->{'fullname'} = $filename;
		my ($arc) = ($details->{'filename'} =~ /\.(tar\..{1,3}|tar|cpio|tbz2|tgz|tbz|zip|rar|arc|arj|bzip|tz|zoo|7z)$/i);
		if (defined $arc) {
			$details->{'archive'} = $arc;
		}
		return $details;
	}
	return;
}

##############################################################################
# Environment Functions 
##############################################################################

=head2 is_mod_perl

Checks to see if mod_perl is detected. This is done by looking for the MOD_PERL
environment variable. Returns 1 (TRUE) if found, or 0 (FALSE) if not.

=cut

sub is_mod_perl {
	return exists $ENV{'MOD_PERL'} ? TRUE : FALSE;
}

##############################################################################
# String Functions
##############################################################################

=head2 is_empty

Returns true if variable is not defined or equal to ''

=cut

sub is_empty {
	my $string = $_[0];
	return ((not defined $string) or ($string eq ''));
}

=head2 is_blank

Returns true if variable is not defined, equal to '', or contains nothing
but whitespace (/^\s*$/).

=cut

sub is_blank {
	my $string = $_[0];
	return ((is_empty($string)) or ($string =~ /^\s*$/));
}

=head2 no_undef

Returns the variable passed to it, unchanged, unless the variable has a value
of undef, in which case it returns ''.

=cut

sub no_undef {
	return (defined $_[0] ? $_[0] : '');
}

##############################################################################
#
# PerlDoc
#
##############################################################################

=head1 AUTHOR

Gregory S. Youngblood, C<< <zeta at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zeta-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zeta-Tools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Zeta::Util


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Zeta-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Zeta-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Zeta-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Zeta-Tools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 1995-2012 Gregory S. Youngblood, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

##############################################################################
#
# Make perl happy
#
##############################################################################
1;
