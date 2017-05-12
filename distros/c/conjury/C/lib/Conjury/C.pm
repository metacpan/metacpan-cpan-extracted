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

my (%prototype, %validator);

package Conjury::C;
use Conjury::Core qw(%Option);

BEGIN {
    require Conjury::Core::Prototype;

    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION = 1.004;

    die "Conjury::C v$VERSION requires Conjury::Core v1.003 or later.\n"
      unless ($Conjury::Core::VERSION >= 1.003);

    @ISA = qw(Exporter);
    @EXPORT = qw(&c_compiler &c_linker &c_archiver &c_object
		 &c_executable &c_static_library);

    use vars qw($Default_Compiler $Default_Linker $Default_Archiver);
    use subs qw(c_compiler c_linker c_archiver c_object c_executable
		c_static_library);
}


package Conjury::C::Compiler;
use Conjury::Core qw(%Option $Current_Context &cast_error &cast_warning
		     &fetch_spells);
use Carp qw(croak);
use Config;

sub _new_f()		{ __PACKAGE__ . '::new'	     }
sub _cc_new_profile_f()     { __FILE__ . '/$cc_new_profile'     }
sub _object_spell_f()       { __PACKAGE__ . '::object_spell'    }

BEGIN {
    use vars qw($AUTOLOAD %Default);
    
    $Default{Flag_Map} = { map { $_ => "-$_" } qw(I D c o) };

    $Default{Suffix_Rule} = sub {
	my $name = shift;
	$name =~ s/\.c\Z/$Config{_o}/i
	  || cast_error "C source file '$name' doesn't have a .c extension.";
	return $name;
    };

    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Program => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Flag_Map => \&Conjury::Core::Prototype::validate_hash_of_scalars);
    $proto->optional_arg
      (Suffix_Rule => \&Conjury::Core::Prototype::validate_code);
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $proto->optional_arg
      (Scanner => \&Conjury::Core::Prototype::validate_code);
    $prototype{_new_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Directory => \&Conjury::Core::Prototype::validate_scalar);
    $proto->required_arg
      (Source => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Includes => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Defines => \&Conjury::Core::Prototype::validate_hash_of_scalars);
    $proto->optional_arg
      (Factors => \&Conjury::Core::Prototype::validate_array);
    $prototype{_object_spell_f()} = $proto;
}

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    $class = ref($class) if ref($class);

    my $program = $arg{Program};
    $program = $Config{cc} unless defined($program);

    my $options = $arg{Options};
    $options = defined($options) ? [ @$options ] : [ ];

    my $flag_map = $arg{Flag_Map};
    my %my_flag_map = %{$Default{Flag_Map}};
    if (defined $flag_map) {
	my ($key, $value);
	while (($key, $value) = each %$flag_map) {
	    $my_flag_map{$key} = $value;
	}
    }
    $flag_map = \%my_flag_map;

    my $suffix_rule = $arg{Suffix_Rule};
    $suffix_rule = $Default{Suffix_Rule} unless defined($suffix_rule);

    my $journal = $arg{Journal};
    my $scanner = $arg{Scanner};
    
    my $self = { };
    bless $self, $class;

    $self->{Program} = $program;
    $self->{Options} = $options;
    $self->{Flag_Map} = $flag_map;
    $self->{Suffix_Rule} = $suffix_rule;
    $self->{Journal} = $journal;
    $self->{Scanner} = $scanner;

    return $self;
}

sub DESTROY { }

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

my $cc_new_profile = sub {
    my ($prefix, $factors, $c_file, $scanner, $parameters) = @_;
    
    my $profile;
    my $profile_str = __PACKAGE__ . " $prefix";
    my @c_file_factors = fetch_spells Name => $c_file;
    if (@c_file_factors) {
	push @$factors, @c_file_factors;
	$profile = $profile_str;
    }
    else {
	$profile = sub {
	    my $result = $profile_str;
	    
	    my @c_file_stat = stat $c_file;
	    if (@c_file_stat) {
		$result .= " $c_file_stat[9]";
	    }
	    else {
		cast_error
		  "No spells for '$c_file' ...is it a missing source file?";
	    }
	    
	    my @dependencies;
	    if (defined($scanner)) {
		print "Scanning: $c_file\n" if exists($Option{'verbose'});
		@dependencies = &$scanner($c_file, $parameters);
	    }

	    for my $file (@dependencies) {
		next if $file eq $c_file;
		@c_file_stat = stat $file;
		if (@c_file_stat) {
		    $result .= " $c_file_stat[9]";
		}
		else {
		    cast_warning
		      "File '$c_file' depends on missing file '$file'.";
		}
	    }

	    return $result;
	};
    }

    return $profile;
};

