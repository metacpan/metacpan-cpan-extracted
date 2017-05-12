package Module::Build::PdfDocument;

use 5.008;
use strict;
use warnings;
use Module::Build;
use Config;
use File::Copy;
use Cwd;

our @ISA = qw( Module::Build );

our $wxpdfversion = '0.9.5';

our $VERSION = '0.62';

sub wxpdf_builderclass {

	# get builder class
	# based on OS && Config as we can't
	# load alien and we are never likely
	# to support a *nix toolkit other than
	# gtk

	my $bclass;

	if ( $^O =~ /^mswin/i ) {
		if ( $Config{cc} eq 'cl' ) {
			require Module::Build::PdfDocument::MSW;
			$bclass = 'Module::Build::PdfDocument::MSW';
		} else {
			require Module::Build::PdfDocument::MSWgcc;
			$bclass = 'Module::Build::PdfDocument::MSWgcc';
		}
	} elsif ( $^O =~ /^darwin/i ) {
		require Module::Build::PdfDocument::OSX;
		$bclass = 'Module::Build::PdfDocument::OSX';
	} else {
		require Module::Build::PdfDocument::GTK;
		$bclass = 'Module::Build::PdfDocument::GTK';
	}

	return $bclass;
}

sub wxpdf_prebuild_check { 1; }

sub wxpdf_libdirectory { 'wxpdfdoc-' . $wxpdfversion; }

sub wxpdf_source_file  { 'wxpdfdoc-' . $wxpdfversion . '.tar.gz';  }
					   
sub wxpdf_source_url   { 'http://sourceforge.net/projects/wxcode/files/Components/wxPdfDocument/' . wxpdf_source_file();  }

