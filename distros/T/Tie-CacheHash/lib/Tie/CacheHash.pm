# Tie::CacheHash -- Maintains sorted lists of top entries.  -*- perl -*-
#
# Copyright 1999 by Jamie McCarthy <jamie@mccarthy.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Version 0.50: First version, does what it's supposed to do,
#	        tested only in-house so far.

############################################################################
# Modules and declarations
############################################################################

package Tie::CacheHash;

require 5.003;

use strict;
use vars qw(
        $VERSION
        $DEBUG
        );

use Carp;

# The version of this module is its CVS revision.
$VERSION = '0.50';
$DEBUG = 0;

############################################################################
# Tie methods
############################################################################

sub TIEHASH {
    my($class, @args) = @_;
    $class = ref($class) || $class;

    my $details = "see 'perldoc Tie::CacheHash' for details";
    if (scalar(@args) != 1) {
	Carp::croak("Tie::CacheHash requires exactly one argument,"
	    . " and it must be a reference to a hash - $details");
    }

	# "ahr" = "argument hash ref"
    my $ahr = $args[0];
    if (!ref $ahr or ref $ahr ne 'HASH') {
	Carp::croak("the argument passed to Tie::CacheHash must be a"
	    . " hash reference - $details");
    }

    $ahr->{min}		= '1%'	if !defined($ahr->{min});
    $ahr->{min_margin}	= '1%'	if !defined($ahr->{min_margin});
    $ahr->{max_margin}	= '5%'	if !defined($ahr->{max_margin});
    $ahr->{max}		= '10%'	if !defined($ahr->{max});
    $ahr->{sort_func}	= undef	if !defined($ahr->{sort_func});
    $ahr->{sort_rev}	= 0	if !defined($ahr->{sort_rev});
    $ahr->{scan_min}	= 800	if !defined($ahr->{scan_min});
    $ahr->{fudge}	= 0.1	if !defined($ahr->{fudge});
    $ahr->{sub_hash}	= undef	if !defined($ahr->{sub_hash});

    my $self = {

	h		=> { },
	cache		=> [ ],

	# The user may set these variables directly, either in the
	# arguments passed to tie() or BEFORE any data is stored in
	# the hash.  As soon as any data is stored in the hash,
	# the user MUST NOT change these.

	min		=> $ahr->{min},
	min_margin	=> $ahr->{min_margin},
	max_margin	=> $ahr->{min_margin},
	max		=> $ahr->{max},

	sort_func	=> $ahr->{sort_func},
	sort_rev	=> $ahr->{sort_rev},

	# These variables are used to perform cache_remove efficiently.
	# They may be edited by the user at any time.

	scan_min	=> $ahr->{scan_min},
	fudge		=> $ahr->{fudge},

	# This is a convenience variable which the user should never
	# write to but may read.  It's faster than "scalar(keys %myhash)"
	# (or at least it should be, haven't tested this).

	num_keys	=> 0,

    };
    bless $self, $class;

    if ($ahr->{sub_hash}) {
	$self->{h} = $ahr->{sub_hash};
	$self->{num_keys} = undef;
	if ($DEBUG) {
	    my $info = "num_keys=(not_yet_defined)";
	    my $href = ref $self->{h};
	    $info .= " ref=$href" if $href;
	    my $tied = tied %{$self->{h}};
	    if ($tied) {
		my $tref = ref $tied;
		$info .= " ref(tied())=$tref" if $tref;
	    }
	    print STDERR scalar(localtime) . " using reference to existing hash: $info\n";
	}
	$self->cache_rebuild();
    }

    $self;
}


sub FETCH {
    if ($DEBUG > 2) {
	my $value = (defined($_[0]->{h}{$_[1]}) ? $_[0]->{h}{$_[1]} : '(undef)');
	print STDERR scalar(localtime) . " FETCH key=$_[1] value=$value\n";
    }
    # FETCH is one function that must be very fast, so we
    # streamline it by not even using any variables.
    $_[0]->{h}{$_[1]};
}

