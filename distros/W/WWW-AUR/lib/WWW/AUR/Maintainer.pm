package WWW::AUR::Maintainer;

use warnings 'FATAL' => 'all';
use strict;

use Carp qw();

use WWW::AUR::RPC;

#---CONSTRUCTOR---
sub new
{
    my $class = shift;

    my ($name, %params) = @_
        or Carp::croak 'You must supply a maintainer name as argument';

    my $packages_ref = WWW::AUR::RPC::msearch( $name );
    bless { name => $name, packages => $packages_ref, %params }, $class;
}

sub name
{
    my ($self) = @_;
    return $self->{name};
}

#---PUBLIC METHOD---
sub packages
{
    my ($self) = @_;

    my $pkgs = $self->{packages};

    require WWW::AUR::Package;
    return map { WWW::AUR::Package->new( $_->{name}, info => $_ ) }
        @$pkgs;
}

1;

__END__

=head1 NAME

WWW::AUR::Maintainer - List packages owned by a given maintainer.

=head1 SYNOPSIS

  my $maint = $aurobj->maintainer( 'juster' );
  
  # or ...
  my $maint = WWW::AUR::Maintainer->new( 'juster' );
  
  my $name = $maint->name;
  my @pkgs = $maint->packages;

=head1 CONSTRUCTOR

  $OBJ = WWW::AUR::Maintainer->new( $NAME, %PATH_PARAMS? );

If the maintainer matching the given name does not exist, it is hard
to tell. Currently if a bad maintainer name is given, the results
of L</packages> will return an empty list.

=over 4

=item C<$NAME>

The name of the maintainer.

=item C<%PATH_PARAMS> I<(Optional)>

These are propogated to the L<WWW::AUR::Package> objects created by
L</packages>. See L<WWW::AUR/PATH PARAMETERS> for more info.

=back

=head1 METHODS

=head2 name

  $MNAME = $OBJ->name

=over 4

=item C<$MNAME>

The name of the maintainer as given to the constructor.

=back

=head2 packages

  @PKGOBJS = $OBJ->packages

=over 4

=item C<@PKGOBJS>

A list of L<WWW::AUR::Package> objects. These represent the packages
that are owned by the given maintainer. The list can be empty. If the
maintainer named does not exist, the list will be empty.

=back

=head1 SEE ALSO

L<WWW::AUR>

=head1 AUTHOR

Justin Davis, C<< <juster at cpan dot org> >>

=head1 BUGS

Please email me any bugs you find. I will try to fix them as quick as I can.

=head1 SUPPORT

Send me an email if you have any questions or need help.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Justin Davis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
