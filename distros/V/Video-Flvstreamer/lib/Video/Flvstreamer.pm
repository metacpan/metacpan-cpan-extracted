package Video::Flvstreamer;

use warnings;
use strict;

use IPC::Run qw/run timeout/;

=head1 NAME

Video::Flvstreamer - An OO interface to flvstreamer

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

An interface to flvstreamer: a commandline video stream ripping application

http://savannah.nongnu.org/projects/flvstreamer

    use Video::Flvstreamer;

    my $flv = Video::Flvstreamer->new();
    $flv->get( $url, $target );


=head1 SUBROUTINES/METHODS

=head2 new

Create a new object.

    my $flv = Video::Flvstreamer->new();

or

    my $flv = Video::Flvstreamer->new( { flvstreamer => $path_to_flvstreamer,
                                         timeout     => $timout_seconds,
                                         try         => $try_times,
                                         socks       => $socks_proxy } );

flvstreamer is the path to your binary flvstreamer. Default: /usr/bin/flvstreamer

timeout is the network timeout (seconds) during streaming.  Default: 10

try is the number of times flvstreamer should be called (with --resume) to try and complete a download,
if errors occur. Default: 10

socks is the socks proxy server for flvstreamer to use if necessary

=cut

sub new{
    my( $class, $args ) = @_;
    my $self = {};

    # Some defaults
    $self->{flvstreamer} = '/usr/bin/flvstreamer';
    $self->{timeout}     = 10;
    $self->{try}         = 10;
    $self->{debug}       = undef;

    foreach( qw/flvstreamer timout socks debug/ ){
        if( $args->{$_} ){
            $self->{$_} = $args->{$_};
        }
    }

    if( ! -e $self->{flvstreamer} ){
        die( "flvstreamer is not executable or does not exist: $self->{flvstreamer}\n");
    }

    bless $self, $class;
    return $self;
}



=head2 get_raw

    $flv->get_raw( $raw_string, $target, $args );

raw_string is a pre-formatted flvstreamer argument string.  e.g.
-r rtmp://example.org/stream

target is the target that the ripped stream should be saved to

args are the same as in the new() method, if you want to have individual settings for this get command

-resume and -o $target is still automatically added to the raw_string

=cut

sub get_raw{
    my( $self, $raw, $target, $args ) = @_;

    if( ! $raw ){
        die( __PACKAGE__ . " no raw opts passed to get_raw" );
    }

   # Allow override by args, otherwise use defaults
    foreach( qw/timout flvstreamer socks swfUrl pageUrl/ ){
        if( ! $args->{$_} && $self->{$_} ){
            $args->{$_} = $self->{$_};
        }
    }

    my @cmd;
    if( ref( $raw ) eq 'ARRAY' ){
        @cmd = ( $args->{flvstreamer}, @$raw, '--resume',  '-q', '-o', $target );
    }else{
        @cmd = ( $args->{flvstreamer}, $raw, '--resume', '-q', '-o', $target );
    }

    # Often transfer fails - retry till finished
    my $finished = undef;
    my $try = 1;
    my $last_size = undef;
    my( $out, $err );
  TRY_DOWNLOAD:
    while( ! $finished and $try <= $self->{try}  ){
        # Out/Err don't seem to be used by flvstreamer in -q mode...
        if( $self->{debug} ){
            printf( __PACKAGE__ . "->get_raw : try=%03u, cmd = %s\n", $try, join( ' ', @cmd ) );
        }

        if( run( \@cmd, undef, \$out, \$err ) ){
            $finished = 1;
        }elsif( $err ){
            last TRY_DOWNLOAD;
        }
        # Try again.  The return value is stored in $?
        $try++;
    }
    if( ! $finished ){
        die( "I tried $try times, but couldn't complete download.\nCommand: " . 
             join( ' ', @cmd ) .
             "\nLast Return code: $?\n" .
           "Last StdErr: $err\n" .
           "Last StdOut: $out\n" );
    }
}

=head2 get

    $flv->get( $url, $target, $args );

url is the source stream, e.g. rtmp://example.org/stream

target is the target that the ripped stream should be saved to

args are the same as in the new() method, if you want to have individual settings for this get command

=cut
sub get{
    my( $self, $url, $target, $args ) = @_;
    if( ! $url ){
        die( __PACKAGE__ . " cannot get without a url\n" );
    }
    if( $url !~ m/^rtmp\:\/\// ){
        die( __PACKAGE__ . " invalid protocol (not rtmp): $url\n" );
    }

    # Allow override by args, otherwise use defaults
    foreach( qw/timout flvstreamer socks swfUrl pageUrl/ ){
        if( ! $args->{$_} && $self->{$_} ){
            $args->{$_} = $self->{$_};
        }
    }

    my @flv_opts = ( '--rtmp', $url );

    foreach( qw/swfUrl pageUrl timeout/ ){
        if( $args->{$_} ){
            push( @flv_opts, '--' . $_ );
            push( @flv_opts, $args->{$_} );
        }
    }

    return $self->get_raw( \@flv_opts, $target, $args );
}



=head1 AUTHOR

Robin Clarke, C<< <robin at robinclarke.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-video-flvstreamer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Video-Flvstreamer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Video::Flvstreamer

You can also look for information at:

=over 4

=item * Repository on Github

L<https://github.com/robin13/Video-Flvstreamer>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Video-Flvstreamer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Video-Flvstreamer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Video-Flvstreamer>

=item * Search CPAN

L<http://search.cpan.org/dist/Video-Flvstreamer/>

=back


=head1 ACKNOWLEDGEMENTS

L<http://savannah.nongnu.org/projects/flvstreamer>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Video::Flvstreamer
