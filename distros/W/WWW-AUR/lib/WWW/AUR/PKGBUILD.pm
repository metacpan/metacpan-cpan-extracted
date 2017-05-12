package WWW::AUR::PKGBUILD;

use warnings 'FATAL' => 'all';
use strict;

use Fcntl qw(SEEK_SET);
use Carp  qw();

my @ARRAY_FIELDS = qw{ license source noextract
                       md5sums sha1sums sha256sums sha384sums sha512sums
                       groups arch backup depends makedepends conflicts
                       provides replaces options };
# We cannot auto-split optdepends because spaces are allowed.

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;

    if ( @_ ) { $self->read( @_ ); }
    return $self;
}

#---HELPER FUNCTION---
sub _unquote_bash
{
    my ($bashtext, $start, $expander) = @_;
    my $elem;

    $expander ||= sub { shift };
    $start    ||= 0;
    ( pos $bashtext ) = $start;

    # Extract the values of a bash array...
    if ( $bashtext =~ / \G [(] ([^)]*) [)] /gcx ) {
        my $arrtext = $1;
        my @result;

        ARRAY_LOOP:
        while ( 1 ) {
            my ($elem, $elem_end) = _unquote_bash( $arrtext,
                                                   pos $arrtext,
                                                   $expander );
            push @result, $elem if $elem;

            # There should only be spaces leftover.
            ( pos $arrtext ) = $elem_end;
            last ARRAY_LOOP if ( $elem_end >= length $arrtext ||
                                 $arrtext !~ /\G\s+/g );
        }

        # Arrays are special, we do not recurse after we find one.
        return \@result, pos $bashtext;
    }

    # The rest is for string "parsing"...

    # Single quoted strings cannot escape the quote (')...
    if ( $bashtext =~ /\G'([^']*)'/gc ) {
        $elem = $1;
    }
    # Double quoted strings can...
    elsif ( $bashtext =~ /\G"/gc ) {
        my $beg = pos $bashtext;
        # Skip past escaped double-quotes and non-double-quote chars.
        while ( $bashtext =~ / \G (?: \\" | [^"] ) /gcx ) { ; }

        $elem = substr $bashtext, $beg, ( pos $bashtext ) - $beg;
        $elem = $expander->( $elem );
        ++( pos $bashtext ); # skip the closing "
    }
    # Otherwise regular words are treated as one element...
    elsif ( $bashtext =~ /\G([^ \n\t'"]+)/gc ) {
        $elem = $expander->( $1 );
    }
    # If none of the above matches, then we stop recursion.
    else { return q{}, $start; }

    # We recurse in order to concatenate adjacent strings.
    my ( $next_elem, $next_end ) = _unquote_bash( $bashtext,
                                                  pos $bashtext,
                                                  $expander );
    return ( $elem . $next_elem, $next_end );
}

# Perform the simplest parameter expansion possible.
sub _expand_bash
{
    my ($bashstr, $fields_ref) = @_;

    my $expand_field = sub {
        my $name = shift;
        return $fields_ref->{ $name } if defined $fields_ref->{ $name };
        return qq{\$$name};
        # TODO: error reporting?
    };

    $bashstr =~ s{ \$ ([\w_]+) }
                 { $expand_field->( $1 ) }gex;

    # TODO: check for special expansion modifiers
    $bashstr =~ s( \$ \{ ([^}]+) \} )
                 ( $expand_field->( $1 ) )gex;

    return $bashstr;
}

#---HELPER FUNCTION---
sub _depstr_to_hash
{
    my ($depstr) = @_;
    my ($pkg, $cmp, $ver) = $depstr =~ / \A ([^=<>]+)
                                         (?: ([=<>]=?)
                                             (.*) )? \z/xms;

    Carp::confess "Failed to parse depend string: $_" unless $pkg;

    return +{ 'pkg' => $pkg, 'cmp' => $cmp,
              'ver' => $ver, 'str' => $depstr };
}

sub _provides_to_hash
{
    my ($provstr) = @_;
    my ($pkg, $ver) = $provstr =~ / \A ([^=]+)
                                    (?: = (.*))?
                                  /xms;
    Carp::confess "Failed to parse provides string: $_" unless $pkg;
    return +{ 'pkg' => $pkg, 'ver' => $ver, 'str' => $provstr };
}