sub STORE {
    my($self, $key, $value) = @_;

    return if defined($self->{h}{$key}) and $self->{h}{$key} eq $value;

    print STDERR scalar(localtime) . " STORE BEGIN key=$key value=$value oldvalue=" . ((defined($self->{h}{$key}) ? $self->{h}{$key} : '(undef)')) . " num_keys=$self->{num_keys}\n" if $DEBUG > 2;

    if (defined($self->{h}{$key})) {

	# There already exists a different value for this key.  Remove
	# it so we can store the new value.

	$self->DELETE($key);

	print STDERR scalar(localtime) . " STORE1 key=$key deletedvalue=" . ((defined($self->{h}{$key}) ? $self->{h}{$key} : '(undef)')) . "\n" if $DEBUG > 2;

    }

    $self->{h}{$key} = $value;
    $self->{num_keys}++;

    # Should we insert this value into the cache?  Only if it's less than
    # the current cache_top, or if the size of the entire hash is less
    # than the maximum cache size.

    my $cr = $self->{cache};
    my $cache_top = $self->get_cache_top();
    my $max = $self->cache_value('max');
    print STDERR scalar(localtime) . " STORE2 key=$key value=$value cache_top=$cache_top cr=$#$cr max=$max cmp()=" . ($self->cmp($value, $cache_top)) . "\n" if $DEBUG > 2;
    if ($self->{num_keys} <= $max
	or !defined($cache_top)
	or $self->cmp($value, $cache_top) <= 0) { # shouldn't matter whether this is "<0" or "<=0"
	$self->cache_insert($key, $value);
    }
    print STDERR scalar(localtime) . " STORE3 key=$key cache_top=$cache_top cr=$#$cr\n" if $DEBUG > 2;
    if ($DEBUG and int(rand(200)) == 0) {
	$self->cache_sort_check("inserted $key $value");
    }

    print STDERR scalar(localtime) . " STORE END key=$key value=$value cache_top=" . (defined($cache_top) ? $cache_top : '(undef)') . " cr=$#$cr max=$max num_keys=$self->{num_keys}\n" if $DEBUG > 2;
}

sub DELETE {
    my($self, $key) = @_;
    return unless exists($self->{h}{$key});
    my $value = $self->{h}{$key};

    my $cache_top = $self->get_cache_top();
    print STDERR scalar(localtime) . " DELETE BEGIN key=$key value=$value cr=$#{$self->{cache}} cache_top=$cache_top\n" if $DEBUG > 2;
    if (!defined($cache_top) or $self->cmp($value, $cache_top) <= 0) {
	print STDERR scalar(localtime) . " DELETE key=$key before cache_remove cr=$#{$self->{cache}}\n" if $DEBUG > 2;
	$self->cache_remove($key, $value);
	print STDERR scalar(localtime) . " DELETE key=$key  after cache_remove cr=$#{$self->{cache}}\n" if $DEBUG > 2;
    }

    delete $self->{h}{$key};
    $self->{num_keys}--;

    if ($DEBUG and int(rand(200)) == 0) {
	$self->cache_sort_check("deleted $key $value $#{$self->{cache}}");
    }
    if ($self->cache_too_small()) {
	$self->cache_rebuild();
	$self->cache_sort_check("deleted $key $value $#{$self->{cache}} and rebuilt") if $DEBUG;
    }

    if ($DEBUG > 2) {
	my $cache_top = $self->get_cache_top() || '(none)';
	print STDERR scalar(localtime) . " DELETE END"
	    . " key=$key value=$value"
	    . " cr=$#{$self->{cache}} cache_top=$cache_top\n";
    }
}

sub FIRSTKEY {
    my($self) = @_;
    scalar keys %{$self->{h}};
    my @kv = $self->NEXTKEY;
    return undef if !@kv;
    return (wantarray ? @kv : $kv[0]) if @kv;
}

sub NEXTKEY {
    my($self) = @_;
    my @kv = each %{$self->{h}};
    return undef if !@kv;
    return (wantarray ? @kv : $kv[0]) if @kv;
}

sub EXISTS {
    my($self, $key) = @_;
    return 1 if $key and exists($self->{h}{$key});
}

# CLEAR gets called when someone wants to erase all our data.  This
# is a pretty powerful command.

