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

our $VERSION = '0.20';
# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our @EXPORT = qw/ h2o /;  ## no critic (ProhibitAutomaticExportation)
our @EXPORT_OK = qw/ o2h /;

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
are not recursed into, but see the C<-arrays> option for that.

Versions of this module before v0.12 did not pass down the C<-lock> option,
meaning that if you used C<-nolock, -recurse> on those versions, the nested
hashes would still be locked.

=item C<-arrays>

Like C<-recurse>, but additionally, C<h2o> is applied to elements of
nested arrays as well. The same options as with C<-recurse> are
passed down to nested hashes and arrayrefs. Takes precedence over the
C<-pass> option, i.e. if you use these two options together,
arrayrefs are still descended into. Like hashrefs, the original
arrays are modified!

This option implies C<-recurse>.
This option was added in v0.20.

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
C<-new> or C<-classify>.

If you wanted to generate a unique package name in a different package,
you could use:
C<< h2o -class => sprintf('My::Class::Name::_%x', $hash+0), $hash >>,
perhaps even in combination with C<< -isa => 'My::Class::Name' >>.
However, keep in mind that you shouldn't step into another class' namespace
without knowing that this won't cause conflicts, and also that not using the
default class names means that functions like C<o2h> will no longer identify
the objects as coming from C<h2o>.

=item C<< -classify => I<classname_string or $hashref> >>

In the form C<< -classify => I<classname_string> >>, this is simply the short
form of the options C<< -new, -meth, -class => I<classname_string> >>.

As of v0.16, in the special form C<< -classify => I<$hashref> >>, where the
C<-classify> B<must> be the B<last> option in C<@opts> before the
L<C<$hashref>|/"$hashref">, it is the same as
C<< -new, -meth, -class => __PACKAGE__, I<$hashref> >> - that is, the current
package's name is used as the custom class name. It does not make sense to use
this outside of an explicit package, since your class will be named C<main>.
With this option, the C<Point> example in the L</Synopsis> can be written like
the following, which can be useful if you want to add more things to the
C<package>, or perhaps if you want to write your methods as regular C<sub>s:

 {
     package Point;
     use Util::H2O;
     h2o -classify, {
          angle => sub { my $self = shift; atan2($self->y, $self->x) }
     }, qw/ x y /;
 }

Note C<h2o> will remain in the package's namespace, one possibility is that you
could load L<namespace::clean> after you load this module.

You might also note that in the above example, one could write C<angle> as a
regular C<sub> in the package. And at that point, one might recongize the
similarity between the code and what one can do with e.g.
L<Class::Tiny|Class::Tiny> or even L<Moo|Moo>.

=item C<< -isa => I<arrayref or scalar> >>

Convenience option to set the L<C<@ISA>|perlvar/"@ISA"> variable in the package
of the object, so that the object inherits from that/those package(s).
This option was added in v0.14.

B<Warning:> The methods created by C<h2o> will not call superclass methods.
This means the parent class' C<DESTROY> method(s) are not called, and any
accessors generated from hash keys are blindly overriden.

=item C<-new>

Generates a constructor named C<new> in the package. The constructor
works as a class and instance method, and dies if it is given any
arguments that it doesn't know about. If you want more advanced
features, like required arguments, validation, or other
initialization, you should probably L<switch|/"Upgrading to Moo">
to something like L<Moo> instead.

=item C<< -destroy => I<coderef> >>

Allows you to specify a custom destructor. This coderef will be called from the
object's actual C<DESTROY> in void context with the first argument being the
same as the first argument to the C<DESTROY> method. Errors will be converted
to warnings.
This option was added in v0.14.

=item C<< -clean => I<bool> >>

Whether or not to clean up the generated package when the object is
destroyed. Defaults to I<false> when C<-class> is specified, I<true>
otherwise. If this is I<false>, be aware that the packages will stay
in Perl's symbol table and use memory accordingly.

