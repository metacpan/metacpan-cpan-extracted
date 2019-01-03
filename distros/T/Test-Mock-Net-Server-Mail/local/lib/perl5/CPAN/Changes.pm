package CPAN::Changes;

use strict;
use warnings;

use CPAN::Changes::Release;
use Scalar::Util ();
use version      ();
use Encode qw(decode FB_CROAK LEAVE_SRC);

our $VERSION = '0.400002';

# From DateTime::Format::W3CDTF
our $W3CDTF_REGEX = qr{(\d\d\d\d) # Year
                 (?:-(\d\d) # -Month
                 (?:-(\d\d) # -Day
                 (?:[T\s]
                   (\d\d):(\d\d) # Hour:Minute
                   (?:
                     :(\d\d)     # :Second
                     (\.\d+)?    # .Fractional_Second
                   )?
                   ( Z          # UTC
                   | [+-]\d\d:\d\d    # Hour:Minute TZ offset
                     (?::\d\d)?       # :Second TZ offset
                 )?)?)?)?}x;

my @m = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my %months = map { $m[ $_ ] => $_ + 1 } 0 .. 11;

our $UNKNOWN_VALS = join( '|', (
    'Unknown Release Date', 'Unknown', 'Not Released', 'Development Release', 
    'Development', 'Developer Release', 
) );

sub new {
    my $class = shift;
    return bless {
        preamble => '',
        releases => {},
        months   => \%months,
        @_,
    }, $class;
}

sub load {
    my ( $class, $file, @args ) = @_;

    open( my $fh, '<:raw', $file ) or die $!;

    my $content = do { local $/; <$fh> };

    close $fh;

    # if it's valid UTF-8, decode that.  otherwise, assume latin 1 and leave it.
    eval { $content = decode('UTF-8', $content, FB_CROAK | LEAVE_SRC) };

    return $class->load_string( $content, @args );
}

sub load_string {
    my ( $class, $string, @args ) = @_;

    my $changes  = $class->new( @args );
    my $preamble = '';
    my ( @releases, $ingroup, $indent );

    $string =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;
    my @lines = split( "\n", $string );

    my $version_line_re
        = $changes->{ next_token }
        ? qr/^(?:$version::LAX|$changes->{next_token})/
        : qr/^$version::LAX/;

    $preamble .= shift( @lines ) . "\n" while @lines && $lines[ 0 ] !~ $version_line_re;

    for my $l ( @lines ) {

        # Version & Date
        if ( $l =~ $version_line_re ) {
            my ( $v, $n ) = split m{\s[\W\s]*}, $l, 2;
            my $match = '';
            my $d;

            # munge date formats, save the remainder as note
            if ( $n ) {
                # unknown dates
                if ( $n =~ m{^($UNKNOWN_VALS)}i ) {
                    $d     = $1;
                    $match = $d;
                }
                # handle localtime-like timestamps
                elsif ( $n
                    =~ m{^(\D{3}\s+(\D{3})\s+(\d{1,2})\s+([\d:]+)?\D*(\d{4}))} )
                {
                    $match = $1;
                    if ( $4 ) {

                        # unfortunately ignores TZ data
                        $d = sprintf(
                            '%d-%02d-%02dT%sZ',
                            $5, $changes->{ months }->{ $2 },
                            $3, $4
                        );
                    }
                    else {
                        $d = sprintf( '%d-%02d-%02d',
                            $5, $changes->{ months }->{ $2 }, $3 );
                    }
                }

                # RFC 2822
                elsif ( $n
                    =~ m{^(\D{3}, (\d{1,2}) (\D{3}) (\d{4}) (\d\d:\d\d:\d\d) ([+-])(\d{2})(\d{2}))}
                    )
                {
                    $match = $1;
                    $d = sprintf(
                        '%d-%02d-%02dT%s%s%02d:%02d',
                        $4, $changes->{ months }->{ $3 },
                        $2, $5, $6, $7, $8
                    );
                }

                # handle dist-zilla style, puts TZ data in note
                elsif ( $n
                    =~ m{^((\d{4}-\d\d-\d\d)\s+(\d\d:\d\d(?::\d\d)?))(?:\s+[A-Za-z]+/[A-Za-z_-]+)} )
                {
                    $match = $1;
                    $d = sprintf( '%sT%sZ', $2, $3 );
                }

                # start with W3CDTF, ignore rest
                elsif ( $n =~ m{^($W3CDTF_REGEX)} ) {
                    $match = $1;
                    $d = $match;
                    $d =~ s{ }{T};
                    # Add UTC TZ if date ends at H:M, H:M:S or H:M:S.FS
                    $d .= 'Z' if length( $d ) == 16 || length( $d ) == 19 || $d =~ m{\.\d+$};
                }

                # clean date from note
                $n =~ s{^\Q$match\E\s*}{};
            }

            undef $d unless length $d;
            undef $n unless length $n;

            push @releases,
                CPAN::Changes::Release->new(
                version      => $v,
                date         => $d,
                _parsed_date => $match,
                note         => $n,
                );
            $ingroup = undef;
            $indent  = undef;
            next;
        }

        # Grouping
        if ( $l =~ m{^\s+\[\s*([^\[\]]+?)\s*\]\s*$} ) {
            $ingroup = $1;
            $releases[ -1 ]->add_group( $1 );
            next;
        }

        $ingroup = '' if !defined $ingroup;

        next if $l =~ m{^\s*$};

        if ( !defined $indent ) {
            $indent
                = $l =~ m{^(\s+)}
                ? '\s' x length $1
                : '';
        }

        $l =~ s{^$indent}{};

        # Inconsistent indentation between releases
        if ( $l =~ m{^\s} && !@{ $releases[ -1 ]->changes( $ingroup ) } ) {
            $l =~ m{^(\s+)};
            $indent = $1;
            $l =~ s{^\s+}{};
        }

        # Change line cont'd
        if ( $l =~ m{^\s} ) {
            $l =~ s{^\s+}{};
            my $changeset = $releases[ -1 ]->changes( $ingroup );
            $changeset->[ -1 ] .= " $l";
        }

        # Start of Change line
        else {
            $l =~ s{^[^[:alnum:]]+\s}{};    # remove leading marker
            $releases[ -1 ]->add_changes( { group => $ingroup }, $l );
        }

    }

    $changes->preamble( $preamble );
    $changes->releases( @releases );

    return $changes;
}

