# Copyright (c) 1999-2000, James H. Woodyatt
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in
#   the documentation and/or other materials provided with the
#   distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE. 

require 5.005;
use strict;

=pod

=head1 NAME

Conjury::Core - the foundation of Perl Conjury

=head1 SYNOPSIS

  use Conjury::Core;

  tie I<HASH>, Conjury::Core::Journal, F<filename>;

  $spell = Conjury::Core::Spell->new ( I<HASH> );

  cast_warning ( I<LIST> );
  cast_error ( I<LIST> );

  [$spell =] name_spell ( I<HASH> );

  @spells = fetch_spells ( I<HASH> );

  $spell = Conjury::Core::deferral ( I<HASH> );

  $spell = Conjury::Core::filecopy ( I<HASH> );

  $spell = Conjury::Core::dispell ( I<HASH> );

=head1 DESCRIPTION

The F<Conjury::Core> module is the foundation of the Perl Conjury software
construction framework.  You need to understand this module before you design
other Perl Conjury modules, especially application-specific ones referenced in
your F<Conjury.pl> files.

In addition to some exported functions, there are four Perl packages in the
C<Conjury::Core> namespace: Conjury::Core::Context, Conjury::Core::Journal and
Conjury::Core::Spell.

=cut

my (%prototype, %validator);

package Conjury::Core;

BEGIN {
    require Conjury::Core::Prototype;
    use Exporter ();

    use vars qw($VERSION @ISA @EXPORT_OK @EXPORT %EXPORT_TAGS);

    $VERSION = 1.004;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(%Option $Top_Context $Current_Context %Context_By_Directory
		    %Spell_By_FileSpec &filecopy &deferral &dispell);
    @EXPORT = qw(&cast_warning &cast_error &name_spell &fetch_spells);
}

use subs qw(cast_warning cast_error execute name_spell fetch_spells
	    deferral filecopy dispell);
use vars qw(%Option $Top_Context $Current_Context %Context_By_Directory
	    %Spell_By_FileSpec);

%Option = ( );
$Top_Context = undef;
$Current_Context = undef;
%Context_By_Directory = ( );
%Spell_By_FileSpec = ( );

BEGIN {
    $validator{scalar_or_hash} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a SCALAR or a HASH'
	  unless (defined $x and (!ref $x or ref $x eq 'HASH'));
	return $y;
    };

    $validator{scalar_or_array_of_scalar} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a SCALAR or an ARRAY of SCALAR'
	  unless ((defined $x and !ref $x)
		  or (ref $x eq 'ARRAY' and !(grep ref, @$x)));
	return $y;
    };

    $validator{scalar_or_code} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a SCALAR or CODE'
	  unless (defined $x and  (!ref $x or ref $x eq 'CODE'));
	return $y;
    };

    $validator{scalar_array_or_code} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a SCALAR, ARRAY of SCALAR, or CODE'
	  unless (defined $x
		  and (!ref $x
		       or (ref $x eq 'ARRAY' and !(grep ref, @$x))
		       or ref $x eq 'CODE'));
	return $y;
    };

    $validator{context_object} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a Conjury::Core::Context object'
	  unless (ref $x and $x->UNIVERSAL::isa('Conjury::Core::Context'));
	return $y;
    };

    $validator{spell_object} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a Conjury::Core::Spell object'
	  unless (ref $x and $x->UNIVERSAL::isa('Conjury::Core::Spell'));
	return $y;
    };

    $validator{array_of_2_scalars} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not an ARRAY of 2 SCALAR values, i.e. [ user, group ]'
	  unless (ref $x eq 'ARRAY' and @$x == 2 and !(grep ref, @$x));
	return $y;
    };

}


package Conjury::Core::Context;

use Conjury::Core qw(%Option $Top_Context $Current_Context
		     %Context_By_Directory %Spell_By_FileSpec &cast_error);
use File::Spec;
use File::Basename qw(fileparse);
use Cwd qw(chdir getcwd abs_path);
use Carp qw(croak);

use vars qw($AUTOLOAD %By_Dir);

=pod

=head2 Conjury::Core::Context

A "context" is an association between a directory within the source file
hierarchy and the spells defined by the Conjury.pl file there.  (The name
of the spell definition file may differ on your platform.  See L<Conjury>.)

A C<Conjury::Core::Context> object encapsulates this association.  It should be
treated like a structure with named members.  Most of its methods are not
really for public use.

The 'Directory' method returns the name of the directory associated with the
context.

The C<$Current_Context> package variable always contains a reference to the
current context object. The C<$Top_Context> package variable always contains a
reference to the context at the top of the source file hierarchy.

=cut

sub _new_f()    { __PACKAGE__ . '::new' }

BEGIN {
    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Directory => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Spells_By_Name => \&Conjury::Core::Prototype::validate_hash);
    $proto->optional_arg
      (Default_Spells => \&Conjury::Core::Prototype::validate_code);
    $prototype{_new_f()} = $proto;
}

my $compile_index = 0;

