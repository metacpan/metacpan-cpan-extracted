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

my (%prototype, %verifier);

package Conjury::C::Sun;

BEGIN {
    use Conjury::C;
    use vars qw(@ISA);
    @ISA = qw(Conjury::C);

    $verifier{suncc_language} = sub {
	my ($x, $y) = (shift, undef);
	$y = q/not 'c' or 'c++'/
	  unless ($x =~ m/\A(c|c\+\+)\Z/i);
	return $y;
    };
}

package Conjury::C::Sun::Compiler;
use vars qw(@ISA);
use Carp qw(croak);
use Conjury::Core qw(cast_error %Option);

sub _new_f()    { __PACKAGE__ . '::new'     }

BEGIN {
    @ISA = qw(Conjury::C::Compiler);

    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Program => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (No_Scanner => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Language => $verifier{suncc_language});
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $prototype{_new_f()} = $proto;
}

my $suncc_scanner = sub {
    my ($program, $c_file, $parameters) = @_;

    my $verbose = exists $Option{'verbose'};
    my $command = "$program";
    for (@$parameters) {
	$command .= ' ';
	$command .= /\s/ ? "'$_'" : $_;
    }
    $command .= " -xM1 $c_file";

    print "scanning $c_file ...\n";
    print "$command\n" if $verbose;

    cast_error "Unable to scan file '$c_file'"
      unless open(PIPE, "$command |");
    my @make_rule = <PIPE>;
    close PIPE || cast_error 'Scan failed.';

    print @make_rule if $verbose;
    
    for (@make_rule) {
	chomp;
	s/\s*\\?$//;
	s/^\S+:\s*//;
    }

    return split('\s+', join(' ', @make_rule));
};

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    $class = ref($class) if ref($class);

    my $program = $arg{Program};
    $program = 'cc' unless defined($program);

    my $language = $arg{Language};
    $language = 'c' unless defined($language);
    $language = lc($language);
    $program =~ s/cc/CC/ if $language eq 'c++';

    my $no_scanner = $arg{No_Scanner};
    my $journal = $arg{Journal};
    my $scanner = undef;

    $scanner = sub { &$suncc_scanner($program, @_) }
      if (defined($journal) && $no_scanner);

    my $suffix_rule = sub {
	my $name = shift;
	$name .= '.o' unless $name =~ s/\.(c|C|cc|cxx|c\+\+|m|i|ii|s|S)\Z/.o/;
	return $name;
    };

    my $self = eval {
      Conjury::C::Compiler->new
	(Program => $program,
	 Suffix_Rule => $suffix_rule,
	 Options => $arg{Options},
	 Scanner => $scanner,
	 Journal => $journal);
    };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }

    $self->{Language} = $language;

    bless $self, $class;
}


package Conjury::C::Sun::Linker;
use vars qw(@ISA);
use Carp qw(croak);

sub _new_f()    { __PACKAGE__ . '::new'     }

BEGIN {
    @ISA = qw(Conjury::C::Linker);

    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Program => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (No_Scanner => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Language => $verifier{suncc_language});
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $prototype{_new_f()} = $proto;
}

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    $class = ref($class) if ref($class);

    my $program = $arg{Program};
    $program = 'cc' unless defined($program);

    my $language = $arg{Language};
    $language = 'c' unless defined($language);
    $language = lc($language);
    $program =~ s/cc/CC/ if $language eq 'c++';

    my $self = eval {
      Conjury::C::Linker->new
	(Program => $program,
	 Options => $arg{Options},
	 Journal => $arg{Journal});
    };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }

    $self->{Language} = $language;
    bless $self, $class;
}

package Conjury::C::Sun::Archiver;
use vars qw(@ISA);

use Carp qw(croak);

sub _new_f()    { __PACKAGE__ . '::new'     }

BEGIN {
    @ISA = qw(Conjury::C::Archiver);

    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Program => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (No_Scanner => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Language => $verifier{suncc_language});
    $proto->optional_arg
      (Options => \&Conjury::Core::Prototype::validate_array_of_scalars);
    $proto->optional_arg
      (Journal => \&Conjury::Core::Prototype::validate_hash);
    $prototype{_new_f()} = $proto;
}

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    $class = ref($class) if ref($class);

    my $program = $arg{Program};
    my $language = $arg{Language};
    $language = 'c' unless defined($language);
    $language = lc($language);
    
    my @arglist = ( );
    if ($language eq 'c++') {
	$program = 'CC' unless defined($program);

	push @arglist, (Flag_Map => { 'r' => '-xar' });
    }

    push @arglist, (Program => $program) if (defined $program);
    push @arglist, (Options => $arg{Options}, Journal => $arg{Journal});

    my $self = eval { Conjury::C::Archiver->new(@arglist) };
    if ($@) { $@ =~ s/ at \S+ line \d+\n//; croak $@; }

    $self->{Language} = $language;
    bless $self, $class;
}

1;

__END__

=head1 NAME

Conjury::C::Sun -- Perl Conjury with the Sun Workshop C/C++ tools

=head1 SYNOPSIS

  c_compiler Vendor => 'Sun',
    Language => I<language>,
    No_Scanner => 1,
    Program => I<program>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Journal => I<journal>;

  c_linker Vendor => 'Sun',
    Language => I<language>,
    Program => I<program>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Journal => I<journal>;

  c_archiver Vendor => 'Sun',
    Language => I<language>,
    Program => I<program>,
    Options => [ I<opt1>, I<opt2>, ... ],
    Journal => I<journal>;

=head1 DESCRIPTION

The optional 'Program', 'Options' and 'Journal' arguments to the
Sun-specific specializations of the C<c_compiler> and C<c_linker>
functions are simply passed through unmodified to the base class
constructor.

The optional 'Language' argument specifies the langauge for which
the compiler or linker should be invoked.  The C language is the
default if not otherwise specified.  The value is case-insensitive
and may be either 'c'or 'c++'.

The optional 'No_Scanner' argument in the C<c_compiler>
specialization specifies that the processing overhead of scanning
all the source files for their dependency trees is unnecessary.
If you are only building from clean source file hierarchies (with
no existing products from previous runs), then the construction
time of large builds may be improved with this option.

=head1 SEE ALSO

More documentation can be found in L<Conjury>, L<cast>, L<Conjury::Core>
and L<Conjury::C>.

=head1 AUTHOR

James Woodyatt <jhw@wetware.com>
