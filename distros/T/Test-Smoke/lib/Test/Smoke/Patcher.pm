package Test::Smoke::Patcher;
use strict;

our $VERSION = '0.012';

use base 'Exporter';
use File::Spec;
use Cwd;

use Test::Smoke::Util qw( get_regen_headers );

our @EXPORT = qw( &TRY_REGEN_HEADERS );

sub MAX_FLAG_COUNT    () { 16 }
sub ALL_FLAGS         () { (2**MAX_FLAG_COUNT) - 1 }
sub TRY_REGEN_HEADERS () { 1 }

my %CONFIG = (
    df_ddir     => File::Spec->rel2abs( cwd ),
    df_fdir     => undef,
    df_pfile    => undef,
    df_patchbin => 'patch',
    df_popts    => '',       # '-p1' is added in call_patch()
    df_flags    => 0,
    df_regen    => 1,        # regen => set/unset TRY_REGEN_HEADERS in flags
    df_oldpatch => 0,
    df_v        => 0,

    valid_type => { single => 1, multi => 1 },
    single     => [qw( pfile patchbin popts flags regen oldpatch )],
    multi      => [qw( pfile patchbin popts flags regen oldpatch )],
);

=head1 NAME

Test::Smoke::Patcher - OO interface to help patching the source-tree

=head1 SYNOPSIS

    use Test::Smoke::Patcher;

    my $patcher = Test::Smoke::Patcher->new( single => {
        ddir  => $build_dir,
        pfile => $patch,
        popts => '-p1',
        v     => 1, # 0..2
    });
    $patcher->patch;

or

    my $patcher = Test::Smoke::Patcher->new( multi => {
        ddir  => $buildir,
        pfile => $patch_info,
        v     => 1, #0..2
    });
    $patcher->patch;

=head1 DESCRIPTION

Okay, you will need a working B<patch> program, which I believe is available
for most platforms perl runs on.

There are two ways to initialise the B<Test::Smoke::Patcher> object.

=over 4

=item B<single> mode

The B<pfile> attribute is a pointer to a I<single> patch.
There are four (4) ways to specify that patch.

=over 4

=item I<refernece to a SCALAR>

The scalar holds the complete patch as literal text.

=item I<reference to an ARRAY>

The array holds a list of lines (with newlines) that make up the
patch as literal text (C<< $patch = join "", @$array_ref >>).

=item I<reference to a GLOB>

You passed an opened filehandle to a file containing the patch.

=item I<filename>

If none of the above apply, it is assumed you passed a filename.
Relative paths are rooted at the builddir (B<ddir> attribute).

=back

=item B<multi> mode

The B<pfile> attribute is a pointer to a recource that contains filenames
of patches.
The format of this recource is one filename per line optionally followed
by a semi-colon (;) and switches for the patch program.

The patch-resource can also be specified in four (4) ways.

=over 4

=item I<reference to a SCALAR>

=item I<reference to an ARRAY>

=item I<reference to a GLOB>

=item I<filename>

=back

=back

=head2 TRY_REGEN_HEADERS

Constant: 1

=head2 MAX_FLAG_COUNT

Constant: 16

=head2 ALL_FLAGS

Constant: 2**MAX_FLAG_COUNT) - 1

=head1 METHODS

=over 4

=cut

=item Test::Smoke::Patcher->new( $type => \%args );

C<new()> crates the object. Valid types are B<single> and B<multi>.
Valid keys for C<%args>:

    * ddir:     the build directory
    * fdir:     the intermediate forest dir (preferred)
    * pfile:    path to either the patch (single) or a textfile (multi)
    * popts:    options to pass to 'patch' (-p1)
    * patchbin: full path to the patch binary (patch)
    * regen:    flag to set/unset the TRY_REGEN_HEADERS flag
    * v:        verbosity 0..2

=cut

sub new {
    my $proto = shift;
    my  $class = ref $proto || $proto;

    my $type = lc shift;
    unless ( $type && exists $CONFIG{valid_type}->{ $type } ) {
        defined $type or $type = 'undef';
        require Carp;
        Carp::croak( "Invalid Patcher-type: '$type'" );
    }

    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } ( v => ddir => fdir => @{ $CONFIG{ $type } } );
    $fields{pdir} = File::Spec->rel2abs(
        defined $fields{fdir} ? $fields{fdir} : $fields{ddir}
    );
    $fields{ptype} = $type;
    if ($fields{regen}) {
        $fields{flags} = ($fields{flags} | TRY_REGEN_HEADERS) & ALL_FLAGS;
    }
    else {
        $fields{flags} = ($fields{flags} & ~TRY_REGEN_HEADERS) & ALL_FLAGS;
    }

    bless { %fields }, $class;
}

