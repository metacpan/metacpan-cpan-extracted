package UR::ModuleBuild;
use strict;
use warnings;
use base 'Module::Build';

sub ACTION_clean {
    # FIXME: is this safe?
    use File::Path qw/rmtree/;
    rmtree "./_build";
    rmtree "./blib";
    unlink "./Build";
    unlink "./MYMETA.yml";
}

our $ns = 'UR';
our $cmd_class = 'UR::Namespace::Command';

sub ACTION_ur_docs {
    # We want to use UR to autodocument our code.  This is done
    # with module introspection and requires some namespace hackery
    # to work.  ./Build doc comes after ./Build and copies the root
    # namespace module into ./blib to fake a Genome namespace so this will work.
    use File::Copy qw/copy/;
    $ENV{ANSI_COLORS_DISABLED} = 1;
    
    eval {
        my $oldpwd = $ENV{PWD};

        unshift @INC, "$ENV{PWD}/blib/lib";

        my ($namespace_src_dr) = grep { -s "$_/$ns.pm" } @INC;
        unless ($namespace_src_dr) {
        die "Failed to find $ns.pm in \@INC.\n";
        }

        chdir "$ENV{PWD}/blib/lib/$ns" || die "Can't find $ns/";
        unless (-e "../$ns.pm") {
            copy "$namespace_src_dr/$ns.pm", "../$ns.pm" || die "Can't find $ns.pm";
        }

        eval "use $ns";
        $cmd_class->class();

        UR::Namespace::Command::Update::Pod->execute(
            base_commands => [ $cmd_class ],
        );
        # We need to move back for perl install to find ./lib
        chdir $oldpwd;
    };

    die "failed to extract pod: $!: $@" if ($@);
}

sub ACTION_docs {
    my $self = shift;
    $self->depends_on('ur_docs');
    $self->depends_on('code');
    $self->depends_on('manpages', 'html');
}



1;
__END__

=pod

=head1 NAME

UR::ModuleBuild - a Module::Build subclass with UR extensions

=head1 VERSION

This document describes UR::ModuleBuild version 0.47.

=head1 SYNOPOSIS

In your Build.PL:

use UR::ModuleBuild;

my $build = UR::ModuleBuild->new(
  module_name => 'MyApp',
  license => 'perl',
  dist_version => '0.01',
  dist_abstract => 'my app rocks because I get to focus on the problem, not the crud',
  build_requires => {
    'UR' => '0.32',
  },
  requires => {
    'Text::CSV_XS' => '',
    'Statistics::Distributions' => '',
  },
);

$build->create_build_script;

