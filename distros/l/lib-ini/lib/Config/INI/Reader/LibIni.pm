package Config::INI::Reader::LibIni;
{
  $Config::INI::Reader::LibIni::VERSION = '0.002';
}

use strict;
use warnings;

use base 'Config::INI::Reader';

sub new {
    my ($class) = @_;
    return bless { data => [] }, $class;
}

sub change_section {
    my ($self, $section) = @_;
    push @{ $self->{data} }, [ $section => {} ];
}

sub set_value {
    my ($self, $name, $value) = @_;

    if ( exists $self->{data}[-1][1]{$name} ) {
        my $existing = $self->{data}[-1][1]{$name};

        if (ref $existing eq 'ARRAY') {
            push @{ $self->{data}[-1][1]{$name} }, $value;
        } else {
            $self->{data}[-1][1]{$name} = [$existing, $value];
        }
    } else {
        $self->{data}[-1][1]{$name} = $value;
    }
}

sub current_section {
    my ($self) = @_;
    exists $self->{data}[-1] ? $self->{data}[-1][0] : $self->starting_section;
}

1;

__END__
=pod

=for :stopwords Peter Shangov Plugin

=head1 NAME

Config::INI::Reader::LibIni

=head1 VERSION

version 0.002

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

