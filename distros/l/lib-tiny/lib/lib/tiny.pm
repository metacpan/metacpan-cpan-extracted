package lib::tiny;

# use strict; # this works but is disabled for production, since it doesn't gain any thing in this mod and adds appx 184K to memory
$lib::tiny::VERSION = 0.7;

sub import {
    shift;
    my %seen;
    for ( reverse @_ ) {
        next if !defined $_ || $_ eq '';
        unshift @INC, $_ if -d $_;

        # if we can do this without Config and 'tiny' File::Spec-ness to properly join their names into a path...
        # handle '$_/@{'inc_version_list'} here
        # unshift @INC, "$_/$archname")          if -d "$_/$archname/auto";
        # unshift @INC, "$_/$version")           if -d "$_/$version";
        # unshift @INC, "$_/$version/$archname") if -d "$_/$version/$archname";
    }
    @INC = grep { $seen{$_}++ == 0 } @INC;
}

sub unimport {
    shift;
    my %ditch;
    @ditch{@_} = ();

    # if import ever does version/archname/inc_version_list paths we need to remove them here
    @INC = grep { !exists $ditch{$_} } @INC;
}

1;
