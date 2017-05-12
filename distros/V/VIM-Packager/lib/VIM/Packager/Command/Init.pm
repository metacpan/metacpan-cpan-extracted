package VIM::Packager::Command::Init;
use warnings;
use strict;
use VIM::Packager;
use File::Path;
use File::Spec;
use DateTime;
use base qw(App::CLI::Command);

=head1 NAME

VIM::Packager::Command::Init - create vim package skelton

=head1 init

=head2 SYNOPSIS

    $ vim-packager init \
            --name=ohai \
            --type=plugin \
            --author=Cornelius \
            --email=cornelius.howl@gmail.com

or just skip author name and email option if you have L</Autho Info File> 

    $ vim-packager init \
            --name=ohai \
            --type=plugin \

            # optional 
            --dirs
            --dirs=basic
            --dirs=full 
            --dirs=auto  # default

even skip plugin name

    $ cd your-plugin.vim
    $ vim-packager init --type plugin

the plugin name will be C<your-plugin.vim>

=head2 OPTIONS

=over 4

=item --name=[name]  | -n

=item --type=[type]  | -t

=item --author=[author]  | -a

=item --email=[email]  | -e

=item --migrate | -m

=back

=head2 Author Info File

it locates at F<~/.vim-author>.

the format is:

    author: Your Name
    email:  cornelius.howl @ delete-me.gmail.com

=cut

sub options {
    (
        'n|name=s'        => 'name',
        'v|verbose'       => 'verbose',
        'm|migration'     => 'migration',
        't|type=s'        => 'type',
        'a|author=s'      => 'author',
        'e|email=s'       => 'email',
        'd|dirs=s'          => 'dirs',
    );
}

sub run {
    my ( $self, @args ) = @_;

    my $plugin_name;
    my $author;
    my $email;

    $plugin_name ||= $self->{name};
    unless( $plugin_name ) {
        my $cwd;
        chomp($cwd = `pwd`);
        $cwd =~ s{/$}{};
        my @s = split "/", $cwd;
        $plugin_name = pop @s;
        $self->{name} = $plugin_name;
    }

    my $info_file = File::Spec->join( $ENV{HOME}  , '.vim-author' ) ;
    if( -e $info_file ) {
        say "Found author info file";
        # found author information file
        open FH , "<" , $info_file or die $@;
        while( <FH> ) {
            chomp( $self->{author} = $_ ) if s/^author:\s+//;
            chomp( $self->{email}  = $_ ) if s/^email:\s+//;
        }
        say "  Author: " . $self->{author};
        say "  Email:  " . $self->{email};
        close FH;
    }

    unless( $self->{author} and $self->{email} ) {
        say "Please specify --author and --email";
        return;
    }

    # migrate dirs
    if( $self->{migrate} ) {
        File::Path::mkpath [ 'vimlib' ];
        my @known_dir_names = qw(autoload indent syntax colors doc plugin ftplugin after ftdetect);
        for ( @known_dir_names ) {
            if( -e $_ ) {
                say "$_ directory found , migrate $_ into vimlib/ ";
                rename $_ , File::Spec->join( 'vimlib', $_ );
            }
        }
    }

    $self->create_dir_skeleton() if $self->{dirs};

    # if we have doc directory , create a basic doc skeleton
    $self->create_doc_skeleton() 
        if -e File::Spec->join('vimlib' , 'doc') ;

    # create meta file skeleton
    $self->create_meta_skeleton( );

    $self->create_readme_skeleton();
}

sub create_readme_skeleton {
    my $self = shift;
    my $cmd = shift;
    
    say "Creating README";

    open README , ">" , "README";
    print README ""; # XXX
    close README;

}

sub create_doc_skeleton {
    my $self = shift;
    my $name = $self->{name};

    say "Creating doc skeleton.";

    open DOC , ">" , File::Spec->join( 'vimlib', 'doc' , "$name.txt" );
    print DOC <<END;

    *$name.txt*  Plugin for .... 

$name                                       *$name* 
Last Change: @{[ DateTime->now ]}

Version 0.0.0
Copyright (C) yourname
License: MIT license  {{{
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEME and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom 
}}}

CONTENTS                                               *$name-contents*

|$name-description|   Description
|$name-usage|         Usage
|$name-key-mappings|  Key mappings
|$name-variables|     Variables
|$name-contact|       Contact

For Vim version 7.0 or later.
This plugin only works if 'compatible' is not set.
{Vi does not have any of these features.}

==============================================================================
DESCRIPTION                                             *$name-description*

*$name* is a plugin to provide way to ...

==============================================================================
USAGE                                                   *$name-usage*


==============================================================================
KEY MAPPINGS                                            *$name-key-mappings*

xx_key                                                               *xx_key*
  key description here

==============================================================================
VARIABLES                                               *$name-variables*

g:xxx_variable
  Your variable here

==============================================================================
CHANGELOG                                               *$name-changelog*

==============================================================================
CONTACT                                                 *$name-contact*


==============================================================================
Document skeleton generated by VIM::Packager.

vim:tw=78:ts=8:ft=help:norl:fen:fdl=0:fdm=marker:
END
        close DOC;
}

=head2 create_dir_skeleton



=cut

sub create_dir_skeleton {
    my $self = shift;
    say "Creating directories.";
    if( $self->{dirs} eq 'basic' ) {
        File::Path::mkpath [
            map { File::Spec->join( 'vimlib' , $_ ) }  qw(autoload syntax plugin ftplugin ftdetect doc)
        ],1;
    }
    elsif( $self->{dirs} eq 'full' ) {
        File::Path::mkpath [
            map { File::Spec->join( 'vimlib' , $_ ) }  qw(autoload syntax indent colors plugin ftplugin ftdetect compiler doc)
        ],1;
    }
    elsif( $self->{dirs} eq 'auto' ) {

        # create direcotries by type
        my $type = $self->{type};
        if( $type ) {
            if ( $type eq 'syntax' ) {
                File::Path::mkpath [
                    map { File::Spec->join( 'vimlib' , $_ ) }  qw(syntax indent)
                ],1;
            }
            elsif( $type eq 'colors' ) {
                File::Path::mkpath [
                    map { File::Spec->join( 'vimlib' , $_ ) }  qw(colors)
                ],1;
            }
            elsif( $type eq 'plugin' ) {
                File::Path::mkpath [
                    map { File::Spec->join( 'vimlib' , $_ ) }  qw(plugin doc autoload)
                ],1;
            }
            elsif( $type eq 'ftplugin' ) {
                File::Path::mkpath [
                    map { File::Spec->join( 'vimlib' , $_ ) }  qw(ftplugin doc autoload)
                ],1;
            }
        }
        # or we just create some common directories
        else {
            # create basic skeleton directories
            File::Path::mkpath [
                map { File::Spec->join( 'vimlib' , $_ ) }  qw(autoload plugin doc)
            ],1;
        }

    }


}

sub create_meta_skeleton {
    my $self = shift;
    say "Writing META.";

    open FH, ">", "META";
    print FH <<END;
\n=name           @{[ $self->{name} ]}
\n=author         @{[ $self->{author} ]}
\n=email          @{[ $self->{email} ]}
\n=type           @{[ $self->{type} || '[ script type ]' ]}
\n=version_from   [File]
\n=vim_version    >= 7.2
\n=dependency

    [name] >= [version]

    [name]
        | autoload/libperl.vim | http://github.com/c9s/libperl.vim/raw/master/autoload/libperl.vim
        | plugin/yours.vim | http://ohlalallala.com/yours.vim
\n=script

    # your script files here

\n=repository git://....../

END
    close FH;

}

1;
