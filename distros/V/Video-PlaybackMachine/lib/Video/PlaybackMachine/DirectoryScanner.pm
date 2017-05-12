package Video::PlaybackMachine::DirectoryScanner;

our $VERSION = '0.09'; # VERSION

use Moo;

use Types::Standard qw(ArrayRef Str);

use Video::Xine;
use Video::Xine::Stream 'XINE_META_INFO_TITLE';

use Video::PlaybackMachine::Schema;
use Video::PlaybackMachine::DB;

use File::Find::Rule;
use File::Basename;
use List::MoreUtils 'uniq';
use POSIX 'ceil';

has 'directories' => (
    'is'       => 'ro',
    'isa'      => ArrayRef,
    'required' => 1
);

has 'schedule_name' => (
    'is'      => 'ro',
    'isa'     => Str,
    'default' => 'Test Schedule'
);

has 'xine' => ( 'is' => 'lazy', );

has 'stream' => ( 'is' => 'lazy', );

has 'schema' => ( 'is' => 'lazy' );

has 'suffixes' => (
    'is'  => 'lazy',
    'isa' => ArrayRef
);

sub _build_xine {
    my $self = shift;

    return Video::Xine->new();
}

sub _build_stream {
    my $self = shift;

    my $xine = $self->xine();

    my $vo = Video::Xine::Driver::Video->new( $xine, 'none' );
    my $ao = Video::Xine::Driver::Audio->new( $xine, 'none' );

    return $xine->stream_new( $ao, $vo );
}

sub _build_schema {
    my $self = shift;

    return Video::PlaybackMachine::DB->schema();
}

sub _build_suffixes {
    return ['*.mp4'];
}

sub scan {
    my $self = shift;

    my @movie_info = ();

    my @mrls = $self->file_mrls();

    foreach my $mrl (@mrls) {
        $self->stream->open($mrl);
        my ( undef, undef, $duration_millis ) = $self->stream->get_pos_length();
        my $duration_secs = ceil( $duration_millis / 1000 );

        my $title = $self->stream->get_meta_info(XINE_META_INFO_TITLE);
        $self->stream->close();

        if ( !defined $title ) {
            $title = basename($mrl);
            $title =~ s/\.\w{1,4}$//;
            $title =~ s/_\d+kb//;
            $title =~ s/[_-]/ /g;
        }

        push( @movie_info, [ $duration_secs, $title, $mrl ] );
    }

    my $movie_info_rs = $self->schema()->resultset('MovieInfo');

    my $schedule_end_rs = $self->schema->resultset('ScheduleEntryEnd');

    my $schedule_entry_rs = $self->schema->resultset('ScheduleEntry');

    my $run_sub = sub {
        $movie_info_rs->delete();
        $movie_info_rs->populate(
            [ [ 'duration', 'title', 'mrl' ], @movie_info ] );

        $schedule_end_rs->delete();

        while ( my $entry = $schedule_entry_rs->next() ) {
            my $movie = $movie_info_rs->find( { 'mrl' => $entry->mrl() } );
            if ( !defined $movie ) {
                warn "No Movie found for MRL '" . $entry->mrl . "'\n";
                next;
            }
            $entry->create_related( 'schedule_entry_end',
                { stop_time => $entry->start_time + $movie->duration() } );
        }

    };

    $self->schema->txn_do($run_sub);

    return;
}

sub file_mrls {
    my $self = shift;

    my @files = File::Find::Rule->file()->name( @{ $self->suffixes() } )
      ->in( @{ $self->directories() } );

    my @mrls = map { "file://$_" } @files;

    return @mrls;
}

no Moo;

1;
