package WWW::Pastebin::PastebinCa::Create;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use URI;
use WWW::Mechanize;
use JSON::PP ();
use Digest::SHA ();

# pastebin.ca was rebuilt in 2026. The old HTML paste form is gone; pastes
# are now created through a documented JSON API:
#   GET  /api/v1/pastes/pow-challenge  -> proof-of-work challenge (for
#                                         anonymous, key-less creation)
#   POST /api/v1/pastes                -> create the paste
# Anonymous creates must solve the proof-of-work challenge (in lieu of the
# browser Turnstile widget) and must set an expiry no longer than 90 days.
my $Base            = 'https://pastebin.ca';
my $Max_Expire_Secs = 7_776_000; # 90 days: server-enforced anon maximum

my %Valid_Langs   = valid_langs();
my %Valid_Expires = map { $_ => $_ } valid_expires();

# Map the historical numeric 'lang' codes to the syntax hint strings the
# rebuilt site understands. Unknown/Raw map to plain "text".
my %Lang_To_Syntax = (
    1  => 'text',       2  => 'asterisk',   3  => 'c',
    4  => 'cpp',        5  => 'php',        6  => 'perl',
    7  => 'java',       8  => 'vb',         9  => 'csharp',
    10 => 'ruby',       11 => 'python',     12 => 'pascal',
    13 => 'mirc',       14 => 'pli',        15 => 'xml',
    16 => 'sql',        17 => 'scheme',     18 => 'actionscript',
    19 => 'ada',        20 => 'apache',     21 => 'nasm',
    22 => 'asp',        23 => 'bash',       24 => 'css',
    25 => 'delphi',     26 => 'html',       27 => 'javascript',
    28 => 'lisp',       29 => 'lua',        30 => 'asm',
    31 => 'objc',       32 => 'vbnet',      33 => 'log',
    34 => 'diff',
);

# Map the historical 'expire' strings to a number of seconds.
my %Expire_To_Secs = (
    '5 minutes'  => 5*60,        '10 minutes' => 10*60,
    '15 minutes' => 15*60,       '30 minutes' => 30*60,
    '45 minutes' => 45*60,       '1 hour'     => 60*60,
    '2 hours'    => 2*3600,      '4 hours'    => 4*3600,
    '8 hours'    => 8*3600,      '12 hours'   => 12*3600,
    '1 day'      => 86400,       '2 days'     => 2*86400,
    '3 days'     => 3*86400,     '1 week'     => 7*86400,
    '2 weeks'    => 14*86400,    '3 weeks'    => 21*86400,
    '1 month'    => 30*86400,    '2 months'   => 60*86400,
    '3 months'   => 90*86400,    '4 months'   => 120*86400,
    '5 months'   => 150*86400,   '6 months'   => 180*86400,
    '1 year'     => 365*86400,
);

use overload q|""| => sub { shift->paste_uri };

sub new {
    my $self = bless {}, shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{timeout} ||= 30;
    $args{mech}    ||= WWW::Mechanize->new(
        autocheck => 0,
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
    );

    $self->mech( $args{mech} );

    return $self;
}

