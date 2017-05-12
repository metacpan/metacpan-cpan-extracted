package Text::Amuse::Preprocessor::Footnotes;

use strict;
use warnings;
use File::Spec;
use File::Temp;
use File::Copy;
use Data::Dumper;

=encoding utf8

=head1 NAME

Text::Amuse::Preprocessor::Footnotes - Rearrange footnote numbering in muse docs

=head1 DESCRIPTION

Given an input file, scan its footnotes and rearrange them. This means
that such document:

  #title test
  
  Hello [1] There [1] Test [1]
  
  [1] first
  
  Hello hello

  [1] second
  
  [1] third

will become

  #title test
  
  Hello [1] There [2] Test [3]
  
  Hello hello

  [1] first
  
  [2] second
  
  [3] third

Given that the effects of the rearranging could be very destructive
and mess up your documents, the module try to play on the safe side
and will refuse to write out a file if there is a count mismatch
between the footnotes and the number of references in the body.

The core concept is that the module doesn't care about the number.
Only order matters.

This could be tricky if the document uses the number between square
brackets for other than footnotes.

Also used internally by L<Text::Amuse::Preprocessor>.

=head1 METHODS

=head2 new(input => $infile, output => $outfile, debug => 0);

Constructor with the following options:

=head3 input

The input file. It must exists.

=head3 output

The output file. It will be written by the module if the parsing
succeedes. If not specified, the module will run in dry-run mode.

=head3 debug

Print some additional info.

=head2 process

Do the job, write out C<output> and return C<output>. On failure, set
an arror and return false.

=head2 error

Accesso to the error. If there is a error, an hashref with the
following keys will be returned:

=over 4

=item references

The total number of footnote references in the body.

=item footnotes

The total number of footnotes.

=item references_found

The reference's numbers found in the body as a long string.

=item footnotes_found

The footnote' numbers found in the body as a long string.

=back

=cut


sub new {
    my ($class, %options) = @_;
    my $self = {
                input => undef,
                output => undef,
                debug => 0,
               };
    foreach my $k (keys %$self) {
        if (exists $options{$k}) {
            $self->{$k} = delete $options{$k};
        }
    }
    $self->{_error} = '';

    die "Unrecognized option: " . join(' ', keys %options) . "\n" if %options;
    die "Missing input" unless defined $self->{input};
    # output is no checked.
    bless $self, $class;
}

sub debug {
    return shift->{debug};
}

sub input {
    return shift->{input};
}

sub output {
    return shift->{output};
}

=head2 error

Return a string with the errors caught, undef otherwise.

=cut

sub error {
    return shift->{_error};
}

sub _set_error {
    my ($self, $error) = @_;
    $self->{_error} = $error if $error;
}


=head2 tmpdir

Return the directory name used internally to hold the temporary files.

=cut

sub tmpdir {
    my $self = shift;
    unless ($self->{_tmpdir}) {
        $self->{_tmpdir} = File::Temp->newdir(CLEANUP => !$self->debug);
    }
    return $self->{_tmpdir}->dirname;
}

sub process {
    my $self = shift;
    print Dumper($self) if $self->debug;
    # auxiliary files
    my $tmpdir = $self->tmpdir;
    print "Using $tmpdir\n" if $self->debug;
    my $auxfile  = File::Spec->catfile($tmpdir, 'fixed.muse');
    # open the auxiliary file
    open (my $out, '>:encoding(UTF-8)', $auxfile)
      or die ("can't open $auxfile $!");

    my $infile   = $self->input;
    open (my $in, '<:encoding(UTF-8)', $infile)
      or die ("can't open $infile $!");
    
    # read the file.
    my $fn_counter = 0; 
    my $body_fn_counter = 0;
    my @footnotes_found;
    my @references_found;
    while (my $r = <$in>) {

        # a footnote
        if ($r =~ s/^
                    \[
                    ([0-9]+)
                    \]
                    (?=\s)/_check_and_replace_fn($1,
                                                 \$fn_counter,
                                                 \@footnotes_found)/xe) {
            # nothing to do
        }
        else {
            $r =~ s/\[
                    ([0-9]+)
                    \]/_check_and_replace_fn($1,
                                             \$body_fn_counter,
                                             \@references_found)/gxe;
        }
        print $out $r;
    }

    close $in  or die $!;
    close $out or die $!;

    if ($body_fn_counter == $fn_counter) {
        if (my $outfile = $self->output) {
            copy $auxfile, $outfile or die "Cannot copy $auxfile to $outfile $!";
            return $outfile;
        }
        else {
            # dry run, just state success
            return 1;
        }
    }
    else {
        $self->_set_error({
                           references => $body_fn_counter,
                           footnotes => $fn_counter,
                           references_found => join(" ",
                                                    map { "[$_]" }
                                                    @references_found),
                           footnotes_found  => join(" ",
                                                     map { "[$_]" }
                                                     @footnotes_found),
                          });
        return;
    }
}

sub _check_and_replace_fn {
    my ($number, $current, $list) = @_;
    if ($number < ($$current + 100)) {
        push @$list, $number;
        return '[' . ++$$current . ']';
    }
    else {
        return '[' . $number . ']';
    }

}

1;
