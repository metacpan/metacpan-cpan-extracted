package Tie::AliasHash;

use strict;

use vars qw( @ISA @EXPORT_OK $VERSION );

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( allkeys );

$VERSION = '1.02';

#### constants

sub _HASH          () { 0 }
sub _ALIAS         () { 1 }
sub _ALIAS_REV     () { 2 }
sub _ALIAS_REV_IDX () { 3 }
sub _JOLLY         () { 4 }

#### data structure is:
#### $self = [
####     _HASH (the real hash)
####         realkey => value
####     _ALIAS (the aliases (forward lookup))
####         alias => realkey
####     _ALIAS_REV (the aliases (reverse lookup))
####         realkey => [alias1, alias2, aliasN]
####     _ALIAS_REV_IDX (the alias indices in _ALIAS_REV)
####         alias1 => 0
####         alias2 => 1
####         aliasN => N
####     _JOLLY (where unknown keys will be sent)
#### ]

#### tie stuff

sub TIEHASH {
	my($class, @aliases) = @_;
	my $self = bless [ {}, {}, {}, {}, undef ], $class;
	my($key, $alias);
	foreach $alias ( @aliases ) {
		if(ref($alias) eq "ARRAY") {
			$self->add_alias( @$alias );
		} else {
			if($^W) {
				warn( "Tie::AliasHash: argument '$alias' to hash is not an ARRAY ref!" );
			}
		}
	}
	return $self;
}

sub FETCH {
	my($self, $key) = @_;
	$key = $self->realkey($key) if $self->is_alias($key);
	$key = $self->[_JOLLY] 
		if not $self->is_key($key) 
		   and defined $self->[_JOLLY];
	return $self->[_HASH]->{$key};
}

sub STORE ($\@$) {
	my($self, $key, $value) = @_;
	my @keys;	
	if( ref($key) eq "ARRAY" ) {
		@keys = @$key;
	} else {
		@keys = split( $;, $key);
	}
	$key = $keys[0] if scalar(@keys) > 1;
	$key = $self->realkey($key) if $self->is_alias($key); 
	$key = $self->[_JOLLY] if not $self->is_key($key) and defined $self->[_JOLLY];
	$self->[_HASH]->{$key} = $value;
	if(@keys > 1) {
		$self->add_alias( @keys );
	}
}

sub FIRSTKEY {
	my($self) = @_;
	my @init = keys %{ $self->[_HASH] };
    my ($k, $v) = each %{ $self->[_HASH] };
	return $k;
}

sub NEXTKEY {
	my($self) = @_;
    my ($k, $v) = each %{ $self->[_HASH] };
	return $k;
}

sub EXISTS {
	my($self, $key) = @_;
	return ( $self->is_key($key)
	or       $self->is_alias($key) );
}

sub DELETE {
	my($self, $key) = @_;
	$key = $self->realkey($key) if $self->is_alias($key);
	$self->remove_aliases( $key );
	delete ${ $self->[_HASH] }{$key}
	if exists $self->[_HASH]->{$key};
}	

sub CLEAR { 
	my($self) = @_;
	$self->[_HASH] = {};
	$self->[_ALIAS] = {};
	$self->[_ALIAS_REV] = {};
	$self->[_ALIAS_REV_IDX] = {};
	$self->[_JOLLY] = undef;
}

#### methods

sub add_alias {
	my $self = shift;
	my $key = shift;
	$key = $self->realkey($key) if $self->is_alias($key);
	my $alias;	
	while(defined( $alias = shift )) {
		$self->[_ALIAS]->{$alias} = $key;
		if(exists ${ $self->[_ALIAS_REV] }{$key}) {
			push( @{ $self->[_ALIAS_REV]->{$key} }, $alias );
			$self->[_ALIAS_REV_IDX]->{$alias} = $#{ $self->[_ALIAS_REV]->{$key} };
		} else {
			$self->[_ALIAS_REV]->{$key} = [ $alias ];
			$self->[_ALIAS_REV_IDX]->{$alias} = 0;
		}
	}
}

