
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);


use ExtUtils::MakeMaker;

my $root = "/blib/arch/auto/libmetaphone";


use Cwd;
my $pwd = fastcwd;

my $p = $pwd;

print "PWD: $pwd\n";
$pwd =~ s|(\w+)/(\w+)$|$1|;
print "PWD: $pwd\n";
$root = $pwd.$root;
print "ROOT: $root\n";

use File::Path 'mkpath';
mkpath $root, 1, 0755 unless -d $root;

system "touch $root/libmetaphone.so";


WriteMakefile(
	'NAME'		=> 'Text::TransMetaphone::en_US',
	'VERSION_FROM'	=> '../lib/Text/TransMetaphone/en_US.pm', # finds $VERSION
	'LIBS'		=> "-L$root -lmetaphone",
	'INC'		=> '-I../include',
	# 'CCFLAGS'	=> '-funsigned-char',
	'OBJECT'	=> '$(O_FILES)',
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "The en_US TransMetaphone Mappings.",
	'TYPEMAPS'	=> [ "$p/typemap" ]
);
