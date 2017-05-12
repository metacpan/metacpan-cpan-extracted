package Test::StubGenerator;

use strict;
use warnings;

use PPI 1.118;
use Perl::Tidy;
use Carp;
use English qw( -no_match_vars );

use version; our $VERSION = qv('0.9.6');

my %DEFAULT_OPTIONS = ( file      => undef,
                        source    => undef,
                        output    => undef,
                        out_dir   => undef,
                        tidy      => 1,
                        pertidyrc => '~/.perltidyrc', );

sub new {
  my( $class, $arg_ref ) = @_;
  my $self = {};

  # Collect the options passed in, defaulting to the, uh ... defaults.
  my %option_args =
    ref $arg_ref eq 'HASH'
    ? ( %DEFAULT_OPTIONS, %{$arg_ref} )
    : %DEFAULT_OPTIONS;
  $self->{file}       = $option_args{file};
  $self->{source}     = $option_args{source};
  $self->{output}     = $option_args{output};
  $self->{out_dir}    = $option_args{out_dir};
  $self->{tidy}       = $option_args{tidy};
  $self->{perltidyrc} = $option_args{perltidyrc};
  $self->{structure}  = {};

  # Trim trailing slashes if present for easier interpolation later.
  $self->{out_dir} =~ s{ / $ }{}xms if $self->{out_dir};

  # One or the other of these need to be non-false.
  my $code = $self->{file} || $self->{source};
  $code or die "No code provided to Test::StubGenerator\n";    # :)

  # Also, if we can't create a new PPI document from the file or
  # code passed in, we're in trouble.
  $self->{doc} = PPI::Document->new( $code, readonly => 1, )
    or croak "Unable to initialize PPI document: $!";

  return bless $self, $class;
}

# Find something in the PPI doc that we're looking for.
sub _find {
  my( $self, $sub_ref, $item_type ) = @_;
  my $item_ref = $self->{doc}->find($sub_ref);
  if($item_ref) {
    return $item_ref;
  }
  else {
    carp "No $item_type found";
  }
  return;
}

# In this case, we want things that are PPI::Subs and have names, but are
# not 'Scheduled' - i.e. BEGIN, CHECK, INIT, END blocks.
sub _find_subs {
  my $self = shift;
  my $subs_ref = $self->_find(
    sub {
      $_[1]->isa('PPI::Statement::Sub')
        && ! $_[1]->isa('PPI::Statement::Scheduled')
        && $_[1]->name;
    },
    'subs', );
  for my $sub ( @{$subs_ref} ) {
    $self->_process_sub($sub);
  }
  return;
}

# We're looking for package declarations.  Not all code has a declared
# package, and that may or may not be a problem.
sub _find_package {
  my $self = shift;
  my $pkg_ref = $self->_find(
    sub {
      $_[1]->isa('PPI::Statement::Package') && $_[1]->namespace;
    },
    'packages', );

  for my $pkg ( @{$pkg_ref} ) {
    $self->{structure}->{package} = $pkg->namespace;
  }
  return;
}

# We've been passed a named, non-scheduled PPI::Statement::Sub.
sub _process_sub {
  my( $self, $sub ) = @_;

  # Let's examine the block defined for it.
  my $block = $sub->block;
  my @variables;

  # Keep track of all the variables passed into the subroutine.
  for my $statement ( $block->children ) {
    if( $statement->isa('PPI::Statement::Variable') ) {
      $self->_get_variables( $statement, \@variables );
    }
  }

  # Add the subroutine to the methods hash along with all associated variables
  # that we were able to find.
  $self->{structure}->{methods}->{ $sub->name } = [@variables];
  return;
}

sub _get_variables {
  my( $self, $statement, $vars_ref ) = @_;

  # If any of the statements children contains "@_"...
  if( scalar grep { $_->isa('PPI::Token::Magic') } $statement->children ) {
    push @{$vars_ref},    # keep all variables unpacked from @_.
      grep { $_ ne '$self' } $statement->variables;    # other than $self
  }

  # If any of the statements' children assigns using shift...
  if( scalar grep { $_->content eq 'shift' } $statement->children ) {
    push @{$vars_ref},    # keep all variables shifted to.
                          # other than $self, $class, or $package
      grep { $_ !~ /(?:\$self|\$class|\$package)/ } $statement->variables;
  }
  return;
}

sub gen_testfile {
  my $self = shift;

  # do a majority of the work here.
  $self->_find_package();
  $self->_find_subs();

  # start the testfile text.
  my $test_file = _test_file_header();

  my $package = $self->{structure}->{package};

  # Add a little extra testing goodness if we're dealing with a package.
  $test_file .= $self->_generate_preamble($package);

  my $declarations = q();
  my $tests        = q();
  my @vars;
  for my $sub ( sort keys %{ $self->{structure}->{methods} } ) {
    my $vars_ref = $self->{structure}->{methods}->{$sub};
    for my $var ( @{$vars_ref} ) {

      # Add handy testing variable declarations to the test file...
      if( ! scalar grep { $_ eq $var } @vars ) {
        my $arg_decl;
        if( $var =~ /^\%/ ) {
          $arg_decl = q{( '' => '', )};
        }
        elsif( $var =~ /^\@/ ) {
          $arg_decl = q{( '', )};
        }
        else {
          $arg_decl = q{''};
        }
        $declarations .= "my $var = " . sprintf "%s;\n", $arg_decl;

        # declare properly hash v. arr v. sclr
      }

      # ... assuming we haven't run across them already.
      push @vars, $var;
    }

    # If we've got a package, precede all method calls with the object.
    my $object_call = $package ? '$obj->' : q();
    {    # A little easier to interpolate the array directly.
      local $LIST_SEPARATOR = ', ';
      $tests .= "ok( $object_call$sub( @{ $vars_ref } ), "
        . "'can call $object_call$sub()' );\n"
        if @{$vars_ref};
    }

    # add a test calling the subroutine without parameters.
    $tests .= "ok( $object_call$sub(), "
      . "'can call $object_call$sub() without params' );\n";
    $tests .= "\n";
  }

  # Put it all together.
  $test_file .= _assemble_tests( $package, $declarations, $tests );

  # Tidy the output if desired
  if( $self->{tidy} ) {
    perltidy( source      => \$test_file,
              destination => \$test_file,
              perltidyrc  => $self->{perltidyrc} );
  }
  return $self->_handle_output($test_file);
}

sub _generate_preamble {
  my( $self, $package ) = @_;
  my $test_file = q();

  if($package) {

    # Well packaged modules may not need the explicit 'use lib' statement.
    # But in the off chance that `make test` doesn't set -I, the tests
    # will still run.
    my $pkg_hierarchy = $package =~ m/::/g;
    if( $pkg_hierarchy > 0 ) {
      my $use_lib = join q(/), q(..) x $pkg_hierarchy;
      $test_file .= "use lib '$use_lib';\n\n";
    }

    # Add the BEGIN block to the tests.
    $test_file .= "BEGIN { use_ok( '$package' ); }\n\n";
  }
  else {

   # If it's not a package, chances are it should be required instead of used.
    $test_file .= "BEGIN { require_ok( '$self->{ file }' ); }\n\n"
      if $self->{file};    # If it's not a file, we really can't require it.
  }

  my $constructor_found = 0;
  for my $constructor (qw{ new instance }) {

    # If it's a package and has a constructor...
    if( $package && defined $self->{structure}->{methods}->{$constructor} ) {
      $constructor_found++;    # controls whether or not we test the interface

      # Add tests for it.
      $test_file .= 'ok( my $obj = ' . $package
        . "->$constructor(), 'can create object $package' );\n";
      $test_file .= "isa_ok( \$obj, '$package', 'object \$obj' );\n";

     # It seems that testing Test::StubGenerator->can( '$constructor' ); as an
     # element of its interface makes less sense since by this
     # point in the test file, we've aready used it. :)
      delete $self->{structure}->{methods}->{$constructor};

    }
  }

  # Add interface tests.
  if($constructor_found) {
    my @methods = sort keys %{ $self->{structure}->{methods} };
    if( scalar @methods ) {

      # A little easier to interpolate the array directly.
      local $LIST_SEPARATOR = q(', ');
      $test_file .= "can_ok( \$obj, '@methods' );\n\n";
    }
  }
  return $test_file;
}

