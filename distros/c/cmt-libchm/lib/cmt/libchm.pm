package cmt::libchm;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	CHM_COMPRESSED
	CHM_ENUMERATE_ALL
	CHM_ENUMERATE_DIRS
	CHM_ENUMERATE_FILES
	CHM_ENUMERATE_META
	CHM_ENUMERATE_NORMAL
	CHM_ENUMERATE_SPECIAL
	CHM_ENUMERATOR_CONTINUE
	CHM_ENUMERATOR_FAILURE
	CHM_ENUMERATOR_SUCCESS
	CHM_MAX_PATHLEN
	CHM_PARAM_MAX_BLOCKS_CACHED
	CHM_RESOLVE_FAILURE
	CHM_RESOLVE_SUCCESS
	CHM_UNCOMPRESSED
	
	chm_open
	chm_close
	chm_set_param
	chm_resolve_object
	chm_retrieve_object
	chm_enumerate
	chm_enumerate_dir
	
	dumpUnitInfo
	getUnitInfo
);

our %EXPORT_TAGS = ( 'all' => [ @EXPORT ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&cmt::libchm::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('cmt::libchm', $VERSION);



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

cmt::libchm - Perl extension for blah blah blah

=head1 SYNOPSIS

  use cmt::libchm;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for cmt::libchm, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head2 Exportable constants

  CHM_COMPRESSED
  CHM_ENUMERATE_ALL
  CHM_ENUMERATE_DIRS
  CHM_ENUMERATE_FILES
  CHM_ENUMERATE_META
  CHM_ENUMERATE_NORMAL
  CHM_ENUMERATE_SPECIAL
  CHM_ENUMERATOR_CONTINUE
  CHM_ENUMERATOR_FAILURE
  CHM_ENUMERATOR_SUCCESS
  CHM_MAX_PATHLEN
  CHM_PARAM_MAX_BLOCKS_CACHED
  CHM_RESOLVE_FAILURE
  CHM_RESOLVE_SUCCESS
  CHM_UNCOMPRESSED



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
