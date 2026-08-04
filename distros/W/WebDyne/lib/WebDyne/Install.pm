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
$VERSION='3.007';


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
    my $dry_run=$ENV{'DRY_RUN'};


    #  Delete cache files and remove if empty
    #
    if ($cache_dn && (-d $cache_dn)) {
        my @file_cn=glob(File::Spec->catfile($cache_dn, '*'));
        message "removing cache files from '$cache_dn'";
        foreach my $fn (grep {/\w{32}(\.html)?$/} @file_cn) {
            if ($dry_run) {
                message "would remove cache file '$fn'";
                next;
            }
            unlink($fn) ||
                return err("unable to remove cache file $fn, $!");
        }
        message "removing cache directory '$cache_dn'";
        unless ($cache_dn eq File::Spec->tmpdir) {
            if ($dry_run) {
                message "would remove cache directory '$cache_dn'";
            }
            else {
                my @remaining=glob(File::Spec->catfile($cache_dn, '*'));
                unless (@remaining) {
                    rmdir($cache_dn) ||
                        return err("unable to remove cache directory $cache_dn, $!");
                }
            }
        }
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
        if ($ENV{'DRY_RUN'}) {
            message "would create cache directory '$cache_dn'.";
        }
        else {
            File::Path::mkpath($cache_dn, 0, 0755) || do {
                return err("unable to create dir $cache_dn") unless (-d $cache_dn)
            };
        }

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
__END__

=begin markdown

# WebDyne::Install #

# NAME #

WebDyne::Install - base installation helper for WebDyne cache setup

# SYNOPSIS #

```perl
use WebDyne::Install qw(message);

WebDyne::Install->install($prefix);
WebDyne::Install->uninstall($prefix);
```

# DESCRIPTION #

`WebDyne::Install` provides the base installation and uninstall routines used by the WebDyne installer scripts and higher-level installer modules.

Its main job is to determine the appropriate cache directory, create it during installation, and remove WebDyne-managed cache artifacts during uninstall.

# METHODS #

* **install($prefix)**

    Create the cache directory if required and report progress through `message()`. If `DRY_RUN` is set in the environment, report the action without creating the directory.

* **uninstall($prefix)**

    Remove cached compile artifacts from the resolved cache directory and attempt to remove the directory if appropriate. Cache cleanup is limited to files whose names match a 32-character word name, optionally followed by `.html`.

* **cache_dn($prefix)**

    Resolve the cache directory path from `WEBDYNE_CACHE_DN`, an installation prefix, or `DIR_CACHE_DEFAULT`.

* **message(@args)**

    Print installer progress messages unless `SILENT` is set in the environment.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Install


=head1 NAME

WebDyne::Install - base installation helper for WebDyne cache setup


=head1 SYNOPSIS


 use WebDyne::Install qw(message);
 
 WebDyne::Install->install($prefix);
 WebDyne::Install->uninstall($prefix);

=head1 DESCRIPTION

C<WebDyne::Install> provides the base installation and uninstall routines used by the WebDyne installer scripts and higher-level installer modules.

Its main job is to determine the appropriate cache directory, create it during installation, and remove WebDyne-managed cache artifacts during uninstall.


=head1 METHODS

=over

=item *

B<install($prefix)>

Create the cache directory if required and report progress through C<message()>. If C<DRY_RUN> is set in the environment, report the action without creating the directory.



=item *

B<uninstall($prefix)>

Remove cached compile artifacts from the resolved cache directory and attempt to remove the directory if appropriate. Cache cleanup is limited to files whose names match a 32-character word name, optionally followed by C<.html>.



=item *

B<cache_dn($prefix)>

Resolve the cache directory path from C<WEBDYNE_CACHE_DN>, an installation prefix, or C<DIR_CACHE_DEFAULT>.



=item *

B<message(@args)>

Print installer progress messages unless C<SILENT> is set in the environment.



=back


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
