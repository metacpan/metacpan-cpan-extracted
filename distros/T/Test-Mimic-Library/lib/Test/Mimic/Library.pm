package Test::Mimic::Library;

use 5.006001; # for my $filehandle
use strict;
use warnings;

our $VERSION = 0.012_006;

use Test::Mimic::Library::MonitorScalar;
use Test::Mimic::Library::MonitorArray;
use Test::Mimic::Library::MonitorHash;
use Test::Mimic::Library::PlayScalar;
use Test::Mimic::Library::PlayArray;
use Test::Mimic::Library::PlayHash;
use Test::Mimic::Library::MonitorTiedScalar;
use Test::Mimic::Library::MonitorTiedArray;
use Test::Mimic::Library::MonitorTiedHash;

use Scalar::Util qw<blessed refaddr reftype weaken readonly>;

#use Data::Dump::Streamer if possible, otherwise Data::Dumper and ad hoc replacements.
BEGIN {
    if ( eval { require Data::Dump::Streamer; 1 } ) {
        Data::Dump::Streamer->import( qw<:undump Dump regex> );

        # Accepts a single argument. Returns true iff the argument is a regular expression created by qr.
        *_is_pattern = sub { return scalar regex( $_[0] ); };

        # Accepts a single argument. Returns a string form of this argument that can be inverted
        # (approximately) with _default_destringifier.
        *_default_stringifier = sub {
            return scalar Dump( $_[0] )->Names('TML_destringify_val')->KeyOrder('', 'lexical')->Out();
        }; 
        # The horrible name is my attempt to avoid collisions with variables from closures. Sadly, DDS doesn't
        # allow package scoped names.

        # Accepts a string returned by _default_stringifier. Returns an approximation to the original value.
        *_default_destringifier = sub {
            my $TML_destringify_val;
            eval( $_[0] . "; 1" )
                or die "Unable to eval the string: $_[0]\nwith error: $@";
            return $TML_destringify_val;
        };
    }
    else {
        require Data::Dumper;
        Data::Dumper->import();

        # Accepts a single argument. Returns true if the argument is a regular expression created by qr that
        # is not blessed. If it is blessed returns true iff the argument was blessed into the Regexp class.
        # Returns false in all other cases. In other words, this gives false positives for non qr refs
        # blessed into Regexp and false negatives for qr refs blessed into any other package.
 
        # NOTE: This is a major problem if we need to store qr refs blessed into other packages. We will
        # attempt to dereference the qr object and tie the result. This will cause our code to die. False
        # positives will merely cause incomplete recording and punt the responsibility of preserving the
        # value to the stringifier.
        *_is_pattern = sub {
            my $type = ref( $_[0] );
            if ( defined($type) ) {
                my $class = blessed( $_[0] );
                if ( defined($class) ) {
                    return $class eq 'Regexp';
                }
                else {
                    return $type eq 'Regexp';
                }
            }
            else {
                return ();
            }
        };

        # Accepts a single argument. Returns a string form of this argument that can be inverted
        # (approximately) with _default_destringifier.
        *_default_stringifier = sub { return scalar Dumper( $_[0] ); };

        # Accepts a string returned by _default_stringifier. Returns an approximation to the original value.
        *_default_destringifier = sub {
            my $VAR1;
            eval( $_[0] . "; 1" )
                or die "Unable to eval the string: $_[0]\nwith error: $@";
            return $VAR1;
        };
    }
}

require Exporter;

our @ISA = qw<Exporter>;

our %EXPORT_TAGS = (
    'constants' => [ qw(
        SCALAR_CONTEXT
        LIST_CONTEXT
        VOID_CONTEXT
        STABLE
        VOLATILE
        NESTED
        RETURN
        EXCEPTION
        ARBITRARY
        CODE_E
        SCALAR_E
        ARRAY_E
        HASH_E
        ENCODE_TYPE
        DATA
        DATA_TYPE
        HISTORY
        CLASS
    ) ],
);

our @EXPORT_OK = (
    qw<
        encode
        decode
        monitor
        play
        monitor_args
        monitor_args_by
        play_args
        play_args_by
        gen_arg_key
        gen_arg_key_by
        stringify
        stringify_by
        destringify
        destringify_by
        init_records
        load_records
        write_records
        get_references
        execute
        descend
        load_preferences
    >,
    @{ $EXPORT_TAGS{'constants'} },
);

our @EXPORT = qw(
	
);


use constant {
    # Array indices for the three contexts
    SCALAR_CONTEXT  => 0,
    LIST_CONTEXT    => 1,
    VOID_CONTEXT    => 2,

    # Description of encoded data
    STABLE      => 200,
    VOLATILE    => 201,
    NESTED      => 202,

    # The two types of supported behavior
    RETURN      => 300,
    EXCEPTION   => 301,

    # Convenience values
    ARBITRARY   => 400, # For merely creating hash entries

    # Event types. Should we deprecate this?
    CODE_E      => 500,
    SCALAR_E    => 501,
    ARRAY_E     => 502,
    HASH_E      => 503,

    # Encoded data fields, i.e. indices.
    ENCODE_TYPE => 0,
    DATA        => 1,

    # Reference table item fields, i.e. indices.
    DATA_TYPE   => 0,
    HISTORY     => 1,
    CLASS       => 2,

};

