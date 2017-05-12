
# $Id: Admin.pm,v 1.24 2008/11/07 00:46:29 Martin Exp $

=head1 NAME

Win32::IIS::Admin - Administer Internet Information Service on Windows

=head1 SYNOPSIS

  use Win32::IIS::Admin;
  my $oWIA = new Win32::IIS::Admin;
  $oWIA->create_virtual_dir(-dir_name => 'cgi-bin',
                            -path => 'C:\wwwroot\cgi-bin',
                            -executable => 1);

=head1 DESCRIPTION

Enables you to do a few administration tasks on a IIS webserver.
Currently only works for IIS 5 (i.e. Windows 2000 Server).
Currently there are very few tasks it can do.
On non-Windows systems, the module can be loaded, but
new() always returns undef.

=head1 METHODS

=over

=cut

package Win32::IIS::Admin;

use strict;
use warnings;

use Data::Dumper;
use File::Spec::Functions;
use IO::String;

use constant DEBUG => 0;
use constant DEBUG_EXEC => 0;
use constant DEBUG_EXT => 0;
use constant DEBUG_FETCH => 0;
use constant DEBUG_PARSE => 0;
use constant DEBUG_SET => 0;

our
$VERSION = do { my @r = (q$Revision: 1.24 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=item new

Returns a new Win32::IIS::Admin object, or undef if there is any problem
(such as, IIS is not installed on the local machine!).

=cut

sub new
  {
  my ($class, %parameters) = @_;
  if ($^O ne 'MSWin32')
    {
    DEBUG && print STDERR " DDD this is not windows\n";
    return undef;
    } # if
  # Find out where IIS is installed.
  # Find the cscript executable:
  my (@asTry, $sCscript);
  push @asTry, catfile($ENV{windir}, 'system32', 'cscript.exe');
  foreach my $sTry (@asTry)
    {
    if (-f $sTry)
      {
      $sCscript = $sTry;
      last;
      } # if
    } # foreach
  DEBUG && print STDERR " DDD cscript is ==$sCscript==\n";
  if ($sCscript eq '')
    {
    warn "can not find executable cscript\n";
    return undef;
    } # if
  # Get a list of logical drives:
  eval q{use Win32API::File qw( :DRIVE_ )};
  if ($@)
    {
    DEBUG && warn " EEE can not use Win32API::File because $@\n";
    return undef;
    } # if
  my @asDrive = Win32API::File::getLogicalDrives();
  DEBUG && print STDERR " DDD logical drives are: @asDrive\n";
  # See which ones are hard drives:
  my @asHD;
  foreach my $sDrive (@asDrive)
    {
    my $sType = Win32API::File::GetDriveType($sDrive);
    push @asHD, $sDrive if ($sType eq eval'DRIVE_FIXED');
    } # foreach
  DEBUG && print STDERR " DDD hard drives are: @asHD\n";
  # Find the adsutil.vbs script:
  my $sAdsutil = '';
  @asTry = ();
  # This is the default location, according to microsoft.com:
  push @asTry, catdir($ENV{windir}, qw( System32 Inetsrv AdminSamples ));
  # This is where I find it on my old IIS installation:
  push @asTry, map { catdir($_, qw( inetpub AdminScripts )) } @asHD;
  @asTry = map { catfile($_, 'adsutil.vbs') } @asTry;
  foreach my $sTry (@asTry)
    {
    if (-f $sTry)
      {
      $sAdsutil = $sTry;
      last;
      } # if
    } # foreach
  DEBUG && print STDERR " DDD adsutil is ==$sAdsutil==\n";
  if ($sAdsutil eq '')
    {
    warn "can not find adsutil.vbs\n";
    return undef;
    } # if
  # Now we have all the info we need to get started:
  my %hash = (
              adsutil => $sAdsutil,
              cscript => $sCscript,
             );
  my $self = bless (\%hash, ref ($class) || $class);
  return $self;
  } # new


# Not published.

sub _config_set_value
  {
  my $self = shift;
  local $" = ',';
  DEBUG_SET && print STDERR " DDD _config_set_value(@_)\n";
  # Required arg1 = section:
  my $sSection = shift || '';
  return unless ($sSection ne '');
  # Required arg2 = parameter name:
  my $sParameter = shift || '';
  return unless ($sParameter ne '');
  # Remaining arg(s) will be taken as the value(s) for this parameter.
  return unless @_;
  my $sRes = $self->_execute_script('adsutil', 'SET', "$sSection/$sParameter", map { qq/"$_"/ } @_);
  if ($sRes =~ m!ERROR TRYING TO GET THE SCHEMA!i)
    {
    # Unknown parameter name:
    $self->_add_error($sRes);
    return;
    } # if
  if ($sRes =~ m!ERROR TRYING TO GET THE OBJECT!i)
    {
    # Section does not exist:
    $self->_add_error($sRes);
    return;
    } # if
  if ($sRes =~ m!ERROR TRYING TO SET THE PROPERTY!i)
    {
    # Type mismatch
    $self->_add_error($sRes);
    return;
    } # if
  # Assume success at this point:
  return '';
  } # _config_set_value


# Not published.

sub _config_get_value
  {
  my $self = shift;
  local $" = ',';
  DEBUG_FETCH && print STDERR " DDD _config_get_value(@_)\n";
  # Required arg1 = section:
  my $sSection = shift || '';
  return unless ($sSection ne '');
  # Required arg2 = parameter name:
  my $sParameter = shift || '';
  return unless ($sParameter ne '');
  my $sRes = $self->_execute_script('adsutil', 'GET', "$sSection/$sParameter");
  if ($sRes =~ m!ERROR TRYING TO GET!i)
    {
    $self->_add_error($sRes);
    return;
    } # if
  my $oIS = IO::String->new($sRes);
  my $sLine = <$oIS>;
  if ($sLine =~ m!\A(\S+)\s+:\s+\((\S+)\)\s*(.+)\Z!)
    {
    my ($sProperty, $sType, $sValue) = ($1, $2, $3);
    my @asValue;
    if ($sType eq 'STRING')
      {
      # Protect backslashes, in case this value is a dir/file path:
      $sValue =~ s!\\!/!g;
      $sValue = eval $sValue;
      return $sValue;
      } # if STRING
    elsif ($sType eq 'INTEGER')
      {
      $sValue = eval $sValue;
      return $sValue;
      } # if INTEGER
    elsif ($sType eq 'EXPANDSZ')
      {
      # Protect backslashes, this value is a dir/file path:
      $sValue =~ s!\\!/!g;
      $sValue = eval $sValue;
      $sValue =~ s!%([^%]+)%!$ENV{$1}!g;
      return $sValue;
      } # if INTEGER
    elsif ($sType eq 'BOOLEAN')
      {
      $sValue = ($sValue eq 'True');
      return $sValue;
      }
    elsif ($sType eq 'LIST')
      {
      my @asValue = ();
      if ($sValue =~ m!(\d+)\sItems!)
        {
        my $iCount = 0 + $1;
      ITEM_OF_LIST:
        for (1..$iCount)
          {
          my $sSubline = <$oIS>;
          if ($sSubline =~ m!\A\s+\042([^"]+)\042!) #
            {
            push @asValue, $1;
            } # if
          else
            {
            print STDERR " WWW list item does not look like string, in line ==$sLine==\n";
            }
          } # for ITEM_OF_LIST
        } # if
      else
        {
        print STDERR " WWW found LIST type but not item count at line ==$sLine==\n";
        next LINE_OF_CONFIG;
        }
      return \@asValue;
      } # if LIST
    elsif ($sType eq 'MimeMapList')
      {
      my %hash;
      while ($sValue =~ m!"(\S+)"!g)
        {
        my ($sExt, $sType) = split(',', $1);
        $hash{$sExt} = $sType;
        } # while
      return \%hash;
      }
    else
      {
      print STDERR " EEE unknown type =$sType=\n";
      }
    } # if PropertyName : (TYPE) value
  else
    {
    DEBUG_PARSE && print STDERR " WWW unparsable line ==$sLine==\n";
    }
  return;
  } # _config_get_value


=item iis_version

Returns the version of IIS found on this machine,
in a decimal number format like "6.0".

=cut

sub iis_version
  {
  my $self = shift;
  if (! defined  $self->{_iss_version_})
    {
    my $iMajor = $self->_config_get_value('/W3SVC/Info',
                                          'MajorIIsVersionNumber');
    my $iMinor = $self->_config_get_value('/W3SVC/Info',
                                          'MinorIIsVersionNumber');
    $self->{_iss_version_} = "$iMajor.$iMinor";
    } # if
  return $self->{_iss_version_};
  } # iis_version


=item get_timeout

Returns the IIS timeout value.

=cut

sub get_timeout
  {
  my $self = shift;
  $self->_config_get_value('/W3SVC', 'CGITimeout');
  } # set_timeout


=item set_timeout

Given an integer,
sets the IIS timeout to that value.
Does no checking on the value passed in, so use carefully!

=cut

sub set_timeout
  {
  my $self = shift;
  # Required arg1 = an integer:
  my $iArg = shift() + 0;
  $self->_config_set_value('/W3SVC', 'CGITimeout', $iArg);
  } # set_timeout


=item path_of_virtual_dir

Given the name of a virtual directory (or 'ROOT'),
returns the absolute full path of where the physical files are located.
Returns undef if there is no virtual directory matching the name given.

=cut

sub path_of_virtual_dir
  {
  my $self = shift;
  my $sDir = shift || '';
  if ($sDir eq '')
    {
    $self->_add_error(qq(Argument <virtual dir name> is required on path_of_virtual_dir.));
    return;
    } # if
  # We cravenly refuse to modify anything but the default #1 webserver:
  my $sWebsite = 1;
  if ($sDir eq 'ROOT')
    {
    goto ROOT;
    } # if
  my $sVersion = $self->iis_version;
  if ("6.0" le $sVersion)
    {
    my $sSection = join('/', 'W3SVC', $sWebsite);
    my $sRes .= $self->_execute_script('iisvdir', '/query', $sSection) || '';
    if ($sRes =~ m!Error!)
      {
      $self->_add_error($sRes);
      return;
      } # if
    DEBUG_FETCH && print STDERR " DDD iisvdir returned:", $sRes;
    my $oIS = IO::String->new($sRes);
  FIND_DIVIDER_LINE:
    while (my $sLine = <$oIS>)
      {
      last if ($sLine =~ m!={22}!);
      } # while FIND_DIVIDER_LINE
  VIR_DIR_LINE:
    while (my $sLine = <$oIS>)
      {
      chomp $sLine;
      my ($sVirDir, $sPath) = split(/ +/, $sLine);
      DEBUG_FETCH && print STDERR " DDD found virdir=$sVirDir==>$sPath\n";
      # Question: do we want to match the vir-dir name
      # case-INsensitively?
      if ($sVirDir =~ m!\A/?$sDir\Z!)
        {
        return $sPath;
        } # if
      } # while VIR_DIR_LINE
    return '';
    } # if
 ROOT:
  # If we get here, we must be using IIS 5.0:
  my $sSection = join('/', '', 'W3SVC', $sWebsite, 'ROOT');
  if ($sDir !~ m!\AROOT\Z!i)
    {
    $sSection .= "/$sDir";
    } # if
  my $sPath = $self->_config_get_value($sSection, 'Path') || '';
  return $sPath;
  } # path_of_virtual_dir


=item create_virtual_dir

Given the following named arguments, create a virtual directory on the
default #1 server on the local machine's IIS instance.

=over

=item -dir_name => 'virtual'

This is the virtual directory name as it will appear to your browsers.

=item -path => 'C:/local/path'

This is the full path the the actual location of the data files.

=item -executable => 1

Give this argument if your virtual directory holds executable programs.
Default is 0 (NOT executable).

=back

=cut

sub create_virtual_dir
  {
  my $self = shift;
  my %hArgs = @_;
  $hArgs{-dir_name} ||= '';
  if ($hArgs{-dir_name} eq '')
    {
    $self->_add_error(qq(Argument -dir_name is required on create_virtual_dir.));
    return;
    } # if
  $hArgs{-path} ||= '';
  if ($hArgs{-path} eq '')
    {
    $self->_add_error(qq(Argument -path is required on create_virtual_dir.));
    return;
    } # if
  $hArgs{-executable} ||= 0;
  # print STDERR Dumper(\%hArgs);
  # We cravenly refuse to modify anything but the default #1 webserver:
  my $sWebsite = 1;
  # First, see if a virtual directory with the same name is already
  # exists:
  my $sPath = $self->path_of_virtual_dir($hArgs{-dir_name});
  my $sRes = '';
  if ($sPath ne '')
    {
    # There is already a virtual directory with that name.  Create a
    # sensible error message:
    if ($sPath ne $hArgs{-path})
      {
      $self->_add_error(qq(There is already a virtual directory named '$hArgs{-dir_name}', but it points to $sPath));
      return;
      } # if
    $self->_add_error(qq(There is already a virtual directory named '$hArgs{-dir_name}' pointing to $sPath));
    # Fall through and (try to) set the access rules.
    } # if
  else
    {
    # Virtual dir not there, create it:
    my @asArgs = ('mkwebdir',
                  qq(-v "$hArgs{-dir_name}","$hArgs{-path}"),
                  qq(-w $sWebsite),
                  # qq(-c $sComputer),
                 );
    if ('6.0' le $self->iis_version)
      {
      @asArgs = ('iisvdir', '/create', "W3SVC/$sWebsite",
                 $hArgs{-dir_name}, $hArgs{-path});
      } # if
    $sRes .= $self->_execute_script(@asArgs) || '';
    if ($sRes =~ m!Error!)
      {
      $self->_add_error($sRes);
      return;
      } # if
    } # else
  # Whether the dir was already defined or not, try to set permissions
  # as requested:
  if ($hArgs{-executable})
    {
    my $sSection = join('/', '', 'W3SVC', $sWebsite, 'Root', $hArgs{-dir_name});
    if ('6.0' le $self->iis_version)
      {
      $sRes .= $self->_config_set_value($sSection, "AccessExecute", 'True');
      # These seem to get turned on by default, but we'll make them
      # explicit anyway:
      $sRes .= $self->_config_set_value($sSection, "AccessScript", 'True');
      $sRes .= $self->_config_set_value($sSection, "AccessRead", 'True');
      }
    else
      {
      # For some reason, the argument to chaccess has no leading slash
      # (some other scripts require leading slash):
      $sSection =~ s!\A/!!;
      # Set accesses for execution:
      $sRes .= $self->_execute_script('chaccess',
                                      -a => $sSection,
                                      qw( +execute +read +script ),
                                     );
      } # else
    } # if
  return $sRes;
  } # create_virtual_dir


=item add_extension_restriction

Given the following named arguments,
adds an "extension restriction" to
the default #1 server on the local machine's IIS instance.
Only works on IIS version 6.0.
Note: no checking is done on the arguments,
so it is possible to add bogus/duplicate/conflicting/illegal values to your IIS configuration.
For more information, see
http://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/79652e88-e713-4aa5-a88c-8e2bd6a2955e.mspx?mfr=true

=over

=item -allow => <0, 1>

Send 0 if this is a "deny" rule; send 1 if this is an "allow" rule.
The default is 0, deny.

=item -path => <fullpath>

The full path to the executable or extension.
This argument is required.

=item -groupid => <string>

"A non-localizable string used to identify groups of extensions."
Default is empty string.

=item -description => <string>

"A localizable description of the extension."
Default is empty string.

=back

=cut

sub add_extension_restriction
  {
  my $self = shift;
  # print STDERR " DDD add_extension_restriction()\n";
  if ($self->iis_version < 6.0)
    {
    return;
    } # if
  # Set defaults, and get arguments:
  my %hArgs = (
               -allow => 0,
               -groupid => '',
               -description => '',
               @_,
               # At present, this argument is not alterable:
               -deletable => 1,
              );
  # Verify all argument values:
  $hArgs{-allow} = 0 if ($hArgs{-allow} ne '1');
  if (! exists $hArgs{-path})
    {
    $self->add_error("add_extension_restriction() called without required argument -path");
    return;
    } # if
  # Construct the new Registry value:
  my $s = join(',', @hArgs{qw( -allow -path -deletable -groupid -description )});
  # print STDERR " DDD   s=$s=\n";
  my $ra = $self->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
  # print STDERR " DDD   before, list is ", Dumper($ra);
  push @{$ra}, $s;
  $self->_config_set_value('/W3SVC', 'WebSvcExtRestrictionList', @{$ra});
  } # add_extension_restriction


=item remove_extension_restriction

Given the full path of an existing "extension restriction" in
the default #1 server on the local machine's IIS instance,
removes that restriction.
If more than one restriction refers to the same path,
they will all be removed.
Only works on IIS version 6.0.

=cut

sub remove_extension_restriction
  {
  my $self = shift;
  # Required arg1 = path element:
  my $sPath = shift || '';
  DEBUG_EXT && print STDERR " DDD remove_extension_restriction($sPath)\n";
  $self->_remove_extension_restriction_by_elem($sPath, 1);
  } # remove_extension_restriction


=item remove_extension_restriction_group

Given the group ID of an existing "extension restriction" in
the default #1 server on the local machine's IIS instance,
removes all restrictions of that group.
Only works on IIS version 6.0.

=cut

sub remove_extension_restriction_group
  {
  my $self = shift;
  # Required arg1 = path element:
  my $sValue = shift || '';
  DEBUG_EXT && print STDERR " DDD remove_extension_restriction_group($sValue)\n";
  $self->_remove_extension_restriction_by_elem($sValue, 3);
  } # remove_extension_restriction_group


sub _remove_extension_restriction_by_elem
  {
  my $self = shift;
  # Required arg1 = path element:
  my $sValue = shift || '';
  # Required arg2 = element number:
  my $iElem = shift;
  # Verify all argument values:
  return if ! defined($iElem);
  return if ($iElem < 0);
  return if (4 < $iElem);
  if ($sValue eq '')
    {
    return;
    } # if
  if ($self->iis_version < 6.0)
    {
    return;
    } # if
  my $rasOrig = $self->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
  DEBUG_EXT && print STDERR " DDD   before, list is ", Dumper($rasOrig);
  my @asNew;
  foreach my $s (@$rasOrig)
    {
    my @asElem = split(',', $s);
    if (($asElem[$iElem] || '') eq $sValue)
      {
      DEBUG_EXT && print STDERR " DDD   found one to remove\n";
      }
    else
      {
      push @asNew, $s;
      }
    } # foreach
  DEBUG_EXT && print STDERR " DDD   after, list is ", Dumper(\@asNew);
  $self->_config_set_value('/W3SVC', 'WebSvcExtRestrictionList', @asNew);
  } # _remove_extension_restriction_by_elem


=item restart_iis

Restarts the IIS service on the local machine.
Assumes that IISReset.exe is in your path.

=cut

sub restart_iis
  {
  my $self = shift;
  # Assume that IISReset is in the path:
  my $sProg = 'IISReset';
  my $iRes = system(qq'$sProg /RESTART');
  if ($iRes)
    {
    # print STDERR "$sProg failed: $!";  # for debugging
    $self->add_error("$sProg failed: $!");
    } # if
  } # restart_iis


=item errors

Method not implemented.
In the current version, error messages are printed to STDERR as they occur.

=cut

sub errors
  {
  } # errors

sub _add_error
  {
  my $self = shift;
  print STDERR "@_\n";
  } # add_error

sub _execute_script
  {
  my $self = shift;
  my $sVBS = shift;
  # Figure out exactly which script the caller wants to execute.
  # Cscript needs the full path:
  my $sScriptFname;
  if (defined $self->{$sVBS})
    {
    # User requested a script which we have already located.
    $sScriptFname = $self->{$sVBS};
    }
  else
    {
    # adsutil.vbs is the only script we bother to physically locate;
    # all other scripts are next to cscript itself:
    $sScriptFname = $self->{cscript};
    $sScriptFname =~ s!cscript\.exe!$sVBS.vbs!i;
    }
  my $sCmd = join(' ', $self->{cscript}, '-nologo', $sScriptFname, @_);
  DEBUG_EXEC && print STDERR " DDD exec ==$sCmd==\n";
  my $sRes = qx/$sCmd/;
  print STDERR " DDD   result ===$sRes===\n" if (1 < DEBUG_EXEC);
  return $sRes;
  } # _execute_script

=back

=head1 BUGS

To report a bug, please use L<http://rt.cpan.org>.

=head1 AUTHOR

Martin Thurn C<mthurn@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;

__END__