sub object_spell {
    my ($self, %arg) = @_;
    my $error = $prototype{_object_spell_f()}->validate(\%arg);
    croak _object_spell_f, "-- $error" if $error;

    my $directory = $arg{Directory};
    my $c_file = $arg{Source};
    my $factors_ref = $arg{Factors};
    my @factors = defined($factors_ref) ? @$factors_ref : ();

    my $flag_map = $self->{Flag_Map};

    my $defines = $arg{Defines};
    $defines = { } unless defined($defines);
    my $flag_D = $flag_map->{D};
    my @define_list = map {
	my ($name, $value) = ($_, $defines->{$_});
	$value eq '1' ? "$flag_D$name" : "$flag_D$name=$value";
    } sort(keys(%$defines));
    $defines = \@define_list;

    my $includes = $arg{Includes};
    $includes = [ ] unless defined($includes);
    my $flag_I = $flag_map->{I};
    my @include_list = map "$flag_I$_", @$includes;
    $includes = \@include_list;

    my $options = $arg{Options};
    $options = defined($options) ? [ @$options ] : [ ];

    my $cc_options = $self->{Options};
    unshift @$options, @$cc_options;

    my $program = $self->{Program};
    my $journal = $self->{Journal};
    my $scanner = $self->{Scanner};

    my $suffix_rule = $self->{Suffix_Rule};
    my $o_file = &$suffix_rule($c_file);

    $o_file = File::Spec->catfile($directory, $o_file)
      if defined($directory);
    $o_file = File::Spec->canonpath($o_file);

    my $flag_c = $flag_map->{c};
    my $flag_o = $flag_map->{o};

    my @parameters = (@$options, @$defines, @$includes);
    my @command = ($program, @parameters, $flag_o, $o_file, $flag_c, $c_file);

    my $command_str = join ' ', @command;

    my $profile = &$cc_new_profile($command_str, \@factors, $c_file, $scanner,
				   \@parameters);

    return Conjury::Core::Spell->new
      (Product => $o_file,
       Factors => \@factors,
       Profile => $profile,
       Action => \@command,
       Journal => $journal);
}


package Conjury::C::Linker;
use Conjury::Core qw(%Option $Current_Context &cast_error &fetch_spells);
use Carp qw(croak);
use Config;

sub _new_f()		{ __PACKAGE__ . '::new'		 }
sub _executable_spell_f()   { __PACKAGE__ . '::executable_spell'    }

