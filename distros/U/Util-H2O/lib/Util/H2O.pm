#!perl
package Util::H2O;
use warnings;
use strict;
use Exporter 'import';
use Carp;
use Symbol qw/delete_package/;

=head1 Name

Util::H2O - Hash to Object: turns hashrefs into objects with accessors for keys

=head1 Synopsis

 use Util::H2O;
 
 my $hash = h2o { foo => "bar", x => "y" }, qw/ more keys /;
 print $hash->foo, "\n";           # accessor
 $hash->x("z");                    # change value
 $hash->more("cowbell");           # additional keys
 
 my $struct = { hello => { perl => "world!" } };
 h2o -recurse, $struct;            # objectify nested hashrefs as well
 print $struct->hello->perl, "\n";
 
 my $obj = h2o -meth, {            # code references become methods
     what => "beans",
     cool => sub {
         my $self = shift;
         print $self->what, "\n";
     } };
 $obj->cool;                       # prints "beans"
 
 h2o -classify=>'Point', {         # whip up a class
         angle => sub { my $self = shift; atan2($self->y, $self->x) }
     }, qw/ x y /;
 my $one = Point->new(x=>1, y=>2);
 my $two = Point->new(x=>3, y=>4);
 printf "%.3f\n", $two->angle;     # prints 0.927

=cut

our $VERSION = '0.12';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our @EXPORT = qw/ h2o /;  ## no critic (ProhibitAutomaticExportation)

BEGIN {
	# lock_ref_keys wasn't available until Hash::Util 0.06 / Perl v5.8.9
	# (note the following will probably also fail on the Perl v5.9 dev releases)
	# uncoverable branch false
	# uncoverable condition false
	if ( $] ge '5.008009' ) {
		require Hash::Util;
		Hash::Util->import(qw/ lock_ref_keys lock_hashref /) }
	else {
		*lock_ref_keys = *lock_hashref = sub {
			carp "this Perl is too old to lock the hash";  # uncoverable statement
		};  # uncoverable statement
	}
}

=head1 Description

This module allows you to turn hashrefs into objects, so that instead
of C<< $hash->{key} >> you can write C<< $hash->key >>, plus you get
protection from typos. In addition, options are provided that allow
you to whip up really simple classes.

You can still use the hash like a normal hashref as well, as in
C<< $hash->{key} >>, C<keys %$hash>, and so on, but note that by
default this function also locks the hash's keyset to prevent typos
there too.

This module exports a single function by default.

=head2 C<h2o I<@opts>, I<$hashref>, I<@additional_keys>>

=head3 C<@opts>

If you specify an option with a value multiple times, only the last
one will take effect.

=over

=item C<-recurse>

Nested hashes are objectified as well. The only options that are passed down to
nested hashes are C<-lock> and C<-ro>. I<None> of the other options will be
applied to the nested hashes, including C<@additional_keys>. Nested arrayrefs
are not recursed into.

Versions of this module before v0.12 did not pass down the C<-lock> option,
meaning that if you used C<-nolock, -recurse> on those versions, the nested
hashes would still be locked.

=item C<-meth>

Any code references present in the hash at the time of this function
call will be turned into methods. Because these methods are installed
into the object's package, they can't be changed later by modifying
the hash.

To avoid confusion when iterating over the hash, the hash entries
that were turned into methods are removed from the hash. The key is
also removed from the "allowed keys" (see the C<-lock> option),
I<unless> you specify it in C<@additional_keys>. In that case, you
can change the value of that key completely independently of the
method with the same name.

=item C<< -class => I<classname> >>

Specify the class name into which to bless the object (as opposed to
the default: a generated, unique package name in C<Util::H2O::>).

I<Note:> If you use this option, C<-clean> defaults to I<false>,
meaning that the package will stay in Perl's symbol table and use
memory accordingly, and since this function installs the accessors in
the package every time it is called, if you re-use the same package
name, you will get "redefined" warnings. Therefore, if you want to
create multiple objects in the same package, you should probably use
C<-new>.

