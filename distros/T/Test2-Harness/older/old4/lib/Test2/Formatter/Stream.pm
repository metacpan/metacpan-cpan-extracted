package Test2::Formatter::Stream;
use strict;
use warnings;

use Carp qw/confess/;
use Test2::Util qw/get_tid pkg_to_file ipc_separator try_sig_mask do_rename/;
use File::Spec();
use Time::HiRes qw/time/;

use base qw/Test2::Formatter/;
use Test2::Util::HashBase qw/serializer io dir counter stream_id _encoding/;

sub hide_buffered { 0 }

sub find_serializer {
    my $class = shift;

    my $serializer = $ENV{T2_STREAM_SERIALIZER} || 'Storable';

    my $sclass;
    if ($serializer =~ m/^(\+)?(.*)$/) {
        $sclass = $1 ? $2 : __PACKAGE__ . '::Serializer::' . $2;
    }

    my $sfile = pkg_to_file($sclass);
    eval { require $sfile } || die "Could not load serializer '$serializer': $@";

    return $sclass->new;
}

# Sorry, but there are some vars we MUST have access to, and they cannot be
# validated in any real way.
sub untaint {
    my $in = shift;
    return unless defined $in;
    $in =~ m/^(.*)$/;
    return $1;
}

my %OPENED;
sub find_handle {
    my $class = shift;

    my $handle;

    if (my $file = untaint($ENV{T2_STREAM_FILE})) {
        confess "'$file' cannot be re-opened" if $OPENED{$file}++;
        require IO::Handle;
        open($handle, '>', $file) or die "Could not open stream file '$file': $!";
    }
    elsif (my $sfile = untaint($ENV{T2_STREAM_SOCKET})) {
        confess "'$file' cannot be re-opened" if $OPENED{$file}++;
        require IO::Socket::UNIX;
        my $handle = IO::Socket::UNIX->new(Peer => $sfile) or die "Could not connect to unix socket '$sfile': $!";
    }
    elsif (my $port = untaint($ENV{T2_STREAM_PORT})) {
        my $addr = untaint($ENV{T2_STREAM_ADDR}) || 'localhost';
        require IO::Socket::INET;
        $handle = IO::Socket::INET->new(
            PeerAddr => $addr,
            PeerPort => $port,
        );
    }

    return unless $handle;

    $handle->autoflush(1);

    return $handle;
}

sub init {
    my $self = shift;

    $self->{+STREAM_ID} ||= untaint($ENV{T2_STREAM_ID});

    $self->{+IO}  ||= $self->find_handle;
    $self->{+DIR} ||= untaint($ENV{T2_STREAM_DIR}) unless $self->{+IO};

    confess "Could not find destination, please pass one to the constructor, or specify one or more of T2_STREAM_(DIR|FILE|SOCKET|PORT|ADDR) environment variables"
        unless $self->{+IO} || $self->{+DIR};

    # For handles that are not true files we send the id alone as the first data (if an ID is provided).
    if ($self->{+IO} && $self->{+STREAM_ID} && $self->{+IO}->isa('IO::Socket')) {
        my $io = $self->{+IO};
        my $id = $self->{+STREAM_ID};
        print $io "$id\n";
    }

    $self->{+SERIALIZER} ||= $self->find_serializer;
}

sub encoding {
    my $self = shift;

    if (@_) {
        my ($enc) = @_;
        $self->{+SERIALIZER}->send($self->{+IO}, {control => {encoding => $enc}});
        $self->set_encoding($enc);
    }

    return $self->{+_ENCODING};
}

sub set_encoding {
    my $self = shift;

    if (@_) {
        my ($enc) = @_;

        # https://rt.perl.org/Public/Bug/Display.html?id=31923
        # If utf8 is requested we use ':utf8' instead of ':encoding(utf8)' in
        # order to avoid the thread segfault.
        if ($enc =~ m/^utf-?8$/i) {
            binmode($self->{+IO}, ":utf8");
        }
        else {
            binmode($self->{+IO}, ":encoding($enc)");
        }
        $self->{+_ENCODING} = $enc;
    }

    return $self->{+_ENCODING};
}

my $COUNTER = 1;
if ($^C) {
    no warnings 'redefine';
    *write = sub {};
}
sub write {
    my ($self, $e, $num, $f) = @_;
    $f ||= $e->facet_data;

    $self->set_encoding($f->{control}->{encoding}) if $f->{control}->{encoding};

    my $io = $self->{+IO};
    my ($file);
    unless($io) {
        my $dir =
            $self->{+STREAM_ID}
            ? File::Spec->catfile($self->{+DIR}, $self->{+STREAM_ID})
            : $self->{+DIR};

        mkdir($dir) or die "Could not make dir '$dir': $!" unless -d $dir;

        $file = File::Spec->catfile(
            $dir,
            $COUNTER++
        );
        confess "File '$file' already exists" if -e $file;
        open($io, '>', "$file.pend") or die "Could not open file '$file.pend': $!";
    }

    my ($ok, $err) = try_sig_mask {
        $self->{+SERIALIZER}->send(
            $io,
            {
                facets        => $f,
                assert_count  => $num,
                stamp         => time,
                stream_id     => $self->{+STREAM_ID},
            },
        );

        return unless $file;

        $io->flush;
        close($io);
        my ($rok, $rerr) = do_rename("$file.pend", $file);
        die $rerr unless $rok;
    };
    die $err unless $ok;
}

sub DESTROY {
    my $self = shift;
    my $IO = $self->{+IO} or return;
    eval { $IO->flush };
}


1;