BEGIN {
    use vars qw($AUTOLOAD %Default);

    my $verbose = exists $Option{'verbose'};

    $Default{Flag_Map} = { map { $_ => "-$_" } qw(o L l) };

    $Default{Bind_Rule} = sub {
	my ($library, $binding) = @_;
	cast_error "No support for '$binding' binding."
	  unless ($binding eq '' || $binding =~ /\A(static|dynamic)\Z/);

	my @result = ("lib${library}$Config{_a}");
	unshift @result, "lib${library}.$Config{so}"
	  unless $binding eq 'static';
	return @result;
    };

    $Default{Search_Rule} = sub {
	my ($library, $bind_rule, $binding, @search) = @_;

	my @files = &$bind_rule($library, $binding);
	my @factors = ( );
	
      outer:
	for my $dir (@search) {
	    for my $file (@files) {
		@factors =
		  fetch_spells(Name => File::Spec->catfile($dir, $file));
		last outer if @factors;
	    }
	}

	if ($verbose) {
	    print __PACKAGE__, "::Default{Search_Rule}--\n";
	    print "  library='$library'\n";
	    print "  binding='$binding'\n";
	    print "  search=[", join(',', (map "'$_'", @search)), "]\n";

	    my $factors_str = '';
	    for my $factor (@factors) {
		$factors_str .= join(',', (map "'$_'", @{$factor->Product}));
	    }

	    print '  factors=[', $factors_str, "]\n";
	}

	return @factors;
    };

    $Default{Order_Key_Match_} =
      join '|', qw(Objects Libraries Searches);

    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Program => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Flag_Map => \&Conjury::Core::Prototype::validate_hash_of_scalars);
    $proto->optional_arg
      (Bind_Rule => \&Conjury::Core::Prototype::validate_code);
    $proto->optional_arg
      (Search_Rule => \&Conjury::Core::Prototype::validate_code);
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $prototype{_new_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->required_arg
      (Name => \&Conjury::Core::Prototype::validate_scalar);
    $proto->required_arg
      (Order => \&Conjury::Core::Prototype::validate_array);
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Factors => \&Conjury::Core::Prototype::validate_array);
    $prototype{_executable_spell_f()} = $proto;
}

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    $class = ref($class) if ref($class);

    my $program = $arg{Program};
    $program = $Config{ld} unless defined($program);

    my $options = $arg{Options};
    if (defined($options)) {
	$options = [ [ @$options ], [ ] ] if (!ref($options->[0]));
	croak _new_f, '-- argument mismatch {Options} [length]'
	  unless (@$options == 2);
    }
    else {
	$options = [ [ ], [ ] ];
    }

    my $flag_map = $arg{Flag_Map};
    my %my_flag_map = %{$Default{Flag_Map}};
    if (defined($flag_map)) {
	my ($key, $value);
	while (($key, $value) = each %$flag_map) {
	    $my_flag_map{$key} = $value;
	}
    }
    $flag_map = \%my_flag_map;
    my $flag_L = $flag_map->{L};

    my $bind_rule = $arg{Bind_Rule};
    $bind_rule = $Default{Bind_Rule} unless defined($bind_rule);

    my $search_rule = $arg{Search_Rule};
    $search_rule = $Default{Search_Rule} unless defined($search_rule);

    my $journal = $arg{Journal};

    my $self = { };
    bless $self, $class;

    $self->{Program} = $program;
    $self->{Options} = $options;
    $self->{Flag_Map} = $flag_map;
    $self->{Bind_Rule} = $bind_rule;
    $self->{Search_Rule} = $search_rule;
    $self->{Journal} = $journal;
    $self->{Order_Key_Match_} = $Default{Order_Key_Match_};

    return $self;
}

sub DESTROY { }

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

sub process_ {
    my ($self, $traveller, $key, $value) = @_;

    my $order_key_match = $self->{Order_Key_Match_};

    croak __PACKAGE__, '::process_-- unrecognized order key'
      unless (!ref($key) && $key =~ /\A($order_key_match)\Z/);

    $key = "process_${key}_";
    eval { $self->$key($traveller, $value) };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    undef;
}

sub process_Objects_ {
    my ($self, $traveller, $value) = @_;

    croak __PACKAGE__, '::process_Objects_-- argument mismatch'
      unless (ref($value) eq 'ARRAY' && !grep ref, @$value);
	
    for (@$value) {
	push @{$traveller->{parameters}}, $_;
	push @{$traveller->{factors}}, $_;
    }

    undef;
}

sub process_Libraries_ {
    my ($self, $traveller, $value) = @_;

    croak __PACKAGE__, '::process_Libraries_-- argument mismatch'
      unless (ref($value) eq 'ARRAY' && !grep ref, @$value);
	    
    my $bind_rule = $self->{Bind_Rule};
    my $search_rule = $self->{Search_Rule};
    my $flag_map = $self->{Flag_Map};
    my $flag_l = $flag_map->{l};
    my $binding = $traveller->{binding};
    $binding = '' unless defined($binding);
    my $searches = $traveller->{searches};
    $searches = [ ] unless defined($searches);

    for (@$value) {
	my @spells = &$search_rule($_, $bind_rule, $binding, @$searches);
	push @{$traveller->{parameters}}, "$flag_l$_";
	push @{$traveller->{factors}}, @spells;
    }

    undef;
}

sub process_Searches_ {
    my ($self, $traveller, $value) = @_;

    croak __PACKAGE__, '::process_Searches_-- argument mismatch'
      unless (ref($value) eq 'ARRAY' && !grep ref, @$value);

    my $flag_map = $self->{Flag_Map};
    my $flag_L = $flag_map->{L};

    $traveller->{searches} = [ ] unless exists($traveller->{searches});

    for (@$value) {
	push @{$traveller->{searches}}, $_;
	push @{$traveller->{parameters}}, "$flag_L$_";
    }

    undef;
}