sub CLEAR {
    my($self) = @_;
    %{$self->{h}} = ( );
    $self->{cache} = [ ];
    $self->{num_keys} = 0;
    $self->cache_rebuild(); # not necessary but doesn't hurt
}

############################################################################
# Internal-use-only methods.
############################################################################

sub cmp {
    my $self = shift @_;
    local($Tie::Cache::a, $Tie::Cache::b);
    if ($self->{sort_rev}) {
	($Tie::Cache::b, $Tie::Cache::a) = @_;
    } else {
	($Tie::Cache::a, $Tie::Cache::b) = @_;
    }
    my $retval = 0;
    my $sf = $self->{sort_func};
    my $ref_sf = ref $sf;

    # Always sort undef to the beginning.  (Maybe there should be an
    # option to switch this to the end?)
    if (!defined($Tie::Cache::a)) {
	if (!defined($Tie::Cache::b)) {
	    $retval = 0;
	} else {
	    $retval = -1;
	}
    } elsif (!defined($Tie::Cache::b)) {
	$retval = 1;
    } else {

	if (!defined($sf) or ($ref_sf and $ref_sf ne 'CODE')) {
	    $retval = ($Tie::Cache::a cmp $Tie::Cache::b);
	} else {
	    if ($ref_sf) {
		$retval = &$sf;
	    } elsif (not ref $sf) {
		SWITCH: {
		    $retval = ($Tie::Cache::a <=> $Tie::Cache::b), last SWITCH	if $sf eq '<=>';
		    # Insert additional defined sort_func strings here.
		    $retval = ($Tie::Cache::a cmp $Tie::Cache::b);
		}
	    } else {
		$retval = ($Tie::Cache::a cmp $Tie::Cache::b);
	    }
	}

    }

    $retval;
}