As of v0.16, this module will refuse to delete the package if it
is named C<main>.

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

=item C<< -pass => "ref" I<or> "undef" >>

When this option is set to C<"undef"> (that's the string C<"undef">, I<not>
C<undef> itself!), then passing a value of C<undef> for the C<$hashref> will
not result in a fatal error, the value will simply be passed through.

When this option is set to the string C<"ref">, then any value other than a
plain hashref that is a reference, including objects, plus C<undef> as above,
will be passed through without modification. Any hashes nested inside of these
references will not be descended into, even when C<-recurse> is specified.
However, C<-arrays> takes precedence over this option, see its documentation.

This option was added in v0.18.

=back

=head3 C<$hashref>

You must supply a plain (unblessed) hash reference here, unless
you've specified the C<-pass> and/or C<-arrays> options. Be aware
that this function I<does> modify the original hashref(s) by blessing
it and locking its keyset (the latter can be disabled with the
C<-lock> option), and if you use C<-meth> or C<-classify>, keys whose
values are code references will be removed.
If you use C<-arrays>, the elements of those arrays may also be modified.

An accessor will be set up for each key in the hash(es); note that the
keys must of course be valid Perl identifiers for you to be able to
call the method normally (see also the L</Cookbook>).

The following keys will be treated specially by this module. Please note that
there are further keys that are treated specially by Perl and/or that other
code may expect to be special, such as L<UNIVERSAL>'s C<isa>. See also
L<perlsub> and the references therein.

=over

=item C<new>

This key is not allowed in the hash if the C<-new> option is on.

=item C<DESTROY>

This key is not allowed except if all of the following apply:

=over

=item *

C<-destroy> is not used,

=item *

C<-clean> is off (which happens by default when you use C<-class>),

=item *

C<-meth> is on, and

=item *

the value of the key C<DESTROY> is a coderef.

=back

Versions of this module before v0.14 allowed a C<DESTROY> key in more
circumstances (whenever C<-clean> was off).

=item C<AUTOLOAD>

If your hash contains a key named C<AUTOLOAD>, or this key is present in
C<@additional_keys>, this module will set up a method called C<AUTOLOAD>, which
is subject to Perl's normal autoloading behavior - see L<perlsub/Autoloading>
and L<perlobj/AUTOLOAD>. Without the C<-meth> option, you will get a
"catch-all" accessor to which all method calls to unknown method names will go,
and with C<-meth> enabled (which is implied by C<-classify>), you can install
your own custom C<AUTOLOAD> handler by passing a coderef as the value for this
key - see L</An Autoloading Example>. However, it is important to note that
enabling autoloading removes any typo protection on method names!

=back

=head3 C<@additional_keys>

Methods will be set up for these keys even if they do not exist in the hash.

Please see the list of keys that are treated specially above.

=head3 Returns

The (now blessed and optionally locked) C<$hashref>.

=cut

our $_PACKAGE_REGEX = qr/\AUtil::H2O::_[0-9A-Fa-f]+\z/;