=item C<< -classify => I<classname> >>

Short form of the options C<< -new, -meth, -class => I<classname> >>.

=item C<-new>

Generates a constructor named C<new> in the package. The constructor
works as a class and instance method, and dies if it is given any
arguments that it doesn't know about. If you want more advanced
features, like required arguments, validation, or other
initialization, you should probably switch to something like L<Moo>
instead.

=item C<< -clean => I<bool> >>

Whether or not to clean up the generated package when the object is
destroyed. Defaults to I<false> when C<-class> is specified, I<true>
otherwise. If this is I<false>, be aware that the packages will stay
in Perl's symbol table and use memory accordingly.

=item C<< -lock => I<bool> >>

Whether or not to use L<Hash::Util>'s C<lock_ref_keys> to prevent
modifications to the hash's keyset. Defaults to I<true>.
The C<-nolock> option is provided as a short form of C<< -lock=>0 >>.

Keysets of objects created by the constructor generated by the
C<-new> option are also locked. Versions of this module before
v0.12 did not lock the keysets of new objects.

Note that on really old Perls, that is, before Perl v5.8.9,
L<Hash::Util> and its C<lock_ref_keys> are not available, so the hash
is never locked on those versions of Perl. Versions of this module
before v0.06 did not lock the keyset.
Versions of this module as of v0.12 issue a warning on old Perls.

=item C<-nolock>

Short form of the option C<< -lock=>0 >>.

=item C<-ro>

Makes the entire hash read-only using L<Hash::Util>'s C<lock_hashref> and the
generated accessors will also throw an error if you try to change values. In
other words, this makes the object and the underlying hash immutable.

You cannot specify any C<@additional_keys> with this option enabled unless you
also use the C<-new> option - the additional keys will then only be useful as
arguments to the constructor. This option can't be used with C<-nolock> or
C<< -lock=>0 >>.

This option was added in v0.12. Using this option will not work and cause a
warning when used on really old Perls (before v5.8.9), because this
functionality was not yet available there.

=back

=head3 C<$hashref>

You must supply a plain (unblessed) hash reference here. Be aware
that this function I<does> modify the original hashref(s) by blessing
it and locking its keyset (the latter can be disabled with the
C<-lock> option), and if you use C<-meth> or C<-classify>, keys whose
values are code references will be removed.

An accessor will be set up for each key in the hash; note that the
keys must of course be valid Perl identifiers for you to be able to
call the method normally.

When C<-clean> is I<true> (the default, unless you use C<-class>),
the hash may not contain a key named C<DESTROY>. When C<-new> is
used, the hash may not contain a key named C<new>.
If the hash contains a key named C<AUTOLOAD>, see L</AUTOLOAD>.

=head3 C<@additional_keys>

Methods will be set up for these keys even if they do not exist in the hash.

=head3 Returns

The (now blessed and optionally locked) C<$hashref>.

=cut

