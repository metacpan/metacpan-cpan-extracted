=head1 NAME

ex::newest - look for newest versions of modules installed several times

=cut

package ex::newest;

{
    local $^W = 0;
    require v5.7.2;
}
use strict;
use warnings;
no warnings 'redefine';

use ExtUtils::MM_Unix;

our $VERSION = '0.02';

sub ex::newest::INC {
    my ($self, $file) = @_;
    return undef if substr($file,-3) ne '.pm'; # Handle only modules
    my $package = substr($file,0,-3);
    $package =~ s,/,::,g;
    my @found;
    my $path;
    for my $dir (@INC) {
	next if ref $dir;
	$path = "$dir/$file";
	push @found, $path if -f $path && -r _;
    }
    return undef if not @found;
    if (@found == 1) {
	$path = $found[0];
    } else {
	my @versions = ();
	for my $f (@found) {
	    my $version = ExtUtils::MM_Unix::parse_version(undef,$f) || 0;
	    push @versions, [ $version, $f ];
	}
	@versions = sort { $b->[0] <=> $a->[0] } @versions;
	$path = $versions[0][1];
    }
    open my $fh, $path
	or return undef; # Fallback to the regular mechanism
    $INC{$file} = $path;
    return $fh;
}

sub rm_hook () {
    @INC = grep { ref ne __PACKAGE__ } @INC;
}

# We override lib.pm to ensure that the ex::newest object
# remains in front of @INC.

sub lib::import {
    rm_hook;
    local *lib::import;
    local $^W = 0;	# Silent non-lexical warnings
    delete $INC{'lib.pm'};
    require lib;
    import lib @_[1..$#_];
    import ex::newest;
}

sub lib::unimport {
    rm_hook;
    local *lib::unimport;
    local $^W = 0;
    delete $INC{'lib.pm'};
    require lib;
    unimport lib @_[1..$#_];
    import ex::newest;
}

sub import {
    unshift @INC, bless {} unless grep { ref eq __PACKAGE__ } @INC;
    $INC{'lib.pm'} = __FILE__;
}

sub unimport {
    rm_hook;
    # Restore lib.pm
    local $^W = 0;
    delete $INC{'lib.pm'};
    require lib;
}

1;
__END__

=head1 SYNOPSIS

use ex::newest;

use My::Module;		# Load newest version present

no ex::newest;

=head1 DESCRIPTION

With this pragma, when you try to load a module with C<use> or
C<require>, all directories specified in @INC will be searched for
occurences of this module, and the most recent version found will be
loaded.

The versions of the installed modules are computed by using
C<ExtUtils::MM_Unix::parse_version>.

=head1 BUGS

Doesn't work when @INC contains hooks. More generally, you shouldn't
manipulate @INC directly when using this module, unless you know what
you're doing.

=head1 AUTHOR

Copyright (c) 2001 Rafael Garcia-Suarez. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
