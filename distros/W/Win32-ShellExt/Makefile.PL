# -*- cperl -*-
#
# (C) 2002 Jean-Baptiste Nivoit
#

use ExtUtils::MakeMaker;
use Config;

my $samples = {
	       CtxtMenu::Base64Decode => { 'MIME::Base64' => 2.12 },				# ok
	       CtxtMenu::Base64Encode => { 'MIME::Base64' => 2.12 },				# ok
##not tested.	       CtxtMenu::BinHex => { 'Convert::BinHex' => 1.119 },
#	       CtxtMenu::CanonicalXML => { 'XML::Canonical' => 0.04 },
	       CtxtMenu::CopyPath => {},								# ok
	       CtxtMenu::FIGlet => { 'Text::FIGlet' => 1.05 },					# ok
	       CtxtMenu::Gzip => { 'Compress::Zlib' => 1.16 },
	       CtxtMenu::Gunzip => { 'Compress::Zlib' => 1.16 },
	       CtxtMenu::MD5 => { 'MD5' => 1.7 },
	       CtxtMenu::MagickConvertJPG => { 'Image::Magick' => 5.41 },
	       CtxtMenu::MagickConvertGIF => { 'Image::Magick' => 5.41 },
	       CtxtMenu::MagickConvert => { 'Image::Magick' => 5.41 },
#	       CtxtMenu::ExpandTabs => { 'Text::Tabs' => 98.112801 },
	       CtxtMenu::UnexpandTabs => { 'Text::Tabs' => 98.112801 },
#	       CtxtMenu::PDF => { 'PDF' => 1.11 },
	       CtxtMenu::PDF => { 'Text::PDF' => 0.18 },						# ok, but needs correct parameters for the booklet
	       CtxtMenu::RegisterDll => { 'Win32' => 0.18 },
	       CtxtMenu::UnregisterDll => { 'Win32' => 0.18 },
	       CtxtMenu::RenameMP3 => { 'MP3::Info' => 0.91, 'Win32API::File' => 0.08 }, # KO!
	       CtxtMenu::SwapFileNames => {},							# ok
	       CtxtMenu::Tar => { 'Archive::Tar' => 0.22 },
#	       CtxtMenu::Tgz => { 'Archive::Tar' => 0.22, 'Compress::Zlib' => 1.16 },
	       CtxtMenu::Whitespace => { 'Whitespace' => 1.02 },					# ok
	       CtxtMenu::Zip => { 'Archive::Zip' => 0.11 },
	       CtxtMenu::BinHex => { 'Convert::BinHex' => 1.119 },
#KO	       CtxtMenu::LinkExtor => { 'Win32::Clipboard' => 0.51 ,
#			      'HTML::Parser' => 3.25, # HTML::LinkExtor
#			      'URI::URL' => 1.18 }
	       QueryInfo::PM => {},
	       QueryInfo::ELisp => {},
	       QueryInfo::TeX => {},
	       QueryInfo::LineCount => {},
	       QueryInfo::Shortcut => {},
	       QueryInfo::JpgSize => { 'Image::Magick' => 5.41 },
	       QueryInfo::PDF => { 'PDF' => 1.11 },
	       QueryInfo::Zip => { 'Archive::Zip' => 0.11 },
	       ColumnProvider::JpgSize => { 'Image::Magick' => 5.41 },
	       ColumnProvider::PM => {},
#	       CopyHook::Veto => {},
#KO	       CtxtMenu::Join => { 'Text::Trie' => 0.1 }
# untested     DragAndDropHandler::Zip => {Archive::Zip' => 0.11 },
	       };


$my_samples = {
#KO	       Gzip => { 'Compress::Zlib' => 1.16 },
#KO	       MD5 => { 'MD5' => 1.7 },
#	       MagickConvertJPG => { 'Image::Magick' => 5.41 },
#KO	       Tar => { 'Archive::Tar' => 0.22 },
#	       Zip => { 'Archive::Zip' => 0.11 }
	       MagickConvert => { 'Image::Magick' => 5.41 },
# for testing with multiple commands...
#	       CopyPath => {},								
#	       FIGlet => { 'Text::FIGlet' => 1.05 },					

	       };


# Before writing the makefile, let's check that CLSID's really are unique, this will avoids surprises afterwards...
my %clsids;
push @INC,"examples";
map {
  my $clsid = eval "use Win32::ShellExt::$_; Win32::ShellExt::$_->hkeys()->{CLSID}; ";
  if(defined($clsid)) { # might be undefined if module loading failed..
    #print "Win32::ShellExt::$_ => $clsid\n";
    die "duplicate CLSID in Win32::ShellExt::$_ and Win32::ShellExt::".$clsids{$clsid}."\n" if(defined($clsids{$clsid}));
    $clsids{$clsid} = $_;
  }
} sort keys %$samples;
pop @INC;

