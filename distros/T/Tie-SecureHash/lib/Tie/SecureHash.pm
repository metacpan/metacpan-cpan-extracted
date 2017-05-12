package Tie::SecureHash;

use strict;
our ($VERSION, $strict, $fast, $dangerous, $loud);
use Carp;

$VERSION = '1.10';

sub import {
    my ($pkg, @args) = @_;
    my $args = join(' ', @args);
    $strict = $args =~ /\bstrict\b/;
    $fast   = $args =~ /\bfast\b/;
    $dangerous = $args =~ /\bdangerous\b/;
    $loud = $args =~ /\bloud\b/;
    croak qq{$pkg can't be both "strict" and "fast"} if $strict && $fast;
    $strict = 1 if $loud;
}

# TAKE A LIST OF POSSIBLE CLASSES FOR AN IMPLICIT KEY AND REMOVE NON-CONTENDERS

sub _winnow {
    my ($caller, $nonpublic, @classes) = @_;

    # REMOVE CLASSES NOT IN HIERARCHY FOR NON-PUBLIC KEY

    @classes = grep { $caller->isa($_) } @classes if $nonpublic;

    # COMPARE REMAINING KEYS PAIRWISE, ELIMINATING "SHADOWED" KEYS...

  I: for(my $i=0; $i<$#classes; )
	{
          J: for(my $j=$i+1; $j<@classes; )
		{
                    if ($classes[$j]->isa($classes[$i])) {
			# CLASS J SHADOWS I FROM $caller
                        if ($caller->isa($classes[$j])) {
                            splice @classes,$i,1;
                            next I;
                        }
			# CLASS J BELOW CALLING PACKAGE
			# (SO CALLING PACKAGE COULDN'T INHERIT IT)
                        elsif ($classes[$j]->isa($caller)) {
                            splice @classes,$j,1;
                            next J;
                        }
                    } elsif ($classes[$i]->isa($classes[$j])) {
			# CLASS I SHADOWS J FROM $caller
                        if ($caller->isa($classes[$i])) {
                            splice @classes,$j,1;
                            next J;
                        }
			# CLASS I BELOW CALLING PACKAGE
			# (SO CALLING PACKAGE COULDN'T INHERIT IT)
                        elsif ($classes[$i]->isa($caller)) {
                            splice @classes,$i,1;
                            next I;
                        }
                    }
                    $j++;

		}
            $i++;
	}

    return @classes;
}
;

# DETERMINE IF A KEY IS ACCESSIBLE

sub _access {
    my ($self, $key, $caller, $file, $delete) = @_;

    # EXPLICIT KEYS...

    if ($key =~ /\A([\w:]*)::((_{0,2})[^:]+)\Z/) {
        my ($classname, $shortkey, $mode) = ($1,$2,$3);
        unless ($classname)
            {
                $classname = 'main';
                $key = $classname.$key;
            }
        if ($mode eq '__')	# PRIVATE
            {
                croak "Private key $key of tied securehash inaccessible from package $caller"
                    unless $classname eq $caller;
                if (exists $self->{fullkeys}{$key}) {
                    croak "Private key $key of tied securehash inaccessible from file $file"
                        if $self->{file}{$key} ne $file;
                } else {
                    if ($delete) {
                        delete $self->{file}{$key};
                    } else {
                        $self->{file}{$key} = $file;
                    }
                }
            } elsif ($mode eq '_') # PROTECTED
		{
                    croak "Protected key $key of tied securehash inaccessible from package $caller"
                        unless $caller->isa($classname);
		}

        if (!exists $self->{fullkeys}{$key}) {
            croak "Entry for key $key of tied securehash cannot be created " .
                "from package $caller"
                    if $classname ne $caller && !$delete;
            if ($delete) {
                @{$self->{keylist}{$shortkey}} =
                    grep { $_ !~ /$classname/ }
                        @{$self->{keylist}{$shortkey}}
                    } else {
                        push @{$self->{keylist}{$shortkey}}, $classname;
                    }
        }
    }

    # IMPLICIT PRIVATE KEY (MUST BE IN CALLING CLASS)
    elsif ($key =~ /\A(__[^:]+)\Z/) {
        carp qq{Accessing securehash via unqualified key {"$key"}\n}.
            qq{will be unsafe in 'fast' mode. Use {"${caller}::$key"}}
                if $strict && $ENV{UNSAFE_WARN};
        if (!exists $self->{fullkeys}{"${caller}::$key"}) {
            croak "Private key '$key' of tied securehash is inaccessible from package $caller"
                if exists $self->{keylist}{$key};
            croak "Private key '${caller}::$key' does not exist in tied securehash"
        }
        $key = "${caller}::$key";	
        if (exists $self->{fullkeys}{$key}) {
            croak "Private key $key of tied securehash inaccessible from file $file"
                if $self->{file}{$key} ne $file;
        }
    }

    # IMPLICIT PROTECTED OR PUBLIC KEY
    # (PROTECTED KEY MUST BE IN ANCESTRAL HIERARCHY OF CALLING CLASS)
    elsif ($key =~ /\A((_?)[^:]+)\Z/) {
        my $fullkey = "${caller}::$key";	
        carp qq{Accessing securehash via unqualified key {"$key"}\n}.
            qq{will be unsafe in 'fast' mode. Use {"${caller}::$key"}}
                if $strict && $ENV{UNSAFE_WARN};
        if (exists $self->{fullkeys}{$fullkey}) {
            $key = $fullkey;
        } else {
            my @classes = _winnow($caller, $2,
                                  @{$self->{keylist}{$key}||[]});
	
            if (@classes) {
				# TOO MANY CHOICES
                croak "Ambiguous key '$key' (when accessed "
                    . "from package $caller).\nCould be:\n"
                        . join("", map {"\t${_}::$key\n"} @classes)
                            . " " 
                                if @classes > 1;
                $key = $classes[0]."::$key";
            } else              # NOT ENOUGH CHOICES
                {
                    croak +($2?"Protected":"Public")." key '$key' of tied securehash is inaccessible from package $caller"
                        if exists $self->{keylist}{$key};
                    croak +($2?"Protected":"Public")." key '${caller}::$key' does not exist in tied securehash";
                }
        }
    } else                      # INVALID KEY 
	{
            croak "Invalid key '$key'";
	}

    if ($delete) {
        return delete $self->{fullkeys}{$key};
    }	
    return \$self->{fullkeys}{$key};
}

sub _dangerous_access {
    my ($self,$key,$caller, $action) = @_;
    _complain(@_) if $strict;
    require mro;
    my @isa = @{mro::get_linear_isa($caller)}; # mro seems to return a weird read only arrayref
    pop @isa if $isa[-1] eq 'Exporter';
    my @candidate_keys = map { "$_::$key" } @isa;
    my $val;
    foreach my $k (@candidate_keys) {
        if ($action eq 'DELETE') {
            my $deleted;
            if (exists $self->{fullkeys}->{$k}) {
                delete $self->{fullkeys}->{$k};
                $deleted = 1;
            }
            last if $deleted;
        } else {
            $val = $self->{fullkeys}->{$k};
            last if $val;
        }
    }
    return \$val;
}

sub _complain { # override complain with Role::Tiny to customise dump.
    my ($self, $key, $caller, $action) = @_;
    $DB::single=1;
    carp "Ran an expensive dangerous $action due to unqualified key $key being sent in to hash for $caller" if $strict;
    if ($loud) {
        require Data::Dumper;
        Data::Dumper->import;
        carp Dumper ($self->{fullkeys});
    }
}

# NOTE THAT NEW MAY TIE AND BLESS INTO THE SAME CLASS
# IF NOTHING MORE APPROPRIATE IS SPECIFIED

sub new {
    my %self = ();
    my $class =  ref($_[0])||$_[0];
    my $blessclass =  ref($_[1])||$_[1]||$class;
    my $impl = tie %self, $class unless $fast;
    my $self = bless \%self, $blessclass;
    splice(@_,0,2);
    if (@_)                     # INITIALIZATION ARGUMENTS PRESENT
	{
            my ($ancestor, $file);
            my $i = 0;
            while ( ($ancestor,$file) = caller($i++) ) {
                last if $ancestor eq $blessclass;
            }
            $file = "" if ! defined $file; # dms 14 Mar 2000: satisfy -w switch
            my ($key, $value);
            while (($key,$value) = splice(@_,0,2)) {
                my $fullkey = $key=~/::/ ? $key : "${blessclass}::$key";
                if ($fast) {
                    $self->{$fullkey} = $value;
                } else {
                    $impl->{fullkeys}{$fullkey} = $value;
                    push @{$impl->{keylist}{$key}}, $blessclass;
                    $impl->{file}{$fullkey} = $file
                        if $key =~ /\A__/;
                }
            }
	}

    return $self;
}

# USEFUL METHODS TO DUMP INFORMATION

sub debug {
    my $self = tied %{$_[0]};
    my ($caller, $file, $line, $sub) = (caller,(caller(1))[3]||"(none)");
    return _simple_debug($_[0],$caller, $file, $line, $sub) unless $self;
    my ($key, $val);
    my %sorted = ();
    while ($key = CORE::each %{$self->{fullkeys}}) {
        $key =~ m/\A(.*?)([^:]*)\Z/;
        push @{$sorted{$1}}, $key;
    }

    print STDERR "\nIn subroutine '$sub' called from package '$caller' ($file, line $line):\n";
    foreach my $class (CORE::keys %sorted) {
        print STDERR "\n\t$class\n";
        foreach $key ( @{$sorted{$class}} ) {
            print STDERR "\t\t";
            my ($shortkey) = $key =~ /.*::(.*)/;
            my $explanation = "";
            if (eval { _access($self,$shortkey,$caller, $file); 1 }) {
                print STDERR '(+)';
            } elsif ($@ =~ /\AAmbiguous key/) {
                print STDERR '(?)';
                ($explanation = $@) =~ s/.*\n//;
                $explanation =~ s/.*\n\Z//;
                $explanation =~ s/\ACould/Ambiguous unless fully qualified. Could/;
                $explanation =~ s/^(?!\Z)/\t\t\t>>> /gm;
            } else {
                print STDERR '(-)';
                if ($shortkey =~ /\A__/ && $@ =~ /file/) {
                    $explanation = "\t\t\t>>> Private entry of $class\n\t\t\t>>> declared in file $self->{file}{$key}\n\t\t\t>>> is inaccessable from file $file.\n"
                } elsif ($shortkey =~ /\A__/) {
                    $explanation = "\t\t\t>>> Private entry of $class\n\t\t\t>>> is inaccessable from package $caller.\n"
                } else {
                    $explanation = "\t\t\t>>> Protected entry of $class\n\t\t\t>>> is inaccessible outside its hierarchy (i.e. from $caller).\n"
                }
				
            }
            my $val = $self->{fullkeys}{$key};
            if (defined $val) {
                $val = "'$val'";
            } else {
                $val = "undef";
            }
            print STDERR " '$shortkey'\t=> $val";
            print STDERR "\n$explanation" if $explanation;
            print STDERR "\n";
        }
    }
}

sub _simple_debug {
    my ($self,$caller, $file, $line, $sub) = @_;
    my ($key, $val);
    my %sorted = ();
    while ($key = CORE::each %{$self}) {
        $key =~ m/\A(.*?)([^:]*)\Z/;
        push @{$sorted{$1}}, $key;
    }

    print "\nIn subroutine '$sub' called from package '$caller' ($file, line $line):\n";
    foreach my $class (CORE::keys %sorted) {
        print "\n\t$class\n";
        foreach $key ( @{$sorted{$class}} ) {
            print "\t\t";
            print " '$key'\t=> '$self->{$key}'\n";
        }
    }
}


sub each($)	{ CORE::each %{$_[0]} }
sub keys($)	{ CORE::keys %{$_[0]} }
sub values($)	{ CORE::values %{$_[0]} }
sub exists($$)	{ CORE::exists $_[0]->{$_[1]} }

sub TIEHASH {                   # ($class, @args)
    my $class = ref($_[0]) || $_[0];
    if ($strict) {
        carp qq{Tie'ing a securehash directly will be unsafe in 'fast' mode.\n}.
            qq{Use Tie::SecureHash::new instead}
                unless (caller 1)[3] =~ /\A(.*?)::([^:]*)\Z/
                    && $2 eq "new"
                        && "$1"->isa('Tie::SecureHash') && $ENV{UNSAFE_WARN};
    } elsif ($fast) {
        carp qq{Tie'ing a securehash directly should never happen in 'fast' mode.\n}.
            qq{Use Tie::SecureHash::new instead}
	}
    bless {}, $class;
}

sub FETCH {                     # ($self, $key)
    my ($self, $key) = @_;
    my $entry;
    if (! $dangerous) {
        $entry = _access($self,$key,(caller)[0..1]);
    } elsif ($key =~ /::/) {
        $entry = \$self->{fullkeys}->{$key};
    } else {
        my $caller = (caller)[0];
        $entry = $self->_dangerous_access($key, $caller, 'FETCH');
    }
    return $$entry if $entry;
    return;
}

sub STORE {                       # ($self, $key, $value)
	my ($self, $key, $value) = @_;
	my $entry;
	if (! $dangerous) {
            $entry = _access($self,$key,(caller)[0..1]);
	} elsif ($key =~ /::/) {
            $self->{fullkeys}->{$key} = $value;
            $entry = \$self->{fullkeys}->{$key};
	} else {
            my $caller = (caller)[0];
            $entry = $self->_dangerous_access($key,$caller, 'STORE');
	}
	return $$entry = $value if $entry;
	return;
    }

sub DELETE {                      # ($self, $key)
    my ($self, $key) = @_;
    if (! $dangerous) {
        return _access($self,$key,(caller)[0..1],'DELETE');
    } 
    elsif ($key =~ /::/) {
        delete $self->{fullkeys}->{$key};
    } 
    else {
        my $caller = (caller)[0];
        return $self->_dangerous_access($key, $caller, 'DELETE');
    }
}


sub CLEAR {                     # ($self)
    my ($self) = @_;
    if ($dangerous) {
        %$self = ();
    }
    else {
        my ($caller, $file) = caller;
        my @inaccessibles =
            grep { ! eval { _access($self,$_,$caller,$file); 1 } }
                CORE::keys %{$self->{fullkeys}};
        croak "Unable to assign to securehash because the following existing keys\nare inaccessible from package $caller and cannot be deleted:\n" .
            join("\n", map {"\t$_"} @inaccessibles) . "\n "
                if @inaccessibles;
        %{$self} = ();
    }
}

sub EXISTS                      # ($self, $key)
    {
	my ($self, $key) = @_;
        if (! $dangerous) {
            my @context = (caller)[0..1];
            eval { _access($self,$key,@context); 1 } ? 1 : '';
        }
        elsif ($key =~ /::/) {
            return exists $self->{fullkeys}->{$key};
        }
        else {
            my $caller = (caller)[0];
            _complain($self, $key, $caller, 'EXISTS') if $strict;
            return exists $self->{fullkeys}->{"$caller::$key"};
        }
    }

sub FIRSTKEY                    # ($self)
    {
	my ($self) = @_;
	CORE::keys %{$self->{fullkeys}};
	goto &NEXTKEY;
    }

sub NEXTKEY                     # ($self)
    {
	my $self = $_[0];
        if ($dangerous) {
            return CORE::each %{$self->{fullkeys}};
        }
	my $key;
	my @context = (caller)[0..1];
	while (defined($key = CORE::each %{$self->{fullkeys}})) {
            last if eval { _access($self,$key,@context) };
            carp "Attempt to iterate inaccessible key '$key' will be unsafe in 'fast' mode. Use explicit keys" if $ENV{UNSAFE_WARN};
		     
	}
	return $key;
    }

sub DESTROY {    # ($self) 
    # NOTHING TO DO
    # (BE CAREFUL SINCE IT DOES DOUBLE DUTY FOR tie AND bless)
}


1;
__END__

=head1 NAME

Tie::SecureHash - A tied hash that supports namespace-based encapsulation

=head1 VERSION

This document describes version 1.00 of Tie::SecureHash,
released December 3, 1998

=head1 CAVEAT

The original author of this module doesn't use it any more and it's
not recommended for new code.  Use L<Moo> or L<Moose> instead.  Newer
(2015) releases of this module are here to deal with unintended
consequences of the original implementation, and code that's not
easily moved away to more modern constructs.

=head1 SYNOPSIS

    use Tie::SecureHash;

    # CREATE A SECURE HASH

	my %hash;
	tie %hash, Tie::SecureHash;

    # CREATE A REFERENCE TO A SECURE HASH (BLESSED INTO Tie::SecureHash!)

	my $hashref = Tie::SecureHash->new();

    # CREATE A REFERENCE TO A SECURE HASH (BLESSED INTO $some_other_class)

	my $hashref = Tie::SecureHash->new($some_other_class);

    # CREATE NEW ENTRIES IN THE HASH

	package MyClass;

	sub new
	{
		my ($class, %args) = @_
		my $self = Tie::SecureHash->new($class);

		$self->{MyClass::public}     = $args{public};
		$self->{MyClass::_protected} = $args{protected};
		$self->{MyClass::__private}  = $args{private};

		return $self;
	}

    # SAME EFFECT, EASIER SYNTAX...

	package MyClass;

	sub new
	{
		my ($class, %args) = @_
		my $self = Tie::SecureHash->new($class,
				public     => $args{public},
				_protected => $args{protected},
				__private  => $args{private},
				);

		return $self;
	}


    # ACCESS RESTRICTIONS ON ENTRIES

	package MyClass;

	sub print_attributes
	{
	    my $self = $_[0];
					# OKAY? (ACCESSIBLE WHERE?)

	    print $self->{public};	#  YES  (ANYWHERE)
	    print $self->{_protected};	#  YES  (ONLY IN MyClass HIERARCHY)
	    print $self->{__private};	#  YES  (ONLY IN MyClass)
	}


	package SonOfMyClass; @ISA = qw( MyClass );

	sub print_attributes
	{
	    my $self = $_[0];
					# OKAY? (ACCESSIBLE WHERE?)

	    print $self->{public};	#  YES  (ANYWHERE)
	    print $self->{_protected};	#  YES  (ONLY IN MyClass HIERARCHY)
	    print $self->{__private};	#  NO!  (ONLY IN MyClass)
	}


	package main;

	my $object = MyClass->new();
					# OKAY? (ACCESSIBLE WHERE?)

	print $object->{public};	#  YES  (ANYWHERE)
	print $object->{_protected};	#  NO!  (ONLY IN MyClass HIERARCHY)
	print $object->{__private};	#  NO!  (ONLY IN MyClass)


    # DEBUGGING

	$object->Tie::SecureHash::debug();


=head1 DESCRIPTION

=head2 The problem
	
In Perl objects are just variables that have been associated with a
particular package. Typically they're blessed hashes, or arrays, or
scalars; occasionally they're darker mysteries, like typeglobs or
closures. And because they are usually just standard variables, the
attribute values they store are freely accessible everywhere in a
program.

So, even if the object has accessor methods to control how the
object's attributes are manipulated:

	$obj->set_name("ob1");
	print $obj->get_name();
	
it's still possible to access the data directly:

	$obj->{_name} = "ob1";
	print $obj->{_name};
	
But if the get_name and set_name methods do anything other than simply
retrieve and set the underlying hash entryfor example, checking the
assigned value's validity, or logging retrievalsthen directly
accessing the data in this way may introduce subtle bugs into the
program.

In practice, this lack of a built-in encapsulation mechanism rarely
seems to be a problem in Perl. Most object-oriented Perl programmers
use hashes as the basis of their objects, and get by quite happily
with the principle of "encapsulation by good manners". The lack of
protection for attribute values doesn't matter because users of a
class either respect the official interface of its objects (i.e. their
methods), or they're smart enough to get away with poking around
inside an object without breaking anything.

The only problem is that this culturally enforced encapsulation
doesn't scale very well. It's fine for a few hundred lines of code
written by a single programmer, but is less successful when the code
is tens of thousands of lines long and developed by a group of people.
Even if the entire team can be trusted to maintain sufficient
programming discipline and to consistently respect the notional
encapsulation of attributes (a dubious proposition), accidents and
mistakes will happen. Especially in rarely used parts of the system.

Moreover, deliberate decisions to circumvent the conventions of
encapsulation are rarely documented adequately, leading to problems
much later in the development cycle. For example, consider a
notionally "private" attribute of an object, which for efficiency
reasons is accessed directly in an obscure part of a large system. If
the implementation of the object's class changes, that attribute may
cease to exist. In a more static language, this would cause an error
message to be generated when next some external code attempts to
access the (now non-existent) attribute. However, Perl's
autovivification of hash entries will silently "recreate" the former
attribute whenever it's accessed. The direct access operation
proceeds, but now it retrieves or modifies a "phantom" attribute. Bugs
such as this can be painfully difficult to diagnose and track down,
especially if the original programmer has moved on by the time the
problem is discovered.
	
Most object-oriented languages provide encapsulation that comes in
varying strengths. For example, in C++ and Java, object and class data
members can be declared as "public", "protected", or "private".
"Public" attributes are available everywhere, "protected" attributes
are restricted to a particular class hierarchy, and "private"
attributes are only visible to the current class. Likewise, attributes
in Eiffel can be given an export list to control which other classes
can access them.

In contrast, other Perl encapsulation techniques (encapsulation via
closures, and the "Flyweight" patter -- see L<perltoot>
and I<Object Oriented Perl>) are
inherently "all-or-nothing" propositions. Every attribute is
completely encapsulated from the rest of the program. In C++/Java
terms, they're all "private"; in Eiffel terms, none of them is
"exported". It's up to the accessor subroutines to provide the
necessary logic (i.e. die unless $public{$attr} || caller eq $class)
to grant different levels of access. And, of course, this logic has to
be manually coded in each encapsulating closure.

A more significant drawback is that these techniques are moderately
hard to understand and to code correctly, particularly by beginners, who
probably benefit most from proper encapsulation. Both techniques are
based on the closure properties of Perl subroutines, which are not
well understood by many programmers. Both are most efficiently
implemented using relatively obscure code, which reduces the
maintainability of the resulting classes.

All in all, the costs of building encapsulated classes seem to
outweigh the benefits. It's hardly surprising that, as elegant as they
are, such classes are used so rarely. What's really needed is a
mechanism that will allow objects to be implemented in the usual way
(i.e. by blessing hashes) and yet enable the implementer to designate
some of the attributes of the resulting objects as "protected" or
"private".

=head2 A limited-access hash
	
The Tie::SecureHash module does just that. Hashes that are tied
to it continue to provide most of the behaviours of a normal hash, but
also allow their keys to be fully qualifiedas if they were independent
package variables. The module then uses these key qualifiers to
restrict the accessibility of the corresponding entries in a tied
hash.

A Tie::SecureHash object (or securehash) can be created by explicitly
tie'ing an existing hash:

	my %securehash;
	tie %securehash, Tie::SecureHash;
	
or by calling the module's constructor method:

	my $securehash_ref = Tie::SecureHash->new();
	
The constructor version returns a reference to an anonymous hash that
has been tied to the Tie::SecureHash package, and which has also been
blessed into the Tie::SecureHash class.

Either way, a securehash acts like a regular hash, and provides:

=over

=item *

access to individual entries using the normal hash access
syntaxes: C<$securehash{$key}> or C<$securehash_ref-E<gt>{$key}>,

=item *

iteration through the entire hash: C<each %securehash>,

=item *

lists of keys and values that it currently contains:
C<keys %securehash}, C<values %{$securehash_ref}>,

=item * existence checks for entries: C<exists $securehash_ref-E<gt>{$key}>,

=back

The module provides object methods corresponding to each of these
operations: C<$securehash_ref-E<gt>values()>, C<$securehash_ref-E<gt>each()>,
C<$securehash_ref-E<gt>exists($key)>, etc.

Securehashes also support deletion of individual entries and direct
assignment, with some limitations.

=head2 Building objects from securehashes
	
When using a securehash as the basis of an object (i.e. blessing it in
some class's constructor), it's tedious to have to create the hash,
tie it, and then bless it as well:

	sub MyClass::new {
		my $class = ref($_[0]) || $_[0];
		tie my %hash, Tie::SecureHash;
		my $self = bless \%hash, $class;
	
		# initialization of attrs here
			
		return $self;
	}
	
Because securehashes are principally intended as object
implementations, the Tie::SecureHash module makes process easier by
providing the method Tie::SecureHash::new. When called with a single
argument, this method creates a new securehash (i.e. ties an ordinary
anonymous hash to the Tie::SecureHash package) and then blesses it
into the class named by argument (or into the same class as the
argument, if it's an object reference). That simplifies MyClass::new
to this:

	sub MyClass::new {
		my $self = Tie::SecureHash->new($_[0]);
			
		# initialization of attrs here
			
		return $self;
	}
	

=head2 Declaring securehash entries
	
Both versions of MyClass::new shown above leave space for
initialization. That's because the various entries of a securehash
have to be explicitly "declared" before they can be used. In other
words, securehash entries aren't autovivifying.

This may seem inconvenient at first, but it actually saves an
inordinate amount of time and effort tracking down "spelling bugs"
like this:

	package Disk::Recovery;
	
	sub new {
		my ($class, @files) = @_;
		bless {
			_retrieved  => [ @files ],
			_attempts   => 0,
			_wierd_data => undef,
		}, $class;
	}
	
	sub report {
		print "Made $self->{_attempts} attempts to recover:\n";
		print "\t$_\n" foreach (@{self->{retreived}})
		print "Failed (weird data)\n" if $self->{_weird_data};
	}
	
Unlike the regular hash in the above example, the entries of a
securehash can't be accessed until they've been "created". A specific
entry is created by referring to it using a qualified key, which is a
key string consisting of any characters except ':', preceded by a
standard Perl package qualifier. The following table illustrates some
typical qualified keys:

	Qualified key		Actual key	Qualifier
	=============		==========	=========
	'Class::key		'key'		'Class::'
	'Class::a key'		'a key',	'Class::'
	'My::CD::_tracks'	'_tracks'	'My::CD::'
	'Railway::_tracks'	'_tracks'	'Railway::'
	'Crypt::__passwd'	'__passwd'	'Crypt::'
	'main::key_berm'	'key_berm'	'main::'
	'::key_berm'		'key_berm'	'main::'


Each qualifier indicates the package that "owns" the key. Hence, the
first two keys above are owned by class Class and the last two by the
main package.

Qualified keys that have the same key but different qualifiers (for
example, C<'Railway::_tracks'> and C<'My::CD::_tracks'>) are treated as
being distinct, even if they label two entries in the same securehash.

Typically, entries in a securehash are created by referring to their
fully-qualified names at some point in a class's constructor:

	sub MyClass::new {
		my $self = Tie::SecureHash->new($_[0]);
			
		$self->{MyClass::attr1}  = $_[1];
		$self->{MyClass::_attr2} = $_[2];
		$self->{MyClass::__attr3}= $_[3];
			
		return $self;
	}
        
In this case, the entries with the keys C<"attr1">, C<"_attr2">, and
C<"__attr3"> are all "owned" by the class MyClass. For reasons that will
be made clear in the next section, an entry must be declared within
its owner's package. In practice, that means that the qualifier for
any entry declaration will always be the name of the current package,
as in the example above.

Key qualifiers are only required during the creation of entries (and
occasionally to resolve ambiguities). After the declarations, they can
usually be ignored:

	sub MyClass::set_attr2 {
		my ($self, $newval) = @_;
		$self->{_attr2} = $newval if @_>1;
	}
        
though using the fully qualified key is always acceptable:

	sub MyClass::set_attr2 {
		my ($self, $newval) = @_;
		$self->{MyClass::_attr2} = $newval if @_>1;
	}
        
=head2 Easier initialization
        
It's annoying to have to repeat the same class name when declaring
each attribute in the constructor, so Tie::SecureHash allows
Tie::SecureHash::new to take extra parameters which declare attributes
without individual qualifiers. Or rather, the qualifier for each
attribute passed to C<new> is assumed to be the class name that is passed
as the first argument.

For example, the constructor for MyClass could also be written like
this:

	sub MyClass::new {
		my $self = Tie::SecureHash->new($_[0],
						attr1   => $_[1],
						_attr2  => $_[2],
						__attr3 => $_[3],
		);
	}
        
This is the only way that entries can be declared without an explicit
qualifier.

=head2 Access constraints
        
Securehashes use an extension of a common Perl custom -- underscoring -- to
determine the accessibility of their various entries. In Perl, a
leading underscore in the key of an entry suggests that the particular
entry is "not for public use". Tie::SecureHash formalizes that idea by
treating any entry whose key begins with a single underscore as being
inaccessible outside its owner's class hierarchy. In other words, an
underscored key indicates a "protected" method.

Tie::SecureHash treats keys that begin with two (or more) underscores
even more carefully. The entries for such keys are only accessible
from code in their owner's package and in the same file as they were
originally declared. In other words, a double underscored key
indicates a "private" and "pseudo-lexical" key.

The only other possibility is a key with no leading underscore.
Predictably, no underscore indicates that an entry is "public" and
universally accessible.

This is reasonably consistent with existing Perl conventions about key
naming, but the important difference is that securehashes enforce the
convention at run-time. If a doubly-underscored key is accessed
outside its owner's package or its declaration file, an exception is
immediately thrown. The same thing happens if a singly-underscored key
is accessed outside its native class hierarchy. For example:

        package Derived::Class;
        @ISA = qw( MyClass );
        
	sub dump {
		my ($self) = @_;
		print $self->{attr1};    # okay
		print $self->{_attr2};   # okay
		print $self->{__attr3};  # error
	}
        
The first C<print> is okay because the lack of a leading underscore
indicates that C<'attr1'> is a public attribute, accessible from any
package. The second C<print> is okay too because the single leading
underscore indicates that C<'_attr2'> is a protected attribute,
accessible for any package in Class's hierarchy. But the last C<print>
tries to access an attribute with two leading underscores, causing the
exception:

        Private key 'MyClass::__attr3' of tied SecureHash
        is inaccessible from package Derived::Class.
        
Likewise, an access attempt such as:

        package main;
        my $obj = MyClass->new();
        print $obj->{_attr2};
        
would die with the message:

        Protected key 'MyClass::_attr2' of tied SecureHash
        is inaccessible from package main
        
(unless C<main> inherits from C<MyClass>, of course).

Access constraints also apply to the functions C<each>, C<keys>, C<values>,
and C<delete>, when applied to securehashes. A key will only be iterated,
listed, or deleted if it is accessible at the point where the
operation is invoked.

This also has implications for direct assignment to a securehash. A
statement such as:

        %securehash = ();
        
is equivalent to a series of C<delete> operations, and hence will only
succeed if every key in the securehash is accessible from that point.
If any key is inaccessible, an exception will be thrown (and the
securehash will be unchanged).

Another difficulty with reassigning a securehash is that every new key
being assigned must be appropriately qualified with the name of the
current package. In other words, the standard securehash entry
declaration rules still apply. For example:

        package SomeClass;
	%securehash = (
		attr1 => $val1,
		attr2 => $val2,
	);
        
will throw an exception because the keys C<'attr1'> and C<'attr2'> don't
exist in the newly-cleared C<%securehash>. To successfully reinitialize
the securehash, each new key requires a fully qualified name:

        package SomeClass;
	%securehash = (
		SomeClass::attr1 => $val1,
		SomeClass::attr2 => $val2,
	);
        
       
=head2 Ambiguous keys in a securehash
        
The ability to access securehash entries by unqualified keys is an
important convenience. It can also be a useful programming technique
when using inheritance, since it provides "polymorphic" attributes
(see below). But it creates problems under some circumstances.

The convenience aspect is obvious. Requiring that securehash keys
always be fully qualified would flout the cardinal virtue of Laziness.
No-one would want to use a securehash if they always had to write
C<$self-E<gt>{MyClass::__attr3}>, instead of just C<$self-E<gt>{__attr3}>. In most
cases, each attribute of an object will be uniquely named, so each
securehash will contain only a single matching unqualified key. The
qualifier would be redundant and annoying.

Inheritance, however, brings a difficulty known as the "data
inheritance problem". When one class inherits from another, it's
all too easy to accidentally reuse the name of a base class attribute
in a derived class. For example:

        package Settable;
        $VERSION = 1.00;        #uses normal hashes
        
	sub new {
		my ($class, $is_set) = @_;
		my $self = {_set => $is_set};
		bless $self, $class;
	}
        
	sub set {
		my ($self) = @_;
		# access Settable's _set attr
		$self->{_set} = 1;
	}
        
        package Set;
        @ISA = qw( Settable );
        
	sub new {
		my ($class, %items) = @_;
		my $self = $class->SUPER::new();
		$self->{_set} = { %items }
		# Oops!
	}
        
	sub list {
		my ($self) = @_;
		print keys %{$self->{_set}};
		# Err...was that Set's '_set'
		# or Settable's '_set'?
	}
        
The problem is both Settable and Set want to use a C<'_set'> entry, but
Set objects have to share the same hash as their Settable base parts,
and hence there can be only one such entry.

The use of qualified keys in a securehash solves the problem (in fact,
it's the same solution as suggested in Perl Cookbook):

        package Settable;
        $VERSION = 2.00;        #uses securehashes
        
	sub new {
		my ($class, $set) = @_;
		my $self = Tie::SecureHash->new($class);
		$self->{Settable::_set} = $set;
		return $self;
	}
        
        
	sub set {
		my ($self) = @_;
		$self->{Settable::_set} = 1;
		# Definitely Settable's _set
	}
        
        package Set;
        @ISA = qw( Settable );
        
	sub new {
		my ($class, %items) = @_;
		my $self = $class->SUPER::new();
		$self->{Set::_set} = { %items };
		# Different key so no "collision"
	}
        
	sub list {
		my ($self) = @_;
		print keys %{$self->{Set::_set}};
		# Definitely Set's _set
	}
        
But securehashes are even smarter than that. Any qualifier/key
combination that is unique creates an entry whose unqualified key is
unique within its owner's namespace. So it's also possible to write:

        package Settable;
        $VERSION = 3.00;        #uses securehashes
        
	sub new {
		my ($class, $set) = @_;
		my $self = Tie::SecureHash->new($class);
		$self->{Settable::_set} = $set;
		return $self;
	}
        
	sub set {
		my ($self) = @_;
		$self->{_set} = 1;
		# Definitely Settable's '_set' (!)
	}
        
        package Set;
        @ISA = qw( Settable );
        
	sub new {
		my ($class, %items) = @_;
		my $self = $class->SUPER::new();
		$self->{Set::_set} = { %items };
		# Different key so no "collision"
	}
        
	sub list {
		my ($self) = @_;
		print keys %{$self->{_set}};
		# Definitely Set's _set (!)
	}
        
The unqualified keys are unambiguous because the Tie::SecureHash
module keeps track of where an access was requested, and works out
which key was intended from that context. When the C<Set::list> accesses
the C<'_set'> key, it probably wants the entry for C<'Set::_set'>, not
C<'Settable::_set'>. The securehash is aware of the context of the access
and returns the correct attribute.

Another way of looking at it is to think of securehash entries that
are defined in a base class as being "hidden" by derived class entries
of the same name (just like inherited attributes are in most other
object-oriented languages). Of course, if the inherited entry is
needed in a derived class method, it can still be accessed by fully
qualifying it:

	sub Set::list {
		my ($self) = @_;
		print keys %{$self->{_set}}
		if $self->{Settable::_set};
	}
        
That's not to say that a securehash can always correctly guess the
intended entry for an unqualified key. Consider the following two
classes:

        package Chemical;
        
	sub new {
		my ($class, $chemname) = @_;
		Tie::SecureHash->new($class, name => $chemname);
	}
        
        package Medicine;
        @ISA = qw( Chemical );
        
	sub new {
		my ($class, $medname, $chemname) = @_;
		my $self = Chemical->new($class, $chemname);
		$self->{Medicine::name} = $medname;
		return $self;
	}
        
Within the Chemical class, the unqualified public key C<'name'> will
always be assumed to be referring to C<'Chemical::name'>. Similarly,
inside any of Medicine's methods, the same key is unambiguously
resolved to C<'Medicine::name'>. But what about accesses from the main
package? For example:

        package main;
        my $medicine =  Medicine->new("Dydroxifen","dihydrogen oxide");
        print $medicine->{name};
        
Since the C<'name'> entry isn't being accessed from a method of either
class, there's no way to decide which entry was intended.
Tie::SecureHash resolves the ambiguity by immediately throwing an
exception.

The solution is to explicitly qualify any ambiguous case:

        print $medicine->{Medicine::name};
        
Problems of a similar type occur with protected keys as well, whenever
a class inherits from two or more classes. If both classes use a
protected attribute of the same name then, in a class than derives
from both, it's impossible to tell which inherited attribute was
intended:

        package Dessert::Topping;
        
        sub new { Tie::SecureHash->new($_[0], _shaken => 0) }
        
        sub shake { $_[0]->{_shaken} = 1 }
        
        
        package Floor::Wax;
        
        sub new { Tie::SecureHash->new($_[0], _shaken => 0 ) }
        
        sub shake { $_[0]->{_shaken}++ }
        
        
        package Jiffy::Whip;
        @ISA = qw(Dessert::Topping Floor::Wax);
        
        sub shaken { $_[0]->{_shaken} }     # Dessert::Topping's '_shaken'
					    # orFloor::Wax's '_shaken'?
        
Once again, since it can't decide which of the two attributes was
intended, Tie::SecureHash simply throws an exception.

=head2 Debugging a securehash
        
In a more complicated hierarchy than the ones shown above, ambiguities
can be quite difficult to detect and defuse. The Tie::SecureHash
module provides a method (named C<debug>) that can be called to dump the
contents of a securehash to C<STDERR>. The debug method can be called on
any securehash -- regardless of the class into which it's been blessed --
with an explicit method call:

	sub Jiffy::Whip::shaken {
		my ($self) = @_;
		$self->Tie::SecureHash::debug();   # Find the source...
		return $self->{_shaken};           # ...of this problem:
	}
        
Tie::SecureHash::debug reports the current location details (package,
file, line and subroutine) and the key and value of each entry of the
securehash, categorized by owner. More importantly, debug reports the
accessibility of each entry at the point where it was called (either
"accessible", "inaccessible", or "ambiguous") and explains why.

=head3 More Debugging

Sometimes you want to disable Tie::SecureHash's features.  See the
CPAN module L<Tie::InSecureHash> for one approach.

=head2 "Fast" securehashes
        
Securehashes provide an easy means of controlling the accessibility of
object attributes on a per-attribute basis. Unfortunately, that ease
and flexibility comes at a cost. For a start, accessing the entries of
any kind of tied hash is significantly slower that for untied hashes,
often taking 5 to 10 times as long per access. On top of that
performance hit, securehashes have to perform some moderately
expensive tests (involving the C<Universal::isa> subroutine) before they
can grant access to an entry. These tests can double the cost again,
so accesses to securehashes are often 10 and 20 times slower than to
untied hash. That makes the use of securehashes impractical in most
production code.

Fortunately, production code doesn't actually need the security of
encapsulation. That's because all that checking of access restrictions
is only actually required when a piece of code incorrectly attempts to
violate those restrictions. Since production code is always thoroughly
tested (ahem!), such bugs will have been caught and eliminated, so the
checks are redundant. In other words, if no one can ever break the
law, you no longer need any police to enforce it.

Thus, the solution is to develop the application using Tie::SecureHash
to enforce proper encapsulation, test it thoroughly to ensure that
there are no improper accesses anywhere in the code, and then optimize
the final code by converting every securehash to a normal hash.

Because a securehash's interface mimics the interface of a regular
hash, converting from securehashes to the regular kind is surprisingly
easy. It's not necessary to change any of the code that accesses a
securehash, only the code that creates it. In fact, that's exactly
what encapsulation is all about: hiding implementation details behind
a standard interface so that client code doesn't have to worry when
those details change.

Of course, in the typical large application where encapsulation is
most useful, hunting for every situation where a securehash is created
and then replacing it with a regular hash could still be
time-consuming and error-prone. Fortunately, even that isn't
necessary.

Tie::Securehash provides a special "fast" mode, in which a call to
Tie::SecureHash::new returns a reference to an ordinary hash, rather
than to a securehash. Hence, in "fast" mode, there's no need to
replace any code like:

        $self = Tie::SecureHash->new($_[0]);
        
because it correctly adjusts its behaviour automatically.

Of course, that doesn't solve the problem of any "raw" tie-ing:

        tie %$self, Tie::SecureHash;
        
but that's just another reason to use Tie::SecureHash::new instead.
Indeed, in "fast" mode, Tie::SecureHash generates a warning whenever a
raw tie such as this is used.

"Fast" mode is enabled by importing the entire module with an extra
argument:

        use Tie::SecureHash "fast";
        

=head2 "Strict" securehashes
        
This "develop-with-restrictions-then-run-without-them" approach works
well, but there are two caveats: C<Tie::SecureHash::new> must always be
used to create securehashes, and unqualified keys can never be used to
access them.

The need to use C<Tie::SecureHash::new> was explained above:
C<Tie::SecureHash::new> knows about "fast" mode and can adjust for it,
but the in-built C<tie> function doesn't and can't.

The second caveat imposes a more significant restriction. One of the
useful features of a securehash is that, once an entry has been
declared with its full qualifier, any code can refer to it without the
qualifier and expect the securehash to do the right thing in all
unambiguous cases. However, when the securehash is replaced with a
regular hash, that "do what I mean" intelligence disappears. That can
lead to subtle bugs, because regular hashes autovivify and will
happily create unrelated entries when both qualified and unqualified
versions of a key are used.

These two restrictions are not particularly onerous, but they can be
difficult to apply consistently in a large application. To make
conversion to "fast" mode easier, Tie::SecureHash offers another mode,
called "strict". Like "fast" mode, this mode can be invoked by
importing the module with the appropriate argument:

        use Tie::SecureHash "strict";
        
In "strict" mode, securehashes control access in their normal way,
except that they also produce warnings whenever a hash is explicitly
tied to Tie::SecureHash, and whenever an unqualified key is used to
access a securehash. Thus, code that uses securehashes and runs
without warnings in "strict" mode is guaranteed to have the same
behaviour in "fast" mode.

=head2 'Dangerous' securehashes

Dangerous mode is an experimental mode where you get much of the speedup
with safe mode but where your tests aren't good enough to make fast mode
reliable.  If you start in strict and dangerous mode you'll get warnings
about problematic entries.  I would imagine if the code is 'strict
dangerous' warnings clean, then you have a good chance that fast mode will
work.  Dangerous B<will not> work correctly in some multiple inheritance
scenarios, it's very much up to the existing structure of your code.  This
mode is called 'dangerous' for a reason.  Caveat emptor.

You can also pass in 'loud' as well as dangerous for the ultimate in
logging your SecureHash's behaviour.  'loud' also implies 'strict'.

=head2 The formal access rules

The access rules for a securehash are designed to provide secure
encapsulation with minimal inconvenience and maximal intuitiveness.
However, to produce this appearance of intelligence, the formal access
rules are quite complicated...

=over 

=item All entries

=over

=item *

No entry for an unqualified key is autovivifying. Each entry must
be declared before it's used. Qualified keys do autovivify their
entry, so an entry may be declared as part of its initial use.

=item *

The key of each entry must be explicitly qualified (in the form
C<"I<owner>::I<key>">) when entry is declared.

=item *

An entry is owned by the package whose name was used as the
explicit qualifier in its declaration.

=item *

Entries must be declared within of their owner's package.

=item *

An unqualified key is always interpreted as referring to the key
owned by the current package, if such a key exists, no matter how
many other accessible matching keys the hash may also contain.

=item *

Otherwise, accesses through an unqualified key throw an exception
if the number of accessible matching keys in the securehash is not
1 (either "key does not exist" if the number is zero, or "key is
ambiguous" if it is greater than 1).

=item *

A fully qualified key is never ambiguous (though it may be
non-existent, or inaccessible from a particular package).

=back

=item Public entries

=over

=item *

Public accessibility of entries is indicated by their unqualified
key beginning with a character other than an underscore.

=item *

Public entries may be subsequently accessed from any package in
any source file.

=item *

A public entry's key is ambiguous if it is not explicitly
qualified, and there is not a matching key owned by the current
package, and there exist two or more matching unqualified keys
owned by any other packages.

=back

=item Protected entries

=over

=item *

Protected accessibility of entries is indicated by their
unqualified key beginning with a single underscore.

=item *

Protected entries may subsequently be accessed from any package
(C<P>) in any source file, provided that at the point of access, C<P> is
(or inherits from) the entry's owner package (<Owner>). That is, a
protected entry is accessible in any package C<P>, where
C<P-E<gt>isa("Owner")>.

=item *

Protected keys that are declared to be owned by a given package
will "hide" entries with the same unqualified key that are
inherited from parent classes of that package. Any inherited entry
that is hidden in this way is inaccessible from the scope of the
derived class (unless accessed via a qualified key).

=item *

A protected key is ambiguous if it's not explicitly qualified, and
there is not a matching key owned by the current package, and
there exist two or more accessible matching keys owned by two or
more other packages, and those other packages are inherited by the
current package through two distinct inheritance paths.

=back

=item Private entries

=over

=item *

Private accessibility of entries is indicated by their unqualified
key beginning with two or more underscores.

=item *

Private entries can be accessed only from within their owner's
package, and only from the source file in which they were
originally declared.

=item *

Unqualified private keys are never ambiguous. Since private
entries are only ever accessible from a single class, there can be
at most only one accessible matching private key.

=back

=back

=head1 DIAGNOSTICS

=over 4

=item C<Private key %s of tied securehash inaccessible from package %s>

Private keys can only be accessed from their "owner" package. An
attempt was made to access a private key from some other package.

=item C<Private key %s of tied securehash inaccessible from file %s>

Private keys can only be accessed from the lexical scope of the file in which
they were originally declared. An attempt was made
to access a private key from some lexical scope (probably another file, but
perhaps an C<eval>).

=item C<Protected key %s of tied securehash inaccessible from package %s>

Protected keys can only be accessed from their "owner" package and any
of its subclasses. An attempt was made to access a protected key from
some package not in the owner's inheritance hierarchy.


=item C<Entry for key %s of tied securehash cannot be created from package %s>

Keys must be declared from within the lexical scope of their owner's package.
In other words, the qualifier for a key declaration must be the same as the
current package. An attempt was made to declare a key from some package other
than its owner.

=item C<Private key %s does not exist in tied securehash>

Securehash keys are not autovivifying; they must be declared using a
fully qualified key before they can be used. An attempt was made to
access or assign to an unqualified private key (one with two
leading underscores), before the corresponding fully qualified key
was declared.

=item C<Protected key %s does not exist in tied securehash>

Securehash keys are not autovivifying; they must be declared using a
fully qualified key before they can be used. An attempt was made to
access or assign to an unqualified protected key (one with a single
leading underscore), before the corresponding fully qualified key
was declared.

=item C<Public key %s does not exist in tied securehash>

Securehash keys are not autovivifying; they must be declared using a
fully qualified key before they can be used. An attempt was made to
access or assign to an unqualified public key (one with no leading
underscore), before the corresponding fully qualified key was declared.

=item C<Ambiguous key %s (when accessed from package %s). Could be: %s>

An unqualified key was used to access the securehash, but it was ambiguous
in the context. The error message lists the set of fully qualified keys that
might have matched.

=item C<Invalid key %s>

An attempt was made to access the securehash (or declare a key) through an
improperly formatted key. This almost always means that the qualifier isn't a
valid package name.

=item C<%s can't be both "strict" and "fast">

Tie::SecureHash detected that both the $Tie::SecureHash::strict and


=item C<Accessing securehash via unqualified key %s will be unsafe in 'fast' mode. Use %s::%s>

This warning is issued in "strict" mode if the environment variable
UNSAFE_WARN is true, and points out an access attempt which will break
if the code is converted to "fast" mode.

=item C<Tie'ing a securehash directly will circumvent 'fast' mode. Use Tie::SecureHash::new instead>

This warning is issued in "strict" mode, and points out an explicit
C<tie> to the Tie::SecureHash module. Hashes tied in this way will not
speed up under "fast" mode.

=item C<Tie'ing a securehash directly should never happen in 'fast' mode. Use Tie::SecureHash::new instead>

This warning is issued in "fast" mode, and points out an explicit
C<tie> to the Tie::SecureHash module. Hashes tied in this way will still
be slow. This diagnostic can be turned off by setting $Tie::SecureHash::fast to
any value other than 1.

=item C<Unable to assign to securehash because the following existing keys are inaccessible from package %s and cannot be deleted: %s>

=back

An attempt was made to assign a completely new set of entries to a securehash.
Typically something like this:

	%securehash = ();

This doesn't work unless all the existing keys are accessible at the point of
the assignment.



=head1 REPOSITORY

L<https://github.com/singingfish/perl-Tie-SecureHash.git>

=head1 AUTHOR

Damian Conway (damian@cs.monash.edu.au)

"Dangerous mode" and 'better' test coverage Kieren Diment <zarquon@cpan.org>

=head1 BUGS AND IRRITATIONS

There are undoubtedly serious bugs lurking somewhere in this code :-)
Bug reports and other feedback are most welcome.

=head1 COPYRIGHT

        Copyright (c) 1998-2000, Damian Conway. All Rights Reserved.
      This module is free software. It may be used, redistributed
      and/or modified under the terms of the Perl Artistic License
           (see http://www.perl.com/perl/misc/Artistic.html)

