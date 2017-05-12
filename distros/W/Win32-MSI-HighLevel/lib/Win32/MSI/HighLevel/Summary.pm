use strict;
use warnings;

=head1 NAME

Win32::MSI::HighLevel::Summary - Helper module for Win32::MSI::HighLevel.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


package Win32::MSI::HighLevel::Summary;

use Win32::API;
use Win32::MSI::HighLevel::Handle;
use Carp;

use base qw(Win32::MSI::HighLevel::Handle);

my $MsiGetSummaryInformation = Win32::MSI::HighLevel::Common::_def(MsiGetSummaryInformation => "IPIP");
my $MsiSummaryInfoGetProperty = Win32::MSI::HighLevel::Common::_def(MsiSummaryInfoGetProperty => "IIPPPPP");
my $MsiSummaryInfoGetPropertyCount = Win32::MSI::HighLevel::Common::_def(MsiSummaryInfoGetPropertyCount => "IP");
my $MsiSummaryInfoPersist = Win32::MSI::HighLevel::Common::_def(MsiSummaryInfoPersist => "I");
my $MsiSummaryInfoSetProperty = Win32::MSI::HighLevel::Common::_def(MsiSummaryInfoSetProperty => "IIIIPP");
my %pidLookup = (
    PID_CODEPAGE => [qw(1 VT_I2)],
    PID_TITLE => [qw(2 VT_LPSTR)],
    PID_SUBJECT => [qw(3 VT_LPSTR)],
    PID_AUTHOR => [qw(4 VT_LPSTR)],
    PID_KEYWORDS => [qw(5 VT_LPSTR)],
    PID_COMMENTS => [qw(6 VT_LPSTR)],
    PID_TEMPLATE => [qw(7 VT_LPSTR)],
    PID_LASTAUTHOR => [qw(8 VT_LPSTR)],
    PID_REVNUMBER => [qw(9 VT_LPSTR)],
    PID_LASTPRINTED => [qw(11 VT_FILETIME)],
    PID_CREATE_DTM => [qw(12 VT_FILETIME)],
    PID_LASTSAVE_DTM => [qw(13 VT_FILETIME)],
    PID_PAGECOUNT => [qw(14 VT_I4)],
    PID_WORDCOUNT => [qw(15 VT_I4)],
    PID_CHARCOUNT => [qw(16 VT_I4)],
    PID_APPNAME => [qw(18 VT_LPSTR)],
    PID_SECURITY => [qw(19 VT_I4)],
    );
my $ERROR_MORE_DATA = 234;

# View caches column name to number mapping and column name to type mapping.
#   Column numbers are keyed by columnName#
#   Column types are keyed by columnName!

sub new {
    my ($type, $highLevel, %params) = @_;
    my $class = ref $type || $type;

    croak "Constructor requires a HighLevel object as the first parameter"
        unless defined $highLevel and $highLevel->isa ('Win32::MSI::HighLevel');

    my $hdl = Win32::MSI::HighLevel::Handle->null ();
    my $filename;

    $params{result} = $MsiGetSummaryInformation->Call
        ($highLevel->{handle}, 0, 19, $hdl);

    croak Win32::MSI::HighLevel::_errorMsg ($highLevel)
        if $params{result};

    $params{_typeLookup} = {VT_I2 => 2, VT_I4 => 3, VT_FILETIME => 64, VT_LPSTR => 30};

    return $class->SUPER::new ($hdl, %params, highLevel => $highLevel);
}


