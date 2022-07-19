package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

use Config ();

my $UID2_DIR = 'ext/uid2-client-cpp11';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    # cmake is required for building uid2-client-cpp11
    if (my $cmake = $self->args('with-cmake')) {
        print "Using cmake: $cmake\n";
    } else {
        print "Detecting cmake: ";
        system 'which', 'cmake' and die "Can't detect cmake";
    }

    my $openssl = $self->args('with-openssl-root-dir');
    my @extra_compiler_flags = (qw(
        -x c++ --std=c++11 -I.
        -Wall -Wextra -Wno-parentheses
        -Wno-unused -Wno-unused-parameter
    ), "-I$UID2_DIR/include");
    my @extra_linker_flags = ('-lstdc++', "-L$UID2_DIR/build/lib", '-luid2client');
    if ($openssl) {
        push @extra_linker_flags, "-L$openssl/lib";
    }
    push @extra_linker_flags, ('-lssl', '-lcrypto');
    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
    }
    $self->extra_compiler_flags(@extra_compiler_flags);
    $self->extra_linker_flags(@extra_linker_flags);
    $self;
}

sub compile_xs {
    my ($self, $file, %args) = @_;
    require ExtUtils::ParseXS;
    $self->log_verbose("$file -> $args{outfile}\n");
    ExtUtils::ParseXS::process_file(
        filename   => $file,
        prototypes => 0,
        output     => $args{outfile},
        'C++'      => 1,
        hiertype   => 1,
    );
}

sub is_debug {
    -d '.git';
}

sub ACTION_build {
    my $self = shift;
    $self->ACTION_ppport_h() unless -e 'ppport.h';
    my $cmake = $self->args('with-cmake') || 'cmake';
    $cmake .= ' -DCMAKE_POSITION_INDEPENDENT_CODE=ON';
    if (my $openssl = $self->args('with-openssl-root-dir')) {
        $cmake .= " -DOPENSSL_ROOT_DIR=$openssl";
    }
    system <<"END_CMD" and die $!;
cd $UID2_DIR \\
&& (patch --batch --quiet --forward -p1 < ../uid2-client-cpp11.patch || true) \\
&& mkdir -p build \\
&& cd build \\
&& $cmake .. \\
&& make
END_CMD
    $self->SUPER::ACTION_build();
}

sub ACTION_ppport_h {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('ppport.h');
}

1;
__END__
