package WebService::FuncNet::JobStatus;

use strict;
use warnings;

our $VERSION = '0.2';

=head1 NAME

WebService::FuncNet::JobStatus - An object representing the status of a FuncNet session

=head1 0.1

This document describes JobStatus version 0.1

=head1 SYNOPSIS

    use WebService::FuncNet::JobStatus;

    my $status = JobStatus->new( $myStatus, $myXmlTrace );
    
    print $status->status();
    
    print $status->trace();
      
=head2 new

Constructs a new JobStatus object with a status code and XML trace supplied.

=cut

sub new {
    my $class = shift;
    my $self  = {
        STATUS => shift,
        TRACE  => shift
    };
    bless $self, $class;
    return $self;
}

=head2 status

Returns the actual status code of the job: I<WORKING>, I<COMPLETE>, I<CANCELLED>, I<FAILURE>, I<EXPIRED>, I<UNKNOWN>.

=cut

sub status {
    my $self = shift;
    return $self->{ STATUS };
}

=head2 trace

Returns the raw XML of the status response.

=cut

sub trace {
    my $self = shift;
    return $self->{ TRACE };
}

1;                              # Magic true value required at end of module
__END__


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Status requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-<RT NAME>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

clegg  C<< <<andrew.clegg@uclmail.net>> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) <2009>, <clegg> C<< <<andrew.clegg@uclmail.net>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 REVISION INFO

  Revision:      $Rev: 64 $
  Last editor:   $Author: andrew_b_clegg $
  Last updated:  $Date: 2009-07-06 16:12:20 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