my $compile_spells_file = sub {
    my $self = shift;

    my $verbose = exists $Option{'verbose'};
    my $directory = $self->{Directory};

    $Context_By_Directory{$directory} = $self;

    my @candidates = ( );
    @candidates = qw(Conjury.pl)
	if $^O =~ /\A(MacOS|AmigaOS|MSWin32|darwin)\Z/;
    @candidates = qw(CONJURY.PL) if $^O eq 'VMS';
    @candidates = qw(conjury.pl Conjury.pl) if @candidates == 0;

    my $filename = undef;
    my $full_filename = undef;
    for my $candidate (@candidates) {
	my $full_candidate = File::Spec->catfile($directory, $candidate);

	if (-f $full_candidate) {
	    warn
		"$0 warning: Found both '$filename' and '$candidate' in",
		" $directory --\n\tusing '$candidate'"
		    if (defined($filename));
    
	    $filename = $candidate;
	    $full_filename = $full_candidate;
	}
    }

    if (!defined($filename)) {
	my $message = (@candidates > 1) ? 'No files ' : 'No file ';
	$message .= join(' or ', (map "'$_'", @candidates));
	die "$0: $message in '$directory'.\n";
    }

    open SPELLSFILE, "$full_filename"
      || die "$0 error: Unable to read $full_filename ($!)";
    my $spellsfile = join '', <SPELLSFILE>;
    close SPELLSFILE;

    ++$compile_index;

    my @save = $self->push;
    eval "package Conjury::Core::Tmp${compile_index}; $spellsfile";
    my $error = $@;
    $self->pop(@save);

    if ($error) {
	print $error;
	print "$0 error: Compiling $full_filename failed.\n";
	exit -1;
    }

    undef;
};

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    my $directory = $arg{Directory};
    $directory = File::Spec->curdir unless (defined $directory);
    my %spells_hash;
    %spells_hash = ( %{$arg{Spells_By_Name}} )
      if (exists $arg{Spells_By_Name});
    my @spells_list;
    @spells_list = @{$arg{Default_Spells}} if (exists $arg{Default_Spells});

    my $self = { };
    bless $self, $class;

    $self->{Directory} = $directory;
    $self->{Spells_By_Name} = \%spells_hash;
    $self->{Default_Spells} = \@spells_list;

    $Top_Context = $self unless defined($Top_Context);

    &$compile_spells_file($self);

    return $self;
}

sub AUTOLOAD {
    my $field = $AUTOLOAD;
    $field =~ s/.*:://;
    my ($self, $set) = @_;

    croak __PACKAGE__, "::$field-- argument mismatch"
	unless ((@_ == 1 || @_ == 2) && ref($self));
    croak __PACKAGE__, "::$field-- no field exists"
	unless exists($self->{$field});
    
    $self->{$field} = $set if defined($set);
    return $self->{$field};
}

sub DESTROY { }

sub push {
    my $self = shift;
    croak __PACKAGE__, '::push-- argument mismatch'
      unless (!@_ && ref($self));

    return ( undef, undef )
      if (defined($Current_Context) && $self == $Current_Context);

    my $old_context = $Current_Context;

    my $old_directory
      = defined($old_context) ? $old_context->Directory : getcwd;

    my $new_directory = $self->{Directory};

    print "Context[>>]: $new_directory\n" if exists($Option{'verbose'});
    chdir $new_directory
	|| cast_error "Unable to change to directory '$new_directory'.";

    $Current_Context = $self;

    return ($old_directory, $old_context);
}

sub pop {
    croak __PACKAGE__, '::pop-- no context to pop'
	unless defined($Current_Context);

    my ($self, $new_directory, $new_context) = @_;
    croak __PACKAGE__, '::pop-- argument mismatch'
	unless ((@_ == 3)
		&& (ref($new_context) || !defined($new_context))
		&& (!ref($new_directory) || !defined($new_directory)));
    return undef if !defined($new_directory);

    my $old_directory = $Current_Context->{Directory};

    $Current_Context = $new_context;

    print "Context[<<]: $old_directory\n" if exists($Option{'verbose'});
    chdir $new_directory
	|| cast_error "Unable to change to directory '$new_directory'.";

    undef;
}

sub in_context {
    my $self = shift;
    croak __PACKAGE__, '::in_context-- argument mismatch'
	unless (ref($self) && @_ > 0);
    croak __PACKAGE__, '::in_context-- array context required'
	unless (@_ == 1 || wantarray);

    my ($dummy,$dirname)
	= fileparse(File::Spec->catfile($self->{Directory}, 'x'));
    my @result = map { $_ = $1 if /^$dirname(.*)$/o } @_;
    return wantarray ? @result : $result[0];
}


package Conjury::Core::Journal;

use Conjury::Core qw(%Option $Current_Context &cast_error &cast_warning);
use Carp;

use vars qw($fetch_hash $store_hash);

=pod

=head2 Conjury::Core::Journal

A "journal" is a file that contains the persistent data that Perl Conjury uses
to record the signatures of actions as they are performed, so that they can be
skipped on subsequent runs when the signature for products are known not to
have changed.

It probably should not be implemented as a tied hash, but it is.  It should be
treated like an opaque object.

Create a journal using the C<tie> builtin and specifying the name of the file
to write.

=cut

my $fetch_hash = sub {
    my $filename = shift;

    my %by_name = ( );
    my ($signature, $name);

    my $verbose = exists $Option{'verbose'};

    if (open JOURNAL, $filename) {
	print "Journal: Reading $filename ...\n" if $verbose;

	while (<JOURNAL>) {
	    chomp;
	    my ($operation, $signature, $name) = split('\s+', $_, 3);
	    next unless (defined($signature) && defined($name));
	    if ($operation eq '+') {
		$by_name{$name} = $signature;
		print "  + $name\n" if $verbose;
	    }
	    elsif ($operation eq '-') {
		delete $by_name{$name};
		print "  - $name\n" if $verbose;
	    }
	}

	close JOURNAL;
    }
    elsif ($verbose) {
	cast_warning "Failed to read journal $filename";
    }

    return \%by_name;
};

