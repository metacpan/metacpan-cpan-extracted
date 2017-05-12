########################################################################
# Example code to demonstrate the population of the disk cache         #
# automatically with an "external" program                             #
#                                                                      #
# PS: if you are using globals (defined in the Dummy package)          #
# either duplicate the controller code here or the related template    #
# will die upon compiling. Since the compiled code will be generated   #
# anyway, this is not an issue for the disk cache.                     #
########################################################################
# Copyright 2008 Burak Gursoy. All rights reserved.                    #
########################################################################
# This code is free software; you can redistribute it and/or modify    #
# it under the same terms as Perl itself, either Perl version 5.8.8 or # 
# at your option, any later version of Perl 5 you may have available.  #
########################################################################
use strict;
use warnings;
use Cwd;
use File::Find;
use File::Spec::Functions qw( catfile );
use Text::Template::Simple;

our $VERSION = '0.10';

my $source_dir = '/full/path/to/original/templates';
my $cache_dir  = '/full/path/to/cache/directory';
my $extension  = qr{ [.]tts \z }xms; # the extension of files to compile

my $cwd = getcwd;
chdir $source_dir;

my $t = Text::Template::Simple->new( cache => 1, cache_dir => $cache_dir );

find { no_chdir => 1, wanted => \&search_and_compile }, q{.};

chdir $cwd; # restore

sub search_and_compile {
    return if -d;
    return if $_ !~ $extension;
    my $file = catfile $_;
    warn "COMPILING: $file\n";
    my $rv = eval {
        $t->compile( $file, undef, { chkmt => 1 } );
    };
    return if ! $@;
    warn "ERROR: $@\n"; # recoverable
    return;
}

1;
