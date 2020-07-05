package Win32::GetDefaultBrowser;

use Win32;
use Win32::TieRegistry qw|Delimiter \\ REG_SZ KEY_READ|;
use base qw(Exporter);

our @EXPORT = qw(get_default_browser);

our $VERSION = '1.02';

sub get_default_browser
{
	 my $strBrowser = 0;
	 my $strSubBrowser = 0;
	 my $strFallbackBrowser = 0;
	 my $boolIs64Bit = 0;
     if($ENV{'PROGRAMW6432'} =~ m/\w/)
     {
          $boolIs64Bit = 1;
     }
	 if(($boolIs64Bit) && (-e ($ENV{'SYSTEMDRIVE'} . '\\Program Files (x86)\\Internet Explorer\\iexplore.exe')))
	 {
		  $strFallbackBrowser = $ENV{'SYSTEMDRIVE'} . '\\Program Files (x86)\\Internet Explorer\\iexplore.exe';
	 }
	 elsif(-e ($ENV{'SYSTEMDRIVE'} . '\\Program Files\\Internet Explorer\\iexplore.exe'))
	 {
		  $strFallbackBrowser = $ENV{'SYSTEMDRIVE'} . '\\Program Files\\Internet Explorer\\iexplore.exe';
	 }
	 if(! $strFallbackBrowser)
	 {
		  $strFallbackBrowser = 'iexplore.exe';
	 }
	 my @strWinVer = Win32::GetOSVersion;
      my $strMajorWinBuild = $strWinVer[1];
      if($strMajorWinBuild >= 10)
      {
          my $RegHash = new Win32::TieRegistry('HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\http\\UserChoice', { Access => KEY_READ(), Delimiter => '\\' });
          if($RegHash)
		{
               my $strBrowser = $RegHash->GetValue('ProgId');
               if($strBrowser)
               {
                    my $sub_regkey = new Win32::TieRegistry('HKEY_CLASSES_ROOT\\' . $strBrowser . '\\shell\\open\\command', { Access => KEY_READ(), Delimiter => '\\' });
                    if($sub_regkey)
                    {
                          $strSubBrowser = $sub_regkey->GetValue('');
                    }
               }
          }
          if($strSubBrowser =~ m/^"([^"]{1,})"/)
          {
               $strSubBrowser = $1;
          }
      }
	 elsif($strMajorWinBuild > 5)
	 {
		  my $regkey = new Win32::TieRegistry('HKEY_CURRENT_USER\\Software\\Clients\\StartMenuInternet', { Access => KEY_READ(), Delimiter => '\\' });
		  if ($regkey)
		  {
			  $strBrowser = $regkey->GetValue('');
			  if($strBrowser)
			  {
					my $regpath_str = 'HKEY_LOCAL_MACHINE\\Software\\Clients\\StartMenuInternet\\' . $strBrowser . '\\shell\\open\\command';
					if($boolIs64Bit)
					{
						 $regpath_str = 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Clients\\StartMenuInternet\\' . $strBrowser . '\\shell\\open\\command';
					}
					my $sub_regkey = new Win32::TieRegistry($regpath_str, { Access => KEY_READ(), Delimiter => '\\' });
					if($sub_regkey)
					{
						 $strSubBrowser = $sub_regkey->GetValue('');
					}
			  }
		  }
		  $strSubBrowser =~ s/["']//g;
	 }
	 else
	 {
		  my $regkey = new Win32::TieRegistry('HKEY_CLASSES_ROOT\\HTTP\\shell\\open\\command', { Access => KEY_READ(), Delimiter => '\\' });
		  if ($regkey)
		  {
			   $strSubBrowser = $regkey->GetValue('');
			   $strSubBrowser =~ s/(\.exe).{1,}$/$1/i;
			   $strSubBrowser =~ s/["']//g;
		  }
	 }
	 if((! (length($strSubBrowser))) || (!-e $strSubBrowser))
	 {
		  $strSubBrowser = $strFallbackBrowser;
	 }
	 return($strSubBrowser);
}

=head1 NAME

Win32::GetDefaultBrowser - Return full path to default browser on Windows systems

=head1 SYNOPSIS

	use Win32::GetDefaultBrowser;
	
	my $default_browser = get_default_browser;

=head1 DESCRIPTION

Returns the full path to the default browser on a Windows system.

Pollutes the namespace with one function: get_default_browser.

=head1 METHODS

=head2 get_default_browser

Returns the full path to the default browser on a Windows system. Falls back to
Internet Explorer on failure.

=head1 Version History

1.00 - Initial Release

1.01 - Added Windows 10 support (hopefully)

1.02 - Fixed this POD document

=head1 Author

Brandon Bourret

=head1 License

Permission is granted to use this software under the same terms as Perl itself.

Refer to the L<Perl Artistic|perlartistic> license for details.

=cut