sub paste {
    my ( $self, $content ) = splice @_, 0, 2;

    $self->$_(undef) for qw(paste_uri error);

    defined $content
        or carp "first argument to paste() is not defined" and return;

    croak "Must have even number of optional arguments to paste()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;
    %args = (
        content     => $content,
        name        => '',
        desc        => '',
        tags        => '',
        lang        => 1,
        expire      => '',
        %args,
    );

    croak q|Invalid 'lang' was specified to paste(). |
        . q|print Dumper { WWW::Pastebin::PastebinCa::Create::valid_langs }|
        unless exists $Valid_Langs{ $args{lang} };

    croak q|Invalid 'expire' was specified to paste(). |
      . q|print Dumper { WWW::Pastebin::PastebinCa::Create::valid_expires }|
        if length $args{expire}
            and not exists $Valid_Expires{ $args{expire} };

    my $mech = $self->mech;

    # 1) Obtain and solve a proof-of-work challenge so we can create
    #    anonymously without an account/API key.
    my $pow = $self->_solve_pow
        or return; # error already set

    # 2) Work out the expiry. Anonymous pastes must expire within 90 days,
    #    so an empty (historically "never") or too-long value is capped.
    my $expire_secs = length $args{expire}
        ? ( $Expire_To_Secs{ $args{expire} } || $Max_Expire_Secs )
        : $Max_Expire_Secs;
    $expire_secs = $Max_Expire_Secs if $expire_secs > $Max_Expire_Secs;

    # 3) Build and send the create request.
    my %payload = (
        body               => $args{content},
        syntax_hint        => ( $Lang_To_Syntax{ $args{lang} } || 'text' ),
        visibility         => 'unlisted',
        expires_in_seconds => $expire_secs,
        pow_challenge_id   => $pow->{challenge_id},
        pow_nonce          => "$pow->{nonce}",
    );
    $payload{title} = $args{name}
        if length $args{name};

    my $json = JSON::PP->new->utf8->canonical;
    my $res  = $mech->post(
        "$Base/api/v1/pastes",
        'Content-Type' => 'application/json',
        Content        => $json->encode( \%payload ),
    );

    unless ( $res->is_success ) {
        my $msg = $res->status_line;
        my $body = eval { $json->decode( $res->decoded_content ) };
        $msg .= " ($body->{error})"
            if ref $body eq 'HASH' and defined $body->{error};
        return $self->_set_error( "Network error: $msg" );
    }

    my $data = eval { $json->decode( $res->decoded_content ) };
    return $self->_set_error('Failed to parse response from pastebin.ca')
        unless ref $data eq 'HASH' and defined $data->{url};

    return $self->paste_uri( URI->new( $data->{url} ) );
}

