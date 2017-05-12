package App::ForkProve::SourceHandler;
use strict;
use parent qw(TAP::Parser::SourceHandler);

use App::ForkProve::PipeIterator;
use Scalar::Util 'openhandle';
use TAP::Parser::IteratorFactory;
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

use TAP::Parser::SourceHandler::Perl;

sub can_handle {
    my($class, $src) = @_;

    # I think there's a TAP::Parser bug thinking the first line of .t
    # file as a shebang even if it doesn't begin with '#!'
    local $src->meta->{file}{shebang} = undef
      if $src->meta->{file}{shebang} !~ /^#!/;

    my $is_perl = TAP::Parser::SourceHandler::Perl->can_handle($src);
    return 1 if $is_perl > 0.5 && !$class->ignore($src->meta->{file});
    return 0;
}

sub ignore {
    my($class, $file) = @_;
    $ENV{PERL_FORKPROVE_IGNORE} && ($file->{dir} . $file->{basename}) =~ /$ENV{PERL_FORKPROVE_IGNORE}/;
}

sub make_iterator {
    my($class, $src) = @_;

    my $path = $src->meta->{file}{dir} . $src->meta->{file}{basename};
    my @inc = map { s/^-I//; $_ } grep { /^-I/ } @{ $src->switches };

    $class->_autoflush(\*STDOUT);
    $class->_autoflush(\*STDERR);

    pipe my $reader, my $writer;
    my $pid = fork;
    if ($pid) {
        close $writer;
        return App::ForkProve::PipeIterator->new($reader, $pid);
    } else {
        close $reader;
        open STDOUT, ">&", $writer;
        open STDERR, ">&", $writer if $src->merge;
        _run($path, \@inc);
        exit;
    }
}

sub _run {
    my ($t, $inc) = @_;

    # Many tests especially Exception tests rely on test file name being
    # passed as t/foo.t without a leading path
    local $0 = $t;
    local @INC = (@$inc, @INC);

    # if FindBin is preloaded, reset it with the new $0
    if (defined &FindBin::init) {
        FindBin::init()
    }

    # open DATA from test script
    {
        close ::DATA;
        if (open my $fh, $t) {
            my $code = do { local $/; <$fh> };
            if(my($data) = $code =~ /^__(?:END|DATA)__$(.*)/ms){
                open ::DATA, '<', \$data
                  or die "Can't open string as DATA. $!";
            }
        }
    }

    # restore DATA for all preloaded modules
    my $data = \%App::ForkProve::Data;
    for my $mod (keys %$data) {
        my ($was_open, $prev_file, $prev_pos) = @{ $data->{$mod} };

        my $fh = do {
            no strict 'refs';
            *{ $mod . '::DATA' }
        };

        # note that we need to ensure that each forked copy is using a
        # different file handle, or else concurrent processes will interfere
        # with each other

        close $fh if openhandle($fh);

        if ($was_open) {
            if (open $fh, '<', $prev_file) {
                seek($fh, $prev_pos, 0);
            }
            else {
                warn "Couldn't reopen DATA for $mod: $!";
            }
        }
    }

    # restore defaults
    Getopt::Long::ConfigDefaults();

    # reset the state of empty pattern matches, so that they have the same
    # behavior as running in a clean process.
    # see "The empty pattern //" in perlop.
    # note that this has to be dynamically scoped and can't go to other subs
    "" =~ /^/;

    # Test::Builder is loaded? Reset the $Test object to make it unaware
    # that it's a forked off proecess so that subtests won't run
    if (defined $Test::Builder::Test) {
        $Test::Builder::Test->reset;
    }

    # avoid child processes sharing the same seed value as the parent
    srand();

    # clear @ARGV it's localized in App::ForkProve
    local @ARGV = ();

    # do() can't tell if a test can't be read or a .t's last statement
    # returned undef with $! set somewhere. Fortunately in case of
    # prove, non-readable .t will fail earlier in prove itself.
    eval q{ package main; do $t; die $@ if $@; 1 } or die $@;
}

sub _autoflush {
    my ( $class, $flushed ) = @_;
    my $old_fh = select $flushed;
    $| = 1;
    select $old_fh;
}

1;
