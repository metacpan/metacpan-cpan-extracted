package rig::parser::yaml;
{
  $rig::parser::yaml::VERSION = '0.04';
}
use strict;
use Carp;

our %rig_files;
our $CURR_RC_FILE;

sub parse {
    my $self = shift;
    my $path = $CURR_RC_FILE = shift || $self->_find_first_rig_file();
    $rig_files{$path} && return $rig_files{$path}; # cache?
    return undef unless $path;
    #confess 'No .perlrig file found' unless $path;
    return $rig_files{$path} = $self->parse_file( $path );
}

sub file {
    return $CURR_RC_FILE;
}

sub parse_file {
    my $self = shift;
    my $file = shift;
    open my $ff, '<', $file or confess $!;
    my $yaml = YAML::XS::Load( join '',<$ff> ) or confess $@;
    close $ff;
    return $yaml;
}

sub _rigpath {
    my $class = shift;
    return split( /[\:|\;]/, $ENV{PERL_RIG_PATH})
        if defined $ENV{PERL_RIG_PATH};

    return( Cwd::getcwd, File::HomeDir->my_home ); #TODO add caller's home
}


sub _is_module_task {
    shift =~ /^\:/;  
}

sub _has_rigfile_tasks {
    my $self = shift;
    for( @_ ) {
        return 1 unless _is_module_task($_)
    }
}


sub _find_first_rig_file {
    my $self = shift;
    return $ENV{PERLRIG_FILE} if defined $ENV{PERLRIG_FILE} && -e $ENV{PERLRIG_FILE};
    my $path;
    # search path
    my $current = Cwd::getcwd;
    my $home = File::HomeDir->my_home;
    for( $self->_rigpath() ) {
        my $path = File::Spec->catfile( $_, '.perlrig' ); 
        return $path if -e $path;
    }

    # not in path, or no path specified
}
1;

=head1 NAME

rig::parser::yaml - YAML parser for rig

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is used by the base engine to find and parse .perlrig YAML files.

=head1 METHODS

=head2 parse

Main method, called by C<rig> to parse a file.

=head2 file

Returns the current loaded file. 

=head2 parse_file

Loads a YAML file using L<YAML::XS>.

=cut 