sub preamble {
    my $self = shift;

    if ( @_ ) {
        my $preamble = shift;
        $preamble =~ s{\s+$}{}s;
        $self->{ preamble } = $preamble;
    }

    return $self->{ preamble };
}

sub releases {
    my $self = shift;

    if ( @_ ) {
        $self->{ releases } = {};
        $self->add_release( @_ );
    }

    my $sort_function = sub {
        (   eval {
                ( my $v = $a->version ) =~ s/-TRIAL$//;
                version->parse( $v );
            }
                || 0
            ) <=> (
            eval {
                ( my $v = $b->version ) =~ s/-TRIAL$//;
                version->parse( $v );
            }
                || 0
            ) or ( $a->date || '' ) cmp( $b->date || '' );
    };

    my $next_token = $self->{ next_token };

    my $token_sort_function = sub {
        $a->version =~ $next_token - $b->version =~ $next_token
            or $sort_function->();
    };

    my $sort = $next_token ? $token_sort_function : $sort_function;

    return sort $sort values %{ $self->{ releases } };
}

sub add_release {
    my $self = shift;

    for my $release ( @_ ) {
        my $new = Scalar::Util::blessed $release ? $release
            : CPAN::Changes::Release->new( %$release );
        $self->{ releases }->{ $new->version } = $new;
    }
}

sub delete_release {
    my $self = shift;

    delete $self->{ releases }->{ $_ } for @_;
}

sub release {
    my ( $self, $version ) = @_;

    return unless exists $self->{ releases }->{ $version };
    return $self->{ releases }->{ $version };
}

sub delete_empty_groups {
    my $self = shift;

    $_->delete_empty_groups for $self->releases;
}

sub serialize {
    my $self = shift;
    my %args = @_;

    my %release_args;
    $release_args{ group_sort } = $args{ group_sort } if $args{ group_sort };

    my $output;

    $output = $self->preamble . "\n\n" if $self->preamble;

    my @r = $self->releases;
    @r = reverse @r unless $args{reverse};  # not a typo!

    $output .= $_->serialize( %release_args ) for @r;
    $output =~ s/\n\n+\z/\n/;

    return $output;
}

