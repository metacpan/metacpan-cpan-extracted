package Test2::Harness::Config;
use strict;
use warnings;

use Carp qw/croak confess/;
use Storable qw/store retrieve/;

use Test2::Harness::TestFile;
use File::Find;
use File::Spec;

use Test2::Util qw/pkg_to_file/;

use Test2::Harness::HashBase qw{
    -jobs
    -libs -lib -blib
    -preload -switches
    -merge -event_stream
    -parser
    -tests
};

sub init {
    my $self = shift;

    $self->{+JOBS}   ||= 1;
    $self->{+TESTS}  ||= ['t'];
    $self->{+PARSER} ||= 'Test2::Harness::Parser::TAP';
}

sub write {
    my $self = shift;
    my ($dir) = @_;

    my $file = "$dir/config";

    croak "Config file '$file' already exists"
        if -f $file;

    store($self, $file);
}

sub read {
    my $self = shift;
    my ($dir) = @_;

    my $file = "$dir/config";

    croak "Config file '$file' does not exist"
        unless -f $file;

    retrieve($file);
}

sub cli_switches {
    my $self = shift;

    my @out;

    my @libs;
    push @libs => 'lib' if $self->{+LIB};
    push @libs => 'blib/lib', '-Iblib/arch' if $self->{+BLIB};
    push @libs => @{$self->{+LIBS}} if $self->{+LIBS};
    push @libs => @INC;

    push @out => map { "-I" . File::Spec->rel2abs($_) } @libs;

    my @switch_list;
    push @switch_list => $self->{+SWITCHES} if $self->{+SWITCHES};
    push @switch_list => @_ if @_;

    for my $switches (@switch_list) {
        for (my $i = 0; $i < @$switches; $i++) {
            my $switch = $switches->[$i];
            my $next = $switches->[$i + 1];

            if ($next && substr($next, 0, 1) ne '-') {
                push @out => ($switch, $next);
                $i++;
                next;
            }

            push @out => $switch;
        }
    }

    return @out;
}

sub load_preloads {
    my $self = shift;
    my $load = $self->{+PRELOAD} or return 0;

    for my $mod (@$load) {
        my $file = pkg_to_file($mod);
        require $file;
    }

    return 1;
}

sub find_tests {
    my $self = shift;
    my $tests = $self->{+TESTS};

    my @files;

    for my $test (@$tests) {
        my ($chdir, $path);
        my $ref = ref($test);

        if    (!$ref)           { ($path, $chdir) = ($test, '.') }
        elsif ($ref eq 'ARRAY') { ($path, $chdir) = @$test }
        elsif ($ref eq 'HASH')  { ($path, $chdir) = @{$test}{qw/path chdir/} }

        $chdir = File::Spec->rel2abs($chdir || '.');
        $path  = File::Spec->rel2abs($path);

        if (-d $path) {
            File::Find::find(
                sub {
                    no warnings 'once';
                    return unless -f $_ && m/\.t2?$/;
                    push @files => Test2::Harness::TestFile->new(filename => $File::Find::name, chdir => $chdir);
                },
                $path
            );
        }
        elsif (-f $path) {
            push @files => Test2::Harness::TestFile->new(filename => $path, chdir => $chdir);
        }
        else {
            die "'$path' is not a valid test file or directory.\n";
        }
    }

    return sort { $a->filename cmp $b->filename } @files;
}

1;
