use ExtUtils::MakeMaker;
use Config;
use strict;
use lib qw(../lib);
use Apache::libapreq qw(xsubpp);

my $Is_Win32 = ($^O eq "MSWin32") || $ENV{WIN32_TEST}; 
my @mm_args = (
	       'NAME'	=> 'Apache::Cookie',
	       'VERSION_FROM' => 'Cookie.pm',
	       );

if ($Is_Win32) {
    win32_setup(@mm_args);
#    xsubpp("Cookie");
}
else {
    require Apache::src;
    my $src = Apache::src->new;
    use File::Path 'mkpath';
    my $root = "../blib/arch/auto/libapreq";
    mkpath $root, 1, 0755 unless -d $root;

    #grr, must trick ExtUtils::Liblist
    system "touch $root/libapreq.a";
    WriteMakefile(
        @mm_args,
        'INC'	=> "-I../c ". $src->inc,
        'TYPEMAPS'  => $src->typemaps,
        'OBJECT' => "Cookie.o $root/libapreq.a",
	'dynamic_lib' => {
		'OTHERLDFLAGS' => $src->otherldflags,
	},
    );
    unlink "$root/libapreq.a";
}

sub win32_setup {
  my @mm_args = @_;
  WriteMakefile(
		@mm_args,
		'TYPEMAPS' => [ "$ENV{MP_INC}/typemap" ],
                'INC' => qq{ -I../c -I"$ENV{AP_INC}" -I"$ENV{AP_INC}/../os/win32" -I"$ENV{MP_INC}" },
		'LIBS' => qq{ -L"$ENV{MP_LIB}" -lmod_perl -L"$ENV{APREQ_LIB}" -llibapreq -L"$ENV{AP_LIB}" -lApacheCore },
		'OBJECT' => 'Cookie.o',
	       );
}