my $references; # A table containing recorded data for volatile references and objects. The index of a
                # given reference is simply the number of references
                # monitor saw before the reference under
                # consideration.
my $address_to_index;   # A hash ref mapping the address of a reference to its index in $references.
my $is_alive;           # A hash ref mapping the address of a reference to its current alive state. This will
                        # be defined if the value stored at $address_to_index is current, undefined
                        # otherwise.
my $index_to_reference; # Almost, but not quite, the inverse of $address_to_index. Rather than mapping to the
                        # address of the reference it maps to the reference itself.

# Preloaded methods go here.

sub init_records {
    $references = [];
    $address_to_index = {};
    $is_alive = {};
    $index_to_reference = {};
}

sub load_records {
    my ($file_name) = @_;

    init_records();
    
    open( my $fh, '<', $file_name ) or die "Could not open file: $!";

    my $recorded_data;
    {
        local $/;
        undef $/;
        $recorded_data = <$fh>;
    }
    $references = destringify($recorded_data);

    close($fh) or die "Could not close file: $!";
}

sub get_references {
    return $references;
}

sub write_records {
    my ($file_name) = @_;

    open( my $fh, '>', $file_name ) or die "Could not open file: $!";
    print $fh stringify($references);
    close($fh) or die "Could not close file: $!";
}

sub load_preferences {
    my ($preferences) = @_;

    if ( defined( $preferences->{'string'} ) ) {
        stringify_by( $preferences->{'string' } );
    }
    if ( defined( $preferences->{'destring'} ) ) {
        destringify_by( $preferences->{'destring'} );
    }
    gen_arg_key_by($preferences);
    monitor_args_by($preferences);
    play_args_by($preferences);
}

# Changes the current working directory to $dir. If $dir does not exist then it will be created.
# If it exists, but it is not a directory or any other error occurs descend will die.
sub descend {
    my ($dir) = @_;

    # Move to the $dir directory, creating if needed.
    if  ( -e $dir ) {
        if ( ! ( -d $dir ) ) {
            die "$dir exists, but it is not a directory.";
        }
    }
    else {
        mkdir( $dir ) or die "Could not create directory: $!";
    }
    chdir($dir) or die "Could not change the current working directory: $!";
}

sub execute {
    my ( $package, $subroutine, $behavior, $args ) = @_;

    # Find proper behavior for these arguments.
    my $key = gen_arg_key( $package, $subroutine, $args );

    if ( ! exists( $behavior->{$key} ) ) {
        die "No call recorded with corresponding arguments. Package: $package, Subroutine: $subroutine, Key: $key";
    }
    my $context_to_result = $behavior->{$key};

    # Find proper behavior for this context.
    my $index;
    if (wantarray) {
        $index = LIST_CONTEXT;
    }
    elsif ( defined wantarray ) {
        $index = SCALAR_CONTEXT;
    }
    else {
        $index = VOID_CONTEXT;
    }
    my $results = $context_to_result->[$index];
    if ( ! defined( $results ) ) {
        die "No call recorded in context $index. Package: $package, Subroutine: $subroutine, Key: $key";
    }

    # Obtain the results for this call.
    if ( @{$results} == 0 ) {
        die "Call history exhausted. Package: $package, Subroutine: $subroutine, Key: $key";
    }

    my ( $arg_signature, $stored_result ) = splice( @{$results}, 0, 2 );

    # Tie arguments making them behave as they were recorded behaving.
    play_args( $package, $subroutine, $args, $arg_signature );
    
    # Perform appropriately
    my ( $result_type, $result ) = @{$stored_result};
    if ( $result_type == EXCEPTION ) {
        die decode( $result );
    }
    elsif ( $result_type == RETURN ) {
        if (wantarray) {
            return @{ decode($result) };
        }
        elsif ( defined wantarray ) {
            return decode($result);
        }
        else {
            return;
        }
    }
    else {
        die "Bad result type <$result_type>. Package: $package, Subroutine: $subroutine, Key: $key";
    }
}

