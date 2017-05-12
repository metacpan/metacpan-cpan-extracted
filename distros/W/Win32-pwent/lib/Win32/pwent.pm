package Win32::pwent;

use warnings;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(getpwent endpwent setpwent getpwnam getpwuid getgrent entgrent setgrent getgrnam getgrgid);

use File::Spec;

use Win32;
use Win32::NetAdmin;
use Win32::TieRegistry Delimiter => "/";
use Win32API::Net 0.13; # for USER_INFO_4 structure

=head1 NAME

Win32::pwent - pwent and grent support for Win32

=cut

our $VERSION = '0.100';

=head1 SYNOPSIS

    use Win32;
    use Win32::pwent qw(getpwnam getpwent endpwent);

    my $uid = getpwnam(getlogin);
    my $win32login = Win32::LoginName();
    while( my @pwent = getpwent )
    {
        if( $pwent[0] eq $win32login and $pwent[2] == $uid )
        {
            print( "It's me \\o/\n" );
            endpwent();
            last;
        }
    }

=head1 DESCRIPTION

Win32::pwent should help building a bridge for Perl scripts running on
Unix like systems to Win32.

It supports reading access to LanManager User-Info structures via the
well known pwent and grent functions.

=head1 EXPORT

Win32::pwent doesn't export anything by default. Following function can
be imported explicitely: C<endgrent>, C<getpwent>, C<getpwnam>, C<getpwuid>,
C<entgrent>, C<getgrent>, C<getgrnam>, C<getgrgid>

=head1 SUBROUTINES/METHODS

All exported subroutines behaves as the same ones for Unix-like systems
provided by Perl itself. See L<http://perldoc.perl.org/>.

=head2 getpwent

Returns the next entry from user list got from LANMAN user database.
If this is the first call to C<getpwent> (or the first call after an
C<endpwent> call), a user cache based on the LANMAN database using the
functions C<GetUsers> and C<UserGetInfo> from the module L<Win32API::Net>
is created.

see L<http://perldoc.perl.org/functions/getpwent.html>

=head2 endpwent

Free the user list cache and rewind the pointer for the next user entry.

see L<http://perldoc.perl.org/functions/endpwent.html>

=head2 setpwent

Rewind the pointer for the next user entry.

see L<http://perldoc.perl.org/functions/setpwent.html>

=head2 getpwnam

Fetches the user (by name) entry from LANMAN user database and return it

see L<http://perldoc.perl.org/functions/getpwnam.html>

=head2 getpwuid

fetches the user (by user id) entry from LANMAN user database and return it

see L<http://perldoc.perl.org/functions/getpwuid.html>

=head2 getgrent

Return the next group entry from LANMAN group database. If this is the first
call to C<getgrent> (or the first call after an C<endgrent> call), a group
cache based on the LANMAN database using the functions C<GroupEnum> and
C<GroupGetInfo> from the module L<Win32API::Net> is created.

see L<http://perldoc.perl.org/functions/getgrent.html>

=head2 endgrent

Free the group list cache and rewind the pointer for the next group entry.

see L<http://perldoc.perl.org/functions/getgrent.html>

=head2 setgrent

Rewind the pointer for the next group entry.

see L<http://perldoc.perl.org/functions/getgrent.html>

=head2 getgrnam

Fetches the group (by name) entry from LANMAN user database and return
it.  This function doesn't uses the groups cache from getgrent.

see L<http://perldoc.perl.org/functions/getgrnam.html>

=head2 getgrgid

Fetches the group (by group id) entry from LANMAN user database and return
it.  This function doesn't uses the groups cache from getgrent.

see L<http://perldoc.perl.org/functions/getgruid.html>

=cut

sub _fillpwent
{
    my $userName = $_[0];

    my %userInfo;
    if( Win32API::Net::UserGetInfo( "", $userName, 4, \%userInfo ) )
    {
        $userInfo{userId} = $1 if( $userInfo{userSid} =~ m/-(\d+)$/ );
    }
    else
    {
        Win32API::Net::UserGetInfo( "", $userName, 3, \%userInfo )
            or die "UserGetInfo() failed: $^E";
    }

    if( defined( $userInfo{userSid} ) )
    {
        unless( defined( $userInfo{homeDir} ) && ( $userInfo{homeDir} ne '' ) )
        {
            my $regPath = "LMachine/SOFTWARE/Microsoft/Windows NT/CurrentVersion/ProfileList/" . $userInfo{userSid} . "/ProfileImagePath";
            $userInfo{homeDir} = $Registry->{$regPath};
        }

        #my $console;
        #$::HKEY_USERS->Open( $userInfo{userSid} . "\\Console", $console );
        # find tree item - e.g. %SystemRoot%_system32_cmd.exe
        $userInfo{shell} = File::Spec->catfile( $ENV{SystemRoot}, 'system32', 'cmd.exe' );

    }
    else
    {
        $userInfo{shell} = File::Spec->catfile( $ENV{SystemRoot}, 'system32', 'cmd.exe' );
    }
    my @pwent = ( @userInfo{'name', 'password', 'userId', 'primaryGroupId', 'maxStorage', 'comment', 'fullName', 'homeDir', 'shell', 'acctExpires'} );

    return \@pwent;
}

