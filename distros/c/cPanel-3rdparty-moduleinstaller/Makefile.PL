use ExtUtils::MakeMaker;

createMainLoader();

sub createMainLoader
{
    if(! -d "/usr/local/cpanel/whostmgr/docroot/cgi")
    {
		return;
    }

	mkdir("/usr/local/cpanel/whostmgr/docroot/cgi/addons",0755);
	mkdir("/usr/local/cpanel/whostmgr/docroot/cgi/addons/cpfm-module-installer",0755);

    open(SRC, "lib/cPanel/3rdparty/cpfm-module-installer.cgi");
    open(DST, ">/usr/local/cpanel/whostmgr/docroot/cgi/addons/cpfm-module-installer/cpfm-module-installer.cgi");
    while(<SRC>)
    {
		print DST $_;
    }
    close(SRC);
    close(DST);
    
    open(SRC, "lib/cPanel/3rdparty/cpfm-module-installer.cgi");
    open(DST, ">/usr/local/cpanel/whostmgr/docroot/cgi/cpfm-module-installer.cgi");
    while(<SRC>)
    {
		print DST $_;
    }
    close(SRC);
    close(DST);
    
    open(SRC, "lib/cPanel/3rdparty/cpfm-module-installer.conf");
    open(DST, ">/var/cpanel/apps/cpfm-module-installer.conf");
    while(<SRC>)
    {
		print DST $_;
    }
    close(SRC);
    close(DST);


    chmod 0700, "/usr/local/cpanel/whostmgr/docroot/cgi/addons/cpfm-module-installer/cpfm-module-installer.cgi";
    chmod 0700, "/usr/local/cpanel/whostmgr/docroot/cgi/cpfm-module-installer.cgi";
    chmod 0600, "/var/cpanel/apps/cpfm-module-installer.conf";
    
    if(-f "/usr/local/cpanel/bin/register_appconfig")
    {
		system("/usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/cpfm-module-installer.conf");
    }
    
}


WriteMakefile(
    NAME              => 'cPanel::3rdparty::ModuleInstaller',
    VERSION_FROM      => 'lib/cPanel/3rdparty/ModuleInstaller.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/cPanel/3rdparty/ModuleInstaller.pm', # retrieve abstract from module
       AUTHOR         => 'Farhad Malekpour <fm@farhad.ca>') : ()),
);