=item Test::Smoke::Patcher->config( $key[, $value] )

C<config()> is an interface to the package lexical C<%CONFIG>,
which holds all the default values for the C<new()> arguments.

With the special key B<all_defaults> this returns a reference
to a hash holding all the default values.

=cut

sub config {
    my $dummy = shift;

    my $key = lc shift;

    if ( $key eq 'all_defaults' ) {
        my %default = map {
            my( $pass_key ) = $_ =~ /^df_(.+)/;
            ( $pass_key => $CONFIG{ $_ } );
        } grep /^df_/ => keys %CONFIG;
        return \%default;
    }

    return undef unless exists $CONFIG{ "df_$key" };

    $CONFIG{ "df_$key" } = shift if @_;

    return $CONFIG{ "df_$key" };
}

=item $patcher->patch

C<patch()> is a simple dispatcher.

=cut

sub patch {
    my $self = shift;

    my $method = "patch_$self->{ptype}";
    my $ret = $self->$method( @_ );
    $ret &&= $self->perl_regen_headers;

    if ( $self->{fdir} ) { # This is a forest setup, re-sync
        require Test::Smoke::Syncer;
        my %options = (
            hdir => $self->{fdir},
            ddir => $self->{ddir},
            v    => $self->{v},
        );
        my $resync = Test::Smoke::Syncer->new( hardlink => %options );
        $resync->sync;
    }
    return $ret;
}

=item perl_regen_headers( )

Try to run F<regen_headers.pl> if the flag is set.

=cut

sub perl_regen_headers {
    my $self = shift;
    return 1 unless $self->{flags} & TRY_REGEN_HEADERS;

    my $regen_headers = get_regen_headers( $self->{pdir} );
    my $regen_perly = $self->{perly}
        ? qq|$^X "| . File::Spec->catfile( $self->{pdir}, 'regen_perly.pl' ).
          qq|"|
        : "";
    my @regens = grep $_ => ( $regen_headers, $regen_perly );
    for my $regen ( @regens ) {
        my $cwd = cwd;
        chdir $self->{pdir} or return;
        local *RUN_REGEN;
        if ( open RUN_REGEN, "$regen |" ) {
            $self->{v} and print "Started [$regen]\n";
            while ( <RUN_REGEN> ) {
                $self->{v} and print;
            }
            close RUN_REGEN or do {
                require Carp;
                Carp::carp( "Error while running [$regen]" );
                return;
            };
        } else {
            require Carp;
            Carp::carp( "Could not fork [$regen]" );
            return;
        }
        chdir $cwd;
    }
    return 1;
}

=item $patcher->patch_single( )

C<patch_single()> checks if the B<pfile> attribute is a plain scalar
or a ref to a scalar, array, glob. In the first case this is taken to
be a filename.  A GLOB-ref is a filehandle, the other two are taken to
be literal content.

=cut

sub patch_single {
    my $self = shift;

    my $pfile = shift || $self->{pfile};

    local *PATCH;
    my $content;
    if ( ref $pfile eq 'SCALAR' ) {
        $content = $$pfile;
        $self->{pfinfo} ||= 'internal content';
    } elsif ( ref $pfile eq 'ARRAY' ) {
        $content = join "", @$pfile;
        $self->{pfinfo} ||= 'internal content';
    } elsif ( ref $pfile eq 'GLOB' ) {
        *PATCH = *$pfile;
        $content = do { local $/; <PATCH> };
        $self->{pfinfo} ||= 'file content';
    } else {
        my $full_name = File::Spec->file_name_is_absolute( $pfile )
            ? $pfile : File::Spec->rel2abs( $pfile, $self->{pdir} );

        $self->{pfinfo} = $full_name;
        open PATCH, "< $full_name" or do {
            require Carp;
            Carp::croak( "Cannot open '$full_name': $!" );
        };
        $content = do { local $/; <PATCH> };
        close PATCH;
    }

    $self->{v} and print "Get patch from $self->{pfinfo}\n";
    $self->call_patch( \$content, @_ );
}

=item $patcher->patch_multi( )

