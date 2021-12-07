package fs::Promises;
use v5.24;
use warnings;
use experimental qw/signatures lexical_subs/;
no warnings qw/
    experimental
    experimental::signatures
    experimental::lexical_subs
/;

# Core
use File::Spec           ();

use Scalar::Util         ();

use AnyEvent::XSPromises ();
use POSIX::AtFork        ();
POSIX::AtFork->add_to_child(sub {
    IO::AIO::reinit() if $INC{'IO/AIO.pm'};
});

# Utils
use Ref::Util             ();
use Hash::Util::FieldHash ();

our $VERSION = 0.04;

my sub deferred { AnyEvent::XSPromises::deferred() }
my sub resolved { AnyEvent::XSPromises::resolved(@_) }
my sub rejected { AnyEvent::XSPromises::rejected(@_) }

my sub errno {
    my $e_num = 0 + $!;
    my $e_str = "$!";
    return Scalar::Util::dualvar( $e_num, $e_str );
}

use Exporter 'import';
our @EXPORT_OK = qw(
    open
    close
    stat
    lstat

    seek

    fcntl
    ioctl


    utime
    chown
    chmod
    truncate

    unlink
    link
    symlink
    rename
    copy
    move

    readlink
    realpath
    mkdir
    rmdir
    rmtree
    scandir

    slurp
    readline
);
my @promise_versions;
foreach my $exported ( @EXPORT_OK ) {
    my $promise_version = "${exported}_promise";
    push @promise_versions, $promise_version;
    no strict 'refs';
    *{$promise_version} = \*{$exported};
}
push @EXPORT_OK, @promise_versions;

use constant DEBUG => $ENV{DEBUG_fs_Promises} // 0;
sub TELL { say STDERR sprintf(__PACKAGE__ . ': ' . shift, @_) }

Hash::Util::FieldHash::fieldhash my %per_fh_buffer_cache;

