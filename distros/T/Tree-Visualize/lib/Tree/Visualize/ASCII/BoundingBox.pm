
package Tree::Visualize::ASCII::BoundingBox;

use strict;
use warnings;

use Tree::Visualize::Exceptions;

our $VERSION = '0.01';

## constructor

sub new {
    my ($_class, $string) = @_;
    my $class = ref($_class) || $_class;
    my $box = {
        string => [ split(/\n/, $string) ]
        };
    bless($box, $class);
    return $box;
}

## accessors

sub height {
    my ($self) = @_;
    scalar @{$self->{string}};    
}

sub width {
    my ($self) = @_;
    defined($self->{string}->[0]) || return 0;
    length($self->{string}->[0]);
}

sub getLinesAsArray {
    my ($self) = @_;
    return @{$self->{string}};
}

sub getAsString {
    my ($self) = @_;
    join "\n" => @{$self->{string}};
}

sub getFirstConnectionPointIndex {
    my ($self) = @_;
    my ($space, $top_line_of_box) = ($self->{string}->[0] =~ /(\s*)(\S*)/);
    return length($space) + int(length($top_line_of_box) / 2);    
}

## mutators

sub flipVertical {
    my ($self) = @_;
    $self->{string} = [ reverse(@{$self->{string}}) ];
    $self;
}

