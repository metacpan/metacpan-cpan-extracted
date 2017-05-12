package Text::Tokenize::Indented;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Iterator::Simple;
use Iterator::Simple::Lookahead;
use Data::Dumper;
use Carp;

=head1 NAME

Text::Tokenize::Indented - tokenize indented lines in text

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

As part of the Decl language project (the windmill I've been tilting at since 2010), I end up working with
text a lot that is structured by indentation. Finally, I think, this module provides a solid underpinning
to working with that kind of text, in that it provides as convenient a tokenizer as possible.

It's based on L<Iterator::Simple::Lookahead>, meaning that it (1) does a lazy tokenization of a list passed
into it, and (2) provides a peek and unget so that you can easily chain tokenizers; if a given piece that has
already been identified turns out to break into multiple tokens, you simply tokenize it and push the subpieces
back into the stream for later retrieval as individual tokens.

This allows very nice compartmentalization of the details of parsing, leaving you a lot less to debug when
parsing more difficult items.

You use it like this:

   use Text::Tokenize::Indented;
   
   my $tok = Text::Tokenize::Indented ({tab => 4}, <<EOF, {tab => 8}, $trailing_iterator)
   text
   text
      text
      text
   
   text
   EOF
   
(For instance.) This then returns the following token stream:

   [0, 'text']
   [0, 'text']
   [3, 'text']
   [3, 'text']
   [-1]
   [0, 'text']
   (whatever the trailing iterator returns)
   
We might then chain another tokenizer onto this one which would tokenize the individual lines into more meaningful things.
Note that blank lines officially have an indentation of -1.

=head1 METHODS

=head2 new

Creates a new tokenizer, with or without input. Any parameters are passed to C<input>.
The defaults for parameters are as follows: tabs=4 (tabs are 4 spaces), blank, newline.
Any parameter can be changed mid-stream by sending a hashref into the input.

Returns an Iterator::Simple::Lookahead iterator that returns items from the input queue.

=cut

sub new {
    my $class = shift;
    my $self = bless {
        tabs => 4,
        blank => qr/\s+/,
        newline => qr/\n/,
        queue => [],
    }, $class;
    $self->input(@_) if @_;
    $self->{iterator} = Iterator::Simple::Lookahead->new (
      sub {
          NEXT:
          # End of input if the queue is empty.
          return undef unless @{$self->{queue}};
          my $next = $self->{queue}->[0];
          
          # Take care of parameter updates if the next thing is a hashref, start over.
          if (ref $next eq 'HASH') {
              foreach my $key (keys(%$next)) {
                  $self->{$key} = $next->{$key};
              }
              shift @{$self->{queue}};
              goto NEXT;
          }
          
          # Get the next value in the queue.
          NEXTVAL:
          my $nextval = $next->();
          
          # If the currently next iterator is finished, go to the next thing on the queue.
          if (not defined $nextval) {
              shift @{$self->{queue}};
              goto NEXT;
          }
          
          # If the next value itself is a hashref, we'll still get parameters out of it.
          if (ref ($nextval) eq 'HASH') {
              foreach my $key (keys(%$nextval)) {
                  $self->{$key} = $next->{$key};
              }
              goto NEXTVAL;
          }
          
          # Return the value if it's an arrayref, as we have somehow presumably already
          # tokenized it in an upstream tokenizer of some sort.
          return $nextval if ref($nextval);
          
          # Oh! A string!
          if ($nextval =~ /^(\s+)(.*)/) {
              my ($white, $meat) = ($1, $2);
              return [-1] unless $meat;
              $white =~ s/\t/' ' x $self->{tabs}/ge;
              return [length($white), $meat];
          }
          return [0, $nextval];
      });
    #print STDERR Dumper($self);
    $self;
}

=head2 tokenize (@input)

Creates a tokenizer with input, but instead of returning the object, returns only
the iterator. No new input can be added to this tokenizer, but normally you don't
care.

=cut

sub tokenize {
    my $t = new(@_);
    $t->{iterator};
}

=head2 input

Input is where text is loaded up into the tokenizer. It takes a list of items, each of which can be
either a hashref, which will be used to set values in the tokenizer that apply to coming data,
a string, which will be split into lines, or an iterable object, which will be passed through
to the tokenizer output.

Returns the iterator for the object.

=cut

sub input {
    my $self = shift;
    foreach my $load (@_) {
        if (ref $load eq '') { # String input.
           my @lines = split /\n/, $load;
           push @{$self->{queue}}, Iterator::Simple::iter(\@lines);
        } elsif (ref $load eq 'HASH') { # Parameters.
           push @{$self->{queue}}, $load;
        } else {
           croak "Non-iterable input supplied" unless Iterator::Simple::is_iterable($load);
           push @{$self->{queue}}, Iterator::Simple::iter($load);
        }
    }
    $self->{iterator};
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-tokenize-indented at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Tokenize-Indented>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Tokenize::Indented


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Tokenize-Indented>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Tokenize-Indented>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Tokenize-Indented>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Tokenize-Indented/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Text::Tokenize::Indented