{
    my $key_gens = {};

    # The best way to think of the key generator is as a hint to the mimic system. A constant map to
    # 'the key' would work provided that all calls to a given subroutine occur in order. If a smarter
    # map is used then the mimic system will be more flexible. Call order only must be preserved in each set
    # of calls generated by the inverse map of each distinct key. Of course, if one call produces data that
    # another requires it doesn't really make sense to change the order (in either the playback _or_ record
    # stages).
    # 
    # NOTE: The passed subroutine should probably not use the stored reference information. This is because
    # out of order calls could then break. Consider subroutines foo and bar. Both take a hash
    # reference. Suppose that in the recording stage foo is called first, bar second and that the same
    # reference is passed both times. If the reference is created by the user, i.e. not returned from a
    # mimicked subroutine or otherwise seen by the recorder, then foo will end up naming the reference.
    # foo's key generator will not be able to include the reference name and will perhaps instead perform
    # a straightforward stringification of the hash. bar's key generator on the other hand will be able to
    # use the fact that we are monitoring the reference and may instead create a key like '[ VOLATILE, 47 ]'.
    # Now suppose that in the playback stage the call order is reversed. The hash reference isn't named until
    # the call to foo, so there is no way bar can recognize it.
    #
    # NOTE: Or maybe SCRATCH ALL OF THAT. The above problem sucks, but the alternative is worse. Suppose we
    # do a _light_encode and then a stringification. If we played the object into existence then it is tied.
    # If it is tied and we examine it we will consume it's output. Even we added logic to halt the
    # consumption we don't have access to the most recent state of the object. Similarly, in the record phase
    # we don't know what the next access will be when gen_arg_key is called, so we can't approximate state
    # by considering the history information. We could allow gen_arg_key to cause history to build up like
    # it was a user call, but then we are enforcing call order on the set of subroutines that share
    # arguments. This is definitely a lesser of, err... 4 or 5, evils situation.
    #
    # NOTE: Additionally, you should avoid any calls to monitor, monitor_args or encode. These have the side
    # effect of naming passed values which will break the built in monitor_args/play_args paradigm.
    sub gen_arg_key_by {
        $key_gens = $_[0];
    }

    sub gen_arg_key {
        my ( $package, $subroutine, $args ) = @_;
        local $Test::Mimic::Recorder::SuspendRecording = 1;
        
        my $key_gen;
        if (   defined( $key_gen = $key_gens->{'packages'}->{$package}->{'subs'}->{$subroutine}->{'key'} )
            || defined( $key_gen = $key_gens->{'packages'}->{$package}->{'key'} )
            || defined( $key_gen = $key_gens->{'key'} ) ) {

            return &{$key_gen}($args);
        }
        else {
            return stringify( _light_encode( $args, 2 ) );
        }
    }
}

{
    # Each of these helper subroutines takes ( $val, $at_level, $type ).
    my $scalar_action = sub { return [ 'SCALAR', _light_encode( ${ $_[0] }, $_[1] ) ]; };
    my $simple_action = sub { return [ $_[2] ]; };
    my %type_to_action = (
        'REG_EXP'   => $simple_action,
        'SCALAR'    => $scalar_action,
        'REF'       => $scalar_action,
        'LVALUE'    => $scalar_action,
        'VSTRING'   => $scalar_action,
        'ARRAY'     => sub {
            my @temp = map( { _light_encode( $_, $_[1] ) } @{ $_[0] } );
            return [ 'ARRAY', \@temp ];
        },
        'HASH'      => sub {
            my %temp;
            @temp{ keys %{ $_[0] } } = map( { _light_encode( $_[0]->{$_}, $_[1] ) } keys %{ $_[0] } );
            return [ 'HASH', \%temp];
        },
        'GLOB'      => $simple_action,
        'IO'        => $simple_action,
        'FORMAT'    => $simple_action,
        'CODE'      => $simple_action,
    );

    # RESULTS NOT SUITABLE FOR DECODE!
    sub _light_encode {
        my ( $val, $at_level ) = @_;

        my $type = reftype($val);
        if ( ! $type ) { # If the value is not a reference...
            return [ STABLE, $val ];
        }
        elsif ( exists( $type_to_action{$type} ) ) {
            my $address = refaddr($val);
            if ( defined( $is_alive->{$address} ) ) {
                return [ VOLATILE, $address_to_index->{$address} ];
            }

            if ( _is_pattern($val) ) { # reftype doesn't recognize patterns, so set $type manually.
                $type = 'REG_EXP';
            }
            
            if ( $at_level == 0 ) { # If we have reached the deepest requested layer...
                return [ NESTED, [ $type ] ];
            }
            else {
                $at_level--;
            }
            
            my $coded = &{ $type_to_action{$type} }( $val, $at_level, $type );
            return [ NESTED, $coded ];
        }
        else {
            die "Unknown reference type <$type> from <$val>. Unable to encode.";
        }
    }
}

# So you want to build your own key generator? That's great. One rule: Never ever ever view the state of the
# arguments you are mapping into keys. That won't be a problem will it? Didn't think so. Those of you
# nonconformists that think state is important can use get_id. For each component of a passed value, i.e.
# a single alias in the list, an array element of a dereferenced alias, an element of the array element
# dereferenced as a hash etc., that you wish to examine _at all_ you must first call get_id on the component.
# If it returns undef you can look at it, but if it is an aggregate you need to use get_id on it's components
# as well. If undef is not returned, then you will be given an index corresponding to the reference. It is
# guaranteed to be unique over the execution of the program and stable between the record and playback
# phases. This is due to the fact that what you think are real variables in the playback phase are really
# tied variables. They don't have any state and if you try to look at them you will just consume their fake
# state. This will cause everything to crash and burn. In conclusion, use get_id. In the future we may store
# state in the tied variables and allow you to look at them. Keep your fingers crossed.
sub get_id {
        my ($val) = @_;

        my $address = refaddr($val);
        if ( defined( $is_alive->{$address} ) ) {
            return $address_to_index->{$address};
        }
        else {
            return undef;
        }
}

