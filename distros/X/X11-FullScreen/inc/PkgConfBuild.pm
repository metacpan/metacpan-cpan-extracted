package
PkgConfBuild;

use strict;
use warnings;

use base 'Module::Build';

use Devel::CheckLib;
use ExtUtils::PkgConfig;

sub new {
	my $type = shift;
	my %opts = @_;
	
	check_lib_or_exit(
	    lib => [qw(Imlib2 X11)]
    );
    
	my %x11_info = ExtUtils::PkgConfig->find('x11');
	my %imlib2_info = ExtUtils::PkgConfig->find('imlib2');

    $opts{'extra_linker_flags'} = $imlib2_info{'libs'} . ' ' . $x11_info{'libs'};
    $opts{'extra_compiler_flags'} = '-I. ' . $imlib2_info{'cflags'} . ' ' . $x11_info{'cflags'};

	return $type->SUPER::new(%opts);
}

1;