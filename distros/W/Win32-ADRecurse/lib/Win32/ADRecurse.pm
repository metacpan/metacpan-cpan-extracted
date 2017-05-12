package Win32::ADRecurse;
{
  $Win32::ADRecurse::VERSION = '0.04';
}

#ABSTRACT: recursively examine an Active Directory structure

use strict;
use warnings;
use Win32::OLE 'in';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(recurse examine);  # symbols to export on request

sub recurse {
  my $ref = shift;
  my $DOMAIN = shift;
  die "Argument must be a CODEREF\n" unless $ref and ref $ref eq 'CODE';
  unless ( $DOMAIN ) {
    my $objRootDSE = Win32::OLE->GetObject('LDAP://RootDSE');
    $DOMAIN  = $objRootDSE->Get("defaultNamingContext");
  }
  my $domain = Win32::OLE->GetObject("LDAP://$DOMAIN");
  examine($ref,$_->{AdsPath}) for in $domain;
}

sub examine {
  my $ref = shift;
  my $adspath = shift;
  my $ou = Win32::OLE->GetObject($adspath);
  foreach my $child ( in $ou ) {
    if ($child->{Class} =~ m!^(organizationalUnit|container)$! ) {
      examine($ref,$child->{AdsPath});
    }
    else {
      $ref->($child->{AdsPath},$child->{Class});
    }
  }
}

qq[Recurse this AD];


__END__
=pod

=head1 NAME

Win32::ADRecurse - recursively examine an Active Directory structure

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # Recurse through an entire Active Directory producing
  # CSV formatted records about each user

  use strict;
  use warnings;
  use Time::Piece;
  use Text::CSV;
  use Win32::OLE;
  use Win32::ADRecurse qw[recurse];

  $|=1;

  my $csv = Text::CSV->new();

  recurse(
    sub {
      my $adspath = shift;
      my $class = shift;
      return unless $class eq 'user';
      my $user = Win32::OLE->GetObject($adspath);
      return unless $user;
      $user->GetInfo;
      return if $user->{userAccountControl} & 0x0002; # skip disabled accounts
      my $when = '';
      eval {
        my $t = Time::Piece->strptime( $user->{whenCreated}, "%m/%d/%Y %I:%M:%S %p" );
        $when = $t->strftime( '%Y/%m/%d %H:%M:%S' );
      };
      my $last = '';
      eval {
        $last = time2str("%Y/%m/%d %T", msqtime2perl( $user->{lastLogonTimestamp} ) );
      };
      $csv->combine( ( map { s/\n/ /g; s/[^[:print:]]+//g; $_ } map { $user->{$_} || '' }
        qw(sAMAccountName givenName initials sn displayName mail employeeID
           title department company physicalDeliveryOfficeName streetAddress l postalCode) ), $last, $when )
        and print $csv->string(), "\n";
    },
  );

  exit 0;

  sub msqtime2perl { # MicroSoft QuadTime to Perl
    my $foo = shift;
    my ($high,$low) = map { $foo->{ $_ } } qw(HighPart LowPart);
    return unless $high and $low;
    return ((unpack("L",pack("L",$low)) + (unpack("L",pack("L",$high)) *
      (2 ** 32))) / 10000000) - 11644473600;
  }

=head1 DESCRIPTION

Win32::ADRecurse is a module that provides functions to recursively examine an
Active Directory.

A provided subroutine is called for non-OU/container within the AD structure.

You can manipulate each AD item within the provided subroutine in any way that
you fit, using Active Directory Service Interfaces for instance.

=head1 FUNCTIONS

The following functions may be imported if requested.

=over

=item C<recurse>

Takes two arguments.

  A coderef, mandatory
  An Active Directory DNS name, optional.

The coderef provided will be invoked for each non-OU or non-container object within the Active Directory
structure with two parameters.

  $_[0] - ADSPath of the object in Active Directory
  $_[1] - The ADS class of the object

If no Active Directory DNS name is provided, the current AD will be used.

=item C<examine>

This is similar to C<recurse> (in fact C<recurse> utilises this function itself), but allows
the start point of the recursion to be at levels lower that the root of the Active Directory.

Takes two arguments.

  A coderef, mandatory
  An Active Directory ADSPath of an OU or Container, mandatory

The coderef provided will be invoked for each non-OU or non-container object within the Active Directory
structure with two parameters.

  $_[0] - ADSPath of the object in Active Directory
  $_[1] - The ADS class of the object

=back

=head1 SEE ALSO

L<Win32::OLE>

L<Win32::NameTranslate>

L<http://en.wikipedia.org/wiki/Active_Directory_Service_Interfaces>

L<http://msdn.microsoft.com/en-us/library/windows/desktop/aa772170%28v=vs.85%29.aspx>

=head1 AUTHOR

Chris 'BinGOs' Williams <bingos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

