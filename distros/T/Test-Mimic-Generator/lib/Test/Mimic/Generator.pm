package Test::Mimic::Generator;

use 5.006001; #for open( my $fh...
use strict;
use warnings;

our $VERSION = 0.009_005;

#Returns the name of the package that objects returned by new are blessed into. For encapuslation
#purposes this may not be Test::Mimic::Generator. Should be considered protected.
sub get_object_package {
    my ($class) = @_;
    return $class . '::Object';
}

# See the POD documentation below.
sub new {
    my ($class) = @_;
    return bless( [], $class->get_object_package() );
}

package Test::Mimic::Generator::_Implementation;

use Test::Mimic::Library qw< stringify stringify_by destringify DATA descend >;
use Cwd qw<abs_path>;
use File::Copy;
use Data::Dumper;

# Construct constants to access member variables.
BEGIN {
    my $offset = 0;
    for my $field ( qw< TYPEGLOBS EXTRA OPERATION_SEQUENCE READ_DIR > ) {
        eval("sub $field { return $offset; }");
        $offset++;
    }
}

# See the POD documentation below.
sub Test::Mimic::Generator::Object::load {
    my ($self, $dir_name) = @_;

    open( my $fh, '<', $dir_name . '/additional_info.rec' ) or die "Could not open file: $!";
    
    my $recorded_data;
    {
        local $/;
        undef $/;
        $recorded_data = <$fh>;
    }

    close($fh) or die "Could not close file: $!";
    my $living_data = destringify($recorded_data); 

    $self->[TYPEGLOBS] = $living_data->[0]; #This could change later, so I'm listing all the assigns explicitly.
    $self->[EXTRA] = $living_data->[1];
    $self->[OPERATION_SEQUENCE] = $living_data->[2];
    $self->[READ_DIR] = $dir_name;
}

# See the POD documentation below.
sub Test::Mimic::Generator::Object::write {
    my ( $self, $write_dir, @packages ) = @_;

    # Either select all recorded packages to write or verify that the requested packages were recorded.
    if ( @packages == 0 ) { # If no packages were selected explicitly...
        @packages = keys %{ $self->[TYPEGLOBS] };
    }
    else {
        for my $package (@packages) {
            if ( ! exists( $self->[TYPEGLOBS]->{$package} ) ) {
                die "The $package package was not found in the loaded recording.";
            }
        }
    }
    
    my $top_level = abs_path();
    
    # Move to the $write_dir/lib directory, creating dirs as needed.
    descend($write_dir);
    descend('lib');
   
    # Consider each package, construct and write the .pm file.
    my $start_path = abs_path();
    for my $package (@packages) {
                
        # Gets the name of the .pm file, descends to where it will be located.
        my @dirs = split( /::/, $package );
        my $filename = pop(@dirs) . '.pm';
        for my $dir (@dirs ) {
            descend($dir);
        }
        
        # Open, write and close the .pm file.
        open( my $fh, '>', $filename ) or die "Could not open file: $!";
        _create($package,  $self->[TYPEGLOBS]->{$package}, $self->[EXTRA]->{$package}, $fh );
        close($fh) or die "Could not close file: $!";

        # Move to the top of our fake library hierarchy.
        chdir($start_path) or die "Could not change the current working directory: $!";
    }

    # Rename the history file so that the controller recognizes it.
    chdir($top_level) or die "Could not change the current working directory: $!"; 
    copy( $self->[READ_DIR] . '/history_from_recorder.rec', $write_dir . '/history_for_playback.rec' )
        or die "Unable to copy file: $!";
    # NOTE: In the future we may modify the contents of the file as well.
}

