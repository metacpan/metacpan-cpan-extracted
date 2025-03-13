package Test::Smoke::FTPClient;
use strict;

use Net::FTP;
use Cwd;
use File::Path;
use File::Spec::Functions qw( :DEFAULT abs2rel rel2abs );
use Test::Smoke::Util qw( clean_filename time_in_hhmm );

our $VERSION = '0.011';

my %CONFIG = (
    df_fhost    => undef,
    df_fport    => 21,
    df_fuser    => 'anonymous',
    df_fpasswd  => '',
    df_v        => 1,
    df_fpassive => 1,
    df_ftype    => undef,

    valid      => [qw( fport fuser fpasswd fpassive ftype )],
);
my @sn = qw( B KB MB GB TB );

BEGIN { eval qq/use Time::HiRes qw( time ) / }

=head1 NAME

Test::Smoke::FTPClient - Implement a mirror like object

=head1 SYNOPSIS

    use Test::Smoke::FTPClient;

    my $server = 'ftp.example.com';
    my $fc = Test::Smoke::FTPClient->new( $server );

    my $sdir = '/';
    my $ddir = '~/perlsmoke/perl-current';
    my $cleanup = 1; # like --delete for rsync

    $fc->connect;
    $fc->mirror( $sdir, $ddir, $cleanup );

    $fc->bye;

=head1 DESCRIPTION

This solution is B<slow>, you'd better use B<rsync>!

=head1 METHODS

=head2 Test::Smoke::FTPClient->new( $server[, %options] )

Create a new object with option checking:

    * fuser
    * fpasswd
    * v
    * fpassive
    * ftype

=cut

sub  new {
    my $class = shift;

    my $server = shift;
    my $port = shift;

    unless ( $server ) {
        require Carp;
        Carp::croak( "Usage: Test::Smoke::FTPClient->new( \$server, \$port )" );
    };
    unless ( $port ) {
        require Carp;
        Carp::croak( "Usage: Test::Smoke::FTPClient->new( \$server, \$port )" );
    };


    my %args_raw = @_ ? UNIVERSAL::isa( $_[0], 'HASH' ) ? %{ $_[0] } : @_ : ();

    my %args = map {
        ( my $key = $_ ) =~ s/^-?(.+)$/lc $1/e;
        ( $key => $args_raw{ $_ } );
    } keys %args_raw;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } ( v => @{ $CONFIG{ valid } } );
    $fields{fhost} = $server;
    $fields{fport} = $port;
    $fields{v} ||= 0;

    return bless \%fields, $class;

}

=head2 $ftpclient->connect( )

Returns true for success after connecting and login.

=cut

sub connect {
    my $self = shift;

    $self->{v} and print "Connecting to '$self->{fhost}' with port '$self->{fport}' ";
    $self->{client} = Net::FTP->new( $self->{fhost},
        Port    => $self->{fport},
        Passive => $self->{fpassive},
        Debug   => ( $self->{v} > 2 ),
    );
    unless ( $self->{client} ) {
        $self->{error} = $@;
        $self->{v} and print "NOT OK ($self->{error})\n";
        return;
    }
    $self->{v} and print "OK\n";

    $self->{v} and print "Authenticating ";
    unless ( $self->{client}->login( $self->{fuser}, $self->{fpasswd} ) ) {
        $self->{error} = $@ ||
            "Could not login($self->{fuser}) on $self->{fhost}";
        $self->{v} and print "NOT OK ($self->{error})\n";
        return;
    }
    $self->{v} and print "OK\n";

    return 1;
}

=head2 $client->mirror( $sdir, $ddir )

Set-up the environment and call C<__do_mirror()>

=cut

sub mirror {
    my $self = shift;
    return unless UNIVERSAL::isa( $self->{client}, 'Net::FTP' );

    my( $fdir, $ddir, $cleanup ) = @_;
    my $cwd = cwd();
    # Get the local directory sorted
    $ddir = rel2abs( $ddir );
    mkpath( $ddir, $self->{v} ) unless -d $ddir;
    unless ( chdir $ddir ) {
        $self->{error} = "Cannot chdir($ddir): $!";
        return;
    }
    my $lroot = catdir( $ddir, updir );
    chdir $lroot and $lroot = cwd() and chdir $cwd;

    if ( $self->{ftype} && $self->{client}->can( $self->{ftype} ) ) {
        my $ftype = $self->{ftype};
        eval '$self->{client}->$ftype';
    }
    my( $totsize, $tottime ) = ( 0, 0 );
    $self->{v} and print "Start mirror to: $ddir\n";
    my $start = time;
    my $ret = __do_mirror( $self->{client}, $fdir, $ddir, $lroot,
                           $self->{v}, $cleanup, $totsize, $tottime );
    my $ttime = time - $start;
    $tottime or $tottime = 0.001;
    my $speed = $totsize / $tottime;
    my $ord = 0;
    while ( $speed > 1024 ) { $speed /= 1024; $ord++ }
    $self->{v} and printf "Mirror took %s \@ %.3f %s\n",
                          time_in_hhmm( $ttime ), $speed, $sn[ $ord ];
    chdir $cwd;
    return $ret;
}

