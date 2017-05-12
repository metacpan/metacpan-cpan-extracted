
package Text::Flow::Wrap;
use Moose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'check_width' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has 'word_boundry'      => (is => 'rw', isa => 'Str', default => " ");
has 'paragraph_boundry' => (is => 'rw', isa => 'Str', default => "\n");

has 'word_break'        => (is => 'rw', isa => 'Str', default => " ");
has 'line_break'        => (is => 'rw', isa => 'Str', default => "\n");
has 'paragraph_break'   => (is => 'rw', isa => 'Str', default => "\n\n");

sub wrap {
    my ($self, $text) = @_;
    $self->reassemble_paragraphs(
        $self->disassemble_paragraphs($text)
    );
}

sub reassemble_paragraphs {
    my ($self, $paragraphs) = @_;
    join $self->paragraph_break => map { 
        $self->reassemble_paragraph($_) 
    } @$paragraphs;
}

sub reassemble_paragraph {
    my ($self, $paragraph) = @_;
    join $self->line_break => @$paragraph;
}

sub disassemble_paragraphs {
    my ($self, $text) = @_;
    
    my @paragraphs = split $self->paragraph_boundry => $text;
    
    my @output; 
    foreach my $paragraph (@paragraphs) { 
        push @output => $self->disassemble_paragraph($paragraph); 
    }
    
    return \@output;
}

sub disassemble_paragraph {
    my ($self, $text) = @_;
    
    my @output = ('');
    
    my @words = split $self->word_boundry => $text;
    
    my $work_break = $self->word_break;    
    
    foreach my $word (@words) {
        my $padded_word = ($word . $work_break);
        my $canidate    = ($output[-1] . $padded_word);
        if ($self->check_width->($canidate)) {
            $output[-1] = $canidate;
        }
        else {
            push @output => ($padded_word);
        }
    }
    
    # NOTE:
    # remove that final word break character
    chop $output[-1] if substr($output[-1], -1, 1) eq $work_break;
    
    return \@output;    
}

no Moose;

1;

__END__

=pod

=head1 NAME

Text::Flow::Wrap - Flexible word wrapping for not just ASCII output.

=head1 SYNOPSIS

  use Text::Flow::Wrap;
  
  # for regular ASCII usage ...
  my $wrapper = Text::Flow::Wrap->new(
      check_width => sub { length($_[0]) < 70 },
  );
  
  # for non-ASCII usage ...
  my $wrapper = Text::Flow::Wrap->new(
      check_width => sub { $pdf->get_text_width($_[0]) < 500 },
  );
  
  my $text = $wrapper->wrap($text);  

=head1 DESCRIPTION

The main purpose of this module is to provide text wrapping features 
without being tied down to ASCII based output and fixed-width fonts.

My needs were for sophisticated test control in PDF and GIF output 
formats in particular. 

=head1 METHODS

=over 4

=item B<new (%params)>

This constructs a new Text::Flow::Wrap module whose C<%params> set the 
values of the attributes listed below.

=item B<wrap ($text)>

This method will accept a bunch of text, it will then return a new string 
which is wrapped to the expected width.

=back

=head2 Attribute Accessors

=over 4

=item B<check_width (\&code)>

This attribute is required, and must be a CODE reference. This will be 
used to determine if the width of the text is appropriate. It will get 
as an argument, a string which is should check the width of. It should 
return a Boolean value, true if the string is not exceeded the max width
and false if it has.

=item B<line_break ($str)>

This is the line break character used when assembling and disassembling 
the text, it defaults to the newline character C<\n>.

=item B<paragraph_boundry ($str)>

This is the paragraph boundry marker used when disassembling the text, 
it defaults to the string C<\n>.

=item B<paragraph_break ($str)>

This is the paragraph breaker used when re-assembling the text, it defaults 
to the string C<\n\n>.

=item B<word_boundry ($str)>

This is the word boundry marker used when disassembling the text, 
it defaults to a single space character.

=item B<word_break ($str)>

This is the paragraph breaker used when re-assembling the text, it defaults 
to a single space character.

=back

=head2 Paragraph Disassembling

These methods deal with breaking up the paragraphs into its parts, which 
can then be processed through the re-assembling methods.

These methods are mostly used internally, but more sophisticated tools 
might need to access them as well (see Text::Flow).

=over 4

=item B<disassemble_paragraph>

=item B<disassemble_paragraphs>

=back

=head2 Paragraph Reassembling

These methods deal with putting the paragraph parts back together after the 
disassembling methods have done thier work.

These methods are mostly used internally, but more sophisticated tools 
might need to access them as well (see Text::Flow)

=over 4

=item B<reassemble_paragraph>

=item B<reassemble_paragraphs>

=back

=head2 Introspection

=over 4 

=item B<meta>

Returns the Moose meta object associated with this class.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