sub executable_spell {
    my ($self, %arg) = @_;
    my $error = $prototype{_executable_spell_f()}->validate(\%arg);
    croak _executable_spell_f, "-- $error" if $error;

    my $directory = $arg{Directory};
    my $name = $arg{Name};
    my $product = "$name$Config{_exe}";

    my $options = $arg{Options};
    if (defined($options)) {
	$options = [ [ @$options ], [ ] ] if (!ref($options->[0]));
	croak _executable_spell_f, '-- argument mismatch {Options} [length]'
	  unless (@$options == 2);
    }
    else {
	$options = [ [ ], [ ] ];
    }
    
    my $ld_options = $self->{Options};
    unshift @{$options->[0]}, @{$ld_options->[0]};
    unshift @{$options->[1]}, @{$ld_options->[1]};

    my $order_ref = $arg{Order};
    croak _executable_spell_f, '-- argument mismatch[1] {Order}'
      unless (@$order_ref > 1 && !(@$order_ref % 2));
    my @order = @$order_ref;

    my $factors_ref = $arg{Factors};
    my @factors = defined($factors_ref) ? @$factors_ref : ();

    my @parameters = ( );
    my %traveller;
    $traveller{parameters} = \@parameters;
    $traveller{factors} = \@factors;

    while (@order) {
	eval { $self->process_(\%traveller, splice(@order, 0, 2)) };
	if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    }

    my $program = $self->{Program};
    my $journal = $self->{Journal};

    $product = File::Spec->catfile($directory, $product)
      if defined($directory);
    $product = File::Spec->canonpath($product);

    my $flag_map = $self->{Flag_Map};
    my $flag_o = $flag_map->{o};

    my @command =
	    ($program, @{$options->[0]}, $flag_o, $product, @parameters,
	     @{$options->[1]});
    my $profile = join(' ', (__PACKAGE__, @command));

    return Conjury::Core::Spell->new
      (Product => $product,
       Factors => \@factors,
       Profile => $profile,
       Action => \@command,
       Journal => $journal);
}


package Conjury::C::Archiver;
use Conjury::Core qw(%Option &cast_error);
use Carp qw(croak);
use Config;

sub _new_f()	    { __PACKAGE__ . '::new'	     }
sub _library_spell_f()  { __PACKAGE__ . '::library_spell'   }

BEGIN {
    use vars qw($AUTOLOAD %Default);

    $Default{Flag_Map} = { map { $_ => "-$_" } qw(r) };

    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Program => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Flag_Map => \&Conjury::Core::Prototype::validate_hash_of_scalars);
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $prototype{_new_f()} = $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->required_arg
      (Name => \&Conjury::Core::Prototype::validate_scalar);
    $proto->required_arg
      (Objects => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Directory => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Factors => \&Conjury::Core::Prototype::validate_array);
    $prototype{_library_spell_f()} = $proto;
}

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    $class = ref($class) if ref($class);

    my $program = $arg{Program};
    $program = $Config{ar} unless defined($program);

    my $options = $arg{Options};
    $options = defined($options) ? [ @$options ] : [ ];

    my $flag_map = $arg{Flag_Map};
    my %my_flag_map = %{$Default{Flag_Map}};
    if (defined($flag_map)) {
	my ($key, $value);
	while (($key, $value) = each %$flag_map) {
	    $my_flag_map{$key} = $value;
	}
    }
    $flag_map = \%my_flag_map;

    my $journal = $arg{Journal};

    my $self = { };
    bless $self, $class;

    $self->{Program} = $program;
    $self->{Options} = $options;
    $self->{Flag_Map} = $flag_map;
    $self->{Journal} = $journal;

    return $self;
}

sub DESTROY { }

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

