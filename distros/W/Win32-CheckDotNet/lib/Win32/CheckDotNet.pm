package Win32::CheckDotNet;

use 5.016003;
use strict;
use warnings;
use utf8;
use Moose;
use Win32API::Registry qw( regLastError KEY_READ KEY_WRITE KEY_ALL_ACCESS);
use Win32::TieRegistry;
use Log::Log4perl qw/get_logger :levels/;
use Data::Dumper qw/Dumper/;

our $VERSION = '0.02';

=head1 NAME

Win32::CheckDotNet - Perl extension for checking installed .NET versions

=head1 SYNOPSIS

  use Win32::CheckDotNet;

  my $check = Win32::CheckDotNet->new;
  printf ".NET 4.5 full -> %s\n", $check->check_dotnet_4_5;
  printf ".NET 4.0 full -> %s\n", $check->check_dotnet_4_0_full;
  printf ".NET 4.0 client -> %s\n", $check->check_dotnet_4_0_client;
  printf ".NET 3.5 -> %s\n", $check->check_dotnet_3_5;
  printf ".NET 3.0 -> %s\n", $check->check_dotnet_3_0;
  printf ".NET 2.0 -> %s\n", $check->check_dotnet_2_0;
  printf ".NET 1.1 -> %s\n", $check->check_dotnet_1_1;
  printf ".NET 1.0 -> %s\n", $check->check_dotnet_1_0;

=head1 DESCRIPTION

This module inspects the Windows Registry to check if .NET is installed.
Various versions can be checked.

=head1 METHODS

=head2 check_dotnet_1_0()

Checks if .NET version 1.0 is installed.

=cut

sub check_dotnet_1_0 {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/.NETFramework/Policy/v1.0';
    
    return $self->_check_registry_key($registry_key, '3705');
} # /check_dotnet_1_0




=head2 check_dotnet_1_1()

Checks if .NET version 1.1 is installed.

=cut

sub check_dotnet_1_1 {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/NET Framework Setup/NDP/v1.1.4322';
    
    return $self->_check_registry_key($registry_key, 'Install');
} # /check_dotnet_1_1




=head2 check_dotnet_2_0()

Checks if .NET version 2.0 is installed.

=cut

sub check_dotnet_2_0 {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/NET Framework Setup/NDP/v2.0.50727';
    
    return $self->_check_registry_key($registry_key, 'Install');
} # /check_dotnet_2_0




=head2 check_dotnet_3_0()

Checks if .NET version 3.0 is installed.

=cut

sub check_dotnet_3_0 {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/NET Framework Setup/NDP/v3.0/Setup';
    
    return $self->_check_registry_key($registry_key, 'InstallSuccess');
} # /check_dotnet_3_0




=head2 check_dotnet_3_5()

Checks if .NET version 3.5 is installed.

=cut

sub check_dotnet_3_5 {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/NET Framework Setup/NDP/v3.5';
    
    return $self->_check_registry_key($registry_key, 'Install');
} # /check_dotnet_3_5




=head2 check_dotnet_4_0_full()

Checks if .NET version 4.0 (full) is installed.

=cut

sub check_dotnet_4_0_full {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/NET Framework Setup/NDP/v4/Client';
    
    return $self->_check_registry_key($registry_key, 'Install');
} # /check_dotnet_4_0_full




=head2 check_dotnet_4_0_client()

Checks if .NET version 4.0 (client) is installed.

=cut

sub check_dotnet_4_0_client {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/NET Framework Setup/NDP/v4/Full';
    
    return $self->_check_registry_key($registry_key, 'Install');
} # /check_dotnet_4_0_client




=head2 check_dotnet_4_5()

Checks if .NET version 4.5 is installed.

=cut

sub check_dotnet_4_5 {
    my $self = shift;
    
    my $registry_key = 'HKEY_LOCAL_MACHINE/Software/Microsoft/NET Framework Setup/NDP/v4/Full';
    
    return $self->_check_registry_key($registry_key, 'Release');
} # /check_dotnet_4_5




=head2 _check_registry_key( $key )

Checks for a given .NET registry key. Returns 1 if registry key is present and has value C<0x00000001>.
Returns 0 if registry key is not present or does not equals C<0x00000001>.

C<$key> has to have C</> as delimiter.

=cut

sub _check_registry_key {
    my $self = shift;
    my $registry_key = shift or die('Missing registry key');
    my $registry_value = shift or die('Missing registry value');

    my $logger = get_logger('Win32::CheckDotNet');
    
    my $key = Win32::TieRegistry->new( $registry_key, { Access => KEY_READ(), Delimiter => '/' } );
    if( $key ) {
        $logger->trace("Registry key for .NET was found: $registry_key");
        
        # If the registry key was found, try to read the value of InstallLocation
        my ( $install, undef ) = $key->GetValue($registry_value);
        
        return 0 unless defined $install;
        
        $logger->trace("Install value for .NET key [$registry_key] is [$install]");
        return 1 if $install eq '0x00000001';
        return 0;
        
    }else {
        # The key for .NET
        $logger->debug("Unable to read registry key [$registry_key]: " . Win32API::Registry::regLastError());
        
        # If the key was not found, this indicated that .NET version is not installed.
        return 0;
    }
    
    return undef; # shouldn't be here
} # /_check_registry_key




=head1 SEE ALSO

Once I asked how to heck for an installed .NET version.
The answer was a link to the list of registry keys that identify if .NET is installed and the Tie::Registry module.

=over

=item * L<http://stackoverflow.com/questions/199080/how-to-detect-what-net-framework-versions-and-service-packs-are-installed/199783#199783>

=item * L<http://stackoverflow.com/questions/18188507/how-can-i-check-if-net-is-installed-using-perl>

=back




=head1 AUTHOR

Alexander Becker, E<lt>c a p f a n .a-t' g m x ^dot. d eE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Alexander Becker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

1; # /Win32::CheckDotNet