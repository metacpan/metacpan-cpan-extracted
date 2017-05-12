package inc::MBwishlist;

# Copyright (C) 2006, by Eric Wilhelm
# License: perl

# I'm waiting on upstream releases on this stuff

use warnings;
use strict;
use Carp;

=head1 ACTIONS

=over

=item testall

Run all tests.

=cut

sub ACTION_testall {
  my $self = shift;

  my $p = $self->{properties};
  my @test_types = ('t',
    ($p->{test_types} ? keys(%{$p->{test_types}}) : ())
  ); 
  $self->generic_test(types => \@test_types);
}

=back

=cut

=begin devnotes

=head1 WHAT'S ALL THIS THEN?

I added the concept of test types (or groups) to Module::Build in this
subclass.  This really needs to go upstream.

=end devnotes

=cut

sub ACTION_test {
  my $self = shift;

  $self->generic_test(type => 't');
}
# stolen from M::B::B::ACTION_test
sub generic_test {
  my $self = shift;
  (@_ % 2) and
    croak('Odd number of elements in argument hash');
  my %args = @_;
  
  my @types = (
    (exists($args{type})  ? $args{type} : ()), 
    (exists($args{types}) ? @{$args{types}} : ()),
    );
  @types or croak "need some types of tests to check";

  my $p = $self->{properties};
  require Test::Harness;
  
  $self->depends_on('code');
  
  # Do everything in our power to work with all versions of Test::Harness
  my @harness_switches = $p->{debugger} ? qw(-w -d) : ();
  local $Test::Harness::switches    = join ' ', grep defined, $Test::Harness::switches, @harness_switches;
  local $Test::Harness::Switches    = join ' ', grep defined, $Test::Harness::Switches, @harness_switches;
  local $ENV{HARNESS_PERL_SWITCHES} = join ' ', grep defined, $ENV{HARNESS_PERL_SWITCHES}, @harness_switches;
  
  $Test::Harness::switches = undef   unless length $Test::Harness::switches;
  $Test::Harness::Switches = undef   unless length $Test::Harness::Switches;
  delete $ENV{HARNESS_PERL_SWITCHES} unless length $ENV{HARNESS_PERL_SWITCHES};
  
  local ($Test::Harness::verbose,
	 $Test::Harness::Verbose,
	 $ENV{TEST_VERBOSE},
         $ENV{HARNESS_VERBOSE}) = ($p->{verbose} || 0) x 4;

  # Make sure we test the module in blib/
  local @INC = (File::Spec->catdir($p->{base_dir}, $self->blib, 'lib'),
		File::Spec->catdir($p->{base_dir}, $self->blib, 'arch'),
		@INC);

  # Filter out nonsensical @INC entries - some versions of
  # Test::Harness will really explode the number of entries here
  @INC = grep {ref() || -d} @INC if @INC > 100;
  
  my $tests = $self->find_test_files(@types);

  if (@$tests) {
    # Work around a Test::Harness bug that loses the particular perl
    # we're running under.  $self->perl is trustworthy, but $^X isn't.
    local $^X = $self->perl;
    Test::Harness::runtests(@$tests);
  } else {
    $self->log_info("No tests defined.\n");
  }

  # This will get run and the user will see the output.  It doesn't
  # emit Test::Harness-style output.
  if (-e 'visual.pl') {
    $self->run_perl_script('visual.pl', '-Mblib='.$self->blib);
  }
}
sub expand_test_dir {
  my $self = shift;
  my ($dir, @types) = @_;

  my $p = $self->{properties};

  my @tfiles;
  my @typelist;
  foreach my $type (@types) {
    # old-school
    if($type eq 't') { push(@typelist, 't'); next; }

    defined($p->{test_types}) or
      Carp::confess("cannot have typed testfiles without 'test_types' data");
    defined($p->{test_types}{$type}) or
      croak "no test type '$type' is defined";
    push(@typelist, $p->{test_types}{$type});
  }
  #warn "expand_test_dir($dir, @types) @typelist";
  #do('./util/BREAK_THIS') or die;
  if($self->recursive_test_files) {
    push(@tfiles, @{$self->rscan_dir($dir, qr{^[^.].*\.$_$})})
      for(@typelist);
  }
  else {
    push(@tfiles, glob(File::Spec->catfile($dir, $_)))
      for(map({"*.$_"} @typelist));
  }
  $p->{verbose} and warn "found ", scalar(@tfiles), " test files\n";
  return(sort(@tfiles));
}

sub find_test_files {
  my $self = shift;
  my (@types) = @_;

  my $p = $self->{properties};
  
  if (my $files = $p->{test_files}) {
    $files = [keys %$files] if UNIVERSAL::isa($files, 'HASH');
    $files = [map { -d $_ ? $self->expand_test_dir($_, @types) : $_ }
	      map glob,
	      $self->split_like_shell($files)];
    
    # Always given as a Unix file spec.
    return [ map $self->localize_file_path($_), @$files ];
    
  } else {
    # Find all possible tests in t/ or test.pl
    my @tests;
    push @tests, 'test.pl'                                  if -e 'test.pl';
    push @tests, $self->expand_test_dir('t', @types)        if -e 't' and -d _;
    return \@tests;
  }
}

1;
