=head1 NAME

XAO::PluginUtils - utilities for plug-ins installation

=head1 SYNOPSIS

 Makefile.PL:
 ....
 install::
        \$(PERL) -MXAO::PluginUtils=install_templates \\
                 -e'install_templates("MANIFEST",1)'

=head1 DESCRIPTION

This modules includes some utility functions aided to help plug-in
authors in the installation of templates and other content into the
appropriate directories.

See examples the Makefile.PL of XAO::Web and XAO::DO::Web::PodView
packages.

=cut

package XAO::PluginUtils;
use strict;
use XAO::Base qw($homedir);
use File::Path;
use File::Basename;
use File::Copy;

require Exporter;

use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION);

@ISA=qw(Exporter);
@EXPORT_OK=qw(install_templates);
@EXPORT=();

$VERSION=(0+sprintf('%u.%03u',(q$Id: PluginUtils.pm,v 2.1 2005/01/14 01:39:56 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub install_templates ($;$) {
    my $manifest=shift || 'MANIFEST';
    my $force=shift || 0;

    $homedir && -x $homedir || die "Can't get home directory from XAO::Base!\n";

    if(!$force && $homedir =~ /\/devsite\b/) {
        print "Would not install templates to devsite installation (this is not an error).\n";
        return 0;
    }

    if(!$force && -l "$homedir/templates") {
        print "Would not install templates to sym-linked directory ($homedir/templates).\n";
        exit(0);
    }

    open(F,$manifest) || die "Cannot open $manifest: $!\n";
    umask 022;
    while(my $file=<F>) {
        chomp($file);
        next unless $file =~ /^templates\//;
        my $outfile=$homedir . '/' . $file;
        print "Copying to $outfile\n";
        mkpath([dirname($outfile)],0,0755);
        copy($file,$outfile) || die "Cannot copy $file to $outfile: $!\n";
        chmod 0644, $outfile;
    }
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
