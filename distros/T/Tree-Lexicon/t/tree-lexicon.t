#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::Simple tests => 12;

use Tree::Lexicon qw( cs_regexp ci_regexp );

init();

ok( cs_lex_pop_ok(),    'populate case sensitive lexicon'             );
ok( cs_lex_cmp_ok(),    'compare case sensitive lexicons'             );
ok( cs_lex_vocab_ok(),  'vocabulary of case sensitive lexicon'        );
ok( cs_lex_auto_ok(),   'auto-complete for case sensitive lexicon'    );
ok( cs_regexp_ok(),     'case sensitive convenience function'         );
ok( cs_lex_depop_ok(),  'depopulate case sensitive lexicon'           );

ok( ci_lex_pop_ok(),    'populate case insensitive lexicon'           );
ok( ci_lex_cmp_ok(),    'compare case insensitive lexicons'           );
ok( ci_lex_vocab_ok(),  'vocabulary of case insensitive lexicon'      );
ok( ci_lex_auto_ok(),   'auto-complete for case insensitive lexicon'  );
ok( ci_regexp_ok(),     'case insensitive convenience function'       );
ok( ci_lex_depop_ok(),  'depopulate case insensitive lexicon'         );



my %cs_hash;
my %ci_hash;
my @cs;
my @ci;
my $lexicon;
my $regexp;
my $lex_empty_regexp;
my $use_empty_regexp;

