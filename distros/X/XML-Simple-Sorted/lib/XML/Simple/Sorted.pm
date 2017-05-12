=head1 NAME

XML::Simple::Sorted - Version of XML::Simple with enforced tag and attribute sort order.
This module was born out of the need to interface with some legacy systems that could not be
changed and that expected a certain tag order, otherwise they would crash and burn... just kidding ;-)

=head1 SYNOPSIS

    use XML::Simple::Sorted;

    my $xml = XML::Simple::Sorted->new( [OPT] ) ;

=cut

package XML::Simple::Sorted;

use strict;
use warnings;

use XML::Simple;
use Carp;

BEGIN
{
    use Exporter();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = '1.00';
    @ISA = qw(XML::Simple);
    @EXPORT = ();
    %EXPORT_TAGS = ();
    @EXPORT_OK = qw();
}
our @EXPORT_OK;

=head1 CLASS METHODS

=head2 B<new() >

Creates a new instance of C<XML::Simple::Sorted>.
Here, we simply override the constructor of L<XML::Simple> and check if the user has given
an *.ini file or hash containing the desired tag and attribute order.

=over 4

=item B<SortOrder>

This new option can either specify a hashref containing the desired tag and attribute sort
order or the path to an ini file (see L<Config::IniFiles>) containing the desired tag and
attribute sort order.
This method will croak() if one specifies a non-existing config file.

=back

=head3 Example

    my $xml = XML::Simple::Sorted->new(SortOrder => 'sort_config.ini');

    my $sort_hashref = { ... };
    my $xml = XML::Simple::Sorted->new(SortOrder => $sort_hashref);

=head3 Example sort_config.ini file

    [message]
        tags = [ 'tradeid', 'leg' ]
        attr = [ 'system', 'sender', 'receiver', 'timestamp' ]
    [leg]
        tags = [ 'legid', 'payment', 'book', 'product' ]
    [payment]
        tags = [ 'start', 'end', 'nominal', 'currency' ]
    ...

=head3 Example sort_hashref

    my $order = {
        message => {
            tags => [ 'tradeid', 'leg' ],
            attr => [ 'system', 'sender', 'receiver', 'timestamp' ]
        },
        leg => {
            tags => [ 'legid', 'payment', 'book', 'product' ]
        },
        payment => {
            tags => [ 'start', 'end', 'nominal', 'currency' ]
        },
    };
    Please note that the 'tags' und 'attr' parameters are semantically identical, i.e. one
    could specify the attribute order also using the 'tags' parameter and vice versa.
    Two parameters only serve to hopefully improve the readability of the *.ini file / hashref.

=cut
sub new {
    my ($class, %args) = @_;
    my @params = ('tags', 'attr');
    my $sort;
    if (exists($args{SortOrder})) {
        if (UNIVERSAL::isa($args{SortOrder}, 'HASH')) {
            $sort = $args{SortOrder};
        } else {
            use Config::IniFiles;
            use Tie::File;
            my %ini;
            croak($args{SortOrder}, ' not found') if (! -f $args{SortOrder});
            tie %ini, 'Config::IniFiles', ( -file => $args{SortOrder} );
            my %sorted;
            for my $k (keys %ini) {
                for my $p (@params) {
                    $sorted{$k}{$p} = eval($ini{$k}{$p}) if ($ini{$k}{$p});
                }
            }
            $sort = \%sorted;
        }
        delete($args{SortOrder});
    }
    my $self = $class->SUPER::new(%args);
    $self->{params} = \@params;
    $self->{sort} = $sort;
    bless($self, $class);
    return $self;
} # new()

=head2 B<sorted_keys()>

Override method C<sorted_keys()> of L<XML::Simple> to perform the desired ordering of XML
tags and attributes.

=cut
sub sorted_keys {
    my ($self, $name, $hashref) = @_;
    my @sorted_tags;
    for my $p (@{$self->{params}}) {
        if (my $val = $self->{sort}->{$name}{$p}) {
            for my $k (@$val) {
                # Only return tags and attributes that also exist in the given XML hashref to
                # prevent the creation of empty attributes.
                push(@sorted_tags, $k) if (exists($hashref->{$k}));
            }
        }
    }
    return @sorted_tags if (@sorted_tags);
    return $self->SUPER::sorted_keys($name, $hashref);
} # sorted_keys()

1;

=head1 SEE ALSO

L<XML::Simple>, L<Config::IniFiles>

=head1 AUTHOR

Sinisa Susnjar <sini@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 Sinisa Susnjar

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
