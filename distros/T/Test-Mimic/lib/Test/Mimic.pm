package Test::Mimic;

use strict;
use warnings;

use Test::Mimic::Library qw<
    load_records
    init_records
    load_preferences
    ARBITRARY
>;
use Test::Mimic::Generator;

our $VERSION = 0.009_007;

# Preloaded methods go here.

# Private to the Test::Mimic suite.
{
    my @pristine_INC;

    # Returns @INC to its state prior to when require_from was called.
    # Generated packages must call this before using any external modules.
    sub prepare_for_use {
        if (@pristine_INC) {
            @INC = @pristine_INC;
            @pristine_INC = ();
        }
    }
    
    # Accepts a package to require and a directory name to load it from.
    # This will modify @INC while it is running, but return restore it
    # prior to exiting.
    sub require_from {
        my ( $package, $dir ) = @_;
        
        @pristine_INC = @INC;
        @INC = ($dir);
        
        # Load the package
        my $success = eval( "require $package; 1" );

        # Undo the @INC change
        prepare_for_use();

        return $success;
    }
}

my $save_to;            # The directory to read/write recorded behavior.
my $recording_required; # Will be set to true iff a package was requrested that has not yet been recorded.

# See the POD below.
sub import {
    my ( $class, $user_preferences ) = @_;

    if ( ! defined($user_preferences) ) {
        die 'No preference hash reference passed to import in Test::Mimic.';
    }

    my %preferences = %{$user_preferences};

    if ( ! defined( $preferences{'packages'} ) ) {
        die 'No packages selected to mimic.';
    }

    $preferences{'test_mimic'} = ARBITRARY;
    $save_to = $preferences{'save'} ||= '.test_mimic_data';

    # Setup the library to behave per user preferences.
    my $history = $save_to . '/history_for_playback.rec';
    if ( -e $history ) { # This won't be true if we haven't recorded at all before.
        load_records($history);
    }
    else {
        init_records();
    }
    load_preferences(\%preferences);

    # Attempt to load mimicked versions of each package. Note those that have not been recorded.
    my $lib_dir = $save_to . '/lib';
    my $playback_stage = 0;
    my @to_record;
    for my $package_to_mimic ( keys %{ $preferences{'packages'} } ) {
        if ( ! require_from( $package_to_mimic, $lib_dir ) ) {
            push( @to_record, $package_to_mimic );
        }
        else {
            $playback_stage = 1; 
        } 
    }

    # Prevent playback/recording conflicts.
    if ( $playback_stage && @to_record > 0 ) {
        die "The playback stage and the recording stage can not coincide. Either delete the current" .
            "recordings or stop mimicking the following package(s): @to_record";
    }

    # Record the missing packages.
    if ( @to_record != 0 ) {
        $recording_required = 1;
        require Test::Mimic::Recorder;
        my %recorder_prefs = %preferences;

        #Only include those packages that need recording.
        $recorder_prefs{'packages'} = {};
        for my $package (@to_record) {
            $recorder_prefs{'packages'}->{$package} = $preferences{'packages'}->{$package};
        }
        Test::Mimic::Recorder->import(\%recorder_prefs);
    }
}

# Handles the code generation after the recording is complete.
# NOTE: This relies on the LIFO structure of END block execution.
END {
    if ($recording_required) {
        my $generator = Test::Mimic::Generator->new();
        $generator->load($save_to);
        $generator->write($save_to);
    }
}

1;
__END__

=head1 NAME

Test::Mimic - Perl module for automatic package and object mocking via recorded data.

=head1 SYNOPSIS

  # Mimic the Foo::Bar package with defaults.
  use Test::Mimic { 'packages' => { 'Foo::Bar' => {} } };

  # Mimic the Foo::Bar package with alternatives.
  use Test::Mimic {
      'save'      => '.test_mimic_data',
      'string'    => sub {}, # The sub {} construction simply represents a subroutine reference.
      'destring'  => sub {}, # See below for appropriate contracts.

      'key'           => sub {},
      'monitor_args'  => sub {},
      'play_args'     => sub {},

      'packages'  => {
          'Foo::Bar'  => {
              'scalars'   => [ qw< x y z > ],

              'key'           => sub {},
              'monitor_args'  => sub {},
              'play_args'     => sub {},

              'subs' => {
                  'foo' => {
                      'key'           => sub {},
                      'monitor_args'  => sub {},
                      'play_args'     => sub {},
                  },
              },
          },
      },
  };

=head1 DESCRIPTION

Test::Mimic allows one to easily mock a package by first recording its behavior and then playing it back.
All that is required is to use Test::Mimic prior to loading the real packages and then run the desired
program. The first run will be the recording phase and your program should behave normally. Subsequent runs
will use the recorded data to simulate the mimicked packages. This is the playback phase.

=over

=item Test::Mimic->import($preferences)

The $preferences hash reference passed to import is fairly simply and the majority of its structure can be
deduced from the synopsis above. Several of the elements themselves, however, require explanation.

'save' => a directory name where recorded data should be written/read from. The directory need
not exist.

'string' => a reference to a subroutine that accepts a single argument and returns it in a stringified form.
It should minimally handle non-reference scalars, array references, hash references and references to
scalars.

'destring' => a reference to a subroutine that is the inverse of the 'string' subroutine. For example,
is_deeply( $x, $preferences->{'destring'}->( $preferences->{'string'}->($x) ) ) from the Test::More module
should pass.

'key' => a reference to a subroutine that accepts a reference to an array of arguments and returns a hash key
based upon them. It is VITALLY IMPORTANT that you run Test::Mimic::Library::get_id on any argument before
examining its state. See the documentation for Test::Mimic::Library for more information.

'monitor_args' => a reference to a subroutine that accepts a reference to an array of arguments and begins
recording the desired ones. You will probably want to  use Test::Mimic::Library::monitor. Returns a
scalar that will later be passed to the subroutine keyed by 'play_args'.

'play_args' => a reference to a subroutine that accepts first a reference to an array of arguments and then
the scalar returned by the subroutine keyed by 'monitor_args'. It should hijack the desired arguments. You
will probably want to apply the soon to be written Test::Mimic::Library::hijack.

'scalars' => a reference to an array of package scalar names that you wish to record.

'key', 'monitor_args', and 'play_args' can be repeated at several levels of the hash. The most specific one
possible will be used in each case. Also, all subroutines, arrays and hashes in a package will be recorded.

=cut

=back

=head2 EXPORT

Nothing is available for export.

=head1 SEE ALSO

Test::MockObject

Other members of the Test::Mimic suite:
Test::Mimic::Recorder
Test::Mimic::Library
Test::Mimic::Generator

The latest source for the Test::Mimic suite is available at:

git://github.com/brendanr/Test--Mimic.git

=head1 AUTHOR

Concept by Tye McQueen.
Made possible by WhitePages Inc.

Development by Brendan Roof, E<lt>brendanroof@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brendan Roof

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