sub DESTROY {
    my $self = shift;
    my $result = $MsiSummaryInfoPersist->Call ($self->{handle});

    croak "Error code $self->{result} persisting Summary Stream"
        if $self->{result};

    $self->{highLevel} = undef;
    $self->SUPER::DESTROY ();
}


    #Property name           Property ID         PID Type
    #Codepage                PID_CODEPAGE        1   VT_I2
    #Title                   PID_TITLE           2   VT_LPSTR
    #Subject                 PID_SUBJECT         3   VT_LPSTR
    #Author                  PID_AUTHOR          4   VT_LPSTR
    #Keywords                PID_KEYWORDS        5   VT_LPSTR
    #Comments                PID_COMMENTS        6   VT_LPSTR
    #Template                PID_TEMPLATE        7   VT_LPSTR
    #Last Saved By           PID_LASTAUTHOR      8   VT_LPSTR
    #Revision Number         PID_REVNUMBER       9   VT_LPSTR
    #Last Printed            PID_LASTPRINTED     11  VT_FILETIME
    #Create Time/Date        PID_CREATE_DTM      12  VT_FILETIME
    #Last Save Time/Date     PID_LASTSAVE_DTM    13  VT_FILETIME
    #Page Count              PID_PAGECOUNT       14  VT_I4
    #Word Count              PID_WORDCOUNT       15  VT_I4
    #Character Count         PID_CHARCOUNT       16  VT_I4
    #Creating Application    PID_APPNAME         18  VT_LPSTR
    #Security                PID_SECURITY        19  VT_I4


sub getProperty {
    my ($self, $propertyId) = @_;

    croak "Invalid property for Summary Stream: $propertyId"
        unless exists $pidLookup {$propertyId};

    my ($id, $type) = @{$pidLookup {$propertyId}};
    my $iValue = 0;
    my $fValue = Win32::MSI::HighLevel::Handle->null ();
    my $sValue = '';
    my $sLen = pack ("l", 0);

    $self->{result} = $MsiSummaryInfoGetProperty->Call
        ("$self->{handle}", $id, $type, $iValue, $fValue, $sValue, $sLen);

    croak "Error code $self->{result} for Summary Stream property $propertyId"
        if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    $type = unpack ('l', $type);
    if ($type eq $self->{_typeLookup}{VT_LPSTR}) {
        $sLen = unpack ("l", $sLen);

        if ($sLen) {
            my $size = $sLen * 2; # length to UTF-16 size

            $sValue = "\0" x $size;
            $self->{result} = $MsiSummaryInfoGetProperty->Call
                ("$self->{handle}", $id, $type, $iValue, $fValue, $sValue, $sLen);

            croak "Error code $self->{result} for Summary Stream property $propertyId"
                if $self->{result};

            # Now UTF-8 encoded, trim to $sLen
            $sValue = substr $sValue, 0, $sLen;
        } else {
            $sValue = '';
        }

        return $sValue;

    } elsif ($type eq 'VT_FILETIME') {
        croak "VT_FILETIME properties such as $propertyId are not currently Win32::MSI::HighLevel::Handled."
            if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    } elsif ($type eq $self->{_typeLookup}{VT_I4} || $type eq $self->{_typeLookup}{VT_I2}) {
        return $iValue;
    }
}


sub setProperty {
    my ($self, $propertyId, $value) = @_;

    croak "Invalid property for Summary Stream: $propertyId"
        unless exists $pidLookup {$propertyId};

    my ($id, $type) = @{$pidLookup {$propertyId}};
    my $iValue = 0;
    my $fValue = Win32::MSI::HighLevel::Handle->null ();
    my $sValue = '';

    if ($type eq 'VT_I2' || $type eq 'VT_I2') {
        $iValue = $value;

    } elsif ($type eq 'VT_FILETIME') {
        croak "VT_FILETIME properties such as $propertyId are not currently Win32::MSI::HighLevel::Handled."
            if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    } elsif ($type eq 'VT_LPSTR') {
        $sValue = $value;
    }

    $type = $self->{_typeLookup}{$type};
    $self->{result} = $MsiSummaryInfoSetProperty->Call
        ("$self->{handle}", $id, $type, $iValue, $fValue, $sValue);

    croak "Error code $self->{result} for Summary Stream property $propertyId"
        if $self->{result};
}


1;
