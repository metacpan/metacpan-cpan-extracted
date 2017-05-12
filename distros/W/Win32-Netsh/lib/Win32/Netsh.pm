package Win32::Netsh;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Win32::Netsh - A family of modules for querying and manipulating the network
insterface of a Windows based PC using the netsh utility

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  use Win32::Netsh;
  
  my $response = netsh(qq{wlan}, qq{show}, qq{interfaces});

=cut

##****************************************************************************
##****************************************************************************
use strict;
use warnings;
use 5.010;
use Carp;
use File::Spec;
use Exporter::Easy (EXPORT => [qw(netsh netsh_path can_netsh netsh_context_found)],);

## Version string
our $VERSION = qq{0.04};


## Default path to the netsh command 
my $__NETSH_CMD = File::Spec->catfile(
  $ENV{WINDIR}, qq{system32}, qq{netsh.exe}
  );

##****************************************************************************
##****************************************************************************

=head2 netsh(...)

=over 2

=item B<Description>

Run the netsh command line utility with the provided arguments

=item B<Parameters>

... - Variable number of arguments

=item B<Return>

SCALAR - String captured from the standard out of the command

=back

=cut

##----------------------------------------------------------------------------
sub netsh    ## no critic (RequireArgUnpacking)
{

  ## Make sure this is a Windows box
  unless ($^O eq qq{MSWin32})
  {
    croak(
      qq{Win32::Netsh is intended for use on Microsoft Windows platforms only!}
    );
  }

  ## Build the command
  my $command = $__NETSH_CMD;
  foreach my $arg (@_)
  {
    $command .= qq{ } . $arg;
  }

  ## Execute command and capture output
  my $result = qx{$command};    ## no critic (ProhibitBacktick)

  ## return the result
  return ($result);
}

##****************************************************************************
##****************************************************************************

=head2 can_netsh()

=over 2

=item B<Description>

Verify that the netsh can be found and executed

=item B<Parameters>

NONE

=item B<Return>

UNDEF on error, or 1 for success

=back

=cut

##----------------------------------------------------------------------------
sub can_netsh
{

  ## Make sure this is a Windows box
  unless ($^O eq qq{MSWin32})
  {
    print(
      qq{Win32::Netsh is intended for use on }, 
      qq{Microsoft Windows platforms only!\n}
    );
    return;
  }

  ## Execute command and capture output
  my $output = qx{$__NETSH_CMD help > NUL 2>&1};    ## no critic (ProhibitBacktick)
  
  ## Get the result of the last command 
  if (my $error = ($? >> 8))
  {
    print(qq{Could not locate the command "$__NETSH_CMD"!\n});
    return;
  }

  ## return success
  return(1);
}

##****************************************************************************
##****************************************************************************

=head2 netsh_path($path)

=over 2

=item B<Description>

Set the complete path to the netsh command. Typically the command is in the
path, but this function can be used to specify a location to use.

=item B<Parameters>

=over 4

=item I<$path>

Complete path, including the .exe extension.

=back

=item B<Return>

=over 4

=item I<SCALAR>

String containing the complete path to the netsh command

=back

=back

=cut

##----------------------------------------------------------------------------
sub netsh_path
{
  my $path = shift // qq{};

  ## Set the path (if provided)
  $__NETSH_CMD = $path if ($path);
  
  ## Return the current path
  return($__NETSH_CMD);
}

##****************************************************************************
##****************************************************************************

=head2 netsh_context_found($context)

=over 2

=item B<Description>

Determine if the given netsh context is supported on this system.

=item B<Parameters>

=over 4

=item I<$context>

Context to examine (for example "wlan").

=back

=item B<Return>

=over 4

=item I<SCALAR>

UNDEF if context is not supported, or 1 if context is supported

=back

=back

=cut

##----------------------------------------------------------------------------
sub netsh_context_found
{
  my $context = shift;
  
  my $response = netsh(qq{$context ?});

  return if ($response =~ /was \s not \s found/x);
  
  return(1);
}


##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 SEE ALSO

L<Win32::Netsh::Interface> for examining and controlling the netsh interface
context including interface ipv4.

L<Win32::Netsh::Wlan> for examining and controlling the netsh wlan context
for wireless interfaces.

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__