sub wxpdf_wxconfig {
	my $self = shift;

	# not available on windows
	return $self->{_wxpdf_config_wxconfig} if $self->{_wxpdf_config_wxconfig};
	my $binpathconfig;
	my $sympathconfig = Alien::wxWidgets->prefix . '/bin/wx-config';

	# sometimes the symlink is broken - if there has been relocation etc.
	# but we know where it should be if installed by Alien::wxWidgets
	# For system installs, 'wx-config' should work

	eval {
		my $location = readlink($sympathconfig);
		my @sympaths = split( /\//, $location );
		my $testpath = Alien::wxWidgets->prefix . '/lib/wx/config/' . $sympaths[-1];
		$binpathconfig = $testpath if -f $testpath;
	};

	my $wxconfig = $binpathconfig || 'wx-config';
	my $configtest = qx($wxconfig --version);
	if ( $configtest !~ /^\d+\.\d+\.\d+/ ) {
		die
			'Cannot find wx-config for wxWidgets. Perhaps you need to install wxWidgets development libraries for your system?';
	}
	$self->{_wxpdf_config_wxconfig} = $wxconfig;
	return $self->{_wxpdf_config_wxconfig};
}

sub wxpdf_version_split {
	my $class   = shift;
	my $version = Alien::wxWidgets->version;
	my $major   = substr( $version, 0, 1 );
	my $minor   = 1 * substr( $version, 2, 3 );
	my $release = 1 * substr( $version, 5, 3 );
	return ( $major, $minor, $release );
}

sub wxpdf_linker {
	my $self    = shift;
	my $command = $self->wxpdf_wxconfig . ' --ld';
	my $linker  = qx($command);
	chomp($linker);
	return $linker;
}

sub wxpdf_ldflags {
	my $self = shift;
	return Alien::wxWidgets->link_flags;
}

sub wxpdf_defines {
	my $self = shift;
	my $defines =
		Alien::wxWidgets->defines . ' -DWXBUILDING -DWXUSINGDLL -D__WX__';
	return $defines;
}

sub wxpdf_compiler {
	my $self     = shift;
	my $command  = $self->wxpdf_wxconfig . ' --cc';
	my $compiler = qx($command);
	chomp($compiler);
	{
		my @commands = split( /\s/, $compiler );
		$commands[0] =~ s/^gcc/g\+\+/;
		$commands[0] .= ' -c';
		$compiler = join( ' ', @commands );
	}
	return $compiler;
}

sub wxpdf_ccflags {
	my $self    = shift;
	my $command = $self->wxpdf_wxconfig . ' --cxxflags';
	my $flags   = qx($command);
	chomp($flags);
	$flags .= ' ' . Alien::wxWidgets->c_flags;
	return $flags;
}

sub ACTION_build {
	my $self = shift;
	$self->SUPER::ACTION_build;
	
	require Alien::wxWidgets;
	Alien::wxWidgets->import;

	# check wx widgets version
	my $wxversion = Alien::wxWidgets->version;

	$self->wxpdf_prebuild_check;
	
	# Create distribution share directory
	my $dist_dir = 'blib/arch/auto/Wx/PdfDocument';
	File::Path::mkpath( $dist_dir, 0, oct(777) );
	$self->wxpdf_get_pdfdocument_source;
	$self->build_pdfdoc_library;
	$self->build_xs;
	$self->build_info_lib;
	$self->build_demofiles;

}

# Build test action invokes build first
sub ACTION_test {
	my $self = shift;

	$self->depends_on('build');
	$self->SUPER::ACTION_test;
}

# Build install action invokes build first
sub ACTION_install {
	my $self = shift;

	$self->depends_on('build');
    
	$self->SUPER::ACTION_install;
	
	my $dllname = $self->wxpdf_pdfdocument_dll;
    my $installdir = File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/PdfDocument');
    for my $symlink ( $self->wxpdf_pdfdocument_symlinks ) {
		unlink( qq($installdir/$symlink) );
        symlink($dllname, qq($installdir/$symlink)) or die qq(Failed to created symlink $symlink : $!);	
	}
}

sub process_xs_files {
	my $self = shift;

	# Override Module::Build with a null implementation
	# We will be doing our own custom XS file handling
}

#
# Joins the list of commands to form a command, executes it a C<system> call
# and handles CTRL-C and bad exit codes
#

sub _run_command {
	my $self = shift;
	my $cmds = shift;

	my $cmd = join( ' ', @$cmds );
	if ( !$self->verbose and $cmd =~ /(cc|gcc|g\+\+|cl).+-o\s+(\S+)/ ) {
		my $object_name = File::Basename::basename($2);
		$self->log_info("    CC -o $object_name\n");
	} else {
		$self->log_info("$cmd\n");
	}
	my $rc = system($cmd);
	die "Failed with exit code $rc\n$cmd\n"  if $rc != 0;
	die "Ctrl-C interrupted command\n$cmd\n" if $rc & 127;
}

sub build_pdfdoc_library {
	my $self = shift;
	unless ( -e 'blib/arch/auto/Wx/PdfDocument/' . $self->wxpdf_pdfdocument_dll ) {
		$self->wxpdf_build_pdfdocument;
	}
}

sub build_xs {
	my $self = shift;

	my $perltypemap;
	my $wxtypemap;

	for my $incpath (@INC) {
		my $perlcheckfile = qq($incpath/ExtUtils/typemap);
		my $wxcheckfile   = qq($incpath/Wx/typemap);
		if ( !$perltypemap && -f $perlcheckfile ) {
			$perltypemap = $perlcheckfile;
			$perltypemap =~ s/\\/\//g;
		}
		if ( !$wxtypemap && -f $wxcheckfile ) {
			$wxtypemap = $wxcheckfile;
			$wxtypemap =~ s/\\/\//g;
		}
		last if ( $wxtypemap && $perltypemap );
	}

	die 'Unable to determine Perl typemap' if !defined($perltypemap);
	die 'Unable to determine Wx typemap' if !defined($wxtypemap);

	# Trigger a smart XS build only if it is not up to date.
	my @writefiles = qw( PdfDocument.xs PdfDocument.c );
	
	my $lastbuildsucceded = ( -f 'pdfbsuccess.scs' );
	
	unless ( $lastbuildsucceded && $self->up_to_date( @writefiles ) ) {
		
		my @removefiles = qw(
			pdfbsuccess.scs PdfDocument.o PdfDocument.obj
			PdfDocument.def PdfDocument.c PdfDocument.xsc
		);
		
		for ( @removefiles ) {
			unlink( $_ ) if -f $_ ;
		}
		
		unlink '' ;
		require Wx::Overload::Driver;
		my $driver = Wx::Overload::Driver->new
			( files  => [ qw( XS/PdfDocument.xsp XS/PdfLineStyle.xsp ) ],
			  header => 'cpp/ovl_const.h',
			  source => 'cpp/ovl_const.cpp',
			  );
			  
		$driver->process;
		
		require ExtUtils::ParseXS;
		ExtUtils::ParseXS::process_file(
			filename    => 'PdfDocument.xs',
			output      => 'PdfDocument.c',
			prototypes  => 0,
			linenumbers => 0,
			typemap     => [
				$perltypemap,
				$wxtypemap,
				'typemap',
			],
		);
		
		$self->wxpdf_build_xs;
	}

	if ( open my $fh, '>PdfDocument.bs' ) {
		close $fh;
	}


	my $dll = File::Spec->catfile( 'blib/arch/auto/Wx/PdfDocument', 'PdfDocument.' . $Config{dlext} );

	# Trigger a smart XS link only if it is not up to date.
	unless( $self->up_to_date( 'PdfDocument.c', $dll ) ) {
		$self->wxpdf_link_xs($dll);
		if ( open my $fh, '>pdfbsuccess.scs' ) {
			close $fh;
		}
	}	

	chmod( 0755, $dll );

	require File::Copy;
	unlink('blib/arch/auto/Wx/PdfDocument/PdfDocument.bs');
	File::Copy::copy( 'PdfDocument.bs', 'blib/arch/auto/Wx/PdfDocument/PdfDocument.bs' ) or die "Cannot copy PdfDocument.bs\n";
	chmod( 0644, 'blib/arch/auto/Wx/PdfDocument/PdfDocument.bs' );
}

sub wxpdf_get_wx_include_path {
	my $self = shift;
	eval { require Wx::Mini; };
	my $minipath = $INC{'Wx/Mini.pm'};
	return '' if !$minipath;
	my ( $vol, $dir, $file ) = File::Spec->splitpath($minipath);
	my @dirs = File::Spec->splitdir($dir);
	return File::Spec->catpath( $vol, File::Spec->catdir(@dirs), '' );
}

sub wxpdf_get_pdfdocument_source {
	my $self = shift;
	
	my $sourcedir = $self->wxpdf_libdirectory;
	return $sourcedir if -e $sourcedir;
	
	if( !-e $self->wxpdf_source_file ) {
		$self->log_info('Downloading ' . $self->wxpdf_source_file . qq(\n));
        require LWP::UserAgent;
		my $ua = LWP::UserAgent->new();
		$ua->env_proxy;
		$ua->timeout( 30 );
		$ua->agent( qq(Wx-PdfDocument build version $VERSION) );
    
		my $headeresponse = $ua->head( $self->wxpdf_source_url );
    
		if( !$headeresponse->is_success ) {
			my $msg = sprintf('Source Download Failed : %s : %s', $headeresponse->message, $self->wxpdf_source_url );
			$self->log_info("$msg\n");
			die $msg;
		}
    
		my $content_size = $headeresponse->headers()->header('content-length');
		my $datalength = 0;
		my $updatesize = $content_size / 10;
		my $totalupdate = 0;
		open (my $fh, '>', $self->wxpdf_source_file) or die 'Could not open ' . $self->wxpdf_source_file;
		binmode( $fh );
		my $contentresponse = $ua->get( $self->wxpdf_source_url, ':content_cb' =>
			sub {
				my($chunk, $robj, $pobj) = @_;
				$datalength += length( $chunk );
				print $fh $chunk;
				my $ucount = int( $datalength / $updatesize );
				if( $ucount > $totalupdate ) {
					$totalupdate = $ucount;
					$self->log_info(    'Completed ' . $totalupdate * 10 . '%' . "\n");
				}
			}
		);
		close($fh);
		if( !$contentresponse->is_success ) {
			unlink $self->wxpdf_source_file;
			my $msg = sprintf('Source Download Failed : %s : %s', $contentresponse->message, $self->wxpdf_source_url );
			$self->log_info("$msg\n");
			die $msg;
		}
    }
		
	$self->log_info('Extracting ' . $self->wxpdf_source_file . qq(\n));
	require Archive::Extract;
	$Archive::Extract::PREFER_BIN = 1;
    my $ae = Archive::Extract->new( archive => $self->wxpdf_source_file );
    die 'Error: ', $ae->error unless $ae->extract;
	
	# patches
	{		
		my $patchfile = qq(patches/wxpdfdoc.patch);
		my @patches;
		if(-f $patchfile ){
			open my $fh, '<', $patchfile or die qq(Could not open $patchfile : $!);
			binmode($fh);
			
			my $currentpatch;
			my $currentfilename;
			
			while(<$fh>) {
				if( /^diff -ruN{0,1}w -x\.svn -x docs [^\\\/]+[\\\/]([^\s]+).+$/ ) {
					push(@patches, [ $currentfilename, $currentpatch ] ) if $currentpatch;
					$currentfilename = $1;
					$currentpatch = '';
				} else {
					$currentpatch .= $_;
				}
			}
			push(@patches, [ $currentfilename, $currentpatch ] );
			close($fh);
		}
		$self->log_info(qq(\n\n));
		for my $patch ( @patches ) {
			my $sourcefile = $sourcedir . '/' . $patch->[0];
			my $patchcontent = $patch->[1];
			my $sourcecontent = '';
			$self->log_info(qq(Patching $sourcefile ...\n));
            if( -f $sourcefile) {
                open my $sfh, '<', $sourcefile or die qq(Could not open $sourcefile for read: $!);
                binmode($sfh);
                while(<$sfh>) {
                    $sourcecontent .= $_; 
                }
                close($sfh);
            }
            require Text::Patch;
			my $patchedoutput = Text::Patch::patch( $sourcecontent, $patchcontent, STYLE => "Unified" ) or die qq(Failed to patch $sourcefile : $!);
			open my $fh, '>', $sourcefile or die qq(Could not open $sourcefile for write: $!);
			binmode($fh);
			print $fh $patchedoutput;
			close($fh);
			$self->log_info(qq(Patched $sourcefile\n));
		}
		$self->log_info(qq(\n\n));
	}

	return 	$sourcedir;
}

sub wxpdf_install_pdflibrary {
	my $self = shift;
	my $iswindows = $^O =~ /^mswin/i;
	my $autodllname = $self->wxpdf_pdfdocument_dll;
	my $dllsourcepath = $self->wxpdf_built_libdir . qq(/$autodllname);
	my $autodir  = 'blib/arch/auto/Wx/PdfDocument';
	my $fontsharedir = 'blib/arch/auto/share/dist/Wx-PdfDocument/lib/fonts';
	my $utilsharedir = 'blib/arch/auto/share/dist/Wx-PdfDocument/utils';
	
	File::Path::mkpath( $fontsharedir, 0, oct(777) );
	File::Path::mkpath( $utilsharedir, 0, oct(777) );
	
	unlink(qq($autodir/$autodllname));
	for my $symlink ( $self->wxpdf_pdfdocument_symlinks ) {
		unlink( qq($autodir/$symlink) );
	}
	
	# install the dll
	File::Copy::copy($dllsourcepath, qq($autodir/$autodllname)) or die qq(Failed to copy $dllsourcepath : $!);
	
	# install the fonts
	
	{
		my $fontdir = $self->wxpdf_libdirectory . qq(/lib/fonts);
		opendir(FONTS, $fontdir) or die qq(Could not open directory $fontdir $!);
		my @fontfiles = grep { -f qq($fontdir/$_) } readdir(FONTS);
		closedir(FONTS);
		for my $fontf ( @fontfiles ) {
			File::Copy::copy(qq($fontdir/$fontf), qq($fontsharedir/$fontf)) or die qq(Failed to copy font file $fontf : $!);
		}
		
	}
	
	for my $symlink ( $self->wxpdf_pdfdocument_symlinks ) {
		symlink($autodllname, qq($autodir/$symlink)) or die qq(Failed to created symlink $symlink : $!);	
	}
	
	# install makefont and showfont
	{
		# showfont
		my $filename = ( $iswindows ) ? 'showfont.exe' : 'showfont';
		my $src = $self->wxpdf_libdirectory . '/showfont/' . $filename;
		my $fmode = (stat($src))[2];
		my $tgt = qq($utilsharedir/$filename);
		if( -f $tgt ) {
			chmod(0644, $tgt);
			unlink $tgt;
		}
		File::Copy::copy($src, $tgt) or die qq(Failed to copy utilities file $src : $!);
		chmod($fmode, $tgt);
	}
	{
		# makefont
		my $srcfolder = $self->wxpdf_libdirectory . '/makefont';
		opendir(MAKEFONT, $srcfolder) or die qq(Could not open directory $srcfolder $!);
		my @mffiles = grep { $_ !~ /\.(cpp|h|obj|o|ico|rc)$/ && -f qq($srcfolder/$_) } readdir(MAKEFONT);
		closedir(MAKEFONT);
		for my $mfile ( @mffiles ) {
			my $src = qq($srcfolder/$mfile);
			my $tgt = qq($utilsharedir/$mfile);
			my $fmode = (stat($src))[2];
			if( -f $tgt ) {
				chmod(0644, $tgt);
				unlink $tgt;
			}
			File::Copy::copy($src, $tgt) or die qq(Failed to copy utilities file $mfile : $!);
			chmod($fmode, $tgt);
		}
	}
}

sub build_info_lib {
	my $self = shift;
	
	my $modulename = $self->wxpdf_pdfdocument_module_name;
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	
	my $source = 'Info.template';
	my $target = 'blib/lib/Wx/PdfDocument/Info.pm';
	if( -f $target ) {
		chmod( 0644, $target);
		unlink $target;
	}
	open my $infh,  '<', $source or die qq(Failed to open source $source : $!);
	open my $outfh, '>', $target or die qq(Failed to open target $target : $!);
	my $content = '';
	while( <$infh> ) {
		s/REPLACEWXMAJOR/$major/g;
		s/REPLACEWXMINOR/$minor/g;
		s/REPLACEWXRELEASE/$release/g;
		s/REPLACEPDFDOCDLL/$modulename/g;
		$content .= $_;
	}
	print $outfh $content;
	close($infh);
	close($outfh);
}

sub build_demofiles {
	my $self = shift;
    
    my $extrasdir = 'demo';
    my @extras;
    my $extrasglob;
    {
        opendir( $extrasglob, $extrasdir) or die qq(unable to open directory $extrasdir : $!);
        @extras = grep { -f qq($extrasdir/$_) } readdir($extrasglob);
        closedir($extrasglob);
    }
    
    my $targetdir = 'blib/lib/Wx/DemoModules/files/pdfdocument';
    File::Path::mkpath( $targetdir, 0, oct(777) );
	for my $extra( @extras ) {
		my $targetpath = qq($targetdir/$extra);
        my $sourcepath = qq($extrasdir/$extra);
        if( -f $targetpath ) {
            chmod 0666, $targetpath;
            unlink $targetpath;
        }
		File::Copy::copy($sourcepath,$targetpath) or die qq(Failed to build $extrasdir/$extra : $!);
	}
	
}

1;
