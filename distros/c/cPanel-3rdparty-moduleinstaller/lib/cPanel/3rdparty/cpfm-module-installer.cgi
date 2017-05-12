#!/usr/local/cpanel/3rdparty/bin/perl
#WHMADDON:cpfm-module-installer:CPFM Module Installer

#    cpfm-module-installer.pm - Module Installer Helper for WHM/cPanel.
#    Author: Farhad Malekpour <fm@farhad.ca>
#    Copyright (C) 2011-2013 Dayana Networks Ltd.
#    More information can be found at http://www.cpios.com
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as perl itself.
#


use lib '/usr/local/cpanel/';
use Whostmgr::ACLS ();
use Whostmgr::HTMLInterface ();
use Whostmgr::Mail::RBL     ();
use Cpanel::Encoder::Tiny   ();
use Cpanel::Form            ();
use Cpanel::HttpRequest		();
use Cpanel::CPAN::MIME::Base64::Perl ();
use Cpanel::CPAN::Digest::Perl::MD5  ();

Whostmgr::ACLS::init_acls();

print "Content-type: text/html\n\n";

my %FORM = Cpanel::Form::parseform();
print "FORM ACTION: [".$FORM{'action'}."]\n";




if ( (!Whostmgr::ACLS::hasroot() || !Whostmgr::ACLS::checkacl( 'all' )) && ($FORM{'action'} ne 'update-hm-wrap') )
{
	print qq{
	<br />
	<br />
	<div align="center"><h1>Permission denied</h1></div>
	};
	exit;
}



if($FORM{'action'} eq 'install-module')
{
	foreach my $key (sort keys  %FORM)
	{
	if($key =~ m/^cgi-/)
	{
		my $fn = $key;
		$fn =~ s/^cgi-//;
			my $fc = Cpanel::CPAN::MIME::Base64::Perl::decode_base64($FORM{$key});

			print "Saving [$fn] => [$fc]\n";

			open(FILE,">/usr/local/cpanel/whostmgr/docroot/cgi/$fn");
			print FILE $fc;
			close(FILE);
			chmod 0700, "/usr/local/cpanel/whostmgr/docroot/cgi/$fn";
		}
	if($key =~ m/^cpanel-/)
	{
		my $fn = $key;
		$fn =~ s/^cpanel-//;
			my $fc = Cpanel::CPAN::MIME::Base64::Perl::decode_base64($FORM{$key});
			open(FILE,">/usr/local/cpanel/Cpanel/$fn");
			print FILE $fc;
			close(FILE);
			chmod 0644, "/usr/local/cpanel/Cpanel/$fn";
		}
	if($key =~ m/^whm-/)
	{
		my $fn = $key;
		$fn =~ s/^whm-//;
			my $fc = Cpanel::CPAN::MIME::Base64::Perl::decode_base64($FORM{$key});
			open(FILE,">/usr/local/cpanel/Whostmgr/$fn");
			print FILE $fc;
			close(FILE);
			chmod 0644, "/usr/local/cpanel/Whostmgr/$fn";
		}
	}
	print qq{
	<br />
	<br />
	<div align="center"><h1>Module installed</h1></div>
	};
	exit;
}

