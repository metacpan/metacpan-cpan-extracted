package Win32::DriverQuery;

=head1 NAME

Win32::DriverQuery - query system for installed drivers and their versions

=head1 SYNOPSIS

  my @modules = Win32::DriverQuery->query;
  print join(' :: ', $_->{FullPathName}, ($_->{version}//'undef'),
    ( -e $_->{FullPathName} ? "" : "no path" )), "\n" for @modules;

=head1 DESCRIPTION

The class method C<query> returns a list of hashrefs with keys C<FullPathName> and C<version>, for each installed driver.

=head1 AUTHOR

Ed J took Daniel Dragan's excellent script and made it into a module.

=cut

use strict;
use warnings;
use Win32::API;
use Win32;
use Config;

our $VERSION = '0.02';

my @MEMBERS = qw(
      HANDLE Section;
      HANDLE MappedBase;
      HANDLE ImageBase;
      ULONG ImageSize;
      ULONG Flags;
      USHORT LoadOrderIndex;
      USHORT InitOrderIndex;
      USHORT LoadCount;
      USHORT OffsetToFileName;
      UCHAR FullPathName[256];
);
Win32::API::Struct->typedef('RTL_PROCESS_MODULE_INFORMATION', @MEMBERS);

Win32::API->Import(
    'ntdll', 'NTSTATUS WINAPI NtQuerySystemInformation(
  int SystemInformationClass,
  char * SystemInformation,
  ULONG SystemInformationLength,
  char * ReturnLength
);'
);

my @E = map { s/[^A-Za-z]//gr } keys %{{ reverse @MEMBERS }};
my $INIT_POS = $Config{archname} =~ /64/ ? 8 : 4;

sub query {
  my ($class) = shift;
  my $info = Win32::API::Struct->new( 'RTL_PROCESS_MODULE_INFORMATION' );
  my $buf = "\x00" x 1000000;
  my $len = "\x00\x00\x00\x00";
  my $ntstatus = NtQuerySystemInformation( 11, $buf, 1000000, $len );
  die "NtQuerySystemInformation failed with NTSTATUS $ntstatus" if $ntstatus != 0;
  my $NumberOfModules = unpack( 'L', $buf );
  $len = unpack( 'L', $len );
#print "got len $len count $NumberOfModules\n";

  my $pos = $INIT_POS;
  my @modules;

  for ( 0 .. $NumberOfModules - 1 ) {
    @{$info}{@E} = ( (1) x @E ); # otherwise get "uninit" warnings in line below
    $info->Pack();
    $info->{buffer} = substr( $buf, $pos, $info->sizeof() );
    $info->Unpack();
    my %h;
    @h{@E} = @{$info}{@E};
    $h{FullPathName} =~ s/^\\SystemRoot/c:\\windows/;
    $h{FullPathName} =~ s/^\\\?\?\\//;
    $h{FullPathName} =~ s/^\\Windows/c:\\windows/;
    $h{version} = Win32::GetFileVersion( $h{FullPathName} );
    push @modules, \%h;
    $pos += $info->sizeof;
  }
  @modules;
}

1;
