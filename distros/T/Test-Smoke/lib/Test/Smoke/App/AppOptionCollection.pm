package Test::Smoke::App::AppOptionCollection;
use warnings;
use strict;

use base 'Test::Smoke::ObjectBase';

=head1 NAME

Test::Smoke::App::AppOptionCollection - A collection of AppOption objects.

=head1 DESCRIPTION

=head2 Test::Smoke::App::AppOptionCollection->new()

=head3 Arguments

An optional list of L<Test::Smoke::App::AppOption> objects.

=head3 Returns

An instatiated object.

=head3 Exceptions

None.

=cut

sub new {
    my $class = shift;

    my $struct = {
        _added_options => [],
        _options_hash  => {},
        _options_list  => [],
        _helptext      => '',
    };

    my $self = bless $struct, $class;
    $self->add(@_);

    return $self;
}

=head2 $collection->add(@arguments)

Add the L<Getopt::Long> option and default to the collection. Also add the
L<Test::Smoke::App::AppOption->show_helptext()> to the running helptext variable.

=head3 Arguments

A list of L<Test::Smoke::AppOption> objects.

=head3 Returns

The object.

=head3 Exceptions

None.

=cut

sub add {
    my $self = shift;

    for my $tsao (@_) {
        push @{$self->added_options}, $tsao;
        $self->options_hash->{$tsao->name} = $tsao->default;
        push @{ $self->options_list }, $tsao->gol_option
            if !grep $_ eq $tsao->gol_option, @{$self->options_list};
        $self->add_helptext($tsao->show_helptext) if $tsao->helptext;
    }

    return $self;
}

=head2 $collection->add_helptext($string)

Adds a string to the currently build up helptext variable.

=cut

sub add_helptext {
    my $self = shift;

    $self->{_helptext} .= shift;
}

=head2 $collection->options_with_default()

=head3 Arguments

None

=head3 Returns

A hasref to a struct with only the defaults set from object construction.

=cut

sub options_with_default {
    my $self = shift;

    my %defaults =  map {
        +($_->name => $_->default)
    } grep
        $_->had_default
    , @{$self->added_options};

    return \%defaults;
}

=head2 $collection->options_for_cli()

=head3 Arguments

None

=head3 Returns

A hashref with options that have a CODEref as default.

=head3 Exceptions

None

=cut

sub options_for_cli {
    my $self = shift;

    my %clis = map {
        +($_->name => $_->default)
    } grep
        $_->had_default && ref($_->default) eq 'CODE'
    , @{$self->added_options};
    return \%clis;
}

=head2 $collection->all_options()

=head3 Arguments

None.

=head3 Returns

A hashref with all options and theire coded default.

=head3 Exceptions

None.

=cut

sub all_options {
    my $self = shift;

    return {
        map {
            +($_->name => $_->default)
        } @{$self->added_options}
    };
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
