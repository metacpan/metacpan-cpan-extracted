package WWW::AUR::Iterator;

use warnings 'FATAL' => 'all';
use strict;

use WWW::AUR::Package   qw();
use WWW::AUR::URI       qw( pkg_uri );
use WWW::AUR            qw( _path_params _category_name _useragent );

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    $self->init( @_ );
}

sub init
{
    my $self = shift;

    my $startidx;
    $startidx = shift if @_ % 2 == 1;

    %$self = ( %$self, _path_params( @_ ));
    $self->reset();
    $self->set_pos( $startidx ) if $startidx;

    return $self;
}

sub set_pos
{
    my ($self, $startidx) = @_;
    Carp::croak 'Argument to set_pos() must an integer'
        unless $startidx =~ /\A\d+\z/;

    $self->{'curridx'}  = $startidx;
    $self->{'finished'} = 0;
    $self->{'packages'} = [];

    return;
}

sub reset
{
    my ($self) = @_;
    $self->{'curridx'}   = 0;
    $self->{'finished'}  = 0;
    $self->{'packages'}  = [];
    $self->{'useragent'} = _useragent();
    return;
}

#---HELPER FUNCTION---
sub _pkglist_uri
{
    my ($startidx) = @_;
    return pkg_uri( q{SB} => q{n}, q{O}  => $startidx, 
                    q{SO} => q{a}, q{PP} => 100 );
}

#---PRIVATE METHOD---
sub _scrape_pkglist
{
    my ($self) = @_;

    my $uri  = _pkglist_uri( $self->{'curridx'} );
    my $resp = $self->{'useragent'}->get( $uri );

    Carp::croak 'Failed to GET package list webpage: ' . $resp->status_line
        unless $resp->is_success;

    my @pkginfos;
    my @rows = _splitrows( $resp->content );
    shift @rows; # remove the header column

    for my $rowhtml ( @rows ) {
        my @cols = _splitcols( $rowhtml );

        # cat, name, version, votes, desc, maintainer
        push @pkginfos, @cols;
    }

    return \@pkginfos;
}

sub _splitrows
{
    my ($html) = @_;
    my @rows = $html =~ m{ <tr[^>]*> ( .*? ) </tr> }gxs;
    return @rows;
}

sub _splitcols
{
    my ($rowhtml) = @_;
    my @cols = $rowhtml =~ m{ <td[^>]*> ( .*? ) </td> }gxs;
    for ( @cols ) {
        s/<[^>]+>//g; # delete tags
        s/\A\s+//; s/\s+\z//; # trim whitespace
    }
    return @cols;
}

sub next
{
    my ($self) = @_;

    # There are no more packages to iterate over...
    return undef if $self->{'finished'};

    my @pkginfo = splice @{ $self->{'packages'} }, 0, 6;
    if ( @pkginfo ) {
        my $pkg;
        my @k = qw/name version votes popularity desc/;
        for my $i (0 .. $#k) {
            $pkg->{$k[$i]} = $pkginfo[$i];
        }

        my $maint = $pkginfo[5];
        $pkg->{'maint'} = ($maint eq 'orphan' ? undef : $maint);
        return $pkg;
    }

    # Load a new batch of packages if our internal list is empty...
    my $newpkgs = $self->_scrape_pkglist;

    $self->{'curridx'} += 100;
    $self->{'packages'} = $newpkgs;
    $self->{'finished'} = 1 if scalar @$newpkgs == 0;

    # Recurse, just avoids code copy/pasting...
    return $self->next();
}

sub next_obj
{
    my ($self) = @_;

    my $next = $self->next;
    return ( $next
             ? WWW::AUR::Package->new( $next->{'name'}, %$self )
             : undef );
}

1;

__END__

=head1 NAME

WWW::AUR::Iterator - An iterator for looping through all AUR packages.

=head1 SYNOPSIS

  my $aurobj = WWW:AUR->new();
  my $iter = $aurobj->iter();
  
  # or without WWW::AUR:
  my $iter = WWW::AUR::Iterator->new();
  
  while ( my $pkg = $iter->next_obj ) {
      print $pkg->name, "\n";
  }
  
  $iter->reset;
  while ( my $p = $iter->next ) {
      print "$_:$p->{$_}\n"
          for qw{ id name version cat desc maint };
      print "---\n";
  }
  
  # Retrieve information on the 12,345th package, alphabetically.
  $iter->set_pos(12_345);
  my $pkginfo  = $iter->next;

=head1 DESCRIPTION

A B<WWW::AUR::Iterator> object can be used to iterate through I<all>
packages currently listed on the AUR webiste.

=head1 CONSTRUCTOR

  $OBJ = WWW::AUR::Iterator->new( %PATH_PARAMS );

=over 4

=item C<%PATH_PARAMS>

The parameters are the same as the L<WWW::AUR> constructor. These are
propogated to any L<WWW::AUR::Package> objects that are created.

=item C<$OBJ>

A L<WWW::AUR::Iterator> object.

=back

=head1 METHODS

=head2 reset

  $OBJ->reset;

The iterator is reset to the beginning of all packages available in
the AUR. This starts the iteration over just like creating a new
I<WWW::AUR::Iterator> object.

=head2 next

  \%PKGINFO | undef = $OBJ->next();

This package scrapes the L<http://aur.archlinux.org/packages.php>
webpage as if it kept clicking the Next button and recording each
package.

=over 4

=item C<\%PKGINFO>

A hash reference containing all the easily available information about
that particular package. The follow table lists each key and its
corresponding value.

  |------------+------------------------------------------------|
  | NAME       | VALUE                                          |
  |------------+------------------------------------------------|
  | name       | The name (pkgname) of the package.             |
  | votes      | The number of votes for the package.           |
  | desc       | The description (pkgdesc) of the package.      |
  | cat        | The AUR category name assigned to the package. |
  | maint      | The name of the maintainer of the package.     |
  |------------+------------------------------------------------|

=item C<undef>

If we have iterated through all packages, then C<undef> is returned.

=back

=head2 next_obj

  $PKGOBJ | undef = $OBJ->next_obj();

This package is like the L</next> method above but creates a new
object as a convenience. Keep in mind an HTTP request to AUR must be
made when creating a new WWW::AUR::Package object.  Use the L</next>
method if you can, it is faster.

=over 4

=item C<$PKGOBJ>

A L<WWW::AUR::Package> object representing the next package in the AUR.

=item C<undef>

If we have iterated through all packages, then C<undef> is returned.

=back

=head2 set_pos

  undef = $OBJ->set_pos( $POS );

Set the iterator position to the given index in the entire list of
packages from packages.php.

=over 4

=item C<$POS>

This is not the package ID but simply the list offset on the package webpage.

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
