package Test::Mimic::Recorder;

use 5.006001;   # For open( my $fh, ...
use strict;
use warnings;

use Devel::EvalError ();
use Cwd qw<abs_path>;
use Scalar::Util qw<reftype>;

use Test::Mimic::Library qw(
    encode
    descend
    stringify
    gen_arg_key
    monitor_args
    init_records
    load_preferences
    write_records
    RETURN
    EXCEPTION
    CODE_E
    SCALAR_CONTEXT
    VOID_CONTEXT
    LIST_CONTEXT
    ARBITRARY
);

our $VERSION = 0.012_005;
our $SuspendRecording = 0; # Turn off recording.
my  $done_writing = 0;

# Data to be stored.
my %typeglobs;  # Contains recorded data for scalars, arrays, hashes and subroutines in a structure analogous
                # to the symbol table. The key is the package name.
my %extra;      # Currently contains only a flattened class hierarchy for each recorded class at
                # $extra{$class}{'ISA'} as a hash ref. $extra{$recorded_class}{'ISA'}{$other_class} will
                # exist iff $recorded_class isa $other_class.
my @operation_sequence; # An ordered list of recorded operations. The first operation happened first, the
                        # second operation happened second and so forth. This currently only includes
                        # subroutine calls in recorded packages. Orderings of various 'scopes' can later be
                        # extracted from this.

# Transient data
my $save_to;

sub import {
    my ( $class, $preferences ) = @_;

    $save_to =  $preferences->{'save'} || '.test_mimic_recorder_data';

    # If we are not being run from Test::Mimic...
    if ( ! defined( $preferences->{'test_mimic'} ) ) { # Perhaps use caller instead?
        init_records();
        load_preferences($preferences);
    }

    # Call _record_package on each package passing along the package and a list of scalars to record.
    for my $package ( keys %{ $preferences->{'packages'} } ) {
        _record_package( $package, $preferences->{'packages'}->{$package}->{'scalars'} ||= [] );
    }
}

# Writes recording to disk. Typically called automatically.
sub finish {
    $done_writing = 1; # Prevents the END block from overwriting what we just wrote.

    # Move the current directory to the specified directory, creating if needed.
    my $top_level = abs_path();
    descend($save_to);

    open( my $fh, '>', 'additional_info.rec' ) or die "Unable to open file: $!";
    print $fh stringify( [ \%typeglobs, \%extra, \@operation_sequence ] )
        or die "Unable to write: $!";
    close($fh) or die "Unable to close file: $!";
    write_records( 'history_from_recorder.rec' );

    # Undo the change to the current working directory above.
    chdir($top_level) or die "Unable to change the current working directory: $!";
}

