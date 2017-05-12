
package XML::CuteQueries;

use strict;
use warnings;

our $VERSION = '0.6614';

use Carp;
use Scalar::Util qw(reftype blessed);
use XML::CuteQueries::Error;
use base 'XML::Twig';

use constant LIST   => 1;
use constant KLIST  => 2;

use parent 'Exporter';
our @EXPORT_OK = qw(CQ slurp);

# CQ {{{
sub CQ {
    our $CQ ||= __PACKAGE__->new;

    no warnings 'misc'; ## no critic: yeah, they might do it wrong and pass an odd number, deal with it
    if( my %o = @_ ) {
        my $arg;
        if( $arg = $o{file} ) {
            eval { $CQ->parsefile($arg); 1 } or do {
                $CQ = __PACKAGE__->new; # build new CQ so we can do the next twig
                my $e = $@; $e =~ s/\s+(eval \d+)//;
                croak $@;
            }

        } elsif( $arg = $o{xml} ) {
            eval { $CQ->parse($arg); 1 } or do {
                $CQ = __PACKAGE__->new; # build new CQ so we can do the next twig
                my $e = $@; $e =~ s/\s+(eval \d+)//;
                croak $@;
            }
        }
    }

    return $CQ
}
# }}}

our %VALID_OPTS = (map {$_=>1} qw(nostrict nostrict_match nostrict_single nofilter_nontags notrim klist));

# _data_error {{{
sub _data_error {
    my $this = shift;
    my $desc = shift || "single-value";
       $desc = shift() . " [$desc result request]";

    XML::CuteQueries::Error->new(
        type => XML::CuteQueries::Error::DATA_ERROR(),
        text => $desc,
    )->throw;

    return; # technically unreachable, but critic won't notice
}
# }}}
# _query_error {{{
sub _query_error {
    my $this = shift;
    my $err  = shift;

    my $f = __FILE__;
    $err =~ s/\s+at\s+\Q$f\E\s+line\s+\d+//;

    XML::CuteQueries::Error->new(
        type => XML::CuteQueries::Error::QUERY_ERROR(),
        text => $err,
    )->throw;

    return; # technically unreachable, but critic won't notice
}
# }}}