1;

__END__

=head1 NAME

CPAN::Changes - Read and write Changes files

=head1 SYNOPSIS

    # Load from file
    my $changes = CPAN::Changes->load( 'Changes' );

    # Create a new Changes file
    $changes = CPAN::Changes->new(
        preamble => 'Revision history for perl module Foo::Bar'
    );
    
    $changes->add_release( {
        version => '0.01',
        date    => '2009-07-06',
    } );

    $changes->serialize;

=head1 DESCRIPTION

It is standard practice to include a Changes file in your distribution. The 
purpose the Changes file is to help a user figure out what has changed since 
the last release.

People have devised many ways to write the Changes file. A preliminary 
specification has been created (L<CPAN::Changes::Spec>) to encourage module
authors to write clear and concise Changes.

This module will help users programmatically read and write Changes files that 
conform to the specification.

=head1 METHODS

=head2 new( %args )

Creates a new object using C<%args> as the initial data.

=over

=item C<next_token>

Used to passes a regular expression for a "next version" placeholder token.
See L</"DEALING WITH "NEXT VERSION" PLACEHOLDERS"> for an example of its usage.

=back

=head2 load( $filename, %args )

Parses C<$filename> as per L<CPAN::Changes::Spec>. 
If present, 
the optional C<%args> are passed to the underlaying call to
C<new()>.

=head2 load_string( $string, %args )

Parses C<$string> as per L<CPAN::Changes::Spec>.
If present, 
the optional C<%args> are passed to the underlaying call to
C<new()>.

=head2 preamble( [ $preamble ] )

Gets/sets the preamble section.

=head2 releases( [ @releases ] )

Without any arguments, a list of current release objects is returned sorted 
by ascending release date. When arguments are specified, all existing 
releases are removed and replaced with the supplied information. Each release 
may be either a regular hashref, or a L<CPAN::Changes::Release> object.

    # Hashref argument
    $changes->releases( { version => '0.01', date => '2009-07-06' } );
    
    # Release object argument
    my $rel = CPAN::Changes::Release->new(
        version => '0.01', date => '2009-07-06'
    );
    $changes->releases( $rel );

=head2 add_release( @releases )

Adds the release to the changes file. If a release at the same version exists, 
it will be overwritten with the supplied data.

=head2 delete_release( @versions )

Deletes all of the releases specified by the versions supplied to the method.

=head2 release( $version )

Returns the release object for the specified version. Should there be no 
matching release object, undef is returned.

=head2 serialize( reverse => $boolean, group_sort => \&sorting_function )

Returns all of the data as a string, suitable for saving as a Changes 
file.

If I<reverse> is provided and true, the releases are
printed in the reverse order (oldest to latest).

If I<group_sort> is provided, change groups are
sorted according to the given function. If not,
groups are sorted alphabetically.

=head2 delete_empty_groups( )

Deletes change groups without changes in all releases.

=head1 DEALING WITH "NEXT VERSION" PLACEHOLDERS

In the working copy of a distribution, it's not uncommon 
to have a "next release" placeholder section as the first entry
of the C<Changes> file. 

For example, the C<Changes> file of a distribution using
L<Dist::Zilla> and L<Dist::Zilla::Plugin::NextRelease> 
would look like:


    Revision history for Foo-Bar

    {{$NEXT}}
        - Add the 'frobuscate' method.

    1.0.0     2010-11-30
        - Convert all comments to Esperanto.

    0.0.1     2010-09-29
        - Original version unleashed on an unsuspecting world


To have C<CPAN::Changes> recognizes the C<{{$NEXT}}> token as a valid
version, you can use the C<next_token> argument with any of the class' 
constructors. Note that the resulting release object will also
be considered the latest release, regardless of its timestamp. 

To continue with our example:

    # recognizes {{$NEXT}} as a version
    my $changes = CPAN::Changes->load( 
        'Changes',
        next_token => qr/{{\$NEXT}}/,
    );

    my @releases = $changes->releases;
    print $releases[-1]->version;       # prints '{{$NEXT}}'

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Spec>

=item * L<Test::CPAN::Changes>

=back

=head2 SIMILAR MODULES

=over 4

=item * L<Module::Metadata::Changes>

=item * L<Module::Changes>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