{ 
    # A few useful constant maps.
    my %TYPE_TO_SIGIL = ( 'ARRAY' => '@', 'HASH' => '%', 'SCALAR' => '$' );
    my %TYPE_TO_TIE = (
        'ARRAY'     => 'Test::Mimic::Library::PlayArray',
        'HASH'      => 'Test::Mimic::Library::PlayHash',
        'SCALAR'    => 'Test::Mimic::Library::PlayScalar',
    );

    # Accepts a package name, the corresponding pseudo symbol table, the corresponding extra hash ref
    # and a filehandle to write to. Assembles the code for the mock package and writes it to disk. 
    sub _create {
        my ( $package, $pseudo_symbol_table, $extra, $fh ) = @_;

        my $header_code = join( "\n",
            'package ' . $package  . ';',
            '',
            'use strict;',
            'use warnings;',
            '',
            'BEGIN {',  #TODO: Check to see if Test::Mimic is loaded, allow requiring fake pack directly etc.
            '    Test::Mimic::prepare_for_use();',
            '}',
            '',
            'use Scalar::Util;',
            '',
            'use Test::Mimic::Library qw< execute get_references HISTORY decode destringify >;',
            'use Test::Mimic::Library::PlayScalar;',
            'use Test::Mimic::Library::PlayArray;',
            'use Test::Mimic::Library::PlayHash;',
            '',
            '',
        );
        print $fh $header_code;

        # Create code to tie package variables.
        my $package_var_code = join( "\n",
            'BEGIN {',
            '    my $references = get_references();',
            '',
        );
        for my $typeglob ( keys %{$pseudo_symbol_table} ) {

            # Tie the current typeglob
            my %slots = %{ $pseudo_symbol_table->{$typeglob} };
            delete $slots{'CODE'};
            delete $slots{'CONSTANT'};
            # NOTE: You may (some day) need to delete other types too.
            for my $type ( keys %slots ) {
                $package_var_code .= "\n" . '    tie( '
                    . $TYPE_TO_SIGIL{$type} . $package . '::' . $typeglob # Full name including sigil
                    . ', q<' . $TYPE_TO_TIE{$type} 
                    . '>, $references->['
                    . $slots{$type}->[DATA]    # Index for the reference, ...->[ENCODE_TYPE]
                                               # must be VOLATILE. Check?
                    . ']->[HISTORY] );';
            }
        }
        $package_var_code .= "\n" . '}' . "\n\n";
        print $fh $package_var_code;

        # Create code for generating constants.
        my $constant_code = 'use constant {' . "\n";
        for my $symbol ( keys %{$pseudo_symbol_table} ) {
            my $typeglob = $pseudo_symbol_table->{$symbol};
            if ( exists( $typeglob->{'CONSTANT'} ) ) {
                $constant_code .= '    ' . _string_to_perl($symbol) . ' => decode( destringify( '
                    . _string_to_perl( stringify( $typeglob->{'CONSTANT'} ) ) . ' ) ),' . "\n";
                
            }
        }
        $constant_code .= '};' . "\n\n";
        print $fh $constant_code;

        my @ancestors = %{ $extra->{'ISA'} };
        my $isa_code = join( "\n",
            '{',
            '    my %ancestors = qw< ' . "@ancestors" . ' >;', # Interpolation is needed here.
            '',
            '    sub isa {',
            '        my ( $self, $type ) = @_;',
            '',    
            '        if ( Scalar::Util::reftype($self) ) {',
            '            my $name = Scalar::Util::blessed($self);',
            '            if ($name) {',
            '                return exists( $ancestors{$name} );',
            '            }',
            '            else {',
            '                return ();',
            '            }',
            '        }',
            '        else {',
            '            return exists( $ancestors{$self} );',
            '        }',
            '    }',
            '}',
            '',
            '',
        );
        # TODO: Make this dependent on user options.
        print $fh $isa_code;

        # Create code for user defined subroutines
        my $prototypes = $extra->{'PROTOTYPES'};
        for my $symbol ( keys %{$pseudo_symbol_table} ) {
            my $typeglob = $pseudo_symbol_table->{$symbol};
            if ( exists( $typeglob->{'CODE'} ) ) {
                my $sub_code = '{' . "\n";  # Of course, I could say "{\n". I am being overly verbose in an
                                            # attempt to very explicitly separate out strings that
                                            # interpolate. This is a problem because the perl code that I am
                                            # writing often uses scalars that could be accidentally
                                            # interpolated. If I come back to this line and add a scalar (or
                                            # array) I don't want it to bite me.

                # Create the code for the behavior hash.
                my $behavior_code = stringify( $typeglob->{'CODE'} );
                $sub_code .= 'my $behavior = destringify( ' . _string_to_perl($behavior_code) . ' );' . "\n";
                
                my $prototype = $prototypes->{$symbol};
                $sub_code .= join( "\n",
                    '',
                    '    sub ' . $symbol . ( defined($prototype) ? " ($prototype)" : '' ) . ' {',
                    '        return execute( q<' . $package . '>, q<' . $symbol . '>, $behavior, \@_ );',
                    '    }',
                    '}',
                    '',
                    '',
                );

                print $fh $sub_code;
            }
        }
    }
}

# Given a string returns a Perl expression (as a string) that evaluates to the passed string.
sub _string_to_perl {
    my ($string) = @_;

    my $code = Dumper($string);
    $code =~ s/^.*?= //;
    $code =~ s/;.*?\n$//;

    return $code;
}

1;
__END__

=head1 NAME

Test::Mimic::Generator - Perl module for generating mock perl packages from data recorded by Test::Mimic::Recorder.

=head1 SYNOPSIS

  use Test::Mimic::Generator;

  my $generator = Test::Mimic::Generator->new();
  $generator->load('.test_mimic_recorder_data');
  $generator->write('.test_mimic_data');

=head1 DESCRIPTION

=over

=item Test::Mimic::Generator->new()

Constructs and returns a new generator object.

=cut

=item $generator->load($read_directory)

Accepts the name of a directory to load information from. Test::Mimic::Recorder must have written to this
directory. Can be called multiple times. Only the information from the last call will be used. Later in
development we should be able to merge multiple recordings.

=cut

=item $generator->write($write_directory)

Accepts the name of a directory to store the generated .pm files and other information in. This directory
need not exist. The .pm files will be stored in "$write_directory/lib". Additional history information will
be recorded in "$write_directory/history_for_playback.rec".

=cut

=item NOTE
 
It should be mentioned that the generated .pm files
require that Test::Mimic::Library be in a certain state. Specifically,
Test::Mimic::Library::load_records("$write_directory/history_for_playback.rec") should have been called.
Typically this is handled by the controller, Test::Mimic, but if you are using the files independently you
must do this yourself.

=back

=head2 EXPORT

Nothing available for export.

=head1 SEE ALSO

Other members of the Test::Mimic suite:
Test::Mimic
Test::Mimic::Recorder
Test::Mimic::Library

The latest source for the Test::Mimic suite is available at:

git://github.com/brendanr/Test--Mimic.git

=head1 AUTHOR

Brendan Roof, E<lt>brendanroof@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brendan Roof.

Made possible by a generous contribution from WhitePages, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
