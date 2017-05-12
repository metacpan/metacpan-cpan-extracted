package WWW::Postini::Constants;

use strict;
use warnings;

use Exporter;

use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS $VERSION );

use constant SHOW_ALL          => 0;
use constant SHOW_QUARANTINED  => 1;
use constant SHOW_DELIVERED    => 2;
use constant SHOW_DELETED      => 3;

use constant SORT_NONE         => 0;
use constant SORT_RECIPIENT    => 1;
use constant SORT_SENDER       => 3;
use constant SORT_SUBJECT      => 4;
use constant SORT_FILTER       => 5;

use constant RECIPIENT_USER    => 0;
use constant RECIPIENT_ADMIN   => 1;

$VERSION = '0.01';

@ISA = qw( Exporter );

@EXPORT_OK = qw(
	SHOW_ALL
	SHOW_QUARANTINED
	SHOW_DELIVERED
	SHOW_DELETED
	
	SORT_NONE
	SORT_RECIPIENT
	SORT_SENDER
	SORT_SUBJECT
	SORT_FILTER
	
	RECIPIENT_USER
	RECIPIENT_ADMIN
);

%EXPORT_TAGS = (
	'all'  => [qw(
		SHOW_ALL
		SHOW_QUARANTINED
		SHOW_DELIVERED
		SHOW_DELETED
		SORT_NONE
		SORT_RECIPIENT
		SORT_SENDER
		SORT_SUBJECT
		SORT_FILTER
		RECIPIENT_USER
		RECIPIENT_ADMIN
	)],
	'show' => [qw(
		SHOW_ALL
		SHOW_QUARANTINED
		SHOW_DELIVERED
		SHOW_DELETED
	)],
	'sort' => [qw(
		SORT_NONE
		SORT_RECIPIENT
		SORT_SUBJECT
		SORT_FILTER
	)],
	'recipient' => [qw(
		RECIPIENT_USER
		RECIPIENT_ADMIN
	)]
);

1;

__END__

=head1 NAME

WWW::Postini::Constants - Exportable constants for use with WWW::Postini

=head1 SYNOPSIS

  use WWW::Postini::Constants ':all';

=head1 DESCRIPTION

The WWW::Postini::Constants module contains a collection of constants
intended for use with WWW::Postini.  This single module approach is
taken for the sake of consistency.

=head1 CONSTANTS

=head2 Message searching

These constants are intended for use with the C<show> parameter of the
C<list_messages()> method in
L<WWW::Postini|WWW::Postini>.

=over 4

=item C<SHOW_ALL>

Show all messages

=item C<SHOW_QUARANTINED>

Show only quarantined messages

=item C<SHOW_DELIVERED>

Show messages which have already been delivered

=item C<SHOW_DELETED>

Show deleted messages

=back

=head2 Message sorting

These constants are intended for use with the C<sort> parameter of the
C<list_messages()> method in
L<WWW::Postini|WWW::Postini>.

=over 4

=item C<SORT_NONE>

Do not sort messages

=item C<SORT_RECIPIENT>

Sort by recipient

=item C<SORT_SENDER>

Sort by sender

=item C<SORT_SUBJECT>

Sort by subject

=item C<SORT_FILTER>

Sort by filter

=back

=head2 Message recipient

These constants are intended for use with the C<recipient> parameter of the
C<list_messages()> method in
L<WWW::Postini|WWW::Postini>.

=over 4

=item C<RECIPIENT_USER>

Set recipient to the original user

=item C<RECIPIENT_ADMIN>

Set recipient to the administrator

=back

=head1 EXPORTS

By default, nothing is exported from this module.  Constants may be imported
individually or via the provided export groups below.

=over 4

=item C<:all>

Exports all constants

=item C<:show>

Exports all C<SHOW_> constants

=item C<:sort>

Exports all C<SORT_> constants

=item C<:recipient>

Exports all C<RECIPIENT_> constants

=back

=head1 SEE ALSO

L<WWW::Postini>

=head1 AUTHOR

Peter Guzis, E<lt>pguzis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Peter Guzis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Postini, the Postini logo, Postini Perimeter Manager and preEMPT are
trademarks, registered trademarks or service marks of Postini, Inc. All
other trademarks are the property of their respective owners.

=cut