{
    my $stringifier = \&_default_stringifier;

    sub stringify_by {
        $stringifier = $_[0];
    }

    # Given an encoded element returns a string version. Should be suitable for use as a key in a hash as well as
    # being invertible with destringify.
    sub stringify {
        return &{$stringifier};
    }
}

{
    my $destringifier = \&_default_destringifier;

    sub destringify_by {
        $destringifier = $_[0];
    }

    sub destringify {
        return &{$destringifier};
    }
}

{
    my $monitors = {};
    
    sub monitor_args_by {
        $monitors = $_[0];
    }

    # aliases act like references, but look like simple scalars. Because of this we have to be particularly
    # cautious where they could appear. Barring XS code and the sub{\@_} construction we only need to worry
    # about subroutine arguments, i.e. $_[i].
    #
    # Accepts a reference to an array of aliases,
    # e.g. @_ from another subroutine. It will monitor each alias that is not read-only and return a tuple
    # consisting of the total number of aliases from the array reference as well as a hash reference that takes
    # an index of a mutable element in the array to the result of monitor being called on a reference to said
    # element.
    sub monitor_args {
        my ( $package, $subroutine, $aliases ) = @_;

        my $arg_monitor;
        if (   defined( $arg_monitor = $monitors->{'packages'}->{$package}->{'subs'}->{$subroutine}->{'monitor_args'} )
            || defined( $arg_monitor = $monitors->{'packages'}->{$package}->{'monitor_args'} )
            || defined( $arg_monitor = $monitors->{'monitor_args'} ) ) {

            return &{$arg_monitor}($aliases);
        }
        else {
            my $num_aliases = @{$aliases};
            my %mutable;
            for ( my $i = 0; $i < $num_aliases; $i++ ) {
                if ( ! readonly( $aliases->[$i] ) ) {
                    $mutable{$i} = monitor( \$aliases->[$i] );
                }
            }
            return [ $num_aliases, \%mutable ];
        }
    }
}

{
    my $players = {};

    sub play_args_by {
        $players = $_[0];
    }

    # Accepts an array of aliases and the tuple returned by monitor_args.
    # Attempts to match the aliases in the array reference with those in the tuple. If everything matches the
    # mutable passed aliases will be tied to behave as those monitored earlier, otherwise dies. The array and
    # the tuple representing the original array are said to match if the total number of elements are the same
    # and the mutable elements are the same, i.e. appear at the same indices.
    sub play_args {
        my ( $package, $subroutine, $aliases, $coded_aliases ) = @_;

        my $arg_player;
        if (   defined( $arg_player = $players->{'packages'}->{$package}->{'subs'}->{$subroutine}->{'play_args'} )
            || defined( $arg_player = $players->{'packages'}->{$package}->{'play_args'} )
            || defined( $arg_player = $players->{'play_args'} ) ) {

            &{$arg_player}( $aliases, $coded_aliases );
        }
        else {
            my ( $orig_num_aliases, $mutable ) = @{$coded_aliases};

            # Apply a primitive signature check, list length.
            my $cur_num_aliases = @{$aliases};
            if ( $orig_num_aliases != $cur_num_aliases ) {
                die "Signatures do not match. Unable to play_args from <$coded_aliases> onto <$aliases>.";
            }

            # Consider each alias, tie the mutable aliases if everything matches, else die.
            for ( my $i = 0; $i < $cur_num_aliases; $i++ ) { 
                my $cur_read_only = readonly( $aliases->[$i] );
                my $orig_read_only = ! exists( $mutable->{$i} );

                if ( $cur_read_only && $orig_read_only ) {  # If they are both read-only they match.
                    next;                                   # We shouldn't try to tie a read-only variable. :)
                }
                elsif ( ! $cur_read_only && ! $orig_read_only ) { # If they are both mutable...
                    my $index = $mutable->{$i}->[DATA]; # See monitor.

                    if ( defined( $index_to_reference->{$index} ) ) { # If we have already seen this value.
                        next;
                    }

                    #TODO: Assuming we maintain address_to_index and is_alive during playback too we can
                    #      check to see if $address_to_index{ refaddr( $index_to_reference{$index} ) } == $index.
                    #      If it doesn't we know that there is a problem. <---- that like something Or.

                    my ( $type, $history, $old_class ) = @{ $references->[$index] };
                    tie( $aliases->[$i], 'Test::Mimic::Library::PlayScalar', $history );
                    $index_to_reference->{$index} = \( $aliases->[$i] );
                    weaken( $index_to_reference->{$index} ); # Don't prevent the val from being gced.

                    #NOTE: We need not bless the alias here. Either we produced it earlier, blessed it then and hit
                    #      next above or the alias was produced externally and if blessed at all was blessed
                    #      elsewhere.

                    my $address = refaddr( \( $aliases->[$i] ) ); 
                    $address_to_index->{$address} = $index;
                    $is_alive->{$address} = \( $aliases->[$i] );
                    weaken( $is_alive->{$address} );

                }
                else {
                    die "Mutable/immutable mismatch. Unable to play_args from <$coded_aliases> onto "
                        . "<$aliases>.";
                }
            }
        }
    }
}

