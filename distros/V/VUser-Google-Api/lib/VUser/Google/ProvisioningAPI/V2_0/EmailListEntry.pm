package VUser::Google::ProvisioningAPI::V2_0::EmailListEntry;
use warnings;
use strict;

use vars qw($AUTOLOAD);

use Carp;

our $VERSION = '0.2.0';

sub new {
    my $object = shift;
    my $class = ref($object) || $object;

    my $self = {
	'EmailList' => shift
    };
    bless $self, $class;
    return $self;
}

sub DESTROY { };

sub AUTOLOAD {
    my $self = shift;
    my $member = $AUTOLOAD;
    $member =~ s/.*:://;
    if (exists $self->{$member}) {
	$self->{$member} = $_[0] if defined $_[0];
	return $self->{$member};
    } else {
	croak "Unknown member: $member";
    }
}

=pod

=head1 NAME 

VUser::Google::ProvisioningAPI::V2_0::EmailListEntry - Google Provisioning API 2.0 email list entry

=head1 SYNOPSIS

 my $entry = VUser::Google::ProvisioningAPI::V2_0::EmailListEntry->new();
 $entry->EmailList('bar');

=head1 ACCESSORS

=over

=item EmailList

=back

=head1 AUTHOR

Randy Smith, perlstalker at vuser dot org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Randy Smith, perlstalker at vuser dot org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