# Accepts a package name and a list of scalars in the package to be recorded. Test::Mimic::Recorder will
# begin monitoring this package including the passed scalars.
sub _record_package {
    my ( $package, $user_selected_scalars ) = @_; 
    
    eval("require $package; 1")
        or die "Failed to load package $package. $@";
    
    # Consider every symbol in the package, tie arrays and tie hashes.
    my $symbol_table;
    {
        no strict 'refs';
        $symbol_table = \%{ $package . '::' };
    }

    my $fake_package = ( $typeglobs{$package} ||= {} );
    for my $symbol ( keys %{$symbol_table} ) {

        my $typeglob = \$symbol_table->{$symbol};   # According to Tye it is better to handle glob refs than
                                                    # globs themselves.
        my $fake_typeglob = ( $fake_package->{$symbol} ||= {} );

        my $symbol_type = reftype( ${$typeglob} );
        if ( ! defined($symbol_type) ) {
            my $pointer_type = reftype($typeglob);
            if ( $pointer_type eq 'GLOB' ) {
                # Tie arrays and hashes.
                my $reference = *{$typeglob}{'ARRAY'};
                if ( defined($reference) ) {
                    $fake_typeglob->{'ARRAY'} = encode( $reference, 0 );
                }

                $reference = *{$typeglob}{'HASH'};
                if ( defined($reference) && ! ($symbol =~ m/^\w+::$/) ) { #Avoid tying symbol tables!
                    $fake_typeglob->{'HASH'} = encode( $reference, 0 );
                }
            }
            # Perl apparently sometimes stores subroutine stub declarations as simple
            # scalars. We would like to leave these alone. (See the Perl 5.10
            # delta for one reference.)
            elsif ( $pointer_type ne 'SCALAR' ) {
                warn "The symbol <$symbol> in package <$package> with type <$pointer_type> is neither a glob,"
                    . ' constant optimization or subroutine stub declaration. Ignoring and proceeding.';
            }
        }
        # Perl 5.10 optimizes constants by storing them as plain references, not globs initially, so
        # we handle that here by watching the 'constant' value. This is needed because although the
        # value itself is constant, the contents of the value may not be. If it is an array reference,
        # for example, we can modify the backing array.
        elsif ( $symbol_type eq 'REF' || $symbol_type eq 'SCALAR' ) {
            # If we are dealing with a simple scalar then it won't be tied anyways. Otherwise, an $at_level
            # of 1 will start the monitoring/tying on the elements of the aggregate/dereferenced value rather
            # than the aggregate/reference itself.
            $fake_typeglob->{'CONSTANT'} = encode( ${${$typeglob}}, 1 ); 
        }
        else {
            warn "The symbol <$symbol> in package <$package> with reftype <$symbol_type> is neither a glob,"
                . ' constant optimization or subroutine stub declaration. Ignoring and proceeding.';
        }
    }
    
    # Combine the user selected scalars with the the exported scalars.
    my %all_scalars;
    if ( $package->isa('Exporter') ) {
        no strict 'refs';
        for my $symbol ( @{ $package . '::EXPORT' }, @{ $package . '::EXPORT_OK' } ) {
            if ( substr( $symbol, 0, 1 ) eq '$' ) {
                $all_scalars{ substr( $symbol, 1 ) } = ARBITRARY;
            }
        }
    }
    for my $scalar ( @{$user_selected_scalars} ) {
        $all_scalars{$scalar} = ARBITRARY;
    }
    
    # Tie all scalars.
    for my $scalar ( keys %all_scalars ) {
        my $typeglob = \$symbol_table->{$scalar};
 
        if ( reftype($typeglob) eq 'GLOB' ) { # Ignore constant optimizations, handled above in array/hash code.
            $fake_package->{$scalar}->{'SCALAR'} = encode( *{$typeglob}{'SCALAR'}, 0 );
        }
    }
    
    #Handle inheritance issues regarding both isa and can.
    my ( $full_ISA, $all_subs ) = _get_hierarchy_info($package);
    $extra{$package}{'ISA'} = $full_ISA;
 
    # Wrap all subroutines. (Or rather, redefine each subroutine to record the operation of the original.)
    for my $sub ( keys %{$all_subs} ) {
        my $original_sub = $package->can($sub);
        my $record_to = ( $fake_package->{$sub}->{'CODE'} ||= {} );
        
        # Define the new subroutine
        my $wrapper_sub = sub {
            
            # Discard calls while recording is suspended, i.e. make the call, but don't record it.
            if ($Test::Mimic::Recorder::SuspendRecording) {
                goto &{$original_sub};
            }
            
            # Set up the recording storage for this call.
            my $arg_key = gen_arg_key($package, $sub, \@_);
            my $context_to_result = ( $record_to->{$arg_key} ||= [] );
            
            # TODO: Query user settings regarding the volatility of the arguments.
            my $arg_signature = monitor_args( $package, $sub, \@_ );
            
            # Make actual call, trap exceptions or store return.
            local $Test::Mimic::Recorder::SuspendRecording = 1; # Suspend recording. We don't wan't to record
                                                                # internal calls or state modifications.
            my $context = wantarray();
            my $context_index;
            my $exception;
            my @results;
            my $stored_result;
            my $failed;
            my $eval_error = Devel::EvalError->new();
            $eval_error->ExpectOne(
                eval {
                    if ($context) {
                        $context_index = LIST_CONTEXT;
                        @results = &{$original_sub};
                        $stored_result = [ RETURN, encode( \@results, 1) ];
                    }
                    elsif (defined $context) {
                        $context_index = SCALAR_CONTEXT;
                        $results[0] = &{$original_sub};
                        $stored_result = [ RETURN, encode( $results[0], 0 ) ];
                    }
                    else {
                        $context_index = VOID_CONTEXT;
                        &{$original_sub};
                        $stored_result = [RETURN];
                    }
                    1;
                }
            );
            $failed = $eval_error->Failed();
            if ( $failed ) {
                $exception = ( $eval_error->AllReasons() )[-1];
                $stored_result = [ EXCEPTION, encode( $exception, 0 ) ];
            }
            
            # Maintain records
            push( @operation_sequence, [ $package, CODE_E, $sub, $arg_key, $context_index ] );
            push( @{ $context_to_result->[$context_index] ||= [] }, ( $arg_signature, $stored_result ) );

            # Propagate original behavior
            if ( $failed ) {
                die $exception;
            }
            elsif ($context) {
                return @results;
            }
            elsif ( defined $context ) {
                return $results[0];
            }
            else {
                return;
            }
        };
        
        # Handle prototypes
        my $replacement;
        my $proto = prototype($original_sub);
        $replacement = eval "package $package; sub " . ( defined($proto) ? "($proto) " : '' )
            . "{ return \$wrapper_sub->(\@_); };";
        # Saying 'package' in the eval allows us to record subroutines used by sort. If we don't $a and $b
        # are not imported properly.
        $extra{$package}{'PROTOTYPES'}{$sub} = $proto;
         
        # Redefine the original subroutine
        {
            no warnings 'redefine';
            no strict 'refs';
            *{ $package . '::' . $sub } = $replacement;
        }
    }
}

