package Text::Amuse::Compile::Fonts::Import;
use utf8;
use strict;
use warnings;
use IO::Pipe;
use JSON::MaybeXS ();
use Text::Amuse::Compile::Fonts;
use Moo;
use Data::Dumper;


=head1 NAME

Text::Amuse::Compile::Fonts::Import - create a list of fonts to be used with Text::Amuse::Compile

=head1 DESCRIPTION

This module is basically an hack. It parses the output of fc-list or
identify (from imagemagick) to get a list of font paths.

It should work on Windows if imagemagick is installed.

=head1 ACCESSOR

=head2 output

The output file to write the json to. If not provided, it will print on the STDOUT.

=head1 PUBLIC METHODS

=head2 import_and_save

Parse the font list and output it to the file, if provided to the
constructor, otherwise print the JSON on the standard output.

=head1 INTERNAL METHODS

=over 4

=item use_fclist

=item use_imagemagick

=item try_list

=item all_fonts

=item import_with_fclist

=item import_with_imagemagick

=item import_list

=item as_json

=back


=cut


has output => (is => 'ro');

sub use_fclist {
    return system('fc-list', '--version') == 0;
}

sub use_imagemagick {
    return system('identify', '-version') == 0;
}

sub try_list {
    # pick the default list from the Fonts class and add Noto
    my $fonts = Text::Amuse::Compile::Fonts->new;
    my %all = (
               serif => [ map { $_->name } $fonts->serif_fonts ],
               mono  => [ map { $_->name } $fonts->mono_fonts ],
               sans  => [ map { $_->name } $fonts->sans_fonts ],
              );
    return \%all;
}

sub all_fonts {
    my $self = shift;
    my $list = $self->try_list;
    my %all;
    foreach my $k (keys %$list) {
        foreach my $font (@{$list->{$k}}) {
            $all{$font} = $k;
        }
    }
    return %all;
}

sub import_with_fclist {
    my $self = shift;
    return unless $self->use_fclist;
    local $_;
    my %specs;
    my %all = $self->all_fonts;
    my $pipe = IO::Pipe->new;
    my @dupes;
    $pipe->reader('fc-list');
    $pipe->autoflush;
    while (<$pipe>) {
        chomp;
        if (m/(.+?)\s*:
              \s*(.+?)(\,.+)?\s*:
              \s*style=(
                  Book|Roman|Medium|Regular|
                  Italic|Oblique|
                  Bold|
                  Bold\s*Italic|Bold\s*Oblique)$/x) {
            my $file = $1;
            my $name = $2;
            my $style = lc($4);
            next unless $file =~ m/\.(t|o)tf$/i;
            $style =~ s/\s//g;
            next unless $all{$name};
            if ($specs{$name}{files}{$style}) {
                warn "Duplicated font! $file $name $style $specs{$name}{files}{$style}\n";
                push @dupes, $name;
            }
            else {
                $specs{$name}{files}{$style} = $file;
            }
        }
    }
    wait;
    if (@dupes) {
        warn "Deleting duplicated fonts, likely to cause problems:" . join(" ", @dupes). "!\n";
        foreach my $dupe (@dupes) {
            delete $specs{$dupe};
        }
    }
    return \%specs;
    
}

sub import_with_imagemagick {
    my $self = shift;
    return unless $self->use_imagemagick;
    my %specs;
    my %all = $self->all_fonts;
    local $_;
    my $pipe = IO::Pipe->new;
    $pipe->reader('identify', -list => 'font');
    $pipe->autoflush;
    my %current;
    while (<$pipe>) {
        chomp;
        if (m/^\s*Font:/) {
            if ($current{family} && $current{glyphs} && $current{style} && $current{weight}) {
                my $name = $current{family};
                my $file = $current{glyphs};
                my $style;
                if ($current{style} eq 'Normal') {
                    if ($current{weight} == 700) {
                        $style = 'bold';
                    }
                    elsif ($current{weight} == 400 or
                           $current{weight} == 500) {
                        $style = 'regular';
                    }
                }
                elsif ($current{style} eq 'Italic') {
                    if ($current{weight} == 700) {
                        $style = 'bolditalic';
                    }
                    elsif ($current{weight} == 400 or
                           $current{weight} == 500) {
                        $style = 'italic';
                    }
                }
                if ($style and $all{$name}) {
                    if ($specs{$name}{files}{$style}) {
                        # warn "Duplicated font! $file $name $style $specs{$name}{files}{$style}\n";
                    }
                    else {
                        $specs{$name}{files}{$style} = $file;
                    }
                }
            }
            %current = ();
        }
        elsif (m/^\s*(\w+):\s+(.+)\s*$/) {
            $current{$1} = $2;
        }
    }
    return \%specs;
}

sub import_list {
    my $self = shift;
    my $list = $self->try_list;
    my $specs = $self->import_with_fclist || $self->import_with_imagemagick;
    die "Cannot retrieve specs, nor with fc-list, nor with imagemagick" unless $specs;
    my @out;
    foreach my $type (qw/serif sans mono/) {
        foreach my $font (@{$list->{$type}}) {
            if (my $found = $specs->{$font}) {
                my $files = $found->{files};
                my %styles = (
                              bold => $files->{bold},
                              bolditalic => $files->{bolditalic} || $files->{boldoblique},
                              italic => $files->{italic} || $files->{oblique},
                              regular => $files->{regular} || $files->{book} || $files->{roman} || $files->{medium},
                              name => $font,
                              desc => $font,
                              type => $type,
                             );
                if (grep { !$_ } values %styles) {
                    warn "Discarding $font, missing styles: " . Dumper(\%styles);
                }
                else {
                    push @out, \%styles;
                }
            }
        }
    }
    return \@out;
};

sub as_json {
    my $self = shift;
    my $list = $self->import_list;
    return JSON::MaybeXS->new(pretty => 1,
                              canonical => 1,
                             )->encode($list);
}

sub import_and_save {
    my $self = shift;
    my $json = $self->as_json;
    if (my $file = $self->output) {
        open (my $fh, '>', $file) or die $!;
        print $fh $json;
        close $fh;
    }
    else {
        print $json;
    }
}

1;
