use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my %param = (
    NAME         => 'Win32::Internet',
    VERSION_FROM => 'Internet.pm',
    INC          => '-I.',
);
$param{LIBS} = ['wininet.lib'] if $Config{cc} =~ /^cl/i;
$param{LIBS} = ['-L/lib/w32api -lwininet -lversion'] if $^O eq "cygwin";
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
WriteMakefile(%param);

package MY;
use Config qw(%Config);
sub const_loadlibs {
    my ($self) = @_;
    if ($^O eq "MSWin32") {
	if ($Config{cc} =~ /^gcc/i) {
	    $self->{LDLOADLIBS} .= " -lwininet";
	}
	elsif ($Config{cc} =~ /^bcc/i) {
	    $self->{LDLOADLIBS} .= " inet.lib";
	}
	elsif ($] == 5.006 && $Config{cc} =~ /^cl/i) {
	    $self->{LDLOADLIBS} .= " wininet.lib";
	}
    }
    return $self->SUPER::const_loadlibs;
}
