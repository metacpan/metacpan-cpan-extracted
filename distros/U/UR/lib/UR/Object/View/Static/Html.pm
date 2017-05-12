package UR::Object::View::Static::Html;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

class UR::Object::View::Static::Html {
    is => 'UR::Object::View',
    has => {
        output_format => { value => 'html' },
        html_root     => { doc => 'path to plain-old html files' }
    },
    has_constant => [
        perspective => { value => 'static' },
        toolkit => { value => 'html' },
    ],
};

sub content {

    my ($self) = @_;

    my $filename = class_to_filename($self->subject->class);
    my $perspective = $self->perspective() || die "Error: I have no perspective";

    my $pathname = join('/', $self->html_root(), $perspective, $filename);

    open(my $fh, $pathname); if (!$fh) { die "Could not open the static html file: $pathname"; }
    my $c =  do
    {   undef $/;
        <$fh>;
    };
    close($pathname);

    return $c;
}

sub class_to_filename {
    my ($class) = @_;
    $class = lc($class);
    $class =~ s/::/_/g;
    $class .= '.html';
    return $class;
}



1;

=pod

=head1 NAME

UR::Object::View::Static::Html - represent object state in HTML format 

=head1 SYNOPSIS

package Genome::Sample::Set::View::Detail::Html;

class Genome::Sample::Set::View::Detail::Html {
    is => 'UR::Object::View::Static::Html',
    has_constant => [
        toolkit     => { value => 'html' },
        perspective => { value => 'detail' }
    ]
};


=head1 DESCRIPTION

The current default HTML class creates HTML by getting XML and applying XSL.
This class, on the other hand, displays some static html

=head1 SEE ALSO

UR::Object::View::Default::Html, UR::Object::View::Default::Text, UR::Object::View, UR::Object::View::Toolkit::XML, UR::Object::View::Toolkit::Text, UR::Object

=cut