sub get_cache_top {
    my($self) = @_;
    my $cr = $self->{cache};
    return undef if $#$cr < 0;
    $self->{h}{$cr->[$#$cr]};
}

sub cache_pos {
    my($self, $key, $value) = @_;

    my $cr = $self->{cache};
    my($min, $max) = (0, $#$cr+1);
    MINMAX: while ($min <= $max) {
	last MINMAX if $min > $#$cr; # Here, ">" seems to work where ">=" does not.
	my $mid = int(($min+$max)/2);
	my $mid_key = $cr->[$mid];
	my $mid_value = $self->{h}{$mid_key};
	my $cmp = $self->cmp($value, $mid_value);
	if (!$cmp) {
	    $cmp = ($key cmp $mid_key);
	}

	if ($cmp < 0) {
	    $max = $mid-1; # Is this wrong, should it be just "$max=$mid"?
	} elsif ($cmp > 0) {
	    $min = $mid+1;
	} else {
	    $min = $mid, last MINMAX; # same key, same value
	}
    }

    # If there is a run of two or more keys in the cache with the same
    # value, we may have binary-jumped right into the middle.
    # Deciding arbitrarily whether to go up or down one key doesn't
    # necessarily get us to exactly the right place.  We have to scan
    # backward or forward until either the value changes or our key
    # "fits."  (Actually, I'm not sure this section is necessary.
    # Now that we're properly doing a bi-level, well-defined sort,
    # there should be no need for such scanning.)

    if ($DEBUG > 2) {
        my $keyleft = ($min ? ($cr->[$min-1] || '') : '');
	my $valleft = ($keyleft ? $self->{h}{$keyleft} : '');
        my $keymin = $cr->[$min] || '';
	my $valmin = ($keymin ? $self->{h}{$keymin} : '');
        my $keyright = $cr->[$min+1] || '';
	my $valright = ($keyright ? $self->{h}{$keyright} : '');
	print STDERR scalar(localtime) . " cache_pos BEGIN key=$key value=$value initial_cache_pos=$min: ($keyleft/$valleft) ($keymin/$valmin) ($keyright/$valright)\n";
    }

    if ($min > 0 and $min < $#$cr
	and $self->cmp( $value, $self->{h}{$cr->[$min]} ) == 0) {

	while ($min > 0
	    and $self->cmp( $value, $self->{h}{$cr->[$min-1]} ) == 0
	    and $cr->[$min-1] ge $key) {
	    print STDERR scalar(localtime) . " cache_pos key=$key have to decrement min: $min ($cr->[$min-1] >= $key) ($value) (was $cr->[$min]/$self->{h}{$cr->[$min]})\n";
	    --$min;
	}
	while ($min < $#$cr
	    and $self->cmp( $value, $self->{h}{$cr->[$min+1]} ) == 0
	    and $key ge $cr->[$min+1]) {
	    print STDERR scalar(localtime) . " cache_pos key=$key have to increment min: $min ($key >= $cr->[$min+1]) ($value) (was $cr->[$min]/$self->{h}{$cr->[$min]})\n";
	    ++$min;
	}

    }

    if ($DEBUG) {

        # Let's do some sanity checking.

	# Here, min is the location where the value goes.
	if ($min < 0 or $min > $#$cr + 1 or $min != int($min)) {
	    warn "logic err 0 invalid value for min '$min' '$#$cr'";
	}
	if ($#$cr == -1) {
	    # Empty cache array.
	    if ($min != 0) {
		warn "logic err 1 only one place to go '$min' '$value'";
	    }
	} elsif ($#$cr == 0) {
	    # One item in the cache array, we're either before it or after it.
	    if (     $min == 0 and $self->cmp($value, $self->{h}{$cr->[0]}) > 0) {
		warn "logic err 2 should be before single item '$min' '$value' '$self->{h}{$cr->[0]}'";
	    } elsif ($min == 1 and $self->cmp($self->{h}{$cr->[0]}, $value) > 0) {
		warn "logic err 3 should be after single item '$min' '$value' '$self->{h}{$cr->[0]}'";
	    } elsif ($min < 0 or $min > 1) {
		warn "logic err 4 bogus min '$min' '$value' '$self->{h}{$cr->[0]}'";
	    }
	} else {
	    if (     $min == 0       and $self->cmp($value, $self->{h}{$cr->[0]}) > 0) {
		warn "logic err 5 wrongly at beginning '$value' '$self->{h}{$cr->[0]})'";
	    } elsif ($min == $#$cr+1 and $self->cmp($self->{h}{$cr->[$#$cr]}, $value) > 0) {
		warn "logic err 6 wrongly at end '$value' '$self->{h}{$cr->[$#$cr]})'";
	    } elsif ($min > 0 and $min <= $#$cr) {
		if ($self->cmp($self->{h}{$cr->[$min-1]}, $value) > 0) {
		    warn "logic err 7 preceding entry larger $min $#$cr $value '"
			. join(' ', map { $self->{h}{$cr->[$_]} } ( $min-2 .. $min+2 ) )
			. "'";
		}
		if ($self->cmp($value, $self->{h}{$cr->[$min]}) > 0) {
		    warn "logic err 8 succeeding entry smaller '$value' '$self->{h}{$cr->[$min]}'";
		}
	    }
	}

    }

    print STDERR scalar(localtime) . " cache_pos END key=$key value=$value cache_pos=$min\n" if $DEBUG > 2;

    $min;
}

sub cache_insert {
    my($self, $key, $value) = @_;
    my $cr = $self->{cache};
print STDERR scalar(localtime) . " cache_insert key=$key value=$value \$\#\$cr=$#$cr\n" if $DEBUG > 2;
    my $cache_pos = $self->cache_pos($key, $value);
print STDERR scalar(localtime) . " cache_insert key=$key cache_pos=$cache_pos\n" if $DEBUG > 2;
    my @replacement_keys = ($key, @$cr[$cache_pos..$#$cr]);
print STDERR scalar(localtime) . " cache_insert key=$key \$\#replacement_keys=$#replacement_keys\n" if $DEBUG > 2;
    splice(@$cr,				# array
	$cache_pos,				# offset
	$#$cr - $cache_pos + 1,			# length
	@replacement_keys
    );
print STDERR scalar(localtime) . " cache_insert key=$key \$\#\$cr=$#$cr\n" if $DEBUG > 2;
    if ($self->cache_too_large()) {
print STDERR scalar(localtime) . " cache_insert key=$key cache_too_large\n" if $DEBUG > 2;
	# Pop the last item.
	$#$cr--;
    }
print STDERR scalar(localtime) . " cache_insert key=$key done\n" if $DEBUG > 2;
}

sub cache_remove {
    my($self, $key, $value) = @_;
    my $cr = $self->{cache};
    my $cache_pos = $self->cache_pos($key, $value);

    # We don't know whether the cache position returned is of the
    # actual key we're looking for, or of where it would go if it
    # weren't (incorrectly) missing from the cache.

    if ($cache_pos <= $#$cr and $cr->[$cache_pos] eq $key) {
	splice(@$cr,				# array
	    $cache_pos,				# offset
	    1					# length
	);					# replacement (none)
    }
}

sub cache_value {
    my($self, $field) = @_;
    my $value = $self->{$field};
    my $round = 0.5;
    $round = 0 if $field eq 'min';
    if ($value =~ /^(\d+(?:\.\d*)?|\.\d+)\%$/) {
	$value = int($self->{num_keys} * $1 + $round)
    }
    $value;
}

sub cache_too_small {
    # The cache is too small and MUST be rebuilt if it is both
    # smaller than the min variable and smaller than the
    # size of the entire hash.
    my($self) = @_;
    my $cr = $self->{cache};
    my $min = $self->cache_value('min');
    $#$cr+1 < $min and $#$cr+1 < $self->{num_keys};
}

sub cache_may_rebuild {
    # The cache is small enough and MAY be rebuilt if it is both
    # smaller than the (min+min_margin) variable and smaller than the
    # size of the entire hash.
    my($self) = @_;
    my $cr = $self->{cache};
    my $min = $self->cache_value('min');
    my $min_margin = $self->cache_value('min_margin');
    my $small_enuf = $min + $min_margin;
    my $max = $self->cache_value('max');
    $small_enuf = $max - 1 if $small_enuf > $max - 1;
    $#$cr <= $small_enuf and $#$cr+1 < $self->{num_keys};
}

sub cache_may_accept {
    # The cache is large enough and MAY be accepted if it is
    # larger than the (max-max_margin) variable or equal to the
    # size of the entire hash.
    my($self) = @_;
    my $cr = $self->{cache};
    my $max = $self->cache_value('max');
    my $max_margin = $self->cache_value('max_margin');
    my $large_enuf = $max - $max_margin;
    my $min = $self->cache_value('min');
    $large_enuf = $min + 1 if $large_enuf < $min + 1;
    $#$cr >= $large_enuf or $#$cr+1 == $self->{num_keys};
}

sub cache_too_large {
    # The cache is too large and MUST be shrunk if it is
    # larger than the max variable.
    my($self) = @_;
    my $cr = $self->{cache};
    my $max = $self->cache_value('max');
    $#$cr >= $max;
}

sub cache_rebuild {
    my($self) = @_;
    my($start_time, $elapsed_time);
    my $cr = $self->{cache};
    if ($DEBUG > 1) {
	$start_time = time;
    }

    my @scanned = ( );
    my @unscanned = keys %{$self->{h}}; # This can take a while but there's no way around it.
    if (!defined($self->{num_keys})) {
	$self->{num_keys} = $#unscanned+1;
    }

    if ($DEBUG > 1) {
	my @sort_unscanned = sort @unscanned;
	my @sort_unscanned_print;
	if ($#sort_unscanned > 10) {
	    @sort_unscanned_print = (@sort_unscanned[0..3], '...', @sort_unscanned[-4..-1]);
	} else {
	    @sort_unscanned_print = @sort_unscanned;
	}
	print STDERR scalar(localtime) . " cache_rebuild"
	    . " $#sort_unscanned: @sort_unscanned_print\n";
    }

    my $do_it_the_stupid_way = 0;
    my $max = $self->cache_value('max');

    if ($self->{num_keys} <= $max*(1+$self->{fudge})) {

	$do_it_the_stupid_way = 1;

    } else {

	# Do Monte Carlo sampling in order to sort as little as possible.

	my $key;
	$self->{scan_min} = 10 if !$self->{scan_min} or $self->{scan_min} < 10; # sanity check
	my $desired_fraction = ($max/$self->{num_keys}) * (1+$self->{fudge});
	my $max_num_to_scan = int($self->{num_keys}/2);
	my $num_to_scan = $self->{scan_min}; # If too large, will be reduced below.

	# Repeat the following attempts until Monte fails us and we
	# must finally give up.

	my $n_failures = 0;
	my $success = 0;
	while (!$success and !$do_it_the_stupid_way) {

	    print STDERR scalar(localtime) . " MONTE1"
		. " num_to_scan=$num_to_scan frac=$desired_fraction"
		. " \$\#scanned=$#scanned \$\#unscanned=$#unscanned"
		. " num_keys=$self->{num_keys} \$\#\$cr=$#$cr\n" if $DEBUG > 1;

	    # Gather a pseudorandom (thanks to the hashing algorithm)
	    # sampling of keys.
	    $num_to_scan = $max_num_to_scan - ($#scanned+1)
		if $num_to_scan >= $max_num_to_scan - $#scanned;
	    $num_to_scan = $#unscanned+1
		if $num_to_scan > $#unscanned+1;
	    if ($num_to_scan) {
		my $start_scanned = $#scanned;
		print STDERR scalar(localtime) . " MONTE1a"
		    . " start_scanned=$start_scanned"
		    . " num_to_scan=$num_to_scan\n" if $DEBUG > 1;
		# To make it even more random, try taking a random section out of
		# the source array.  It shouldn't matter unless the hash
		# algorithm is pathological, but who knows, someday it might
		# do some good.
		my $unscanned_start = 0;
		if ($#unscanned >= $num_to_scan) {
		    $unscanned_start = int(rand($#unscanned-$num_to_scan+1)); # could be +2
		}
		splice(@scanned, $#scanned+1, 0,
		    splice(@unscanned, $unscanned_start, $num_to_scan)
		);
		$num_to_scan = 0;
		print STDERR scalar(localtime) . " MONTE2"
		    . " unscanned_start=$unscanned_start num_to_scan=$num_to_scan"
		    . " \$\#scanned=$#scanned \$\#unscanned=$#unscanned\n" if $DEBUG > 1;
	    }

	    # Make a guess at the "max value" we should accumulate into our
	    # soon-to-be-cache.
	    # BUG: This sorted array need not be rebuilt if %monte has not
	    # changed since the last time through this loop.
	    my @sorted_scanned = sort {
		$self->cmp( $self->{h}{$a}, $self->{h}{$b} )
			||
		$a cmp $b
	    } @scanned;

	    if ($#sorted_scanned >= 0) {

		my $guess_max_key_index = int( $#sorted_scanned * $desired_fraction + 0.5 );
		$guess_max_key_index += $n_failures;
		$guess_max_key_index = 1 if $guess_max_key_index == 0; # never use the lowest scanned
		$guess_max_key_index = $#sorted_scanned
		    if $guess_max_key_index > $#sorted_scanned;
		my $guess_max_key = $sorted_scanned[$guess_max_key_index];
		my $guess_max_value = $self->{h}{$guess_max_key};
		# BUG: if this isn't our first time through this loop,
		# make sure we're not using the exact same key value as
		# we used last time - if so, scan $guess_max_key_index up
		# thru the list until we get to the next largest value.

		print STDERR scalar(localtime) . " MONTE3"
		    . " guess_max_key_index=$guess_max_key_index"
		    . " guess_max_key=$guess_max_key"
		    . " guess_value=$guess_max_value\n" if $DEBUG > 1;

		# Accumulate any duples less than that max value into our cache.
		@$cr = ( );
		for $key (@scanned) {
		    push @$cr, $key if $self->cmp( $self->{h}{$key}, $guess_max_value ) <= 0;
		}
		for $key (@unscanned) {
		    push @$cr, $key if $self->cmp( $self->{h}{$key}, $guess_max_value ) <= 0;
		}

		print STDERR scalar(localtime) . " MONTE4 \$\#\$cr=$#$cr\n" if $DEBUG > 1;

		if ($self->cache_may_accept()) {

		    # Hey, it worked, we have enough data.  Sort it, trim it, and
		    # we're done.
		    print STDERR scalar(localtime) . " MONTE5 sorting"
			. " array size \$\#\$cr=$#$cr"
			. " (max=$max):"
			. " @$cr[0..4]\n" if $DEBUG > 1;
		    @$cr = sort {
			$self->cmp( $self->{h}{$a}, $self->{h}{$b} )
				||
			$a cmp $b
		    } @$cr;
		    $#$cr = $max-1 if $#$cr >= $max;
		    $success = 1;
		    print STDERR scalar(localtime) . " MONTE6 SUCCESS"
			. " \$\#\$cr=$#$cr: @$cr[0..4]\n" if $DEBUG > 1;

		}

	    }

	    if (!$success) {

		# Well, that didn't work, either because there were no monte
		# keys or because our guess didn't net us enough cache keys.
		# Either way, we need to try again.  Pull a few more keys into
		# our pseudorandom sampling to try to make it more accurate
		# (though don't go beyond double the original scan_min;  the
		# point of rapidly diminishing returns is below 1000 samples).
		# Then we kick up the fraction by an appropriate amount,
		# at least the fudge factor.  Increasing the fraction is
		# the thing that will really get us more data next time.
		# Then repeat.

		my $fraction_multiplier = $max/($#$cr+2);
		$fraction_multiplier = 2 if $fraction_multiplier > 2;
		$fraction_multiplier = 1+$self->{fudge} if $fraction_multiplier < 1+$self->{fudge};
		$desired_fraction *= $fraction_multiplier;
		if ($desired_fraction > 0.8) {
		    # Screw it.  Just scan the whole hash.
		    $do_it_the_stupid_way = 1;
		}
		if ($#scanned < $self->{scan_min}*1.9) {
		    $num_to_scan = int($self->{scan_min}/2);
		}
	        print STDERR scalar(localtime) . " MONTE7 failure"
		    . " frac_mul=$fraction_multiplier"
		    . " frac=$desired_fraction"
		    . " num_to_scan=$num_to_scan"
		    . " stupid=$do_it_the_stupid_way\n" if $DEBUG > 1;

	    }
	    
	}

    }

    if ($do_it_the_stupid_way) {

	# This would be the stupid way of doing it.  The point of this module
	# is not to do it the stupid way when the number of keys in the hash
	# gets large.  Looks like we suck!  Oh well!

	@$cr = sort {
	    $self->cmp( $self->{h}{$a}, $self->{h}{$b} )
		    ||
	    $a cmp $b
	} @unscanned;
	if ($#$cr >= $max) {
	   $#$cr = $max-1;
	}

    }

    if ($DEBUG > 1) {
	$elapsed_time = time - $start_time;
    }
    if ($DEBUG) {
	$self->cache_sort_check();
    }
    if ($DEBUG > 1) {
	my $total_elapsed_time = time - $start_time;
	my $n_cache_keys = $#$cr + 1;
	my $n_hash_keys = scalar(keys %{$self->{h}});
	print STDERR scalar(localtime) . " rebuilt cache ($n_cache_keys/$n_hash_keys keys) in $elapsed_time seconds (counting the check, $total_elapsed_time seconds)\n";
    }
}

sub cache_sort_check {
    my($self, $info) = @_;
    return unless $DEBUG;
    $info = '' if !$info;
    my $error = 0;
    my $cr = $self->{cache};
    if ($#$cr > 0) {
	my $lastval = $self->{h}{$cr->[0]};
	my $i;
	for $i (1..$#$cr) {
	    my $newval = $self->{h}{$cr->[$i]};
	    if (!defined($newval) or !defined($lastval) or $self->cmp($newval, $lastval) < 0) {
		$newval = '(undef)' if !defined($newval);
		$lastval = '(undef)' if !defined($lastval);
		$error = "\nnewval ($newval) < lastval ($lastval) at pos $i/$#$cr: $info\n";
		last;
	    }
	    $lastval = $newval;
	}
    }
    if ($#$cr >= 0 and !$error) {
	my %cache = map { $_ => 1 } @$cr;
	my $key;
	my $pivot_value = $self->{h}{$cr->[$#$cr]};
	for $key (keys %{$self->{h}}) {
	    if ($cache{$key}) {
		# It's in the cache so its value should be small.
		if ($self->cmp( $self->{h}{$key}, $pivot_value ) > 0) {
		    $error = "\nkey=$key value=$self->{h}{$key} in cache but"
			. " larger than $cr->[$#$cr]: $info\n";
		    last;
		}
	    } else {
		# It's not in the cache so its value should be large.
		if ($self->cmp( $self->{h}{$key}, $pivot_value ) < 0) {
		    $error = "\nkey=$key value=$self->{h}{$key} not in cache but"
			. " smaller than key=$cr->[$#$cr] value=$pivot_value: $info\n";
		    last;
		}
	    }
	}
    }
    if ($error) {
	my $j;
	for $j (0..$#$cr) {
	    my $key = defined($cr->[$j]) ? $cr->[$j] : '';
	    my $val = ''; $val = defined($self->{h}{$key}) ? $self->{h}{$key} : '' if $key;
	    print STDERR "cache \#$j\t$key\t$val\n";
	}
	croak $error;
    }
}

############################################################################
# Wrap-up
############################################################################

# Make sure the module returns true.
1;

__DATA__

=head1 NAME

Tie::CacheHash - Maintains sorted lists of top entries

=head1 SYNOPSIS

    use Tie::CacheHash;
    tie %hash1, 'Tie::CacheHash', 10, 100;
    tie %hash2, 'Tie::CacheHash', '5%', '10%';

=head1 DESCRIPTION

Of course you can get the "top 100" entries of any perl hash:

    @top_keys = (sort my_sort_func keys %my_hash)[0..99];

But if your hash has more than a few thousand entries, that sort operation
may take several seconds.  And if you have tens of thousands of entries,
the sort may take many minutes.

(If you are reading this documentation past the expiration date on the
bottom of the carton, please adjust the numbers accordingly.  Sorting is
always problematic for sufficiently large n.)

Many programs will need to keep track of a "top 100" (or "bottom 100")
to perform such operations as expiring the oldest items out of a cache.
Sorting the entire array and skimming off the top items is not
always an acceptable algorithm.  Tie::CacheHash provides a simple and
reasonably efficient solution.  Its primary design goal is reasonable
responsiveness on every operation, i.e. no unpredictable long delays,
and it achieves this goal by avoiding the sorting of huge arrays.

The two parameters you pass after the classname are the minimum and
maximum allowable size for the cache.  The largest array the module will
ever have to sort will be somewhat above the maximum (how much depends
on the distribution of your data), so picking a good 'max' will help
control the maximum delay you will experience.  

A 'min' of 0 means it is OK for the cache to run dry and never
replenish itself (###I think###), so you probably want a minimum of at
least 1.  A minimum/maximum of a very large integer (try 2**30) means
to keep the whole hash in the cache.

Duplicate values are allowed;  if you don't specify your own sort
function, they will be secondarily sorted by key.

If you pass in a subhash, you MUST NOT alter its data directly:  only
through the CacheHash.

=head1 BUGS

There should be a way to store or delete large amounts of data at once,
without cache overhead between each entry.  For now, it should work
to munge the {h} array directly and then call cache_rebuild, but that's
an ugly workaround.

There should be a way to set cache_pos's secondary (key) sort function,
instead of forcing "cmp".  (This would mean a tertiary sort to ensure
predictable sort order in case the user screws up and returns 0 for
nonequal keys.)

Not sure yet whether the undefined value is handled properly in all cases.
Should be tested with a subhash of a type known to choke and die horribly
on undef (ideally, Tie::CacheHash would not provoke such behavior).

The percent-style min/max arguments don't work yet (but they're an
awfully cool idea aren't they?).

Because it's not a full 1.0 release yet, "make test" still does a
tremendous amount of randomized stress testing.  This takes longer
than it really should (typically 15-30 seconds, sometimes more).
When it gets closer to release, this will be backed-off.

The Monte Carlo algorithm has a number of places where its performance
could be further optimized.  In some cases the impact is significant.
These are marked in the code as "BUG".

The cmp() method probably has room for performance improvement if we
make the very fair assumption that sort_func and sort_rev will not
change during a sort!

The different DEBUG levels are neither well-thought-out nor documented.

Haven't tested setting cache minimum to 0.

Haven't tested setting cache maximum to 2**30.

=head1 AUTHOR

Jamie McCarthy E<lt>jamie@mccarthy.orgE<gt>.

=cut