WriteMakefile(
	      NAME         => 'Win32::ShellExt',
	      VERSION_FROM => 'ShellExt.pm', # finds $VERSION
	      PREREQ_PM => { Win32::TieRegistry => 0.23 }, # FIXME infer that from %samples
	      'dist'             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	      LIBS         => [''],
	      DEFINE       => '',     # e.g., '-DHAVE_SOMETHING'
	      INC        => '',     # e.g., '-I/usr/include/other'
	      AUTHOR     => 'Jean-Baptiste Nivoit <jbnivoit@hotmail.com>',
	      ABSTRACT   => 'Allows to write Windows shell extensions in Perl',
	      C => 'Win32ShellExt.cpp debug.cpp',
#	      O => 'Win32ShellExt.obj debug.obj',
	      H => 'PerlQueryInfoExt.h Win32ShellExt.h debug.h exports.h PerlQueryInfoExt.cpp',
#	      DIR => ['examples'],
#	      PMLIBDIRS => ['examples'],
#	      PMLIBDIRS => ['ShellExt'],
#	      PMLIBDIRS => ['.', 'ShellExt', 'ShellExt/CopyHook', 'ShellExt/ColumnProvider', 'ShellExt/QueryInfo'],
	      PMLIBDIRS => ['ShellExt', 'ShellExt/CopyHook', 'ShellExt/ColumnProvider', 'ShellExt/QueryInfo', 'ShellExt/CtxtMenu', 'ShellExt/DragAndDropHandler'],
#	      EXE_FILES => ['perlshellext.dll'],
	      INST_BIN => ['perlshellext.dll'],
	      XS => { 'ShellExt/CopyHook.xs' => 'ShellExt/CopyHook.c' }
);

# This adds hand-coded rules to build the embedding DLL.
sub MY::makefile {
  my $self = shift;
  $self->MM::makefile() .
'

XSUBPPDIR = C:\perl\lib\ExtUtils
XSUBPP = $(XSUBPPDIR)/xsubpp
XSPROTOARG = 
XSUBPPDEPS = $(XSUBPPDIR)\typemap typemap $(XSUBPP)
XSUBPPARGS = -typemap $(XSUBPPDIR)\typemap -typemap typemap

.xs.c:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c

perlshellext.dll : Win32ShellExt.obj debug.obj
	link -dll -def:Win32ShellExt.def -nologo  -out:.\perlshellext.dll Win32ShellExt.obj debug.obj d:\build\perl\p561\lib\CORE\perl56.lib user32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib -libpath:c:\perl\bin /SUBSYSTEM:windows

Win32ShellExt.obj : Win32ShellExt.cpp PerlQueryInfoExt.cpp PerlMenu.cpp PerlColumnProviderExt.cpp PerlCopyHookExt.cpp PerlShellExtCtxtMenu.cpp PerlShellExt.cpp PerlDataObjectExt.cpp PerlDropTargetExt.cpp PerlShellExtInit.cpp PerlPersistFileExt.cpp PerlIconHandlerExt.cpp PerlPropSheetExt.cpp debug.h PerlShellExtInit.h exports.h Win32ShellExt.h PerlQueryInfoExt.h PerlColumnProviderExt.h PerlPropSheetExt.h PerlUnknownExt.h PerlCopyHookExt.h PerlMenu.h PerlShellExt.h PerlDataObjectExt.h PerlShellExtCtxtMenu.h PerlDropTargetExt.h PerlPersistFileExt.h PerlIconHandlerExt.h ShellExt/CopyHook.c PerlShellExtClassFactory.h PerlShellExtClassFactory.cpp
	cl -c -I. -nologo -Gf -W3 -I..\perl\p561\lib\CORE -I..\perl\p561\include -I. -I.. -DWIN32 -D_CONSOLE -DNO_STRICT   -Od -MD -Zi  -DPERL_MSVCRT_READFIX  -DWITH_DEBUG -UWITH_DEBUG -Fo.\win32shellext.obj .\win32shellext.cpp

debug.obj : debug.cpp debug.h
	cl -c -I. -nologo -Gf -W3 -DWIN32 -D_CONSOLE -DNO_STRICT -DWITH_DEBUG -UWITH_DEBUG   -Od -MD -Zi -Fo.\debug.obj .\debug.cpp

'
}

# This adds a new target to invoke the installation method on the installed .PMs
sub MY::install {
  my $self = shift;

  my @rules = map {
    "perl -MWin32::ShellExt::$_ -e \"Win32::ShellExt::$_->install;\""
  } sort keys %$samples;

  my $rule = "

install_registry ::
	" . join "\n\t", @rules;


  # now get the basic rules, and insert my 'install_registry' one in it.
  my $baserule = $self->MM::install();
  $baserule =~ s!(install :: all pure_install doc_install)!$1 install_registry!;

  $baserule .= $rule;
  $rule =~ s!install!uninstall!g;

  $baserule . $rule
}







