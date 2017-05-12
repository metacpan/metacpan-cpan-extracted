package VMS::Logical;

use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.6';
our @EXPORT = ();
our @EXPORT_OK = qw(translate getlogical define deassign create_table);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ] );

require XSLoader;
XSLoader::load('VMS::Logical', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

VMS::Logical - OpenVMS Logical name interface

=head1 SYNOPSIS

  use VMS::Logical qw(:all);

  $hashref = translate({lognam='sys$sysdevice',
                        case_blind=>1});

  $string = getlogical('sys$login');
  @strings = getlogical('sys$sysroot');

  $table = create_table({table=>'test_table',
			 partab=>'LNM$PROCESS_DIRECTORY'});

  $table = define({lognam=>'TEST_LOGICAL',
                    tabnam=>'LNM$JOB',
                    acmode=>'SUPERVISOR',
                    equiv->[{string=>'equivalence'},
                            {string=>'another'}]});

  $status = deassign({lognam=>'TEST_LOGICAL',
                      tabnam=>'LNM$JOB',
                      acmode=>'SUPERVISOR'});

=head1 DESCRIPTION

VMS::Logical provides access to logical names on OpenVMS systems.

=head2 translate

Translates a logical name.

  $hash = VMS::Logical::translate('logical_name');
  $hash = VMS::Logical::translate({option=>value});

The first form can be used for a simple logical name translation using
default search options.  The second form should be used if additional
options are necessary.

If the translation is successful, a hash reference will be returned
containing information about the logical name.  C<undef> is returned
on errors.  The VMS error code will be available in $^E.

The options hash may contain the following values.

=over 4

=item lognam

The logical name to translate.

=item case_blind

When set to 1, case will be ignored when searching for the logical
name.

=item interlocked

When set to 1, waits for cluster operations to complete before
proceeding.

=item table

Specifies the name of the table to be searched for the logical name.

=item acmode

Access mode to use for searching.  The value should be one of USER,
SUPERVISOR, EXECUTIVE or KERNEL.  Any abbrevation of these is
accepted.  If specified, only logical names at the specified mode or a
more privileged mode will be returned.

=back

=head2 getlogical

Returns the equivalence string[s] of a logical name.

  $string = VMS::Logical::getlogical('logical_name');
  @strings = VMS::Logical::getlogical('logical_name');
  $string = VMS::Logical::getlogical({option=>value});
  @strings = VMS::Logical::getlogical({option=>value});

The C<getlogical>  method calls the  translate method and  returns the
equivalence strings.  This provides a convenient shorthand if only the
strings and  not the  attributes of the  logical name are  needed.  If
called in  array context,  the equivalence strings  are returned  as a
list.  Otherwise,  a single string  is returned with  the equivalences
separated by commas.

If a string is passed as the argument, it is accepted as the logical
name to translate.  The tables described by LNM$FILE_DEV will be
searched without regard to case for a translation.

If a hash reference is passed as the argument, it will be passed
directly to C<translate>.  This gives full control over the
translation process.

=head2 define

Defines a logical name.

  $table = VMS::Logical::define({option=>value});

The name of the table where the logical name was created is returned
if the call is successful.  On error, C<undef> is returned and the VMS
status code is available in $^E.

The options hash may contain the following values.

=over 4

=item table

The name of the table to contain the logical name.

=item lognam

The name of the logical to be defined.

=item acmode

The access mode of the logical name.

=item attr

Attributes for the logical name.  This is a hashref containing the
following options.

=over 4

=item CONFINE

Logical will not be copied to subprocesses when spawning.

=item NO_ALIAS

Don't allow duplicate logical names at outer levels.

=back

=item equiv

An array of equivalence definitions.  Each equivalence is a hashref
containing the following items.

=over 4

=item attr

Attributes for the equivalence.  The following attributes are supported.

=over 4

=item CONCEALED

Create a concealed logical.

=item TERMINAL

The equivalence contains no logical names.

=back

=item string

The equivalence string.

=back

=back

=head2 deassign

Deletes a logical name.

  $status = VMS::Logical::deassign({option=>value});

Returns a true value if successful.  On error, C<undef> is returned
and the VMS error code is available in $^E.  The options hash may
contain the following values.

=over 4

=item table

Name of the table containing the logical.

=item lognam

The name of the logical to delete.

=item acmode

The access mode of the logical name.

=back

=head2 create_table

Creates a logical name table.

  $table = create_table({option=value});

The name of the created table is returned if successful.  On error,
C<undef> is returned and the VMS error code is available in $^E.

Valid options are as follows.

=over 4

=item table

The name of the table to create.

=item partab

The name of the parent table.

=item quota

The number of bytes of system space that can be used by the table and
logicals defined in it.  This only applies to shared tables.
 
=item acmode

The access mode of the table.

=item attr

Attributes of the table.

=over 4

=item NO_ALIAS

Don't allow tables to be created with the same name at outer access
modes.

=item CREATE_IF

Only create the table if it doesn't exist with the specified
attributes.  If this is not specified and the table already exists,
the new table will supercede the existing one.

=item CONFINE

Don't copy the table to subprocesses.

=back

=head1 SEE ALSO

'HP OpenVMS Programming Concepts Manual' contains a chapter about
logical names and logical name tables.

'HP OpenVMS System Services Reference Manual' provides detailed
information about the OpenVMS logical name system services.

=head1 AUTHOR

Thomas Pfau, E<lt> tfpfau@gmail.com E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009,2012 by Thomas Pfau

This [library|program|code|module] is free software; you
can redistribute it and/or modify it under the terms of the
Artistic License 2.0. For details, see the full text of the
license in the file LICENSE.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties.b

=cut

sub getlogical {
    my $arg = shift;
    $arg = { lognam=>$arg, case_blind=>1, tabnam=>'LNM$FILE_DEV' }
        if (ref($arg) eq "");
    my $res = translate($arg);
    return () unless defined($res);
    my @res = map { $_->{string} } @{$res->{equiv}};
    if (wantarray) {
	return @res;
    }
    return join(',',@res);
}