sub flipHorizontal {
    my ($self) = @_;
    $self->{string} = [ map { join "" => reverse(split // => $_) } @{$self->{string}} ];
    $self;
}

sub padLeft {
    my ($self, $padding) = @_;
    ($padding =~ /^\s*$/) 
        || throw Tree::Visualize::InsufficientArguments "padding can not contain newlines and only be spaces ($padding)";
    $self->{string} = [ map { ($padding . $_) } @{$self->{string}} ];
    $self;
}

sub padRight {
    my ($self, $padding) = @_;
    ($padding =~ /^\s*$/) 
        || throw Tree::Visualize::InsufficientArguments "padding can not contain newlines and only be spaces ($padding)";
    $self->{string} = [ map { ($_ . $padding) } @{$self->{string}} ];
    $self;    
}

sub pasteRight {
    my ($self, $right) = @_;
    (defined($right) && ref($right) && UNIVERSAL::isa($right, "Tree::Visualize::ASCII::BoundingBox")) 
        || throw Tree::Visualize::InsufficientArguments "right argument must be a Tree::Visualize::ASCII::BoundingBox ($right)";
    # split the left
    my @left = $self->getLinesAsArray();
    # and the right
    my @right = $right->getLinesAsArray();
    
    # figure out which has the most lines
    my $num_lines = ($self->height() < $right->height()) ? $right->height() : $self->height();
    
    # get the widths of the first item in the list
    my $first_left_width = $self->width();
    my $first_right_width = $right->width();
    
    my @new_string;
    foreach my $line_num (0 .. $num_lines - 1) { 
        push @new_string => (
            _normalizeLine($left[$line_num], $first_left_width) . 
            _normalizeLine($right[$line_num], $first_right_width)
            );             
    }   
    # and now paste it into the new string
    $self->{string} = \@new_string;
    $self;
}

sub pasteLeft {
    my ($self, $left) = @_;
    (defined($left) && ref($left) && UNIVERSAL::isa($left, "Tree::Visualize::ASCII::BoundingBox")) 
        || throw Tree::Visualize::InsufficientArguments "left argument must be a Tree::Visualize::ASCII::BoundingBox ($left)";
    # split the left
    my @left = $left->getLinesAsArray();
    # and the right
    my @right = $self->getLinesAsArray();
    
    # figure out which has the most lines
    my $num_lines = ($self->height() < $left->height()) ? $left->height() : $self->height();
    
    # get the widths of the first item in the list
    my $first_left_width = $left->width();
    my $first_right_width = $self->width();
    
    my @new_string;
    foreach my $line_num (0 .. $num_lines - 1) { 
        push @new_string => (
            _normalizeLine($left[$line_num], $first_left_width) . 
            _normalizeLine($right[$line_num], $first_right_width)
            );             
    }   
    # and now paste it into the new string
    $self->{string} = \@new_string;
    $self;
}

sub pasteTop {
    my ($self, $top) = @_;
    (defined($top) && ref($top) && UNIVERSAL::isa($top, "Tree::Visualize::ASCII::BoundingBox")) 
        || throw Tree::Visualize::InsufficientArguments "top argument must be a Tree::Visualize::ASCII::BoundingBox ($top)";
    if ($top->width() < $self->width()) {
        unshift @{$self->{string}} => map { _normalizeLine($_, $self->width()) } $top->getLinesAsArray();
    }
    else {
        $self->{string} = [ $top->getLinesAsArray(), map { _normalizeLine($_, $top->width()) } @{$self->{string}} ];
    }
    $self;
}

sub pasteBottom {
    my ($self, $bottom) = @_;
    (defined($bottom) && ref($bottom) && UNIVERSAL::isa($bottom, "Tree::Visualize::ASCII::BoundingBox")) 
        || throw Tree::Visualize::InsufficientArguments "bottom argument must be a Tree::Visualize::ASCII::BoundingBox ($bottom)";
    if ($bottom->width() < $self->width()) {
        push @{$self->{string}} => map { _normalizeLine($_, $self->width()) } $bottom->getLinesAsArray();
    }
    else {
        $self->{string} = [ map { _normalizeLine($_, $bottom->width()) } @{$self->{string}}, $bottom->getLinesAsArray() ];
    }
    $self;
}

## private helper functions

sub _normalizeLine {
    my ($line, $width) = @_;
    unless ($line) {
        $line = (" " x $width);
    }
    elsif ($width > length($line)) {
        $line = $line . (" " x ($width - length($line)));
    }
    elsif ($width < length($line)) {
        # strip any trailing spaces that are larger
        # then the width of the first line of the 
        # left node
        chop($line) while ($line =~ /\s$/o && $width < length($line));
    }
    return $line;
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::BoundingBox - A bounding box for ASCII drawings

=head1 SYNOPSIS

    use Tree::Visualize::ASCII::BoundingBox;
    
    my $box = Tree::Visualize::ASCII::BoundingBox->new(join "\n" => (
                    '+------+',
                    '| test |',
                    '+------+'
                    ));  
                    
    my $box2 = Tree::Visualize::ASCII::BoundingBox->new(join "\n" => (
                    '+-------+',
                    '| test2 |',
                    '+-------+'
                    ));   
                    
    my $box3 = $box->padRight("  ")->pasteRight($box2);    
    
    print $box3->getAsString();
    
    # will give you:
    # +------+  +-------+
    # | test |  | test2 |
    # +------+  +-------+                                       

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ($string)>

=back

=head2 Accessors

=over 4

=item B<height>

Returns the height of the bounding box.

=item B<width>

Returns the width of the bounding box.

=item B<getLinesAsArray>

Returns an array of string representing each line of the drawing.

=item B<getAsString>

Returns the completed drawing as a single string.

=item B<getFirstConnectionPointIndex>

NOTE: This method is used for particular purpose and will likely be changed.

=back

=head2 Mutators

=over 4

=item B<padLeft ($padding)>

Given a C<$padding> of spaces, this will add it to the left side of the bounding box.

=item B<padRight ($padding)>

Given a C<$padding> of spaces, this will add it to the right side of the bounding box.

=item B<pasteLeft ($right)>

Given another BoundingBox object (C<$right>) this will paste it onto the left of the current bounding box.

=item B<pasteRight ($left)>

Given another BoundingBox object (C<$left>) this will paste it onto the right of the current bounding box.

=item B<pasteTop ($top)>

Given another BoundingBox object (C<$top>) this will paste it onto the top of the current bounding box.

=item B<pasteBottom ($bottom)>

Given another BoundingBox object (C<$bottom>) this will paste it onto the bottom of the current bounding box.

=item B<flipHorizontal>

This will flip the bounding box horizontally.

=item B<flipVertical>

This will flip the bounding box vertically.

=back

=head1 TO DO

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