my $store_hash = sub {
    my ($filename, $by_name) = @_;

    my $verbose = exists $Option{'verbose'};

    unlink $filename
	|| cast_warning "Failed to unlink journal $filename";
    open JOURNAL, ">$filename"
	|| cast_error "Failed to write journal $filename";

    print "Journal: Writing $filename ...\n" if $verbose;

    unless (!keys %$by_name) {
	my ($name, $signature);
	while (($name, $signature) = each %$by_name) {
	    next unless (defined($signature));
	    print JOURNAL "+ $signature $name\n";
	    print "  $name\n" if $verbose;
	}
    }

    close JOURNAL;
};

sub TIEHASH {
    my ($class, $filename) = @_;
    croak __PACKAGE__, '::TIEHASH-- argument mismatch'
	unless (@_ == 2 && !ref($filename));

    $filename = File::Spec->catfile($Current_Context->Directory, $filename)
	unless File::Spec->file_name_is_absolute($filename);

    my $by_name = &$fetch_hash($filename);
    &$store_hash($filename, $by_name);

    my $self = { };

    $self->{Filename} = $filename;
    $self->{By_Name} = $by_name;

    return bless $self, $class;
}

sub STORE {
    my ($self, $key, $value) = @_;

    croak __PACKAGE__, '::STORE-- argument mismatch'
	unless (@_ == 3 && defined($key) && !ref($key) && ($key ne '')
		&& defined($value) && !ref($value) && ($value !~ /\s/));

    $self->{By_Name}->{$key} = $value;

    my $file = $self->{Filename};
    if (open JOURNAL, ">>$file") {
	print JOURNAL "+ $value $key\n";
	close JOURNAL;
    }
    else {
	my $filename = $self->{Filename};
	cast_error "File to append journal $filename";
    }

    return $value;
}

sub FETCH {
    return $_[0]->{By_Name}->{$_[1]};
}

sub FIRSTKEY {
    my $by_name = $_[0]->{By_Name};
    my $a = scalar keys %$by_name;
    return each %$by_name;
}

sub NEXTKEY {
    return each %{$_[0]->{By_Name}};
}

sub EXISTS {
    return exists $_[0]->{By_Name}->{$_[1]};
}

sub DELETE {
    my ($self, $key) = @_;

    croak __PACKAGE__, '::DELETE-- argument mismatch'
	unless (@_ == 2 && defined($key) && !ref($key) && ($key ne ''));

    my $result = $self->{By_Name}->{$key};
    delete $self->{By_Name}->{$key};

    my $file = $self->{Filename};
    if (open JOURNAL, ">>$file") {
	print JOURNAL "- - $key\n";
	close JOURNAL;
    }
    else {
	my $filename = $self->{Filename};
	cast_error "File to append journal $filename";
    }

    return $result;
}

sub CLEAR {
    my $self = $_[0];
    my $filename = $self->{Filename};

    unlink $filename
	|| cast_error "Failed to unlink journal $filename";

    $self->{By_Name} = { };
}

sub DESTROY { }


package Conjury::Core::Spell;

use Conjury::Core qw(%Option $Current_Context %Spell_By_FileSpec fetch_spells
		     cast_error);
use Digest::MD5 qw(md5_base64);
use File::Spec;
use Carp qw(croak);

=pod

=head2 Conjury::Core::Spell

A "spell" is an object that encapsulates the action required to perform a task,
typically for constructing or erasing files.  A spell is usually associated
with a list of factors, other spells representing actions that must be taken
first, if the spell is to succeed.

All spells have a profile which is used in computing the signature of the
spell. Before an action is taken for a spell, the signatures of all its factors
are appended to the profile for the spell, then reduced with the MD5
cryptographic hash function to become the signature for the spell.

When a spell creates product files, the names of the files and the signature of
the spell that produced them is journaled to a file.  In this way, if the
signature for a file is found to have changed since it was last journaled,
it is because the spell responsible for creating it has acquired a new profile,
or one of its factors has a new signature.

If a factor of a spell specifies a file not produced by any spells, that file
is treated as a source file, and its modification time is appended to the
profile of the spell which considers it a factor.  In this way, changes to the
modification time of a source file results in a cascading change to the
signature of every spell that references it in its tree of factors.

=cut

sub _new_f()    { __PACKAGE__ . '::new' }

BEGIN {
    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Journal => $validator{scalar_or_hash});
    $proto->optional_arg
      (Factors => \&Conjury::Core::Prototype::validate_array);
    $proto->optional_arg
      (Product => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Action => $validator{scalar_array_or_code});
    $proto->optional_arg
      (Profile => $validator{scalar_or_code});
    $prototype{_new_f()} = $proto;

    use vars qw($AUTOLOAD);
}

=pod

Use the C<Conjury::Core::Spell->new> subroutine to construct a spell object.
The named parameters are all optional, but using some of them implies a
requirement for the use of others.  A spell constructed with no parameters has
no action, no profile, i.e. it generates no effect on the signature of spells
that consider it a factor.

The named parameters of the C<new> method in detail:

=over 4

=item Journal => \%journal

Associates the spell with a journal object.  This is usually not necessary when
the spell has no product files.  Spells that have products should always
journal their signatures, but it is not required.

=item Factors => [ F<factor1>, F<factor2>, ... ]

Specifies the list of factors for the spell.  These may be references to other
spell objects or the names of spells to fetch using the C<fetch_spells>
function.

=item Product => I<filename>

=item Product => [ I<filename1>, I<filename2>, ... ]

Specifies the name of the file, or a list of the names of files, produced by
the action of the spell.  When the spell is created, the names of the products
are stored internally in a global hash available to the C<fetch_spells>
function.

