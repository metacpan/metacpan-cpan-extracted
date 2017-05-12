package WWW::BashOrg;

use warnings;
use strict;

our $VERSION = '1.001003'; # VERSION

use LWP::UserAgent;
use HTML::TokeParser::Simple;
use HTML::Entities;
use overload q|""| => sub { shift->quote };
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors( simple => qw/
    ua
    error
    quote
    default_site
/);

sub new {
    my $class = shift;
    my %args = @_;

    $args{ua} = LWP::UserAgent->new(
        agent   => 'Opera 9.5',
        timeout => 30,
    ) unless defined $args{ua};
    $args{default_site} ||= 'bash';

    my $self = bless {}, $class;

    $self->$_( $args{ $_ } ) for keys %args;

    return $self;
}

sub get_quote {
    my ( $self, $num, $site ) = @_;

    $site = $self->_normalise_site($site);
    $self->quote( undef );
    $self->error( undef );

    unless ( length $num and $num =~ /^\d+$/ ) {
        $self->error('Invalid quote number');
        return;
    }

    my $res = $self->{ua}->get( ( ($site eq 'bash') ? "http://bash.org/?quote=" : "http://www.qdb.us/" ) . $num );
    unless ( $res->is_success ) {
        $self->error("Network error: " . $res->status_line );
        return;
    }

    my $quote = ( $self->_parse_quote( $res->decoded_content, $site ) )[0];
    unless ( defined $quote ) {
        $self->error('Quote not found');
        return;
    }

    return $self->quote( $quote );
}

sub random {
    my ($self, $site) = @_;

    $site = $self->_normalise_site($site);
    $self->quote( undef );
    $self->error( undef );

    unless ( @{ $self->{'cache'.$site} || [] } ) {
        my $res = $self->{ua}->get(
            $site eq 'bash'
                ? "http://bash.org/?random1"
                : "http://www.qdb.us/random"
        );

        unless ( $res->is_success ) {
            $self->error("Network error: " . $res->status_line );
            return;
        }

        @{ $self->{'cache'.$site} }
        = $self->_parse_quote( $res->decoded_content, $site );

        unless ( @{ $self->{'cache'.$site} } ) {
            $self->error('Quote not found');
            return;
        }
    }

    return $self->quote( pop @{ $self->{'cache'.$site} } );
}

sub _parse_quote {
    my ( $self, $content ) = @_;

    my $p = HTML::TokeParser::Simple->new( \$content );

    my $get_quote;
    my $quote;
    my @quotes;
    while ( my $t = $p->get_token ) {
        if ( ( $t->is_start_tag('p') || $t->is_start_tag('span') )
            and defined $t->get_attr('class')
            and $t->get_attr('class') eq 'qt'
        ) {
            $get_quote = 1;
        }

        if ( $get_quote and $t->is_text ) {
            $quote .= $t->as_is;
        }

        if ( $get_quote and ( $t->is_end_tag('p') || $t->is_end_tag('span') ) ) {
            $quote =~ s/&nbsp;/ /g;
            push @quotes, decode_entities $quote;
            $quote = ''; $get_quote = 0;
        }
    }

    return @quotes;
}

sub _normalise_site {
    my ( $self, $site ) = @_;
    $site ||= $self->default_site;
    ( $site ne 'bash' && $site ne 'qdb' ) and $site = $self->default_site;
    return $site;
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::BashOrg - simple module to obtain quotes from http://bash.org/ and http://www.qdb.us/

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use WWW::BashOrg;

    die "Usage: perl $0 quote_number\n"
        unless @ARGV;

    my $b = WWW::BashOrg->new;

    $b->get_quote(shift)
        or die $b->error . "\n";

    print "$b\n";

=head1 DESCRIPTION

A simple a module to obtain either a random quote or a quote by number from
either L<http://bash.org/> or L<http://qdb.us/>.

=head1 CONSTRUCTOR

=head2 C<new>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $b = WWW::BashOrg->new;

    my $b = WWW::BashOrg->new(
        ua  => LWP::UserAgent->new(
            agent   => 'Opera 9.5',
            timeout => 30,
        )
    );

Returns a newly baked C<WWW::BashOrg> object. All arguments are options, so far there
are only two arguments are available:

=head3 C<ua>

    my $b = WWW::BashOrg->new(
        ua  => LWP::UserAgent->new(
            agent   => 'Opera 9.5',
            timeout => 30,
        ),
    );

B<Optional>. Takes an L<LWP::UserAgent> object as a value. This object will be used for
fetching quotes from L<http://bash.org/> or L<http://qdb.us/>. B<Defaults to:>

    LWP::UserAgent->new(
        agent   => 'Opera 9.5',
        timeout => 30,
    )

=head3 C<default_site>

    my $b = WWW::BashOrg->new(
        default_site  => 'qdb'
    );

B<Optional>. Which site to retrieve quotes from by default when not
specified in the method
parameters, C<'qdb'> or C<'bash'>. Default is C<'bash'>.

=head1 METHODS

=head2 C<get_quote>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $quote = $b->get_quote('202477')
        or die $b->error;

    $quote = $b->get_quote('1622', 'qdb')
        or die $b->error;

The first argument, the number of the quote to fetch, is mandatory.
You may also optionally specify
which site to retrieve the quote from
(C<'qdb'> or C<'bash'>). If an error occurs, returns
C<undef> and the reason for failure can be obtained using C<error()> method.

=head2 C<random>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $quote = $b->random('bash')
        or die $b->error;

Has one optional argument, which site to return quote from
(C<'qdb'> or C<'bash'>). Returns a random quote.
If an error occurs, returns C<undef> and the reason for failure can be obtained using
C<error()> method.

=head2 C<error>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $quote = $b->random
        or die $b->error;

If an error occurs during execution of C<random()> or C<get_quote()> method will return
the reason for failure.

=head2 C<quote>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $last_quote = $b->quote;

    my $last_quote = "$b";

Takes no arguments. Must be called after a successful call to either C<random()> or
C<get_quote()>. Returns the same return value as last C<random()> or C<get_quote()> returned.
B<This method is overloaded> thus you can interpolate C<WWW::Bashorg> in a string to obtain
the quote.

=head2 C<ua>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $old_ua = $b->ua;

    $b->ua(
        LWP::UserAgent->new( timeout => 20 ),
    );

Returns current L<LWP::UserAgent> object that is used for fetching quotes. Takes one
option argument that must be an L<LWP::UserAgent> object (or compatible) - this object
will be used for any future requests.

=head2 C<default_site>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    if ( $b->default_site eq 'qdb' ) {
        $b->default_site('bash');
    }

Returns current default site to retrieve quotes from. Takes an optional argument to change this setting (C<'qdb'> or C<'bash'>).

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-BashOrg>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-BashOrg/issues>

If you can't access GitHub, you can email your request
to C<bug-WWW-BashOrg at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 CONTRIBUTORS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/JBARRETT"> <img src="http://www.gravatar.com/avatar/6a296a67e2590050b299c30751a01919?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F3a47418b43981827dbc0e147c2f9199c" alt="JBARRETT" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">JBARRETT</span> </a> </span>

=for text John Barrett <john@jbrt.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut