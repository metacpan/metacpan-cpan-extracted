package WWW::PAUSE::CleanUpHomeDir;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use Carp;
use URI;
use WWW::Mechanize;
use HTML::TokeParser::Simple;
use File::Basename;
use Devel::TakeHashArgs;
use Sort::Versions;
use base 'Class::Accessor::Grouped';
__PACKAGE__->mk_group_accessors(simple => qw(
    error
    last_list
    deleted_list
    _mech
    _is_use_http
));

sub new {
    my $self = bless {}, shift;

    my ( $login, $pass ) = splice @_, 0, 2;

    croak 'Missing mandatory PAUSE login argument'
        unless defined $login;

    croak 'Missing mandatory PAUSE password argument'
        unless defined $pass;

    get_args_as_hash(\@_, \ my %args, { timeout => 30 } )
        or croak $@;

    $self->_is_use_http( $args{use_http} );
    $self->_mech( WWW::Mechanize->new( timeout => $args{timeout} ) );
    $self->_mech->credentials( $login, $pass );

    return $self;
}

sub fetch_list {
    my $self = shift;

    $self->$_(undef) for qw(last_list error);

    my $uri =
    URI->new(
        ($self->_is_use_http ? 'http' : 'https')
            . '://pause.perl.org/pause/authenquery?ACTION=delete_files'
    );

    my $mech = $self->_mech;
    my $response = $mech->get($uri);
    if ( $response->is_success ) {
        return $self->last_list( $self->_parse_list( $mech->content ) );
    }
    else {
        return $self->_set_error( $response, 'net' );
    }
}

sub list_scheduled {
    my $self = shift;

    my $list_ref = $self->last_list;

    $list_ref = $self->fetch_list
        unless ref $list_ref eq 'HASH';

    return unless defined $list_ref;

    my @scheduled_keys = grep {
        $list_ref->{$_}{status} =~ /Scheduled for deletion/
    } keys %$list_ref;

    return sort @scheduled_keys
        if wantarray;

    return { map { $_ => $list_ref->{$_} } @scheduled_keys };
}

sub list_old {
    my $self = shift;

    my $list_ref = $self->last_list;

    $list_ref = $self->fetch_list
        unless ref $list_ref eq 'HASH';

    return unless defined $list_ref;

    my @suf = qw(.meta .readme .tar.gz .tgz .tar .gz .zip .bz2 .bz );
    my $scheduled_re = qr/Scheduled for deletion/;
    my $extracted_re = qr/\.(?:readme|meta)$/;
    my %files = map { (fileparse $_, @suf )[0,2] }
                    grep {
                        $_ ne 'CHECKSUMS'
                        and $_ !~ /$extracted_re/
                        and $list_ref->{$_}{status} !~ /$scheduled_re/
                    } keys %$list_ref;

    my @files = sort {
        my ($na, $va) = $a =~ /(.+)-(\d.+)/;
        my ($nb, $vb) = $b =~ /(.+)-(\d.+)/;
        $na cmp $nb || versioncmp($va, $vb);
    } grep !/
        -(?!.*-)  # last dash in the filename
        .*(TRIAL|_) # trial versions
    /x, keys %files;

    my @old;
    my $re = qr/([^.]+)-/;
    for ( 0 .. $#files-1) {
        my $name      = ($files[ $_   ] =~ /$re/)[0];
        my $next_name = ($files[ $_+1 ] =~ /$re/)[0];
        next
            unless ( defined $name and defined $next_name )
                or $next_name =~ /
                    -(?!.*-)  # last dash in the filename
                    .*(TRIAL|_) # trial versions
                /x;

        push @old, $files[$_]
            if $name eq $next_name;
    }

    return sort @old
        if wantarray;

    return { map { $_ => $files{$_} } @old  };
}

sub clean_up {
    my $self = shift;
    my $only_these_ref = shift;

    $self->$_(undef) for qw(last_list deleted_list list_old);
    # make sure ->list_old reloads the page to avoid surprises with mech

    my $to_delete_ref = $self->list_old;
    if ( defined $only_these_ref and @$only_these_ref ) {
        $to_delete_ref = {
            map { $_ => $to_delete_ref->{$_} }
                @$only_these_ref
        };
    }

    my @files = map +("$_$to_delete_ref->{$_}", "$_.meta", "$_.readme"),
                    sort keys %$to_delete_ref;

    return $self->_set_error('No files to delete')
        unless @files;

    my $mech = $self->_mech;
    $mech->form_number(1); # we already loaded the page from ->list_old

    $mech->tick('pause99_delete_files_FILE', $_ )
        for @files;

    my $response = $mech->click('SUBMIT_pause99_delete_files_delete');

    if ( $response->is_success ) {
        $self->last_list(undef); # reset list again it's too old now

        return $self->deleted_list( \@files );
    }
    else {
        return $self->_set_error( $response, 'net' );
    }
}

sub undelete {
    my $self = shift;
    my $only_these_ref = shift;

    my @files = @{ $self->deleted_list || [] };
    if ( defined $only_these_ref and @$only_these_ref ) {
        @files = @$only_these_ref;
    }

    return $self->_set_error('No files to undelete')
        unless @files;

    my $uri =
    URI->new(
        ($self->_is_use_http ? 'http' : 'https')
            . '://pause.perl.org/pause/authenquery?ACTION=delete_files'
    );

    my $mech = $self->_mech;
    my $response = $mech->get($uri);
    return $self->_set_error( $response, 'net' )
        unless $mech->success;

    $mech->form_number(1); # we already loaded the page from ->list_old
    $mech->tick('pause99_delete_files_FILE', $_)
        for @files;

    $response = $mech->click('SUBMIT_pause99_delete_files_undelete');

    if ( $response->is_success ) {
        $self->deleted_list(undef); # we successfully undeleted all these

        return \@files;
    }
    else {
        return $self->_set_error( $response, 'net' );
    }
}

sub _parse_list {
    my ( $self, $content ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my %data;
    my %nav;
    my $current_line = 0;
    @nav{ qw(level start get_text) } = (0) x 3;
    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('pre') ) {
            @nav{ qw(level start) } = ( 1, 1 );
        }
        elsif ( $t->is_end_tag('pre') ) {
            @nav{ qw(level start is_success) } = ( 2, 0, 1);
            last;
        }
        elsif ( $nav{start} == 1 and $t->is_start_tag('span') ) {
            $current_line = $t->get_attr('class');
            @nav{ qw(level get_text) } = ( 3, 1 );
        }
        elsif ( $nav{get_text} == 1 and $t->is_text ) {
            if ( my ( $name, $size, $status ) = $t->as_is
                    =~ /^\s*(\S+)\s+(\d+)\s+(.+)/s
            ) {
                $data{$name} = {
                    size    => $size,
                    status  => $status,
                };

                @nav{ qw(level get_text) } = ( 4, 0 );
            }
        }
    }
    croak "Parser error! (level: $nav{level}) Content: $content"
        unless $nav{is_success};

    return \%data;
}

sub _set_error {
    my ( $self, $error, $type ) = @_;
    if ( defined $type and $type eq 'net' ) {
        $self->error( 'Network error: ' . $error->status_line );
    }
    else {
        $self->error( $error );
    }
    return;
}

1;
__END__

=encoding utf8

=for stopwords AnnoCPAN Haryanto Mengu Mengué RT SHARYANTO dists occured undeletion versioning dir

=head1 NAME

WWW::PAUSE::CleanUpHomeDir - the module to clean up old dists from your PAUSE home directory

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use strict;
    use warnings;

    use WWW::PAUSE::CleanUpHomeDir;

    my $pause = WWW::PAUSE::CleanUpHomeDir->new( 'PAUSE_ID', 'PASSWORD' );

    $pause->fetch_list
        or die $pause->error;

    my @old_files = $pause->list_old;
    die "No old files were found\n"
        unless @old_files;

    print @old_files . " old files were found:\n" .
            join "\n", @old_files, '';

    print "\nEnter dist names you want to delete or just hit ENTER to delete"
            . " delete all of them\n";

    my @to_delete = split ' ', <STDIN>;
    my $deleted_ref = $pause->clean_up(\@to_delete)
        or die $pause->error;

    print "Deleted:\n" . join "\n", @$deleted_ref, '';

    print "\nWould you like to undelete any of these files? "
            . "If not, just hit ENTER\n";

    my @to_undelete = split ' ', <STDIN>;
    die "Terminating..\n"
        unless @to_undelete;

    $pause->undelete(\@to_undelete)
        or die $pause->error;

    print "Success..\n";