=item Action => I<SCALAR>

=item Action => [ I<PROGRAM>, I<ARG1>, I<ARG2>, ... ]

=item Action => I<CODE>

Specifies the action to take when the spell is invoked.  The first and second
form result in the scalar (or the list of scalars) to be used with the
C<system> builtin function.

The third form is for specifying a closure that takes a reference to the spell
object as its only argument.  If you use a closure, you will be required to
specify a profile for the closure.  This is because you cannot convert a code
block into a string very easily in Perl.

When a spell is invoked, its action is executed in the context in which it was
created.  Actions return boolean true on failure.

=item Profile => I<SCALAR>

=item Profile => I<CODE>

Specifies the profile for an action.  The first form is the simple case,
i.e. the string is used as the profile for an action closure.  You should
provide a profile that uniquely describes the action to take, including the
name of the action function and the values of any parameters used in the
construction of the closure.

The second form is the more complicated case, i.e. the profile is, itself, a
closure.  Closure profiles require no arguments, and they are called during the
invocation phase immediately before the factors are invoked.  The explanation
for why you would want to use this form is tedious, esoteric and best not
presented during dinner.  Hint: C language dependency scanning is one case.

=back

=cut

sub new {
    croak _new_f, '-- no context'
	unless defined($Current_Context);

    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    my $journal = $arg{Journal};
    my $factors_ref = $arg{Factors};
    my @factors = defined($factors_ref) ? @$factors_ref : ();

    my $product_ref = $arg{Product};
    my (@product, @abs_product);
    if (defined($product_ref)) {
	$product_ref = [ $product_ref ] if !ref($product_ref);

	my $context = $Current_Context;
	my $directory = $context->Directory;

	@product = @$product_ref;

	for (@$product_ref) {
	    my $file = $_;
	    $file = File::Spec->catfile($directory, $file)
		unless File::Spec->file_name_is_absolute($file);
	    $file = File::Spec->canonpath($file);

	    croak _new_f, "-- spell exists for $file"
		if exists($Spell_By_FileSpec{$file});

	    push @abs_product, $file;
	}
    }

    my $action = $arg{Action};
    croak _new_f, '-- action required for product'
	unless (!@product || defined($action));

    my $profile = $arg{Profile};
    
    if (defined($action)) {
        if (!ref($action)) {
	    if ($action ne '') {
		my $output = $action;
		$profile = __PACKAGE__ . ' ' . $output
		  unless (defined $profile);

		my $save_action = $action;
		$action = sub {
		    print "$output\n";

		    my $result;
		    $result = system $save_action
			if !exists($Option{'preview'});
		    return $result;
		};
	    }
	    else {
		croak _new_f, '-- empty action scalar';
	    }
	}
	elsif (ref($action) eq 'ARRAY') {
	    if (@$action) {
		my $output = join ' ', (map { /\s/ ? "'$_'" : $_ } @$action);
		$profile = __PACKAGE__ . ' ' . $output
		    unless defined($profile);

		my $save_action = $action;
		$action = sub {
		    print "$output\n";

		    my $result;
		    $result = system @$save_action
			if !exists($Option{'preview'});
		    return $result;
		};
	    }
	    else {
		croak _new_f, '-- empty action array';
	    }
	}
	else {
	    croak _new_f, '-- action requires a profile'
		unless defined($profile);
	}
    }

    $profile = __PACKAGE__ . " $$ $^T" unless defined($profile);

    my $self = { };
    bless $self, $class;

    $self->{Journal} = $journal;
    $self->{Factors} = \@factors;
    $self->{Product} = \@product;
    $self->{Abs_Product} = \@abs_product;
    $self->{Profile} = $profile;
    $self->{Context} = $Current_Context;
    $self->{Action} = $action;
    $self->{Signature} = undef;

    for (@abs_product) {
	$Spell_By_FileSpec{$_} = $self;
    }

    return $self;
}

sub AUTOLOAD {
    my $field = $AUTOLOAD;
    $field =~ s/.*:://;
    my ($self, $set) = @_;

    croak __PACKAGE__, "::$field-- argument mismatch"
	unless ((@_ == 1 || @_ == 2) && ref($self));
    croak __PACKAGE__, "::$field-- no field exists"
	unless exists($self->{$field});
    
    $self->{$field} = $set if defined($set);
    return $self->{$field};
}

sub DESTROY {
    my $self = $_[0];

    my $abs_product = $self->{Abs_Product};
    return unless defined($abs_product);

    for (@$abs_product) {
	delete $Spell_By_FileSpec{$_};
    }
}

