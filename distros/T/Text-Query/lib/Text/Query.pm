#
#   Copyright (C) 1999 Eric Bohlman, Loic Dachary
#   Copyright (C) 2013 Jon Jensen
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.  You may also use, redistribute and/or modify it
#   under the terms of the Artistic License supplied with your Perl
#   distribution
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 

package Text::Query;

use strict;

use vars qw($VERSION);

$VERSION = '0.09';

use Carp;

sub new {
  my($class) = shift;
  my($self) = {};
  bless $self,$class;
  if(@_ % 2) {
      my($qstring) = shift;
      $self->configure(@_);
      return defined($qstring) ? $self->prepare($qstring, @_) : $self;
  } else {
      $self->configure(@_);
      return $self;
  }
}

sub configure {
    my($self, %args) = @_;

    $self->{-verbose} = $args{-verbose} || 0 if(!defined($self->{-verbose}));

    my(%defconfigs) = (
      simple_text =>
        { -parse => 'Text::Query::ParseSimple',
          -build => 'Text::Query::BuildSimpleString',
          -optimize => 'Text::Query::Optimize',
          -solve => 'Text::Query::SolveSimpleString'
        },
       advanced_text =>
        { -parse => 'Text::Query::ParseAdvanced',
          -build => 'Text::Query::BuildAdvancedString',
          -optimize => 'Text::Query::Optimize',
          -solve => 'Text::Query::SolveAdvancedString'
        },
    );

    my $default=(defined $args{-mode})?$args{-mode}:'simple_text';
    my($key);
    foreach $key (keys(%{$defconfigs{$default}})) {
        my($package) = $args{$key} ? $args{$key} : $defconfigs{$default}{$key};
	my($load) = !exists($self->{'packages'}{$key}) || $self->{'packages'}{$key} ne $package;

	if($load) {
	    $self->{$key} = $self->loader($package);
	    $self->{$key}->{-verbose} = $self->{-verbose};
	    warn("loaded $package => $self->{$key}") if($self->{-verbose});
	    $self->{'packages'}{$key} = $package;
	}
    }
    $self->{-parse}->{-build} = $self->{-build};
}

sub loader {
    my($self, $package) = @_;

    eval "package Text::Query::_firesafe; require $package";

    if ($@) {
	my($advice) = "";
	if($@ =~ /Can't find loadable object/) {
	    $advice = "Perhaps $package was statically linked into a new perl binary."
		 ."\nIn which case you need to use that new perl binary."
		 ."\nOr perhaps only the .pm file was installed but not the shared object file."
	} elsif ($@ =~ /Can't locate.*?.pm/) {
	    $advice = "Perhaps the $package perl module hasn't been installed\n";
	}
	croak("$package failed: $@$advice\n");
    }
    my($object);
    $object = eval { $package->new() };
    croak("$@") if(!defined($object));

    return $object;
}

sub matchexp {
    my($self) = @_;

    return $self->{matchexp};
}

sub matchstring {
    my($self) = @_;

    return $self->{-build}->matchstring();
}

#
# Parse interface
#

sub prepare {
  my($self) = shift;

  $self->{matchexp} = $self->{-optimize}->optimize($self->{-parse}->prepare(@_));

  return $self;
}

#
# Solve interface
#

sub match {
    my($self) = shift;

    croak("solve undefined") if(!$self->{-solve});

    return $self->{-solve}->match($self->{matchexp}, @_);
}

sub matchscalar {
    my($self) = shift;

    croak("solve undefined") if(!$self->{-solve});

    return $self->{-solve}->matchscalar($self->{matchexp}, @_);
}

#
# Accessors
#

sub build {
    my($self) = shift;
    return $self->{-build};
}

sub parse {
    my($self) = shift;
    return $self->{-parse};
}

sub solve {
    my($self) = shift;
    return $self->{-solve};
}

sub optimize {
    my($self) = shift;
    return $self->{-optimize};
}

1;

__END__

=head1 NAME

Text::Query - Query processing framework

=head1 SYNOPSIS

    use Text::Query;
    
    # Constructor
    $query = Text::Query->new([QSTRING] [OPTIONS]);

    # Methods
    $query->prepare(QSTRING [OPTIONS]);
    $query->match([TARGET]);
    $query->matchscalar([TARGET]);