sub library_spell {
    my ($self, %arg) = @_;
    my $error = $prototype{_library_spell_f()}->validate(\%arg);
    croak _library_spell_f, "-- $error" if $error;

    my $directory = $arg{Directory};
    my $name = $arg{Name};
    my $options = $arg{Options};
    $options = defined($options) ? [ @$options ] : [ ];

    my $ar_options = $self->{Options};
    unshift @$options, @$ar_options;

    my $objects = $arg{Objects};

    my $factors_ref = $arg{Factors};
    my @factors = defined($factors_ref) ? @$factors_ref : ();

    my $program = $self->{Program};
    my $journal = $self->{Journal};

    my $product = "lib${name}$Config{_a}";
    $product = File::Spec->catfile($directory, $product)
      if defined($directory);
    $product = File::Spec->canonpath($product);

    my $flag_map = $self->{Flag_Map};
    my $flag_r = $flag_map->{r};

    my @command = ($program, $flag_r, @$options, $product, @$objects);
    my $command_str = join ' ', @command;

    my $action = sub {
	print "$command_str\n";

	my $result;
	if (!exists($Option{'preview'})) {
	    unlink $product;
	    $result = system @command;
	}

	return $result;
    };

    my $profile = __PACKAGE__ . ' ' . $command_str;

    push @factors, @$objects;

    return Conjury::Core::Spell->new
      (Product => $product,
       Factors => \@factors,
       Profile => $profile,
       Action => $action,
       Journal => $journal);
}


package Conjury::C;
use Carp qw(croak);

sub c_compiler {
    my %arg = @_;

    my $vendor = $arg{Vendor};
    delete $arg{Vendor};
    
    my $cc;
    if (defined($vendor)) {
	my $package = "Conjury::C::$vendor";
	eval "require $package";
	die $@ if $@;

	my $class = "${package}::Compiler";
	$cc = eval { $class->new(%arg) };
    }
    else {
	$cc = eval { Conjury::C::Compiler->new(%arg) };
    }

    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    return $cc;
}

sub c_linker {
    my %arg = @_;

    my $vendor = $arg{Vendor};
    delete $arg{Vendor};
    
    my $cc;
    if (defined($vendor)) {
	my $package = "Conjury::C::$vendor";
	eval "require $package";
	die $@ if $@;

	my $class = "${package}::Linker";
	$cc = eval { $class->new(%arg) };
    }
    else {
	$cc = eval { Conjury::C::Linker->new(%arg) };
    }

    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    return $cc;
}

sub c_archiver {
    my %arg = @_;

    my $vendor = $arg{Vendor};
    delete $arg{Vendor};
    
    my $cc;
    if (defined($vendor)) {
	my $package = "Conjury::C::$vendor";
	eval "require $package";
	die $@ if $@;

	my $class = "${package}::Archiver";
	$cc = eval { $class->new(%arg) };
    }
    else {
	$cc = eval { Conjury::C::Archiver->new(%arg) };
    }

    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    return $cc;
}

sub c_object {
    my %arg = @_;

    my $compiler = $arg{Compiler};
    delete $arg{Compiler};

    if (!defined($compiler)) {
	$Default_Compiler = Conjury::C::Compiler->new
	  unless defined($Default_Compiler);
	$compiler = $Default_Compiler;
    }

    croak __PACKAGE__, '::c_object-- argument mismatch {Compiler}'
      unless ref($compiler);

    my $spell = eval { $compiler->object_spell(%arg) };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    return wantarray ? @{$spell->Product} : $spell;
}

sub c_executable {
    my %arg = @_;

    my $linker = $arg{Linker};
    delete $arg{Linker};

    if (!defined($linker)) {
	$Default_Linker = Conjury::C::Linker->new
	  unless defined($Default_Linker);
	$linker = $Default_Linker;
    }

    croak __PACKAGE__, '::c_executable-- argument mismatch {Linker}'
      unless ref($linker);

    my $spell = eval { $linker->executable_spell(%arg) };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    return wantarray ? @{$spell->Product} : $spell;
}

sub c_static_library {
    my %arg = @_;

    my $archiver = $arg{Archiver};
    delete $arg{Archiver};

    if (!defined($archiver)) {
	$Default_Archiver = Conjury::C::Archiver->new
	  unless defined($Default_Archiver);
	$archiver = $Default_Archiver;
    }

    croak __PACKAGE__, '::c_static_library-- argument mismatch {Archiver}'
      unless ref($archiver);

    my $spell = eval { $archiver->library_spell(%arg) };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }
    return wantarray ? @{$spell->Product} : $spell;
}

1;

__END__

=head1 NAME

Conjury::C - Perl Conjury with C/C++ compilers, linkers and archivers