my sub _drop_self { shift @_ if @_ > 1 && ($_[0]//'') eq __PACKAGE__; }

my sub lazily_require_aio {
    state $loaded = do {
        require IO::AIO;
        require AnyEvent::AIO;
        1;
    };
    return $loaded;
}
sub scandir {
    &_drop_self;
    my $path     = File::Spec->rel2abs(shift);
    my $max_req  = shift;
    my $deferred = AnyEvent::XSPromises::deferred();
    IO::AIO::aio_scandir($path, $max_req, sub {
        if ( !@_ ) {
            $deferred->reject(errno());
            return;
        }
        $deferred->resolve(@_);
    });
    return $deferred->promise;
}

sub open {
    &_drop_self;
    my ($maybe_rel_file, $mode) = @_; # TODO: mode!
    lazily_require_aio();
    $mode ||= IO::AIO::O_RDONLY();

    my %symbolic_mode_to_numeric = (
        '>'  => IO::AIO::O_WRONLY() | IO::AIO::O_CREAT(),
        '>>' => IO::AIO::O_WRONLY() | IO::AIO::O_CREAT() | IO::AIO::O_APPEND(),
        '<'  => IO::AIO::O_RDONLY(),
    );
    $mode = $symbolic_mode_to_numeric{$mode}
        if exists $symbolic_mode_to_numeric{$mode};

    my $abs_file = File::Spec->rel2abs($maybe_rel_file); # AIO api requires absolute paths
    my $deferred = deferred();
    IO::AIO::aio_open($abs_file, $mode, 0, sub ($fh=undef) {
        if ( !$fh ) {
            $deferred->reject(errno());
            return;
        }
        $deferred->resolve($fh);
    });
    return $deferred->promise;
}

my sub _arg_is_fh {
    my $cb                   = shift;
    &_drop_self;
    my $deferred             = deferred();
    $cb->(@_, sub { $_[0] < 0 ? $deferred->reject(errno()) : $deferred->resolve(@_) });
    return $deferred->promise;
}

sub close { lazily_require_aio(); _arg_is_fh(\&IO::AIO::aio_close, @_) } # Don't use unless you know what you are getting into.
sub seek  { lazily_require_aio(); _arg_is_fh(\&IO::AIO::aio_seek,  @_) }
sub fcntl { lazily_require_aio(); _arg_is_fh(\&IO::AIO::aio_fcntl, @_) }
sub ioctl { lazily_require_aio(); _arg_is_fh(\&IO::AIO::aio_ioctl, @_) }

my sub _ensure_globref_or_absolute_path {
    my ($fh_or_file) = @_;
    if (
           Ref::Util::is_globref($fh_or_file)
        || Ref::Util::is_globref(\$fh_or_file)
        || Ref::Util::is_ioref($fh_or_file)
    ) {
        # Globref/IO object, just return it
        return $fh_or_file;
    }
    # Probably a path -- We need to make it an absolute path per
    # the AIO API.
    return File::Spec->rel2abs($fh_or_file);
}

my sub _arg_is_fh_or_file {
    my $cb                   = shift;
    &_drop_self;
    my $fh_or_maybe_rel_path = shift;
    my $fh_or_abs_path       = _ensure_globref_or_absolute_path($fh_or_maybe_rel_path);
    my $deferred             = deferred();
    push @_, sub { $_[0] < 0 ? $deferred->reject(errno()) : $deferred->resolve(@_) };
    $cb->($fh_or_abs_path, @_);
    return $deferred->promise;
}

my sub _wrap_stat_and_lstat {
    my $cb                   = shift;
    &_drop_self;
    my $fh_or_maybe_rel_path = shift;
    my $fh_or_abs_path       = _ensure_globref_or_absolute_path($fh_or_maybe_rel_path);
    my $deferred             = deferred();
    push @_, sub {
        my $stat_status  = shift;
        if ( $stat_status ) {
            # non-zero status for stat; the call failed, so the pseudo-handle _ will hold nothing
            # of interest
            $deferred->reject(errno());
            return;
        }

        # Get the cached (l)stat results (calling stat or lstat here doesn't matter, since
        # it just gets whatever is cached in _):
        my $stat_results = [ stat(_) ];
        $deferred->resolve($stat_results);
    };
    $cb->($fh_or_abs_path, @_);
    return $deferred->promise;
}


sub stat     { lazily_require_aio(); _wrap_stat_and_lstat(\&IO::AIO::aio_stat,     @_) }
sub lstat    { lazily_require_aio(); _wrap_stat_and_lstat(\&IO::AIO::aio_lstat,    @_) }
sub utime    { lazily_require_aio(); _arg_is_fh_or_file(\&IO::AIO::aio_utime,    @_) }
sub chown    { lazily_require_aio(); _arg_is_fh_or_file(\&IO::AIO::aio_chown,    @_) }
sub truncate { lazily_require_aio(); _arg_is_fh_or_file(\&IO::AIO::aio_truncate, @_) }
sub chmod    { lazily_require_aio(); _arg_is_fh_or_file(\&IO::AIO::aio_chmod,    @_) }
sub unlink   { lazily_require_aio(); _arg_is_fh_or_file(\&IO::AIO::aio_unlink,   @_) }

my sub _arg_is_two_paths {
    my $cb                         = shift;
    &_drop_self;
    my ($first_path, $second_path) = map File::Spec->rel2abs($_), shift, shift;
    my $deferred                   = deferred();
    $cb->($first_path, $second_path, @_, sub {
        $_[0] < 0 ? $deferred->reject(errno()) : $deferred->resolve(@_)
    });
    return $deferred->promise;
}

sub link    { lazily_require_aio(); _arg_is_two_paths(\&IO::AIO::aio_link,    @_) }
sub symlink { lazily_require_aio(); _arg_is_two_paths(\&IO::AIO::aio_symlink, @_) }
sub rename  { lazily_require_aio(); _arg_is_two_paths(\&IO::AIO::aio_rename,  @_) }
sub copy    { lazily_require_aio(); _arg_is_two_paths(\&IO::AIO::aio_copy,    @_) }
sub move    { lazily_require_aio(); _arg_is_two_paths(\&IO::AIO::aio_move,    @_) }


my sub _arg_is_single_path {
    my $cb         = shift;
    &_drop_self;
    my $first_path = File::Spec->rel2abs(shift);
    my $deferred   = deferred();
    $cb->($first_path, @_, sub {
        $_[0] < 0 ? $deferred->reject(errno()) : $deferred->resolve(@_)
    });
    return $deferred->promise;
}
sub readlink { _arg_is_single_path(\&IO::AIO::aio_readlink, @_) }
sub realpath { _arg_is_single_path(\&IO::AIO::aio_realpath, @_) }
sub mkdir    { _arg_is_single_path(\&IO::AIO::aio_mkdir,    @_) }
sub rmdir    { _arg_is_single_path(\&IO::AIO::aio_rmdir,    @_) }
sub rmtree   { _arg_is_single_path(\&IO::AIO::aio_rmtree,   @_) }

sub slurp {
    &_drop_self;
    my $file      = File::Spec->rel2abs(shift);
    my $deferred  = deferred();
    my $buffer    = '';
    IO::AIO::aio_slurp($file, 0, 0, $buffer, sub {
        if ( $_[0] < 0 ) { # will be 0 if the file was empty
            $deferred->reject(errno());
            return;
        }
        $deferred->resolve($buffer);
    });
    return $deferred->promise;
}

sub readline {
    &_drop_self;
    my ($fh, $block_size) = @_;
    $block_size ||= 8192; #(stat $fh)[11] || 1024;

    my $eol = $/;

    if ( !$fh ) {
        return rejected("No filehandle provided to readline()");
    }

    my $io = *{$fh}{IO};

    my $buffer    = \($per_fh_buffer_cache{$io} //= '');

    my $fileno      = fileno($fh);
    my $buf_index   = length($$buffer);
    if ( $buf_index ) {
        my $eol_index = $eol ? index($$buffer, $eol, 0) : -1;

        if ( $eol_index >= 0 ) {
            DEBUG and TELL "fd %d: cached EOL", $fileno;
            # previous read got multiple lines!
            my $line = substr($$buffer, 0, $eol_index + 1, '');
            return resolved($line);
        }
    }

    my $deferred    = deferred();
    sub {
        my $do_aio_read = __SUB__;
        my $this_read_buf = '';
        IO::AIO::aio_read(
            $fh,
            undef,            # read offset -- undef means from the fd's offset
            $block_size,      # read size
            $this_read_buf,   # buffer to place the read data into
            0,                # offset in the buffer to start writing from
            sub {
                my ($bytes_read) = @_;

                if ( !$bytes_read ) {
                    # EOF; return what we have so far
                    if ( $$buffer ) {
                        DEBUG and TELL "fd %d: EOF, with cached EOL", $fileno;
                        $deferred->resolve("$$buffer");
                        $$buffer = '';
                    }
                    else {
                        DEBUG and TELL "fd %d: EOF", $fileno;
                        # we read nothing, and had nothing buffered.  Return undef.
                        $deferred->resolve(undef);
                    }
                    return;
                }

                $$buffer .= $this_read_buf if $bytes_read;

                my $eol_index = $eol ? index($$buffer, $eol, $buf_index) : -1;

                if ( $eol_index >= 0 ) {
                    DEBUG and TELL "fd %d: EOL", $fileno;
                    $buf_index = 0;
                    my $found = substr($$buffer, 0, $eol_index + 1, '');
                    $deferred->resolve($found);
                    return;
                }

                $buf_index += $bytes_read;

                # Not EOF, but not EOL, so do another read:
                DEBUG and TELL "fd %d: No EOL or EOF, doing another read", $fileno;
                return $do_aio_read->();
            },
        );
    }->();

    return $deferred->promise;
}

1;
__END__
=encoding utf-8

=pod

=head1 NAME

fs::Promises - Promises interface to nonblocking file system operations

=head1 SYNOPSIS

    use fs::Promises;
    use fs::Promises::Utils qw(await);

    # Fancy, but not really useful:
    my $fh = await +fs::Promises->open_promise($0);
    while ( my $line = await +fs::Promises->readline_promise($fh) ) {
        say $line;
    }


    # Same thing but using the functional interface:
    use fs::Promises qw(open_promise readline_promise);
    my $fh = await open_promise($0);
    while ( my $line = await readline_promise($fh) ) {
        say $line;
    }

    # Actuall async:
    use experimental 'signatures';
    use fs::Promises qw(open_promise readline_promise);
    use fs::Promises::Utils qw(p_while);
    await +open_promise($0)->then(sub ($fh) {
        return p_while { readline_promise($fh) } sub ($line) {
            say $line;
        }
    });

    # Reading four files in parallel:
    use experimental 'signatures';
    use AnyEvent::XSPromises qw(collect);
    use fs::Promises qw(open_promise readline_promise);
    use fs::Promises::Utils qw(await p_while);
    my $read_file = sub ($fh) {
        return p_while { readline_promise($fh) } sub ($line) {
            say $line;
        }
    };

    await +collect(
        open_promise($0)->then($read_file),
        open_promise($0)->then($read_file),
        open_promise($0)->then($read_file),
        open_promise($0)->then($read_file),
    );

=head1 DESCRIPTION

C<fs::Promises> is a promises layer around L<AnyEvent::AIO>.  If your code
is using promises, then you can use this module to do fs-based stuff in
an asynchronous way.

=head1 DEALING WITH ERRORS

In standard Perl land, syscalls like the ones exposed here generally have
this interface:

    foo() or die "$!"

That is, you invoke the sycall, and it returns false if the underlaying
operation failed, setting C<$ERRNO / $!> in the process.

C<$!> doesn't quite cut it for promises, because by the time your callback
is invoked, it is entirely possible for something else to have run, which
has now wiped C<$!>.

So instead, all the interfaces here follow the same rough pattern:

    foo()->then(sub ($success_result) { ... })
         ->catch(sub ($errno)         { ... })

The real example:

    stat_promise($file)->then(
        sub ($stat_results) {
            # $stat_results has the same 13-element list as 'stat()'
        },
        sub ($errno) {
            my $e_num = 0 + $errno;
            my $e_str = "$errno";
            warn "stat($file) failed: '$e_str' ($e_num)";
            return;
        }
    );

=cut