=for html  </div></div>

=head1 DESCRIPTION

The module provides means to clean up your PAUSE home directory from
old distributions with ability to undelete files if you so prefer.

=head1 WARNING

The module was tested for me and it works for me. The test suite does
not include live tests to determine if it actually deletes anything.
Depending on the versioning system you are using for your files it might
not work for you. I recommend that you double check (at least on first runs)
if the right files were deleted.

=head1 CONSTRUCTOR

=head2 new

    my $pause = WWW::PAUSE::CleanUpHomeDir->new(
        'PAUSE_ID',
        'PAUSE_password',
        use_http => 1, # optional; by default uses HTTPS
        timeout => 10, # optional; default is 30
    );

Constructs and returns a fresh WWW::PAUSE::CleanUpHomeDir object. Takes
two mandatory and one optional arguments. Optional argument is passed
as a key/value pair. The first argument is your PAUSE author ID, the
second argument is your PAUSE password.

=head3 C<use_http>

    my $pause = WWW::PAUSE::CleanUpHomeDir->new(
        'PAUSE_ID',
        'PAUSE_password',
        use_http => 1, # optional; by default uses HTTPS
    );

B<Optional>. As of version 0.003, this module will use HTTPS protocol
when dealing with PAUSE. If you want to go back to using plain HTTP,
set C<use_http> argument to a true value. B<By default:> not specified
(i.e. will use HTTPS).

=head3 C<timeout>

    my $pause = WWW::PAUSE::CleanUpHomeDir->new(
        'PAUSE_ID',
        'PAUSE_password',
        timeout => 10, # optional; default is 30
    );

B<Optional>. Specifies the C<timeout> (in seconds) for dealing with PAUSE
and it will B<default to> C<30> if not specified.

=head1 METHODS

=head2 fetch_list

    my $list_of_your_files_ref = $pause->fetch_list
        or die $pause->error;


    $VAR1 = {
        'Net-OBEX-Packet-Request-0.002.readme' => {
            'status' => 'Scheduled for deletion (due at Fri, 21 Mar 2008 02:42:37 GMT)',
            'size' => '871'
        },
        'Net-OBEX-Response-0.002.tar.gz' => {
            'status' => 'Sun, 02 Mar 2008 15:56:19 GMT',
            'size' => '7618'
        },
        'Net-OBEX-Response-0.002.readme' => {
            'status' => 'Sun, 02 Mar 2008 15:55:08 GMT',
            'size' => '834'
        },
    }

Takes no arguments. On failure returns either C<undef> or an empty list
depending on the context and the reason for failure will be available via
C<error()> method.
On success returns a hashref with keys being the files in your PAUSE home
dir and values being 2-key hashrefs with keys being C<size> and C<status>.
The C<size> is the size of that particular file. The C<status> will contain
the time of creation or I<Scheduled for deletion...>  if the
file is scheduled for deletion.

=head2 last_list

    my $last_list_ref = $pause->last_list;

Must be called after a successful call to C<fetch_list()> method.
Takes no arguments, returns the same hashref as last call to C<fetch_list()>
returned.

=head2 list_scheduled

    my $scheduled_for_deletion_ref = $pause->list_scheduled
        or die $pause->error;

    my @scheduled_for_deletion = $pause->list_scheduled
        or die $pause->error;

Takes no arguments. If called prior to the call to C<fetch_list()> will do
so automatically and if that fails will return either undef or an empty list
(depending on the context) and the reason for the failure will be available
via C<error()> method.

