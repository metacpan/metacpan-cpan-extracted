# Regexp::Assemple.pm
#
# Copyright (c) 2004-2008 David Landgren
# All rights reserved

package Regexp::Assemble;

use vars qw/$VERSION $have_Storable $Current_Lexer $Default_Lexer $Single_Char $Always_Fail/;
$VERSION = '0.34';

use strict;

use constant DEBUG_ADD  => 1;
use constant DEBUG_TAIL => 2;
use constant DEBUG_LEX  => 4;
use constant DEBUG_TIME => 8;

# The following patterns were generated with eg/naive
$Default_Lexer = qr/(?![[(\\]).(?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?|\\(?:[bABCEGLQUXZ]|[lu].|(?:[^\w]|[aefnrtdDwWsS]|c.|0\d{2}|x(?:[\da-fA-F]{2}|{[\da-fA-F]{4}})|N\{\w+\}|[Pp](?:\{\w+\}|.))(?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?)|\[.*?(?<!\\)\](?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?|\(.*?(?<!\\)\)(?:[*+?]\??|\{\d+(?:,\d*)?\}\??)?/; # ]) restore equilibrium

$Single_Char   = qr/^(?:\\(?:[aefnrtdDwWsS]|c.|[^\w\/{|}-]|0\d{2}|x(?:[\da-fA-F]{2}|{[\da-fA-F]{4}}))|[^\$^])$/;

# the pattern to return when nothing has been added (and thus not match anything)
$Always_Fail = "^\\b\0";

sub new {
    my $class = shift;
    my %args  = @_;

    my $anc;
    for $anc (qw(word line string)) {
        if (exists $args{"anchor_$anc"}) {
            my $val = delete $args{"anchor_$anc"};
            for my $anchor ("anchor_${anc}_begin", "anchor_${anc}_end") {
                $args{$anchor} = $val unless exists $args{$anchor};
            }
        }
    }

    # anchor_string_absolute sets anchor_string_begin and anchor_string_end_absolute
    if (exists $args{anchor_string_absolute}) {
        my $val = delete $args{anchor_string_absolute};
        for my $anchor (qw(anchor_string_begin anchor_string_end_absolute)) {
            $args{$anchor} = $val unless exists $args{$anchor};
        }
    }

    exists $args{$_} or $args{$_} = 0 for qw(
        anchor_word_begin
        anchor_word_end
        anchor_line_begin
        anchor_line_end
        anchor_string_begin
        anchor_string_end
        anchor_string_end_absolute
        debug
        dup_warn
        indent
        lookahead
        mutable
        track
        unroll_plus
    );

    exists $args{$_} or $args{$_} = 1 for qw(
        fold_meta_pairs
        reduce
        chomp
    );

    @args{qw(re str path)} = (undef, undef, []);

    $args{flags} ||= delete $args{modifiers} || '';
    $args{lex}     = $Current_Lexer if defined $Current_Lexer;

    my $self = bless \%args, $class;

    if ($self->_debug(DEBUG_TIME)) {
        $self->_init_time_func();
        $self->{_begin_time} = $self->{_time_func}->();
    }
    $self->{input_record_separator} = delete $self->{rs}
        if exists $self->{rs};
    exists $self->{file} and $self->add_file($self->{file});

    return $self;
}

sub _init_time_func {
    my $self = shift;
    return if exists $self->{_time_func};

    # attempt to improve accuracy
    if (!defined($self->{_use_time_hires})) {
        eval {require Time::HiRes};
        $self->{_use_time_hires} = $@;
    }
    $self->{_time_func} = length($self->{_use_time_hires}) > 0
        ? sub { time }
        : \&Time::HiRes::time
    ;
}

sub clone {
    my $self = shift;
    my $clone;
    my @attr = grep {$_ ne 'path'} keys %$self;
    @{$clone}{@attr} = @{$self}{@attr};
    $clone->{path}   = _path_clone($self->_path);
    bless $clone, ref($self);
}

sub _fastlex {
    my $self   = shift;
    my $record = shift;
    my $len    = 0;
    my @path   = ();
    my $case   = '';
    my $qm     = '';

    my $debug       = $self->{debug} & DEBUG_LEX;
    my $unroll_plus = $self->{unroll_plus};

    my $token;
    my $qualifier;
    $debug and print "# _lex <$record>\n";
    my $modifier        = q{(?:[*+?]\\??|\\{(?:\\d+(?:,\d*)?|,\d+)\\}\\??)?};
    my $class_matcher   = qr/\[(?:\[:[a-z]+:\]|\\?.)*?\]/;
    my $paren_matcher   = qr/\(.*?(?<!\\)\)$modifier/;
    my $misc_matcher    = qr/(?:(c)(.)|(0)(\d{2}))($modifier)/;
    my $regular_matcher = qr/([^\\[(])($modifier)/;
    my $qm_matcher      = qr/(\\?.)/;

    my $matcher = $regular_matcher;
    {
        if ($record =~ /\G$matcher/gc) {
            # neither a \\ nor [ nor ( followed by a modifer
            if ($1 eq '\\E') {
                $debug and print "#   E\n";
                $case = $qm = '';
                $matcher = $regular_matcher;
                redo;
            }
            elsif ($qm and ($1 eq '\\L' or $1 eq '\\U')) {
                $debug and print "#  ignore \\L, \\U\n";
                redo;
            }
            $token = $1;
            $qualifier = defined $2 ? $2 : '';
            $debug and print "#  token <$token> <$qualifier>\n";
            if ($qm) {
                $token = quotemeta($token);
                $token =~ s/^\\([^\w$()*+.?@\[\\\]^|{}\/])$/$1/;
            }
            else {
                $token =~ s{\A([][{}*+?@\\/])\Z}{\\$1};
            }
            if ($unroll_plus and $qualifier =~ s/\A\+(\?)?\Z/*/) {
                $1 and $qualifier .= $1;
                $debug and print " unroll <$token><$token><$qualifier>\n";
                $case and $token = $case eq 'L' ? lc($token) : uc($token);
                push @path, $token, "$token$qualifier";
            }
            else {
                $debug and print " clean <$token>\n";
                push @path,
                      $case eq 'L' ? lc($token).$qualifier
                    : $case eq 'U' ? uc($token).$qualifier
                    :                   $token.$qualifier
                    ;
            }
            redo;
        }

        elsif ($record =~ /\G\\/gc) {
            $debug and print "#  backslash\n";
            # backslash
            if ($record =~ /\G([sdwSDW])($modifier)/gc) {
                ($token, $qualifier) = ($1, $2);
                $debug and print "#   meta <$token> <$qualifier>\n";
                push @path, ($unroll_plus and $qualifier =~ s/\A\+(\?)?\Z/*/)
                    ? ("\\$token", "\\$token$qualifier" . (defined $1 ? $1 : ''))
                    : "\\$token$qualifier";
            }
            elsif ($record =~ /\Gx([\da-fA-F]{2})($modifier)/gc) {
                $debug and print "#   x $1\n";
                $token = quotemeta(chr(hex($1)));
                $qualifier = $2;
                $debug and print "#  cooked <$token>\n";
                $token =~ s/^\\([^\w$()*+.?\[\\\]^|{\/])$/$1/; # } balance
                $debug and print "#   giving <$token>\n";
                push @path, ($unroll_plus and $qualifier =~ s/\A\+(\?)?\Z/*/)
                    ? ($token, "$token$qualifier" . (defined $1 ? $1 : ''))
                    : "$token$qualifier";
            }
            elsif ($record =~ /\GQ/gc) {
                $debug and print "#   Q\n";
                $qm = 1;
                $matcher = $qm_matcher;
            }
            elsif ($record =~ /\G([LU])/gc) {
                $debug and print "#   case $1\n";
                $case = $1;
            }
            elsif ($record =~ /\GE/gc) {
                $debug and print "#   E\n";
                $case = $qm = '';
                $matcher = $regular_matcher;
            }
            elsif ($record =~ /\G([lu])(.)/gc) {
                $debug and print "#   case $1 to <$2>\n";
                push @path, $1 eq 'l' ? lc($2) : uc($2);
            }
            elsif (my @arg = grep {defined} $record =~ /\G$misc_matcher/gc) {
                if ($] < 5.007) {
                    my $len = 0;
                    $len += length($_) for @arg;
                    $debug and print "#  pos ", pos($record), " fixup add $len\n";
                    pos($record) = pos($record) + $len;
                }
                my $directive = shift @arg;
                if ($directive eq 'c') {
                    $debug and print "#  ctrl <@arg>\n";
                    push @path, "\\c" . uc(shift @arg);
                }
                else { # elsif ($directive eq '0') {
                    $debug and print "#  octal <@arg>\n";
                    my $ascii = oct(shift @arg);
                    push @path, ($ascii < 32)
                        ? "\\c" . chr($ascii+64)
                        : chr($ascii)
                    ;
                }
                $path[-1] .= join( '', @arg ); # if @arg;
                redo;
            }
            elsif ($record =~ /\G(.)/gc) {
                $token = $1;
                $token =~ s{[AZabefnrtz\[\]{}()\\\$*+.?@|/^]}{\\$token};
                $debug and print "#   meta <$token>\n";
                push @path, $token;
            }
            else {
                $debug and print "#   ignore char at ", pos($record), " of <$record>\n";
            }
            redo;
        }

        elsif ($record =~ /\G($class_matcher)($modifier)/gc) {
            # [class] followed by a modifer
            my $class     = $1;
            my $qualifier = defined $2 ? $2 : '';
            $debug and print "#  class begin <$class> <$qualifier>\n";
            if ($class =~ /\A\[\\?(.)]\Z/) {
                $class = quotemeta $1;
                $class =~ s{\A\\([!@%])\Z}{$1};
                $debug and print "#  class unwrap $class\n";
            }
            $debug and print "#  class end <$class> <$qualifier>\n";
            push @path, ($unroll_plus and $qualifier =~ s/\A\+(\?)?\Z/*/)
                ? ($class, "$class$qualifier" . (defined $1 ? $1 : ''))
                : "$class$qualifier";
            redo;
        }

        elsif ($record =~ /\G($paren_matcher)/gc) {
            $debug and print "#  paren <$1>\n";
            # (paren) followed by a modifer
            push @path, $1;
            redo;
        }

    }
    return \@path;
}

sub _lex {
    my $self   = shift;
    my $record = shift;
    my $len    = 0;
    my @path   = ();
    my $case   = '';
    my $qm     = '';
    my $re     = defined $self->{lex} ? $self->{lex}
        : defined $Current_Lexer ? $Current_Lexer
        : $Default_Lexer;
    my $debug  = $self->{debug} & DEBUG_LEX;
    $debug and print "# _lex <$record>\n";
    my ($token, $next_token, $diff, $token_len);
    while( $record =~ /($re)/g ) {
        $token = $1;
        $token_len = length($token);
        $debug and print "# lexed <$token> len=$token_len\n";
        if( pos($record) - $len > $token_len ) {
            $next_token = $token;
            $token = substr( $record, $len, $diff = pos($record) - $len - $token_len );
            $debug and print "#  recover <", substr( $record, $len, $diff ), "> as <$token>, save <$next_token>\n";
            $len += $diff;
        }
        $len += $token_len;
        TOKEN: {
            if( substr( $token, 0, 1 ) eq '\\' ) {
                if( $token =~ /^\\([ELQU])$/ ) {
                    if( $1 eq 'E' ) {
                        $qm and $re = defined $self->{lex} ? $self->{lex}
                            : defined $Current_Lexer ? $Current_Lexer
                            : $Default_Lexer;
                        $case = $qm = '';
                    }
                    elsif( $1 eq 'Q' ) {
                        $qm = $1;
                        # switch to a more precise lexer to quotemeta individual characters
                        $re = qr/\\?./;
                    }
                    else {
                        $case = $1;
                    }
                    $debug and print "#  state change qm=<$qm> case=<$case>\n";
                    goto NEXT_TOKEN;
                }
                elsif( $token =~ /^\\([lu])(.)$/ ) {
                    $debug and print "#  apply case=<$1> to <$2>\n";
                    push @path, $1 eq 'l' ? lc($2) : uc($2);
                    goto NEXT_TOKEN;
                }
                elsif( $token =~ /^\\x([\da-fA-F]{2})$/ ) {
                    $token = quotemeta(chr(hex($1)));
                    $debug and print "#  cooked <$token>\n";
                    $token =~ s/^\\([^\w$()*+.?@\[\\\]^|{\/])$/$1/; # } balance
                    $debug and print "#   giving <$token>\n";
                }
                else {
                    $token =~ s/^\\([^\w$()*+.?@\[\\\]^|{\/])$/$1/; # } balance
                    $debug and print "#  backslashed <$token>\n";
                }
            }
            else {
                $case and $token = $case eq 'U' ? uc($token) : lc($token);
                $qm   and $token = quotemeta($token);
                $token = '\\/' if $token eq '/';
            }
            # undo quotemeta's brute-force escapades
            $qm and $token =~ s/^\\([^\w$()*+.?@\[\\\]^|{}\/])$/$1/;
            $debug and print "#   <$token> case=<$case> qm=<$qm>\n";
            push @path, $token;

            NEXT_TOKEN:
            if( defined $next_token ) {
                $debug and print "#   redo <$next_token>\n";
                $token = $next_token;
                $next_token = undef;
                redo TOKEN;
            }
        }
    }
    if( $len < length($record) ) {
        # NB: the remainder only arises in the case of degenerate lexer,
        # and if \Q is operative, the lexer will have been switched to
        # /\\?./, which means there can never be a remainder, so we
        # don't have to bother about quotemeta. In other words:
        # $qm will never be true in this block.
        my $remain = substr($record,$len); 
        $case and $remain = $case eq 'U' ? uc($remain) : lc($remain);
        $debug and print "#   add remaining <$remain> case=<$case> qm=<$qm>\n";
        push @path, $remain;
    }
    $debug and print "# _lex out <@path>\n";
    return \@path;
}

sub add {
    my $self = shift;
    my $record;
    my $debug  = $self->{debug} & DEBUG_LEX;
    while( defined( $record = shift @_ )) {
        CORE::chomp($record) if $self->{chomp};
        next if $self->{pre_filter} and not $self->{pre_filter}->($record);
        $debug and print "# add <$record>\n";
        $self->{stats_raw} += length $record;
        my $list = $record =~ /[+*?(\\\[{]/ # }]) restore equilibrium
            ? $self->{lex} ? $self->_lex($record) : $self->_fastlex($record)
            : [split //, $record]
        ;
        next if $self->{filter} and not $self->{filter}->(@$list);
        $self->_insertr( $list );
    }
    return $self;
}

sub add_file {
    my $self = shift;
    my $rs;
    my @file;
    if (ref($_[0]) eq 'HASH') {
        my $arg = shift;
        $rs = $arg->{rs}
            || $arg->{input_record_separator}
            || $self->{input_record_separator}
            || $/;
        @file = ref($arg->{file}) eq 'ARRAY'
            ? @{$arg->{file}}
            : $arg->{file};
    }
    else {
        $rs   = $self->{input_record_separator} || $/;
        @file = @_;
    }
    local $/ = $rs;
    my $file;
    for $file (@file) {
        open my $fh, '<', $file or do {
            require Carp;
            Carp::croak("cannot open $file for input: $!");
        };
        while (defined (my $rec = <$fh>)) {
            $self->add($rec);
        }
        close $fh;
    }
    return $self;
}

sub insert {
    my $self = shift;
    return if $self->{filter} and not $self->{filter}->(@_);
    $self->_insertr( [@_] );
    return $self;
}

sub _insertr {
    my $self   = shift;
    my $dup    = $self->{stats_dup} || 0;
    $self->{path} = $self->_insert_path( $self->_path, $self->_debug(DEBUG_ADD), $_[0] );
    if( not defined $self->{stats_dup} or $dup == $self->{stats_dup} ) {
        ++$self->{stats_add};
        $self->{stats_cooked} += defined($_) ? length($_) : 0 for @{$_[0]};
    }
    elsif( $self->{dup_warn} ) {
        if( ref $self->{dup_warn} eq 'CODE' ) {
            $self->{dup_warn}->($self, $_[0]); 
        }
        else {
            my $pattern = join( '', @{$_[0]} );
            require Carp;
            Carp::carp("duplicate pattern added: /$pattern/");
        }
    }
    $self->{str} = $self->{re} = undef;
}

sub lexstr {
    return shift->_lex(shift);
}

sub pre_filter {
    my $self   = shift;
    my $pre_filter = shift;
    if( defined $pre_filter and ref($pre_filter) ne 'CODE' ) {
        require Carp;
        Carp::croak("pre_filter method not passed a coderef");
    }
    $self->{pre_filter} = $pre_filter;
    return $self;
}


sub filter {
    my $self   = shift;
    my $filter = shift;
    if( defined $filter and ref($filter) ne 'CODE' ) {
        require Carp;
        Carp::croak("filter method not passed a coderef");
    }
    $self->{filter} = $filter;
    return $self;
}

sub as_string {
    my $self = shift;
    if( not defined $self->{str} ) {
        if( $self->{track} ) {
            $self->{m}      = undef;
            $self->{mcount} = 0;
            $self->{mlist}  = [];
            $self->{str}    = _re_path_track($self, $self->_path, '', '');
        }
        else {
            $self->_reduce unless ($self->{mutable} or not $self->{reduce});
            my $arg  = {@_};
            $arg->{indent} = $self->{indent}
                if not exists $arg->{indent} and $self->{indent} > 0;
            if( exists $arg->{indent} and $arg->{indent} > 0 ) {
                $arg->{depth} = 0;
                $self->{str}  = _re_path_pretty($self, $self->_path, $arg);
            }
            elsif( $self->{lookahead} ) {
                $self->{str}  = _re_path_lookahead($self, $self->_path);
            }
            else {
                $self->{str}  = _re_path($self, $self->_path);
            }
        }
        if (not length $self->{str}) {
            # explicitly fail to match anything if no pattern was generated
            $self->{str} = $Always_Fail;
        }
        else {
            my $begin = 
                  $self->{anchor_word_begin}   ? '\\b'
                : $self->{anchor_line_begin}   ? '^'
                : $self->{anchor_string_begin} ? '\A'
                : ''
            ;
            my $end = 
                  $self->{anchor_word_end}            ? '\\b'
                : $self->{anchor_line_end}            ? '$'
                : $self->{anchor_string_end}          ? '\Z'
                : $self->{anchor_string_end_absolute} ? '\z'
                : ''
            ;
            $self->{str} = "$begin$self->{str}$end";
        }
        $self->{path} = [] unless $self->{mutable};
    }
    return $self->{str};
}

sub re {
    my $self = shift;
    $self->_build_re($self->as_string(@_)) unless defined $self->{re};
    return $self->{re};
}

use overload '""' => sub {
    my $self = shift;
    return $self->{re} if $self->{re};
    $self->_build_re($self->as_string());
    return $self->{re};
};

sub _build_re {
    my $self  = shift;
    my $str   = shift;
    if( $self->{track} ) {
        use re 'eval';
        $self->{re} = length $self->{flags}
            ? qr/(?$self->{flags}:$str)/
            : qr/$str/
        ;
    }
    else {
        # how could I not repeat myself?
        $self->{re} = length $self->{flags}
            ? qr/(?$self->{flags}:$str)/
            : qr/$str/
        ;
    }
}

sub match {
    my $self = shift;
    my $target = shift;
    $self->_build_re($self->as_string(@_)) unless defined $self->{re};
    $self->{m}    = undef;
    $self->{mvar} = [];
    if( not $target =~ /$self->{re}/ ) {
        $self->{mbegin} = [];
        $self->{mend}   = [];
        return undef;
    }
    $self->{m}      = $^R if $] >= 5.009005;
    $self->{mbegin} = _path_copy([@-]);
    $self->{mend}   = _path_copy([@+]);
    my $n = 0;
    for( my $n = 0; $n < @-; ++$n ) {
        push @{$self->{mvar}}, substr($target, $-[$n], $+[$n] - $-[$n])
            if defined $-[$n] and defined $+[$n];
    }
    if( $self->{track} ) {
        return defined $self->{m} ? $self->{mlist}[$self->{m}] : 1;
    }
    else {
        return 1;
    }
}

sub source {
    my $self = shift;
    return unless $self->{track};
    defined($_[0]) and return $self->{mlist}[$_[0]];
    return unless defined $self->{m};
    return $self->{mlist}[$self->{m}];
}

sub mbegin {
    my $self = shift;
    return exists $self->{mbegin} ? $self->{mbegin} : [];
}

sub mend {
    my $self = shift;
    return exists $self->{mend} ? $self->{mend} : [];
}

sub mvar {
    my $self = shift;
    return undef unless exists $self->{mvar};
    return defined($_[0]) ? $self->{mvar}[$_[0]] : $self->{mvar};
}

sub capture {
    my $self = shift;
    if( $self->{mvar} ) {
        my @capture = @{$self->{mvar}};
        shift @capture;
        return @capture;
    }
    return ();
}

sub matched {
    my $self = shift;
    return defined $self->{m} ? $self->{mlist}[$self->{m}] : undef;
}

sub stats_add {
    my $self = shift;
    return $self->{stats_add} || 0;
}

sub stats_dup {
    my $self = shift;
    return $self->{stats_dup} || 0;
}

sub stats_raw {
    my $self = shift;
    return $self->{stats_raw} || 0;
}

sub stats_cooked {
    my $self = shift;
    return $self->{stats_cooked} || 0;
}

sub stats_length {
    my $self = shift;
    return (defined $self->{str} and $self->{str} ne $Always_Fail) ? length $self->{str} : 0;
}

sub dup_warn {
    my $self = shift;
    $self->{dup_warn} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_word_begin {
    my $self = shift;
    $self->{anchor_word_begin} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_word_end {
    my $self = shift;
    $self->{anchor_word_end} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_word {
    my $self  = shift;
    my $state = shift;
    $self->anchor_word_begin($state)->anchor_word_end($state);
    return $self;
}

sub anchor_line_begin {
    my $self = shift;
    $self->{anchor_line_begin} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_line_end {
    my $self = shift;
    $self->{anchor_line_end} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_line {
    my $self  = shift;
    my $state = shift;
    $self->anchor_line_begin($state)->anchor_line_end($state);
    return $self;
}

sub anchor_string_begin {
    my $self = shift;
    $self->{anchor_string_begin} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_string_end {
    my $self = shift;
    $self->{anchor_string_end} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_string_end_absolute {
    my $self = shift;
    $self->{anchor_string_end_absolute} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub anchor_string {
    my $self  = shift;
    my $state = defined($_[0]) ? $_[0] : 1;
    $self->anchor_string_begin($state)->anchor_string_end($state);
    return $self;
}

sub anchor_string_absolute {
    my $self  = shift;
    my $state = defined($_[0]) ? $_[0] : 1;
    $self->anchor_string_begin($state)->anchor_string_end_absolute($state);
    return $self;
}

sub debug {
    my $self = shift;
    $self->{debug} = defined($_[0]) ? $_[0] : 0;
    if ($self->_debug(DEBUG_TIME)) {
        # hmm, debugging time was switched on after instantiation
        $self->_init_time_func;
        $self->{_begin_time} = $self->{_time_func}->();
    }
    return $self;
}

sub dump {
    return _dump($_[0]->_path);
}

sub chomp {
    my $self = shift;
    $self->{chomp} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub fold_meta_pairs {
    my $self = shift;
    $self->{fold_meta_pairs} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub indent {
    my $self = shift;
    $self->{indent} = defined($_[0]) ? $_[0] : 0;
    return $self;
}

sub lookahead {
    my $self = shift;
    $self->{lookahead} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub flags {
    my $self = shift;
    $self->{flags} = defined($_[0]) ? $_[0] : '';
    return $self;
}

sub modifiers {
    my $self = shift;
    return $self->flags(@_);
}

sub track {
    my $self = shift;
    $self->{track} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub unroll_plus {
    my $self = shift;
    $self->{unroll_plus} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub lex {
    my $self = shift;
    $self->{lex} = qr($_[0]);
    return $self;
}

sub reduce {
    my $self = shift;
    $self->{reduce} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub mutable {
    my $self = shift;
    $self->{mutable} = defined($_[0]) ? $_[0] : 1;
    return $self;
}

sub reset {
    # reinitialise the internal state of the object
    my $self = shift;
    $self->{path} = [];
    $self->{re}   = undef;
    $self->{str}  = undef;
    return $self;
}

sub Default_Lexer {
    if( $_[0] ) {
        if( my $refname = ref($_[0]) ) {
            require Carp;
            Carp::croak("Cannot pass a $refname to Default_Lexer");
        }
        $Current_Lexer = $_[0];
    }
    return defined $Current_Lexer ? $Current_Lexer : $Default_Lexer;
}

# --- no user serviceable parts below ---

# -- debug helpers

sub _debug {
    my $self = shift;
    return $self->{debug} & shift() ? 1 : 0;
}

# -- helpers

sub _path {
    # access the path
    return $_[0]->{path};
}

# -- the heart of the matter

$have_Storable = do {
    eval {
        require Storable;
        import Storable 'dclone';
    };
    $@ ? 0 : 1;
};

sub _path_clone {
    $have_Storable ? dclone($_[0]) : _path_copy($_[0]);
}

sub _path_copy {
    my $path = shift;
    my $new  = [];
    for( my $p = 0; $p < @$path; ++$p ) {
        if( ref($path->[$p]) eq 'HASH' ) {
            push @$new, _node_copy($path->[$p]);
        }
        elsif( ref($path->[$p]) eq 'ARRAY' ) {
            push @$new, _path_copy($path->[$p]);
        }
        else {
            push @$new, $path->[$p];
        }
    }
    return $new;
}

sub _node_copy {
    my $node = shift;
    my $new  = {};
    while( my( $k, $v ) = each %$node ) {
        $new->{$k} = defined($v)
            ? _path_copy($v)
            : undef
        ;
    }
    return $new;
}

sub _insert_path {
    my $self  = shift;
    my $list  = shift;
    my $debug = shift;
    my @in    = @{shift()}; # create a new copy
    if( @$list == 0 ) { # special case the first time
        if( @in == 0 or (@in == 1 and (not defined $in[0] or $in[0] eq ''))) {
            return [{'' => undef}];
        }
        else {
            return \@in;
        }
    }
    $debug and print "# _insert_path @{[_dump(\@in)]} into @{[_dump($list)]}\n";
    my $path   = $list;
    my $offset = 0;
    my $token;
    if( not @in ) {
        if( ref($list->[0]) ne 'HASH' ) {
            return [ { '' => undef, $list->[0] => $list } ];
        }
        else {
            $list->[0]{''} = undef;
            return $list;
        }
    }
    while( defined( $token = shift @in )) {
        if( ref($token) eq 'HASH' ) {
            $debug and print "#  p0=", _dump($path), "\n";
            $path = $self->_insert_node( $path, $offset, $token, $debug, @in );
            $debug and print "#  p1=", _dump($path), "\n";
            last;
        }
        if( ref($path->[$offset]) eq 'HASH' ) {
            $debug and print "#   at (off=$offset len=@{[scalar @$path]}) ", _dump($path->[$offset]), "\n";
            my $node = $path->[$offset];
            if( exists( $node->{$token} )) {
                if ($offset < $#$path) {
                    my $new = {
                        $token => [$token, @in],
                        _re_path($self, [$node]) => [@{$path}[$offset..$#$path]],
                    };
                    splice @$path, $offset, @$path-$offset, $new;
                    last;
                }
                else {
                    $debug and print "#   descend key=$token @{[_dump($node->{$token})]}\n";
                    $path   = $node->{$token};
                    $offset = 0;
                    redo;
                }
            }
            else {
                $debug and print "#   add path ($token:@{[_dump(\@in)]}) into @{[_dump($path)]} at off=$offset to end=@{[scalar $#$path]}\n";
                if( $offset == $#$path ) {
                    $node->{$token} = [ $token, @in ];
                }
                else {
                    my $new = {
                        _node_key($token) => [ $token, @in ],
                        _node_key($node)  => [@{$path}[$offset..$#{$path}]],
                    };
                    splice( @$path, $offset, @$path - $offset, $new );
                    $debug and print "#   fused node=@{[_dump($new)]} path=@{[_dump($path)]}\n";
                }
                last;
            }
        }

        if( $debug ) {
            my $msg = '';
            my $n;
            for( $n = 0; $n < @$path; ++$n ) {
                $msg .= ' ' if $n;
                my $atom = ref($path->[$n]) eq 'HASH'
                    ? '{'.join( ' ', keys(%{$path->[$n]})).'}'
                    : $path->[$n]
                ;
                $msg .= $n == $offset ? "<$atom>" : $atom;
            }
            print "# at path ($msg)\n";
        }

        if( $offset >= @$path ) {
            push @$path, { $token => [ $token, @in ], '' => undef };
            $debug and print "#   added remaining @{[_dump($path)]}\n";
            last;
        }
        elsif( $token ne $path->[$offset] ) {
            $debug and print "#   token $token not present\n";
            splice @$path, $offset, @$path-$offset, {
                length $token
                    ? ( _node_key($token) => [$token, @in])
                    : ( '' => undef )
                ,
                $path->[$offset] => [@{$path}[$offset..$#{$path}]],
            };
            $debug and print "#   path=@{[_dump($path)]}\n";
            last;
        }
        elsif( not @in ) {
            $debug and print "#   last token to add\n";
            if( defined( $path->[$offset+1] )) {
                ++$offset;
                if( ref($path->[$offset]) eq 'HASH' ) {
                    $debug and print "#   add sentinel to node\n";
                    $path->[$offset]{''} = undef;
                }
                else {
                    $debug and print "#   convert <$path->[$offset]> to node for sentinel\n";
                    splice @$path, $offset, @$path-$offset, {
                        ''               => undef,
                        $path->[$offset] => [ @{$path}[$offset..$#{$path}] ],
                    };
                }
            }
            else {
                # already seen this pattern
                ++$self->{stats_dup};
            }
            last;
        }
        # if we get here then @_ still contains a token
        ++$offset;
    }
    $list;
}

sub _insert_node {
    my $self   = shift;
    my $path   = shift;
    my $offset = shift;
    my $token  = shift;
    my $debug  = shift;
    my $path_end = [@{$path}[$offset..$#{$path}]];
    # NB: $path->[$offset] and $[path_end->[0] are equivalent
    my $token_key = _re_path($self, [$token]);
    $debug and print "#  insert node(@{[_dump($token)]}:@{[_dump(\@_)]}) (key=$token_key)",
        " at path=@{[_dump($path_end)]}\n";
    if( ref($path_end->[0]) eq 'HASH' ) {
        if( exists($path_end->[0]{$token_key}) ) {
            if( @$path_end > 1 ) {
                my $path_key = _re_path($self, [$path_end->[0]]);
                my $new = {
                    $path_key  => [ @$path_end ],
                    $token_key => [ $token, @_ ],
                };
                $debug and print "#   +bifurcate new=@{[_dump($new)]}\n";
                splice( @$path, $offset, @$path_end, $new );
            }
            else {
                my $old_path = $path_end->[0]{$token_key};
                my $new_path = [];
                while( @$old_path and _node_eq( $old_path->[0], $token )) {
                    $debug and print "#  identical nodes in sub_path ",
                        ref($token) ? _dump($token) : $token, "\n";
                    push @$new_path, shift(@$old_path);
                    $token = shift @_;
                }
                if( @$new_path ) {
                    my $new;
                    my $token_key = $token;
                    if( @_ ) {
                        $new = {
                            _re_path($self, $old_path) => $old_path,
                            $token_key => [$token, @_],
                        };
                        $debug and print "#  insert_node(bifurc) n=@{[_dump([$new])]}\n";
                    }
                    else {
                        $debug and print "#  insert $token into old path @{[_dump($old_path)]}\n";
                        if( @$old_path ) {
                            $new = ($self->_insert_path( $old_path, $debug, [$token] ))->[0];
                        }
                        else {
                            $new = { '' => undef, $token => [$token] };
                        }
                    }
                    push @$new_path, $new;
                }
                $path_end->[0]{$token_key} = $new_path;
                $debug and print "#   +_insert_node result=@{[_dump($path_end)]}\n";
                splice( @$path, $offset, @$path_end, @$path_end );
            }
        }
        elsif( not _node_eq( $path_end->[0], $token )) {
            if( @$path_end > 1 ) {
                my $path_key = _re_path($self, [$path_end->[0]]);
                my $new = {
                    $path_key  => [ @$path_end ],
                    $token_key => [ $token, @_ ],
                };
                $debug and print "#   path->node1 at $path_key/$token_key @{[_dump($new)]}\n";
                splice( @$path, $offset, @$path_end, $new );
            }
            else {
                $debug and print "#   next in path is node, trivial insert at $token_key\n";
                $path_end->[0]{$token_key} = [$token, @_];
                splice( @$path, $offset, @$path_end, @$path_end );
            }
        }
        else {
            while( @$path_end and _node_eq( $path_end->[0], $token )) {
                $debug and print "#  identical nodes @{[_dump([$token])]}\n";
                shift @$path_end;
                $token = shift @_;
                ++$offset;
            }
            if( @$path_end ) {
                $debug and print "#   insert at $offset $token:@{[_dump(\@_)]} into @{[_dump($path_end)]}\n";
                $path_end = $self->_insert_path( $path_end, $debug, [$token, @_] );
                $debug and print "#   got off=$offset s=@{[scalar @_]} path_add=@{[_dump($path_end)]}\n";
                splice( @$path, $offset, @$path - $offset, @$path_end );
                $debug and print "#   got final=@{[_dump($path)]}\n";
            }
            else {
                $token_key = _node_key($token);
                my $new = {
                    ''         => undef,
                    $token_key => [ $token, @_ ],
                };
                $debug and print "#   convert opt @{[_dump($new)]}\n";
                push @$path, $new;
            }
        }
    }
    else {
        if( @$path_end ) {
            my $new = {
                $path_end->[0] => [ @$path_end ],
                $token_key     => [ $token, @_ ],
            };
            $debug and print "#   atom->node @{[_dump($new)]}\n";
            splice( @$path, $offset, @$path_end, $new );
            $debug and print "#   out=@{[_dump($path)]}\n";
        }
        else {
            $debug and print "#   add opt @{[_dump([$token,@_])]} via $token_key\n";
            push @$path, {
                ''         => undef,
                $token_key => [ $token, @_ ],
            };
        }
    }
    $path;
}

sub _reduce {
    my $self    = shift;
    my $context = { debug => $self->_debug(DEBUG_TAIL), depth => 0 };

    if ($self->_debug(DEBUG_TIME)) {
        $self->_init_time_func;
        my $now = $self->{_time_func}->();
        if (exists $self->{_begin_time}) {
            printf "# load=%0.6f\n", $now - $self->{_begin_time};
        }
        else {
            printf "# load-epoch=%0.6f\n", $now;
        }
        $self->{_begin_time} = $self->{_time_func}->();
    }

    my ($head, $tail) = _reduce_path( $self->_path, $context );
    $context->{debug} and print "# final head=", _dump($head), ' tail=', _dump($tail), "\n";
    if( !@$head ) {
        $self->{path} = $tail;
    }
    else {
        $self->{path} = [
            @{_unrev_path( $tail, $context )},
            @{_unrev_path( $head, $context )},
        ];
    }

    if ($self->_debug(DEBUG_TIME)) {
        my $now = $self->{_time_func}->();
        if (exists $self->{_begin_time}) {
            printf "# reduce=%0.6f\n", $now - $self->{_begin_time};
        }
        else {
            printf "# reduce-epoch=%0.6f\n", $now;
        }
        $self->{_begin_time} = $self->{_time_func}->();
    }

    $context->{debug} and print "# final path=", _dump($self->{path}), "\n";
    return $self;
}

sub _remove_optional {
    if( exists $_[0]->{''} ) {
        delete $_[0]->{''};
        return 1;
    }
    return 0;
}

sub _reduce_path {
    my ($path, $ctx) = @_;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};
    $debug and print "#$indent _reduce_path $ctx->{depth} ", _dump($path), "\n";
    my $new;
    my $head = [];
    my $tail = [];
    while( defined( my $p = pop @$path )) {
        if( ref($p) eq 'HASH' ) {
            my ($node_head, $node_tail) = _reduce_node($p, _descend($ctx) );
            $debug and print "#$indent| head=", _dump($node_head), " tail=", _dump($node_tail), "\n";
            push @$head, @$node_head if scalar @$node_head;
            push @$tail, ref($node_tail) eq 'HASH' ? $node_tail : @$node_tail;
        }
        else {
            if( @$head ) {
                $debug and print "#$indent| push $p leaves @{[_dump($path)]}\n";
                push @$tail, $p;
            }
            else {
                $debug and print "#$indent| unshift $p\n";
                unshift @$tail, $p;
            }
        }
    }
    $debug and print "#$indent| tail nr=@{[scalar @$tail]} t0=", ref($tail->[0]),
        (ref($tail->[0]) eq 'HASH' ? " n=" . scalar(keys %{$tail->[0]}) : '' ),
        "\n";
    if( @$tail > 1
        and ref($tail->[0]) eq 'HASH'
        and keys %{$tail->[0]} == 2
    ) {
        my $opt;
        my $fixed;
        while( my ($key, $path) = each %{$tail->[0]} ) {
            $debug and print "#$indent| scan k=$key p=@{[_dump($path)]}\n";
            next unless $path;
            if (@$path == 1 and ref($path->[0]) eq 'HASH') {
                $opt = $path->[0];
            }
            else {
                $fixed = $path;
            }
        }
        if( exists $tail->[0]{''} ) {
            my $path = [@{$tail}[1..$#{$tail}]];
            $tail = $tail->[0];
            ($head, $tail, $path) = _slide_tail( $head, $tail, $path, _descend($ctx) );
            $tail = [$tail, @$path];
        }
    }
    $debug and print "#$indent _reduce_path $ctx->{depth} out head=", _dump($head), ' tail=', _dump($tail), "\n";
    return ($head, $tail);
}

sub _reduce_node {
    my ($node, $ctx) = @_;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};
    my $optional = _remove_optional($node);
    $debug and print "#$indent _reduce_node $ctx->{depth} in @{[_dump($node)]} opt=$optional\n";
    if( $optional and scalar keys %$node == 1 ) {
        my $path = (values %$node)[0];
        if( not grep { ref($_) eq 'HASH' } @$path ) {
            # if we have removed an optional, and there is only one path
            # left then there is nothing left to compare. Because of the
            # optional it cannot participate in any further reductions.
            # (unless we test for equality among sub-trees).
            my $result = {
                ''         => undef,
                $path->[0] => $path
            };
            $debug and print "#$indent| fast fail @{[_dump($result)]}\n";
            return [], $result;
        }
    }

    my( $fail, $reduce ) = _scan_node( $node, _descend($ctx) );

    $debug and print "#$indent|_scan_node done opt=$optional reduce=@{[_dump($reduce)]} fail=@{[_dump($fail)]}\n";

    # We now perform tail reduction on each of the nodes in the reduce
    # hash. If we have only one key, we know we will have a successful
    # reduction (since everything that was inserted into the node based
    # on the value of the last token of each path all mapped to the same
    # value).

    if( @$fail == 0 and keys %$reduce == 1 and not $optional) {
        # every path shares a common path
        my $path = (values %$reduce)[0];
        my ($common, $tail) = _do_reduce( $path, _descend($ctx) );
        $debug and print "#$indent|_reduce_node  $ctx->{depth} common=@{[_dump($common)]} tail=", _dump($tail), "\n";
        return( $common, $tail );
    }

    # this node resulted in a list of paths, game over
    $ctx->{indent} = $indent;
    return _reduce_fail( $reduce, $fail, $optional, _descend($ctx) );
}

sub _reduce_fail {
    my( $reduce, $fail, $optional, $ctx ) = @_;
    my( $debug, $depth, $indent ) = @{$ctx}{qw(debug depth indent)};
    my %result;
    $result{''} = undef if $optional;
    my $p;
    for $p (keys %$reduce) {
        my $path = $reduce->{$p};
        if( scalar @$path == 1 ) {
            $path = $path->[0];
            $debug and print "#$indent| -simple opt=$optional unrev @{[_dump($path)]}\n";
            $path = _unrev_path($path, _descend($ctx) );
            $result{_node_key($path->[0])} = $path;
        }
        else {
            $debug and print "#$indent| _do_reduce(@{[_dump($path)]})\n";
            my ($common, $tail) = _do_reduce( $path, _descend($ctx) );
            $path = [
                (
                    ref($tail) eq 'HASH'
                        ? _unrev_node($tail, _descend($ctx) )
                        : _unrev_path($tail, _descend($ctx) )
                ),
                @{_unrev_path($common, _descend($ctx) )}
            ];
            $debug and print "#$indent| +reduced @{[_dump($path)]}\n";
            $result{_node_key($path->[0])} = $path;
        }
    }
    my $f;
    for $f( @$fail ) {
        $debug and print "#$indent| +fail @{[_dump($f)]}\n";
        $result{$f->[0]} = $f;
    }
    $debug and print "#$indent _reduce_fail $depth fail=@{[_dump(\%result)]}\n";
    return ( [], \%result );
}

sub _scan_node {
    my( $node, $ctx ) = @_;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};

    # For all the paths in the node, reverse them. If the first token
    # of the path is a scalar, push it onto an array in a hash keyed by
    # the value of the scalar.
    #
    # If it is a node, call _reduce_node on this node beforehand. If we
    # get back a common head, all of the paths in the subnode shared a
    # common tail. We then store the common part and the remaining node
    # of paths (which is where the paths diverged from the end and install
    # this into the same hash. At this point both the common and the tail
    # are in reverse order, just as simple scalar paths are.
    #
    # On the other hand, if there were no common path returned then all
    # the paths of the sub-node diverge at the end character. In this
    # case the tail cannot participate in any further reductions and will
    # appear in forward order.
    #
    # certainly the hurgliest function in the whole file :(

    # $debug = 1 if $depth >= 8;
    my @fail;
    my %reduce;

    my $n;
    for $n(
        map { substr($_, index($_, '#')+1) }
        sort
        map {
            join( '|' =>
                scalar(grep {ref($_) eq 'HASH'} @{$node->{$_}}),
                _node_offset($node->{$_}),
                scalar @{$node->{$_}},
            )
            . "#$_"
        }
    keys %$node ) {
        my( $end, @path ) = reverse @{$node->{$n}};
        if( ref($end) ne 'HASH' ) {
            $debug and print "# $indent|_scan_node push reduce ($end:@{[_dump(\@path)]})\n";
            push @{$reduce{$end}}, [ $end, @path ];
        }
        else {
            $debug and print "# $indent|_scan_node head=", _dump(\@path), ' tail=', _dump($end), "\n";
            my $new_path;
            # deal with sing, singing => s(?:ing)?ing
            if( keys %$end == 2 and exists $end->{''} ) {
                my ($key, $opt_path) = each %$end;
                ($key, $opt_path) = each %$end if $key eq '';
                $opt_path = [reverse @{$opt_path}];
                $debug and print "# $indent| check=", _dump($opt_path), "\n";
                my $end = { '' => undef, $opt_path->[0] => [@$opt_path] };
                my $head = [];
                my $path = [@path];
                ($head, my $slide, $path) = _slide_tail( $head, $end, $path, $ctx );
                if( @$head ) {
                    $new_path = [ @$head, $slide, @$path ];
                }
            }
            if( $new_path ) {
                $debug and print "# $indent|_scan_node slid=", _dump($new_path), "\n";
                push @{$reduce{$new_path->[0]}}, $new_path;
            }
            else {
                my( $common, $tail ) = _reduce_node( $end, _descend($ctx) );
                    if( not @$common ) {
                    $debug and print "# $indent| +failed $n\n";
                    push @fail, [reverse(@path), $tail];
                }
                else {
                    my $path = [@path];
                    $debug and print "# $indent|_scan_node ++recovered common=@{[_dump($common)]} tail=",
                        _dump($tail), " path=@{[_dump($path)]}\n";
                    if( ref($tail) eq 'HASH'
                        and keys %$tail == 2
                    ) {
                        if( exists $tail->{''} ) {
                            ($common, $tail, $path) = _slide_tail( $common, $tail, $path, $ctx );
                        }
                    }
                    push @{$reduce{$common->[0]}}, [
                        @$common, 
                        (ref($tail) eq 'HASH' ? $tail : @$tail ),
                        @$path
                    ];
                }
            }
        }
    }
    $debug and print
        "# $indent|_scan_node counts: reduce=@{[scalar keys %reduce]} fail=@{[scalar @fail]}\n";
    return( \@fail, \%reduce );
}

sub _do_reduce {
    my ($path, $ctx) = @_;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};
    my $ra = Regexp::Assemble->new(chomp=>0);
    $ra->debug($debug);
    $debug and print "# $indent| do @{[_dump($path)]}\n";
    $ra->_insertr( $_ ) for
        # When nodes come into the picture, we have to be careful
        # about how we insert the paths into the assembly.
        # Paths with nodes first, then closest node to front
        # then shortest path. Merely because if we can control
        # order in which paths containing nodes get inserted,
        # then we can make a couple of assumptions that simplify
        # the code in _insert_node.
        sort {
            scalar(grep {ref($_) eq 'HASH'} @$a)
            <=> scalar(grep {ref($_) eq 'HASH'} @$b)
                ||
            _node_offset($b) <=> _node_offset($a)
                ||
            scalar @$a <=> scalar @$b
        }
        @$path
    ;
    $path = $ra->_path;
    my $common = [];
    push @$common, shift @$path while( ref($path->[0]) ne 'HASH' );
    my $tail = scalar( @$path ) > 1 ? [@$path] : $path->[0];
    $debug and print "# $indent| _do_reduce common=@{[_dump($common)]} tail=@{[_dump($tail)]}\n";
    return ($common, $tail);
}

sub _node_offset {
    # return the offset that the first node is found, or -ve
    # optimised for speed
    my $nr = @{$_[0]};
    my $atom = -1;
    ref($_[0]->[$atom]) eq 'HASH' and return $atom while ++$atom < $nr;
    return -1;
}

sub _slide_tail {
    my $head   = shift;
    my $tail   = shift;
    my $path   = shift;
    my $ctx    = shift;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};
    $debug and print "# $indent| slide in h=", _dump($head),
        ' t=', _dump($tail), ' p=', _dump($path), "\n";
    my $slide_path = (each %$tail)[-1];
    $slide_path = (each %$tail)[-1] unless defined $slide_path;
    $debug and print "# $indent| slide potential ", _dump($slide_path), " over ", _dump($path), "\n";
    while( defined $path->[0] and $path->[0] eq $slide_path->[0] ) {
        $debug and print "# $indent| slide=tail=$slide_path->[0]\n";
        my $slide = shift @$path;
        shift @$slide_path;
        push @$slide_path, $slide;
        push @$head, $slide;
    }
    $debug and print "# $indent| slide path ", _dump($slide_path), "\n";
    my $slide_node = {
        '' => undef,
        _node_key($slide_path->[0]) => $slide_path,
    };
    $debug and print "# $indent| slide out h=", _dump($head),
        ' s=', _dump($slide_node), ' p=', _dump($path), "\n";
    return ($head, $slide_node, $path);
}

sub _unrev_path {
    my ($path, $ctx) = @_;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};
    my $new;
    if( not grep { ref($_) } @$path ) {
        $debug and print "# ${indent}_unrev path fast ", _dump($path);
        $new = [reverse @$path];
        $debug and print "#  -> ", _dump($new), "\n";
        return $new;
    }
    $debug and print "# ${indent}unrev path in ", _dump($path), "\n";
    while( defined( my $p = pop @$path )) {
        push @$new,
              ref($p) eq 'HASH'  ? _unrev_node($p, _descend($ctx) )
            : ref($p) eq 'ARRAY' ? _unrev_path($p, _descend($ctx) )
            : $p
        ;
    }
    $debug and print "# ${indent}unrev path out ", _dump($new), "\n";
    return $new;
}

sub _unrev_node {
    my ($node, $ctx ) = @_;
    my $indent = ' ' x $ctx->{depth};
    my $debug  =       $ctx->{debug};
    my $optional = _remove_optional($node);
    $debug and print "# ${indent}unrev node in ", _dump($node), " opt=$optional\n";
    my $new;
    $new->{''} = undef if $optional;
    my $n;
    for $n( keys %$node ) {
        my $path = _unrev_path($node->{$n}, _descend($ctx) );
        $new->{_node_key($path->[0])} = $path;
    }
    $debug and print "# ${indent}unrev node out ", _dump($new), "\n";
    return $new;
}

sub _node_key {
    my $node = shift;
    return _node_key($node->[0]) if ref($node) eq 'ARRAY';
    return $node unless ref($node) eq 'HASH';
    my $key = '';
    my $k;
    for $k( keys %$node ) {
        next if $k eq '';
        $key = $k if $key eq '' or $key gt $k;
    }
    return $key;
}

sub _descend {
    # Take a context object, and increase the depth by one.
    # By creating a fresh hash each time, we don't have to
    # bother adding make-work code to decrease the depth
    # when we return from what we called.
    my $ctx = shift;
    return {%$ctx, depth => $ctx->{depth}+1};
}

#####################################################################

sub _make_class {
    my $self = shift;
    my %set = map { ($_,1) } @_;
    delete $set{'\\d'} if exists $set{'\\w'};
    delete $set{'\\D'} if exists $set{'\\W'};
    return '.' if exists $set{'.'}
        or ($self->{fold_meta_pairs} and (
               (exists $set{'\\d'} and exists $set{'\\D'})
            or (exists $set{'\\s'} and exists $set{'\\S'})
            or (exists $set{'\\w'} and exists $set{'\\W'})
        ))
    ;
    for my $meta( q/\\d/, q/\\D/, q/\\s/, q/\\S/, q/\\w/, q/\\W/ ) {
        if( exists $set{$meta} ) {
            my $re = qr/$meta/;
            my @delete;
            $_ =~ /^$re$/ and push @delete, $_ for keys %set;
            delete @set{@delete} if @delete;
        }
    }
    return (keys %set)[0] if keys %set == 1;
    for my $meta( '.', '+', '*', '?', '(', ')', '^', '@', '$', '[', '/', ) {
        exists $set{"\\$meta"} and $set{$meta} = delete $set{"\\$meta"};
    }
    my $dash  = exists $set{'-'} ? do { delete($set{'-'}), '-' } : '';
    my $caret = exists $set{'^'} ? do { delete($set{'^'}), '^' } : '';
    my $class = join( '' => sort keys %set );
    $class =~ s/0123456789/\\d/ and $class eq '\\d' and return $class;
    return "[$dash$class$caret]";
}

sub _re_sort {
    return length $b <=> length $a || $a cmp $b
}

sub _combine {
    my $self = shift;
    my $type = shift;
    # print "c in = @{[_dump(\@_)]}\n";
    # my $combine = 
    return '('
    . $type
    . do {
        my( @short, @long );
        push @{ /^$Single_Char$/ ? \@short : \@long}, $_ for @_;
        if( @short == 1 ) {
            @long = sort _re_sort @long, @short;
        }
        elsif( @short > 1 ) {
            # yucky but true
            my @combine = (_make_class($self, @short), sort _re_sort @long);
            @long = @combine;
        }
        else {
            @long = sort _re_sort @long;
        }
        join( '|', @long );
    }
    . ')';
    # print "combine <$combine>\n";
    # $combine;
}

sub _combine_new {
    my $self = shift;
    my( @short, @long );
    push @{ /^$Single_Char$/ ? \@short : \@long}, $_ for @_;
    if( @short == 1 and @long == 0 ) {
        return $short[0];
    }
    elsif( @short > 1 and @short == @_ ) {
        return _make_class($self, @short);
    }
    else {
        return '(?:'
            . join( '|' =>
                @short > 1
                    ? ( _make_class($self, @short), sort _re_sort @long)
                    : ( (sort _re_sort( @long )), @short )
            )
        . ')';
    }
}

sub _re_path {
    my $self = shift;
    # in shorter assemblies, _re_path() is the second hottest
    # routine. after insert(), so make it fast.

    if ($self->{unroll_plus}) {
        # but we can't easily make this blockless
        my @arr = @{$_[0]};
        my $str = '';
        my $skip = 0;
        for my $i (0..$#arr) {
            if (ref($arr[$i]) eq 'ARRAY') {
                $str .= _re_path($self, $arr[$i]);
            }
            elsif (ref($arr[$i]) eq 'HASH') {
                $str .= exists $arr[$i]->{''}
                    ? _combine_new( $self,
                        map { _re_path( $self, $arr[$i]->{$_} ) } grep { $_ ne '' } keys %{$arr[$i]}
                    ) . '?'
                    : _combine_new($self, map { _re_path( $self, $arr[$i]->{$_} ) } keys %{$arr[$i]})
                ;
            }
            elsif ($i < $#arr and $arr[$i+1] =~ /\A$arr[$i]\*(\??)\Z/) {
                $str .= "$arr[$i]+" . (defined $1 ? $1 : '');
                ++$skip;
            }
            elsif ($skip) {
                $skip = 0;
            }
            else {
                $str .= $arr[$i];
            }
        }
        return $str;
    }

    return join( '', @_ ) unless grep { length ref $_ } @_;
    my $p;
    return join '', map {
        ref($_) eq '' ? $_
        : ref($_) eq 'HASH' ? do {
            # In the case of a node, see whether there's a '' which
            # indicates that the whole thing is optional and thus
            # requires a trailing ?
            # Unroll the two different paths to avoid the needless
            # grep when it isn't necessary.
            $p = $_;
            exists $_->{''}
            ?  _combine_new( $self,
                map { _re_path( $self, $p->{$_} ) } grep { $_ ne '' } keys %$_
            ) . '?'
            : _combine_new($self, map { _re_path( $self, $p->{$_} ) } keys %$_ )
        }
        : _re_path($self, $_) # ref($_) eq 'ARRAY'
    } @{$_[0]}
}

sub _lookahead {
    my $in = shift;
    my %head;
    my $path;
    for $path( keys %$in ) {
        next unless defined $in->{$path};
        # print "look $path: ", ref($in->{$path}[0]), ".\n";
        if( ref($in->{$path}[0]) eq 'HASH' ) {
            my $next = 0;
            while( ref($in->{$path}[$next]) eq 'HASH' and @{$in->{$path}} > $next + 1 ) {
                if( exists $in->{$path}[$next]{''} ) {
                    ++$head{$in->{$path}[$next+1]};
                }
                ++$next;
            }
            my $inner = _lookahead( $in->{$path}[0] );
            @head{ keys %$inner } = (values %$inner);
        }
        elsif( ref($in->{$path}[0]) eq 'ARRAY' ) {
            my $subpath = $in->{$path}[0]; 
            for( my $sp = 0; $sp < @$subpath; ++$sp ) {
                if( ref($subpath->[$sp]) eq 'HASH' ) {
                    my $follow = _lookahead( $subpath->[$sp] );
                    @head{ keys %$follow } = (values %$follow);
                    last unless exists $subpath->[$sp]{''};
                }
                else {
                    ++$head{$subpath->[$sp]};
                    last;
                }
            }
        }
        else {
            ++$head{ $in->{$path}[0] };
        }
    }
    # print "_lookahead ", _dump($in), '==>', _dump([keys %head]), "\n";
    return \%head;
}

sub _re_path_lookahead {
    my $self = shift;
    my $in  = shift;
    # print "_re_path_la in ", _dump($in), "\n";
    my $out = '';
    for( my $p = 0; $p < @$in; ++$p ) {
        if( ref($in->[$p]) eq '' ) {
            $out .= $in->[$p];
            next;
        }
        elsif( ref($in->[$p]) eq 'ARRAY' ) {
            $out .= _re_path_lookahead($self, $in->[$p]);
            next;
        }
        # print "$p ", _dump($in->[$p]), "\n";
        my $path = [
            map { _re_path_lookahead($self, $in->[$p]{$_} ) }
            grep { $_ ne '' }
            keys %{$in->[$p]}
        ];
        my $ahead = _lookahead($in->[$p]);
        my $more = 0;
        if( exists $in->[$p]{''} and $p + 1 < @$in ) {
            my $next = 1;
            while( $p + $next < @$in ) {
                if( ref( $in->[$p+$next] ) eq 'HASH' ) {
                    my $follow = _lookahead( $in->[$p+$next] );
                    @{$ahead}{ keys %$follow } = (values %$follow);
                }
                else {
                    ++$ahead->{$in->[$p+$next]};
                    last;
                }
                ++$next;
            }
            $more = 1;
        }
        my $nr_one = grep { /^$Single_Char$/ } @$path;
        my $nr     = @$path;
        if( $nr_one > 1 and $nr_one == $nr ) {
            $out .= _make_class($self, @$path);
            $out .= '?' if exists $in->[$p]{''};
        }
        else {
            my $zwla = keys(%$ahead) > 1
                ?  _combine($self, '?=', grep { s/\+$//; $_ } keys %$ahead )
                : '';
            my $patt = $nr > 1 ? _combine($self, '?:', @$path ) : $path->[0];
            # print "have nr=$nr n1=$nr_one n=", _dump($in->[$p]), ' a=', _dump([keys %$ahead]), " zwla=$zwla patt=$patt @{[_dump($path)]}\n";
            if( exists $in->[$p]{''} ) {
                $out .=  $more ? "$zwla(?:$patt)?" : "(?:$zwla$patt)?";
            }
            else {
                $out .= "$zwla$patt";
            }
        }
    }
    return $out;
}

sub _re_path_track {
    my $self      = shift;
    my $in        = shift;
    my $normal    = shift;
    my $augmented = shift;
    my $o;
    my $simple  = '';
    my $augment = '';
    for( my $n = 0; $n < @$in; ++$n ) {
        if( ref($in->[$n]) eq '' ) {
            $o = $in->[$n];
            $simple  .= $o;
            $augment .= $o;
            if( (
                    $n < @$in - 1
                    and ref($in->[$n+1]) eq 'HASH' and exists $in->[$n+1]{''}
                )
                or $n == @$in - 1
            ) {
                push @{$self->{mlist}}, $normal . $simple ;
                $augment .= $] < 5.009005
                    ? "(?{\$self->{m}=$self->{mcount}})"
                    : "(?{$self->{mcount}})"
                ;
                ++$self->{mcount};
            }
        }
        else {
            my $path = [
                map { $self->_re_path_track( $in->[$n]{$_}, $normal.$simple , $augmented.$augment ) }
                grep { $_ ne '' }
                keys %{$in->[$n]}
            ];
            $o = '(?:' . join( '|' => sort _re_sort @$path ) . ')';
            $o .= '?' if exists $in->[$n]{''};
            $simple  .= $o;
            $augment .= $o;
        }
    }
    return $augment;
}

sub _re_path_pretty {
    my $self = shift;
    my $in  = shift;
    my $arg = shift;
    my $pre    = ' ' x (($arg->{depth}+0) * $arg->{indent});
    my $indent = ' ' x (($arg->{depth}+1) * $arg->{indent});
    my $out = '';
    $arg->{depth}++;
    my $prev_was_paren = 0;
    for( my $p = 0; $p < @$in; ++$p ) {
        if( ref($in->[$p]) eq '' ) {
            $out .= "\n$pre" if $prev_was_paren;
            $out .= $in->[$p];
            $prev_was_paren = 0;
        }
        elsif( ref($in->[$p]) eq 'ARRAY' ) {
            $out .= _re_path($self, $in->[$p]);
        }
        else {
            my $path = [
                map { _re_path_pretty($self, $in->[$p]{$_}, $arg ) }
                grep { $_ ne '' }
                keys %{$in->[$p]}
            ];
            my $nr = @$path;
            my( @short, @long );
            push @{/^$Single_Char$/ ? \@short : \@long}, $_ for @$path;
            if( @short == $nr ) {
                $out .=  $nr == 1 ? $path->[0] : _make_class($self, @short);
                $out .= '?' if exists $in->[$p]{''};
            }
            else {
                $out .= "\n" if length $out;
                $out .= $pre if $p;
                $out .= "(?:\n$indent";
                if( @short < 2 ) {
                    my $r = 0;
                    $out .= join( "\n$indent|" => map {
                            $r++ and $_ =~ s/^\(\?:/\n$indent(?:/;
                            $_
                        }
                        sort _re_sort @$path
                    );
                }
                else {
                    $out .= join( "\n$indent|" => ( (sort _re_sort @long), _make_class($self, @short) ));
                }
                $out .= "\n$pre)";
                if( exists $in->[$p]{''} ) {
                    $out .= "\n$pre?";
                    $prev_was_paren = 0;
                }
                else {
                    $prev_was_paren = 1;
                }
            }
        }
    }
    $arg->{depth}--;
    return $out;
}

sub _node_eq {
    return 0 if not defined $_[0] or not defined $_[1];
    return 0 if ref $_[0] ne ref $_[1];
    # Now that we have determined that the reference of each
    # argument are the same, we only have to test the first
    # one, which gives us a nice micro-optimisation.
    if( ref($_[0]) eq 'HASH' ) {
        keys %{$_[0]} == keys %{$_[1]}
            and
        # does this short-circuit to avoid _re_path() cost more than it saves?
        join( '|' => sort keys %{$_[0]}) eq join( '|' => sort keys %{$_[1]})
            and
        _re_path(undef, [$_[0]] ) eq _re_path(undef, [$_[1]] );
    }
    elsif( ref($_[0]) eq 'ARRAY' ) {
        scalar @{$_[0]} == scalar @{$_[1]}
            and
        _re_path(undef, $_[0]) eq _re_path(undef, $_[1]);
    }
    else {
        $_[0] eq $_[1];
    }
}

sub _pretty_dump {
    return sprintf "\\x%02x", ord(shift);
}

sub _dump {
    my $path = shift;
    return _dump_node($path) if ref($path) eq 'HASH';
    my $dump = '[';
    my $d;
    my $nr = 0;
    for $d( @$path ) {
        $dump .= ' ' if $nr++;
        if( ref($d) eq 'HASH' ) {
            $dump .= _dump_node($d);
        }
        elsif( ref($d) eq 'ARRAY' ) {
            $dump .= _dump($d);
        }
        elsif( defined $d ) {
            # D::C indicates the second test is redundant
            # $dump .= ( $d =~ /\s/ or not length $d )
            $dump .= (
                $d =~ /\s/            ? qq{'$d'}         :
                $d =~ /^[\x00-\x1f]$/ ? _pretty_dump($d) :
                $d
            );
        }
        else {
            $dump .= '*';
        }
    }
    return $dump . ']';
}

sub _dump_node {
    my $node = shift;
    my $dump = '{';
    my $nr   = 0;
    my $n;
    for $n (sort keys %$node) {
        $dump .= ' ' if $nr++;
        # Devel::Cover shows this to test to be redundant
        # $dump .= ( $n eq '' and not defined $node->{$n} )
        $dump .= $n eq ''
            ? '*'
            : ($n =~ /^[\x00-\x1f]$/ ? _pretty_dump($n) : $n)
                . "=>" . _dump($node->{$n})
        ;
    }
    return $dump . '}';
}

'The Lusty Decadent Delights of Imperial Pompeii';
__END__