sub _get_type {
    my ($val) = @_;

    if ( _is_pattern($val) ) {
        return 'REG_EXP';
    }
    else {
        my $type = reftype($val);
        if ( $type eq 'REF' || $type eq 'LVALUE' || $type eq 'VSTRING' ) {
            return 'SCALAR';
        }
        else {
            return $type;
        }
    }
}

{
    # Each of these helper subroutines takes ( $val, $type ).
    my $scalar_action = sub {
        my $history = [];
        if ( defined( my $old_tie = tied( ${ $_[0] } ) ) ) {
            tie( ${ $_[0] }, 'Test::Mimic::Library::MonitorTiedScalar', $history, $old_tie );
        }
        else {
            tie( ${ $_[0] }, 'Test::Mimic::Library::MonitorScalar', $history, $_[0] );
        }
        return [ 'SCALAR', $history ];
    };
    my $simple_action = sub { return [ $_[1], $_[0] ]; };
    my %type_to_action = (
        'REG_EXP'   => $simple_action,
        'SCALAR'    => $scalar_action,
        'REF'       => $scalar_action,
        'LVALUE'    => $scalar_action,
        'VSTRING'   => $scalar_action,
        'ARRAY'     => sub {
            my $history = [];
            if ( defined( my $old_tie = tied( @{ $_[0] } ) ) ) {
                tie( @{ $_[0] }, 'Test::Mimic::Library::MonitorTiedArray', $history, $old_tie );
            }
            else {
                tie ( @{ $_[0] }, 'Test::Mimic::Library::MonitorArray', $history, $_[0] );
            }
            return [ 'ARRAY', $history ];
        },
        'HASH'      => sub {
            my $history = [];
            if ( defined( my $old_tie = tied( %{ $_[0] } ) ) ) {
                tie( %{ $_[0] }, 'Test::Mimic::Library::MonitorTiedHash', $history, $old_tie );
            }
            else {
                tie ( %{ $_[0] }, 'Test::Mimic::Library::MonitorHash', $history, $_[0] );
            }
            return [ 'HASH', $history ];
        },
        'GLOB'      => $simple_action,
        'IO'        => $simple_action,
        'FORMAT'    => $simple_action,
        'CODE'      => $simple_action,
    );

    # Monitor, i.e. tie the value and record its state, if possible (recursively as needed), otherwise merely
    # encapsulate the value as well as possible. In the second case proper storage and retrivial of the data
    # becomes the responsibility of Test::Mimic::Recorder::stringify.
    #
    # Objects are handled, but to a limited extent. The main restriction is that a reference (or rather the
    # 'object' behind the reference) can not change from being blessed to being unblessed anywhere that monitor
    # will notice. Purely internal modifications, i.e. those occurring in a wrapped subroutine, are okay.
    # Additionally, modifications occurring prior to the reference being monitored are okay. Also, it should be
    # noted that references blessed into a package that is not being recorded will have their state recorded
    # properly (including object info), but that object method calls on that reference will still not be
    # recorded.
    sub monitor {
        my ( $val ) = @_;

        my $type = reftype($val);
        if ( ! $type ) { # If this is not a reference...
            return [ STABLE, $val ];
        }
        else {
            my $address = refaddr($val);
            my $index;

            if ( defined( $is_alive->{$address} ) ) {      # If we are watching this reference...

                # NOTE: We are using defined as opposed to exists because a given address can be used by multiple
                # references over the entire execution of the program. See the comment on weaken below.

                $index = $address_to_index->{$address};
            }
            else {
                # Note that we are watching the reference.
                $is_alive->{$address} = $val;
                weaken( $is_alive->{$address} );   # This reference will be automatically set to undef when $$val is
                                                # garbage collected.

                if ( _is_pattern($val) ) { # reftype doesn't recognize patterns, so set $type manually. 
                    $type = 'REG_EXP';
                }

                # Create a representation of the reference depending on its type.
                # Monitors recursively as necessary.
                my $reference;
                if ( exists( $type_to_action{$type} ) ) {
                    $reference = &{ $type_to_action{$type} }( $val, $type );
                }
                else {
                    die "Unknown reference type <$type> from <$val>. Unable to monitor.";
                }
                $reference->[2] = blessed($val); # Mark this as either an object or a plain reference.

                # Store the representation of the reference into the references table.
                push( @{$references}, $reference );
                $index = $address_to_index->{$address} = $#{$references};
            }
            return [ VOLATILE, $index ];
        }
    }
}

