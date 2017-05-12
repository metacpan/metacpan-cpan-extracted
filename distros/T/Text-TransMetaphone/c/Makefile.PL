
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);


use ExtUtils::MakeMaker;
use Config;

use Cwd;
my $pwd = fastcwd;
$MY_LD_RUN_PATH = "$Config{installsitearch}/auto/libmetaphone:$pwd";


WriteMakefile(
	'NAME'		=> 'libmetaphone',
	'VERSION_FROM'	=> '../lib/Text/TransMetaphone.pm', # finds $VERSION
	'LINKTYPE'	=> 'static',
	'DEFINE'	=> '-DMETA_USE_PERL_MALLOC', # e.g., '-DHAVE_SOMETHING' 
	'INC'		=> '-I../include',
	# 'CCFLAGS'	=> '-funsigned-char',
	'OBJECT'	=> '$(O_FILES)',
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "The non-en_US specific functions for the TransMetaphone package.",
);

$ENV{LD_RUN_PATH} = 
    "$ENV{LD_RUN_PATH}:$Config{installsitearch}/auto/libmetaphone:$pwd";

sub MY::top_targets {
    my $self = shift;
    my $string = $self->MM::top_targets;
    my $libapreq = <<"EOF";
LD_RUN_PATH = $ENV{LD_RUN_PATH}
EOF

    my $so = "\n".'$(DLBASE).$(DLEXT): $(INST_DYNAMIC)'."\n";

    $string =~ s/(pure_all\s+::\s+)(.*)/$1 static $2/;
    return $libmetaphone . $so . $string;
}



sub no_MY {
    for (keys %MY::) {
        if (defined &{ $MY::{$_} }) {
            next if $_ eq 'dynamic';
            undef &{ $MY::{$_} };
            delete $MY::{$_};
        }
    }
}
