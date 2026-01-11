#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::Install;


#  Compiler Pragma
#
sub BEGIN {$^W=0}
use strict qw(vars);
use vars   qw($VERSION @EXPORT_OK @ISA);
use warnings;
no warnings qw(uninitialized);


#  Export the message function
#
require Exporter;
@ISA=qw(Exporter);
@EXPORT_OK=qw(&message);


#  WebDyne Modules
#
use WebDyne::Util;


#  Constants
#
use WebDyne::Constant;
use WebDyne::Install::Constant;


#  External Modules
#
use File::Path;
use File::Spec;
use IO::File;
use Config;


#  Version information
#
$VERSION='2.060';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Uninstaller global
#
my $Uninstall_fg;


#  Init done.
#
1;


#------------------------------------------------------------------------------


sub message {


    #  Print out messages unless silent flag set
    #
    return if $ENV{'SILENT'};
    @_ || return print $/;
    my $message=
        sprintf(join('[%sinstall] - ', undef, ucfirst(shift())) . $/, $Uninstall_fg && 'un', @_);
    $message=~s/\.?$/\./;
    print $message;


}


sub uninstall {


    #  Get prefix, discard class
    #
    my (undef, $prefix)=@_;
    $prefix=undef if ($prefix eq $Config{'prefix'});


    #  Set uninstall flag
    #
    $Uninstall_fg++;
    message;


    #  Get cache dn
    #
    my $cache_dn=&cache_dn($prefix);


    #  Delete cache files and remove if empty
    #
    if ($cache_dn && (-d $cache_dn)) {
        my @file_cn=glob(File::Spec->catfile($cache_dn, '*'));
        message "removing cache files from '$cache_dn'";
        foreach my $fn (grep {/\w{32}(\.html)?$/} @file_cn) {
            unlink $fn;    #don't error here if problems, user will never see it
        }
        message "removing cache directory '$cache_dn'";
        rmdir $cache_dn unless ($cache_dn eq File::Spec->tmpdir);
    }

    #if ($prefix) {
    #    message "updating perl5lib config.";
    #    &perl5lib::del($prefix) if $prefix;
    #    rmdir($prefix) if $prefix;
    #}


    #  Done
    #
    return \undef;

}


#  Create cache dir and update perl5lib param
#
sub install {


    #  Get prefix, discard class
    #
    my (undef, $prefix)=@_;
    #$prefix=undef if ($prefix eq $Config{'prefix'});
    $prefix=undef if ($prefix=~/^$Config{'prefix'}/);

    message;
    message sprintf(q[installation source directory '%s'.], $prefix || $Config{'prefix'});


    #  Create the cache dir
    #
    unless (-d (my $cache_dn=&cache_dn($prefix))) {

        #  Make
        #
        message "creating cache directory '$cache_dn'.";
        File::Path::mkpath($cache_dn, 0, 0755) || do {
            return err("unable to create dir $cache_dn") unless (-d $cache_dn)
        };

    }
    else {

        message "using existing cache directory '$cache_dn'.";

    }


    #  Add prefix to perl5lib store
    #
    #message "updating perl5lib config.";
    #&perl5lib::add($prefix) if $prefix;


    # Done
    #
    message;


    # Done
    #
    return \undef;

}


#  Work out cache dn
#
sub cache_dn {


    #  Get any prefix supplied
    #
    my $prefix=shift();


    #  Var to hold returned result
    #
    my $cache_dn;


    #  Use user specified location
    #
    if ($WEBDYNE_CACHE_DN) {
        $cache_dn=$WEBDYNE_CACHE_DN;
        debug("using WEBDYNE_CACHE_DN: $WEBDYNE_CACHE_DN for cache_dn");
    }

    #  If installed into custom location via PREFIX, but not the same
    #  as the Perl instal,
    #elsif ($prefix && ($prefix ne $Config{'prefix'})) {
    elsif ($prefix && ($prefix !~ /^$Config{'prefix'}/)) {
        $cache_dn=File::Spec->catdir($prefix, 'cache');
        debug("using prefix: $prefix for cache_dn");
    }


    #  No prefix spec'd, or prefix is the same as Perl install dir, so
    #  use default location
    #
    else {
        $cache_dn=$DIR_CACHE_DEFAULT;
        debug("using DIR_CACHE_DEFAULT: $DIR_CACHE_DEFAULT as cache_dn");
    }


    #  Done return result
    #
    return $cache_dn;

}
