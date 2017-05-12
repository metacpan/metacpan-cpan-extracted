package VUser::Google::ProvisioningAPI::V2_0::UserEntry;
use warnings;
use strict;

use vars qw($AUTOLOAD);

use Carp;

our $VERSION = '0.2.0';

sub new {
    my $object = shift;
    my $class = ref($object) || $object;


    #LP: changePasswordAtNextLogin
    my ($user, $password, $family_name, $given_name, $quota, $email, $isSuspended, $changePasswordAtNextLogin, $hashFunctionName);

    if (defined $isSuspended) {
	$isSuspended = ($isSuspended)? '1' : '0';
    }

    #LP: changePasswordAtNextLogin
    if (defined $changePasswordAtNextLogin) {
	$changePasswordAtNextLogin = ($changePasswordAtNextLogin)? '1' : '0';
    }

    # This doesn't quite match the Java API but I don't really care right now.
    # This is much easier. Perhaps, at some point in the future, this can
    # be changed to match the Java API a little more.
    my $self = {
	'User' => $user,
	'Password' => $password,
	'isSuspended' => $isSuspended,
	'FamilyName' => $family_name,
	'GivenName' => $given_name,
	'Email' => $email,
	'Quota' => $quota,
    #LP: changePasswordAtNextLogin
	'changePasswordAtNextLogin' => $changePasswordAtNextLogin,
	'hashFunctionName' => $hashFunctionName,
    };
        
    bless $self, $class;
    return $self;
}

# Alias to match the Java API a little more
sub Suspended { $_[0]->isSuspended(@_); }

sub isSuspended {
    my $self = shift;
    my $suspended = shift;

    if (defined $suspended) {
	if (lc($suspended) eq 'false') {
	    $self->{'isSuspended'} = 0;
	} elsif (not $suspended) {
	    $self->{'isSuspended'} = 0;
	} else {
	    $self->{'isSuspended'} = 1;
	}
    }
    return $self->{'isSuspended'};
}

#LP: changePasswordAtNextLogin
sub changePasswordAtNextLogin {
    my $self = shift;
    my $changePassword = shift;

    if (defined $changePassword) {
	if (lc($changePassword) eq 'false') {
	    $self->{'changePasswordAtNextLogin'} = 0;
	} elsif (not $changePassword) {
	    $self->{'changePasswordAtNextLogin'} = 0;
	} else {
	    $self->{'changePasswordAtNextLogin'} = 1;
	}
    }
    return $self->{'changePasswordAtNextLogin'};
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

VUser::Google::ProvisioningAPI::V2_0::UserEntry - Google Provisioning API 2.0 User entry

=head1 SYNOPSIS

 my $entry = VUser::Google::ProvisioningAPI::V2_0::UserEntry->new();
 $entry->User('foo'); # set the user name to 'foo'
 $entry->GivenName('Fred');
 $entry->FamilyName('Oog');

=head1 ACCESSORS

=over

=item User

=item Password

=item isSuspended

=item FamilyName

=item GivenName

=item Email

=item Quota

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
