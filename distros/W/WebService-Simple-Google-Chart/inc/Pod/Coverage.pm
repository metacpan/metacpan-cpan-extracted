#line 1
use strict;

package Pod::Coverage;
use Devel::Symdump;
use B;
use Pod::Find qw(pod_where);

BEGIN { defined &TRACE_ALL or eval 'sub TRACE_ALL () { 0 }' }

use vars qw/ $VERSION /;
$VERSION = '0.19';

#line 103

sub new {
    my $referent = shift;
    my %args     = @_;
    my $class    = ref $referent || $referent;

    my $private = $args{private} || [
        qr/^_/,
        qr/^import$/,
        qr/^DESTROY$/,
        qr/^AUTOLOAD$/,
        qr/^bootstrap$/,
        qr/^\(/,
        qr/^(TIE( SCALAR | ARRAY | HASH | HANDLE ) |
             FETCH | STORE | UNTIE | FETCHSIZE | STORESIZE |
             POP | PUSH | SHIFT | UNSHIFT | SPLICE | DELETE |
             EXISTS | EXTEND | CLEAR | FIRSTKEY | NEXTKEY | PRINT | PRINTF |
             WRITE | READLINE | GETC | READ | CLOSE | BINMODE | OPEN |
             EOF | FILENO | SEEK | TELL)$/x,
        qr/^( MODIFY | FETCH )_( REF | SCALAR | ARRAY | HASH | CODE |
                                 GLOB | FORMAT | IO)_ATTRIBUTES $/x,
        qr/^CLONE(_SKIP)?$/,
    ];
    push @$private, @{ $args{also_private} || [] };
    my $trustme       = $args{trustme}       || [];
    my $nonwhitespace = $args{nonwhitespace} || undef;

    my $self = bless {
        @_,
        private       => $private,
        trustme       => $trustme,
        nonwhitespace => $nonwhitespace
    }, $class;
}

#line 143

sub coverage {
    my $self = shift;

    my $package = $self->{package};
    my $pods    = $self->_get_pods;
    return unless $pods;

    my %symbols = map { $_ => 0 } $self->_get_syms($package);

    print "tying shoelaces\n" if TRACE_ALL;
    for my $pod (@$pods) {
        $symbols{$pod} = 1 if exists $symbols{$pod};
    }

    foreach my $sym ( keys %symbols ) {
        $symbols{$sym} = 1 if $self->_trustme_check($sym);
    }

    # stash the results for later
    $self->{symbols} = \%symbols;

    if (TRACE_ALL) {
        require Data::Dumper;
        print Data::Dumper::Dumper($self);
    }

    my $symbols = scalar keys %symbols;
    my $documented = scalar grep {$_} values %symbols;
    unless ($symbols) {
        $self->{why_unrated} = "no public symbols defined";
        return;
    }
    return $documented / $symbols;
}

#line 186

sub why_unrated {
    my $self = shift;
    $self->{why_unrated};
}

#line 200

sub naked {
    my $self = shift;
    $self->{symbols} or $self->coverage;
    return unless $self->{symbols};
    return grep { !$self->{symbols}{$_} } keys %{ $self->{symbols} };
}

*uncovered = \&naked;

#line 218

sub covered {
    my $self = shift;
    $self->{symbols} or $self->coverage;
    return unless $self->{symbols};
    return grep { $self->{symbols}{$_} } keys %{ $self->{symbols} };
}

sub import {
    my $self = shift;
    return unless @_;

    # one argument - just a package
    scalar @_ == 1 and unshift @_, 'package';

    # we were called with arguments
    my $pc     = $self->new(@_);
    my $rating = $pc->coverage;
    $rating = 'unrated (' . $pc->why_unrated . ')'
        unless defined $rating;
    print $pc->{package}, " has a $self rating of $rating\n";
    my @looky_here = $pc->naked;
    if ( @looky_here > 1 ) {
        print "The following are uncovered: ", join( ", ", sort @looky_here ),
            "\n";
    } elsif (@looky_here) {
        print "'$looky_here[0]' is uncovered\n";
    }
}

#line 295

# this one walks the symbol tree
sub _get_syms {
    my $self    = shift;
    my $package = shift;

    print "requiring '$package'\n" if TRACE_ALL;
    eval qq{ require $package };
    print "require failed with $@\n" if TRACE_ALL and $@;
    return if $@;

    print "walking symbols\n" if TRACE_ALL;
    my $syms = Devel::Symdump->new($package);

    my @symbols;
    for my $sym ( $syms->functions ) {

        # see if said method wasn't just imported from elsewhere
        my $glob = do { no strict 'refs'; \*{$sym} };
        my $o = B::svref_2object($glob);

        # in 5.005 this flag is not exposed via B, though it exists
        my $imported_cv = eval { B::GVf_IMPORTED_CV() } || 0x80;
        next if $o->GvFLAGS & $imported_cv;

        # check if it's on the whitelist
        $sym =~ s/$self->{package}:://;
        next if $self->_private_check($sym);

        push @symbols, $sym;
    }
    return @symbols;
}

#line 336

sub _get_pods {
    my $self = shift;

    my $package = $self->{package};

    print "getting pod location for '$package'\n" if TRACE_ALL;
    $self->{pod_from} ||= pod_where( { -inc => 1 }, $package );

    my $pod_from = $self->{pod_from};
    unless ($pod_from) {
        $self->{why_unrated} = "couldn't find pod";
        return;
    }

    print "parsing '$pod_from'\n" if TRACE_ALL;
    my $pod = Pod::Coverage::Extractor->new;
    $pod->{nonwhitespace} = $self->{nonwhitespace};
    $pod->parse_from_file( $pod_from, '/dev/null' );

    return $pod->{identifiers} || [];
}

#line 364

sub _private_check {
    my $self = shift;
    my $sym  = shift;
    return grep { $sym =~ /$_/ } @{ $self->{private} };
}

#line 376

sub _trustme_check {
    my ( $self, $sym ) = @_;
    return grep { $sym =~ /$_/ } @{ $self->{trustme} };
}

sub _CvGV {
    my $self = shift;
    my $cv   = shift;
    my $b_cv = B::svref_2object($cv);

    # perl 5.6.2's B doesn't have an object_2svref.  in 5.8 you can
    # just do this:
    # return *{ $b_cv->GV->object_2svref };
    # but for backcompat we're forced into this uglyness:
    no strict 'refs';
    return *{ $b_cv->GV->STASH->NAME . "::" . $b_cv->GV->NAME };
}

package Pod::Coverage::Extractor;
use Pod::Parser;
use base 'Pod::Parser';

use constant debug => 0;

# extract subnames from a pod stream
sub command {
    my $self = shift;
    my ( $command, $text, $line_num ) = @_;
    if ( $command eq 'item' || $command =~ /^head(?:2|3|4)/ ) {

        # take a closer look
        my @pods = ( $text =~ /\s*([^\s\|,\/]+)/g );
        $self->{recent} = [];

        foreach my $pod (@pods) {
            print "Considering: '$pod'\n" if debug;

            # it's dressed up like a method cal
            $pod =~ /-E<\s*gt\s*>(.*)/ and $pod = $1;
            $pod =~ /->(.*)/           and $pod = $1;

            # it's used as a (bare) fully qualified name
            $pod =~ /\w+(?:::\w+)*::(\w+)/ and $pod = $1;

            # it's wrapped in a pod style B<>
            $pod =~ s/[A-Z]<//g;
            $pod =~ s/>//g;

            # has arguments, or a semicolon
            $pod =~ /(\w+)\s*[;\(]/ and $pod = $1;

            print "Adding: '$pod'\n" if debug;
            push @{ $self->{ $self->{nonwhitespace}
                    ? "recent"
                    : "identifiers" } }, $pod;
        }
    }
}

sub textblock {
    my $self = shift;
    my ( $text, $line_num ) = shift;
    if ( $self->{nonwhitespace} and $text =~ /\S/ and $self->{recent} ) {
        push @{ $self->{identifiers} }, @{ $self->{recent} };
        $self->{recent} = [];
    }
}

1;

__END__

#line 486
