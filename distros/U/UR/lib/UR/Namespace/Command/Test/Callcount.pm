package UR::Namespace::Command::Test::Callcount;

use warnings;
use strict;
use IO::File;
use File::Find;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    has => [
        'sort' => { is => 'String', valid_values => ['count', 'sub'], default_value => 'count',
                    doc => 'The output file should be sorted by "count" (sub call counts) or "sub" (sub names)' },
    ],
    has_optional => [
        input  => { is => 'ARRAY', doc => 'list of input file pathnames' },
        output => { is => 'String', doc => 'pathname of the output file' },
        bare_args => {
            is_many => 1,
            shell_args_position => 1
        }
    ],
);

sub help_brief { "Collect the data from a prior 'ur test run --callcount' run into a single output file" }

sub help_synopsis {
    return <<EOS
cd MyNamespace
ur test run --callcount                  # run tests and generate *.callcount files
ur test callcount --output all.callcount # collect all *.callcount info in the current tree

# Collect results from only 2 files and print results to STDOUT
ur test callcount t/test_1.callcount t/test_2.callcount
EOS
}

sub help_detail {
    return <<EOS
This command collects the data in *.callcount files (generated when tests are
run with the 'ur test run --callcount' command), combines like data among
them, and writes a new callcount file with the collected data.  

Input files can be specified on the command line, and the default is to find
all *.callcount files in the current directory tree.  The output file can
be specified with the --output option, or prints its results to STDOUT
by default.
EOS
}

sub execute {

    #$DB::single = 1;
    my $self = shift;

    # First, handle all the different ways input files/directories are
    # handled
    my @input;
    my $inputs = $self->input;
    if ($inputs and ref($inputs) eq 'ARRAY') {
        @input = @$inputs;
    } elsif ($inputs and $inputs =~ m/,/) {
        @input = split(',',$inputs);
    } elsif (!$inputs) {
        @input = $self->bare_args;
        @input = ('.')  unless @input;  # when no inputs at all are given, start with '.'
    } else {
        $self->error_message("Couldn't determine input files and directories");
        return;
    }

    # Now, flatten out everything in @input by searching in directories
    # for *.callcount files
    my(@directories, %input_files);
    foreach (@input) {
        if (-d $_) {
            push @directories, $_;
        } else {
            $input_files{$_} = 1;
        }
    }
    if (@directories) {
        my $wanted = sub {
                         if ($File::Find::name =~ m/.callcount$/) {
                             $input_files{$File::Find::name} = 1;
                         }
                     };
        File::Find::find($wanted, @directories);
    }

    my $out_fh;
    if ($self->output and $self->output eq '-') {
        $out_fh = \*STDOUT;
    } elsif ($self->output) {
        my $output = $self->output;
        $out_fh = IO::File->new($output, 'w');
        unless ($out_fh) {
            $self->error_message("Can't open $output for writing: $!");
            return undef;
        }
    }


    my %data;
    foreach my $input_file ( keys %input_files ) {
        my $in_fh = IO::File->new($input_file);
        unless ($in_fh) {
            $self->error_message("Can't open $input_file for reading: $!");
            next;
        }

        while(<$in_fh>) {
            chomp;
            my($count, $subname, $subloc, $callers) = split(/\t/, $_, 4);
            $callers ||= '';

            my %callers;
            foreach my $caller ( split(/\t/, $callers ) ) {
                $callers{$caller} = 1;
            }
 
            if (exists $data{$subname}) {
                $data{$subname}->[0] += $count;
                foreach my $caller ( keys %callers ) {
                    $data{$subname}->[3]->{$caller} = 1;
                }
            } else {
                $data{$subname} = [ $count, $subname, $subloc, \%callers];
            }
        }
        $in_fh->close();
    }

    my @order;
    if ($self->sort eq 'count') {
        @order = sort { $a->[0] <=> $b->[0] } values %data;
    } elsif ($self->sort eq 'sub' or $self->sort eq 'subs') {
        @order = sort { $a->[1] cmp $b->[1] } values %data;
    }

    if ($out_fh) {
        foreach ( @order ) {
            my $callers = join("\t", keys %{$_->[3]});  # convert the callers back into a \t sep string
            $out_fh->print(join("\t",@{$_}[0..2], $callers), "\n");
        }
        $out_fh->close();
    }

    return \@order;
}

    
1;

=pod

=head1 NAME

B<ur test callcount> - collect callcount data from running tests into one file

=head1 SYNOPSIS

 # run tests in a given namespace
 cd my_sandbox/TheApp
 ur test run --recurse --callcount

 ur test callcount --output all_tests.callcount

=head1 DESCRIPTION

Callcount data can be used to find unused subroutines in your code.  When 
the test suite is run with the C<callcount> option, then for each *.t file
run by the test suite, a corresponding *.callcount file is created containing
information about how often all the defined subroutines were called.

The callcount file is a plain text file with three columns:

=over 4

=item 1.

The number of times this subroutine was called

=item 2.

The name of the subroutine

=item 3.

Where in the code this subroutine is defined

=back

After a test suite run with sufficient coverage, subroutines with 0 calls
are candidates for removal, and subs with high call counts are candidates
for optimization.

=head1 OPTIONS

=over 4

=item --input

Name the *.callcount input file(s).  When run from the command line, it
accepts a list of files separated by ','s.  Input files can also be given
as plain, unnamed command line arguments (C<bare_args>).  When run as a
command module within another program, the C<input>) property can be an
arrayref of pathanmes.

After inputs are determined, any directories given are expanded by searching
them recursively for files ending in .callcount with L<File::Find>.

If no inputs in any form are given, then it defaults to '.', the current
directory, which means all *.callcount files under the current directory
are used.

=item --output

The pathname to write the collected data to.  The user may use '-' to print
the results to STDOUT.

=item --sort

How the collected results should be sorted before being reported.  The
default is 'count', which sorts incrementally by call count (the first
column).  'sub' performs a string sort by subroutine name (column 2).

=back

=head1 execute()

The C<execute()> method returns an arrayref of data sorted in the appropriate
way.  Each element is itself an arrayref of three items: count, sub name, and
sub location.

=cut


