package Text::Template::LocalVars::Package;

use Package::Stash;
use Symbol qw[ delete_package ];
use Storable qw[ dclone ];

my $pkgid = 0;

=begin quiet_pod_coverage

=head2 new

=end quiet_pod_coverage

=cut

sub new {

    my ( $class, $orig ) = @_;

    my $self = bless \( __PACKAGE__ . '::Q' . $pkgid++ ), $class;

    $self->_copy_package( $orig );

    return $self;
}

=begin quiet_pod_coverage

=head2 pkg

=end quiet_pod_coverage

=cut

sub pkg { ${ $_[0] } }

sub DESTROY {

    my $self = shift;

    delete_package( $self->pkg );

    return;
}

#<<< no perltidy
# ignore dclone warnings; $Storable::forgive_me set below
my @Map = (
    [ HASH   => '%' => sub {local $SIG{__WARN__} = sub { }; dclone( shift );}],
    [ ARRAY  => '@' => sub {local $SIG{__WARN__} = sub { }; dclone( shift );}],
    [ CODE   => '&' => sub { shift } ],
    [ SCALAR => '$' => sub { ${ $_[0] } if 'SCALAR' eq ref $_[0] } ],
);
#>>> no perltidy

sub _copy_package {

    my ( $self, $src_pkg ) = @_;

    my $src = Package::Stash->new( $src_pkg );
    my $dst = Package::Stash->new( $self->pkg );

    # can't use the globs directly, but because scalar slots in
    # globs will always return a reference (at least as of Perl
    # 5.20.1) even if unused. that means we'd create extra scalars
    # where there were none.

    # we don't care if dclone can't store things we don't care
    # about (like GLOBS buried in a hash or an array)
    local $Storable::forgive_me = 1;

    for my $map ( @Map ) {

        my ( $type, $sigil, $convert ) = @$map;
        my $symbols = $src->get_all_symbols( $type );

        while ( my ( $var, $value ) = each %$symbols ) {

            # don't clone
            #  * anything which looks like a package stash.
            #  * the special _ variable, which causes things to segv
            #    on some Perls when the package is deleted.
            next if $var =~ /::$/ or $var eq '_';

            eval {
                $dst->add_symbol( $sigil . $var, $convert->( $value ) );
                1;
            } or die( "error adding $sigil$var: $@\n" );
        }
    }
}

1;

=head1 NAME

Text::Template::LocalVars::Package - manage clone of a template variable package

=head1 SYNOPSIS

  Don't do anything with this

=head1 DESCRIPTION

This is a private module for use by L<Text::Template::LocalVars::Package>.


=head1 AUTHOR

Diab Jerius, C<< <djerius at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Smithsonian Astrophysical Observatory

Copyright (C) 2014 Diab Jerius

Text::Template::LocalVars is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


