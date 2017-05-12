package Text::Filter::Chain; # chains multiple filters and runs them sequentially
# $Id: Chain.pm,v 1.5 2000/12/05 15:53:52 verhaege Exp $
use strict;
use vars qw($VERSION);
use fields qw(filters input output);
$VERSION = '0.02';

sub new {
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    
    no strict 'refs';
    my $this = bless [\%{"${pkg}::FIELDS"}], $pkg;
    
    my %arg = @_;
    while(my ($k,$v) = each %arg) {
	$this->{$k} = $v;
    } 

    $this->{filters} ||= [];
    foreach(@{$this->{filters}}) {
	$this->is_valid_filter($_) or die "Invalid filter";
    }

    $this;
}

sub add_filter {
    my $this = shift;
    foreach(@_) {
	$this->is_valid_filter($_) or die "Invalid filter";
	push @{$this->{filters}}, $_;
    }
}

sub is_valid_filter {
    my $this = shift;
    my $filter = shift;
    
    # filter must have methods set_input(), set_output() and run()
    return $filter->can('set_input') && $filter->can('set_output') && $filter->can('run');
}

sub set_input { # 2 arguments possible (input and input_postread), so stored as ref to an array
    my $this = shift;
    $this->{input} = \@_;
}

sub set_output { # 2 arguments possible (output and output_prewrite), so stored as ref to an array
    my $this = shift;
    $this->{output} = \@_;
}

sub run {
    my $this = shift;

    my $n = scalar @{$this->{filters}};
    return unless $n; # nothing to be done when no filters present
    
    # automagical default output buffer 
    unless(defined($this->{output})) { # skip if a chain output is specified
	my $final_filter = $this->{filters}->[-1];
	if($final_filter->isa('Text::Filter') # we can do this effort only for Text::Filter or derived classes
	   && !defined($final_filter->{_filter_output})) {
	    $this->set_output([]); # redirects chain output to an array
	}
    }

    # set chain input and output 
    $this->{filters}->[0]->set_input(@{$this->{input}})
	if defined $this->{input};
    $this->{filters}->[-1]->set_output(@{$this->{output}})
	if defined $this->{output};
    
    # temporary buffers for in between filters
    my $inbuf  = [];
    my $outbuf = [];

    # run all filters in a sequence
    for(my $i = 0; $i < $n; ++$i) {
	my $filter = $this->{filters}->[$i];
	$filter->set_input($inbuf)   unless $i == 0;
	$filter->set_output($outbuf) unless $i == $n - 1;
	$filter->run;
	if($i < $n - 1) { # pipe output of this filter to input of next one
	    $inbuf = $outbuf;
	    $outbuf = [];
	}
    }
}

1;

__END__

=head1 NAME

Text::Filter::Chain - object for chaining Text::Filter objects and running
them sequentially, feeding the output of each filter to the input of the 
next one.

=head1 SYNOPSIS

    use Text::Filter::Chain;

    # let's assume this is a filter which converts text to all lowercase
    $lc = new LowerCaser(input => 'foo.txt'); # reads from file foo.txt
    
    # and assume the following filter greps for a specified pattern
    $grep = new Grepper(pattern => '\bfoo\b',  
                        output  => 'foo.out'); # writes to file foo.out

    # then these commands will read from foo.txt, convert the text to all
    # lowercase, filter out all lines with the word 'foo' and write to foo.out
    $chain = new Text::Filter::Chain(filters => [$lc,$grep]);
    $chain->run(); # this invokes the run() method on $lc and $grep

=head1 DESCRIPTION

=over 4

=item new()

Returns a new empty C<Text::Filter::Chain> object. Optionally, an 
ordered array of filters can be specified by passing a C<filters> 
argument to new(). All filters are checked using is_valid_filter().

=item add_filter($filter)

Adds the filter object $filter to the end of the array of filters. 
The filter is checked using is_valid_filter().

=item is_valid_filter($filter)

Checks whether $filter is a valid filter for inclusion in a 
C<Text::Filter::Chain>. The following requirements need to be met:

=over 2

=item 

a set_input() method must be available for setting the filter input;

=item 

a set_output() method must be available for setting the filter output;

=item 

a run() method must be available which runs the filter on its entire input.

=back

Note that $filter does not need to be a C<Text::Filter> or derived object. 
However, deriving at least the final filter in the chain from C<Text::Filter>
adds the benefit of automagical output buffer creation (see run()).

=item set_input()

Sets the arguments which will be passed to the set_input() method of 
the first filter in the chain in run().

=item set_output()

Sets the arguments which will be passed to the set_output() method of
the final filter in the chain in run().

=item run()

Runs all filters in the chain. This means that the run() method will be 
invoked on each filter object, and that the data will be buffered in 
between the filter: the output of the first filter is written to an array, 
which is used as the input of the 2nd filter, and so on. 

If set_input() was invoked on the chain, these arguments will be passed 
to the set_input() method of the first filter in the chain. 
If this is not the case, the input of the first filter must have been 
defined in some other way, or run() will fail during the processing
of the first filter.

If set_output() was invoked on the chain, these arguments will be passed 
to the set_output() method of the final filter in the chain. 
If this is not the case, the output of the final filter must have been 
defined in some other way, or run() will fail during the processing
of the final filter.

However, a fallback is provided for filters derived from the 
C<Text::Filter> class. If no output is specified for the final filter, 
and no chain output is given, the chain output will
default to an empty array before processing all filters. 
This array is accessible as the 1st element in the ref to array kept 
in the C<output> field of the chain.

=back

=head1 SEE ALSO

More info on text filters is found in L<Text::Filter>.

=head1 AUTHOR

Wim Verhaegen E<lt>wim.verhaegen@ieee.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2000 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute and/or 
modify it under the same terms as Perl itself.

=cut