=head2 $client->bye

Disconnect from the FTP-server and cleanup the Net::FTP client;

=cut

sub bye {
    my $self = shift;
    $self->{client}->quit;
}

=head2 Test::Smoke::FTPClient->config( $key[, $value] )

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

=head2 __do_mirror( $ftp, $ftpdir, $localdir, $lroot, $verbose, $cleanup )

Recursive sub to mirror a tree from an FTP server.

=cut

{
my $mirror_ok = 1;
sub __do_mirror {
    my( $ftp, $ftpdir, $localdir, $lroot, $verbose, $cleanup,
        $totsize, $tottime ) = @_;
    $verbose ||= 0;

    $ftp->cwd( $ftpdir );
    $verbose > 1 and printf "Entering %s\n", $ftp->pwd;

    my @list = dirlist( $ftp, $verbose );

    foreach my $entry ( sort { $a->{type} cmp $b->{type} ||
                               $a->{name} cmp $b->{name} } @list ) {

        if ( $entry->{type} eq 'l' ) {
        } elsif ( $entry->{type} eq 'd' ) {
            $entry->{name} =~ m/^\.\.?$/ and next;
            my $new_locald = File::Spec->catdir( $localdir, $entry->{name} );
            unless ( -d $new_locald ) {
                eval { mkpath( $new_locald, $verbose, $entry->{mode} ) } or
                    return;
                $@ and return;
            }
            chdir $new_locald;
            $mirror_ok &&= __do_mirror( $ftp, $entry->{name},
                                        $new_locald, $lroot, $verbose,
                                        $cleanup, $totsize, $tottime );
            $entry->{time} ||= $entry->{date};
            utime $entry->{time}, $entry->{time}, $new_locald;
            $ftp->cwd( '..' );
            chdir File::Spec->updir;
            $verbose > 1 and print "Leaving '$entry->{name}' [$new_locald]\n";
        } else {
            $entry->{time}  = $ftp->mdtm( $entry->{name} ); #slow down
            my $fname = clean_filename( $entry->{name} );

            my $destname = catfile( $localdir, canonpath($fname) );

            my $skip;
            if ( -e $destname ) {
                my( $l_size, $l_mode, $l_time ) = (stat $destname)[7, 2, 9];
                $l_mode &= 07777;
                $skip = ($l_size == $entry->{size}) &&
                        ($l_mode == $entry->{mode}) &&
		        ($l_time == $entry->{time});
            }
            unless ( $skip ) {
                1 while unlink $destname;
                $verbose and printf "%s: %d/", abs2rel( $destname, $lroot ),
                                               $entry->{size};
                my $start = time;
                my $dest = $ftp->get( $entry->{name}, $destname );
                my $t_time = time - $start;
                $dest or $mirror_ok = 0, return;

                $t_time or $t_time = 0.001; # avoid div by zero
                my $size = -s $dest;
                $totsize += $size;
                $tottime += $t_time;
                my $speed = $size / $t_time;
                my $ord = 0;
                while ( $speed > 1024 ) { $speed /= 1024; $ord++ }
                my $dig = $ord ? '3' : '0';

                utime $entry->{time}, $entry->{time}, $dest;
                chmod $entry->{mode}, $dest;
                $verbose and printf "$size (%.${dig}f $sn[$ord]/s)\n",
                                     $speed;
            } else {
                $verbose > 1 and
                    printf "%s: %d/skipped\n", abs2rel( $destname, $lroot),
                                               $entry->{size};
            }
        }
    }
    if ( $cleanup ) {
        chdir $localdir;
        $verbose > 1 and print "Cleanup '$localdir'\n";
        my %ok_file = map {
            ( clean_filename( $_->{name} ) => $_->{type} )
        } @list;
        local *DIR;
        if ( opendir DIR, '.' ) {
            foreach ( readdir DIR ) {
                my $cmpname = clean_filename( $_ );
                $^O eq 'VMS' and $cmpname =~ s/\.$//;
                if( -f $cmpname ) {
                    unless ( exists $ok_file{ $cmpname } &&
                             $ok_file{ $cmpname } eq 'f' ) {
                        $verbose and printf "Delete %s\n",
                                             abs2rel( rel2abs( $cmpname ),
                                                      $lroot );
                        1 while unlink $_;
                    }
                } elsif ( -d && ! /^..?\z/ ) {
                     $^O eq 'VMS' and $cmpname =~ s/\.DIR$//i;
                     unless ( exists $ok_file{ $cmpname } &&
                              $ok_file{ $cmpname } eq 'd' ) {
                        rmtree( $cmpname, $verbose );
                    }
                }
            }
            closedir DIR;
        }
    }
    @_[ -2, -1 ] = ( $totsize, $tottime );
    return $mirror_ok;
}
}

