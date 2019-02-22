# XML::Axk::Base: common definitions for axk.
# Thanks to David Farrell,
# https://www.perl.com/article/how-to-build-a-base-module/

package XML::Axk::Base;
use parent 'Exporter';
use Import::Into;

# Pragmas
use 5.020;
use feature ":5.20";    # Use expressly so we can re-export it below
use strict;
use warnings;

# Packages
use Data::Dumper;
use Carp;

# Definitions from this file
use constant {
    true => !!1,
    false => !!0,

    SCRIPT_PKG_PREFIX => 'axk_script_',

    # When to run an action --- pre, post, or both (CIAO).
    HI => 2,
    BYE => 1,
    CIAO => 0,  # the only falsy one
};

our @EXPORT = qw(true false HI BYE CIAO);
our @EXPORT_OK = qw(any SCRIPT_PKG_PREFIX now_names);
our %EXPORT_TAGS = (
    default => [@EXPORT],
    all => [@EXPORT, @EXPORT_OK]
);

# Uncomment for full stacktraces on all errors
BEGIN {
    $SIG{'__DIE__'} = sub { Carp::confess(@_) } unless $SIG{'__DIE__'};
    #$Exporter::Verbose=1;
}

sub import {
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    XML::Axk::Base->export_to_level(1, @_);

    # Re-export pragmas
    feature->import::into($target, qw(:5.20));
    foreach my $pragma (qw(strict warnings)) {
        ${pragma}->import::into($target);
    };

    # Re-export packages
    Data::Dumper->import::into($target);
    Carp->import::into($target, qw(carp croak confess));

} #import()

#    # Example of manually copying symbols, for reference
#    # Copy symbols.
#    my $caller = caller(0);     # get the importing package name
#    do {
#        no strict 'refs';
#        *{"${caller}::true"}  = *{"true"};
#    };

# Copied from List::MoreUtils::PP because I don't need anything else
# from that package at the moment.
sub any (&@)
{
    my $f = shift;
    foreach (@_)
    {
        return 1 if $f->();
    }
    return 0;
}

# Names of NOW constants, for debugging
sub now_names {
    my %names=(HI,"entering", BYE,"leaving", CIAO,"both");
    return $names{+shift} || "unknown";
} # now_names

1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker ft=perl: #