if($FORM{'action'} eq 'update-hm-wrap')
{
	my @tempFiles;
	my $requiredVersion = $FORM{'version'};
	$requiredVersion =~ s/[^0-9.]//g;
	if($requiredVersion eq "")
	{
		print qq{<br /><br /><div align="center"><h1>Version is missing</h1></div>};
		exit;
	}
	if(-f '/var/spool/hmupdates')
	{
		unlink('/var/spool/hmupdates');
	}
	if(! -d "/var/spool/hmupdates")
	{
		mkdir("/var/spool/hmupdates",0700);
	}
	chmod 0700, "/var/spool/hmupdates";
	mkdir("/usr/local/cpanel/whostmgr/docroot/cgi/addons/hm_iphone_wrap",0700);

	my $moduleName = 'hm_iphone_wrap.cgi';
	my $moduleNameTemp = 'hm_iphone_wrap-'.rand(10000).'.cgi';
	my $moduleNameConf = 'hm_iphone_wrap.conf';
	my $moduleNameTempConf = 'hm_iphone_wrap-'.rand(10000).'.conf';

	my $httpClient = Cpanel::HttpRequest->new( 'hideOutput' => 1 );

	unlink("/var/spool/hmupdates/".$moduleNameTemp);
	unlink("/var/spool/hmupdates/".$moduleNameTemp.'.md5');
	unlink("/var/spool/hmupdates/".$moduleNameTempConf);
	unlink("/var/spool/hmupdates/".$moduleNameTempConf.'.md5');
	$httpClient->download( 'http://sync.cpios.com/?module=hm_iphone_wrap&mode=file&rnd='.rand(10000).'&major='.$requiredVersion, '/var/spool/hmupdates/' . $moduleNameTemp );
	$httpClient->download( 'http://sync.cpios.com/?module=hm_iphone_wrap&mode=md5&rnd='.rand(10000).'&major='.$requiredVersion, '/var/spool/hmupdates/' . $moduleNameTemp . '.md5' );
	$httpClient->download( 'http://sync.cpios.com/?module=hm_iphone_wrap_conf&mode=file&rnd='.rand(10000).'&major='.$requiredVersion, '/var/spool/hmupdates/' . $moduleNameTempConf );
	$httpClient->download( 'http://sync.cpios.com/?module=hm_iphone_wrap_conf&mode=md5&rnd='.rand(10000).'&major='.$requiredVersion, '/var/spool/hmupdates/' . $moduleNameTempConf . '.md5' );

	push(@tempFiles,$moduleNameTemp);
	push(@tempFiles,$moduleNameTemp.'.md5');
	push(@tempFiles,$moduleNameTempConf);
	push(@tempFiles,$moduleNameTempConf.'.md5');

	if(! -e "/var/spool/hmupdates/".$moduleNameTemp || ! -e "/var/spool/hmupdates/".$moduleNameTemp.'.md5')
	{
		_cleanupTemp(@tempFiles);
		print qq{<br /><br /><div align="center"><h1>Unable to download the updated version of the module</h1></div>};
		exit;
	}
	if(! -e "/var/spool/hmupdates/".$moduleNameTempConf || ! -e "/var/spool/hmupdates/".$moduleNameTempConf.'.md5')
	{
		_cleanupTemp(@tempFiles);
		print qq{<br /><br /><div align="center"><h1>Unable to download the updated version of the module</h1></div>};
		exit;
	}

	$md5o = Cpanel::CPAN::Digest::Perl::MD5->new();
	open(FILE, "/var/spool/hmupdates/".$moduleNameTemp);
	my $buf;
	while ( read( FILE, $buf, 1024 ) ){	$md5o->add($buf);	}
	my $localMD5 = lc($md5o->hexdigest);
	$localMD5 =~ s/[\r\n\s]//g;
	close(FILE);

	$md5oc = Cpanel::CPAN::Digest::Perl::MD5->new();
	open(FILE, "/var/spool/hmupdates/".$moduleNameTempConf);
	my $bufc;
	while ( read( FILE, $bufc, 1024 ) ){	$md5oc->add($bufc);	}
	my $localMD5C = lc($md5oc->hexdigest);
	$localMD5C =~ s/[\r\n\s]//g;
	close(FILE);


	open(FILE, "/var/spool/hmupdates/".$moduleNameTemp.'.md5');
	my $remoteMD5 = <FILE>;
	close(FILE);
	$remoteMD5 =~ s/[\r\n\s]//g;
	$remoteMD5 = lc($remoteMD5);

	open(FILE, "/var/spool/hmupdates/".$moduleNameTempConf.'.md5');
	my $remoteMD5C = <FILE>;
	close(FILE);
	$remoteMD5C =~ s/[\r\n\s]//g;
	$remoteMD5C = lc($remoteMD5C);

	if(($localMD5 ne $remoteMD5) || ($localMD5C ne $remoteMD5C))
	{
		_cleanupTemp(@tempFiles);
		print qq{<br /><br /><div align="center"><h1>MD5 does not match [$localMD5][$remoteMD5]::[$localMD5C][$remoteMD5C]</h1></div>};
		exit;
	}


	open(SRC, "/var/spool/hmupdates/".$moduleNameTemp);
	open(DST, ">/usr/local/cpanel/whostmgr/docroot/cgi/addons/hm_iphone_wrap/".$moduleName);
	my $buf;
	while (<SRC>)
	{
		print DST $_;
	}
	close(SRC);
	close(DST);

	# backward compatible
	open(SRC, "/var/spool/hmupdates/".$moduleNameTemp);
	open(DST, ">/usr/local/cpanel/whostmgr/docroot/cgi/hm_iphone_wrap_1.0.cgi");
	my $buf;
	while (<SRC>)
	{
		print DST $_;
	}
	close(SRC);
	close(DST);

	open(SRC, "/var/spool/hmupdates/".$moduleNameTempConf);
	open(DST, ">/var/cpanel/apps/".$moduleNameConf);
	my $buf;
	while (<SRC>)
	{
		print DST $_;
	}
	close(SRC);
	close(DST);



	chmod 0700, "/usr/local/cpanel/whostmgr/docroot/cgi/addons/hm_iphone_wrap/".$moduleName;
	chmod 0700, "/usr/local/cpanel/whostmgr/docroot/cgi/hm_iphone_wrap_1.0.cgi";
	chmod 0600, "/var/cpanel/apps/".$moduleNameConf;

	if(-f "/usr/local/cpanel/bin/register_appconfig")
	{
		system("/usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/cpfm-module-installer.conf");
		system("/usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/".$moduleNameConf);
	}
                

	_cleanupTemp(@tempFiles);
	print qq{<br /><br /><div align="center"><h1>Module has updated</h1></div>};
	exit;
}

sub _cleanupTemp
{
	my @list = @_;
	foreach my $file (@list)
	{
		unlink('/var/spool/hmupdates/'.$file);
	}
}


print qq{
<br />
<br />
<div align="center"><h1>Invalid action</h1></div>
};

