# ABSTRACT: Faster backend for YAML::PP
package YAML::PP::LibYAML;
use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use base qw/ YAML::PP Exporter /;
our @EXPORT_OK = qw/ Load Dump LoadFile DumpFile /;

use YAML::PP::LibYAML::Parser;
use YAML::PP::LibYAML::Emitter;

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(
        parser => YAML::PP::LibYAML::Parser->new,
        emitter => YAML::PP::LibYAML::Emitter->new(
            indent => delete $args{indent},
        ),
        %args,
    );
    return $self;
}

# legacy interface
sub Load {
    my ($yaml) = @_;
    YAML::PP::LibYAML->new->load_string($yaml);
}

sub LoadFile {
    my ($file) = @_;
    YAML::PP::LibYAML->new->load_file($file);
}

sub Dump {
    my (@data) = @_;
    YAML::PP::LibYAML->new->dump_string(@data);
}

sub DumpFile {
    my ($file, @data) = @_;
    YAML::PP::LibYAML->new->dump_file($file, @data);
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::PP::LibYAML - Faster parsing for YAML::PP

=head1 SYNOPSIS

    use YAML::PP::LibYAML; # use it just like YAML::PP
    my $yp = YAML::PP::LibYAML->new;
    my @docs = $yp->load_string($yaml);

    # Legacy interface
    use YAML::PP::LibYAML qw/ Load /;
    my @docs = Load($yaml);

=head1 DESCRIPTION

L<YAML::PP::LibYAML> is a subclass of L<YAML::PP>. Instead of using
L<YAML::PP::Parser> as a the backend parser, it uses
L<YAML::PP::LibYAML::Parser> which calls L<YAML::LibYAML::API>, an XS wrapper
around the C<C libyaml>.

=head2 libyaml

Syntactically libyaml supports a large subset of the
L<YAML 1.2|http://yaml.org/spec/1.2/spec.html> spec as well as
L<1.1|http://yaml.org/spec/1.1/>.

The things it cannot parse are often not relevant to real world usage.

=head2 YAML::XS

L<YAML::XS> combines a wrapper around libyaml and the code for
constructing/deconstructing the data into one single API, almost completely
written in XS.

That makes it very fast, but the part of constructing the data is not very flexible
simply because it's more work to write this in C. It conforms to only a subset
of the YAML 1.1 types and tags.

=head2 YAML::PP

L<YAML::PP> aims to build a powerful and flexible API for the data construction
part.
Its parser aims to fully support YAML 1.2 syntactically, which mostly includes
1.1, but it's not quite there yet. It parses things that libyaml doesn't, but
the opposite is also true.

=head2 YAML::LibYAML::API

L<YAML::LibYAML::API> is a wrapper around the libyaml parser.

Combining L<YAML::LibYAML::API> and L<YAML::PP> gives you the flexibility
of the loading API and the speed of the quite robust libyaml parser, although
it's still much slower than L<YAML::XS>. Benchmarks will follow.

=head1 METHODS

=over

=item new

Constructor, works like L<YAML::PP::new> but adds L<YAML::PP::LibYAML::Parser>
by default.

=item load_string, load_file, dump_string, dump_file

Work like in L<YAML::PP>

=back

=head1 FUNCTIONS

=over

=item Load, Dump, LoadFile, DumpFile

Work like in L<YAML::PP> (and in all other well known YAML loaders).

The only difference is, none of them is exported by default.

=back

=head1 SEE ALSO

=over

=item L<YAML::PP>

=item L<YAML::XS>

=item L<YAML::LibYAML::API>

=back

=head1 AUTHOR

Tina Müller <tinita@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