=head1 SYNOPSIS

  c_object
    Source => I<source-file>,
    Directory => I<directory>,
    Includes => [ I<dir1>, I<dir2>, ... ],
    Defines => { I<var1> => I<val1>, I<var2> => I<val2>, ... },
    Compiler => I<compiler>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Factors => [ I<factor1>, I<factor2>, ... ];

  c_executable
    Directory => I<directory>,
    Name => I<output-filename>,
    Order => [
    Searches => [ I<dir1>, I<dir2>, ... ],
    Objects => [ I<obj1>, I<obj2>, ... ],
    Libraries => [ I<lib1>, I<lib2>, ...] ],
    Linker => I<linker>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Factors => [ I<factor1>, I<factors2>, ... ]

  c_static_library
    Directory => I<directory>,
    Name => I<output-filename>,
    Objects => [ I<obj1>, I<obj2>, ...],
    Archiver => I<archiver>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Factors => [ I<factor1>, I<factors2>, ... ]

  c_compiler
    Program => I<program>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Journal => I<journal>,
    Flag_Map => { 'I' => I<include-flag>, 'D' => I<define-flag>,
	      'c' => I<source-flag>, 'o' => I<object-flag> },
    Suffix_Rule => sub { my ($name) = @_; ... return $result },
    Scanner => sub { my ($c_file, $args) = @_; ... return @result };

  c_compiler Vendor => I<vendor>, ...

  c_linker
    Program => I<program>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Journal => I<journal>,
    Flag_Map => { 'l' => I<link-flag>, 'L' => I<search-flag>,
	      'o' => I<output-flag> },
    Bind_Rule => sub { my ($lib, $bind) = @_;
		   ... return @result },
    Search_Rule => sub { my ($lib, $rule, $bind, @search) = @_;
		     ... return @factors };

  c_linker Vendor => I<vendor>, ...

  c_archiver
    Program => I<program>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Journal => I<journal>,
    Flag_Map => { 'r' => I<replace-flag> };

  c_archiver Vendor => I<vendor>, ...

=head1 DESCRIPTION

Spells for compiling and linking C/C++ software are constructed using
C<c_object>, C<c_executable> and C<c_static_library>.  The compiler,
linker and archiver used in the resulting actions are the same compiler,
linker and archiver that were used to build Perl itself, unless otherwise
specified.

Specializations of the general classes of compiler, linker and archiver
can be created using C<c_compiler>, C<c_linker> and C<c_archiver>.

=head2 Compiling Objects From C/C++ Source

Use the C<c_object> function to create a spell for compiling an object
file from a C or C++ source file.  The name of the resulting object file
will be derived by removing the .c suffix and replacing it with the
suffix for object files on the current platform.

Use the C<c_compiler> function to create an object to represent a
specialization of the C/C++ compiler tool class.

=over 4

=item c_object

This function returns a spell for the action to compile a source file
into an object file.

The 'Source' argument is required and specifies the name of the source
file to compile into an object file.

The optional 'Directory' argument specifies the directory in which the
object file should be produced.

The optional 'Includes' argument specifies a list of directories that
should be used by the compiler to search for header files.

Preprocessor variables may be specified with the optional 'Defines'
argument by placing the names of variables to set into the keys of a
hash, and defining the values as needed.

The optional 'Compiler' argument specifies that a particular
specialization of the C/C++ compiler tool be used (instead of the
default compiler).

The optional 'Options' argument specifies a list of options with which
to invoke the compiler for this particular object file.

The optional 'Factors' argument specifies additional factors to
associate with the spell created.

=item c_compiler

This function returns an object representing a specialization of the
C/C++ compiler class.  If the 'Vendor' argument is specified, then
the vendor-specific subclass of the C<Conjury::C::Compiler>
class parse the argument list.  Otherwise, the specialization is
applied to the base class used for the default compiler.

The optional 'Program' argument specifies the name of the program to
invoke the compiler.

The optional 'Options' argument specifies the list of options with
which the compiler should be invoked for all object files.

The optional 'Journal' argument specifies the journal object that
should be used in creating all spells.

The optional 'Flag_Map' argument specifies a hash that sets the flag
character for various standard options to C/C++ compilers for setting
the include path, the preprocessor definitions, the source file and
the output file.

The optional 'Suffix_Rule' argument specifies a subroutine that
converts the name of a source file into the corresponding object file.

The optional 'Scanner' argument specifies a subroutine that finds the
list of files that a source file references with '#include' directives.

=back

=head2 Linking Executables From Objects

Use the C<c_executable> function to create a spell for linking an
executable program from a list of object files.

