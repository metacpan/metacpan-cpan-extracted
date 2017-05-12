
package Text::Flow;
use Moose;

use Text::Flow::Wrap;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

has 'check_height' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

has 'wrapper' => (
    is       => 'rw',
    isa      => 'Text::Flow::Wrap',
    required => 1,
);

sub flow {
    my ($self, $text) = @_;
    
    my $paragraphs = $self->wrapper->disassemble_paragraphs($text);
    
    my @sections = ([]);
    foreach my $paragraph (@$paragraphs) {
        push @{$sections[-1]} => [];
        foreach my $line (@$paragraph) {
            unless ($self->check_height->($sections[-1])) {
                push @sections => [[]];                
            }            
            push @{$sections[-1]->[-1]} => $line;                
        }        
    }
    
    #use Data::Dumper;
    #warn Dumper \@sections;
    
    return map {
        chomp; $_;
    } map { 
        $self->wrapper->reassemble_paragraphs($_);
    } @sections;
}

no Moose;

1;

__END__

=pod

=head1 NAME

Text::Flow - Flexible text flowing and word wrapping for not just ASCII output.

=head1 SYNOPSIS
  
  use Text::Flow;
  
  # use it on ASCII text ...
  my $flow = Text::Flow->new(
      check_height => sub { 
          my $paras = shift; 
          sum(map { scalar @$_ } @$paras) <= 10;
      },
      wrapper => Text::Flow::Wrap->new(
          check_width  => sub { length($_[0]) < 70 }
      ),
  );
  
  my @sections = $flow->flow($text);
  
  # @sections will now be an array of strings, each string 
  # will contain no more than 10 lines of text each of which 
  # will be no longer then 70 characters long
  
  # or use it on text in a PDF file ...
  my $flow = Text::Flow->new(
      check_height => sub { 
          my $paras = shift; 
          (sum(map { scalar @$_ } @$paras) * $pdf->get_font_height) < 200;
      },        
      wrapper => Text::Flow::Wrap->new(
          check_width => sub {
              my $string = shift;
              $pdf->get_string_width($string) < 100
          },
      )
  );
  
  my @sections = $flow->flow($text);
  
  # @sections will now be an array of strings, each string 
  # will contain text which will fit within 200 pts and 
  # each line will be no longer then 100 pts wide

=head1 DESCRIPTION

This module provides a flexible way to wrap and flow text for both 
ASCII and non-ASCII outputs. 

=head2 Another Text Wrap module!!?!?!

The main purpose of this module is to provide text wrapping and flowing 
features without being tied down to ASCII based output and fixed-width 
fonts. My needs were for a more sophisticated text control in PDF and GIF 
output formats in particular.  

=head1 METHODS

=over 4

=item B<new (%params)>

This constructs the new Text::Flow instance, and accepts parameters for 
the C<wrapper> and C<check_height> variables.

=item B<wrapper (?$wrapper)>

This is the accessor for the internally help Text::Flow::Wrapper instance 
which is used by Text::Flow to wrap the individual lines.

=item B<check_height>

This is the accessor for the CODE ref which is used to check the height 
of the current paragraph. It gets as an argument, an array-ref of paragraphs, 
each of which is also an array-ref of text lines. The most common usage 
is shown in the SYNOPSIS above, but you can really do anything you want 
with them. It is expected to return a Boolean value, true if the height is 
still okay, and false if the max height has been reached.

=item B<flow ($text)>

This method preforms the text flowing. It returns an array of strings which 
can be treated as complete blocks of text. It will handle paragraph breaks
and line breaks for you.

=back

=head2 Introspection

=over 4 

=item B<meta>

Returns the Moose meta object associated with this class.

=back

=head1 TODO

I wanted to write some tests for using this with GD modules as well. I suppose 
we will have to wait until 0.02 for that.

=head1 SIMILAR MODULES

There are a bunch of other text wrapping and flowing modules out there, but 
they are all meant for use in ASCII outout only. This just didn't work for 
my needs, so I wrote this one. If you need to wrap ASCII text and want to 
do it in a much simpler manner then this module provides, then I suggest
checking out those modules. This module is specifically made for when those 
other modules are no longer powerful and flexible enough.

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