{
    # Each of these helper subroutines takes ( $val, $at_level, $type ).
    my $scalar_action = sub { return [ 'SCALAR', encode( ${ $_[0] }, $_[1] ) ]; };
    my $simple_action = sub { return [ $_[2], $_[0] ]; };
    my %type_to_action = (
        'REG_EXP'   => $simple_action,
        'SCALAR'    => $scalar_action,
        'REF'       => $scalar_action,
        'LVALUE'    => $scalar_action,
        'VSTRING'   => $scalar_action,
        'ARRAY'     => sub {
            my @temp = map( { encode( $_, $_[1] ) } @{ $_[0] } );
            return [ 'ARRAY', \@temp ];
        },
        'HASH'      => sub {
            my %temp;
            @temp{ keys %{ $_[0] } } = map( { encode( $_[0]->{$_}, $_[1] ) } keys %{ $_[0] } );
            return [ 'HASH', \%temp];
        },
        'GLOB'      => $simple_action,
        'IO'        => $simple_action,
        'FORMAT'    => $simple_action,
        'CODE'      => $simple_action,
    );

    # Performs an expansion wrap on the passed value until the given level then watches every component below.
    # Returns a structure analogous to the original except that each component is recursively wrapped. This should
    # only be used on static data. If circular references exist above the watch level or into the wrap level the
    # behavior is undefined.
    #
    # For example if _watch was passed an array it would perhaps return [ VOLATILE, 453 ].
    # _wrap_then_watch would return [ NESTED, [ ARRAY, [ [ STABLE, 'foo' ], [ STABLE, 'bar' ] ] ] ]
    #
    # This is useful when the data currently in the array is important, but the array itself has no special
    # significance.
    #   
    # Currently scalars et al., arrays, hashes, qr objects, code references are handled well.
    # Filehandles are not being tied, ideally they would be, but the filehandle tying mechanism is
    # not complete.
    # Formats are in a similar position, but they probably shouldn't ever be redefined. (Check this.)
    # Because of this that may not really be a problem.
    # The entries in globs can not be tied. A special glob tie could potentially remedy this, but
    # this does not currently exist.
    #
    # TODO: Handle circular references, also save space on DAGs.
    # Idea: Scan through structure. Record all references in a big hash. If we see duplicates note them.
    # The duplicates will exist as a special structure.
    #
    # [ CIRCULAR_NESTED, <dup_table>, [ ARRAY, blah...
    # We have one additional type:
    # [ DUP, <index> ]
    sub encode {
        my ( $val, $at_level ) = @_;

        if ( $at_level == 0 ) { # If we have reached the volatile layer...
            return monitor( $val );
        }
        else {
            $at_level--;
        }

        my $type = reftype($val);
        if ( ! $type ) { # If the value is not a reference...
            return [ STABLE, $val ];
        }
        elsif ( exists( $type_to_action{$type} ) ) {
            if ( _is_pattern($val) ) { # reftype doesn't recognize patterns, so set $type manually.
                $type = 'REG_EXP';
            }
            my $coded = &{ $type_to_action{$type} }( $val, $at_level, $type );
            return [ NESTED, $coded ];
        }
        else {
            die "Unknown reference type <$type> from <$val>. Unable to encode.";
        }
    }
}

{
    # Each of these helper subroutines takes ( $val ).
    my $simple_action = sub { return $_[0]; };
    my %type_to_action = (
        'REG_EXP'   => $simple_action,
        'SCALAR'    => sub {
            my $temp = decode( $_[0] );
            return \$temp;
        },
        'ARRAY'     => sub {
            my @temp = map( { decode( $_ ) } @{ $_[0] } );
            return \@temp;
        },
        'HASH'      => sub {
            my %temp;
            @temp{ keys %{ $_[0] } } = map( { decode( $_[0]->[$_] ) } keys %{ $_[0] } );
            return \%temp;
        },
        'GLOB'      => $simple_action,
        'IO'        => $simple_action,
        'FORMAT'    => $simple_action,
        'CODE'      => $simple_action,
    );

    sub decode {
        my ( $coded_val ) = @_;
        my ( $code_type, $data ) = @{$coded_val};

        if ( $code_type == STABLE ) {
            return $data;
        }
        elsif ( $code_type == NESTED ) {
            my ( $ref_type, $val ) = @{$data};
        
            if ( exists( $type_to_action{$ref_type} ) ) {
                return &{ $type_to_action{$ref_type} }( $val );
            }
            else {
                die "Invalid reference type <$ref_type> from <$data> with value <$val>. Unable to decode.";
            }
        }
        elsif ( $code_type == VOLATILE ) {
            return play( $coded_val ); 
        }
        else {
            die "Invalid code type <$code_type> from <$coded_val> with data <$data>. Unable to decode.";
        }
    }
}