sub invoke {
    my $self = $_[0];
    croak __PACKAGE__, '::invoke-- argument mismatch'
	unless (@_ == 1 && ref($self));

    return $self->{Signature} if defined($self->{Signature});

    my $profile = $self->{Profile};
    my $context = $self->{Context};
    my $signature = '';
    my $verbose = exists $Option{'verbose'};

    my $directory = $context->Directory;
    my @save = $context->push;

    print ">> $directory\n" if (!$verbose && defined($save[0]));

    eval {
	$profile = &$profile() if (ref($profile) eq 'CODE');
	cast_error "Profile returned non-scalar"
	  unless (defined($profile) && !ref($profile));

	my $factors = $self->{Factors};
	my $force = exists $Option{'force'};
	my $preview = exists $Option{'preview'};

	if (@$factors) {
	    my @spells;

	    for my $factor (@$factors) {
		my @f_spells;

		if (ref $factor) {
		     @f_spells = ( $factor );
		}
		else {
		    @f_spells = fetch_spells Name => $factor;
		    if (@f_spells) {
			push @spells, @f_spells;
		    }
		    else {
			my @file_stat = stat $factor;
			if (@file_stat) {
			    $profile .= " $factor $file_stat[9]";
			}
			else {
			    cast_error
			      "No spells for '$factor'",
			      "...is it a missing source file?";
			}
		    }
		}

		for my $spell (@f_spells) {
		    push @spells, $spell
		      if ($context == $spell->{Context});
		}
	    }

	    $profile .= ' ';
	    for my $spell (@spells) {
		unless ($spell == $self) {
		    $profile .= $spell->invoke();
		    $force = 1 unless (defined($spell->{Action}));
		}
	    }
	}

	$signature = $profile;
	$signature = md5_base64($signature) if $signature ne '';

	my $product = $self->{Abs_Product};
	my $journal = $self->{Journal};
	my $action = $self->{Action};
    
	if (defined($journal)) {
	    for my $file (@$product) {
                if (exists $journal->{$file}
                    && $journal->{$file} eq $signature
                    && -f $file)
                {
                    $action = undef unless ($force);
                }
	    }
	}

	if (defined($action)) {
	    my $result = &$action($self);
	    cast_error "Action failed (result='$result')" if $result;

	    unless ($preview) {
		for (@$product) {
		    $journal->{$_} = $signature;
		}
	    }

	    $self->{Action} = undef;
	}
    };

    my $exception = $@;
    $context = Conjury::Core::Context->pop(@save);
    die $exception if $exception;

    print "<< $directory\n" if (!$verbose && defined($save[0]));

    $self->{Signature} = $signature;
    return $signature;
}


package Conjury::Core;

use Carp qw(croak);
use Getopt::Long qw(GetOptions);
use File::Basename qw(basename dirname);
use File::Path;
use Cwd qw(abs_path);

=pod

=head2 Exported Functions

The C<name_spell> and C<fetch_spells> functions should probably be moved into
an appropriate Conjury::Core::Xxxxx namespace.  If they stay where they are,
then the contents of C<@EXPORT> should be moved to C<@EXPORT_OK>. It remains
unclear what is the right thing to do here-- but it will be.  It will.

=over 4

=cut

sub _cast_f()	        { __FILE__ . '/cast'		    }
sub _cast_warning_f()   { __PACKAGE__ . '::cast_warning'    }
sub _cast_error_f()     { __PACKAGE__ . '::cast_error'      }
sub _execute_f()	{ __PACKAGE__ . '::execute'	    }
sub _name_spell_f()     { __PACKAGE__ . '::name_spell'      }
sub _fetch_spells_f()   { __PACKAGE__ . '::fetch_spells'    }
sub _deferral_f()       { __PACKAGE__ . '::deferral'	    }
sub _filecopy_f()       { __PACKAGE__ . '::filecopy'	    }
sub _dispell_f()	{ __PACKAGE__ . '::dispell'	    }