sub h2o {  ## no critic (RequireArgUnpacking, ProhibitExcessComplexity)
	my ($recurse,$arrays,$meth,$class,$isa,$destroy,$new,$clean,$lock,$ro,$pass);
	while ( @_ && $_[0] && !ref$_[0] && $_[0]=~/^-/ ) {
		if ($_[0] eq '-recurse' ) { $recurse = shift }  ## no critic (ProhibitCascadingIfElse)
		elsif ($_[0] eq '-arrays'){ $arrays  = shift }
		elsif ($_[0] eq '-meth' ) { $meth    = shift }
		elsif ($_[0] eq '-clean') { $clean   = (shift, shift()?1:0) }
		elsif ($_[0] eq '-lock' ) { $lock    = (shift, shift()?1:0) }
		elsif ($_[0] eq '-nolock'){ $lock = 0; shift }
		elsif ($_[0] eq '-ro'   ) { $ro      = shift }
		elsif ($_[0] eq '-new'  ) { $new     = shift }
		elsif ($_[0] eq '-pass' ) {
			$pass = (shift, shift);
			croak "invalid -pass option value (must be 'undef' or 'ref')"
				if !defined $pass || $pass ne 'undef' && $pass ne 'ref';
		}
		elsif ($_[0] eq '-class') {
			$class = (shift, shift);
			croak "invalid -class option value"
				if !defined $class || ref $class || !length $class;
		}
		elsif ($_[0] eq '-classify') {
			$class = (shift, shift);
			if ( ref $class eq 'HASH' ) { unshift @_, $class; $class = caller; }
			croak "invalid -classify option value"
				if !defined $class || ref $class || !length $class;
			$meth = 1; $new = 1;
		}
		elsif ($_[0] eq '-isa') {
			$isa = (shift, shift);
			croak "invalid -isa option value" if !( ref($isa) eq 'ARRAY' || !ref($isa) );
			$isa = [$isa] unless ref $isa;
		}
		elsif ($_[0] eq '-destroy') {
			$destroy = (shift, shift);
			croak "invalid -destroy option value" unless ref $destroy eq 'CODE';
		}
		else { croak "unknown option to h2o: '$_[0]'" }
	}
	$clean = !defined $class unless defined $clean;
	$lock = 1 unless defined $lock;
	$recurse = 1 if $arrays;
	my $hash = shift;
	if ( ref $hash ne 'HASH' ) {
		if ( $arrays && ref $hash eq 'ARRAY' ) {
			for (@$hash)
				{ h2o( -arrays, -lock=>$lock, ($ro?-ro:()), $_ )
					if ref eq 'HASH' || ref eq 'ARRAY' }
			return $hash;
		}
		elsif ( $pass ) {
			if ( $pass eq 'ref' ) {
				return $hash if !defined $hash || ref $hash;
				croak "this h2o call only accepts references or undef";
			}
			else { # $pass must be 'undef' due to checks above
				return $hash if !defined $hash;
				croak "this h2o call only accepts a plain hashref or undef";
			}
		}
		croak "this h2o call only accepts plain hashrefs";
	}
	croak "h2o with additional keys doesn't make sense with -ro" if $ro && @_ && !$new;
	my %ak   = map {$_=>1} @_;
	my %keys = map {$_=>1} @_, keys %$hash;
	croak "h2o hashref may not contain a key named DESTROY"
		if exists $keys{DESTROY} && ( $destroy || $clean || !$meth || ref $hash->{DESTROY} ne 'CODE' );
	croak "h2o hashref may not contain a key named new if you use the -new option"
		if $new && exists $keys{new};
	croak "h2o can't turn off -lock if -ro is on" if $ro && !$lock;
	if ($recurse) {
		for (values %$hash) {
			if ( $arrays && ref eq 'ARRAY' )
				{ h2o(-arrays,  -lock=>$lock, ($ro?-ro:()), $_) }
			elsif ( ref eq 'HASH' )
				{ h2o(-recurse, -lock=>$lock, ($ro?-ro:()), $_) }
		}
	}
	my $pack = defined $class ? $class : sprintf('Util::H2O::_%x', $hash+0);
	for my $k (keys %keys) {
		my $sub = $ro
			? sub { my $self = shift; croak "this object is read-only" if @_; exists $self->{$k} ? $self->{$k} : undef }
			: sub { my $self = shift; $self->{$k} = shift if @_; $self->{$k} };
		if ( $meth && ref $$hash{$k} eq 'CODE' )
			{ $sub = delete $$hash{$k}; $ak{$k} or delete $keys{$k} }
		{ no strict 'refs'; *{"${pack}::$k"} = $sub }  ## no critic (ProhibitNoStrict)
	}
	if ( $destroy || $clean ) {
		my $sub = sub {
			$destroy and ( eval { $destroy->($_[0]); 1 } or carp $@ );  ## no critic (ProhibitMixedBooleanOperators)
			if ( $clean ) {
				if ( $pack eq 'main' ) { carp "h2o refusing to delete package \"main\"" }
				else { delete_package($pack) }
			}
		};
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
	if ($isa) { no strict 'refs'; @{$pack.'::ISA'} = @$isa }  ## no critic (ProhibitNoStrict)
	bless $hash, $pack;
	if ($ro) { lock_hashref $hash }
	elsif ($lock) { lock_ref_keys $hash, keys %keys }
	return $hash;
}

=head2 C<o2h I<@opts>, I<$h2object>>

This function takes an object as created by C<h2o> and turns it back
into a hashref by making shallow copies of the object hash and any
nested objects that may have been created via C<-recurse>,
C<-arrays>, or created manually. This function is recursive by
default because for a non-recursive operation you can simply write:
C<{%$h2object}> (making a shallow copy).

Unlike C<h2o>, this function returns a new hashref instead of
modifying the given variable in place (unless what you give this
function is not an C<h2o> object, in which case it will just be
returned unchanged). Similarly, if you specify the C<-arrays> option,
shallow copies of arrays will be returned in place of the original
ones, with C<o2h> applied to the elements.

B<Note> that this function operates only on objects in the default
package - it does not step into plain hashrefs, it does not step into
arrayrefs unless you specify C<-arrays>, nor does it operate on
objects created with the C<-class> or C<-classify> options. Also be
aware that because methods created via C<-meth> are removed from the
object hash, these will disappear in the resulting hashref.

This function was added in v0.18.

=head3 C<@opts>

If you specify an option with a value multiple times, only the last
one will take effect.

=over

=item C<-arrays>

If you specify this option, nested arrayrefs are descended into as well.

This option was added in v0.20.

=back

=cut

sub o2h {  ## no critic (RequireArgUnpacking)
	my ($arrays);
	while ( @_ && $_[0] && !ref$_[0] && $_[0]=~/^-/ ) {
		if ($_[0] eq '-arrays' ) { $arrays = shift }
		else { croak "unknown option to o2h: '$_[0]'" }
	}
	croak "missing argument to o2h" unless @_;
	my $h2o = shift;
	croak "too many arguments to o2h" if @_;
	my @args = ( $arrays ? (-arrays) : () );
	if ( ref($h2o) =~ $_PACKAGE_REGEX )
		{ return { map { $_ => o2h(@args, $h2o->{$_}) } keys %$h2o } }
	elsif ( $arrays && ref $h2o eq 'ARRAY' )
		{ return [ map { o2h(@args, $_) } @$h2o ] }
	return $h2o;
}

1;
__END__

=head1 Cookbook

=head2 Keys with Spaces, Dashes, or Other Non-Identifier Characters

If the hash you want to pass to C<h2o> contains keys that are not usable as
method names, such as keys containing spaces or dashes, you can transform the
hash before passing it to C<h2o>. There are several ways to do this, including
in plain Perl, but one of the easier ways is with C<pairmap> from the core
module L<List::Util>.

 use List::Util 'pairmap';
 my $hash = { "foo bar" => 123, "quz-ba%z" => 456 };
 my $obj = h2o { pairmap { $a=~tr/a-zA-Z0-9/_/c; ($a,$b) } %$hash };
 print $obj->foo_bar, $obj->quz_ba_z, "\n";  # prints "123456"

=head2 Using with Config::Tiny

One common use case for this module is to make accessing hashes nicer, like for
example those you get from L<Config::Tiny|Config::Tiny>. Here's how you can
create a new C<h2o> object from a configuration file:

 use Util::H2O 0.18 qw/ h2o o2h /;  # v0.18 for o2h
 use Config::Tiny 2.27;             # v2.27 for writing file back out
 
 my $config = h2o -recurse, {%{ Config::Tiny->read($config_filename) }};
 
 say $config->foo->bar;  # prints the value of "bar" in section "[foo]"
 $config->foo->bar("Hello, World!");  # change value
 
 # write file back out
 Config::Tiny->new(o2h $config)->write($config_filename);

=head2 Debugging

Because the packages generated by C<h2o> are dynamic, note that any debugging
dumps of these objects will be somewhat incomplete because they won't show the
methods. However, if you'd like somewhat nicer looking dumps of the I<data>
contained in the objects, one way you can do that is with L<Data::Dump::Filtered>:

 use Util::H2O;
 use Data::Dump qw/dd/;
 use Data::Dump::Filtered qw/add_dump_filter/;
 add_dump_filter( sub {
     my ($ctx, $obj) = @_;
     return { bless=>'', comment=>'Util::H2O::h2o()' }
         if $ctx->class=~/^Util::H2O::/;
     return undef; # normal Data::Dump processing for all other objects
 });
 
 my $x = h2o -recurse, { foo => "bar", quz => { abc => 123 } };
 dd $x;

Outputs:

 # Util::H2O::h2o()
 {
   foo => "bar",
   quz => # Util::H2O::h2o()
          { abc => 123 },
 }

=head2 An Autoloading Example

If you wanted to create a class where (almost!) every method call is
automatically translated to a hash access of the corresponding key, here's how
you could do that:

 h2o -classify=>'HashLikeObj', -nolock, {
     AUTOLOAD => sub {
         my $self = shift;
         our $AUTOLOAD;
         ( my $key = $AUTOLOAD ) =~ s/.*:://;
         $self->{$key} = shift if @_;
         return $self->{$key};
     } };

=head2 Upgrading to Moo

Let's say you've used this module to whip up two simple classes:

 h2o -classify => 'My::Class', {}, qw/ foo bar details /;
 h2o -classify => 'My::Class::Details', {}, qw/ a b /;

But now you need more features and would like to upgrade to an actual OO system
like L<Moo>. Here's how you'd write the above code using that, with some
L<Type::Tiny> thrown in:

 package My::Class2 {
     use Moo;
     use Types::Standard qw/ InstanceOf /;
     use namespace::clean; # optional but recommended
     has foo     => (is=>'rw');
     has bar     => (is=>'rw');
     has details => (is=>'rw', isa=>InstanceOf['My::Class2::Details']);
 }
 package My::Class2::Details {
     use Moo;
     use namespace::clean;
     has a => (is=>'rw');
     has b => (is=>'rw');
 }

=head1 See Also

Inspired in part by C<lock_keys> from L<Hash::Util>.

Many, many other modules exist to simplify object creation in Perl.
This one is mine C<;-P>

Similar modules include L<Object::Adhoc|Object::Adhoc>,
L<Object::Anon|Object::Anon>, L<Hash::AsObject|Hash::AsObject>,
L<Object::Result|Object::Result>, and L<Hash::Wrap|Hash::Wrap>,
the latter of which also contains a comprehensive list of similar
modules. Also, see L<Class::Tiny|Class::Tiny> for another minimalistic class
generation module.

For real OO work, I like L<Moo|Moo> and L<Type::Tiny|Type::Tiny> (see
L</"Upgrading to Moo">).

Further modules that might be useful in combination with this one:
L<Hash::Merge|Hash::Merge> for merging hashes before using this module (for
example, to supply default values for keys); L<Role::Tiny|Role::Tiny> for
applying roles.

See also L<Util::H2O::More|Util::H2O::More> by OODLER, a module with additional
functionality on top of this module.

=head1 Special Thanks

Thanks to oodler577 on GitHub (OODLER on CPAN), whose many suggestions have
inspired a lot of the features in this module!

=head1 Author, Copyright, and License

Copyright (c) 2020-2023 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