=head1 DESCRIPTION

This module provides an object that matches a data source
against a query expression.

Query expressions are compiled into an internal form when a new object is created 
or the C<prepare> method is 
called; they are not recompiled on each match.

The class provided by this module uses four packages to process the query.
The query parser parses the question and calls a query expression
builder (internal form of the question). The optimizer is then called
to reduce the complexity of the expression. The solver applies the expression
on a data source. 

The following parsers are provided:

=over 4

=item Text::Query::ParseAdvanced

=item Text::Query::ParseSimple

=back

The following builders are provided:

=over 4

=item Text::Query::BuildAdvancedString

=item Text::Query::BuildSimpleString

=back

The following solver is provided:

=over 4

=item Text::Query::SolveSimpleString

=item Text::Query::SolveAdvancedString

=back

=head1 EXAMPLES

  use Text::Query;
  my $q=new Text::Query('hello and world',
                        -parse => 'Text::Query::ParseAdvanced',
                        -solve => 'Text::Query::SolveAdvancedString',
                        -build => 'Text::Query::BuildAdvancedString');
  die "bad query expression" if not defined $q;
  print if $q->match;
  ...
  $q->prepare('goodbye or adios or ta ta',
              -litspace => 1,
              -case => 1);
  #requires single space between the two ta's
  if($q->match($line)) {
  #doesn't match "Goodbye"
  ...
  $q->prepare('"and" or "or"');
  #quoting operators for literal match
  ...
  $q->prepare('\\bintegrate\\b', -regexp => 1);
  #won't match "disintegrated"

=head1 CONSTRUCTOR

=over 4

=item new ([QSTRING] [OPTIONS])

This is the constructor for a new Text::Query object.  If a C<QSTRING> is 
given it will be compiled to internal form.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<-parse> - Package name of the parser. Default is Text::Query::ParseSimple.

B<-build> - Package name of the builder. Default is Text::Query::Build.

B<-optimize> - Package name of the optimizer. Default is Text::Query::Optimize.

B<-solve> - Package name of the solver. Default is Text::Query::Solve.

B<-mode> - Name of predefined group of packages to use.  Options are
           currently C<simple_text> and C<advanced_text>.

These options are handled by the C<configure> method.

All other options are passed to the parser C<prepare> function.
See the corresponding manual pages for a description.

If C<QSTRING> is undefined, the prepare function is not called.

The constructor will croak if a C<QSTRING> was supplied and had 
illegal syntax.

=back

=head1 METHODS

=over 4

=item configure ([OPTIONS])

Set the C<parse>, C<build>, C<optimize> or C<solve> packages. See the
C<CONSTRUCTOR> description for explanations.

=item prepare (QSTRING [OPTIONS])

Compiles the query expression in C<QSTRING> to internal form and sets any 
options (same as in the constructor).  C<prepare> may be used to change 
the query expression and options for an existing query object.  If 
C<OPTIONS> are omitted, any options set by a previous call to 
C<prepare> are persistent.

The optimizer (-optimize) is called with the result of the parser (-parse).
The parser uses the builder (-build) to construct the internal form.

This method returns a reference to the query object if the syntax of the 
expression was legal, or croak if not.

=item match ([TARGET])

Calls the match method of the solver (-solve).

=item matchscalar ([TARGET])

Calls the matchscalar method of the solver (-solve).

=back

=head1 SEE ALSO

Text::Query::ParseAdvanced(3),
Text::Query::ParseSimple(3),
Text::Query::BuildSimpleString(3),
Text::Query::BuildAdvanedString(3),
Text::Query::SolveSimpleString(3),
Text::Query::SolveAdvancedString(3),

Text::Query::Build(3),
Text::Query::Parse(3),
Text::Query::Solve(3),
Text::Query::Optimize(3)

=head1 MAINTENANCE

=over

=item https://github.com/jonjensen/Text-Query

=item https://rt.cpan.org//Dist/Display.html?Queue=Text-Query

=back

=head1 AUTHORS

Eric Bohlman (ebohlman@netcom.com)

Loic Dachary (loic@senga.org)

Jon Jensen, jon@endpoint.com

=cut

# Local Variables: ***
# mode: perl ***
# End: ***