#---HELPER FUNCTION---
sub _pkgbuild_fields
{
    my ($pbtext) = @_;

    my %pbfields;
    my $expander = sub {
        _expand_bash( shift, \%pbfields )
    };

    while ( $pbtext =~ / \G .*? \n? ^ ([\w_]+) = /gxms ) { 
        my $name = $1;
        my ( $value, $endpos ) = _unquote_bash( $pbtext,
                                                pos $pbtext,
                                                $expander );
        $pbfields{ $name } = $value;
        ( pos $pbtext ) = $endpos;
    }

    # Split arrays at whitespace for poorly made PKGBUILDs...
    # also ensures each field has an arrayref.
    ARRAY_LOOP:
    for my $arrkey ( @ARRAY_FIELDS ) {
        unless ( $pbfields{ $arrkey } ) {
            $pbfields{ $arrkey } = [];
            next ARRAY_LOOP;
        }

        my $val_ref = $pbfields{ $arrkey };

        # Force the value into being an array...
        $val_ref    = [ $val_ref ] unless ref $val_ref;

        # Try to filter out common problems people have with defining arrays.
        # 1) trailing \'s
        # 2) commented array items (generally a complete line is commented)
        # 3) depends=('foo=1 bar<2 baz>=3')  (a string separated by spaces)
        # 4) depends=('turbojpegipp >=1.11') (only in the turbovnc-bin pkg)
        # (These should be done by the parser, eventually)
        $val_ref    = [ grep { $_ ne q{\\} } # *1
                        map  { split }       # *3
                        map  { s{ \A (\w+) \s+
                                  ([<>=]{1,2}\d+) }{$1$2}x; $_ } # *4
                        map  { s/\A\s+//; s/\s+\z//; $_ }        # trim ws
                        grep { length } map { s/\#.*//; $_ }     # *2
                        @$val_ref ];

        $pbfields{ $arrkey } = $val_ref;
    }

    # optdepends are special, we should only split on newlines
    if ( $pbfields{'optdepends'} ) {
        my $optdeps = $pbfields{'optdepends'};
        $optdeps = [ $optdeps ] unless ref $optdeps;

        # Remember stupid \'s at the end of lines
        $optdeps = [ grep { length } map { s/\#.*//; $_ }
                     grep { $_ ne q{\\} }
                     map { s/\A\s+//; s/\s+\z//; $_ }
                     @$optdeps ];
        $pbfields{'optdepends'} = $optdeps;
    }
    else {
        $pbfields{'optdepends'} = [];
    }

    # Convert all depends into hash references...
    VERSPEC_LOOP:
    for my $depkey ( qw/ makedepends depends conflicts / ) {
        my @deps = @{ $pbfields{ $depkey } };
        next VERSPEC_LOOP unless @deps;

        eval {
            $pbfields{ $depkey } = [ map { _depstr_to_hash($_) } @deps ];
        };
        if ( $@ ) {
            die qq{Error with "$depkey" field:\n$@};
        }
    }

    # Provides has no comparison operator and may have no version...
    if ( $pbfields{'provides'} ) {
        $pbfields{'provides'} =
            [ map { _provides_to_hash($_) } @{$pbfields{'provides'}} ];
    }

    return %pbfields;
}

#---HELPER FUNCTION---
sub _slurp
{
    my ($fh) = @_;

    # Make sure we start reading from the beginning of the file...
    seek $fh, SEEK_SET, 0 or die "seek: $!";

    local $/;
    return <$fh>;
}

sub read
{
    my $self = shift;
    $self->{'text'} = ( ref $_[0] eq 'GLOB' ? _slurp( shift ) : shift );

    my %pbfields = _pkgbuild_fields( $self->{'text'} );
    $self->{'fields'} = \%pbfields;    
    return %pbfields;
}

sub fields
{
    my ($self) = @_;
    return %{ $self->{'fields'} }
}

sub _def_field_acc
{
    my ($name) = @_;

    no strict 'refs';
    *{ $name } = sub {
        my ($self) = @_;
        my $val = $self->{'fields'}{$name};

        return q{} unless defined $val;
        return $val;
    }
}

_def_field_acc( $_ ) for qw{ pkgname pkgver pkgdesc pkgrel url
                             license install changelog source
                             noextract md5sums sha1sums sha256sums
                             sha384sums sha512sums groups arch
                             backup depends makedepends optdepends
                             conflicts provides replaces options };

1;

__END__

=head1 NAME

WWW::AUR::PKGBUILD - Parse PKGBUILD files created for makepkg

=head1 SYNOPSIS

  use WWW::AUR::PKGBUILD;
  
  # Read a PKGBUILD from a file handle...
  open my $fh, '<', 'PKGBUILD' or die "open: $!";
  my $pb = WWW::AUR::PKGBUILD->new( $fh );
  close $fh;
  
  # Or read from text
  my $pbtext = do { local (@ARGV, $/) = 'PKGBUILD'; <> };
  my $pbobj  = WWW::AUR::PKGBUILD->new( $pbtext );
  my %pb     = $pbobj->fields();

  # Array fields are converted into arrayrefs...
  my $deps = join q{, }, @{ $pb{depends} };
  
  my %pb = $pb->fields();
  print <<"END_PKGBUILD";
  pkgname = $pb{pkgname}
  pkgver  = $pb{pkgver}
  pkgdesc = $pb{pkgdesc}
  depends = $deps
  END_PKGBUILD
  
  # There are also method accessors for all fields
  

=head1 DESCRIPTION

This class reads the text contents of a PKGBUILD file and does some
primitive parsing. PKGBUILD fields (ie pkgname, pkgver, pkgdesc) are
extracted into a hash. Bash arrays are extracted into an arrayref
(ie depends, makedepends, source).

Remember, bash is more lenient about using arrays than perl is. Bash
treats one-element arrays the same as non-array parameters and
vice-versa. Perl doesn't. I might use a module to copy bash's behavior
later on.

=head1 CONSTRUCTOR

  $OBJ = WWW::AUR::PKGBUILD->new( $PBTEXT | $PBFILE );

All this does is create a new B<WWW::AUR::PKGBUILD> object and
then call the L</read> method with the provided arguments.

=over 4

=item C<$PBTEXT>

A scalar containing the text of a PKGBUILD file.

=item C<$PBFILE>

A filehandle of an open PKGBUILD file.

=back

=head1 METHODS

=head2 fields

  %PBFIELDS = $OBJ->fields();

=over 4

=item C<%PBFIELDS>

The fields and values of the PKGBUILD. Bash arrays (those values defined
with parenthesis around them) are converted to array references.

=back

=head2 read

  %PBFIELDS = $OBJ->read( $PBTEXT | $PBFILE );

=over 4

=item C<$PBTEXT>

A scalar containing the text of a PKGBUILD file.

=item C<$PBFILE>

A filehandle of an open PKGBUILD file.

=item C<%PBFIELDS>

The fields and values of the PKGBUILD. Bash arrays (those values defined
with parenthesis around them) are converted to array references.

=back

=head2 PKGBUILD Field Accessors

  undef | $TEXT | $AREF = ( $OBJ->pkgname     | $OBJ->pkgver     |
                            $OBJ->pkgdesc     | $OBJ->url        |
                            $OBJ->license     | $OBJ->install    |
                            $OBJ->changelog   | $OBJ->source     |
                            $OBJ->noextract   | $OBJ->md5sums    |
                            $OBJ->sha1sums    | $OBJ->sha256sums |
                            $OBJ->sha384sums  | $OBJ->sha512sums |
                            $OBJ->groups      | $OBJ->arch       |
                            $OBJ->backup      | $OBJ->depends    |
                            $OBJ->makedepends | $OBJ->optdepends |
                            $OBJ->conflicts   | $OBJ->provides   |
                            $OBJ->replaces    | $OBJ->options    )

Each standard field of a PKGBUILD can be accessed by using one
of these accessors. The L</fields> method returns a hashref
containing ALL bash variables defined globally.

=over 4

=item C<undef>

If the field was not defined in the PKGBUILD undef is returned.

=item C<$TEXT>

If a field is defined but is not a bash array it is returned as a
scalar text value.

=item C<$AREF>

If a field is defined as a bash array (with parenthesis) it is
returned as an array reference.

=back

=head1 SEE ALSO

=over 4

=item * L<WWW::AUR::Package::File>

=item * L<http://www.archlinux.org/pacman/PKGBUILD.5.html>

=back

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