# Fetch a proof-of-work challenge and brute-force a nonce whose
# sha256(prefix . nonce) has `difficulty_bits` leading zero bits.
sub _solve_pow {
    my $self = shift;
    my $mech = $self->mech;

    my $res = $mech->get("$Base/api/v1/pastes/pow-challenge");
    return $self->_set_error(
        'Network error: ' . $res->status_line
    ) unless $res->is_success;

    my $c = eval { JSON::PP->new->utf8->decode( $res->decoded_content ) };
    return $self->_set_error('Failed to parse proof-of-work challenge')
        unless ref $c eq 'HASH'
            and defined $c->{prefix}
            and defined $c->{challenge_id}
            and defined $c->{difficulty_bits};

    my $bits        = $c->{difficulty_bits};
    my $prefix      = $c->{prefix};
    my $full_bytes  = int( $bits / 8 );
    my $rem_bits    = $bits % 8;
    my $rem_mask    = $rem_bits ? ( ( 0xFF << ( 8 - $rem_bits ) ) & 0xFF ) : 0;

    for ( my $nonce = 0; $nonce <= 2_000_000_000; $nonce++ ) {
        my $hash = Digest::SHA::sha256( $prefix . $nonce );
        my $ok = 1;
        for my $i ( 0 .. $full_bytes - 1 ) {
            if ( ord substr $hash, $i, 1 ) { $ok = 0; last }
        }
        if ( $ok and $rem_mask ) {
            $ok = 0 if ord( substr $hash, $full_bytes, 1 ) & $rem_mask;
        }
        if ( $ok ) {
            return { challenge_id => $c->{challenge_id}, nonce => $nonce };
        }
    }

    return $self->_set_error('Failed to solve proof-of-work challenge');
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub valid_langs {
    return (
         1 => 'Raw',
         2 => 'Asterisk Configuration',
         3 => 'C Source',
         4 => 'C++ Source',
         5 => 'PHP Source',
         6 => 'Perl Source',
         7 => 'Java Source',
         8 => 'Visual Basic Source',
         9 => 'C# Source',
        10 => 'Ruby Source',
        11 => 'Python Source',
        12 => 'Pascal Source',
        13 => 'mIRC Script',
        14 => 'PL/I Source',
        15 => 'XML Document',
        16 => 'SQL Statement',
        17 => 'Scheme Source',
        18 => 'Action Script',
        19 => 'Ada Source',
        20 => 'Apache Configuration',
        21 => 'Assembly (NASM)',
        22 => 'ASP',
        23 => 'BASH Script',
        24 => 'CSS',
        25 => 'Delphi Source',
        26 => 'HTML 4.0 Strict',
        27 => 'JavaScript',
        28 => 'LISP Source',
        29 => 'Lua Source',
        30 => 'Microprocessor ASM',
        31 => 'Objective C',
        32 => 'Visual Basic .NET',
        33 => 'Script Log',
        34 => 'Diff / Patch',
    );
}

sub valid_expires {
    return (
        '2 hours',
        '4 hours',
        '1 year',
        '2 weeks',
        '45 minutes',
        '2 months',
        '30 minutes',
        '1 week',
        '1 hour',
        '15 minutes',
        '10 minutes',
        '3 days',
        '5 months',
        '4 months',
        '5 minutes',
        '8 hours',
        '2 days',
        '3 months',
        '1 day',
        '12 hours',
        '3 weeks',
        '6 months',
        '1 month',
    );
}

sub mech {
    my $self = shift;
    if ( @_ ) { $self->{MECH} = shift };
    return $self->{MECH};
}

sub paste_uri {
    my $self = shift;
    if ( @_ ) { $self->{PASTE_URI} = shift };
    return $self->{PASTE_URI};
}

sub error {
    my $self = shift;
    if ( @_ ) { $self->{ERROR} = shift };
    return $self->{ERROR};
}

1;
__END__

=encoding utf8

=for stopwords desc pastebin Turnstile ktnx

=head1 NAME

WWW::Pastebin::PastebinCa::Create - create new pastes on http://pastebin.ca/ from Perl

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use strict;
    use warnings;

    use WWW::Pastebin::PastebinCa::Create;

    my $paster = WWW::Pastebin::PastebinCa::Create->new;

    $paster->paste('testing')
        or die $paster->error;

    print "Your paste can be found on $paster\n";

=for html  </div></div>

=head1 DESCRIPTION

The module provides means of pasting large texts into
L<http://pastebin.ca/> pastebin site.

B<Note:> pastebin.ca was rebuilt in 2026 and now exposes a documented API
(see L<https://pastebin.ca/api/v1/openapi.json>) instead of the old HTML
paste form. This module creates pastes anonymously through that API,
solving the site's proof-of-work challenge in place of the browser
Turnstile widget (no account or API key is required). Because the site
requires anonymous pastes to expire, an C<expire> that is empty or longer
than 90 days is capped at pastebin.ca's 90-day maximum (see C<expire>
below).

=head1 CONSTRUCTOR

=head2 new

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $paster = WWW::Pastebin::PastebinCa::Create->new;

    my $paster = WWW::Pastebin::PastebinCa::Create->new( timeout => 10 );

    my $paster = WWW::Pastebin::PastebinCa::Create->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

Bakes and returns a fresh WWW::Pastebin::PastebinCa::Create object. Takes two
I<optional> arguments which are as follows:

=head3 timeout

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

    my $paster = WWW::Pastebin::PastebinCa::Create->new( timeout => 10 );

Takes a scalar as a value which is the value that will be passed to
the L<WWW::Mechanize> object to indicate connection timeout in seconds.
B<Defaults to:> C<30> seconds

=head3 mech

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">

    my $paster = WWW::Pastebin::PastebinCa::Create->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

If a simple timeout is not enough for your needs feel free to specify
the C<mech> argument which takes a L<WWW::Mechanize> object as a value.
B<Defaults to:> plain L<WWW::Mechanize> object with C<timeout> argument
set to whatever WWW::Pastebin::PastebinCa::Create's C<timeout> argument is set to
as well as C<agent> argument is set to mimic FireFox.

=head1 METHODS

=head2 paste

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $uri = $paster->paste('some long text')
        or die $paster->error;

    my $uri2 = $paster->paste(
        'some long text',
        name    => 'Zoffix',
        lang    => 6, # perl syntax highlights
        expire  => '5 minutes',
        desc    => 'some codes',
        tags    => 'some space separated tags',
    ) or die $paster->error;

Instructs the object to create a new paste. If an error occured during
pasting the method will return either C<undef> or an empty list
depending on the context and the error will be available via C<error()>
method. On success returns a L<URI> object poiting to the newly created
paste (see also C<uri()> method). The first argument is
I<mandatory> content of your paste. The rest are optional arguments which
are passed in a key/value pairs. The optional arguments are as follows:

=head3 name

    { name    => 'Zoffix' }

B<Optional>. Takes a scalar as an argument which specifies the name of the
poster or
the titles of the paste. B<Defaults to:> empty string, which in turn results
to word C<Stuff> being the title of the paste. B<Defaults to:> empty string.

=head2 lang

    { lang    => 6 }

B<Optional>. Takes an integer value from C<1> to C<34> representing the
(computer)
language of the paste, or, in other words, the syntax highlights to turn
on. B<Defaults to:> C<1> (Raw). The integer C<lang> codes are as follows:

         1 => 'Raw',
         2 => 'Asterisk Configuration',
         3 => 'C Source',
         4 => 'C++ Source',
         5 => 'PHP Source',
         6 => 'Perl Source',
         7 => 'Java Source',
         8 => 'Visual Basic Source',
         9 => 'C# Source',
        10 => 'Ruby Source',
        11 => 'Python Source',
        12 => 'Pascal Source',
        13 => 'mIRC Script',
        14 => 'PL/I Source',
        15 => 'XML Document',
        16 => 'SQL Statement',
        17 => 'Scheme Source',
        18 => 'Action Script',
        19 => 'Ada Source',
        20 => 'Apache Configuration',
        21 => 'Assembly (NASM)',
        22 => 'ASP',
        23 => 'BASH Script',
        24 => 'CSS',
        25 => 'Delphi Source',
        26 => 'HTML 4.0 Strict',
        27 => 'JavaScript',
        28 => 'LISP Source',
        29 => 'Lua Source',
        30 => 'Microprocessor ASM',
        31 => 'Objective C',
        32 => 'Visual Basic .NET',
        33 => 'Script Log',
        34 => 'Diff / Patch',

=head3 expire

    { expire  => '5 minutes' }

B<Optional>. Takes a "valid expire string" as an argument. Specifies when
the paste should expire. B<Note:> the rebuilt pastebin.ca requires anonymous
pastes to expire within 90 days, so an empty value (historically "never")
or any value longer than 90 days is capped at 90 days. B<Defaults to:>
empty string, which is now treated as "the 90-day maximum". Possible
"valid expire string"s are as follows:

    '2 hours'
    '4 hours'
    '1 year'
    '2 weeks'
    '45 minutes'
    '2 months'
    '30 minutes'
    '1 week'
    '1 hour'
    '15 minutes'
    '10 minutes'
    '3 days'
    '5 months'
    '4 months'
    '5 minutes'
    '8 hours'
    '2 days'
    '3 months'
    '1 day'
    '12 hours'
    '3 weeks'
    '6 months'
    '1 month'

=head3 desc

    { desc => 'some codes' }

B<Optional>. Takes a scalar string representing the description of the paste.
B<Defaults to:> empty string. B<Note:> the rebuilt pastebin.ca no longer
stores a separate paste description, so this argument is accepted for
backwards compatibility but has no effect.

=head3 tags

    { tags => 'some space separated tags' }

B<Optional>.
Takes a scalar string which should be space separated "tags" to tag
the paste with. B<Defaults to:> empty string. B<Note:> the rebuilt
pastebin.ca no longer supports paste tags, so this argument is accepted for
backwards compatibility but has no effect.

=head2 error

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $uri = $paster->paste('some long text')
        or die $paster->error;

If an error occured during
a call to C<paste()> it will return either C<undef> or an empty list
depending on the context and the error will be available via C<error()>
method. Takes no arguments, returns an error message explaining why
C<paste()> failed.

=head2 paste_uri

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $paste_uri = $paster->paste_uri;

    print "Paste was pasted on $paster\n";

Must be called after a successfull call to C<paste()>. Takes no arguments,
returns a L<URI> object pointing to a newly created paste. This method
is overloaded with C<q|""|>, thus you can simply interpolate your object
in a string to obtain the URI of newly created paste.

=head2 valid_langs

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-key-value.png">

    my %valid_lang_codes_and_descriptions = $paster->valid_langs;
    use Data::Dumper;
    print Dumper \%valid_lang_codes_and_descriptions;

Takes no arguments. Returns a flattened hash of valid language codes
to use in C<lang> argument to C<paste()> method as keys and the language
descriptions as values.

=head2 valid_expires

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-list.png">

    print "'$_' is a valid expire value\n"
        for $paster->valid_expires;

Takes no arguments. Returns a list of valid values for C<expire> argument
to C<paste()> method

=head2 mech

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $old_mech = $paster->mech;

    $paster->mech( WWW::Mechanize->new( agent => '007' ) );

Returns a L<WWW::Mechanize> object used internally for pasting. When
called with an optional argument (which must be a L<WWW::Mechanize> object)
will use it for pasting.

=head1 NO SPAM

Please note that pastebin.ca has a spam protection and will ban you for
pasting too much. So don't abuse it, ktnx.

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Create>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-Pastebin-PastebinCa-Create/issues>

If you can't access GitHub, you can email your request
to C<bug-www-pastebin-pastebinca-create at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
