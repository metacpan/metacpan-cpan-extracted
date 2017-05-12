package Untaint;

require 5.005;
use strict;
use Carp;
use Taint qw(any_tainted); 

use vars qw(
    $VERSION
    @ISA
    @EXPORT %EXPORT_TAGS
    $UNTAINT_ALLOW_HASH
);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(is_tainted untaint untaint_hash $UNTAINT_ALLOW_HASH);

$Untaint::VERSION = '0.05';

$UNTAINT_ALLOW_HASH = 0;

# This is just a pass-through
sub is_tainted (@) {
	any_tainted(@_);
}	

sub untaint ($@) {
	my $pattern = shift;
	my @array;
	ref @_ ? (@array = @{$_}) : (@array = @_);
	my @return = map is_tainted($_) ? _do_untaint($pattern, $_) : $_, @array;
	# return as an array if wanted, or in scalar context;
	wantarray ? return @return : return "@return";
}

sub _do_untaint {
	my $pattern = shift;
	my $ref = shift;
	if (/($pattern)/) {
       		$ref = $1;
       		return $ref;
        }else{
               		croak "Unable to launder $_\n";
	}
	       
	
}

sub untaint_hash (%%) {
	my %pattern = %{shift @_};
	my %hash = @_;
	my %return;

	for (keys %hash) { 
		if (exists $pattern{$_}) {
			$return{untaint(qr(^$_), $_)} = untaint($pattern{$_}, $hash{$_});
		}elsif ($UNTAINT_ALLOW_HASH) {
			$return{untaint(qr(^$_), $_)} = untaint(qr(^$hash{$_}), $hash{$_});
		}else {
			next;
		}
	}
	return %return;
}

1;

__END__ 

=head1 NAME

Untaint - Module for laundering tainted data.

=head1 SYNOPSIS

	use Untaint;

	my $pattern = qr(^k\w+);

	my $foo = $ARGV[0];

	# Untaint a scalar
	if (is_tainted($foo)) {
       		print "\$foo is tainted. Attempting to launder\n";
	       	$foo = untaint($pattern, $foo);
	}else{
       		print "\$foo is not tainted!!\n";
	}

	# Untaint an array 
	my @foo = @ARGV;

	push @foo, "not tainted";

	if (is_tainted(@foo)) {
        	print "\@foo is tainted. Attempting to launder\n";
	        my @new = untaint($pattern, @foo);
	}else{
        	print "\@foo is not tainted!!\n";
	}	

	# Another way for an list
	($a, $b, $c) = untaint(qr(^\d+$), ($a, $b , $c));

	# Untaint a hash
	my $test = {'name' => $ARGV[0],
	            'age' => $ARGV[1],
	            'gender' => $ARGV[2],
		    'time' => 'late'
        	   };

	my $patterns = {'name' => qr(^k\w+),
       		        'age' => qr(^\d+),
                	'gender' => qr(^\w$)
                       };

	$UNTAINT_ALLOW_HASH++;

	my %new = untaint_hash($patterns, %{$test});


=head1 DESCRIPTION

This module is used to launder data which has been tainted by using the C<-T> switch
to be in taint mode. This can be used for CGI scripts as well as command line scripts.

The module will untaint scalars, arrays, and hashes. When laundering an array, only
array elements which are tainted will be laundered.

=head2 FUNCTIONS

=item is_tainted(<scalar or array>);

You can use this to check the taintedness of data if you wish,
but it is also used internally by Untaint.pm to do this when untaint() is called. This
method returns 1 if tainted, 0 if not. This is actually a pass-through to Taint.pm's
is_tainted method, since that already accomplishes this task.

=item newvar = untaint(<pattern>, <scalar or array/list>);

This method will launder the data (if it can) and return the newly laundered
variable. It should be passed either a scalar, or an array reference.  
This will return either an array, or a scalar depending on which you want
returned.
The pattern should be a regular expression pattern to match the data against. 

If this method can not launder a variable, it will croak(). 

=item untaint_hash(<hashref of patterns>, hash)

When laundering a hash, a hash of patterns can be passed. This allows you to define a
different pattern for each element of the hash. If there is no pattern for an element
in the hash, the value itself will be used as the pattern (therefore untainting itself).
This behavior isn't really safe, so you need to specify that you want to do this by
setting a special variable to a true value like this:

	$UNTAINT_ALLOW_HASH++;

That scalar is exported so you need to specifically say it is ok to do this.

If this is not done, any key/value pair which does not have a pattern will not be
laundered and the returned hash will only contain the key/value pairs which had
a corresponding pattern.

It appears that whenever there is one value in a hash that is tainted, ALL values in 
that hash are tainted. This is a bug in Perl versions which are pre-5.6. This is 
somewhat of a quagmire since key/value pairs you actually
set are now tainted, and need laundering. That's all well and good, but now there is
the chance that when you pass the hash ref, you pass something without a pattern 
unknowingly, and data you don't want untainted is then laundered. Another current bug
is that all hash keys are not considered tainted. So, be wary of using hash keys which
come from unknown sources in Bad ways. But, if you are trying to use a hash key which
you do not know where it's name is from in a dangerous manner, there may be other 
problems!

=item $UNTAINT_ALLOW_HASH

This variable must be set to a true value of you wish to allow hash values to be
untainted based on their own value as a pattern. In other words, the pattern that
will be matched to untaint it, will be itself, hence always being untainted.
USE THIS WITH CAUTION. 

=head1 INSTALLATION

perl Makefile.PL
make
make test
make install
make clean

Look at the test scripts to see how this can be implemented.

=head1 BUGS

None known at this time. PATCHES WELCOME.

=head1 COPYRIGHT

Copyright (c) 2000 Kevin Meltzer. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Kevin Meltzer, E<lt>F<perlguy@perlguy.com>E<gt>

=head1 CREDITS

Tom Phoenix, E<lt>F<rootbeer@teleport.com>E<gt>

=head1 SEE ALSO

L<perlsec>, L<perlrun>