Use the C<c_linker> function to create an object to represent a
specialization of the C/C++ linker tool class.

=over 4

=item c_executable

This function returns a spell for the action to link a list of object
files and libraries into an executable file.

The optional 'Directory' argument specifies the directory where the
executable program is to be produced.  If unspecified, the directory
of the current context is used.

The 'Name' argument is required and specifies the name of the executable
program.  Any filename extensions the system requires for executable
program files will be appended automatically.

The 'Order' argument is a required list of verb-object pairs
corresponding to orders for the linker to use in producing the
executable.  The 'Searches' verb specifies a list of directories to add
to the library search path; the 'Objects' verb specifies a list of
object files to link (either the spells that produce them, or the names
of spells that will produce them); the 'Libraries' verb specifies the
list of libraries to link.  Order verbs may be specified in whatever
sequence makes sense to the linker.

The optional 'Linker' argument specifies that a particular
specialization of the C/C++ linker tool be used (instead of the
default linker).

The optional 'Options' argument specifies a list of options with which
to invoke the linker for this particular object file.

The optional 'Factors' argument specifies additional factors to
associate with the spell created.

=item c_linker

This function returns an object representing a specialization of the
C/C++ linker class.  If the 'Vendor' argument is specified, then
the vendor-specific subclass of the C<Conjury::C::Linker>
class parse the argument list.  Otherwise, the specialization is
applied to the base class used for the default linker.

The optional 'Program' argument specifies the name of the program to
invoke the linker.

The optional 'Options' argument specifies the list of options with
which the linker should be invoked for all product files.

The optional 'Journal' argument specifies the journal object that
should be used in creating all spells.

The optional 'Flag_Map' argument specifies a hash that sets the flag
character for various standard options to C/C++ linkers for setting
the search path, the output file and the libraries to link.

The optional 'Bind_Rule' argument specifies a subroutine that takes
a library name and a binding specification and returns a list of
library filenames for which the binding specification applies.
Typical binding specifications include 'static' and 'dynamic'-- and
the unnamed specification, which typically implies "either dynamic or
static as required."

The optional 'Search_Rule' argument specifies a subroutine that
takes a library name, a binding rule (see above), a binding
specification (also, see above), and a list of the current
directories in the library search path (at the current point in the
sequence of orders), and returns the list of factors which produce
the library files.

=back

=head2 Creating Static Archives Of Objects

Use the C<c_static_library> function to create a spell for composing a
static library from a list of object files.

Use the C<c_archiver> function to create an object to represent a
specialization of the C/C++ archiver tool class.

=over 4

=item c_static_library

This function returns a spell for the action to archive a list of object
files in a static library file.

The optional 'Directory' argument specifies the directory where the
static library file is to be produced.  If unspecified, the directory
of the current context is used.

The 'Name' argument is required and specifies the name of the library
file.  Any filename extensions and prefixes the system requires for
static library files will be added automatically.

The 'Objects' argument is required and specifies the list of objects
(and/or spells that produce the objects) to be archived into the static
library file.

The optional 'Archiver' argument specifies that a particular
specialization of the C/C++ archiver tool be used (instead of the
default archiver).

The optional 'Options' argument specifies a list of options with which
to invoke the archiver for this particular object file.

The optional 'Factors' argument specifies additional factors to
associate with the spell created.

=item c_archiver

This function returns an object representing a specialization of the
C/C++ archiver class.  If the 'Vendor' argument is specified, then
the vendor-specific subclass of the C<Conjury::C::Archiver>
class parse the argument list.  Otherwise, the specialization is
applied to the base class used for the default archiver.

The optional 'Program' argument specifies the name of the program to
invoke the archiver.

The optional 'Options' argument specifies the list of options with
which the archiver should be invoked for all static library files.

The optional 'Journal' argument specifies the journal object that
should be used in creating all spells.

The optional 'Flag_Map' argument specifies a hash that sets the flag
character for various standard options to C/C++ archivers, including
the flag for replacing existing objects with new ones.

=back

=head1 SEE ALSO

The introduction to Perl Conjury is in L<Conjury>.  Other useful documents
include L<cast> and L<Conjury::Core>.

The specialization for the GNU tools is documented in L<Conjury::C::GNU>.

=head1 AUTHOR

James Woodyatt <F<jhw@wetware.com>>
