package Text::Annotated::Line;
# $Id: Line.pm,v 1.6 2007-05-12 18:39:16 wim Exp $
use strict;
use vars qw($VERSION);
use fields qw(filename linenr content);
use overload (
    "\"\"" => \&stringify
);
$VERSION = '0.04';

sub new {
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    
    # build the object
    no strict 'refs';
    my $this = bless [\%{"${pkg}::FIELDS"}], $pkg;

    # initialize any specified fields
    my %arg = @_;
    while(my($k,$v) = each %arg) {
	$this->{$k} = $v;
    }

    return $this;
}

sub clone { # returns a deep copy
    my $this = shift;
    return $this->new(
	 filename => $this->{filename},
         linenr   => $this->{linenr},
         content  => $this->{content},
    );
}

sub stringify {
    my Text::Annotated::Line $this = shift;
    $this->{content};
}

sub stringify_annotated {
    my Text::Annotated::Line $this = shift;
    my $file    = $this->{filename};
    my $linenr  = sprintf('%05d',$this->{linenr});
    my $content = $this->{content};
    chomp $content;
    return "[$file\#$linenr]$content";
}

1;

__END__

=head1 NAME

Text::Annotated::Line - strings with annotation about their origin

=head1 SYNOPSIS

    use Text::Annotated::Line;
   
    # construct a line
    $line = new Text::Annotated::Line(
         filename => 'foo', 
         linenr   => 23,
         content  => 'This is the line content',
    );

    # print the line, with annotation
    print $line->stringify_annotated, "\n";

    # print the line without annotation
    print $line, "\n";

=head1 DESCRIPTION

=head2 FIELDS

All of the following fields must be set through the constructor new():

=over 4

=item filename

name of the file the string originates from

=item linenr

number of the line in the file the string is located

=item content

the actual content of the string

=back

=head2 METHODS

=over 4

=item new()

Constructs a new Text::Annotated::Line object. Fields can be set by
passing them as a hash to new().

=item stringify()

Returns the line without annotations. This method is used for overloading,
so you implicitly call it in any circumstance where you use a 
Text::Annotated::Line object where a string is expected.

=item stringify_annotated()

Returns a string with the content AND the annotation if the format
C<[filename#linenr]content>. Trailing newlines in the content are omitted.

=back

=head1 SEE ALSO

Filters for handling annotated lines are described in 
L<Text::Annotated::Reader> and L<Text::Annotated::Writer>.

=head1 CVS VERSION

This is CVS version $Revision: 1.6 $, last updated at $Date: 2007-05-12 18:39:16 $.

=head1 AUTHOR

Wim Verhaegen E<lt>wim.verhaegen@ieee.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2000-2002 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute and/or 
modify it under the same terms as Perl itself.

=cut