BEGIN {
    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Context => $validator{context_object});
    $proto->optional_arg
      (Name => $validator{scalar_or_array_of_scalar});
    $prototype{_cast_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Spell => $validator{spell_object});
    $proto->optional_arg
      (Context => $validator{context_object});
    $proto->optional_arg
      (Name => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Default => \&Conjury::Core::Prototype::validate_scalar);
    $prototype{_name_spell_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Context => $validator{context_object});
    $proto->optional_arg
      (Name => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Require => \&Conjury::Core::Prototype::validate_scalar);
    $prototype{_fetch_spells_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Directory => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Name => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (If_Present => \&Conjury::Core::Prototype::validate_scalar);
    $prototype{_deferral_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $proto->optional_arg
      (File => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Factors => \&Conjury::Core::Prototype::validate_array);
    $proto->optional_arg
      (Directory => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Permission => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Owner => $validator{array_of_2_scalars});
    $prototype{_filecopy_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $proto->optional_arg
      (Factors => \&Conjury::Core::Prototype::validate_array);
    $proto->optional_arg
      (File => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Glob => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Directory => $validator{scalar_or_array_of_scalar});
    $proto->optional_arg
      (Require => \&Conjury::Core::Prototype::validate_scalar);
    $prototype{_dispell_f()} = $proto;
}

my $cast = sub {
    my %arg = @_;
    my $error = $prototype{_cast_f()}->validate(\%arg);
    croak _cast_f, "-- $error" if $error;

    my $context = (defined $arg{Context}) ? $arg{Context} : $Current_Context;

    my $name_arg;
    $name_arg = $arg{Name} if (defined($arg{Name}));
    $name_arg = [ $name_arg ] if (defined($name_arg) && !ref($name_arg));

    my @spells;
    if (@$name_arg > 0) {
	for (@$name_arg) {
	    push @spells, (fetch_spells
			   Context => $context,
			   Name => $_,
			   Require => 1);
	}
    }
    else {
	@spells = fetch_spells Context => $context, Require => 1;
    }

    for my $spell (@spells) {
	$spell->invoke();
    }

    undef;
};

=pod

=item cast_warning

Prints a warning message to the standard output.  Use this function like the
B<print> builtin function.  A prefix is inserted to identify the message as a
warning from the B<cast> utility, and a newline is appended.

=cut

sub cast_warning {
    my $message = join '', @_;
    croak _cast_warning_f, '-- argument mismatch' unless (!ref($message));

    if (defined($Current_Context)) {
	my $directory = $Current_Context->{Directory};
	warn "$0: Warning in context $directory ...\n$0: $message\n";
    }
    else {
	warn "$0: $message\n";
    }
}

=pod

=item cast_error

Prints an error message to the standard output and dies.  Use this function
like the B<die> builtin function.  A prefix is inserted to identify the
message as an error from the B<cast> utility, and a newline is appended.

=cut

sub cast_error {
    my $message = join '', @_; croak _cast_error_f, '-- argument mismatch'
	unless (!ref($message));

    if (defined($Current_Context)) {
	my $directory = $Current_Context->{Directory};
	die "$0: Error in context $directory ...\n$0: $message\n";
    }
    else {
	die "$0: $message\n";
    }
}

sub execute {
    croak _execute_f, '-- already executing'
	if defined($Current_Context);

    my ($topdir, $curdir) = @_;
    croak _execute_f, '-- argument mismatch'
	unless (@_ == 2 && !ref($topdir) && !ref($curdir));

    GetOptions \%Option, qw(verbose force preview define=s%);

    if (exists $Option{'verbose'}) {
	print "Top:\t\t$topdir\n";
	print "Current:\t$curdir\n";

	my $str = 'verbose';
	$str .= ' force' if exists($Option{'force'});
	$str .= ' preview' if exists($Option{'preview'});
	print "Options:\t$str\n";

	if (exists $Option{'define'}) {
	    my $define = $Option{'define'};
	    print "Variables:\t";

	    my $space = '';
	    scalar(keys %$define);

	    my ($name, $value);
	    while (($name, $value) = each %$define) {
		print "$space'$name'='$value'";
		$space = ' ';
	    }

	    print "\n";
	}

	if (@ARGV) {
	    print "Targets:\t", join(' ', (map "'$_'", @ARGV)), "\n";
	}

	print "\nCompiling...\n";
    }

    Conjury::Core::Context->new(Directory => $topdir);
    my $context = $Context_By_Directory{$curdir};
    cast_error "Directory $curdir not referenced." unless defined($context);

    print "\nCasting...\n" if exists($Option{'verbose'});
    &$cast(Context => $context, Name => \@ARGV);
    return 0;
}

=pod

=item name_spell

name_spell
   (Spell => I<spell>,
    Context => I<context>, 
    Name => [ I<name1>, I<name2>, ... ], # array or scalar is okay
    Default => 1)

Assigns names in a context to a spell.  The 'Spell' argument is the only
required argument.  The others are all optional.

If no context is specified, then the current context is assumed.

If the 'Default' argument is specified, or the 'Name' argument is unspecified
or specifies an empty list, then the spell is explicitly assigned to the
list of unnamed spells in the context.  These spells are typically the
'default' spells that are invoked when no names are given to the B<cast>
utility from the command line.

=cut

sub name_spell {
    my %arg = @_;
    my $error = $prototype{_name_spell_f()}->validate(\%arg);
    croak _name_spell_f, "-- $error" if $error;

    my $spell = $arg{Spell};
    my $context = (defined $arg{Context}) ? $arg{Context} : $Current_Context;
    my $name_list;
    $name_list = $arg{Name} if (exists $arg{Name});
    $name_list = [ $name_list ] if (defined $name_list and !ref $name_list);

    my $spelllist = undef;

    if (defined $name_list) {
	my $spellhash = $context->Spells_By_Name;

	for my $name (@$name_list) {
	    $spellhash->{$name} = [ ] unless (exists $spellhash->{$name});
	    $spelllist = $spellhash->{$name};
	    push @$spelllist, $spell;
	}
    }

    if (!defined $spelllist or defined $arg{Default}) {
	$spelllist = $context->Default_Spells;
	push @$spelllist, $spell;
    }

    return $spell;
}

=pod

=item fetch_spells

fetch_spells(Name => I<name>, Context => I<context>, Require => 1)

Returns a list containing references to all the spell objects with the
name in the context.

If the name is not specified, then the list will contain references to all the
unnamed spell objects. You can use a list of names to fetch all the spell
objects for the whole list at once.  A spell will be fetched if its product
matches the specified name, or the spell was explicitly assigned the name with
the name_spell function.

If the context is not specified, the current context is assumed.

Spells for products created in other contexts can be fetched using either an
absolute or a relative pathname.  Be careful that the path you specify contains
no symbolic links or references to parent directory pointers, i.e. the '..'
directory, as these may not be resolved properly.

If the 'Require' argument is not set, then an empty list is a permissible
result.

=cut

sub fetch_spells {
    my %arg = @_;
    my $error = $prototype{_fetch_spells_f()}->validate(\%arg);
    croak _fetch_spells_f, "-- $error" if $error;

    my $context = (exists $arg{Context}) ? $arg{Context} : $Current_Context;
    my $name_arg = $arg{Name};
    my $require = defined $arg{Require};

    my (@names, $spellhash, $directory);

    $directory = $context->Directory;

    if (defined($name_arg)) {
	$spellhash = $context->Spells_By_Name;
	@names = ref($name_arg) ? @$name_arg : ($name_arg);
    }

    my @spells = ( );
    if (@names > 0) {
	for my $name (@names) {
	    my @these;

	    my $filename = $name;
	    $filename = File::Spec->catfile($directory, $filename)
		unless File::Spec->file_name_is_absolute($filename);
	    $filename = File::Spec->canonpath($filename);

	    if (exists($Spell_By_FileSpec{$filename})) {
		push @these, $Spell_By_FileSpec{$filename}
	    }

	    if (exists $spellhash->{$name}) {
		my $these = $spellhash->{$name};
		push @these, @$these;
	    }

	    if ($require && !@these) {
		die <<ends;
$0: Error in context $directory ...
$0: No spells for '$name'.
ends
	    }

	    push @spells, @these;
	}
    }
    else {
	my $these = $context->Default_Spells;
	if ($require && !@$these) {
		die <<ends;
$0: Error in context $directory ...
$0: No default spells.
ends
	}

	@spells = @$these;
    }

    return wantarray ? @spells : \@spells;
}

=pod

=item deferral

$spell = deferral(Directory => [ F<dir1>, F<dir2>, ...], Name => I<name>,
If_Present => 1);

Creates a spell object that defers its actions to the named spells in contexts
associated with other directories.  The 'Name' argument is used with the
C<fetch_spells> function to find all the named spells in each directory.

There must be a spells definition file in each of the named directories, unless
the 'If_Present' argument is defined.

The 'Name' argument may specify a single name or a list of names.  If it is a
list of names, then all the names are passed to the C<fetch_spells> function
for each directory at a time.

=cut

sub deferral {
    my %arg = @_;
    my $error = $prototype{_deferral_f()}->validate(\%arg);
    croak _deferral_f, "-- $error" if $error;

    my $directory = $arg{Directory};
    $directory = [ $directory ] unless (ref $directory eq 'ARRAY');

    my $name_arg = $arg{Name};
    my @name;
    if (defined($name_arg)) {
	@name = ref($name_arg) ? @$name_arg : ( $name_arg );
    }

    my $if_present = defined $arg{If_Present};

    my @spells;
    my $verbose = exists $Option{'verbose'};

    if ($verbose) {
	print _deferral_f, "--\n";

	print "  Directory => [",  (join ',', (map "'$_'", @$directory)), ']';
	print " if present" if $if_present;
	print "\n";

	print "  Name => [", (join ',', (map "'$_'", @name)), "]\n";
    }

    my @fetch_args = (Name => \@name);
    push @fetch_args, (Require => 1) unless $if_present;

    for my $d (@$directory) {
	unless (-d $d) {
	    my $output = "Directory $d not present";
	    cast_error $output unless $if_present;
	    cast_warning $output if $verbose;
	    next;
	}

	$d = abs_path($d);
	my $c = $Context_By_Directory{$d};
	$c = Conjury::Core::Context->new(Directory => $d) if (!defined($c));

	if (defined($c)) {
	    my @deferred_spells = eval {
		fetch_spells Context => $c, @fetch_args;
	    };

	    if ($@) {
		cast_warning "Problem deferring spells to $d ... ";
		die $@;
	    }

	    push @spells, @deferred_spells;
	}
    }

    return Conjury::Core::Spell->new(Factors => \@spells);
}

=pod

=item filecopy

$spell = filecopy
   (Journal => I<journal>,
    Factors => [ I<spell1>, I<spell2>, ... ],
    Directory => F<directory>,
    File => [ F<file1>, F<file2>, ... ],  # array or scalar is okay
    Permission => I<permission>,
    Owner => [ I<user>, I<group> ];

Creates a spell object that copies a file or a list of files to a directory.

The 'File' argument is required and must specify a filename or a list of
filenames.  The 'Directory' argument is required and must specify the
destination directory for the copy action.

Use the optional 'Factors' argument to add spells explicitly to the list of
factors.  If there are already spells that produce the files in the 'File'
list, they need not be listed here.  They will be fetched and automatically
appended to the factors list.

Use the optional 'Journal' argument to specify a journal object for the spell.

Use the optional 'Permission' argument to specify that the C<chmod> builtin
should be used to set the access permissions associated with the files after
they have been copied to the destination.  The syntax requirements for 
C<chmod> apply.

Use the optional 'Owner' argument to specify that the C<chown> builtin should
be used to set the user and group ownership after the files have been copied to
the destination.  The syntax requirements for C<chown> apply.

=cut

sub filecopy {
    my %arg = @_;
    my $error = $prototype{_filecopy_f()}->validate(\%arg);
    croak _filecopy_f, "-- $error" if $error;

    my $journal = $arg{Journal};
    my $directory = $arg{Directory};
    my $file_arg = $arg{File};
    my $permission = $arg{Permission};
    my $owner = $arg{Owner};
    my $factors_ref = $arg{Factors};

    my $files = (!ref $file_arg) ? [ $file_arg ] : $file_arg;

    $permission = oct $permission
      if (defined($permission) && $permission =~ /\A0\d+\Z/);

    my @factors = (defined $factors_ref) ? @$factors_ref : ();

    my $verbose = exists $Option{'verbose'};
    my $preview = exists $Option{'preview'};

    my @product = map File::Spec->catfile($directory, basename($_)), @$files;
    my $file_str = join(' ', @$files);
    my $product_str = join(' ', @product);

    my $profile = _filecopy_f;
    $profile .= " $directory $file_str";
    $profile .= " permission $permission" if defined($permission);
    $profile .= " owner $owner->[0] $owner->[1]" if defined($owner);

    if ($verbose) {
	print _filecopy_f, "--\n";
	print "  File => [", (join ',', (map "'$_'", @$files)), "]\n";
	print "  Directory => ", $directory, "\n";
	print "  Permission => $permission\n" if defined($permission);
	print "  Owner => ['$owner->[0]','$owner->[2]']\n" if defined($owner);
    }

    my $action = sub {
	use File::Copy qw();

	my $result;
	for (my $i = 0; $i < @$files; ++$i) {
	    print "syscopy $files->[$i] $product[$i]\n";
	    if (!$preview) {
		File::Copy::syscopy($files->[$i], $product[$i])
		  || do { return $! };
	    }
	}

	if (defined($permission)) {
	    my $valstr = sprintf "%o", $permission;
	    print "chmod $valstr $product_str\n";

	    if (!$preview) {
		chmod($permission, @product) == @product
		  || do {
		      my $result = $!;
		      unlink @product;
		      return $result;
		  };
	    }
	}

	if (defined($owner)) {
	    my ($user, $group) = @$owner;
	    my ($name, $pass);
	    
	    unless ($user =~ /\A\d+\Z/) {
		($name, $pass, $user) = getpwnam($user);
	    }

	    unless ($group =~ /\A\d+\Z/) {
		($name, $pass, $group) = getgrnam($group);
	    }

	    print "chown $owner->[0] $owner->[1] $product_str\n";

	    if (!$preview) {
		chown($user, $group, @product) == @product
		  || do {
		      my $result = $!;
		      unlink @product;
		      return $result;
		  };
	    }
	}

	return $result;
    };
    
    push @factors, @$files;

    return Conjury::Core::Spell->new
      (Product => \@product,
       Factors => \@factors,
       Profile => $profile,
       Action => $action,
       Journal => $journal);
}

=pod

=item dispell

$spell = dispell
   (Journal => I<journal>,
    Factors => [ I<spell1>, I<spell2>, ... ],
    Directory => [ F<directory1>, F<directory2>, ...] # array or scalar okay
    File => [ F<file1>, F<file2>, ... ],  # array or scalar okay
    Glob => [ F<expression1>, F<expression2>, ...] # array or scalar okay
    Require => 1;

Creates a spell object that erases files or lists of files in a directory.

At least one of the arguments, 'File', 'Glob' and 'Directory' is required.
The 'File' argument specifies a filename or a list of filenames to unlink with
the 'unlink' builtin function.  The 'Directory' argument specifies a directory
or a list of directories to remove with the 'rmtree' function in File::Path.
The 'Glob' argument specifies a filename globbing expression that is resolved
in the action function into a list of files and directories that are dispelled
as if they were specified in 'File' or 'Directory' argument lists.

The 'Require' argument is optional.  If it is set, then the files and
directories to be unlinked or removed are required to exist when the action is
executed to erase them.

Use the optional 'Factors' argument to add spells explicitly to the list of
factors.

Use the optional 'Journal' argument to specify a journal object for the spell.

=cut

sub dispell {
    my %arg = @_;
    my $error = $prototype{_dispell_f()}->validate(\%arg);
    croak _dispell_f, "-- $error" if $error;

    my $journal = $arg{Journal};
    my $factors_ref = $arg{Factors};
    my @factors = (defined $factors_ref) ? @$factors_ref : ();
    my $file_arg = $arg{File};
    my $directory_arg = $arg{Directory};
    my $glob_arg = $arg{Glob};
    my $require = !!$arg{Require};

    croak _dispell_f, "-- 'File', 'Glob' or 'Directory' argument required"
        unless (defined $file_arg
                or defined $directory_arg
                or defined $glob_arg);

    my (@files, @dirs, @globs);
    @files = (ref $file_arg) ? @$file_arg : ( $file_arg )
        if (defined $file_arg);
    @dirs = (ref $directory_arg) ? @$directory_arg : ( $directory_arg )
        if (defined $directory_arg);
    @globs = (ref $glob_arg) ? @$glob_arg : ( $glob_arg )
        if (defined $glob_arg);

    my $cwd = $Current_Context->Directory;

    my @abs_files  = map File::Spec->catfile($cwd, $_), @files;
    my @abs_dirs   = map File::Spec->catdir($cwd, $_), @dirs;
    my @abs_globs  = map File::Spec->catfile($cwd, $_), @globs;

    my $verbose = exists $Option{'verbose'};
    my $preview = exists $Option{'preview'};

    my $profile = _dispell_f;
    $profile .= ' files '; $profile .= join(' ', @files);
    $profile .= ' dirs '; $profile .= join(' ', @dirs);

    if ($verbose) {
	print _dispell_f, "--\n";
	print "  File       => [", (join ',', (map "'$_'", @files)), "]\n";
	print "  Directory  => [", (join ',', (map "'$_'", @dirs)), "]\n";
	print "  Glob       => [", (join ',', (map "'$_'", @globs)), "]\n";
    }

    my $action = sub {
        print "dispell @globs\n" if (@abs_globs);
	print "unlink @files\n" if (@abs_files);
	print "rmtree @dirs\n" if (@abs_dirs);
        
        while (@abs_globs) {
            my @matches = glob shift @abs_globs;
            while (@matches) {
                my $match = shift @matches;
                if (-d $match) {
                    push @abs_dirs, $match;
                }
                else {
                    push @abs_files, $match;
                }
            }
        }
        
	if (!$preview) {
	    for my $file (@abs_files) {
		next unless ($require or -e $file);
		unlink $file || do { return $! };
                delete $journal->{$file} if (defined $journal);
	    }
	}

	if (!$preview) {
            local $SIG{__WARN__} = sub { die $_[0] };
	    for my $dir (@abs_dirs) {
		next unless ($require or -e $dir);
		rmtree $dir, 0, 1;
                if (defined $journal) {
                    my $pattern = qr/\A\Q$dir\E/m;
                    my @journaled = keys %$journal;
                    @journaled = grep m/$pattern/, @journaled;
                    delete $journal->{$_} for (@journaled);
                }
	    }
	}

	return 0;
    };

    return Conjury::Core::Spell->new
      (Journal => $journal,
       Factors => \@factors,
       Profile => $profile,
       Action => $action);
}

1;

__END__

=pod

=back

=head1 AUTHOR

James Woodyatt <F<jhw@wetware.com>>
