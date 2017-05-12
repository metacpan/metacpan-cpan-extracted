package Text::Flowchart::Script;

use 5.006;
use strict;
our $VERSION = '0.02';

use Text::Flowchart::Script::Lexer;
use Text::Flowchart::Script::Parser;

sub new {
    bless {}, $_[0];
}

sub parse {
    $_[0]->{src} = $_[1];
    Feed $_[0]->{src};
    my $parser = Text::Flowchart::Script::Parser->new();
    $_[0]->{parsed} = $parser->YYParse(yylex => \&Lexer);
}

sub render {
    my $output;
    eval $_[0]->{parsed};
    die "Rendering error $@\n" if $@;
    $output;
}

sub debug { $_[0]->{parsed}."\n" }

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Text::Flowchart::Script - A simple language for Text::Flowchart

=head1 SYNOPSIS

  use Text::Flowchart::Script;
  my $p = Text::Flowchart::Script->new();

  # Parse the program
  $p->parse($program);

  # Draw the chart
  print $p->render;

  # Tokenize the source code
  print $p->tokenize;

  # Print translated code
  print $p->debug;

=head1 DESCRIPTION

L<Text::Flowchart> is a tool for generating flowcharts in ASCII style. However, users have to process some repeated things themselves, such as variable declaration, parentheses. As to this point, L<Text::Flowchart::Script> defines a simple language for users to create text flowcharts much easier.

Now, let's get down to the language. See an example.

Initialize a flowchart.

        init : width => 50, directed => 0;

Let 'begin' be a box.

        begin = box :
                string  => "ALPHA",
                x_coord => 0,
                y_coord => 0,
                width   => 9,
                y_pad   => 0
        ;


Let 'end' be another box.

        end = box :
                string => "OMEGA",
                x_coord => 15,
                y_coord => 0
        ;


Draw a line from 'begin' to 'end'

        relate
              : begin bottom
              : end top
        ;

For details of the functions and parameters, see L<Text::Flowchart>

=head1 NOTES

=over 5

=item * Variables do not come with the dollar sign ($).

=item * Users can treat an initialized variable as a function for modification of variable's attributes

=item * Users can insert comments quoted by /* and */

=item * Arguments are grouped by ':'

=item * Every statement should be ended with a semicolon.

=back



=head1 SEE ALSO

L<Text::Flowchart>

=head1 CAVEATS

This is an experimental design. Use it at your own risk.

=head1 TO DO

Error handling

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
