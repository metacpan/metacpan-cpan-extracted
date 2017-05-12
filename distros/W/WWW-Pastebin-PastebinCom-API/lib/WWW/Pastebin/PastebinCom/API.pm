package WWW::Pastebin::PastebinCom::API;

use strict;
use warnings;

our $VERSION = '1.001004'; # VERSION

use LWP::UserAgent;
use Carp;
use HTTP::Cookies;

use base qw/Class::Data::Accessor/;
__PACKAGE__->mk_classaccessors(qw/
    error
    api_key
    user_key
    paste_url
    _ua
/);

use overload q|""| => sub {
    my $obj = shift;
    defined $obj->error ? 'Error: ' . $obj->error : $obj->paste_url
};

sub new {
    my $class = shift;
    croak 'Must have even number of arguments to the constructor'
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    unless ( $args{timeout} ) {
        $args{timeout} = 30;
    }
    unless ( $args{ua} ) {
        $args{ua} = LWP::UserAgent->new(
            timeout => $args{timeout},
            agent   => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:21.0)'
                        . ' Gecko/20100101 Firefox/21.0',
        );
    }

    my $self = bless {}, $class;
    $self->_ua( $args{ua} );
    $self->api_key( $args{api_key} );
    $self->user_key( $args{user_key} );

    return $self;
}

sub get_user_info {
    my $self = shift;
    $self->error( undef );

    my $api_key = $self->_get_api_key
        or return $self->_set_error(q|Missing API key|);

    my $user_key = $self->_get_user_key
        or return $self->_set_error(
            q|Missing USER key. See ->get_user_key() method|
        );

    my $response = $self->_ua->post(
        'http://pastebin.com/api/api_post.php',
        {
            api_dev_key         => $api_key,
            api_user_key        => $user_key,
            api_option          => 'userdetails',
        },
    );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error( $response->content )
            if $response->content =~ /^Bad API request/;

        return $self->_parse_user_xml( $response->content );
    }
    else {
        $self->error( $response->status_line );
        return;
    }
}

sub list_user_pastes {
    my $self = shift;
    my $limit = shift || 50;
    $limit = 1    if $limit < 1;
    $limit = 1000 if $limit > 1000;

    $self->error( undef );

    my $api_key = $self->_get_api_key
        or return $self->_set_error(q|Missing API key|);

    my $user_key = $self->_get_user_key
        or return $self->_set_error(
            q|Missing USER key. See ->get_user_key() method|
        );

    my $response = $self->_ua->post(
        'http://pastebin.com/api/api_post.php',
        {
            api_dev_key         => $api_key,
            api_user_key        => $user_key,
            api_results_limit   => $limit,
            api_option          => 'list',
        },
    );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error( $response->content )
            if $response->content =~ /^Bad API request/;

        return []
            if $response->content =~ /^No pastes found/;

        return $self->_parse_xml( $response->content );
    }
    else {
        $self->error( $response->status_line );
        return;
    }
}

sub list_trends {
    my $self = shift;

    $self->error( undef );

    my $api_key = $self->_get_api_key
        or return $self->_set_error(q|Missing API key|);

    my $response = $self->_ua->post(
        'http://pastebin.com/api/api_post.php',
        {
            api_dev_key         => $api_key,
            api_option          => 'trends',
        },
    );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error( $response->content )
            if $response->content =~ /^Bad API request/;

        return $self->_parse_xml( $response->content );
    }
    else {
        $self->error( $response->status_line );
        return;
    }
}

