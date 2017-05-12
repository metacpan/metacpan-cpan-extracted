package Test::Pod::Snippets;
BEGIN {
  $Test::Pod::Snippets::AUTHORITY = 'cpan:YANICK';
}
{
  $Test::Pod::Snippets::VERSION = '0.07';
}
# ABSTRACT: Generate tests from pod code snippets

use warnings;
use strict;
use Carp;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Module::Locate qw/ locate /;
use Params::Validate qw/ validate_with validate /;

has parser => (
    is => 'ro',
    default => sub {
        my $tps = Test::Pod::Snippets::Parser->new;
        $tps->{tps} = shift;
        return $tps;
    },
);

has verbatim => (
    reader => 'is_extracting_verbatim',
    writer => 'extracts_verbatim',
    default => 1,
);

has methods => (
    reader => 'is_extracting_methods',
    writer => 'extracts_methods',
    default => 0,
);

has functions => (
    reader => 'is_extracting_functions',
    writer => 'extracts_functions',
    default => 0,
);

has preserve_lines => (
    is => 'rw',
    default => 1,
);

has object_name => (
    is => 'ro',
    default => '$thingy',
);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


sub generate_snippets {
    my( $self, @files ) = @_;
    my $i = 1;

    print "generating snippets\n";

    for ( @files ) {
        my $testfile = sprintf "t/pod-snippets-%02d.t", $i++;
        print "\t$_ => $testfile\n";
        
        open my $fh, '>', $testfile 
                or die "can't open $testfile for writing: $!\n";
        print {$fh} $self->extract_snippets( $_ );
        close $fh;
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub generate_test {
    my $self = shift;

    my %param = validate( @_, { 
            pod => 0,  
            file => 0,
            fh => 0,
            module => 0,
            standalone => 0,
            testgroup => 0,
            sanity_tests => { default => 1 },
        } );

    my @type = grep { $param{$_} } qw/ pod file fh module /;

    croak "method requires one of those parameters: pod, file, fh, module" 
        unless @type;

    if ( @type > 1 ) {
        croak "can only accept one of those parameters: @type";
    }

    my $code = $self->_parse( $type[0], $param{ $type[0] } );

    if ($param{standalone} or $param{testgroup} ) {
        $param{sanity_tests} = 1;
    }

    if( $param{sanity_tests} ) {
        no warnings qw/ uninitialized /;
       $code = <<"END_CODE";
ok 1 => 'the tests compile';   

$code

ok 1 => 'we reached the end!';
END_CODE
    }

    if ( $param{testgroup} ) {
        my $name = $param{file}   ? $param{file} 
                 : $param{module} ? $param{module}
                 : 'unknown'
                 ;
        $code = qq#use Test::Group; #
              . qq#Test::Group::test "$name" => sub { $code }; #;
    }

    my $plan = $param{standalone} ? '"no_plan"' : '' ;

    return <<"END_CODE";
use Test::More $plan;
{
no warnings;
no strict;    # things are likely to be sloppy

$code
}
END_CODE

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


sub _parse {
    my ( $self, $type, $input ) = @_;

    my $output;
    open my $output_fh, '>', \$output;

    if ( $type eq 'pod' ) {
        my $copy = $input;
        $input = undef;
        open $input, '<', \$copy;
        $type = 'fh';
    }

    if ( $type eq 'module' ) {
        my $location = locate $input
            or croak "$input not found in \@INC";
        $input = $location;
        $type = 'file';
    }

    if ( $type eq 'file' ) {
        $self->parser->parse_from_file( $input, $output_fh );
    }
    elsif( $type eq 'fh' ) {
        $self->parser->parse_from_filehandle( $input, $output_fh );
    }
    else {
        die "type $type unknown";
    }

    return $output;
}


sub extract_snippets_from_file {
    my( $self, $file ) = @_;

    if( not -f $file ) {
        croak "$file doesn't seem to exist";
    }

    my $output;
    open my $fh, '>', \$output;

    $self->parser->parse_from_file( $file, $fh );

    return $self->_extract($output);
}


sub extract_snippets {
    my( $self, $pod ) = @_;

    open my $file, '<', \$pod;

    my $output;
    open my $fh, '>', \$output;

    $self->parser->parse_from_filehandle( $file, $fh );

    return $self->_extract($output);
}

sub _extract {
    my( $self, $output ) = @_;

    return <<"END_TESTS";
use Test::More qw/ no_plan /;

no warnings;
no strict;    # things are likely to be sloppy

ok 1 => 'the tests compile';   

$output

ok 1 => 'we reached the end!';

END_TESTS

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub runtest {
    my ( $self, @args ) = @_;

    my $code = $self->generate_test( @args );

    eval $code;

    if ( $@ ) {
        croak "couldn't compile test: $@";
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


sub snippets_ok {
    my( $self, $file ) = @_;

    my $code = $self->extract_snippets( $file );

    eval $code;

    warn $@ if $@;

    return not $@;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub generate_test_file {
    my $self = shift;

    my %param = validate_with( params => \@_,
        spec => { output => 0 },
        allow_extra => 1,
    );

    unless( $param{output} ) {
        my $i;
        my $name;
        do { 
            $i++; 
            $name = sprintf 'tps-%04d.t', $i 
        } while -f $name;

        $param{output} = $name;
    }

    my $filename = $param{output};

    croak "file '$filename' already exists" if -f $filename;

    open my $fh, '>', $filename
        or croak "can't create file '$filename': $!";

    delete $param{output};

    print {$fh} $self->generate_test( %param );

    return $filename;
}

1;

package   # hide from PAUSE
    Test::Pod::Snippets::Parser;

use strict;
use warnings;

no warnings 'redefine';

use parent qw/ Pod::Parser /;

sub initialize {
    $_[0]->SUPER::initialize;
    $_[0]->{$_} = 0 for qw/ tps_ignore tps_ignore_all tps_within_begin_test /;
    $_[0]->{tps_method_level} = 0;
    $_[0]->{tps_function_level} = 0;
}

sub command {
    my ($parser, $command, $paragraph, $line_nbr ) = @_;

    if ( $command eq 'for' ) {
        my( $target, $directive, $rest ) = split ' ', $paragraph, 3;

        return unless $target eq 'test';

        return $parser->{tps_ignore}     = 1 if $directive eq 'ignore';
        return $parser->{tps_ignore_all} = 1 if $directive eq 'ignore_all';

        $parser->{tps_ignore} = 0;
        no warnings qw/ uninitialized /;
        print {$parser->output_handle} join ' ', $directive, $rest;
    }
    elsif( $command eq 'begin' ) {
        my( $target, $rest ) = split ' ', $paragraph, 2;
        return unless $target eq 'test';
        $parser->{tps_within_begin_test} = 1;
        print {$parser->output_handle} $rest;
    }
    elsif( $command eq 'end' ) {
        my( $target ) = split ' ', $paragraph, 2;
        return unless $target eq 'test';

        $parser->{tps_within_begin_test} = 0;
    }
    elsif( $command =~ /^head(\d+)/ ) {

        return unless $parser->{tps}->is_extracting_functions 
                   or $parser->{tps}->is_extracting_methods;

        my $level = $1;

        for my $type ( qw/ tps_method_level tps_function_level / ) {
            if ( $level <= $parser->{$type} ) {
                $parser->{$type} = 0;
            }
        }

        if ( $paragraph =~ /^\s*METHODS\s*$/ ) {
            $parser->{tps_method_level} =
                $parser->{tps}->is_extracting_methods && $level;
            return;
        }

        if ( $paragraph =~ /^\s*FUNCTIONS\s*$/ ) {
            $parser->{tps_function_level} = 
                $parser->{tps}->is_extracting_functions && $level;
            return;
        }

        return if $parser->{tps_ignore} or $parser->{tps_ignore_all};

        my $master_level =  $parser->{tps_method_level} 
                         || $parser->{tps_function_level}
                         || return ;

        # functions and methods are deeper than
        # their main header
        return unless $level > $master_level; 

        $paragraph =~ s/[IBC]<(.*?)>/$1/g;  # remove markups

        $paragraph =~ s/^\s+//;
        $paragraph =~ s/\s+$//;

        if ( $parser->{tps_method_level} ) {
            if ( $paragraph =~ /^new/ ) {
                print {$parser->output_handle}
                    $parser->{tps}->get_object_name,
                    ' = $class->', $paragraph, ";\n";
                return;
            }
            else {
                $paragraph = $parser->{tps}->object_name.'->'.$paragraph;
            }
        }

        my $line_ref;
        $line_ref = "\n#line $line_nbr " . ( $parser->input_file || 'unknown')
                    . "\n"
            if $parser->{tps}->preserve_lines;

        print {$parser->output_handle} 
            $line_ref,
            '@result = ', $paragraph, ";\n";
    }
}

sub textblock {
    return unless $_[0]->{tps_within_begin_test};

    print_paragraph( @_ ); 
}

sub interior_sequence {}

sub verbatim {
    my $self = shift;

    return unless $self->{tps}->is_extracting_verbatim;

    return if ( $self->{tps_ignore} or $self->{tps_ignore_all} ) 
           and not $self->{tps_within_begin_test};

    print_paragraph( $self, @_ ); 
}

sub print_paragraph {
    my ( $parser, $paragraph, $line_no ) = @_;

    $DB::single = 1;
    my $filename = $parser->input_file || 'unknown';

    # remove the indent
    $paragraph =~ /^(\s*)/;
    my $indent = $1;
    $paragraph =~ s/^$indent//mg;
    $paragraph = "\n#line $line_no $filename\n".$paragraph 
        if $parser->{tps}->preserve_lines;

    $paragraph .= ";\n";

    print {$parser->output_handle} $paragraph;
}


'end of Test::Pod::Snippets::Parser';


=pod

=head1 NAME

Test::Pod::Snippets - Generate tests from pod code snippets

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use Test::More tests => 3;

    use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new;

    my @modules = qw/ Foo Foo::Bar Foo::Baz /;

    $tps->runtest( module => $_, testgroup => 1 ) for @modules;

=head1 DESCRIPTION

=over

=item Fact 1

In a perfect world, a module's full API should be covered by an extensive
battery of testcases neatly tucked in the distribution's C<t/> directory. 
But then, in a perfect world each backyard would have a marshmallow tree and
postmen would consider their duty to circle all the real good deals in pamphlets
before stuffing them in your mailbox. Obviously, we're not living in a perfect
world.

=item Fact 2

Typos and minor errors in module documentation. Let's face it: it happens to everyone. 
And while it's never the end of the world and is prone to rectify itself in
time, it's always kind of embarassing. A little bit like electronic zits on
prepubescent docs, if you will.

=back

Test::Pod::Snippets's goal is to address those issues. Quite simply, 
it extracts verbatim text off pod documents -- which it assumes to be 
code snippets -- and generate test files out of them.

=head1 METHODS

=head2 new( %options )

Creates a new B<Test::Pod::Snippets> object. The method accepts
the following options:

=over

=item verbatim => I<$boolean>

If set to true, incorporates the pod's verbatim parts to the test.

Set to true by default.

=item functions => I<$boolean>

If set to true, extracts function definitions from the pod.
More specifically, Test::Pod::Snippets looks for a pod section 
called FUNCTIONS, and assumes the title of all its 
subsections to be functions. 

For example, the pod

    =head1 FUNCTIONS

    =head2 play_song( I<$artist>, I<$song_title> )

    Play $song_title from $artist.

    =head2 set_lighting( I<$intensity> )

    Set the room's light intensity (0 is pitch black 
    and 1 is supernova white, -1 triggers the stroboscope).

would generate the code

    @result = play_song( $artist, $song_title );
    @result = set_lightning( $intensity );

Pod markups are automatically stripped from the headers. 

=item methods  => I<$boolean>

Same as C<functions>, but with methods. In this
case, Test::Pod::Snippets looks for a pod section called METHODS.
The object used for the tests is assumed to be '$thingy' 
(but can be overriden using the argument C<object_name>,
and its class must be given by a variable '$class'.

For example, the pod

    =head1 METHODS

    =for test
        $class = 'Amphibian::Frog';

    =head2 new( $name )

    Create a new froggy!

    =head2 jump( $how_far )

    Make it jumps.

will produces

    $class = 'Amphibian::Frog';
    $thingy = $class->new( $name );
    @result = $thingy->jump( $how_far );

=item object_name => I<$identifier>

The name of the object (with the leading '$') to be
used for the methods if the T:P:S object is set to 
extract methods.

=item preserve_lines => I<$boolean>

If sets to true (which is the default), the generated code
will be peppered with '#line' pre-compiler lines that will
have any failing test point to the test's original file.

=back

=head2 is_extracting_verbatim

=head2 is_extracting_functions

=head2 is_extracting_methods

Returns true if the object is configured to
extract that part of the pod, false otherwise.

=head2 extracts_verbatim( I<$boolean> )

=head2 extracts_functions( I<$boolean> )

=head2 extracts_methods( I<$boolean> )

Configure the object to extract (or not) the given
pod parts.

=head2 generate_test( $input_type => I<$input>, %options )

Extracts the pod off I<$input> and generate tests out of it.
I<$input_type> can be 'file' (a filename), 
'fh' (a filehandler), 'pod' (a string containing pod) or
'module' (a module name).

The method returns the generate tests as a string.

The method accepts the following options:

=over

=item standalone => I<$boolean>

If standalone is true, the generated
code will be a self-sufficient test script. 
Defaults to 'false'.

    # create a test script out of the module Foo::Bar
    open my $test_fh, '>', 't/foo-bar.t' or die;
    print {$test_fh} $tps->generate_test( 
        module     => 'Foo::Bar',
        standalone => 1 ,
    );

=item sanity_tests => I<$boolean>

If true (which is the default), two tests are added to the
very beginning and end of the extracted code, like so:

    ok 1 => 'the tests compile';   
    $extracted_code
    ok 1 => 'we reached the end!';

=item testgroup => I<$boolean>

If true, the extracted code will be wrapped in a L<Test::Group> 
test, which will report a single 'ok' for the whole series of test
(but will give more details if something goes wrong).  Is set
to 'false' by default.

=back

=head2 generate_test_file( $input_type => I<$input>, %options )

Does the same as C<generate_test>, but save the generated
code in a file. The name of the file is the value of the
option B<output>, if given. If the file already exist,
the method dies.  If B<output> is not given, 
the filename will be
of the format 'tps-XXXX.t', where XXXX is choosen not to
interfere with existing tests.  Exception made of C<output>,
the options accepted by the method are the same than for
C<generate_test>.

Returns the name of the created file.

=head2 runtest( $input_type => I<$input>, %options )

Does the same than C<generate_test>, except that it 
executes the generated code rather than return it. 
The arguments are treated the same as for C<generate_test>.

=head2 generate_snippets( @filenames )

For each file in I<@filenames>, generates a I<pod-snippets-X.t>
file in the C<t/> directory.

=head2 extract_snippets_from_file( $filename )

Extracts the snippets from the file and returns a string containing
the generated tests.

=head2 extract_snippets( $pod )

Extracts the snippets from the string I<$pod> and
returns a string containing the generated tests.

=head2 snippets_ok( $pod )

Extracts the snippets from I<$pod> (which can be a string or a filename) and
run the code, returning b<true> if the code run and b<false> if it fails.

=head1 HOW TO USE TEST::POD::SNIPPETS IN YOUR DISTRIBUTION

The easiest way is to create a test.t file calling Test::Pod::Snippets
as shown in the synopsis.  If, however, you don't want to 
add T:P:S to your module's dependencies, you can 
add the following to your Build.PL:

  my $builder = Module::Build->new(
    # ... your M::B parameters
    PL_files  => { 'script/test-pod-snippets.PL' => q{}  },
    add_to_cleanup      => [ 't/tps-*.t' ],
  );

Then create the file F<script/test-pod-snippets.PL>, which should contains

    use Test::Pod::Snippets;

    my $tps = Test::Pod::Snippets->new;

    my @files = qw#
        lib/your/module.pm
        lib/your/documentation.pod
    #;
    
    print "generating tps tests...\n";
    print $tps->generate_test_file( $_ ), "created\n" for @files;
    print "done\n";

And you're set! Running B<Build> should now generate one test file
for each given file.

=head1 SYNTAX

By default, Test::Pod::Snippets considers all verbatim pod text to be 
code snippets. To tell T::P::S to ignore subsequent pieces of verbatim text,
add a C<=for test ignore> to the pod. Likely, to return to the normal behavior, 
insert C<=for test>. For example:

    A sure way to make your script die is to do:

    =for test ignore

        $y = 0; $x = 1/$y;

    The right (or safe) way to do it is rather:

    =for test

        $y = 0; $x = eval { 1/$y };
        warn $@ if $@;

C<=for test> and C<=begin test ... =end test> can also be used to
add code that should be include in the tests but not in the documentation.

Example:

    The right way to do it is:

        $y = 0; $x = eval { 1/$y };

        =for test
           # make sure an error happened
           is $x => undef;
           ok length($@), 'error is reported';

=head1 SEE ALSO

L<podsnippets>

=head2 Test::Inline

Whereas L<Test::Pod::Snippets> extracts
tests out of the modules' documentation, Adam Kennedy's I<Test::Inline> 
allows to insert tests within a module, side-by-side with its code 
and documentation. 

For example, the following code using I<Test::Pod::Snippets>

    =head2 shout()

    Shoutify the passed string.

        # set $x to 'CAN YOU HEAR ME NOW?'
        my $x = shout( 'can you hear me now?' );

        =for test
        is $x => 'CAN YOU HEAR ME NOW?';

is equivalent to this code, using I<Test::Inline>:

    =head2 shout()

    Shoutify the passed string.

        # set $x to 'CAN YOU HEAR ME NOW?'
        my $x = shout( 'can you hear me now?' );

    =begin testing
    my $x = shout( 'can you hear me now?' );
    is $x => 'CAN YOU HEAR ME NOW?';
    =end testing

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