=head2 dirlist( $ftp, $verbose )

Return a list of entries (hashrefs) with these properties:

    * name:    Filename
    * type     f/d/l
    * mode     unix file mode
    * size     filessize in bytes
    * date     file date

=cut

sub dirlist {
    my( $ftp, $verbose ) = @_;
    map __parse_line_from_dir( $_, $verbose ) => $ftp->dir;
}

=head2 __parse_line_from_dir( $line, $verbose )

The C<dir> command in FTP gives a sort of C<ls -la> output,
parts of this output are used as remote file-info.

=cut

sub __parse_line_from_dir {
    my( $entry, $verbose ) = @_;
    my @field = split " ", $entry;

    if ( $field[0] =~ /[dwrx-]{7}/ ) { # Unixy dir entry

        ( my $type = substr $field[0], 0, 1 ) =~ tr/-/f/;
        return {
            name => $field[-1],
            type => $type,
            mode => __get_mode_from_text( substr $field[0], 1 ),
            size => $field[4],
            time => 0,
            date => __time_from_ls( @field[5, 6, 7] ),
        }
    } else { # Windowsy dir entry
        my $type = $field[2] eq '<DIR>' ? 'd' : 'f';
        return {
            name => $field[-1],
            type => $type,
            mode => 0777,
            size => $field[2],
            time => 0,
            date => __time_from_windows( @field[0, 1] ),
        }
    }
}

=head2 __get_mode_from_text( $tmode )

This takes the text representation of a file-mode (like 'rwxr--r--')
and return the numeric value.

=cut

sub __get_mode_from_text {
    my( $tmode ) = @_; # nine letter/dash

    $tmode =~ tr/rwx-/1110/;
    my $mode = 0;
    for ( my $i = 0; $i < 3; $i++ ) {
        $mode <<= 3;
        $mode  += ord(pack B3 => substr $tmode, $i*3, 3) >> 5;
    }

    return $mode;
}

=head2 __time_from_ls( $mname, $day, $time_or_year )

This takes the three date/time related columns from the C<ls -la> output
and returns a localtime-stamp.

=cut

sub __time_from_ls {
    my( $mname, $day, $time_or_year ) = @_;

    my( $local_year, $local_month) = (localtime)[5, 4];
    $local_year += 1900;

    my $month = int( index('JanFebMarAprMayJunJulAugSepOctNovDec', $mname)/3 );

    my( $year, $time ) = $time_or_year =~ /:/
        ? $month > $local_month ? ( $local_year - 1, $time_or_year ) :
            ($local_year, $time_or_year) : ($time_or_year, '00:00' );

    my( $hour, $minutes ) = $time =~ /(\d+):(\d+)/;

    require Time::Local;
    return Time::Local::timelocal( 0, $minutes, $hour, $day, $month, $year );
}

=head2 __time_from_windows( $date, $time )

This takes the two date/time related columns from the C<dir> output
and returns a localtime-stamp

=cut

sub __time_from_windows {
    my( $date, $time ) = @_;

    my( $day, $month, $year ) = split m/-/, $date;
    $month--;
    my( $hour, $minutes, $off )     = $time =~ m/(\d+):(\d+)([ap])m/i;
    $off && lc $off eq 'p' and $hour += 12;

    require Time::Local;
    return Time::Local::timelocal( 0, $minutes, $hour, $day, $month, $year );
}

1;

=head1 SEE ALSO

L<Test::Smoke::Syncer>

=head1 COPYRIGHT & LICENSE

(c) 2003, 2004, 2005, Abe Timmerman <abeltje@cpan.org> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