sub delete_paste {
    my $self       = shift;
    my $paste_key  = shift;

    $paste_key =~ s{(?:https?://)?(?:www\.)?pastebin\.com/}{}i;

    return $self->_set_error('Missing paste key')
        unless defined $paste_key and length $paste_key;

    $self->error( undef );

    my $api_key = $self->_get_api_key
        or return $self->_set_error(q|Missing API key|);

    my $user_key = $self->_get_user_key
        or return $self->_set_error(
            q|Missing USER key. See ->get_user_key() method|
        );

    my $response = $self->_ua->post(
        'http://pastebin.com/api/api_post.php',
        {
            # mandatory API keys
            api_dev_key         => $api_key,
            api_user_key        => $user_key,
            api_paste_key       => $paste_key,
            api_option          => 'delete',
        },
    );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error( $response->content )
            if $response->content =~ /^Bad API request/;

        return 1;
    }
    else {
        $self->error( $response->status_line );
        return;
    }
    return 1;
}

sub get_paste {
    my $self       = shift;
    my $paste_key  = shift;
    my ( $login, $pass ) = @_;

    $self->error( undef );

    $paste_key =~ s{(?:https?://)?(?:www\.)?pastebin\.com/}{}i;

    defined $paste_key and length $paste_key
        or return $self->_set_error('Missing paste ID or URL');

    if ( defined $login and defined $pass ) {
        $self->_ua->cookie_jar( HTTP::Cookies->new );
        $self->_ua->post(
            'http://pastebin.com/login.php', {
                submit_hidden   => 'submit_hidden',
                user_name       => $login,
                user_password   => $pass,
                submit          => 'Login',
            }
        );
    }

    my $response = $self->_ua->get(
        "http://pastebin.com/raw.php?i=$paste_key",
    );

    $self->_ua->cookie_jar( undef );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error(q|This paste doesn't exist|)
            unless defined $response->content
                and length $response->content;

        return $self->_set_error( $response->content )
            if $response->content
            eq 'Error, this is a private paste. If this is your '
                . 'private paste, please login to Pastebin first.';

        return $response->content;
    }
    else {
        if ( $response->status_line eq '404 Not Found' ) {
            $self->error(q|This paste doesn't exist|);
        }
        else {
            $self->error( 'Network error: ' . $response->status_line );
        }
        return;
    }
}

sub paste {
    my $self       = shift;
    my $paste_text = shift;

    $self->error( undef );
    $self->paste_url( undef );

    defined $paste_text and length $paste_text
        or return $self->_set_error('Paste text is empty');

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    my @args = $self->_prepare_optional_api_options( \%args )
        or return;

    my $api_key = $self->_get_api_key
        or return $self->_set_error(q|Missing API key|);

    my $response = $self->_ua->post(
        'http://pastebin.com/api/api_post.php',
        {
            # mandatory API keys
            api_dev_key    => $api_key,
            api_option     => 'paste',
            api_paste_code => $paste_text,

            @args,
        },
    );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error( $response->content )
            if $response->content =~ /^Bad API request|^Post limit, maximum pastes/;

        return $self->paste_url( $response->content );
    }
    else {
        $self->error( $response->status_line );
        return;
    }
}

sub get_user_key {
    my ( $self, $login, $pass ) = @_;

    $self->error( undef );
    $self->user_key( undef );

    my $api_key = $self->_get_api_key
        or return $self->_set_error(q|Missing API key|);

    my $response = $self->_ua->post(
        'http://pastebin.com/api/api_login.php',
        {
            api_dev_key         => $api_key,
            api_user_name       => $login,
            api_user_password   => $pass,
        },
    );

    if ( $response->is_success or $response->is_redirect ) {
        return $self->_set_error( $response->content )
            if $response->content =~ /^Bad API request/;

        return $self->user_key( $response->content );
    }
    else {
        $self->error( $response->status_line );
        return;
    }
}

sub _parse_user_xml {
    my ( $self, $content ) = @_;

    $content =~ s{<user>\s*(.+)\s*</user>}{$1}gs;

    my %user = $content =~ ( m{<([^>]+)>(.*?)</\1>}sg );
    $user{ substr $_, 5 } = delete $user{ $_ } for keys %user;
    if ( $user{private} == 2 ) {
        $user{private} = 1
    }
    elsif ( $user{private} == 1 ) {
        $user{unlisted} = 1;
    }
    else {
        delete $user{private};
    }

    return wantarray ? %user : \%user;
}

sub _parse_xml {
    my ( $self, $content ) = @_;

    my @out;
    for ( $content =~ m{<paste>(.+?)</paste>}gs ) {
        my %paste = ( m{<([^>]+)>(.*?)</\1>}sg );
        $paste{ substr $_, 6 } = delete $paste{ $_ } for keys %paste;

        my $private_flag = delete $paste{private};
        if ( $private_flag == 2 ) { $paste{private} = 1; }
        elsif ( $private_flag == 1 ) { $paste{unlisted} = 1; }

        push @out, \%paste;
    }

    return wantarray ? @out : \@out;
}

sub _get_user_key {
    my $self = shift;

    return $self->user_key
        || return $self->_set_error('API user key must be provided'
            . ' to create private pastes. See ->user_key() or'
            . ' ->get_user_key() in the documentation.');
}

sub _get_api_key {
    my $self = shift;

    return $self->api_key
        || return $self->_set_error(q|Can't operate without an API key.|
            . q| Sign up / Log in to pastebin.com, then go|
            . q| to http://pastebin.com/api to see your API key|
            . q| (it's in the section "Your Unique Developer API Key")|);
}

sub _prepare_optional_api_options {
    my ( $self, $args ) = @_;
    my @out_args;

    push @out_args, api_paste_name => $args->{title}
        if defined $args->{title}; # title of the paste

    if ( defined $args->{format} ) {
        $self->_is_valid_format( $args->{format} )
            or return $self->_set_error(
                'Invalid syntax highlighting code. See ->valid_formats()'
                . ' method in the documentation'
            );
        push @out_args, api_paste_format => $args->{format};
    }

    if( $args->{owned} and not $args->{private} ) {
        defined ( $args->{user_key} || $self->user_key )
            or return $self->set_error(
                'API user key must be provided to create owned pastes.'
                    . ' See ->user_key() or ->get_user_key() in the'
                    . ' documentation.'
            );

            push @out_args,
                api_user_key => ( $args->{user_key} || $self->user_key );
    }

    if ( $args->{private} ) {
        defined ( $args->{user_key} || $self->user_key )
            or return $self->_set_error(
                'API user key must be provided to create private pastes.'
                    . ' See ->user_key() or ->get_user_key() in the'
                    . ' documentation.'
            );

        push @out_args,
            api_paste_private => 2,
            api_user_key => ( $args->{user_key} || $self->user_key );
    }
    elsif ( $args->{unlisted} ) {
        push @out_args, api_paste_private => 1;
    }
    else {
        ### DEBUGGING NOTE:
        ### Pastebin will automatically list duplicate content
        ### or content with "some" keywords as unlisted
        ### even if we tell it to go public
        push @out_args, api_paste_private => 0;
    }

    if ( $args->{expiry} ) {
        my $expiry = $self->_translate_expiry( $args->{expiry} )
            or return $self->_set_error('Invalid `expiry` argument');

        push @out_args, api_paste_expire_date => $expiry;
    }

    return @out_args;
}

sub _translate_expiry {
    my ( $self, $expiry ) = @_;

    my %expiries = (
        # 10 Minutes
        '10m'   => '10M',
        m10     => '10M',
        asap    => '10M',

        # 1 Hour
        h       => '1H',
        '1h'    => '1H',

        # 1 Day
        d       => '1D',
        '1d'    => '1D',
        soon    => '1D',

        # 1 Week
        w       => '1W',
        '1w'    => '1W',
        awhile  => '1W',

        '2w'    => '2W',
        w2      => '2W',

        # 1 Month
        '1m'    => '1M',
        m1      => '1M',
        eventually      => '1M',

        # Never
        n       => 'N',
        never   => 'N',
    );

    return $expiries{ lc $expiry }
        || $self->_set_error('Invalid expiry value');
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub _is_valid_format {
    my ( $self, $format ) = @_;

    my %formats = (
        '4cs' => '4CS',
        '6502acme' => '6502 ACME Cross Assembler',
        '6502kickass' => '6502 Kick Assembler',
        '6502tasm' => '6502 TASM/64TASS',
        'abap' => 'ABAP',
        'actionscript' => 'ActionScript',
        'actionscript3' => 'ActionScript 3',
        'ada' => 'Ada',
        'algol68' => 'ALGOL 68',
        'apache' => 'Apache Log',
        'applescript' => 'AppleScript',
        'apt_sources' => 'APT Sources',
        'arm' => 'ARM',
        'asm' => 'ASM (NASM)',
        'asp' => 'ASP',
        'asymptote' => 'Asymptote',
        'autoconf' => 'autoconf',
        'autohotkey' => 'Autohotkey',
        'autoit' => 'AutoIt',
        'avisynth' => 'Avisynth',
        'awk' => 'Awk',
        'bascomavr' => 'BASCOM AVR',
        'bash' => 'Bash',
        'basic4gl' => 'Basic4GL',
        'bibtex' => 'BibTeX',
        'blitzbasic' => 'Blitz Basic',
        'bnf' => 'BNF',
        'boo' => 'BOO',
        'bf' => 'BrainFuck',
        'c' => 'C',
        'c_mac' => 'C for Macs',
        'cil' => 'C Intermediate Language',
        'csharp' => 'C#',
        'cpp' => 'C++',
        'cpp-qt' => 'C++ (with QT extensions)',
        'c_loadrunner' => 'C: Loadrunner',
        'caddcl' => 'CAD DCL',
        'cadlisp' => 'CAD Lisp',
        'cfdg' => 'CFDG',
        'chaiscript' => 'ChaiScript',
        'clojure' => 'Clojure',
        'klonec' => 'Clone C',
        'klonecpp' => 'Clone C++',
        'cmake' => 'CMake',
        'cobol' => 'COBOL',
        'coffeescript' => 'CoffeeScript',
        'cfm' => 'ColdFusion',
        'css' => 'CSS',
        'cuesheet' => 'Cuesheet',
        'd' => 'D',
        'dcl' => 'DCL',
        'dcpu16' => 'DCPU-16',
        'dcs' => 'DCS',
        'delphi' => 'Delphi',
        'oxygene' => 'Delphi Prism (Oxygene)',
        'diff' => 'Diff',
        'div' => 'DIV',
        'dos' => 'DOS',
        'dot' => 'DOT',
        'e' => 'E',
        'ecmascript' => 'ECMAScript',
        'eiffel' => 'Eiffel',
        'email' => 'Email',
        'epc' => 'EPC',
        'erlang' => 'Erlang',
        'fsharp' => 'F#',
        'falcon' => 'Falcon',
        'fo' => 'FO Language',
        'f1' => 'Formula One',
        'fortran' => 'Fortran',
        'freebasic' => 'FreeBasic',
        'freeswitch' => 'FreeSWITCH',
        'gambas' => 'GAMBAS',
        'gml' => 'Game Maker',
        'gdb' => 'GDB',
        'genero' => 'Genero',
        'genie' => 'Genie',
        'gettext' => 'GetText',
        'go' => 'Go',
        'groovy' => 'Groovy',
        'gwbasic' => 'GwBasic',
        'haskell' => 'Haskell',
        'haxe' => 'Haxe',
        'hicest' => 'HicEst',
        'hq9plus' => 'HQ9 Plus',
        'html4strict' => 'HTML',
        'html5' => 'HTML 5',
        'icon' => 'Icon',
        'idl' => 'IDL',
        'ini' => 'INI file',
        'inno' => 'Inno Script',
        'intercal' => 'INTERCAL',
        'io' => 'IO',
        'j' => 'J',
        'java' => 'Java',
        'java5' => 'Java 5',
        'javascript' => 'JavaScript',
        'jquery' => 'jQuery',
        'kixtart' => 'KiXtart',
        'latex' => 'Latex',
        'ldif' => 'LDIF',
        'lb' => 'Liberty BASIC',
        'lsl2' => 'Linden Scripting',
        'lisp' => 'Lisp',
        'llvm' => 'LLVM',
        'locobasic' => 'Loco Basic',
        'logtalk' => 'Logtalk',
        'lolcode' => 'LOL Code',
        'lotusformulas' => 'Lotus Formulas',
        'lotusscript' => 'Lotus Script',
        'lscript' => 'LScript',
        'lua' => 'Lua',
        'm68k' => 'M68000 Assembler',
        'magiksf' => 'MagikSF',
        'make' => 'Make',
        'mapbasic' => 'MapBasic',
        'matlab' => 'MatLab',
        'mirc' => 'mIRC',
        'mmix' => 'MIX Assembler',
        'modula2' => 'Modula 2',
        'modula3' => 'Modula 3',
        '68000devpac' => 'Motorola 68000 HiSoft Dev',
        'mpasm' => 'MPASM',
        'mxml' => 'MXML',
        'mysql' => 'MySQL',
        'nagios' => 'Nagios',
        'newlisp' => 'newLISP',
        'text' => 'None',
        'nsis' => 'NullSoft Installer',
        'oberon2' => 'Oberon 2',
        'objeck' => 'Objeck Programming Langua',
        'objc' => 'Objective C',
        'ocaml-brief' => 'OCalm Brief',
        'ocaml' => 'OCaml',
        'octave' => 'Octave',
        'pf' => 'OpenBSD PACKET FILTER',
        'glsl' => 'OpenGL Shading',
        'oobas' => 'Openoffice BASIC',
        'oracle11' => 'Oracle 11',
        'oracle8' => 'Oracle 8',
        'oz' => 'Oz',
        'parasail' => 'ParaSail',
        'parigp' => 'PARI/GP',
        'pascal' => 'Pascal',
        'pawn' => 'PAWN',
        'pcre' => 'PCRE',
        'per' => 'Per',
        'perl' => 'Perl',
        'perl6' => 'Perl 6',
        'php' => 'PHP',
        'php-brief' => 'PHP Brief',
        'pic16' => 'Pic 16',
        'pike' => 'Pike',
        'pixelbender' => 'Pixel Bender',
        'plsql' => 'PL/SQL',
        'postgresql' => 'PostgreSQL',
        'povray' => 'POV-Ray',
        'powershell' => 'Power Shell',
        'powerbuilder' => 'PowerBuilder',
        'proftpd' => 'ProFTPd',
        'progress' => 'Progress',
        'prolog' => 'Prolog',
        'properties' => 'Properties',
        'providex' => 'ProvideX',
        'purebasic' => 'PureBasic',
        'pycon' => 'PyCon',
        'python' => 'Python',
        'pys60' => 'Python for S60',
        'q' => 'q/kdb+',
        'qbasic' => 'QBasic',
        'rsplus' => 'R',
        'rails' => 'Rails',
        'rebol' => 'REBOL',
        'reg' => 'REG',
        'rexx' => 'Rexx',
        'robots' => 'Robots',
        'rpmspec' => 'RPM Spec',
        'ruby' => 'Ruby',
        'gnuplot' => 'Ruby Gnuplot',
        'sas' => 'SAS',
        'scala' => 'Scala',
        'scheme' => 'Scheme',
        'scilab' => 'Scilab',
        'sdlbasic' => 'SdlBasic',
        'smalltalk' => 'Smalltalk',
        'smarty' => 'Smarty',
        'spark' => 'SPARK',
        'sparql' => 'SPARQL',
        'sql' => 'SQL',
        'stonescript' => 'StoneScript',
        'systemverilog' => 'SystemVerilog',
        'tsql' => 'T-SQL',
        'tcl' => 'TCL',
        'teraterm' => 'Tera Term',
        'thinbasic' => 'thinBasic',
        'typoscript' => 'TypoScript',
        'unicon' => 'Unicon',
        'uscript' => 'UnrealScript',
        'ups' => 'UPC',
        'urbi' => 'Urbi',
        'vala' => 'Vala',
        'vbnet' => 'VB.NET',
        'vedit' => 'Vedit',
        'verilog' => 'VeriLog',
        'vhdl' => 'VHDL',
        'vim' => 'VIM',
        'visualprolog' => 'Visual Pro Log',
        'vb' => 'VisualBasic',
        'visualfoxpro' => 'VisualFoxPro',
        'whitespace' => 'WhiteSpace',
        'whois' => 'WHOIS',
        'winbatch' => 'Winbatch',
        'xbasic' => 'XBasic',
        'xml' => 'XML',
        'xorg_conf' => 'Xorg Config',
        'xpp' => 'XPP',
        'yaml' => 'YAML',
        'z80' => 'Z80 Assembler',
        'zxbasic' => 'ZXBasic',
    );

    return $formats{ $format }
        || $self->_set_error('Invalid syntax highlighting code');
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN RT YpTmWJG  pastebin.com  pastebin.com.  pastebin .com com tradename

=head1 NAME

WWW::Pastebin::PastebinCom::API - implementation of pastebin.com API

=head1 SYNOPSIS

    use WWW::Pastebin::PastebinCom::API;


    ##### Simple paste with all optional args at default values

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    print $bin->paste('Stuff to paste') || die "$bin";


    ##### Private paste with all optional args set

    $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    $bin->paste(
        'Stuff to paste',

        title => 'Title for your paste',
        private => 1,       # set paste as a private paste
        format => 'perl',   # Perl syntax highlighting
        expiry => 'awhile', # expire the paste after 1 week
    ) or die "$bin";

    print "$bin\n";


    ##### Retrieve the content of an existing paste

    $bin = WWW::Pastebin::PastebinCom::API->new;
    print $bin->get_paste('http://pastebin.com/YpTmWJG6')
        || die "$bin";


    ##### Delete one of user's private pastes

    $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    $bin->delete_paste('http://pastebin.com/YpTmWJG6')
        or die "$bin";


    ##### List trending pastes

    $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    my $trends = $bin->list_trends
        or die "$bin";

    use Data::Dumper;
    print Dumper $trends;


    ##### List user's private pastes

    $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    my $pastes = $bin->list_user_pastes
        or die "$bin";

    use Data::Dumper;
    print Dumper $pastes;


    ##### List user's info

    $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    my $info = $bin->get_user_info
        or die "$bin";

    use Data::Dumper;
    print Dumper $info;



=head1 DESCRIPTION

This module is an implementation of the pastebin.com API
(L<http://pastebin.com/api>). The API allows creation of public,
unlisted, and private pastes; deletion of private pastes;
listing of trending pastes and private pastes; and retrieval
of a paste's raw content (the last one is not part of the API, but
is nevertheless implemented in this module).

B<NOTE ON GETTING PASTES:> Despite tons of patently useless stuff
the API provides, it doesn't offer anything but the raw contents
of the paste (not even that, if we're to get technical). If your
main aim is to B<retrieve> pastes and/or retrieve info about
pastes (e.g. expiry date, highlight, etc), then this module will not
help you. See L<WWW::Pastebin::PastebinCom::Retrieve> for that task.

=head1 API KEY NEEDED

The only method that doesn't require an API key is
C<< ->get_paste() >>. To use any other features of this module
you will need to obtain an
API key from pastebin.com. Simply create an account on pastebin.com,
login, then visit (L<http://pastebin.com/api>) and
the key will be listed somewhere in the second section on the page.
The key will look something like this:
C<a3767061e0e64fef6c266126f7e588f4>.

=head1 METHODS

=head2 C<< new >>

    # no API key
    my $bin = WWW::Pastebin::PastebinCom::API->new;

    # API key and setting timeout
    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key =>  'a3767061e0e64fef6c266126f7e588f4',
        user_key => '4fd751dc94f0b62c489b2c7720e0d240',
        timeout => 60,
    );

    # no API key and setting scustom UA
    my $bin = WWW::Pastebin::PastebinCom::API->new(
        ua => LWP::UserAgent->new(
            timeout => $args{timeout},
            agent   => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:21.0)'
                        . ' Gecko/20100101 Firefox/21.0',
        )
    );

Creates and returns a new C<WWW::Pastebin::PastebinCom::API> object.
All arguments are optional and are described below.

=head3 C<api_key>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key =>  'a3767061e0e64fef6c266126f7e588f4',
    );

B<Optional>.
Takes pastebin.com's API key as a string.
By default is not specified.

You don't have to specify the key here and can use the
C<< ->api_key() >> accessor method instead, to set the key prior
to calling module methods.

The only method that doesn't require an API key is
C<< ->get_paste() >>. To use any other features of this module
you will need to obtain an
API key from pastebin.com. Simply create an account on pastebin.com,
login, then visit (L<http://pastebin.com/api>) and
the key will be listed somewhere in the second section on the page.
The key will look something like this:
C<a3767061e0e64fef6c266126f7e588f4>.

=head3 C<user_key>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        user_key => '4fd751dc94f0b62c489b2c7720e0d240',
    );

B<Optional>. Takes a user key string as a value. By default
is not specified.

To create, delete, or list private pastes, you will need a user key.
To obtain one, see C<< ->get_user_key() >> method. Pastebin.com's API
says these keys don't expire, so I would expect that you can
print one user key from C<< ->get_user_key() >>, then simply
reuse the same user key for your C<WWW::Pastebin::PastebinCom::API>
scripts, just as you do with C<api_key>. This would save making a
request to pastebin.com every time you need a user key.

=head3 C<timeout>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        timeout => 60,
    );

B<Optional>. Takes a number that represents seconds.
B<Default:> 30.

Specifies the request timeout whenever making requests to
pastebin.com.

=head3 C<ua>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        ua => LWP::UserAgent->new(
            timeout => 30,
            agent   => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:21.0)'
                        . ' Gecko/20100101 Firefox/21.0',
        )
    );

B<Optional>. Takes an L<LWP::UserAgent>-compatible object. That
object must implement C<< ->post() >> and C<< ->get() >> methods
that return the same stuff L<LWP::UserAgent> returns.
B<By default> uses L<LWP::UserAgent> with C<timeout> set by
C<timeout> constructor argument (see above) and C<agent> set
to Firefox on Linux.

=head2 C<< get_paste >>

    my $bin = WWW::Pastebin::PastebinCom::API->new;
    print $bin->get_paste('http://pastebin.com/YpTmWJG6')
        || die "$bin";

    print $bin->get_paste('YpTmWJG6')
        || die "$bin";

    #### Get a private paste:
    print $bin->get_paste('YpTmWJG6', $USER, $PASS)
        || die "$bin";

Retrieves raw content of an existing paste.
B<Takes> one mandatory and two optional arguments.

The mandatory argument is a string that is either
a URL to the paste you want to retrieve or just the paste ID
(e.g. paste ID in "http://pastebin.com/YpTmWJG6" is "YpTmWJG6").
The two optional arguments must be provided together and they
are the login and the password to the pastebin.com account.
They must be provided when getting private pastes for that
account.

B<On success returns> the raw content of the paste.
B<On failure returns> either C<undef> or an empty list, depending
on the context, and C<< ->error() >> method will contain
human-readable description of the error.

The use of this method doesn't require
you to have an API key with pastebin.com.

=head2 C<< get_user_key >>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

Obtains a user key from pastebin.com. This user key is required for
creating, deleting, and listing private user pastes. The API spec
says this key does not expire, so you should be able to reuse
one key for all your needs (see C<user_key> argument for the
constructor). B<Takes> two mandatory arguments as
strings: first
one is your pastebin.com login, second one is your pastebin.com
password. B<On success> sets C<< ->user_key() >> accessor and
returns a user key (e.g. C<4fd751dc94f0b62c489b2c7720e0d240>).
B<On failure returns> either C<undef> or an empty list, depending
on the context, and C<< ->error() >> method will contain
human-readable description of the error. Note that
if C<< ->get_user_key() >> fails, then
C<< ->user_key() >> will be undefined, even if it was set
to something prior to the call of C<< ->get_user_key() >>

=head2 C<< paste >>

    ##### Simple paste with all optional args at default values

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    print $bin->paste('Stuff to paste') || die "$bin";


    ##### Make an unlisted paste

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    print $bin->paste( 'Stuff to paste', unlisted => 1, )
        || die "$bin";


    ##### Private paste with all optional args set

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    $bin->paste(
        'Stuff to paste',

        title => 'Title for your paste',
        private => 1,       # set paste as a private paste
        format => 'perl',   # Perl syntax highlighting
        expiry => 'awhile', # expire the paste after 1 week
    ) or die "$bin";

    print "$bin\n";

Creates a new paste on pastebin.com.
B<On success> sets C<< ->paste_url() >> accessor method
and returns a URL pointing to the newly-created paste.
B<On failure returns> either C<undef> or an empty list, depending
on the context, and C<< ->error() >> method will contain
human-readable description of the error. Note that on failure,
C<< ->paste_url() >> will be undefined, even if it was set prior
to executing C<< ->paste() >>. B<Takes> one
mandatory argument as a string (paste content) and several optional
arguments as key/value pairs. Possible arguments are as follows:

=head3 First argument

    print $bin->paste('Stuff to paste') || die "$bin";

B<Mandatory>. Specifies the content of the paste.

=head3 C<title>

    $bin->paste(
        'Stuff to paste',
        title => 'Title for your paste',
    ) or die "$bin";

B<Optional>. Specifies the title of the paste. B<By default> is
not specified and the paste will end up being called "Untitled."

=head3 C<expiry>

    $bin->paste(
        'Stuff to paste',
        expiry => 'asap',
    ) or die "$bin";

B<Optional>. Specifies when the paste should expire.
B<By default> is not specified, so the paste will never expire.
B<Takes> a string as an argument. Case-insensitive. Along with
values specified by the API, several other aliases exist. Possible
values are as follows:

=head4 Expire in 10 Minutes

    10m
    m10
    asap

=head4 Expire in 1 Hour

    h
    1h

=head4 Expire in 1 Day

    d
    1d
    soon

=head4 Expire in 1 Week

    w
    1w
    awhile

=head4 Expire in 2 Weeks

    2w
    w2

=head4 Expire in 1 Month

    1m
    m1
    eventually

=head4 Never expire

    n
    never

=head3 C<format>

    $bin->paste(
        'Stuff to paste',
        format => 'perl',
    ) or die "$bin";

B<Optional.> Specifies syntax highlighting language. B<Takes>
a string as a value, which specifies the language to use. Possible
values are (on the left is the value you'd use for C<format>
and on the right is the explanation of what language it is):

                 4cs   # 4CS
            6502acme   # 6502 ACME Cross Assembler
         6502kickass   # 6502 Kick Assembler
            6502tasm   # 6502 TASM/64TASS
         68000devpac   # Motorola 68000 HiSoft Dev
                abap   # ABAP
        actionscript   # ActionScript
       actionscript3   # ActionScript 3
                 ada   # Ada
             algol68   # ALGOL 68
              apache   # Apache Log
         applescript   # AppleScript
         apt_sources   # APT Sources
                 arm   # ARM
                 asm   # ASM (NASM)
                 asp   # ASP
           asymptote   # Asymptote
            autoconf   # autoconf
          autohotkey   # Autohotkey
              autoit   # AutoIt
            avisynth   # Avisynth
                 awk   # Awk
           bascomavr   # BASCOM AVR
                bash   # Bash
            basic4gl   # Basic4GL
                  bf   # BrainFuck
              bibtex   # BibTeX
          blitzbasic   # Blitz Basic
                 bnf   # BNF
                 boo   # BOO
                   c   # C
        c_loadrunner   # C: Loadrunner
               c_mac   # C for Macs
              caddcl   # CAD DCL
             cadlisp   # CAD Lisp
                cfdg   # CFDG
                 cfm   # ColdFusion
          chaiscript   # ChaiScript
                 cil   # C Intermediate Language
             clojure   # Clojure
               cmake   # CMake
               cobol   # COBOL
        coffeescript   # CoffeeScript
                 cpp   # C++
              cpp-qt   # C++ (with QT extensions)
              csharp   # C#
                 css   # CSS
            cuesheet   # Cuesheet
                   d   # D
                 dcl   # DCL
              dcpu16   # DCPU-16
                 dcs   # DCS
              delphi   # Delphi
                diff   # Diff
                 div   # DIV
                 dos   # DOS
                 dot   # DOT
                   e   # E
          ecmascript   # ECMAScript
              eiffel   # Eiffel
               email   # Email
                 epc   # EPC
              erlang   # Erlang
                  f1   # Formula One
              falcon   # Falcon
                  fo   # FO Language
             fortran   # Fortran
           freebasic   # FreeBasic
          freeswitch   # FreeSWITCH
              fsharp   # F#
              gambas   # GAMBAS
                 gdb   # GDB
              genero   # Genero
               genie   # Genie
             gettext   # GetText
                glsl   # OpenGL Shading
                 gml   # Game Maker
             gnuplot   # Ruby Gnuplot
                  go   # Go
              groovy   # Groovy
             gwbasic   # GwBasic
             haskell   # Haskell
                haxe   # Haxe
              hicest   # HicEst
             hq9plus   # HQ9 Plus
         html4strict   # HTML
               html5   # HTML 5
                icon   # Icon
                 idl   # IDL
                 ini   # INI file
                inno   # Inno Script
            intercal   # INTERCAL
                  io   # IO
                   j   # J
                java   # Java
               java5   # Java 5
          javascript   # JavaScript
              jquery   # jQuery
             kixtart   # KiXtart
              klonec   # Clone C
            klonecpp   # Clone C++
               latex   # Latex
                  lb   # Liberty BASIC
                ldif   # LDIF
                lisp   # Lisp
                llvm   # LLVM
           locobasic   # Loco Basic
             logtalk   # Logtalk
             lolcode   # LOL Code
       lotusformulas   # Lotus Formulas
         lotusscript   # Lotus Script
             lscript   # LScript
                lsl2   # Linden Scripting
                 lua   # Lua
                m68k   # M68000 Assembler
             magiksf   # MagikSF
                make   # Make
            mapbasic   # MapBasic
              matlab   # MatLab
                mirc   # mIRC
                mmix   # MIX Assembler
             modula2   # Modula 2
             modula3   # Modula 3
               mpasm   # MPASM
                mxml   # MXML
               mysql   # MySQL
              nagios   # Nagios
             newlisp   # newLISP
                nsis   # NullSoft Installer
             oberon2   # Oberon 2
                objc   # Objective C
              objeck   # Objeck Programming Langua
               ocaml   # OCaml
         ocaml-brief   # OCalm Brief
              octave   # Octave
               oobas   # Openoffice BASIC
            oracle11   # Oracle 11
             oracle8   # Oracle 8
             oxygene   # Delphi Prism (Oxygene)
                  oz   # Oz
            parasail   # ParaSail
              parigp   # PARI/GP
              pascal   # Pascal
                pawn   # PAWN
                pcre   # PCRE
                 per   # Per
                perl   # Perl
               perl6   # Perl 6
                  pf   # OpenBSD PACKET FILTER
                 php   # PHP
           php-brief   # PHP Brief
               pic16   # Pic 16
                pike   # Pike
         pixelbender   # Pixel Bender
               plsql   # PL/SQL
          postgresql   # PostgreSQL
              povray   # POV-Ray
        powerbuilder   # PowerBuilder
          powershell   # Power Shell
             proftpd   # ProFTPd
            progress   # Progress
              prolog   # Prolog
          properties   # Properties
            providex   # ProvideX
           purebasic   # PureBasic
               pycon   # PyCon
               pys60   # Python for S60
              python   # Python
                   q   # q/kdb+
              qbasic   # QBasic
               rails   # Rails
               rebol   # REBOL
                 reg   # REG
                rexx   # Rexx
              robots   # Robots
             rpmspec   # RPM Spec
              rsplus   # R
                ruby   # Ruby
                 sas   # SAS
               scala   # Scala
              scheme   # Scheme
              scilab   # Scilab
            sdlbasic   # SdlBasic
           smalltalk   # Smalltalk
              smarty   # Smarty
               spark   # SPARK
              sparql   # SPARQL
                 sql   # SQL
         stonescript   # StoneScript
       systemverilog   # SystemVerilog
                 tcl   # TCL
            teraterm   # Tera Term
                text   # None
           thinbasic   # thinBasic
                tsql   # T-SQL
          typoscript   # TypoScript
              unicon   # Unicon
                 ups   # UPC
                urbi   # Urbi
             uscript   # UnrealScript
                vala   # Vala
                  vb   # VisualBasic
               vbnet   # VB.NET
               vedit   # Vedit
             verilog   # VeriLog
                vhdl   # VHDL
                 vim   # VIM
        visualfoxpro   # VisualFoxPro
        visualprolog   # Visual Pro Log
          whitespace   # WhiteSpace
               whois   # WHOIS
            winbatch   # Winbatch
              xbasic   # XBasic
                 xml   # XML
           xorg_conf   # Xorg Config
                 xpp   # XPP
                yaml   # YAML
                 z80   # Z80 Assembler
             zxbasic   # ZXBasic

=head3 C<unlisted>

    print $bin->paste( 'Stuff to paste', unlisted => 1, )
        || die "$bin";

B<Optional.> B<Takes> a true or false value. B<When set to>
a true value, will cause the paste to be unlisted.
When used in conjunction with C<private> option (see below)
the behaviour is undefined. B<By default> neither
C<unlisted> nor C<private> are specified and the created
paste is public and listed.

I<Note:> Pastebin will automatically list duplicate content
or content with some keywords as unlisted,
even if we tell it to go public. It's not a bug in the module.

=head3 C<owned>

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    print $bin->paste( 'Stuff to paste', owned => 1, )
        || die "$bin";

B<Optional.> B<Takes> a true or false value.
B<When set to>
a true value, will cause the paste you create to be labeled as
pasted by you instead of C<Guest>.
B<By default> is set to false and pastes will be labeled
as created by C<Guest>.

When creating an "owned"
paste, C<< ->user_key() >>
accessor method must contain a user key for the user who will own
this paste. You can either set it directly using C<< ->user_key() >>,
set it in the constructor using C<user_key> argument, or set it
indirectly by calling C<< ->get_user_key() >> method.

=head3 C<private>

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    print $bin->paste( 'Stuff to paste', private => 1, )
        || die "$bin";

B<Optional.> B<Takes> a true or false value.
B<When set to>
a true value, will cause the paste to be private (viewable only
when the user is logged in).
When used in conjunction with C<unlisted> option (see above)
the behaviour is undefined. B<By default> neither
C<unlisted> nor C<private> are specified and the created
paste is public and listed.

When creating a private or "owned"
paste, C<< ->user_key() >>
accessor method must contain a user key for the user who will own
this paste. You can either set it directly using C<< ->user_key() >>,
set it in the constructor using C<user_key> argument, or set it
indirectly by calling C<< ->get_user_key() >> method.

=head2 C<delete_paste>

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    $bin->delete_paste('http://pastebin.com/YpTmWJG6')
        or die "$bin";

    #### or
    $bin->delete_paste('YpTmWJG6')
        or die "$bin";

Deletes user's private paste (see C<private> argument
to C<< ->paste() >>). B<Takes> one mandatory argument as a string
containing either the full URL to the paste to be deleted
or just the paste ID (e.g. C<YpTmWJG6> is paste ID for
C<http://pastebin.com/YpTmWJG6>).

The C<< ->user_key() >>
accessor method must contain a user key for the user who owns
this paste. You can either set it directly using C<< ->user_key() >>,
set it in the constructor using C<user_key> argument, or set it
indirectly by calling C<< ->get_user_key() >> method.

=head2 C<list_user_pastes>

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    my $pastes = $bin->list_user_pastes(10) # get at most 10 pastes
        or die "$bin";

    use Data::Dumper;
    print Dumper $pastes;

Lists user's private pastes. Prior to calling C<< ->list_user_pastes() >>
C<< ->user_key() >> must be set, either
by calling C<< ->get_user_key() >>, using C<< ->user_key() >>
accessor method, or C<user_key> constructor argument.
B<Takes> one optional argument as a
positive integer between 1 and 1000, which specifies the
maximum number of pastes to retrieve. B<By default> will get
at most 50 pastes. B<On failure> returns either
C<undef> or an empty list, depending on the context, and the
C<< ->error() >> accessor method will contain human-readable
error message. B<On success> returns a — possibly empty — arrayref
or a list (depending on context) of hashrefs, where each hashref
represents information about a single paste. The format
of the hashref is this:

    {
        'key'           => 'zrke2Q9R',
        'url'           => 'http://pastebin.com/zrke2Q9R',
        'title'         => 'Title for your paste'
        'date'          => '1382901396',
        'expire_date'   => '1383506196',
        'format_short'  => 'perl',
        'format_long'   => 'Perl',
        'private'       => 1,
        'size'          => '14',
        'hits'          => '0',
    }

The API is not descriptive on what values these keys might have,
so what you have below is only my interpretation:

=head3 C<key>

        'key' => 'zrke2Q9R',

String of text. The paste ID of the paste. You can pass it to
C<< ->delete_paste() >> method to delete the paste.

=head3 C<url>

        'url' => 'http://pastebin.com/zrke2Q9R',

String of text. The URL of the paste.

=head3 C<title>

        'title' => 'Title for your paste'

String of text. The title of the paste.

=head3 C<date>

        'date' => '1382901396',

Unix time format. The date when the paste was created.

=head3 C<expire_date>

        'expire_date' => '1383506196',

Unix time format. The date when the paste will expire.

=head3 C<format_short>

        'format_short' => 'perl',

Syntax highlighting for the paste. See the left column in the
C<format> argument for the C<< ->paste() >> method.

=head3 C<format_long>

        'format_long' => 'Perl',

Explanation of the code for the syntax highlighting for the paste.
See the right column in the C<format> argument for
the C<< ->paste() >> method.

=head3 C<private>

        'private' => 1,

True value, if exists. An indication that it's a private paste.

=head3 C<unlisted>

        'unlisted' => 1,

True value, if exists. An indication that it's an unlisted paste.

=head3 C<size>

        'size' => '14',

Positive integer. The size of the paste, presumably the number
of characters.

=head3 C<hits>

        'hits' => '0',

Positive integer or zero. The number of times the paste was viewed.

=head2 C<list_trends>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    my $trends = $bin->list_trends
        or die "$bin";

    use Data::Dumper;
    print Dumper $trends;

Lists 18 trending pastes. B<Takes> no arguments.
B<On failure> returns either
C<undef> or an empty list, depending on the context, and the
C<< ->error() >> accessor method will contain human-readable
error message. B<On success> returns an arrayref
or a list (depending on context) of hashrefs, where each hashref
represents information about a single paste. The format
of the hashref is the same as for hashrefs returned by the
C<< ->list_user_pastes() >> method (see above), except that
that C<private>, C<format_short>, and C<format_long> keys
will not be there.

=head2 C<get_user_info>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    my $info = $bin->get_user_info
        or die "$bin";

    use Data::Dumper;
    print Dumper $info;

List user's account info. Prior to calling C<< ->get_user_info() >>
C<< ->user_key() >> must be set, either
by calling C<< ->get_user_key() >>, using C<< ->user_key() >>
accessor method, or C<user_key> constructor argument. B<Takes>
no arguments. B<On failure> returns either
C<undef> or an empty list, depending on the context, and the
C<< ->error() >> accessor method will contain human-readable
error message. B<On success> either a hashref or a key/value list,
depending on the context. The format of the hashref is this:

    {
        'name' => 'zoffixisawesome',
        'website' => 'http://zoffix.com',
        'location' => 'Toronto',
        'format_short' => 'perl',
        'avatar_url' => 'http://pastebin.com/i/guest.gif',
        'private' => '1',  # also possible for this to be unlisted => 1 instead
        'email' => 'cpan@zoffix.com',
        'expiration' => 'N',
        'account_type' => '0'
    }

The API is not too descriptive about
the values of the user info, so what follows is my interpretation:

=head3 C<name>

    'name' => 'zoffixisawesome',

A string of text. User's login.

=head3 C<email>

    'email' => 'cpan@zoffix.com',

A string of text. User's email address.

=head3 C<website>

    'website' => 'http://zoffix.com',

A string of text. The website the user specified in their profile.

=head3 C<location>

    'location' => 'Toronto',

A string of text. User's location (specified by the user manually
by them in their profile).

=head3 C<format_short>

    'format_short' => 'perl',

This is the code for user's default syntax highlighting. See the left
column in the C<format> argument to C<< ->paste() >> method.

=head3 C<avatar_url>

    'avatar_url' => 'http://pastebin.com/i/guest.gif',

A string of text. The URL to the user's avatar picture.

=head3 C<private> or C<unlisted>

    'private' => '1',

    'unlisted' => '1',

True value, if exist. If C<private> key is present, user's default
paste setting is to make the paste private. If C<unlisted> key is
present, user's default paste setting is to make the paste unlisted.

=head3 C<expiration>

    'expiration' => 'N',

User's default expiry setting for their pastes. The values
you can possibly get here are these:

    N = Never
    10M = 10 Minutes
    1H = 1 Hour
    1D = 1 Day
    1W = 1 Week
    2W = 2 Weeks
    1M = 1 Month

=head3 C<account_type>

    'account_type' => '0',

0 or 1 as a value. Indicates user's account type. 0 means it's a normal;
1 means PRO.

=head1 ACCESSOR METHODS

=head2 C<error>

    $bin->paste('Stuff') or die $bin->error;

    ### or

    $bin->paste('Stuff') or die "$bin";

B<Takes> no arguments. Returns the human-readable error message if
the last method failed.
This method is overloaded so you can call it by interpolating
the object in a string. The only difference is when interpolating,
the error message will be preceded with the word C<Error:>. Note
that C<< ->paste_url() >> is also overloaded and the module will
interpolate the value of instead
C<< ->paste_url() >> if no error is set.

=head2 C<paste_url>

    $bin->paste('Stuff') or die "$bin";
    print $bin->paste_url;

    ### or

    $bin->paste('Stuff') or die "$bin";
    print "$bin"

B<Takes> no arguments. Returns the URL of the newly-created paste after
a successful call to C<< ->paste() >> method.
This method is overloaded so you can call it by interpolating
the object in a string. Note
that C<< ->error() >> is also overloaded and the module will
interpolate the value of C<< ->error() >> instead, if an error is set.

=head2 C<api_key>

    my $bin = WWW::Pastebin::PastebinCom::API->new;

    $bin->api_key('a3767061e0e64fef6c266126f7e588f4');
    printf "Current API key is %s\n", $bin->api_key;

B<Takes> one optional argument as a string, which is a pastebin.com's
API key to be used by the module. B<Returns> the currently used
API key, as a string.

=head2 C<user_key>

    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => 'a3767061e0e64fef6c266126f7e588f4',
    );

    $bin->get_user_key(qw/
        your_pastebin.com_login
        your_pastebin.com_password
    /) or die "$bin";

    printf "Current user key is %s\n", $bin->user_key;

B<Takes> one optional argument as a string, which is a
user key to be used by the module. B<Returns> the currently used
user key, as a string. See C<< ->get_user_key() >> for details
on what a user key is.

=head1 OVERLOADS

    $bin->paste('Stuff') or die "$bin";
    print "$bin";

The C<< ->error() >> and C<< ->paste_url() >> methods are overloaded
so you can call them by interpolating the object in a string.
If C<< ->error() >> contains an error message it will be called
when the object is interpolated, otherwise C<< ->paste_url() >> will
be called. There's a slight difference between calling
C<< ->error() >> directly or through interpolation: when interpolated,
word C<Error: > is added to the error message.

=head1 EXAMPLES

The C<examples/> directory of this distribution contains two example
scripts: one for pasting a file and another for retrieving a paste.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/WWW-Pastebin-PastebinCom-API>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/WWW-Pastebin-PastebinCom-API/issues>

If you can't access GitHub, you can email your request
to C<bug-www-pastebin-pastebincom-api at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet C<zoffix at cpan.org>, (L<http://zoffix.com/>)

=head1 CONTRIBUTORS

Philipp Hamer, L<https://github.com/ponzellus>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