sub _fillpwents
{
    my @pwents;
    my %users;
    Win32::NetAdmin::GetUsers( "", 0, \%users )
        or die "GetUsers() failed: $^E";
    foreach my $userName (keys %users)
    {
        push( @pwents, _fillpwent( $userName ) );
    }

    return \@pwents;
}

my $pwents;
my $pwents_pos;

sub getpwent
{
    unless( "ARRAY" eq ref($pwents) )
    {
        $pwents = _fillpwents();
    }
    defined $pwents_pos or $pwents_pos = 0;
    my @pwent = @{$pwents->[$pwents_pos++]} if( $pwents_pos < scalar(@$pwents) );
    return wantarray ? @pwent : $pwent[2];
}

sub setpwent { $pwents_pos = undef; }

sub endpwent { $pwents = $pwents_pos = undef; }

sub getpwnam
{
    my $userName = $_[0];
    my $pwent = _fillpwent( $userName );
    return wantarray ? @$pwent : $pwent->[2];
}

sub getpwuid
{
    my $uid = $_[0];
    my $pwents = _fillpwents();
    my @uid_pwents = grep { $uid == $_->[2] } @$pwents;
    my @pwent = @{$uid_pwents[0]} if( 1 <= scalar(@uid_pwents) );
    return wantarray ? @pwent : $pwent[0];
}

sub _fillgrent
{
    my $grNam = $_[0];
    my %grInfo;
    unless( Win32API::Net::GroupGetInfo( "", $grNam, 2, \%grInfo ) )
    {
        Win32API::Net::GroupGetInfo( "", $grNam, 3, \%grInfo )
            or die "GroupGetInfo failed $^E";
        $grInfo{groupId} = $1 if( $grInfo{groupSid} =~ m/-(\d+)$/ );
    }
    my @grent = ( $grInfo{name}, undef, $grInfo{groupId} );
    my @grusers;
    Win32API::Net::GroupGetUsers( "", $grNam, \@grusers )
        or die "GroupGetUsers failed $^E";
    push( @grent, join( ' ', @grusers ) );
    return \@grent;
}

sub _fillgrents
{
    my @groupNames;
    Win32API::Net::GroupEnum( "", \@groupNames )
        or die "GroupEnum failed: $^E";
    my @grents;
    foreach my $groupName (@groupNames)
    {
        my $grent = _fillgrent($groupName);
        push( @grents, $grent );
    }
    return \@grents;
}

my $grents;
my $grents_pos;

sub getgrent
{
    unless( "ARRAY" eq ref($grents) )
    {
        $grents = _fillgrents();
    }
    defined $grents_pos or $grents_pos = 0;
    my @grent = @{$grents->[$grents_pos++]} if( $grents_pos < scalar(@$grents) );
    return wantarray ? @grent : $grent[2];
}

sub setgrent { $grents_pos = undef; }

sub endgrent { $grents = $grents_pos = undef; }

sub getgrnam
{
    my $groupName = $_[0];
    my $grent = _fillgrent( $groupName );
    return wantarray ? @$grent : $grent->[2];
}

sub getgrgid
{
    my $gid = $_[0];
    my $grents = _fillgrents();
    my @gid_grents = grep { $gid == $_->[2] } @$grents;
    my @grent = @{$gid_grents[0]} if( 1 <= scalar(@gid_grents) );
    return wantarray ? @grent : $grent[0];
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Win32::pwent uses the LAN manager interface, so it might be possible that
users and groups from Active Directory are not recognized.

All functions provided by Win32::pwent are pure perl functions, so they
don't provide the additional features the core functions provide, because
the core implementation handles them as operators.

If you think you've found a bug then please also read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

Please report any bugs or feature requests to
C<bug-win32-pwent at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-pwent>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::pwent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-pwent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-pwent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-pwent>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-pwent/>

=back

Please recognize that the development of Open Source is done in free time of
volunteers.

=head1 ACKNOWLEDGEMENTS

Jan Dubios from ActiveState who helped me through the required patches for
L<Win32API::Net> and give a lot feedback regarding compatibility.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Win32::pwent