{
    # Each of these helper subroutines takes ( $history ).
    # This will be a single reference, i.e. not a true history, for types we do not tie.
    my $simple_action = sub { return $_[0]; };
    my %type_to_action = (
        'REG_EXP'   => $simple_action,
        'SCALAR'    => sub {
            my $temp;
            tie( $temp, 'Test::Mimic::Library::PlayScalar', $_[0] );
            return \$temp;
        },
        'ARRAY'     => sub {
            my @temp;
            tie( @temp, 'Test::Mimic::Library::PlayArray', $_[0] );
            return \@temp;
        },
        'HASH'      => sub {
            my %temp;
            tie( %temp, 'Test::Mimic::Library::PlayHash', $_[0] );
            return \%temp;
        },
        'GLOB'      => $simple_action,
        'IO'        => $simple_action,
        'FORMAT'    => $simple_action,
        'CODE'      => $simple_action,
    );

    sub play {
        my ( $coded_val ) = @_;
 
        my ( $type, $data ) = @{$coded_val};
        if ( $type == STABLE ) {
            return $data;
        }
        elsif ( $type == VOLATILE ) {
            if ( defined( $index_to_reference->{$data} ) ) {    # We are using defined because the weak
                                                                # references used in the hash will be set to
                                                                # undef upon the destruction of the
                                                                # corresponding values.
                return $index_to_reference->{$data};
            }
            else {
                my ( $type, $history, $class_name ) = @{ $references->[$data] };
                
                my $reference;
                if ( exists( $type_to_action{$type} ) ) {
                    $reference = &{ $type_to_action{$type} }( $history );
                }
                else {
                    die "Unknown reference type <$type> at index <$data>. Unable to play.";
                }

                # If this reference is supposed to point at an object, bless it.
                # This will take place even if we didn't record the class. This may be a feature or a bug.
                if ( defined($class_name) ) {
                    bless( $reference, $class_name );
                }

                # Note the creation of this reference, so we don't recreate it and are aware of what recorded
                # reference it corresponds to.
                my $address = refaddr($reference); 
                $address_to_index->{$address} = $data;
                $is_alive->{$address} = $reference;
                weaken( $is_alive->{$address} );
                $index_to_reference->{$data} = $reference;
                weaken( $index_to_reference->{$data} ); # But don't prevent it from being gced. If we
                                                        # need to we can recreate it easily. ( Although the
                                                        # address may well be different. )

                return $reference;            
            }
        }
        else {
            die "Unrecognized type <$type>. Unable to play.";
        }
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Mimic::Library - Perl library supporting the Test::Mimic suite. 

=head1 SYNOPSIS

  use Test::Mimic::Library qw< encode >;

  my $coded_val = encode( 'a string', 0 );

=head1 DESCRIPTION

Test::Mimic::Library provides a number of tools required in common by Test::Mimic, Test::Mimic::Recorder,
and Test::Mimic::Generator. It also stores internally certain portions of the recording.

=over

=item init_records()

Prepares the library for a new recording.

=cut

=item load_records($file_name)

Loads the portion of the recording specific to the library. Prepares for playback. Dies on any
IO errors.

=cut

=item get_references()

Returns the reference table. This subroutine is for use by generated code files and should
be considered private to the Test::Mimic suite.

=cut

=item write_records($file_name)

Write the portion of the recording specific to the library. Dies on any IO errors.

=cut

=item descend($dir_name)

Changes the current directory to $dir_name creating it if necessary. Dies on IO errors.

=cut

=item execute( $package, $subroutine_name, $behavior_hash, $args )

Emulates "$package::$subroutine_name" based on the information stored in $behavior_hash given
$args. This subroutine should be considered private to the Test::Mimic suite.

=cut

=item gen_arg_key_by($preferences)

Accepts a hash reference describing which key generator to use given package and subroutine names.
It should have the following structure:

{
    'key' => \&generic_sub,
    'packages' => {
        'Foo::Bar' => {
            'key' => \%more_specific,
            'subs' => {
                'foo' => {
                    'key' => \&most_specific,
                }
            }
        }
    }
}

Each of the subroutines should accept an array reference to the arguments and return a key suitable for use
in a hash. Furthermore, they must be the same from run to run and MUST use get_id if they access the state
of any particular argument.

=cut

=item gen_arg_key( $package, $subroutine, $args )

Accepts the name of the package, the name of the subroutine currently being emulated (typically with
execute) and an array reference to the arguments. Returns a hash key based on those arguments using
the requested key generator, or, if none was specified, the default key generator. The generator will be
selected from most to least specific. The default is to encode the arguments by expanding references into
values for 2 levels and then merely note the type. The ids returned by get_id are used instead if an
argument is being micked. stringify is used to convert the above structure into a key.

=cut

=item get_id($value)

When constructing a key in your generator you can't wildly examine any old argument. This is because
the arguments are actually tied values and you will probably consume their state. Call get_id first.
If undef is returned you can proceed, but if you have an aggregate you must use get_id recursively.
Otherwise you will be given a unique integer id. Incorporate this into your key instead and do not
examine the state.

=cut

=item stringify_by($coderef)

Accepts a reference to a subroutine that takes a single argument and returns a stringified
version of it. This subroutine will then be used for all stringification in the Test::Mimic suite. It is
important that identical structures stringify to the same value from one run to another. Specifically, the
order of hash keys must remain the same or the default key generator will break. If you really need to you
could ignore this, but you would need a different key generator.

=cut

=item stringify($value)

Returns a stringified version of $value. The behavior of stringify can be set with stringify_by. If this
was not done then a default stringifier will be used.

=cut

=item destringify_by($coderef)

Accepts a reference to a subroutine that is the inverse of the subroutine that stringify_by was given.
All destringification done in the Test::Mimic suite will then use this subroutine.

=cut

=item destringify($stringified_value)

The inverse of stringify.

=cut

=item monitor_args_by($preferences)

Accepts a hash reference describing which argument monitor to use given package and subroutine names.
It should have the following structure:

{
    'monitor_args' => \&generic_sub,
    'packages' => {
        'Foo::Bar' => {
            'monitor_args' => \%more_specific,
            'subs' => {
                'foo' => {
                    'monitor_args' => \&most_specific,
                }
            }
        }
    } 
}       
            
Each of the subroutines should accept an array reference to the arguments and return a scalar representing
the history of the monitored arguments. Only those arguments the user considers important need be monitored.

=cut

=item monitor_args( $package, $subroutine, $arguments )

Accepts the package and name of the subroutine being called along with an array reference to its arguments.
Monitors the arguments with the argument monitor requested with a call to monitor_args_by, or, if none was
requested, the default. This is simply to monitor each argument that is not read only. Returns a scalar
that should passed to play_args during the playback phase.

=cut

=item play_args_by($preferences)

Accepts a hash reference describing which argument player to use given package and subroutine names.
It should have the following structure:

{
    'play_args' => \&generic_sub,
    'packages' => {
        'Foo::Bar' => {
            'play_args' => \%more_specific,
            'subs' => {
                'foo' => {
                    'play_args' => \&most_specific,
                }
            }
        }
    }   
}       
            
Each of the subroutines should accept an array reference to the arguments and the scalar returned by
monitor_args. They should hijack the arguments as necessary and need not return anything.

=cut

=item play_args( $package, $subroutine, $arguments, $coded_arguments )

Accepts the package and name of the subroutine being called, an array reference to its arguments and
the scalar returned by monitor_args. The arguments will be hijacked as specified with play_args_by, or,
if no behavior was specified, the default -- which corresponds to the default monitor_args behavior.

=cut

=item monitor($value)

Accepts an arbitrary scalar, ensures that its value over time will be recorded (if it is a reference), and
returns a scalar representing it. This return value will be suitable for stringification.

=cut

=item encode( $value, $volatility_depth )

Accepts an arbitrary scalar and the depth at which the dereferenced value may be subject to change (assuming
that it is a reference). 0 is for the passed reference itself, 1, for example, may be the elements of an
array reference, but not the array itself. Circular structures are not allowed unless they are contained
entirely below the volatility depth. The history of the values above the volatility depth is not recorded.
Returns a scalar representing the value. This will be suitable for stringification.

=cut

=item decode($coded_value)

Given the coded value returned by encode or monitor returns an approximation to the original. This method is
somewhat smart -- the same coded value passed to decoded will return the exact same reference, i.e.
refaddr( decode($coded_value) ) == refaddr( decode($coded_value) ). If history was recorded, as opposed to
purely state, this information will be used when the user accesses the variable.

=cut

=item play($coded_value)

Given the coded value returned by decode returns an approximation to the original. Note that decode can
handle anything returned by either monitor or encode, but play can handle only monitor returns, so it
almost always makes sense to use decode.

=cut

=back

=head2 EXPORT

None by default. The following are exported by request:

    SCALAR_CONTEXT
    LIST_CONTEXT
    VOID_CONTEXT
    STABLE
    VOLATILE
    NESTED
    RETURN
    EXCEPTION
    ARBITRARY
    CODE_E
    SCALAR_E
    ARRAY_E
    HASH_E
    ENCODE_TYPE
    DATA
    DATA_TYPE
    HISTORY
    CLASS

    encode
    decode
    monitor
    play
    monitor_args
    monitor_args_by
    play_args
    play_args_by
    gen_arg_key
    gen_arg_key_by
    stringify
    stringify_by
    destringify
    destringify_by
    init_records
    load_records
    write_records
    get_references
    execute
    descend
    load_preferences

=head1 SEE ALSO

Other members of the Test::Mimic suite:
Test::Mimic
Test::Mimic::Recorder
Test::Mimic::Generator

The latest source for the Test::Mimic suite is available at:

git://github.com/brendanr/Test--Mimic.git

=head1 AUTHOR

Concept by Tye McQueen.

Development by Brendan Roof, E<lt>brendanroof@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Made possible by WhitePages Inc.

Copyright (C) 2009 by Brendan Roof

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