# _pre_parse_queries {{{
sub _pre_parse_queries {
    my $this = shift;
    my $opts = shift;

    if( @_ % 2 ) {
        $this->_query_error("odd number of arguments, queries are hashes and therefore should be a series of key/value pairs.");
    }

    return 1;
}
# }}}
# _execute_query {{{
sub _execute_query {
    my ($this, $root, $opts, $query, $res_type, $context) = @_;

    XML::CuteQueries::Error->new(text=>"\$context specification error")->throw
        if not defined $context or $context<1 or $context>2;

    my $mt = 0; # magic restype (restype scalar sub-type)
    my $rt = 0; # processed reftype (false for scalars)

    if( $res_type ||= 0 ) {
        unless( $rt = reftype $res_type ) {
            if( $res_type =~ m/^(?:x|xml|xml\(\))\z/ ) { # xml()
                $mt = "x";

            } elsif( $res_type =~ m/^(?:t|twig|twig\(\))\z/ ) { # twig()
                $mt = "t";

            } elsif( $res_type =~ m/^(?:r|a|recurse|all)(?:_text(?:\(\))?)?/ ) { # recurse_text() all_text()
                $mt = "r";

            } else {
                $this->_query_error("unknown scalar query sub-type: $res_type");
            }

            $res_type = undef;
        }
    }

    my $kar = 0; # klist keys are expected more than once
    if( $query =~ s/^\[\]// ) {
        # NOTE: I don't think this is ever valid XPath
        $kar = 1;

        $this->_query_error("[] queries (\"[]$query\") do not make sense outside of klist contexts") unless $context == KLIST;
    }

    my ($re, $nre) = (0,0);
    if( my ($type, $code) = $query =~ m/^<([!Nn]?[Rr][Ee])>(.+?)(?:<\/\1>)?\z/ ) {
        if( lc($type) eq "re" ) {
            $re  = 1;

        } else {
            $re = $nre = 1;
        }

        $query = qr($code);
    }

    my @c;
    my $attr_query;
    my $oquery = $query;
    if( not $rt ) {
        if( $query =~ m/^\S/ and $query =~ s/\@([\w\d:]+|\*)\z// ) {
            $attr_query = $1;
            $query =~ s,(?<=\w)\/$,,;
            @c = $root unless $query;
        }
    }

    # @c is only true when it's a root-attr query
    unless(@c) {
        @c = eval {
            if( $re ) {
                return grep {$_->gi !~ $query } $root->children if $nre;
                return grep {$_->gi =~ $query } $root->children;
            }

            return $root->get_xpath($query)
        };

        for(@c) { $_ = $root if $_ == $this }

        $this->_query_error("while executing \"$query\": $@") if $@;
        @c = grep {$_->gi !~ m/^#/} @c unless $opts->{nofilter_nontags};
    }

    $this->_data_error($rt, "match failed for \"$query\"") unless @c or $opts->{nostrict_match};
    return unless @c;


    if( not $rt ) {
        my $_trimlist;
        my $_trimhash;

        if( $opts->{notrim} ) {
            $_trimlist = $_trimhash = sub {@_};

        } else {
            $_trimlist = sub { for(@_) { unless( m/\n/ ) { s/^\s+//; s/\s+$// }}; @_ };
            $_trimhash = sub { my %h=@_; for(grep {defined $_} values %h) { unless( m/\n/ ) { s/^\s+//; s/\s+$// }}; %h };
        }

        if( $attr_query ) {
            if( $kar ) {
                my %h;

                # NOTE: it's safe to assume we're in KLIST

                my @attr = $attr_query eq "*"
                         ? do { my %ua; grep { !$ua{$_}++ } map { keys %{$_->{att}} } @c }
                         : $attr_query;

                for my $attr (@attr) {
                    push @{$h{$attr}}, $_trimlist->(
                        map  { $_->{$attr} }
                        grep { exists $_->{$attr} }
                        map  { $_->{att} }
                        @c
                    );
                }

                return %h;
            }

            if( $attr_query eq "*" ) {
                if( $context == KLIST ) {
                    return $_trimhash->( map { %{$_->{att}} } @c );
                }

                return $_trimlist->( map { values %{$_->{att}} } @c );
            }

            if( $context == KLIST ) {
                return $_trimhash->( map { $attr_query => $_->{att}{$attr_query} } @c );
            }

            return $_trimlist->( map { $_->{att}{$attr_query} } @c );
        }

        my $get_value = {
            t => sub { $_[0] },
            x => 'xml_string',
            r => 'text',
            0 => 'text_only'
        }->{$mt};

        if ($mt eq 't') {
            $_trimlist = $_trimhash = sub { @_ };
        }

        return $_trimlist->( map { $_->$get_value } @c ) unless $context == KLIST;

        my %h;

        for (@c) {
            my $arr = $h{$_->gi} ||= [];
            # discard all but the last result
            @$arr = () if $opts->{nostrict_single} and not $kar;
            push @$arr, $_->$get_value;
            unless ($kar || @$arr == 1) {
                $this->_data_error($rt, "expected exactly one match-per-tagname for \"$query\", got more")
            }
        }

        if ($kar) {
            $_trimlist->( @$_ ) for values %h;
            return %h;
        } else {
            $_ = $_->[-1] for values %h;
            return $_trimhash->(%h);
        }

    } elsif( $rt eq "HASH" ) {
        if( $context == KLIST ) {
            if( $kar ) {
                my %h;

                for my $c (@c) {
                    push @{$h{$c->gi}},
                        {map { $this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type}
                }

                return %h;

            } elsif( $opts->{nostrict_single} ) {
                return map {
                    my $c = $_;
                    $c->gi => {map { $this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type}

                } @c;

            } else {
                my %check;
                return map {
                    my $c = $_;
                    my $g = $_->gi;

                    $this->_data_error($rt, "expected exactly one match-per-tagname for \"$query\", got more")
                        if $check{$g}++;

                    $g => {map { $this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST) } keys %$res_type}

                } @c;
            }
        }

        return map {
            my $c = $_;
            scalar # I don't think I should need this word here, but I clearly do, plus would also work
            {map {$this->_execute_query($c, $opts, $_ => $res_type->{$_}, KLIST)} keys %$res_type};
        } @c;

    } elsif( $rt eq "ARRAY" ) {
        my @p;
        while( my ($pat, $res) = splice @$res_type, 0, 2 ) {
            push @p, [$pat, $res];
        }

        if( $context == KLIST ) {
            if( $kar ) {
                my %h;

                for my $c (@c) {
                    push @{$h{$c->gi}},
                        [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ]
                }

                return %h;

            } elsif( $opts->{nostrict_single} ) {
                return map {
                    my $c = $_;
                    $c->gi => [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;

            } else {
                my %check;
                return map {
                    my $c = $_;
                    my $g = $c->gi;

                    $this->_data_error($rt, "expected exactly one match-per-tagname for \"$query\", got more")
                        if $check{$g}++;

                    $g => [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;
            }
        }

        return map { my $c = $_; [ map {$this->_execute_query($c, $opts, @$_, LIST)} @p ] } @c;
    }

    XML::CuteQueries::Error->new(text=>"unexpected condition met")->throw;
    return;
}
# }}}

# cute_query {{{
sub cute_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref $_[0] eq "HASH";

    $opts->{nostrict_match} = $opts->{nostrict_single} = $opts->{nostrict} if exists $opts->{nostrict};

    for(keys %$opts) {
        $this->_query_error("no such query option \"$_\"") unless $VALID_OPTS{$_};
    }

    my $context = LIST;
       $context = KLIST if delete $opts->{klist};

    $this->_pre_parse_queries($opts, @_);

    my @result;
    my ($query, $res_type) = @_; # used in error below

    while( my @q = splice @_, 0, 2 ) {
        push @result, $this->_execute_query($this->root, $opts, @q, $context);
    }

    unless( wantarray ) {

        if( @result>1 ) {
            unless( $opts->{nostrict_single} ) {
                my $rt = (defined $res_type and reftype $res_type) || '';
                $this->_data_error($rt, "expected exactly one match for \"$query\", got " . @result)
            }

        } elsif( @result<1 ) {
            unless( $opts->{nostrict_match} ) {
                my $rt = (defined $res_type and reftype $res_type) || '';
                $this->_data_error($rt, "expected exactly one match for \"$query\", got " . @result)
            }
        }

        return $result[0]; # we never want the size of the array, preferring the first match
    }

    return @result;
}
# }}}

# hash_query {{{
sub hash_query {
    my $this = shift;
    my $opts = {};
       $opts = shift if ref($_[0]) eq "HASH";

    $opts->{klist} = 1;
    return $this->cute_query($opts, @_);
}
*klist_query = \&hash_query;
# }}}

1;
