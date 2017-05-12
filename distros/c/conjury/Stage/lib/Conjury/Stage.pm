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

Conjury::Stage - Perl Conjury staging areas

=head1 SYNOPSIS

  use Conjury::Stage;

  $stage = Conjury::Stage->new ( I<HASH> );
  $stage->make_subdir ( F<filename> );

  ($basedir, $subdir) = find_stage ( F<directory> );

=head1 DESCRIPTION

The F<Conjury::Stage> module defines the object class used to model a staging
area for intermediate constructions.  A stage contains a journal object and
methods for creating new subdirectories in the staging area.  The C<find_stage>
function is also defined for parsing a pathname and returning the base
directory of the stage and the relative remainer of the pathname.

A "stage" is an association between a directory and a journal object mapped to
a file in that directory with a standard name.  On most platforms, journal
files in a stage are named F<.conjury-journal>, but some filesystems have funny
conventions so your experience may vary.

=over 4

=cut

my (%prototype, %validator);

package Conjury::Stage;

BEGIN {
    require Conjury::Core::Prototype;
    use Exporter ();

    use vars qw($VERSION @ISA @EXPORT_OK @EXPORT %EXPORT_TAGS);

    $VERSION = 1.01;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(%Stage_By_Directory);
    @EXPORT = qw(find_stage);
}

use subs qw(find_stage);
use vars qw(%Stage_By_Directory);

%Stage_By_Directory = ( );

BEGIN {
    $validator{scalar_or_hash} = sub {
	my ($x, $y) = (shift, undef);
	$y = 'not a SCALAR or a HASH'
	  unless (defined $x and (!ref $x or ref $x eq 'HASH'));
	return $y;
    };
}

use Conjury::Core qw(%Option $Current_Context cast_error);
use Carp qw(croak);
use Cwd qw(abs_path);
use File::Spec;
use File::Path qw(mkpath);

my %journal_name;

sub _new_f()    { __PACKAGE__ . '::new' }

BEGIN {
    my $proto;

    $proto = Conjury::Core::Prototype->new;
    $proto->optional_arg
      (Directory => \&Conjury::Core::Prototype::validate_scalar);
    $proto->optional_arg
      (Journal => $validator{scalar_or_hash});
    $prototype{_new_f()} = $proto;

    $journal_name{VMS} = 'CONJURY.JNL';
    $journal_name{os2} = 'conjury.jnl';
    $journal_name{MacOS} = 'conjury journal';
    $journal_name{MSWin32} = 'CONJURY.JNL';

    use vars qw($AUTOLOAD);
}

=pod

=item Conjury::Stage->new

Creates a stage object associated with a directory.  The arguments are named in
a hash.  All of them are optional.

Use the optional 'Directory' argument to associate the stage with a directory
other than the one associated with the current context.

Use the optional 'Journal' argument to associate the stage explicitly with a
specific journal object.

=cut

sub new {
    my ($class, %arg) = @_;
    my $error = $prototype{_new_f()}->validate(\%arg);
    croak _new_f, "-- $error" if $error;

    my $directory = $arg{Directory};
    my $curdir = $Current_Context->Directory;
    $directory = $curdir unless defined($directory);
    $directory = abs_path($directory);
    croak _new_f, "-- stage at '$directory' already defined."
	if exists($Stage_By_Directory{$directory});

    mkpath $directory, 1, (0777 ^ umask);

    my $journal = $arg{Journal};
    if (!defined($journal)) {
	$journal = $journal_name{$^O};
	$journal = '.conjury-journal' unless defined($journal);
    }
    if (!ref($journal)) {
	$journal = File::Spec->catfile($directory, $journal);
	$journal = File::Spec->canonpath($journal);

	$journal = eval {
	    my %journal;
	    tie %journal, 'Conjury::Core::Journal', $journal;
	    \%journal;
	};
	
	die $@ if $@;
    }

    my $self = { };
    bless $self, $class;

    $self->{Directory} = $directory;
    $self->{Journal} = $journal;

    print "Stage: $directory\n" if exists($Option{'verbose'});
    $Stage_By_Directory{$directory} = $self;
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

=pod

=item $stage->make_subdir(F<directory>)

Creates a subdirectory within the stage.  The named subdirectory must be
specified by relative path.  The subdirectory is created during the compile
phase.

=cut

sub make_subdir {
    my ($self, $directory) = @_;
    croak __PACKAGE__, '::make_subdir-- argument mismatch'
	unless (ref($self) && !ref($directory)
		&& !File::Spec->file_name_is_absolute($directory));

    $directory = File::Spec->catdir($self->{Directory}, $directory);
    $directory = File::Spec->canonpath($directory);
    mkpath $directory, 1, (0777 ^ umask);
}

=pod

=back

=head2 Exported Functions

There is only one exported function: C<find_stage>.  Whether this should be
only made available as an object method is an argument not settled yet.

=over 4

=cut

sub _find_stage_f()     { __PACKAGE__ . '::find_stage'      }

=pod

=item find_stage F<directory>

Finds the stage object for the specified directory.

In array context, this returns a 2-tuple of the base directory for the stage
object and the relative path from the base to specified directory.

=cut

sub find_stage {
    my $directory = $_[0];
    $directory = $Current_Context->Directory
	unless (defined($directory) || !defined($Current_Context));
    croak _find_stage_f, '-- argument mismatch'
      unless (@_ <= 1 && !ref($directory));

    $directory = abs_path($directory);
    $directory = File::Spec->canonpath($directory);

    my $stage_dir = $directory;
    my ($stage, $subdir);
    while (1) {
	$stage = $Stage_By_Directory{$stage_dir};
	last if (defined($stage) || $stage_dir eq File::Spec->rootdir);
	
	my $name;
	($stage_dir, $name) = (dirname($stage_dir), basename($stage_dir));
	$subdir = defined($subdir)
	    ? File::Spec->catdir($name, $subdir) : $name;
    }

    $stage = Conjury::Stage->new(Directory => $directory)
	unless defined($stage);

    if (wantarray) {
	my @result = ($stage);
	push @result, $subdir if defined($subdir);
	return @result;
    }
    else {
	return $stage;
    }
}

1;

__END__

=pod

=back

=head1 AUTHOR

James Woodyatt <F<jhw@wetware.com>>