sub remove_alias {
	my($self, $alias) = @_;
	my $key = $self->realkey( $alias );
	delete ${ $self->[_ALIAS] }{$alias};
	splice( 
		@{ $self->[_ALIAS_REV]->{$key} }, 
		$self->[_ALIAS_REV_IDX]->{$alias}, 
		1 
	);
	delete ${ $self->[_ALIAS_REV_IDX] }{$alias};
}

sub remove_aliases {
	my($self, $key) = @_;
	my $alias;
	foreach $alias ( @{ $self->[_ALIAS_REV]->{$key} } ) {
		delete ${ $self->[_ALIAS] }{$alias};
		delete ${ $self->[_ALIAS_REV_IDX] }{$alias};
	}
	delete ${ $self->[_ALIAS_REV] }{$key};
}

sub aliases {
	my($self, $key) = @_;
	return @{ $self->[_ALIAS_REV]->{$key} };
}	

sub remove {
	my($self, @keys) = @_;
	foreach my $key (@keys) {
		if( $self->is_alias( $key ) ) {
			$self->remove_alias( $key );
		} elsif( $self->is_key( $key ) ) {
			$self->remove_aliases( $key );
			delete ${ $self->[_HASH] }{$key};
		}
	}
}

sub allkeys(\%) {
	my $self = shift;
	$self = tied %{ $self } if ref $self eq "HASH";
	return (keys %{$self->[_HASH]}), (keys %{$self->[_ALIAS]});
}

sub realkey {
	my($self, $key) = @_;
	if($self->is_alias($key)) {
		return $self->[_ALIAS]->{$key};
	} elsif($self->is_key($key)) {
		return $key;
	} else {
		return undef;
	}
}

sub is_alias {
	my($self, $key) = @_;
	return exists ${ $self->[_ALIAS] }{$key};
}

sub is_key {
	my($self, $key) = @_;
	return exists ${ $self->[_HASH] }{$key};
}

sub set_jolly {
	my($self, $key) = @_;
	$self->[_JOLLY] = $key;
}

sub remove_jolly {
	my($self) = @_;
	$self->[_JOLLY] = undef;
}

1;

__END__

=head1 NAME

Tie::AliasHash - Hash with aliases key (multiple keys, one value)

=head1 SYNOPSIS

  use Tie::AliasHash;

  tie %hash, 'Tie::AliasHash';
	
  $hash{ 'foo', 'bar' } = 'baz';
	
  print $hash{foo}; # prints 'baz'
  print $hash{bar}; # prints 'baz' too

  $hash{bar} = 'zab'; # $hash{foo} is changed too
  print $hash{foo}; # prints 'zab'


=head1 DESCRIPTION

B<Tie::AliasHash> creates hashes that can have multiple keys for a single
value. This means that some keys are just 'aliases' for other keys.

The example shown in the synopsys above creates a key 'foo' and an 
alias key 'bar'. The two keys share the same value, so that fetching 
either of them will always return the same value, and storing a value in
one of them will change both.

The only difference between the two keys is that 'bar' is not reported
by keys() and each():

  use Tie::AliasHash;
  tie %hash, 'Tie::AliasHash';
  tied(%hash)->add_alias( 'foo', 'bar' );
  foreach $k (keys %hash) { print "$k\n"; } # prints 'foo'

To get the 'real' keys and the aliases together, use the C<allkeys>
function:

  use Tie::AliasHash;
  tie %hash, 'Tie::AliasHash';
  tied(%hash)->add_alias( 'foo', 'bar' );
  foreach $k (tied(%hash)->allkeys) { print "$k\n"; } # prints 'foo' and 'bar'

You can create alias keys with 3 methods:

=over 4

=item *
pre-declaring them while tieing the hash

The 'tie' constructor accepts an optional list of key names and aliases.
The synopsis is:

  tie %HASH, 'Tie::AliasHash', 
    KEY => ALIAS,
    KEY => [ALIAS, ALIAS, ALIAS, ...],
    ...

=item *
explicitly with the add_alias method

  tied(%hash)->add_alias( KEY, ALIAS );
  tied(%hash)->add_alias( KEY, ALIAS, ALIAS, ALIAS, ... );

=item *
implicitly with a multiple-key hash assignement

  $hash{ KEY, ALIAS } = VALUE;
  $hash{ KEY, ALIAS, ALIAS, ALIAS, ... } = VALUE;

The list of keys and aliases can be either an array reference, eg.:

  $hash{ [ 'foo', 'bar', 'baz' ] } = $value;
  $hash{ \@foobarbaz } = $value;

or an explicit list, eg.:

  $hash{ qw(foo bar baz) } = $value;
  $hash{ @foobarbaz } = $value;

Be warned that, with the last example, Perl uses the C<$;> variable 
(or subscript separator), which defaults to '\034' (ASCII 28). This 
can cause problems if you plan to use keys with arbitrary ASCII
characters. Always use the first form when in doubt. Consult
L<perlvar> for more information.

=back

=head2 EXPORT

None by default. You can optionally export the C<allkeys> function
to your main namespace, so that it can be used like the builtin C<keys>.

  use Tie::AliasHash 'allkeys';
  tie %hash, 'Tie::AliasHash';
  foreach $k (allkeys %hash) { print "$k\n"; }

But see L<CAVEATS> below for important information about C<allkeys>.

=head2 METHODS

=over 4

=item add_alias( KEY, ALIAS, [ALIAS, ALIAS, ...] )

Add one or more ALIAS for KEY. If KEY itself is an alias, the 
aliases are added to the real key which KEY points to.

=item aliases( KEY )

Returns a list of all the aliases defined for KEY. If KEY itself is
an alias, returns the real key pointed by KEY, as well as any other
alias (thus excluding KEY itself) it has.

=item allkeys

Returns all the (real) keys of the hash, as well as all the aliases.

=item is_alias( KEY )

Returns true if the specified KEY is an alias, false otherwise (either
if KEY does not exists in the hash, or it is a real key).

=item is_key( KEY )

Returns true if the specified KEY is a real key, false otherwise (either
if KEY does not exists in the hash, or it is an alias for another key).

=item remove( KEY )

Remove KEY from the hash: if KEY is a real key, it is removed with
all its aliases. If KEY is an alias, B<only the alias is removed>.
This is different from the builtin C<delete>, see L<CAVEATS> below.

=item remove_alias( ALIAS )

Removes the specified ALIAS from its real key. ALIAS is no longer an
alias and can be assigned its own value. The real key which ALIAS
used to point to is left unchanged.

=item remove_aliases( KEY )

Removes all the aliases defined for KEY.

=item remove_jolly( )

Removes the 'jolly' key from the hash. Operations on non-existant keys 
are restored to normality.

=item set_jolly( KEY )

Sets the 'jolly' key to KEY. When you set a jolly key, all fetch and store 
operations on non-existant keys will be done on KEY instead.

=back

=head1 CAVEATS

This module can generate a wonderful amount of confusion if
not used properly. The package should really have a big
'HANDLE WITH CARE' sticker on it. Other than paying special
attention to what you're doing, you should be aware of the
following subtlenesses:

=over 4

=item *
transitivity

Aliases are 'transitive', and always resolve to their aliased
key. This means that if you write:

  use Tie::AliasHash;
  tie %hash, 'Tie::AliasHash';
  tied(%hash)->add_alias( 'foo', 'bar' );
  tied(%hash)->add_alias( 'bar', 'baz' );

