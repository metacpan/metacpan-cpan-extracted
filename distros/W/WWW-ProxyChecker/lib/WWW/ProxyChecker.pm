package WWW::ProxyChecker;

use warnings;
use strict;

# VERSION

our $VERSION = '1.005';

use Data::Dumper;
use Carp;
use LWP::UserAgent;
use IO::Pipe;
use Time::HiRes qw(gettimeofday);

use base 'Class::Accessor::Grouped';
__PACKAGE__->mk_group_accessors(simple => qw/
    max_kids
    debug
    alive
    check_sites
    max_working_per_kid
    timeout
    agent
/);

sub new {
    my $self = bless {}, shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    %args = (
        timeout       => 5,
        max_kids      => 20,
        check_sites   => [ qw(
                http://google.com
                http://microsoft.com
                http://yahoo.com
                http://digg.com
                http://facebook.com
                http://myspace.com
            )
        ],
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',

        %args,
    );

    $self->$_( $args{ $_ } ) for keys %args;

    return $self;
}
sub check {
    my ( $self, $proxies_ref ) = @_;

    $self->alive(undef);
    $self->{fastest} = {};

    warn "About to check " . @$proxies_ref . " proxies\n"
        if $self->debug;

    my $working_ref = $self->_start_checker( @$proxies_ref );

    warn @$working_ref . ' out of ' . @$proxies_ref
            . " seem to be alive\n" if $self->debug;

    return $self->alive($working_ref);
}
sub fastest {
    my $self = shift;

    my @debug_list;
    my @fastest;

    my %list = %{ $self->{fastest} };

    for my $proxy (sort { $list{$a} <=> $list{$b} } keys %list){
        $list{$proxy} = sprintf("%.2f", $list{$proxy});
        push @debug_list, "$proxy :: $list{$proxy}";
        push @fastest, $proxy;
    }

    if ($self->debug) {
        warn "$_\n" for @debug_list;
    }

    return \@fastest;
}
sub _start_checker {
    my ( $self, @proxies ) = @_;

    my $n = $self->max_kids;
    $n > @proxies and $n = @proxies;
    my $mod = @proxies / $n;
    my %prox;
    for ( 1 .. $n ) {
        $prox{ $_ } = [ splice @proxies, 0,$mod ]
    }
    push @{ $prox{ $n } }, @proxies; # append any left over addresses

    $SIG{CHLD} = 'IGNORE';
    my @children;
    for my $num ( 1 .. $self->max_kids ) {
        my $pipe = new IO::Pipe;
        my $time;

        if ( my $pid = fork ) { # parent
            $pipe->reader;
            push @children, $pipe;
        }
        elsif ( defined $pid ) { # kid
            $pipe->writer;

            my $ua = LWP::UserAgent->new(
                timeout => $self->timeout,
                agent   => $self->agent,
            );

            my $check_sites_ref = $self->check_sites;
            my $debug = $self->debug;
            my @working;
            for my $proxy ( @{ $prox{ $num } } ) {
                warn "Checking $proxy in kid $num\n"
                    if $debug;

                if ($time = $self->_check_proxy($ua, $proxy, $check_sites_ref) ) {
                    push @working, $proxy;

                    last
                        if defined $self->max_working_per_kid
                            and @working >= $self->max_working_per_kid;
                }
            }
            print $pipe "$_ $time\n" for @working;
            exit;
        }
        else { # error
            carp "Failed to fork kid number $num ($?)";
        }

    }

    my @working_proxies;
    for my $num ( 0 .. $#children ) {
        my $fh = $children[$num];
        while (<$fh>) {
            chomp;
            my ($proxy, $time) = split;
            $self->{fastest}{$proxy} = $time if $time != 1;
            push @working_proxies, $proxy;
        }
    }

    return \@working_proxies;
}
sub _check_proxy {
    my ( $self, $ua, $proxy, $sites_ref ) = @_;

    $ua->proxy( [ 'http', 'https', 'ftp', 'ftps' ], $proxy);

    my $start = gettimeofday();

    my $response = $ua->get( $sites_ref->[rand @$sites_ref] );

    my $time = gettimeofday() - $start;

    if ( $response->is_success ){
        return $time;
    }
    else {
        warn "Failed on $proxy " . $response->status_line . "\n"
            if $self->debug;

        my $response_code = $response->code;
        return 0
            if grep { $response_code eq $_ } qw(407 502 503 403);

        ( my $proxy_no_scheme = $proxy ) =~ s{(?:ht|f)tps?://}{}i;
        return $response->status_line
        =~ /^500 read timeout$|\Q$proxy_no_scheme/ ? 0 : 1;
    }
}

1;
__END__

=head1 NAME

WWW::ProxyChecker - Check whether or not proxy servers are alive

=for html
<a href="http://travis-ci.org/stevieb9/p5-www-proxychecker"><img src="https://secure.travis-ci.org/stevieb9/p5-www-proxychecker.png"/>
<a href='https://coveralls.io/github/stevieb9/p5-www-proxychecker?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-www-proxychecker/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::ProxyChecker;

    my $checker = WWW::ProxyChecker->new( debug => 1 );

    my $working_ref= $checker->check( [ qw(
                http://221.139.50.83:80
                http://111.111.12.83:8080
                http://111.111.12.183:3218
                http://111.111.12.93:8080
            )
        ]
    );

    die "No working proxies were found\n"
        if not @$working_ref;

    print "$_ is alive\n"
        for @$working_ref;

=head1 DESCRIPTION

The module provides means to check whether or not HTTP proxies are alive.
The module was designed more towards "quickly scanning through to get a few"
than "guaranteed or your money back" therefore there is no 100% guarantee
that non-working proxies are actually dead and that all of the reported
working proxies are actually good.

=head1 CONSTRUCTOR

=head2 new

    my $checker = WWW::ProxyChecker->new;

    my $checker_juicy = WWW::ProxyChecker->new(
        timeout       => 5,
        max_kids      => 20,
        max_working_per_child => 2,
        check_sites   => [ qw(
                http://google.com
                http://microsoft.com
                http://yahoo.com
                http://digg.com
                http://facebook.com
                http://myspace.com
            )
        ],
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
        debug => 1,
    );

Bakes up and returns a new WWW::ProxyChecker object. Takes a few arguments
I<all of which are optional>. Possible arguments are as follows:

=head3 timeout

    ->new( timeout => 5 );

B<Optional>. Specifies timeout in seconds to give to L<LWP::UserAgent>
object which
is used for checking. If a connection to the proxy times out the proxy
is considered dead. The lower the value, the faster the check will be
done but also the more are the chances that you will throw away good
proxies. B<Defaults to:> C<5> seconds

=head3 agent

    ->new( agent => 'ProxeyCheckerz' );

B<Optional>. Specifies the User Agent string to use while checking proxies. B<By default> will be set to mimic Firefox.

=head3 check_sites

    ->new( check_sites => [ qw( http://some_site.com http://other.com ) ] );

B<Optional>. Takes an arrayref of sites to try to connect to through a
proxy. Yes! It's evil, saner ideas are more than welcome. B<Defaults to:>

    check_sites   => [ qw(
                http://google.com
                http://microsoft.com
                http://yahoo.com
                http://digg.com
                http://facebook.com
                http://myspace.com
            )
        ],

=head3 max_kids

    ->new( max_kids => 20 );

B<Optional>. Takes a positive integer as a value.
The module will fork up maximum of C<max_kids> processes to check proxies
simultaneously. It will fork less if the total number of proxies to check
is less than C<max_kids>. Technically, setting this to a higher value
might speed up the overall process but keep in mind that it's the number
of simultaneous connections that you will have open. B<Defaults to:> C<20>

=head3 max_working_per_child

    ->new( max_working_per_child => 2 );

B<Optional>. Takes a positive integer as a value. Specifies how many
working proxies each sub process should find before aborting (it will
also abort if proxy list is exhausted). In other words, setting C<20>
C<max_kids> and C<max_working_per_child> to C<2> will give you 40 working
proxies at most, no matter how many are in the original list. Specifying
C<undef> will get rid of limit and make each kid go over the entire sub
list it was given. B<Defaults to:> C<undef> (go over entire sub list)

=head3 debug

    ->new( debug => 1 );

B<Optional>. When set to a true value will make the module print out
some debugging information (which proxies failed and how, etc).
B<By default> not specifies (debug is off)

=head1 METHODS

=head2 check

    my $working_ref = $checker->check( [ qw(
                http://221.139.50.83:80
                http://111.111.12.83:8080
                http://111.111.12.183:3218
                http://111.111.12.93:8080
            )
        ]
    );

Instructs the object to check several proxies. Returns a (possibly empty)
array ref of addresses which the object considers to be alive and working.
Takes an arrayref of proxy addresses. The elements of this arrayref will
be passed to L<LWP::UserAgent>'s C<proxy()> method as:

    $ua->proxy( [ 'http', 'https', 'ftp', 'ftps' ], $proxy );

so you can read the docs for L<LWP::UserAgent> and maybe think up something
creative.

=head2 alive

    my $last_alive = $checker->alive;

Must be called after a call to C<check()>. Takes no arguments, returns
the same arrayref last C<check()> returned.

=head1 ACCESSORS/MUTATORS

The module provides an accessor/mutator for each of the arguments in
the constructor (new() method). Calling any of these with an argument
will set a new value. All of these return a currently set value:

    max_kids
    check_sites
    max_working_per_kid
    timeout
    agent
    debug

See C<CONSTRUCTOR> section for more information about these.

=head1 REPOSITORY

L<https://github.com/stevieb9/p5-www-proxychecker>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/stevieb9/p5-www-proxychecker/issues>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

Adopted on Feb 4, 2016 and currently maintained by:

Steve Bertrand C<< <steveb at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2016 Steve Bertrand

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