In scalar context returns a hashref of all the files
which are scheduled for deletion. The format of that hashref is the same
as the return value of C<fetch_list()> method (with the exception that
all C<status> keys will contain I<Scheduled for deletion..>). In list
context returns a sorted list of filenames which are scheduled for deletion.
In other words calling C<list_scheduled()> in list context is the same
as doing C<< @scheduled = sort keys %{ scalar $pause->list_scheduled } >>

=head2 list_old

    my $old_dists_ref = $pause->list_old
        or die $pause->error;

    my @old_dists = $pause->list_old
        or die $pause->error;

Takes no arguments. If called prior to the call to C<fetch_list()> will do
so automatically and if that fails will return either undef or an empty list
(depending on the context) and the reason for the failure will be available
via C<error()> method.

In list context returns a sorted list of B<distributions> for
which the module sees newer versions. In scalar context returns a hashref
with keys being distribution names and values being the extensions of the
archive containing the distribution.

=head2 clean_up

    my $deleted_files_ref = $pause->clean_up
        or die $pause->error;

    my $deleted_files_ref = $pause->clean_up( [ qw(Dist1 Dist2 etc) ] )
        or die $pause->error;

Instructs the object to delete any distributions for which never versions
were found. In other words will delete distributions which C<list_old()>
returns. On failure will return either C<undef> or an empty list (depending
on the context) and the reason for failure will be available via C<error()>
method. On success returns an arrayref of deleted B<files> (archive
containing distribution, C<.meta> files and C<.readme> file). Takes one
optional argument which must be an arrayref containing names of
B<distributions> to delete, if not specified will delete all distributions
for which never versions are available. B<Note:> a call to this method
will reset the list stored in C<last_list()>, it will be set to C<undef>.
B<Note 2:> if either the distribution you specified does no exist
(in your PAUSE home dir) or C<.meta> or C<.readme> files do not exist
the call will cause L<WWW::Mechanize> to croak on you.

=head2 deleted_list

    my $last_deleted_files_ref = $pause->deleted_list;

Must be called after a successful call to C<clean_up()>.
Takes no arguments, returns the same return value last call to C<clean_up()>
returned.

=head2 undelete

    my $undeleted_list_ref = $pause->undelete
        or die $pause->error;

    my $undeleted_list_ref = $pause->undelete( [ qw(Foo.tar.gz Foo.meta Foo.readme) ] )
        or die $pause->error;

Instructs the object to undelete certain files. On failure will return
either C<undef> or an empty list (depending on the context) and the
reason for failure will be available via C<error()> method. On success
returns an arrayref of files which were undeleted. Takes one optional
argument which must be an arrayref of files to undelete, if the argument
is not specified will use list stored in C<deleted_list()>.
B<Note:> a successful call to this method will reset list stored in
C<deleted_list()>
but will B<NOT> reset list stored in C<last_list()>, which will be incorrect
after undeletion (well, only the C<status> keys will present incorrect
status of the files).
B<Note 2:> if either the file you specified does no exist
(in your PAUSE home dir) or files stored in C<deleted_list()> do not exist
(later is unlikely) the call will cause L<WWW::Mechanize> to croak on you.

=head2 error

    my $last_error = $pause->error;

Takes no arguments, returns last error (if any) which occurred during
the calls to other methods.

=head1 EXAMPLES

The C<examples> directory of this distribution contains a script which
can be used for cleaning up your PAUSE home directory.

=head1 SEE ALSO

L<http://pause.perl.org>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-PAUSE-CleanUpHomeDir>

=for html  </div></div>

=head1 BUGS AND CAVEATS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

I have only one PAUSE account which is inadequate for proper testing.
Double check the results to make sure the module works properly for you
when first using it.

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-PAUSE-CleanUpHomeDir/issues>

If you can't access GitHub, you can email your request
to C<bug-www-pause-cleanuphomedir at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 CONTRIBUTORS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=over 4

=item B<Steven 'SHARYANTO' Haryanto> -- submitted a patch for correct version sorting

=item B<Olivier 'DOLMEN' Mengué> -- submitted bug report requesting HTTPS support

=back

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut