package VIM::Packager::Git;
use warnings;
use strict;
use File::Path qw(mkpath rmtree);

use constant build_dir => ( $ENV{VIM_BUILD_DIR} || '/' . File::Spec->join( qw(tmp vim-build) ) );

sub rand_hash { join "", map { ( 'a' .. 'z' )[ rand(26) ] }  1 .. $_[0] } 


sub new {
    return bless {} , shift;
}

sub clone {
    my ($self , $clone_path) = @_;

    mkpath [ build_dir ] unless -e build_dir;
    chdir build_dir;

    my ($build_name) = ( $clone_path =~ m{\/([a-zA-Z0-9-_.]+?)$} );

    my $hash = rand_hash(5);
    $build_name =~ s{\.git$}{}g;
    $build_name .= '-' . $hash;

    $self->{build_name} = $build_name;
    $self->{build_path} = File::Spec->join( build_dir , $build_name );

    my $ret = system(qq{git clone $clone_path $build_name});
    chdir $build_name;

    # do install
    # from here
    return $build_name;
}


sub build_path { $_[0]->{build_path} }
sub build_name { $_[0]->{build_name} }


sub cleanup {
    chdir "..";
    my $self = shift;
    rmtree [ $self->{build_name} ];
}

1;