sub h2o {  ## no critic (RequireArgUnpacking, ProhibitExcessComplexity)
	my ($recurse,$meth,$class,$new,$clean,$lock,$ro);
	while ( @_ && $_[0] && !ref$_[0] ) {
		if ($_[0] eq '-recurse' ) { $recurse = shift }  ## no critic (ProhibitCascadingIfElse)
		elsif ($_[0] eq '-meth' ) { $meth    = shift }
		elsif ($_[0] eq '-clean') { $clean   = (shift, shift()?1:0) }
		elsif ($_[0] eq '-lock' ) { $lock    = (shift, shift()?1:0) }
		elsif ($_[0] eq '-nolock'){ $lock = 0; shift }
		elsif ($_[0] eq '-ro'   ) { $ro      = shift }
		elsif ($_[0] eq '-new'  ) { $new     = shift }
		elsif ($_[0] eq '-class') {
			$class = (shift, shift);
			croak "invalid -class option value"
				if !defined $class || ref $class || !length $class;
		}
		elsif ($_[0] eq '-classify') {
			$class = (shift, shift);
			croak "invalid -classify option value"
				if !defined $class || ref $class || !length $class;
			$meth = 1; $new = 1;
		}
		else { croak "unknown option to h2o: '$_[0]'" }
	}
	$clean = !defined $class unless defined $clean;
	$lock = 1 unless defined $lock;
	my $hash = shift;
	croak "h2o must be given a plain hashref" unless ref $hash eq 'HASH';
	croak "h2o with additional keys doesn't make sense with -ro" if $ro && @_ && !$new;
	my %ak   = map {$_=>1} @_;
	my %keys = map {$_=>1} @_, keys %$hash;
	croak "h2o hashref may not contain a key named DESTROY"
		if $clean && exists $keys{DESTROY};
	croak "h2o hashref may not contain a key named new if you use the -new option"
		if $new && exists $keys{new};
	croak "h2o can't turn off -lock if -ro is on" if $ro && !$lock;
	if ($recurse) { ref eq 'HASH' and h2o(-recurse,-lock=>$lock,($ro?-ro:()),$_) for values %$hash }
	my $pack = defined $class ? $class : sprintf('Util::H2O::_%x', $hash+0);
	for my $k (keys %keys) {
		my $sub = $ro
			? sub { my $self = shift; croak "this object is read-only" if @_; exists $self->{$k} ? $self->{$k} : undef }
			: sub { my $self = shift; $self->{$k} = shift if @_; $self->{$k} };
		if ( $meth && ref $$hash{$k} eq 'CODE' )
			{ $sub = delete $$hash{$k}; $ak{$k} or delete $keys{$k} }
		{ no strict 'refs'; *{"${pack}::$k"} = $sub }  ## no critic (ProhibitNoStrict)
	}
	if ( $clean ) {
		my $sub = sub { delete_package($pack) };
		{ no strict 'refs'; *{$pack.'::DESTROY'} = $sub }  ## no critic (ProhibitNoStrict)
	}
	if ( $new ) {
		my $sub = sub {
			my $class = shift;
			$class = ref $class if ref $class;
			croak "Odd number of elements in argument list" if @_%2;
			my $self = {@_};
			exists $keys{$_} or croak "Unknown argument '$_'" for keys %$self;
			bless $self, $class;
			if ($ro) { lock_hashref $self }
			elsif ($lock) { lock_ref_keys $self, keys %keys }
			return $self;
		};
		{ no strict 'refs'; *{$pack.'::new'} = $sub }  ## no critic (ProhibitNoStrict)
	}
	bless $hash, $pack;
	if ($ro) { lock_hashref $hash }
	elsif ($lock) { lock_ref_keys $hash, keys %keys }
	return $hash;
}

1;
__END__

=head1 Notes

=head2 C<AUTOLOAD>

If your hash contains a key named C<AUTOLOAD>, or this key is present in
C<@additional_keys>, this module will set up a method called C<AUTOLOAD>, which
is subject to Perl's normal autoloading behavior - see L<perlsub/Autoloading>
and L<perlobj/AUTOLOAD>. Without the C<-meth> option, you will get a
"catch-all" accessor to which all method calls to unknown method names will go,
and with C<-meth> enabled (which is implied by C<-classify>), you can install
your own custom C<AUTOLOAD> handler by passing a coderef as the value for this
key. However, it is important to note that enabling autoloading removes any
typo protection on method names.

=head1 See Also

Inspired in part by C<lock_keys> from L<Hash::Util>.

Many, many other modules exist to simplify object creation in Perl.
This one is mine C<;-P>

Similar modules include L<Object::Adhoc|Object::Adhoc>,
L<Object::Anon|Object::Anon>, L<Hash::AsObject|Hash::AsObject>,
L<Object::Result|Object::Result>, and L<Hash::Wrap|Hash::Wrap>,
the latter of which also contains a comprehensive list of similar
modules.

For real OO work, I like L<Moo> and L<Type::Tiny>.

=head1 Author, Copyright, and License

Copyright (c) 2020-2021 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