C<patch_multi()> checks the B<pfile> attribute is a plain scalar
or a ref to a scalar, array, glob. In the first case this is taken to
be a filename.  A GLOB-ref is a filehandle, the other two are taken to
be literal content.

=cut

sub patch_multi {
    my $self = shift;

    my $pfile = shift || $self->{pfile};

    local *PATCHES;
    my @patches;
    if ( ref $pfile eq 'SCALAR' ) {
        @patches = split /\n/, $$pfile;
        $self->{pfinfo} ||= 'internal content';
    } elsif ( ref $pfile eq 'ARRAY' ) {
        chomp( @patches = @$pfile );
        $self->{pfinfo} ||= 'internal content';
    } elsif ( ref $pfile eq 'GLOB' ) {
        *PATCHES = *$pfile;
        chomp( @patches = <PATCHES> );
        $self->{pfinfo} ||= 'file content';
    } else {
        my $full_name = File::Spec->file_name_is_absolute( $pfile )
            ? $pfile : File::Spec->rel2abs( $pfile, $self->{pdir} );
        $self->{pfinfo} = $full_name;
        open PATCHES, "< $full_name" or do {
            require Carp;
            Carp::croak( "Cannot open '$self->{pfile}': $!" );
        };
        chomp( @patches = <PATCHES> );
        close PATCHES;
    }

    $self->{v} and print "Get patchinfo from $self->{pfinfo}\n";

    my $ok = 1;
    foreach my $patch ( @patches ) {
        next if $patch =~ /^\s*[#]/;
        next if $patch =~ /^\s*$/;
        if ( $patch =~ /^\s*!\s*perly$/ ) {
            $self->{perly} = 1;
            next;
        }
        my( $filename, $switches, $descr ) = split /\s*;\s*/, $patch, 3;
        $descr = $descr ? $descr . " ($filename)" : $filename;
        eval { $self->patch_single( $filename, $switches, $descr ) };
        if ( $@ ) {
            require Carp;
            Carp::carp( "[$filename] $@" );
            $ok = 0;
        }
    }
    return $ok;
}

=item $self->_make_opts( $switches )

C<_make_opts()> just creates a string of options to pass to the
B<patch> program. Some implementations of patch do not grog '-u',
so be careful!

=cut

sub _make_opts {
    my $self = shift;
    @_ = grep defined $_ => @_;
    my $switches = @_ ? join " ", @_ : "";

    my $opts = $switches || $self->{popts} || "";
    $opts .= " -p1" unless $opts =~ /-[a-zA-Z]*p\d/;
#    $opts .= " -b" unless $opts =~ /-[a-zA-Z]*b/i;
    $opts .= " --verbose" if $self->{v} > 1 && !$self->{oldpatch};

    return $opts;
}

=item $patcher->call_patch( $ref_to_content )

C<call_patch()> opens a pipe to the B<patch> program and prints
C<< $$ref_to_content >> to it. It will Carp::croak() on any error!

=cut

sub call_patch {
    my( $self, $ref_to_content, $switches, $descr ) = @_;

    local *PATCHBIN;

    my $opts = $self->_make_opts( $switches );

    my $redir = $self->{v} ? "" : ">" . File::Spec->devnull . " 2>&1";

    my $cwd = cwd();
    chdir $self->{pdir} or do {
        require Carp;
        Carp::croak( "Cannot chdir($self->{pdir}): $!" );
    };

    # patch is verbose enough if $self->{v} == 1
    $self->{v} > 1 and
        print "[$self->{pfinfo}] | $self->{patchbin} $opts $redir\n";

    if ( open PATCHBIN, "| $self->{patchbin} $opts $redir" ) {
        binmode PATCHBIN;
        print PATCHBIN $$ref_to_content;
        close PATCHBIN or do {
            require Carp;
            Carp::croak( "Error while patching from '$self->{pfinfo}': $!" );
        };
    } else {
        require Carp;
        Carp::croak( "Cannot fork ($self->{patchbin}): $!" );
    }

    # Add a line to patchlevel.h if $descr
    if ( defined $descr ) {
        require Test::Smoke::Util;
        Test::Smoke::Util::set_local_patch( $self->{pdir}, $descr );
    }

    chdir $cwd or do {
        require Carp;
        Carp::croak( "Cannot chdir($cwd) back: $!" );
    };
}

=back

=head1 SEE ALSO

L<patch>, L<Test::Smoke::Syncer::Snapshot>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
