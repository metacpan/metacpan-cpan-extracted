package Text::Amuse::Compile::FileName;

use strict;
use warnings;
use File::Basename ();

=head1 NAME

Text::Amuse::Compile::FileName - Parser for filenames passed to the compiler.

=head1 METHODS

=head2 new($filename)

The constructor only accept a filename. It can have the form:

 my-filename:0,2,3
 my-filename
 /path/to/filename.muse
 ../path/to/filename.muse
 ../path/to/filename.muse:1,4,5

I.e., relative or absolute paths with extensions, or bare filenames
without extension, with an optional range of fragments (for partial
output).

=head1 METHODS

=head2 path

=head2 name

=head2 suffix

=head2 filename

=head2 full_path

=head2 fragments

=head2 fragments_specification

=head2 name_with_ext_and_fragments

=head2 name_with_fragments

=head2 text_amuse_constructor

=cut

sub new {
    my ($class, $filename) = @_;
    die "Missing filename" unless defined $filename;
    my $fragment_definition = qr/(?: [0-9] | [1-9][0-9]+ | pre | post )/x;
    my $fragment = qr/\: $fragment_definition
                      (?: , $fragment_definition )*
                     /x;
    my $ext = qr{\.muse};
    my @fragments;
    if ($filename =~ m/($ext)?($fragment)\z/) {
        my $fragment_path = $2;
        $filename =~ s/$fragment\z//;
        $fragment_path =~ s/\A\://;
        @fragments = split(/,/, $fragment_path);
    }
    my ($name, $path, $suffix) = File::Basename::fileparse($filename, $ext);
    my $self = {
                name => $name,
                path => $path,
                suffix => '.muse',
                fragments => (scalar(@fragments) ? \@fragments : undef),
               };
    bless $self, $class;
}

sub name { shift->{name} };
sub path { shift->{path} };
sub suffix { shift->{suffix} };
sub fragments { return @{ shift->{fragments} || [] } }

sub fragments_specification {
    my $self = shift;
    my $out = '';
    if (my @fragments = $self->fragments) {
        $out = ':' . join(',', @fragments);
    }
    return $out;
}

sub name_with_fragments {
    my $self = shift;
    return $self->name . $self->fragments_specification;
}

sub name_with_ext_and_fragments {
    my $self = shift;
    return $self->name . $self->suffix . $self->fragments_specification;
}

sub filename {
    my $self = shift;
    return $self->name . $self->suffix;
}

sub full_path {
    my $self = shift;
    return $self->path . $self->filename;
}

sub text_amuse_constructor {
    my $self = shift;
    my %constructor = (file => $self->filename);
    if (my @fragments = $self->fragments) {
        $constructor{partial} = \@fragments;
    }
    return %constructor;
}

1;
