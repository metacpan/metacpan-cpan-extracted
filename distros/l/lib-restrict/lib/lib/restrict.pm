package lib::restrict;

use strict;
use warnings;
our $VERSION = '0.0.5';

use base 'lib';

sub import {
    shift;
    
    my %uid;
    my %okd;
    my $chk = '';
    if(defined $_[-1] && (ref $_[-1] eq 'ARRAY' || $_[-1] =~ m/^\d+$/ || ref $_[-1] eq 'CODE')) {
        if(ref $_[-1]) {
            if(ref $_[-1] eq 'ARRAY') {
    	        @uid{ grep { m/^\d+$/ } @{$_[-1]} } = ();
    	    }
    	    else {
    	        $chk = $_[-1];
    	    }
        }
        else {
    	    $uid{ $_[-1] } = $_[-1];
        }
        pop @_;
    }
    
    for (@_) {
	    my $path = $_; # we'll be modifying it, so break the alias, is there an echo in here :)
	    eval {
	        $path    = lib::_nativize($path);
	    }; # we eval since older lib.pm's don't have this
	    
	    if(!-d $path && ref $ENV{'lib::restrict-!-d_ok_in'} eq 'ARRAY') {
	        my $ok = 0;
	        require File::Spec;
	        require File::Basename;
	        
	        my $absolute = File::Spec->file_name_is_absolute($path) ? $path : File::Spec->rel2abs( $path );
	        my $pathless = File::Basename::dirname($absolute);

	        if(File::Spec->file_name_is_absolute($absolute)) {
    	        for my $base (@{ $ENV{'lib::restrict-!-d_ok_in'} }) {
                    $base =  File::Spec->rel2abs($base) if !File::Spec->file_name_is_absolute($base);
    	            my $grow = ''; # IE '/'
    	            for my $part (File::Spec->splitdir($base)) {
    	                $grow = File::Spec->catdir($grow, $part);
    	                $ok = 1 if $pathless eq $grow;
    	            }
    	        } 
    	        $okd{ $_ } = 1; 
    	        next if $ok;
            }
	    }

	    if( (keys %uid && !exists $uid{ _get_owner($path) }) || (ref $chk eq 'CODE' && !$chk->($_)) ) {
	        if( !$ENV{'lib::restrict-quiet'} ) {
	            require Carp;
	            Carp::carp('Parameter to use lib::restrict is not allowed');
            }
	        @_ = grep { !m/^$path$/ } @_;    	
        }
    }
    
    lib->import(@_); # SUPER instead ??
    @lib::restrict::ORIG_INC = @lib::ORIG_INC;
    
    if(keys %uid) {
        @INC = grep { exists $uid{_get_owner($_)} || exists $okd{ $_ } } @INC; # uninit value ??
    }

    return;
}

sub _get_owner {
    my $own = (stat shift)[4];	
	return defined $own ? $own : '';
}

1;

__END__

=head1 NAME

lib::restrict - Perl extension for restricting what goes into @INC

=head1 SYNOPSIS

    use lib::restrict qw(foo bar baz), $restiction;
 
    use lib::restrict qw(foo bar baz);
    
    no lib::restrict qw(foo bar baz);

=head1 DESCRIPTION

lib::restrict useage and functionality is the same as 'use L<lib>' and 'no L<lib>' (because it ISA lib::) with an additional feature described below.

=head1 RESTRICTING WHAT GOES INTO @INC

If the last item passed to use lib::restrict is all digits or an array ref of items 
that are all digits then only paths passed that are owned by those uids are used.

    # add /foo and /bar only if owned by root
    use lib::restrict '/foo', '/bar', 0;

or

    # add /foo and /bar only if owned by root, effective uid, or real uid
    use lib::restrict '/foo', '/bar', [0, $>, $<];

This means if you are adding a directory that is all digits it has to go somewhere besides the end.

    # add the path 123 if owned by root *not* add the paths 123 and 0
    use lib::restrict '123', '0';

This is not true if its the only argument:
 
    use lib::restrict '123'; # treats 123 as a path not a uid

Any items that are non numeric are simply ignored:

    use lib::restrict '/foo', '/bar', '/baz'; # adds those 3 paths

    use lib::restrict '/foo', '/bar', [qw( /baz 0 123 /wop)]; # adds /foo and /bar if its owned by root or uid 123

In addition the last item can be a code reference that accepts tha filename as 
its only argument and returns true if its ok to add and false to not add it.

=head1 CONTROLLING BEHAVIOR VIA %ENV

If true, $ENV{'lib::restrict-quiet'}, stiffles the carp when a path is denied.

Set $ENV{'lib::restrict-!-d_ok_in'} to an array ref of absolute paths (will be made absolute if relative). 
Any paths passed to lib::restrict that do not exist but whose parent is in that list will be allowed and the uid/code ref check ignored.

In other words if you 

    local $ENV{'lib::restrict-!-d_ok_in'} = ['/foo'];
    # assuming neither exists yet
    use lib::restrict qw(/foo/bar /foo/baz/wop, $restriction);

/foo/bar made it because /foo, its parent is in the list.

/foo/baz/wop did not because it parent, /foo/baz, is not in the list

=head1 SEE ALSO

L<lib>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