sub init {
    my %cs_hash = (
        'A' => [ 'AUTOLOAD' ],
        'B' => [ 'BEGIN' ],
        'C' => [ 'CHECK', 'CORE' ],
        'D' => [ 'DESTROY' ],
        'E' => [ 'END' ],
        'F' => [],
        'G' => [],
        'H' => [],
        'I' => [ 'INIT' ],
        'J' => [],
        'K' => [],
        'L' => [],
        'M' => [],
        'N' => [],
        'O' => [],
        'P' => [],
        'Q' => [],
        'R' => [],
        'S' => [],
        'T' => [],
        'U' => [ 'UNITCHECK' ],
        'V' => [],
        'W' => [],
        'X' => [],
        'Y' => [],
        'Z' => [],
        '_' => [ '__DATA__', '__END__', '__FILE__', '__LINE__', '__PACKAGE__' ],
        'a' => [ 'abs', 'accept', 'alarm', 'and', 'atan2' ],
        'b' => [ 'bind', 'binmode', 'bless', 'break' ],
        'c' => [ 'caller', 'chdir', 'chmod', 'chomp', 'chop', 'chown', 'chr', 'chroot', 'close', 'closedir', 'cmp', 'connect', 'continue', 'cos', 'crypt' ],
        'd' => [ 'dbmclose', 'dbmopen', 'defined', 'delete', 'die', 'do', 'dump' ],
        'e' => [ 'each', 'else', 'elsif', 'endgrent', 'endhostent', 'endnetent', 'endprotoent', 'endpwent', 'endservent', 'eof', 'eq', 'eval', 'exec', 'exists', 'exit', 'exp' ],
        'f' => [ 'fcntl', 'fileno', 'flock', 'for', 'foreach', 'fork', 'format', 'formline' ],
        'g' => [ 'ge', 'getc', 'getgrent', 'getgrgid', 'getgrnam', 'gethostbyaddr', 'gethostbyname', 'gethostent', 'getlogin', 'getnetbyaddr', 'getnetbyname', 'getnetent', 'getpeername', 'getpgrp', 'getppid', 'getpriority', 'getprotobyname', 'getprotobynumber', 'getprotoent', 'getpwent', 'getpwnam', 'getpwuid', 'getservbyname', 'getservbyport', 'getservent', 'getsockname', 'getsockopt', 'glob', 'gmtime', 'goto', 'grep', 'gt' ],
        'h' => [ 'hex' ],
        'i' => [ 'if', 'index', 'int', 'ioctl' ],
        'j' => [ 'join' ],
        'k' => [ 'keys', 'kill' ],
        'l' => [ 'last', 'lc', 'lcfirst', 'le', 'length', 'link', 'listen', 'local', 'localtime', 'lock', 'log', 'lstat', 'lt' ],
        'm' => [ 'm', 'map', 'mkdir', 'msgctl', 'msgget', 'msgrcv', 'msgsnd', 'my' ],
        'n' => [ 'ne', 'next', 'no', 'not' ],
        'o' => [ 'oct', 'open', 'opendir', 'or', 'ord', 'our' ],
        'p' => [ 'pack', 'package', 'pipe', 'pop', 'pos', 'print', 'printf', 'prototype', 'push' ],
        'q' => [ 'q', 'qq', 'qr', 'quotemeta', 'qw', 'qx' ],
        'r' => [ 'rand', 'read', 'readdir', 'readline', 'readlink', 'readpipe', 'recv', 'redo', 'ref', 'rename', 'require', 'reset', 'return', 'reverse', 'rewinddir', 'rindex', 'rmdir' ],
        's' => [ 's', 'say', 'scalar', 'seek', 'seekdir', 'select', 'semctl', 'semget', 'semop', 'send', 'setgrent', 'sethostent', 'setnetent', 'setpgrp', 'setpriority', 'setprotoent', 'setpwent', 'setservent', 'setsockopt', 'shift', 'shmctl', 'shmget', 'shmread', 'shmwrite', 'shutdown', 'sin', 'sleep', 'socket', 'socketpair', 'sort', 'splice', 'split', 'sprintf', 'sqrt', 'srand', 'stat', 'state', 'study', 'sub', 'substr', 'symlink', 'syscall', 'sysopen', 'sysread', 'sysseek', 'system', 'syswrite' ],
        't' => [ 'tell', 'telldir', 'tie', 'tied', 'time', 'times', 'tr', 'truncate' ],
        'u' => [ 'uc', 'ucfirst', 'umask', 'undef', 'unless', 'unlink', 'unpack', 'unshift', 'untie', 'until', 'use', 'utime' ],
        'v' => [ 'values', 'vec' ],
        'w' => [ 'wait', 'waitpid', 'wantarray', 'warn', 'while', 'write' ],
        'x' => [ 'xor' ],
        'y' => [ 'y' ],
        'z' => []
    );

    %ci_hash = (
        'A' => [ 'A', 'ABBR', 'ACRONYM', 'ADDRESS', 'APPLET', 'AREA', 'ARTICLE', 'ASIDE', 'AUDIO' ],
        'B' => [ 'B', 'BASE', 'BASEFONT', 'BDI', 'BDO', 'BIG', 'BLOCKQUOTE', 'BODY', 'BR', 'BUTTON' ],
        'C' => [ 'CANVAS', 'CAPTION', 'CENTER', 'CITE', 'CODE', 'COL', 'COLGROUP', 'COMMAND' ],
        'D' => [ 'DATALIST', 'DD', 'DEL', 'DETAILS', 'DFN', 'DIALOG', 'DIR', 'DIV', 'DL', 'DT' ],
        'E' => [ 'EM', 'EMBED' ],
        'F' => [ 'FIELDSET', 'FIGCAPTION', 'FIGURE', 'FONT', 'FOOTER', 'FORM', 'FRAME', 'FRAMESET' ],
        'G' => [],
        'H' => [ 'H1', 'HEAD', 'HEADER', 'HGROUP', 'HR', 'HTML' ],
        'I' => [ 'I', 'IFRAME', 'IMG', 'INPUT', 'INS' ],
        'J' => [],
        'K' => [ 'KBD', 'KEYGEN' ],
        'L' => [ 'LABEL', 'LEGEND', 'LI', 'LINK' ],
        'M' => [ 'MAP', 'MARK', 'MENU', 'META', 'METER' ],
        'N' => [ 'NAV', 'NOFRAMES', 'NOSCRIPT' ],
        'O' => [ 'OBJECT', 'OL', 'OPTGROUP', 'OPTION', 'OUTPUT' ],
        'P' => [ 'P', 'PARAM', 'PRE', 'PROGRESS' ],
        'Q' => [ 'Q' ],
        'R' => [ 'RP', 'RT', 'RUBY' ],
        'S' => [ 'S', 'SAMP', 'SCRIPT', 'SECTION', 'SELECT', 'SMALL', 'SOURCE', 'SPAN', 'STRIKE', 'STRONG', 'STYLE', 'SUB', 'SUMMARY', 'SUP' ],
        'T' => [ 'TABLE', 'TBODY', 'TD', 'TEXTAREA', 'TFOOT', 'TH', 'THEAD', 'TIME', 'TITLE', 'TR', 'TRACK', 'TT' ],
        'U' => [ 'U', 'UL' ],
        'V' => [ 'VAR', 'VIDEO' ],
        'W' => [ 'WBR' ],
        'X' => [],
        'Y' => [],
        'Z' => []
    );
    foreach (sort keys %cs_hash) { foreach (@{$cs_hash{$_}}) { push @cs, $_ } }
    foreach (sort keys %ci_hash) { foreach (@{$ci_hash{$_}}) { push @ci, $_ } }
    $lex_empty_regexp = qr/\b(?:)\b/;
    $use_empty_regexp = qr/^$/;
}

sub rand_cs {
    my @rcs;
    
    foreach (@cs) {
        splice( @rcs, int(rand(scalar(@rcs)+1)), 0, $_ );
    }

    return @rcs;
}

sub rand_ci {
    my @rci;
    
    foreach (@ci) {
        my $word = $_;
        foreach (0 .. length( $word )-1) {
            (int(rand(2))) and
                substr( $word, $_, 1, lc( substr( $word, $_, 1 ) ) );
        }
        splice( @rci, int(rand(scalar(@rci)+1)), 0, $word );
    }
    
    return @rci;
}

## Begin Tests ##

# Case Sensistive Tests: (1-6)/12