# Accepts a class name. Returns the class hierarchy flattened into a hash ref and a list of all subroutines
# the class responds too (including inherited subroutines, excluding AUTOLOADED subroutines) also as a hash
# ref. An arbitrary element will exist in the proper hash iff the class isa element or the class can element
# for classes and subroutines respectively. The subroutine names are not fully qualified.
sub _get_hierarchy_info {
    my ($class) = @_;
    
    my %full_ISA = ( $class => ARBITRARY ); # Certainly $class isa $class.
    my %full_subs;
    
    # Find all the subroutines declared in the class.
    my $symbol_table;
    {
        no strict 'refs';
        $symbol_table = \%{ $class . '::' };
    }
    for my $symbol ( keys %{$symbol_table} ) {
        my $typeglob = \$symbol_table->{$symbol};

        # Note if the symbol contains a subroutine.
        # Ignore constant optimizations, handled in _record_package except for the
        # case of inherited constants. Do we need to take care of this case?
        if ( ( reftype($typeglob) eq 'GLOB' ) && defined( *{$typeglob}{'CODE'} ) ) {
            $full_subs{$symbol} = ARBITRARY;
        }
    }
    
    # Get a copy of the actual @ISA array.
    my @true_ISA;
    {
        no strict 'refs';
        @true_ISA = @{ $class . '::ISA' };
    }
    
    # Look through the class hierarchy for all ancestor classes and inherited subroutines.
    for my $parent (@true_ISA) {
        if ( ! exists $full_ISA{$parent} ) {
            my ( $parent_full_ISA, $parent_full_subs ) = _get_hierarchy_info($parent);
            
            # Merge in the parent information.
            @full_ISA{ keys %{$parent_full_ISA} } = values %{$parent_full_ISA};
            @full_subs{ keys %{$parent_full_subs} } = values %{$parent_full_subs};
        }
    }
    
    return ( \%full_ISA, \%full_subs );
}

# Write recording to disk
END {
    finish()
        if ( ! $done_writing );
}

1;
__END__

=head1 NAME

Test::Mimic::Recorder - Perl extension for recording the behavior of perl packages. Typically used in
conjunction with Test::Mimic.

=head1 SYNOPSIS

  # Record the Foo::Bar package
  use Test::Mimic::Recorder {
      'save'      => '.test_mimic_recorder_data',
      'string'    => sub {}, # The sub {} construction simply represents a subroutine reference.
      'destring'  => sub {}, # See below for appropriate contracts.

      'key'           => sub {},
      'monitor_args'  => sub {},

      'packages'  => {
          'Foo::Bar'  => {
              'scalars'   => [ qw< x y z > ],

              'key'           => sub {},
              'monitor_args'  => sub {},

              'subs' => {
                  'foo' => {
                      'key'           => sub {},
                      'monitor_args'  => sub {},
                  },
              },
          },
      },
  }; 

=head1 DESCRIPTION

Test::Mimic::Recorder allows a user to monitor the behavior of a set of packages well enough to recreate
that behavior at a later date with reasonable fidelity. Each subroutine, package array and package hash
(excepting symbol tables) is monitored. Package scalars will be monitored if specified or if the package
inherits from Exporter and they appear in the @EXPORT or @EXPORT_OK arrays.

For each quadruple of package, subroutine, argument and context a history of results will be stored. These
results can consist of either return values or exceptions. Package variables have their history stored in a
slightly different fashion. Every time a variable is read the resulting value will be stored. Reading a
variable can take on different forms depending on the variable's type. For instance, a scalar can merely be
read, but a hash can have a particular one of its elements read, one of its keys read, the existence of one
of its elements read and so forth. Writes are not recorded.

=head2 SUBROUTINES

=over 4

=item Test::Mimic::Recorder->import($preferences)

The $preferences hash reference passed to import is fairly simply and the majority of its structure can be
deduced from the synopsis above. For more information see the documentation for Test::Mimic.

In addition to this $preferences may contain the key 'test_mimic' at the top level. If its value is defined
Test::Mimic::Recorder will assume that it is being used by Test::Mimic. The effect of this is to prevent
Test::Mimic::Recorder from reloading key generators and the like. Only the package names and the scalar lists
will be used from $preferences. This should generally not be used by users directly. In short, ignore the
above paragraph unless you randomly decided to put 'test_mimic' into your hash.

=item finish()

Writes all information recorded so far to disk. If called nothing will be written at the end of execution
automatically. You can, however, call finish again.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

Test::Mimic
Test::Mimic::Library
Test::Mimic::Generator

=head1 AUTHOR

Concept by Tye McQueen.

Development by Brendan Roof, E<lt>brendanroof@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brendan Roof.

Made possible by WhitePages Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
