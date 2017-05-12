package Text::Annotated::Reader;
# $Id: Reader.pm,v 1.7 2007-05-12 18:39:16 wim Exp $
use strict;
use vars qw($VERSION);
use Text::Filter;
use Text::Annotated::Line;
use base qw(Text::Filter);
$VERSION = '0.04';

sub new {
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    my $this = $pkg->SUPER::new(output => [], @_);
    bless $this, $pkg;
}

sub set_input { # overrides set_input of Text::Filter, adds a type check
    my ($this,$input,$postread) = @_;
    
    # the input needs to be specified as a filename
    !ref($input) or 
	die "Invalid input specified.\n"
          . "Text::Annotated::Reader expects a filename,\n"
	  . "stopped";
    
    $this->SUPER::set_input($input,$postread);
}

sub set_output { # overrides set_output of Text::Filter, adds some magic
    my ($this,$output,$prewrite) = @_;

    # the output needs to be a ref to an array
    ref($output) eq 'ARRAY' or 
	die "Invalid output. Text::Annotated::Writer expects a ref to an array,\n"
          . "stopped";

    # construct a magic handler which actually annotates the lines
    my $linenr = 1; # index of first line
    my $magic_handler = sub {
	my $line = new Text::Annotated::Line(
            filename => $this->{input},
            linenr   => $linenr++,
	    content  => $_[0],
        );
	push @$output, $line;
    };

    # keep the array in a separate field
    $this->{annotated_lines} = $output;

    $this->SUPER::set_output($magic_handler,$prewrite);
}

sub read { # reads and annotates an entire file
    my Text::Annotated::Reader $this = shift;

    # autogenerate an output array if no output is specified
    $this->set_output([]) unless defined $this->{annotated_lines};

    # copy the lines from input to output, letting the output handler
    # do the annotation
    while(defined(my $line = $this->readline())) {
	$this->writeline($line);
    }
}

sub run { # needed when using the filter in a Text::Filter::Chain
    my $this = shift;
    $this->read(@_);
    return wantarray ? @{$this->{annotated_lines}} : $this->{annotated_lines};
}

sub reader { # constructs and runs a filter
    my $proto = shift;
    my $this = $proto->new(@_);
    $this->read;
    return $this;
}

1;

__END__

=head1 NAME

Text::Annotated::Reader - a filter for annotating lines coming from a file

=head1 SYNOPSIS

    use Text::Annotated::Reader;

    my $reader = new Text::Annotated::Reader(input => 'text.in');
    $reader->read();
    $ra_annotated_lines = $reader->{annotated_lines};

=head1 DESCRIPTION

Text::Annotated::Reader is a subclass of Text::Filter, with as purpose the
reading of lines from a file, and annotating the filename and linenumber
for each line. The following issues are specific to Text::Annotated::Reader:

=over 4

=item *

The set_input() method only accepts filenames as a valid input argument. 
This requirement is also imposed on the C<input> argument passed to new(),
as new() invokes set_input().

=item *

The read() method executes the input operation. run() is an alias for read().

=item *

The reader() method builds a Text::Annotated::Reader filter with the supplied arguments,
calls read() and finally returns the filter. It is thus possible to combine the whole
input operation in a single statement like

    my $ra_annotated_lines = 
      Text::Annotated::Reader->reader(input => 'text.in')->{annotated_lines};

=back

=head1 SEE ALSO

More info on using filters is available from L<Text::Filter>.

L<Text::Annotated::Line> describes annotated lines.

=head1 CVS VERSION

This is CVS version $Revision: 1.7 $, last updated at $Date: 2007-05-12 18:39:16 $.

=head1 AUTHOR

Wim Verhaegen E<lt>wim.verhaegen@ieee.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2000-2002 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute and/or 
modify it under the same terms as Perl itself.

=cut
