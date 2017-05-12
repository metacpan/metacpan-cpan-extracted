package Text::Annotated::Writer;
# $Id: Writer.pm,v 1.7 2007-05-12 18:39:16 wim Exp $
use strict;
use vars qw($VERSION);
use Text::Annotated::Line;
use Text::Filter;
use base qw(Text::Filter);
$VERSION = '0.04';

sub new {
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    my %arg = @_;

    # initialize the no_annotation flag
    my $no_annotation = $arg{no_annotation} || 0; # defaults to printing of the annotations
    delete $arg{no_annotation};

    # construct the filter
    my $this = $pkg->SUPER::new(input => [], %arg);
    bless $this, $pkg;

    # add the fields
    $this->{no_annotation} = $no_annotation;

    # return the filter
    return $this;
}

sub set_input { # overrides set_input in Text::Filter, adding a type check
    my ($this,$input,$postread) = @_;

    ref($input) eq 'ARRAY' or	
	die "Invalid input specified,\n"
	  . "Text::Annotated::Writer expects an array of Text::Annotated::Line objects,\n"
          . "stopped";

    $this->SUPER::set_input($input,$postread);
}

sub write {
    my Text::Annotated::Writer $this = shift;
    my $na = $this->{no_annotation};
    while(defined(my $line = $this->readline)) {
	$this->writeline($na 
	    ? "$line" # this will work both on annotated lines and ordinary strings
	    : $line->stringify_annotated
	);
    }
}

sub run { # needed when using the filter in a Text::Filter::Chain
    my $this = shift;
    $this->write(@_);
}

sub writer { # constructs and runs the filter
    my $proto = shift;
    my $this = $proto->new(@_);
    $this->write;
    return $this;
}

1;

__END__

=head1 NAME

Text::Annotated::Writer -- filter for writing Text::Annotated lines

=head1 SYNOPSIS

    use Text::Annotated::Writer;

    my $writer = new Text::Annotated::Writer(
         input  => $ra_annotated_lines, # ref to array with Text::Annotated objects
	 output => 'text.out', # output file
         no_annotation => 1,   # suppresses writing of the annotations
    );
    $writer->write(); # actually writes the lines to file

=head1 DESCRIPTION

Text::Annotated::Writer is a subclass of Text::Filter, with as purpose the dumping
of annotated lines to an array of ASCII lines or a file. The following issues are
specific to Text::Annotated::Writer:

=over 4

=item *

The list of allowed arguments to new() includes the C<no_annotation> flag. When set to a
true value, the annotation of the lines is suppressed in the output, and only the ASCII content
is shown. The default behaviour is to output the annotation with each line.

=item *

The write() method executes the output operation. run() is an alias for write().

=item *

The writer() method builds a Text::Annotated::Writer filter with the supplied arguments,
calls write() and finally returns the filter. It is thus possible to combine the whole
output operation in a single statement like

    Text::Annotated::Writer->writer(
	input  => $ra_annotated_lines,
        output => 'text.out',
        no_annotation => 1,
    );

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
