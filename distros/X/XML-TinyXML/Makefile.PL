use 5.008;
use ExtUtils::MakeMaker;
use Config

my %config;
my $ok;
my $devnull = File::Spec->devnull();

# GOT FROM Text::Iconv makefile 
###############################################################################
# Check for iconv.

if ($config{LIBS} or $config{INC})
{
   print "Your settings:\n",
       "  LIBS: ", $config{LIBS}, "\n", "  INC:  ", $config{INC}, "\n";
}

print 'Checking for iconv ... ';

if (linktest($config{LIBS}, $config{INC}))
{
   $ok = 1;
   print "ok (iconv apparently in libc)\n";
}
elsif ($config{LIBS} !~ /-liconv/)
{
   $config{LIBS} .= ' -liconv';

   if (linktest($config{LIBS}, $config{INC}))
   {
      $ok = 1;
      print "ok (added: '-DUSE_ICONV -liconv')\n";
   }
}

if ($ok)
{
   $config{CCFLAGS} = "$Config{ccflags} -DUSE_ICONV";

   print <<EOT;

NOTE: If you have multiple iconv implementations installed, you might
      want to make sure that I've found the one you want to use.
      If necessary, you can explicitly specify paths like this:

      $^X Makefile.PL LIBS='-L/path/to/lib' INC='-I/path/to/include'

EOT
}
else
{
   print "Failed to find iconv, encoding functionalities will be disabled\n"
}

###############################################################################
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::TinyXML',
    VERSION_FROM      => 'lib/XML/TinyXML.pm', # finds $VERSION
    PREREQ_PM         => { }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/XML/TinyXML.pm', # retrieve abstract from module
    AUTHOR         => 'xant <xant@cpan.org>',
    LIBS              => $config{LIBS},
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. $config{INC}",
    CCFLAGS           => $config{CCFLAGS},
    OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(XML_BADARGS XML_GENERIC_ERR XML_LINKLIST_ERR XML_MEMORY_ERR
		 XML_NOERR XML_OPEN_FILE_ERR XML_PARSER_GENERIC_ERR XML_MROOT_ERR
		 XML_UPDATE_ERR XML_BAD_CHARS XML_NODETYPE_SIMPLE XML_NODETYPE_COMMENT XML_NODETYPE_CDATA));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'XML::TinyXML',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub linktest
{
   my $libs = shift;
   my $incs = shift;

   my $file = 'linktest';
   my $obj_ext = $Config{_o};

   my $prog = <<EOT;
#include <iconv.h>

int main(void)
{
   (void) iconv_open("", "");
}
EOT

   my $compile;

   unless ($^O eq 'VMS')
   {
      # It is admittedly a bit simplistic to simply concatenate all
      # flags, but it seems to work in most cases.
      $compile = join ' ', $Config{cc}, $incs, $Config{ccflags}, '-DUSE_ICONV',
	  $Config{ldflags}, $libs;
   }
   else
   {
      $compile = join ' ', $Config{cc}, $incs, $Config{ccflags}, '-DUSE_ICONV', $libs;
   }

   if (exists $config{verbose})
   {
      print "\nCompiler: '$compile'\n";
   }

   open  LINKTEST, '>', "$file.c" or die "Can't create test file '$file.c'.";
   print LINKTEST $prog;
   close LINKTEST;

   my $compile_line = "$compile -o $file $file.c $libs 2> $devnull";

   if ($^O eq 'VMS')
   {
      $compile_line = "pipe $compile $file.c $libs 2> NL:";
   }

   if (exists $config{verbose})
   {
      print "\nCompiler command line: '$compile_line'\n";
   }

   my $result = system($compile_line) / 256;
   unlink $file, "$file.c", "$file$obj_ext";

   if ($result == 0)
   {
      return 1;
   }
   else
   {
      return 0;
   }
}