C<$hash{baz}> is created as an alias for C<$hash{foo}>, not for 
C<$hash{bar}> (which isn't a real key). This also means that if you
later change C<$hash{bar}> to point to something else, B<you haven't
changed> C<$hash{baz}>:

  tied(%hash)->add_alias( 'gup', 'bar' );
  # $hash{bar} is now really --> $hash{gup}
  # $hash{baz} is still      --> $hash{foo}

=item *
delete

The builtin C<delete> function resolves aliases to real keys, so it
deletes everything even when called on an alias:

  use Tie::AliasHash;
  tie %hash, 'Tie::AliasHash';
  tied(%hash)->add_alias( 'foo', 'bar' );
  
  delete $hash{bar}; # deletes $hash{foo} too!

To delete an alias leaving its key intact, use the C<remove_alias>
method instead:

  use Tie::AliasHash;
  tie %hash, 'Tie::AliasHash';
  tied(%hash)->add_alias( 'foo', 'bar' );
  
  tied(%hash)->remove_alias( 'bar' ); # $hash{foo} remains intact

=item *
exists

The builtin C<exists> function returns true on aliases too:

  use Tie::AliasHash;
  tie %hash, 'Tie::AliasHash';
  tied(%hash)->add_alias( 'foo', 'bar' );
  
  print exists $hash{'foo'}; # TRUE
  print exists $hash{'bar'}; # TRUE

To distinguish between aliases and real keys, use the C<is_key>
method:

  print exists $hash{'foo'} and tied(%hash)->is_key('foo'); # TRUE
  print exists $hash{'bar'} and tied(%hash)->is_key('bar'); # FALSE

=item *
allkeys

If you export C<allkeys> into your main namespace, it can be used
as the builtin C<keys> in the following code:

  use Tie::AliasHash 'allkeys';
  tie %hash, 'Tie::AliasHash';
  foreach $key (allkeys %hash) { print "$key\n"; }

But note that C<allkeys> is always a function call, so this does not 
work as you expect:

  foreach $key (sort allkeys %hash) { print "$key\n"; }

You have to fool C<sort>, or it will use C<allkeys> as its sort routine.
This can be done by providing an explicit sort routine, or forcing the
result of C<allkeys> to be interpreted as an array by 
referencing-dereferencing it, or with a two-step operation where you
first assign C<allkeys> to an array, and then operate on it:

  foreach $key (sort { $a cmp $b } allkeys %hash) { print "$key\n"; }
  foreach $key (sort @{[ allkeys %hash ]}) { print "$key\n"; }

  @allkeys = allkeys %hash;
  foreach $key (sort @allkeys) { print "$key\n"; }

=item *
the 'jolly' key

The most potentially confusing feature of this module is the 'jolly'
key. When you set a value for it, all 'unknown' keys become aliases
for the jolly key. This means that B<you can't create new keys> in
the hash, because if a key does not exists, the value will be 
'redirected' to the jolly key.

We make an example of how this works and for what can be useful.
Suppose you have a table of records with a 'city' field. You want
to count the occurrencies for Rome, Paris and London (possibly
expressed in different languages), and count every other city as 
'Other'. 

  tie %cities, 'Tie::AliasHash';
  
  $cities{['Rome', 'Roma', 'Rom']} = 0;
  $cities{['Paris', 'Parigi']} = 0;
  $cities{['London', 'Londra', 'Londres']} = 0;
  $cities{'Other'} = 0;
  tied(%cities)->set_jolly('Other');

  while($city = get_city()) {
      $cities{$city}++;
  }
  foreach $city (sort keys %cities) {
      print "$city:\t$cities{$city}\n";
  }

A possible output for the above script can be:

  London: 4
  Other:  92
  Paris:  7
  Rome:   16

Also note that the use of the jolly key is limited to fetch and store, 
it does not affect other hash operations, like exists, delete, each,
keys and values.

=back

=head1 HISTORY

=over 4

=item v1.02 (11 Mar 2016)

Moved to github, using Build.PL instead of Makefile.PL, added license.

=item v1.01 (26 Jun 2003)

Fixed a bug in the EXISTS sub, now works as documented (thanks wk)

=item v1.00 (07 Mar 2001)

First released version

=item v0.01 (20 Feb 2001)

Original version; created by h2xs 1.20 with options

  -CAXn Tie::AliasHash

=back

=head1 AUTHOR

Aldo Calpini <dada@perl.it>

=cut
