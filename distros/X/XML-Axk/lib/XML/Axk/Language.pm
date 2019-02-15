# XML::Axk::Language - common definitions for axk language modules (X::A::Ln).

package XML::Axk::Language;
use XML::Axk::Base ':all';
use Import::Into;
use vars;

use XML::Axk::Vars::Scalar;
use XML::Axk::Vars::Array;

#use Devel::StackTrace;

# Registry mapping XALn package names to arrayrefs of the script parameters
# (SPs) for those packages.
#our %SP_Registry = ();

# Export ========================================================= {{{1
sub import {
    my $class = shift;
    my $lang = caller;
    if($class ne __PACKAGE__) {     # do I need this?
        confess(__PACKAGE__ . " initializer called from class $class");
    }

    #say "XALanguage run from $target:\n", Devel::StackTrace->new->as_string;

    # Set up the registry
    #$SP_Registry{$lang} = [] unless exists $SP_Registry{$lang};
    #my $lrRegistry = $SP_Registry{$lang};

    my %opts = ( $#_>0 && $#_ ? @_ : () );  # even number of args => options

    my (@sps, $drUpdater);  # option values for sp, updater
    my $sandbox;    # _AxkSandbox in the target, if any

    # sp: populate the registry with the given variables.
    if(exists $opts{sp} && $opts{sp}) {
        croak "Need an arrayref for the SPs" unless ref $opts{sp} eq 'ARRAY';
        @sps = @{$opts{sp}};
    } #`sp` option

    # updater: the function that updates the SPs each record
    if(exists $opts{updater} && $opts{updater}) {
        croak "Need a code ref for the SPs" unless ref $opts{updater} eq 'CODE';
            # TODO permit methods?
        $drUpdater = $opts{updater};
    } #`sp` option

    # target: mark the given axk_script (if any)
    if(exists $opts{target} && $opts{target}) {

        my $target = $opts{target};
        my $sandboxname = "${target}::_AxkSandbox";

        #say "Loading $varname with $lang";
        do {
            no strict 'refs';
            #croak "A script can only use one language" if defined $$varname;

            $sandbox = $$sandboxname if defined $$sandboxname;
        };

        # Inject the script parameters
        if(@sps) {
            vars->import::into($target, @sps);  # Create the SP vars...

            if($sandbox) {     # ... then link them to storage in the core.
                $sandbox->allocate_sps($lang, @sps);
                $sandbox->inject_var($lang, $_) for @sps;
            }
        }

        # Set the updater.
        if($sandbox && $drUpdater) {
            $sandbox->set_updater($lang, $drUpdater);
        }

    } #`target` option

} #import()

# }}}1
1;
# === Documentation ===================================================== {{{2

=pod

=encoding UTF-8

=head1 NAME

XML::Axk::Language - base language code for the axk XML processor

=head1 VERSION

Version 0.01

=head1 USAGE

When implementing a language:

    require XML::Axk::Language;
    sub import {
        XML::Axk::Language->import( target => caller, sp => [qw($foo @bar)],
            updater => sub { ... } );
    }

If all you need is the registry:

    use XML::Axk::Language ();
    # Then do something with @XML::Axk::Language::SP_Registry.

=head1 OPTIONS

C<target>: the name of the package to load the script parameters (SPs) into

C<sp>: the list of script parameters to load.

C<updater>: a code ref to a function that will update the SPs based on the data
of a record.  C<&updater> is called with a hashref of the SPs as the first
parameter, and key/value pairs of the record data as the remaining parameters.
C<&updater> should directly update the hashref, not replace it.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}2
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker foldlevel=1: #
