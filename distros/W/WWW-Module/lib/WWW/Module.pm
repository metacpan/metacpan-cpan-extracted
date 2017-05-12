package WWW::Module;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use File::HomeDir;
use File::Spec;
use CPAN;

use vars qw($VERSION);
$VERSION = '1.00';

my ($MAKE_LOG,$MAKE_ERR,$REQUIRE_ERR);
my $CPAN_HOME;

BEGIN
{
    sub do_conf{
	my $build_dir = File::Spec->catfile($CPAN_HOME,'build');
	my $histfile  = File::Spec->catfile($CPAN_HOME,'histfile');
	my $keep_source_where = File::Spec->catfile($CPAN_HOME,'sources');
	my $conf = {
	    'build_cache' => q[10],
	    'build_dir' => $build_dir,
	    'cache_metadata' => q[1],
	    'commandnumber_in_prompt' => q[1],
	    'cpan_home' => $CPAN_HOME,
	    'ftp' => q[ftp],
	    'ftp_passive' => q[1],
	    'ftp_proxy' => q[],
	    'getcwd' => q[],
	    'gpg' => q[],
	    'gzip' => q[],
	    'histfile' => $histfile,
	    'histsize' => q[100],
	    'http_proxy' => q[],
	    'inactivity_timeout' => q[0],
	    'index_expire' => q[1],
	    'inhibit_startup_message' => q[1],
	    'keep_source_where' => $keep_source_where,
	    'lynx' => q[],
	    'make' => q[],
	    'make_arg' => q[],
	    'make_install_arg' => q[],
	    'make_install_make_command' => q[],
	    'makepl_arg' => q[],
	    'mbuild_arg' => q[],
	    'mbuild_install_arg' => q[],
	    'mbuild_install_build_command' => q[],
	    'mbuildpl_arg' => q[],
	    'ncftp' => q[],
	    'ncftpget' => q[],
	    'no_proxy' => q[],
	    'pager' => q[],
	    'prerequisites_policy' => q[follow],
	    'scan_cache' => q[atstart],
	    'shell' => q[],
	    'tar' => q[],
	    'term_is_latin' => q[],
	    'term_ornaments' => q[],
	    'unzip' => q[],
	    'urllist' => [q[ftp://ftp.mirrorservice.org/sites/ftp.funet.fi/pub/languages/perl/CPAN/],q[ftp://mirrors.ibiblio.org/pub/mirrors/CPAN]],
	    'wget' => q[],
	};
	return $conf;
    }
    
    sub mk_cpan_pm {
	my $user_cpan = File::Spec->catfile(File::HomeDir->my_home,'.cpan','CPAN');
	$CPAN_HOME = File::Spec->catfile(File::Spec->tmpdir(),"cpan-". $>);
	mk_path($CPAN_HOME) or return 0;

	my $cpanpm = File::Spec->catfile($user_cpan,'MyConfig.pm');
	unless(-e $cpanpm){
	    mk_path($user_cpan) or return 0;
	    my $conf = do_conf();
	    
	    if(open(CPANPM,"> ". $cpanpm)){
		print CPANPM Data::Dumper->Dump([$conf],['$CPAN::Config']);
		print CPANPM "1;";
	    } else {
		carp("Couldn't write ". $cpanpm. ": ". $!);
		return 0;
	    }
	    close(CPANPM) or return 0;
	}
	return 1;
    }
    
    sub mk_path{
	my $path = shift;
	unless(-e $path){
	    eval{File::Path::mkpath($path,0,0755)};
	    if ($@){
		carp("Couldn't make path ". $path .": ". $@);
		return 0;
	    }
	}
	return 1;
    }

    mk_cpan_pm();
    $MAKE_LOG = File::Spec->catfile($CPAN_HOME, 'make_log');
    $MAKE_ERR = File::Spec->catfile($CPAN_HOME, 'make_err');
    $REQUIRE_ERR = File::Spec->catfile($CPAN_HOME, 'require_err');
    if(-e $MAKE_LOG){
	unlink($MAKE_LOG) or carp("couldn't unlink ". $MAKE_LOG .": ". $!);
    }
    if(-e $MAKE_ERR){
	unlink($MAKE_ERR) or carp("couldn't unlink ". $MAKE_ERR .": ". $!);
    }
    if(-r $REQUIRE_ERR){
	unlink($REQUIRE_ERR) or carp("couldn't unlink ". $REQUIRE_ERR .": ". $!);
    }
# SWITCH THESE OFF FOR CPAN DEBUGGING
    $CPAN::Be_Silent = 1;
    $ENV{PERL_MM_USE_DEFAULT}=1;
}

sub _use
{
    my $incname = my $modname = shift;
    $incname =~ s/::/\//;
    $incname .= '.pm';

    my $mod = CPAN::Shell->expand("Module",$modname);
    unless ($mod->uptodate){
	{
	    open(SAVED_OUT, ">&STDOUT");
	    open(SAVED_ERR, ">&STDERR");
	    close(STDOUT);
	    close(STDERR);

	    open(STDOUT, ">> ". $MAKE_LOG);
	    open(STDERR, ">> ". $MAKE_ERR);
	    $mod->make();
	    close(STDOUT);
	    close(STDERR);

	    open(STDOUT, ">&SAVED_OUT");
	    open(STDERR, ">&SAVED_ERR");
	    close(SAVED_OUT);
	    close(SAVED_ERR);
	}
	my $dist_dir = $mod->distribution()->dir();
	unshift @INC, (File::Spec->catfile($dist_dir,'blib','arch'));
	unshift @INC, (File::Spec->catfile($dist_dir,'blib','lib'));
	unshift @INC, $dist_dir;

	if(exists $INC{$incname}){
	    carp($modname." already defined: trying to redefine");
	    delete $INC{$incname};
	    {
		open(SAVED_OUT, ">&STDOUT");
		open(SAVED_ERR, ">&STDERR");
		close(STDOUT);
		close(STDERR);
		
		open(STDOUT, ">> ". $REQUIRE_ERR);
		open(STDERR, ">&STDOUT");

		eval("require ". $modname);

		close(STDOUT);
		close(STDERR);
		
		open(STDOUT, ">&SAVED_OUT");
		open(STDERR, ">&SAVED_ERR");
		close(SAVED_OUT);
		close(SAVED_ERR);

		carp($modname ." cannot be redefined: ". $@) if $@;
	    }
	}
    }
}

sub import
{
    my ($self,@imports) = @_;
    $CPAN::Config->{cpan_home} = $CPAN_HOME;
    $CPAN::Config->{build_dir} = File::Spec->catfile($CPAN_HOME,'build');
    $CPAN::Config->{histfile}  = File::Spec->catfile($CPAN_HOME,'histfile');
    $CPAN::Config->{keep_source_where} = File::Spec->catfile($CPAN_HOME,'sources');
    foreach my $module(@imports){
	_use($module);
    }
    return 1;
}

1;
__END__

=head1 NAME

WWW::Module - use modules from CPAN without installing

=head1 SYNOPSIS

  # obvious, really
  use WWW::Module qw(Some::Module);
  use Some::Module;

  # multiple modules
  use WWW::Module qw(Foo::Bar Baz);
  use Foo::Bar;
  use Baz;

=head1 NOTES

If you haven't used the CPAN module before, this module will create 
a .cpan/CPAN/MyConfig.pm file with some defaults. You probably wouldn't
want to use these defaults if you regularly are using the CPAN shell 
to install software.

The module will also create a build directory in /tmp/cpan-XXXX

Send me bug reports. I'm sure there will be lots as the whole
idea is probably a bit flaky.

=head1 AUTHOR

Nigel Gourlay        nwetters@cpan.org

Copyright (c) 2006 Nigel Gourlay. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 1.00  (26 Nov, 2006)

=head1 SEE ALSO

perl(1)

=cut
