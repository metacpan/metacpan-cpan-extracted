package builder::MyBuilder;
use strict;
use warnings;
use 5.008001;
use base 'Module::Build::XSUtil';
use File::Which;
use Devel::CheckLib;

which('aalib-config') or exit 1;
my @link_flags = split ' ', `aalib-config --libs`;
my @cflags     = split ' ', `aalib-config --cflags`;

my (@libs, @lib_paths);
for my $flag (@link_flags) {
    if ($flag =~ m{\A-l(.+)\z}) {
        push @libs, $1;
    } elsif ($flag =~ m{\A-L(.+)\z}) {
        push @lib_paths, $1;
    }
}

my @inc_paths;
for my $flag (@cflags) {
    push @inc_paths, $1 if $flag =~ m{\A-I(.+)\z};
}

Devel::CheckLib::check_lib_or_exit(
    lib     => [@libs],
    libpath => [@lib_paths],
    incpath => [@inc_paths],
    header  => ['aalib.h'],
);

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new(
        %args,
        c_source => 'xs-src',
        xs_files => {
            './xs-src/AAlib.xs' => './lib/Text/AAlib.xs',
        },
        generate_ppport_h  => 'lib/Text/ppport.h',
        needs_compiler_c99 => 1,
        extra_compiler_flags => [ @cflags ],
        extra_linker_flags   => [ @link_flags ],
    );
    return $self;
}

1;