# 1/12
sub cs_lex_pop_ok {
    my $ok = 1;

    $lexicon  = Tree::Lexicon->new();
    $regexp   = $use_empty_regexp;
    
    foreach (rand_cs()) {
        ($ok = not $lexicon->contains( $_ )) or last;
        ($ok = ($_ !~ $regexp)) or last;
        $lexicon->insert( $_ );
        $regexp = $lexicon->as_regexp();
        ($ok = $lexicon->contains( $_ )) or last;
        ($ok = ($_ =~ $regexp)) or last;
    }

    return $ok;
}

# 2/12
sub cs_lex_cmp_ok {
    my $ok  = 1;
    my $lex;
    my $re;

    $lex = Tree::Lexicon->new()->insert( @cs );
    $re  = $lex->as_regexp();
    ($ok = ($re eq $regexp)) or return $ok;

    $lex = Tree::Lexicon->new()->insert( reverse @cs );
    $re  = $lex->as_regexp();
    $ok = ($re eq $regexp) or return $ok;

    return $ok;
}

# 3/12
sub cs_lex_vocab_ok {
    my $ok  = 1;
    my @vocab = $lexicon->vocabulary();

    if ($ok = (@vocab == @cs)) {
        foreach (@cs) {
            ($ok = ($_ eq shift @vocab)) or last;
        }
    }
    
    return $ok;
}

# 4/12
sub cs_lex_auto_ok {
    my $ok  = 1;
    
    foreach (keys %cs_hash) {
        my @vals = @{$cs_hash{$_}};
        my @auto = $lexicon->auto_complete( $_ );

        if ($ok = (@vals == @auto)) {
            foreach (@vals) {
                ($ok = ($_ eq shift @auto)) or last;
            }
        }
    }
    
    return $ok;
}

# 5/12
sub cs_regexp_ok {
    my $ok  = 1;

    ($ok = (cs_regexp( rand_cs() ) eq $regexp)) or return $ok;
    ($ok = (ci_regexp( @cs ) ne $regexp));

    return $ok;
}

# 6/12
sub cs_lex_depop_ok {
    my $ok = 1;

    foreach (rand_cs()) {
        ($ok = $lexicon->contains( $_ )) or last;
        ($ok = ($_ =~ $regexp)) or last;
        ($ok = ($_ eq $lexicon->remove( $_ )));
        $regexp = $lexicon->as_regexp();
        ($regexp eq $lex_empty_regexp) and $regexp = $use_empty_regexp;
        ($ok = not $lexicon->contains( $_ )) or last;
        ($ok = ($_ !~ $regexp)) or last;
    }

    return $ok;
}

# Case Insensistive Tests: (7-12)/12

# 7/12
sub ci_lex_pop_ok {
    my $ok = 1;

    $lexicon  = Tree::Lexicon->new( 0 );
    $regexp   = $use_empty_regexp;
    
    foreach (rand_ci()) {
        ($ok = not $lexicon->contains( $_ )) or last;
        ($ok = ($_ !~ $regexp)) or last;
        $lexicon->insert( $_ );
        $regexp = $lexicon->as_regexp();
        ($ok = $lexicon->contains( $_ )) or last;
        ($ok = ($_ =~ $regexp)) or last;
    }

    return $ok;
}

# 8/12
sub ci_lex_cmp_ok {
    my $ok  = 1;
    my $lex;
    my $re;

    $lex = Tree::Lexicon->new( 0 )->insert( @ci );
    $re  = $lex->as_regexp();
    ($ok = ($re eq $regexp)) or return $ok;

    $lex = Tree::Lexicon->new( 0 )->insert( reverse @ci );
    $re  = $lex->as_regexp();
    $ok = ($re eq $regexp);

    return $ok;
}

# 9/12
sub ci_lex_vocab_ok {
    my $ok  = 1;
    my @vocab = $lexicon->vocabulary();

    if ($ok = (@vocab == @ci)) {
        foreach (@ci) {
            ($ok = ($_ eq shift @vocab)) or last;
        }
    }
    
    return $ok;
}

# 10/12
sub ci_lex_auto_ok {
    my $ok  = 1;
    
    foreach (keys %ci_hash) {
        my @vals = @{$ci_hash{$_}};
        my @auto = $lexicon->auto_complete( $_ );

        if ($ok = (@vals == @auto)) {
            foreach (@vals) {
                ($ok = ($_ eq shift @auto)) or last;
            }
        }
    }
    
    return $ok;
}

# 11/12
sub ci_regexp_ok {
    my $ok  = 1;

    ($ok = (cs_regexp( rand_ci() ) ne $regexp)) or return $ok;
    ($ok = (ci_regexp( @ci ) eq $regexp));

    return $ok;
}

# 12/12
sub ci_lex_depop_ok {
    my $ok = 1;

    foreach (rand_ci()) {
        ($ok = $lexicon->contains( $_ )) or last;
        ($ok = ($_ =~ $regexp)) or last;
        ($ok = ($_ eq $lexicon->remove( $_ )));
        $regexp = $lexicon->as_regexp();
        ($regexp eq $lex_empty_regexp) and $regexp = $use_empty_regexp;
        ($ok = not $lexicon->contains( $_ )) or last;
        ($ok = ($_ !~ $regexp)) or last;
    }
    
    return $ok;
}
