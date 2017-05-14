package Text::Spintax;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Text::Spintax::grammar;
use Text::Spintax::RenderNode;
use Parse::Lex;

=head1 NAME

Text::Spintax - A parser and renderer for spintax formatted text.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

    use Text::Spintax;

    my $node = Text::Spintax->new->parse("This {is|was|will be} some {varied|random} text");
    $node->equal_path_weight;
    my $text = $node->render;

=head1 DESCRIPTION

Text::Spintax implements a parser and renderer for spintax formatted text.  Spintax is a commonly used method for
generating "randomized" text.  For example,

    This {is|was} a test

would be rendered as

    * This is a test
    * This was a test

Spintax can be nested indefinitely, for example:

    This is nested {{very|quite} deeply|deep}.

would be rendered as

    * This is nested very deeply.
    * This is nested quite deeply.
    * This is nested deep.

The number of possible combinations is easy to calculate, but the proportion of renders has two options.  The initial Text::Spintax::RenderNode has weight 1 for all nodes, meaning that for the previous example the probabilities of each render would be

    25% This is nested very deeply.
    25% This is nested quite deeply.
    50% This is nested deep.

If you want every possible outcome to be equally likely, then call equal_path_weight on the Text::Spintax::RenderNode object and you'll get this outcome:

    33% This is nested very deeply.
    33% This is nested quite deeply.
    33% This is nested deep.

=cut

sub root { scalar @_ == 2 and $_[0]->{root} = $_[1]; return $_[0]->{root} }
sub curr { scalar @_ == 2 and $_[0]->{curr} = $_[1]; return $_[0]->{curr} }

=head1 SUBROUTINES/METHODS

=head2 new

   Returns a Text::Spintax object

=cut

sub new {
   my $class = shift;
   my $self = bless {}, $class;
   return $self;
}

=head2 parse

   Parses the spintax and returns a Text::Spintax::Node that is suitable for rendering.  Returns undef if the spintax couldn't be parsed.

=cut

our $lexer;

sub parse {
   my $self = shift;
   my ($text) = @_;
   my @lex = qw(
      OBRACE          {
      EBRACE          }
      PIPE            \|
      TEXT            [^{}|]+
   );
   if (not defined $lexer) {
      $lexer = Parse::Lex->new(@lex);
      $lexer->skip('');
   }
   $lexer->from($text);

   my $parser = new Text::Spintax::grammar();
   $parser->YYData->{lexer} = $lexer;
   my $root = Text::Spintax::RenderNode->new(type => "sequence", weight => 1);
   $self->root($root);
   $self->curr($root);

   $parser->YYData->{tree} = $self;
   eval {
      my $value = $parser->YYParse(yylex => \&lexer, yyerror =>\&error);
   };
   if ($@) {
      return undef;
   }
   return $root;
}

sub last_child {
   my $self = shift;
   return $self->curr->{children}[-1];
}

sub obrace {
   my $self = shift;
   my $child = Text::Spintax::RenderNode->new(parent => $self->curr, weight => 1);
   push @{$self->curr->{children}}, $child;
   $self->curr($child);
}

sub ebrace {
   my $self = shift;
   my @groups = ([]);
   foreach my $child (@{$self->curr->children}) {
      if ($child->type eq "pipe") {
         push @groups, [];
      }
      else {
         push @{$groups[-1]}, $child;
      }
   }
   my @children;
   foreach my $group (@groups) {
      if (scalar @$group == 1) {
         push @children, $group->[0];
      }
      else {
         push @children, Text::Spintax::RenderNode->new(parent => $self->curr, children => $group, type => "sequence", weight => 1);
      }
   }
   $self->curr->children(\@children);
   $self->curr($self->curr->parent);
}
sub add_child {
   my $self = shift;
   my ($type,$text,$offset) = @_;
   my $child = Text::Spintax::RenderNode->new(parent => $self->curr, type => $type, text => $text, offset => $offset, weight => 1);
   push @{$self->curr->{children}}, $child;
}

sub type {
   my $self = shift;
   my ($type) = @_;
   $self->curr->{type} = $type;
}

sub lexer {
   my $parser = shift;
   my $lexer = $parser->YYData->{lexer};
   my $token = $parser->YYData->{lexer}->next;
   if (not defined $token) {
      return ('', undef);
   }
   else {
      $parser->YYData->{DATA} = [$token->name, $token->text, $lexer->offset];
   }
   return ('', undef) if $lexer->eoi;
   return ($token->name, $token->text);
}

sub error {
   die "error parsing spintax\n";
}

=head1 AUTHOR

Dale Evans, C<< <daleevans@github> >> http://devans.mycanadapayday.com

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-spintax at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Spintax>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Spintax


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Spintax>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Spintax>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Spintax>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Spintax/>

=back


=head1 ACKNOWLEDGEMENTS

Francois Desarmenien <francois@fdesar.net> for writing Parse::YAPP
Philippe Verdret for writing Parse::Lex

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dale Evans.

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

The Parse::Yapp module and its related modules and shell scripts are copyright (c) 1998-2001 Francois Desarmenien, France. All rights reserved.

You may use and distribute them under the terms of either the GNU General Public License or the Artistic License, as specified in the Perl README file.

=cut

1; # End of Text::Spintax
