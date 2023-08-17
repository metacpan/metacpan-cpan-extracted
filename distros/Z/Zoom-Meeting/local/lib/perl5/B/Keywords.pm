## no critic (PodSections,UseWarnings,Interpolation,EndWithOne,NoisyQuotes)

package B::Keywords;

use strict;

require Exporter;
*import = *import = \&Exporter::import;

use vars qw( @EXPORT_OK %EXPORT_TAGS );
@EXPORT_OK = qw( @Scalars @Arrays @Hashes @Filehandles @Symbols
                 @Functions @Barewords @TieIOMethods @UNIVERSALMethods
                 @ExporterSymbols );
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use vars '$VERSION';
$VERSION = '1.24';
my $CPERL = $^V =~ /c$/ ? 1 : 0;

use vars '@Scalars';
@Scalars = (
    qw( $a
        $b
        $_ $ARG
        $& $MATCH
        $` $PREMATCH
        $' $POSTMATCH
        $+ $LAST_PAREN_MATCH ),
    ($] < 5.008001 ?
    qw( $* $MULTILINE_MATCHING) : ()),
    qw( $. $INPUT_LINE_NUMBER $NR
        $/ $INPUT_RECORD_SEPARATOR $RS
        $| $OUTPUT_AUTOFLUSH ), '$,', qw( $OUTPUT_FIELD_SEPARATOR $OFS
        $\ $OUTPUT_RECORD_SEPARATOR $ORS
        $" $LIST_SEPARATOR
        $; $SUBSCRIPT_SEPARATOR $SUBSEP
    ), '$#', qw( $OFMT
        $% $FORMAT_PAGE_NUMBER
        $= $FORMAT_LINES_PER_PAGE
        $- $FORMAT_LINES_LEFT
        $~ $FORMAT_NAME
        $^ $FORMAT_TOP_NAME
        $: $FORMAT_LINE_BREAK_CHARACTERS
        $? $CHILD_ERROR $^CHILD_ERROR_NATIVE
        $! $ERRNO $OS_ERROR
        $@ $EVAL_ERROR
        $$ $PROCESS_ID $PID
        $< $REAL_USER_ID $UID
        $> $EFFECTIVE_USER_ID $EUID ), 
       '$(', qw( $REAL_GROUP_ID $GID ), 
       '$)', qw( $EFFECTIVE_GROUP_ID $EGID
        $0 $PROGRAM_NAME
        $[
        $]
        $^A $ACCUMULATOR
        $^C $COMPILING
        $^CHILD_ERROR_NATIVE
        $^D $DEBUGGING
        $^E $EXTENDED_OS_ERROR
        $^ENCODING
        $^F $SYSTEM_FD_MAX
        $^GLOBAL_PHASE
        $^H
        $^I $INPLACE_EDIT
        $^L $FORMAT_FORMFEED
        $^LAST_FH
        $^M
        $^MATCH
        $^N $LAST_SUBMATCH_RESULT
        $^O $OSNAME
        $^OPEN
        $^P $PERLDB
        $^PREMATCH $^POSTMATCH
        $^R $LAST_REGEXP_CODE_RESULT
        $^RE_DEBUG_FLAGS
        $^RE_TRIE_MAXBUF
        $^S $EXCEPTIONS_BEING_CAUGHT
        $^T $BASETIME
        $^TAINT
        $^UNICODE
        $^UTF8CACHE
        $^UTF8LOCALE
        $^V $PERL_VERSION
        $^W $WARNING $^WARNING_BITS
        $^WIDE_SYSTEM_CALLS
        $^WIN32_SLOPPY_STAT
        $^X $EXECUTABLE_NAME
        $ARGV
        ),
);

use vars '@Arrays';
@Arrays = qw(
    @+ $LAST_MATCH_END
    @- @LAST_MATCH_START
    @ARGV
    @F
    @INC
    @_ @ARG
);

use vars '@Hashes';
@Hashes = qw(
    %main
    %CORE
    %CORE::GLOBAL::
    %OVERLOAD
    %+ %LAST_MATCH_END
    %- %LAST_MATCH_START
    %! %OS_ERROR %ERRNO
    %^H
    %INC
    %ENV
    %SIG
);

use vars '@Filehandles';
@Filehandles = qw(
    *ARGV ARGV
    *_ _
    ARGVOUT
    DATA
    STDIN
    STDOUT
    STDERR
);

use vars '@Functions';
@Functions = (
  ($] >= 5.015006 ? qw(
    __SUB__
  ) : ()), qw(
    AUTOLOAD
    BEGIN
    DESTROY
    END ),
    # STOP was between 5.5.64 - 5.6.0
  ($] >= 5.005064 && $] < 5.006
    ? qw(STOP) : qw(CHECK)),
    # INIT was called RESTART before 5.004_50
  ($] >= 5.006
    ? qw(INIT) : qw(RESTART)),
   # removed with 855a8c432447
  ($] < 5.007003 ? qw(
    EQ GE GT LE LT NE
   ) : ()),
  ($] >= 5.009005 ? qw(
    UNITCHECK
   ) : ()), qw(
    abs
    accept
    alarm
    atan2
    bind
    binmode
    bless ),
  ($] >= 5.009003 && ($] < 5.027007 || $] >= 5.027008 || $CPERL) ? qw(
    break
  ) : ()), qw(
    caller
    chdir
    chmod
    chomp
    chop
    chown
    chr
    chroot
    close
    closedir
    connect
    cos
    crypt
    dbmclose
    dbmopen ),
  ($] >= 5.009003 && ($] < 5.027007 || $CPERL) ? qw(
    default
  ) : ()), qw(
    defined
    delete
    die
    dump
    each
    endgrent
    endhostent
    endnetent
    endprotoent
    endpwent
    endservent
    eof
    eval ),
  ($] >= 5.015005 ? qw(
    evalbytes
  ) : ()), qw(
    exec
    exists
    exit
    exp ),
  ($] >= 5.029 && $CPERL ? qw(
    extern
  ) : ()),
  ($] >= 5.015008 ? qw(
    fc
  ) : ()), qw(
    fcntl
    fileno
    flock
    fork
    format
    formline
    getc
    getgrent
    getgrgid
    getgrnam
    gethostbyaddr
    gethostbyname
    gethostent
    getlogin
    getnetbyaddr
    getnetbyname
    getnetent
    getpeername
    getpgrp
    getppid
    getpriority
    getprotobyname
    getprotobynumber
    getprotoent
    getpwent
    getpwnam
    getpwuid
    getservbyname
    getservbyport
    getservent
    getsockname
    getsockopt ),
  ($] >= 5.009003 ? qw(
    given
  ) : ()), qw(
    glob
    gmtime
    goto
    grep
    hex
    index
    int
    ioctl ),
  ($] >= 5.031007 ? qw(
    isa
  ) : ()), qw(
    join
    keys
    kill
    last
    lc
    lcfirst
    length
    link
    listen
    local
    localtime ),
  ($] >= 5.004 ? qw(
    lock
  ) : ()), qw(
    log
    lstat
    map
    mkdir
    msgctl
    msgget
    msgrcv
    msgsnd
    my
    next
    not
    oct
    open
    opendir
    ord ),
  ($] >= 5.005061 ? qw(
    our
  ) : ()), qw(
    pack
    pipe
    pop
    pos
    print
    printf
    prototype
    push
    quotemeta
    rand
    read
    readdir
    readline
    readlink
    readpipe
    recv
    redo
    ref
    rename
    require
    reset
    return
    reverse
    rewinddir
    rindex
    rmdir ),
  ($] >= 5.009003 ? qw(
    say
  ) : ()), qw(
    scalar
    seek
    seekdir
    select
    semctl
    semget
    semop
    send
    setgrent
    sethostent
    setnetent
    setpgrp
    setpriority
    setprotoent
    setpwent
    setservent
    setsockopt
    shift
    shmctl
    shmget
    shmread
    shmwrite
    shutdown
    sin
    sleep
    socket
    socketpair
    sort
    splice
    split
    sprintf
    sqrt
    srand
    stat
    study
    substr
    symlink
    syscall
    sysopen
    sysread
    sysseek
    system
    syswrite
    tell
    telldir
    tie
    tied
    time
    times
    truncate
    uc
    ucfirst
    umask
    undef
    unlink
    unpack
    unshift
    untie
    use
    utime
    values
    vec
    wait
    waitpid
    wantarray
    warn ),
  ($] >= 5.009003 && ($] < 5.027007 || $] >= 5.027008 || $CPERL) ? qw(
    when
  ) : ($] >= 5.009003 && !$CPERL) ? qw(
    whereis
    whereso
  ) : ()), qw(
    write

    -r -w -x -o
    -R -W -X -O -e -z -s
    -f -d -l -p -S -b -c -t
    -u -g -k
    -T -B
    -M -A -C
));

use vars '@Barewords';
@Barewords = (
  qw(
    __FILE__
    __LINE__
    __PACKAGE__
    __DATA__
    __END__
    NULL
    and ),
  #removed with a96df643850d22bc4a94
  ($] >= 5.000 && $] < 5.019010 ? qw(
    CORE
   ) : ()),
  ($CPERL && $] >= 5.027001 ? qw(
    class method role multi has
  ) : ()), qw(
    cmp
    continue
    do
    else
    elsif
    eq ),
  # added with dor (c963b151157d), removed with f23102e2d6356
  # in fact this was never in keywords.h for some reason
  ($] >= 5.008001 && $] < 5.010 ? qw(
    err
  ) : ()),
  qw(
    for
    foreach
    ge
    gt
    if
    le
    lock
    lt
    m
    ne
    no
    or
    package
    q
    qq ),
  ($] >= 5.004072 ? qw(
    qr
  ) : ()),
  ($] == 5.007003 ? qw(
    qu
  ) : ()), qw(
    qw
    qx
    s
    sub
    tr
    unless
    until
    while
    x
    xor
    y
  ),
  # also with default, say
  ($] >= 5.009003 ? qw(
     break
     given
     when
   ) : ()
  ),
  # removed as useless with 5.27.7, re-added with 7896dde7482a2851
  ($] >= 5.009003 && ($] < 5.027007 || $] >= 5.027008) ? qw(
     default
   ) : ()
  ),
  ($] >= 5.009004 ? qw(
     state
   ) : ()
  ),
  ($] >= 5.033007 ? qw(
      try
      catch
    ) : ()
  ),
  ($] >= 5.035004 ? qw(
      defer
    ) : ()
  ),
  ($] >= 5.035008 ? qw(
      finally
    ) : ()
  ),
);

# Extra barewords not in keywords.h (import was never in keywords)
use vars '@BarewordsExtra';
@BarewordsExtra = qw(
    import
    unimport
);

use vars '@TieIOMethods';
@TieIOMethods = qw(
    BINMODE CLEAR CLEARERR CLONE CLONE_SKIP CLOSE DELETE EOF
    ERROR EXISTS EXTEND FDOPEN FETCH FETCHSIZE FILENO FILL FIRSTKEY FLUSH
    GETC NEXTKEY OPEN POP POPPED PRINT PRINTF PUSH PUSHED READ READLINE
    SCALAR SEEK SETLINEBUF SHIFT SPLICE STORE STORESIZE SYSOPEN TELL
    TIEARRAY TIEHANDLE TIEHASH TIESCALAR UNREAD UNSHIFT UNTIE UTF8 WRITE
);

use vars '@UNIVERSALMethods';
@UNIVERSALMethods = qw(
    can isa DOES VERSION
);

use vars '@ExporterSymbols';
@ExporterSymbols = qw(
    @EXPORT @EXPORT_OK @EXPORT_FAIL
    @EXPORT_TAGS _push_tags _rebuild_cache as_heavy export export_fail
    export_fail_in export_ok_tags export_tags export_to_level heavy_export
    heavy_export_ok_tags heavy_export_tags heavy_export_to_level
    heavy_require_version require_version
);

use vars '@Symbols';
@Symbols = ( @Scalars, @Arrays, @Hashes, @Filehandles, @Functions );

# This quote is blatantly copied from ErrantStory.com, Michael Poe's
# comic.
BEGIN { $^W = 0 }
"You know, when you stop and think about it, Cthulhu is a bit a Mary Sue isn't he?"

__END__

=encoding UTF-8

=head1 NAME

B::Keywords - Lists of reserved barewords and symbol names

=head1 SYNOPSIS

  use B::Keywords qw( @Symbols @Barewords );
  print join "\n", @Symbols,
                   @Barewords;

=head1 DESCRIPTION

C<B::Keywords> supplies several arrays of exportable keywords:
C<@Scalars>, C<@Arrays>, C<@Hashes>, C<@Filehandles>, C<@Symbols>,
C<@Functions>, C<@Barewords>, C<@BarewordsExtra>, C<@TieIOMethods>,
C<@UNIVERSALMethods> and C<@ExporterSymbols>.

The C<@Symbols> array includes the contents of each
of C<@Scalars>, C<@Arrays>, C<@Hashes>, C<@Functions> and C<@Filehandles>.

Similarly, C<@Barewords> adds a few non-function keywords and
operators to the C<@Functions> array.

C<@BarewordsExtra> adds a few barewords which are not in keywords.h.

All additions and modifications are welcome.

The perl parser uses a static list of keywords from
F<regen/keywords.pl> which constitutes the strict list of keywords
@Functions and @Barewords, though some @Functions are not functions
in the strict sense.
Several library functions use more special symbols, handles and methods.

=head1 DATA

=over

=item C<@Scalars>

=item C<@Arrays>

=item C<@Hashes>

=item C<@Filehandles>

=item C<@Functions>

The above are lists of variables, special file handles, and built in
functions.

=item C<@Symbols>

This is just the combination of all of the above: variables, file
handles, and functions.

=item C<@Barewords>

This is a list of other special keywords in perl including operators
and all the control structures.

=item C<@BarewordsExtra>

This is a list of barewords which are missing from keywords.h, handled
extra in the tokenizer.

=item C<@TieIOMethods>

Those are special tie or PerlIO methods called by the perl core,
namely for tieing or PerlIO::via (or both of those) or threads.

=item C<@UNIVERSALMethods>

Methods defined by the core package UNIVERSAL.

=item C<@ExporterSymbols>

Variables or functions used by Exporter (some internal), which is
almost as good as being keywords, for you mustn't use them for any
other purpose in any package that isa Exporter, which is quite common.

=back

=head1 EXPORT

Anything can be exported if you desire. Use the :all tag to get
everything.

=head1 SEE ALSO

F<regen/keywords.pl> from the perl source, L<perlvar>, L<perlfunc>,
L<perldelta>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-B-Keywords at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=B-Keywords>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc B::Keywords

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=B-Keywords>

=item * GIT repository

L<http://github.com/rurban/b-keywords/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/B-Keywords>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/B-Keywords>

=item * Search CPAN

L<http://search.cpan.org/dist/B-Keywords>

=back

=head1 ACKNOWLEDGEMENTS

Michael G Schwern, Reini Urban, Florian Ragwitz and Zsbán Ambrus
for patches and releases.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Joshua ben Jore, All rights reserved.
Copyright 2013, 2015, 2017-2021 Reini Urban, All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SOURCE AVAILABILITY

This source is in Github: L<git://github.com/rurban/b-keywords.git>

=head1 AUTHOR

Joshua ben Jore <jjore@cpan.org>

=head1 MAINTAINER

Reini Urban <rurban@cpan.org>
