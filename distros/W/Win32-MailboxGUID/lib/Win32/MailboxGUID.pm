package Win32::MailboxGUID;
BEGIN {
  $Win32::MailboxGUID::VERSION = '0.02';
}

#ABSTRACT: functions to convert Exchange mailbox GUIDs

use strict;
use warnings;

our @ISA            = qw[Exporter];
our @EXPORT_OK      = qw[ad_to_exch exch_to_ad];

my $guidre = qr/^\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}$/i;

sub ad_to_exch {
  my $guid = shift;
  $guid = shift if eval { $guid->isa(__PACKAGE__) };
  return unless $guid;
  my @vals = map { sprintf("%.2X", ord $_) } unpack "(a1)*", $guid;
  return unless scalar @vals == 16;
  return join '', '{', @vals[3,2,1,0], '-', @vals[5,4], '-', @vals[7,6], '-', @vals[8,9], '-', @vals[10..$#vals], '}';
}

sub exch_to_ad {
  my $guid = shift;
  $guid = shift if eval { $guid->isa(__PACKAGE__) };
  return unless $guid;
  return unless $guid =~ /$guidre/i;
  $guid =~ s/[\{\}]+//g;
  my $string = '';
  my $count = 0;

  $string .= "\\$_" for
    map { $count++; ( $count >= 4 ? ( unpack "(A2)*", $_ ) : ( reverse unpack "(A2)*", $_ ) ) }
      split /\-/, $guid;

  return $string;
}

q"GUID! GUID, GUID, gum gum";


__END__
=pod

=head1 NAME

Win32::MailboxGUID - functions to convert Exchange mailbox GUIDs

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # Example that requires Win32::OLE, DBI, DBD::ADO and administrative permissions
  # invoked with a list of Exchange servers on the command line to query
  # Use of 'exch_to_ad'

  use strict;
  use warnings;
  use Win32::OLE qw(in);
  use Win32::MailboxGUID qw[exch_to_ad];
  use DBI;

  $|=1;

  my %limitinfo = (
    '1', 'Below Limit',
    '2', 'Issue Warning',
    '4', 'Prohibit Send',
    '8', 'No Checking',
   '16', 'Mailbox Disabled',
  );

  my $Root = Win32::OLE-> GetObject("LDAP://RootDSE");
  my $DefaultDomainNC = $Root-> Get("DefaultNamingContext");
  my $dsn = "Provider=ADsDSOObject;ConnectionString=$DefaultDomainNC";
  my ($usr,$pwd);
  my $att = { };
  my $dbi = DBI->connect("dbi:ADO:$dsn", $usr, $pwd, $att ) or die $DBI::errstr;

  OUTER: foreach my $server ( @ARGV ) {
    my $object = Win32::OLE->GetObject("winmgmts:{impersonationLevel=impersonate}!//$server/root/MicrosoftExchangeV2");
    next OUTER unless $object;
    INNER: foreach my $mailbox ( in $object->InstancesOf("Exchange_Mailbox") ) {

       # Look up the quota info from the user account in AD

       my $mbguid = $mailbox->{MailboxGUID};
       my @quotas = _find_user( $dbi, $mbguid );

       my $limit = defined $mailbox->{StorageLimitInfo} && $limitinfo{ $mailbox->{StorageLimitInfo} } ? $limitinfo{ $mailbox->{StorageLimitInfo} } : '';
       print join ',', $mailbox->{MailboxDisplayName}, $mailbox->{Size}, @quotas, $limit, $mailbox->{ServerName}, $mailbox->{TotalItems} || 0;
       print "\n";
       }
    }
  }

  exit 0;

  sub _find_user {
    my $dbh = shift;

    my $guid = exch_to_ad( shift ); # convert the GUID Exchange to AD

    $guid = $dbi->quote( $guid );
    my $sth = $dbi->prepare(qq{ select AdsPath FROM 'LDAP://$DefaultDomainNC' WHERE msExchMailboxGuid = $guid }) or die "Error $DBI::err ($DBI::errstr)\n";
    $sth->execute() or die "Error $DBI::err ($DBI::errstr)\n";
    while ( my $hashref = $sth->fetchrow_hashref ) {
       my $object = Win32::OLE->GetObject($hashref->{AdsPath});
       next unless $object;
       if ( $object->{mDBUseDefaults} ) {
         return ( 'defaults', 'defaults', 'defaults' );
       }
       else {
         return map { $object->{$_} } qw(mDBStorageQuota mDBOverQuotaLimit mDBOverHardQuotaLimit);
       }
    }
    return ('orphaned','orphaned','orphaned');
  }

=head1 DESCRIPTION

Active Directory and Exchange Server use a GUID to link a user account to a mailbox. Unfortunately, both these
beasts cannot agree on the storage/presentation format of the GUID.

Retrieving user objects from Active Directory with C<ADSI>, the C<msExchMailboxGuid> is in a byte array format,
which can be represented as:

  \C2\A4\11\F9\DE\42\C1\42\8D\97\AB\EF\77\66\06\3C

Whereas using the C<WMI> Exchange provider, C<MailboxGUID> is in the following format:

  {F911A4C2-42DE-42C1-8D97-ABEF7766063C}

This module provides two functions that will convert between these two formats, making the life of the
Win32 Perl scripting system administrator slightly less painful.

=head1 FUNCTIONS

The functions listed may be imported into your namespace on demand.

  use Win32::MailboxGUID qw[ad_to_exch exch_to_ad];

Or called as class methods.

  use Win32::MailBoxGUID;

  my $guid = Win32::MailboxGUID->ad_to_exch( $adexchguid );

=over

=item C<ad_to_exch>

Takes a byte array such as the C<msExchMailboxGuid> attribute from an Active Directory user object.
Returns the GUID as a C<MailboxGUID> formatted string as per the C<Exchange_Mailbox> WMI class.

=item C<exch_to_ad>

Takes a C<MailboxGUID> formatted string as per the C<Exchange_Mailbox> WMI class.
Returns a hex string of the C<msExchMailboxGuid> suitable for searching/updating Active Directory.

=back

=head1 SEE ALSO

L<http://msdn.microsoft.com/en-us/library/aa143732%28v=EXCHG.65%29.aspx>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

