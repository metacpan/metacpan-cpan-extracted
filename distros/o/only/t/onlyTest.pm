package onlyTest;
BEGIN { $^W = 1 }
@EXPORT = qw(version_install site_install create_distributions);

use strict;
use base 'Exporter';
use Test::More;
use File::Spec;
use File::Path;
use Cwd;
use lib File::Spec->catdir(qw(t lib));
use lib File::Spec->catdir(qw(t site));
use only::install qw(install);

sub version_install {
    my ($dist, %args) = @_;
    my $home = Cwd::cwd();
    chdir(File::Spec->catdir(t => distributions => $dist)) or die $!;
    install(%args);
    chdir($home) or die $!;
}

sub site_install {
    my ($dist) = @_;
    my $home = Cwd::cwd();
    my $sitelib = File::Spec->rel2abs(File::Spec->catdir(qw(t site)));
    chdir(File::Spec->catdir(t => distributions => $dist)) or die $!;
    my $lib = File::Spec->catdir(qw(blib lib));
    my $install_map = {
        $lib  => $sitelib,
        read  => '',
    };
    {
        local $^W = 0;
        require ExtUtils::Install;
    }
    ExtUtils::Install::install($install_map, 1, 0);
    chdir($home) or die $!;
}

sub create_distributions {
    my ($spec) = @_;
    for my $dist_name (keys %$spec) {
        my $dist_spec = $spec->{$dist_name};
        for my $dist_ver (keys %$dist_spec) {
            my $path = File::Spec->catdir('t', 'distributions', 
                                          "$dist_name-$dist_ver",
                                         );
            mkpath($path);
            if (int($dist_ver * 100) % 2) {
                my $metafile = File::Spec->catfile($path, 'META.yml');
                open META, '>', $metafile or die $!;
                print META <<END;
---
name: $dist_name
version: $dist_ver
generated_by: onlyTest
END
                close META;
            }
            else {
                my $makefile = File::Spec->catfile($path, 'Makefile');
                open MF, '>', $makefile or die $!;
                print MF <<END;
# Dummy Makefile for testing $dist_name-$dist_ver
DISTNAME = $dist_name
VERSION = $dist_ver
END
                close MF;
            }
            
            my $mod_spec = $dist_spec->{$dist_ver};
            for my $mod_name (keys %$mod_spec) {
                my $lines = '';
                my $mod_ver = $mod_spec->{$mod_name};
                if (ref $mod_ver) {
                    my $ver = shift @$mod_ver;
                    $lines = join "\n", @$mod_ver;
                    $mod_ver = $ver;
                }
                my @parts = split '::', $mod_name;
                my $file = pop @parts;
                my $path2 = File::Spec->catdir($path, 'blib', 'lib', @parts);
                mkpath($path2);
                $file .= '.pm';
                my $module = File::Spec->catfile($path2, $file);
                open MOD, '>', $module or die $!;
                print MOD <<END;
package $mod_name;
\$VERSION = '$mod_ver';
use strict;
$lines
1;
END
                close MOD;
            }
        }
    }
}

1;
