package Win32::GetDefaultBrowser;

use Win32;
use Win32::TieRegistry qw|Delimiter \\ REG_SZ KEY_READ|;
use base qw(Exporter);

our @EXPORT = qw(get_default_browser);

our $VERSION = '1.00';

sub get_default_browser
{
	 my $browser_str = '';
	 my $sub_browser_str = '';
	 my $fallback = 0;
	 my $is64bit = 0;
     if($ENV{'PROGRAMW6432'} =~ m/\w/)
     {
          $is64bit = 1;
     }
	 if(($is64bit) && (-e ($ENV{'SYSTEMDRIVE'} . '\\Program Files (x86)\\Internet Explorer\\iexplore.exe')))
	 {
		  $fallback = $ENV{'SYSTEMDRIVE'} . '\\Program Files (x86)\\Internet Explorer\\iexplore.exe';
	 }
	 elsif(-e ($ENV{'SYSTEMDRIVE'} . '\\Program Files\\Internet Explorer\\iexplore.exe'))
	 {
		  $fallback = $ENV{'SYSTEMDRIVE'} . '\\Program Files\\Internet Explorer\\iexplore.exe';
	 }
	 if(! $fallback)
	 {
		  $fallback = 'iexplore.exe';
	 }
	 my($junkstr, $major, $junkminor, $junkbuild) = Win32::GetOSVersion();
	 if($major > 5)
	 {
		  my $regkey = new Win32::TieRegistry('HKEY_CURRENT_USER\\Software\\Clients\\StartMenuInternet', { Access => KEY_READ(), Delimiter => '\\' });
		  if ($regkey)
		  {
			  $browser_str = $regkey->GetValue('');
			  if($browser_str)
			  {
					my $regpath_str = 'HKEY_LOCAL_MACHINE\\Software\\Clients\\StartMenuInternet\\' . $browser_str . '\\shell\\open\\command';
					if($is64bit)
					{
						 $regpath_str = 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Clients\\StartMenuInternet\\' . $browser_str . '\\shell\\open\\command';
					}
					my $sub_regkey = new Win32::TieRegistry($regpath_str, { Access => KEY_READ(), Delimiter => '\\' });
					if($sub_regkey)
					{
						 $sub_browser_str = $sub_regkey->GetValue('');
					}
			  }
		  }
		  $sub_browser_str =~ s/["']//g;
	 }
	 else
	 {
		  my $regkey = new Win32::TieRegistry('HKEY_CLASSES_ROOT\\HTTP\\shell\\open\\command', { Access => KEY_READ(), Delimiter => '\\' });
		  if ($regkey)
		  {
			   $sub_browser_str = $regkey->GetValue('');
			   $sub_browser_str =~ s/(\.exe).{1,}$/$1/i;
			   $sub_browser_str =~ s/["']//g;
		  }
	 }
	 if((! (length($sub_browser_str))) || (!-e $sub_browser_str))
	 {
		  $sub_browser_str = $fallback;
	 }
	 return($sub_browser_str);
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

=head1 AUTHOR, COPYRIGHT, and LICENSE

Copyright(C) 2009, phatWares, USA. All rights reserved.

Permission is granted to use this software under the same terms as Perl itself.
Refer to the L<Perl Artistic|perlartistic> license for details.

=cut