sub _handle_output {
  my( $self, $test_file ) = @_;
  if( defined $self->{output} ) {
    if( ref $self->{output} eq 'GLOB' ) {

      # We've got a filehandle - print to it.
      print { $self->{output} } $test_file
        or croak "Can't write to file specified: $!";
      return 1;
    }
    elsif( defined $self->{out_dir} && -d $self->{out_dir} ) {

      # We've got an existent directory for output.
      return $self->_write_file($test_file)
        or croak
        "Can't write the test file to the directory as specified: $!";
    }
    else {
      croak sprintf q(Can't write to file '%s' in directory '%s/'.),
        $self->{output}, $self->{out_dir};
    }
  }
  else {

    # Must be looking to have the text returned to them.
    return $test_file;
  }
  return;
}

sub _write_file {
  my( $self, $test_file ) = @_;
  my $filename = $self->{structure}->{package}
    ? $self->{structure}->{package}    # give preference to found package name
    : $self->{output};
  $filename =~ s{
                  ^           # Start of string
                  (?:         # Don't capture this grouping
                    [\w/]*    #   zero or more word or slash chars
                    /         #   followed by a slash
                  )?          # end (optional) grouping
                  (\w+)       # one or more word characters
                  (?:         # Don't capture this grouping
                     \.p[ml]  #   possibly with a pm or pl extension
                  )?          # end (optional) grouping
                  $           # End of string;
                }
                {$1.t}x;    # Give it a .t extension
  open my $test_fh, '>', "$self->{out_dir}/$filename"
    or croak "Can't open file for writing: $!";
  print {$test_fh} $test_file or croak "Can't write to file: $!";
  close $test_fh or carp "Can't close file: $!";
  return 1;
}

# A "theredoc", to keep it out of the other subroutines.
sub _assemble_tests {
  my( $package, $declarations, $tests ) = @_;
  my $assemblage;
  $assemblage = <<"ASSEMBLED_TESTS" if $package;
# Create some variables with which to test the $package objects' methods
# Note: give these some reasonable values.  Then try unreasonable values :)
ASSEMBLED_TESTS
  $assemblage .= <<"ASSEMBLED_TESTS";
$declarations
# And now to test the methods/subroutines.
$tests
ASSEMBLED_TESTS
  return $assemblage;
}

# A "theredoc", to keep it out of the other subroutines.
sub _test_file_header {
  return <<'TEST_FILE_HEADER';
#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;

TEST_FILE_HEADER
}

1;
__END__

=head1 NAME

Test::StubGenerator - A simple module that analyzes a given source file and
automatically generates t/*.t style tests for subroutines/methods
it encounters.

=head1 SYNOPSIS

  use Test::StubGenerator;

  my $stub = Test::StubGenerator->new(
    {
      file => '/path/to/MyModule.pm',
      tidy   => 1,
    }
  );

  print $stub->gen_testfile;

Or, from the command line (split for easier reading):

  $ perl -MTest::StubGenerator -e '
  > my $stub = Test::StubGenerator->new({ file => "Module.pm" });
  > print $stub->gen_testfile;' > Module.t

=head1 DESCRIPTION

Test::StubGenerator is a module that attempts to analyze a given source file
and automatically create testing stubs suitable for unit testing your code.

Test::StubGenerator make use of PPI in order to parse your code, looking for
constructors and methods for modules (.pm), and subroutines for Perl script
files (.pl).

Test::StubGenerator also runs the generated tests through Perl::Tidy before
returning the text of the tests to you, though this can be disabled.

The idea for Test::StubGenerator grew out of a vim plugin I wrote that created
test stub files in a very similar fashion.  However, the line-based nature of
vimscript quickly indicated that adding default parameters to the tests would
prove to be an exercise in futility.  As this was a feature I very much wanted
to implement, I naturally turned to Perl, and L<PPI>.

=head1 CONSTRUCTOR AND OPTIONS

=head2 $stub = Test::StubGenerator->new( { file => 'MyModule.pm' } );

Alternatively:

  my %options = (
    file => '/path/to/Module.pm',
  );

  my $stub - Test::StubGenerator->new( \%options );

The full list of options:

=head3 file

Specify the path to the module or source code file for which you want to
generate test stubs.

=head3 source

Alternatively, if the code for which you want to create tests is already in a
scalar, pass a reference to that scalar as the named source argument.

=head3 tidy

Pass a true value to indicate that you'd like your generated tests run through
Perl::Tidy before being returned.  This is the default.  Specify a false
value to disable this feature.  Note, this will by default use
your ~/.perltidyrc file for formatting.

=head3 perltidyrc

If you have a particular perltidyrc file, specify its location in this option.
Otherwise, the default is to use ~/.perltidyrc.

=head3 output

Pass a filename or an open filehandle to direct the output to.  If this option
isn't specified, then gen_testfile() returns the textual data directly.

=head3 out_dir

Specify a directory for which to save your generated test file.

=head1 METHODS

=head2 $stub->gen_testfile()

This is really the only method you need to know - after you've created a
Test::StubGenerator object, simply call $teststub->gen_testfile().

=head1 DEPENDENCIES

Requires L<PPI> and L<Perl::Tidy> to be installed.

=head1 DIAGNOSTICS

=head3 "No code provided to Test::StubGenerator"

This means you've attempted to instantiate a new Test::StubGenerator object
without specifying a file for Test::StubGenerator to analyze.  Either pass a
filename for Test::StubGenerator to analyze and create tests for, or a
reference to a scalar containing the source code you wish to analyze.

=head3 "Unable to initialize PPI document"

This means that the source you've passed to Test::StubGenerator has major
problems, and PPI is unable to parse it.  At the very least, ensure your
code can pass `perl -Mstrict -wc <filename>` before attempting to generate
tests for it with Test::StubGenerator.

=head3 "No [ packages | subs ] found"

This is just a warning message indicating that Test::StubGenerator didn't
find any of the items of the specified type in your code.  The functionality
that Test::StubGenerator supplies might be less than optimal if the code you're
analyzing doesn't contain any subroutines. :)

=head3 "No output generated"

This means that Test::StubGenerator wasn't able to produce output in the
desired format according to the options passed to the constructor.  Possible
issues are: 1) a directory doesn't exist, 2) you don't have permission to
write to it, 3) the filesystem is full, 4) something is Very Broken.

=head3 "Can't call method "gen_testfile"..."

This probably means that you've trapped an exception with eval, but ignored
it by not checking if $@ ($EVAL_ERROR) has been set, and your code has
attempted to call gen_testfile() without ensuring that creating a
Test::StubGenerator object has been sucessfully created and initialized.

=head3 "Can't open file for writing: Permission denied"

You have passed an output directory (out_dir) that you don't have permission
to write to.  Make sure you have the apropriate permission to the directory
you wish to create test files in.

=head3 "Can't write to file 'filename' in directory 'directory'..."

This means that you have passed an output directory that doesn't exist.
Please double check that any directory you specify in the named out_dir
parameter to new() exist and are writeable by your effective user id.

=head1 SEE ALSO

L<PPI>, L<Perl::Tidy>

=head1 VERSION

This documentation describes Test::StubGenerator version 0.9.6.

=head1 AUTHOR

Kent Cowgill, C<kent@c2group.net> L<http://www.kentcowgill.org/>

=head1 REQUESTS & BUGS

Please report any requests, suggestions, or bugs via the RT bug-tracking
system at http://rt.cpan.org/.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::StubGenerator> is the RT queue
for Test::StubGenerator.  Please check to see if your bug has already been
reported.

=head1 ACKNOWLEDGEMENTS

Many thanks to the giants whose shoulders I stand upon, including Adam
Kennedy, and Steve Hancock.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2009 by Kent Cowgill

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
