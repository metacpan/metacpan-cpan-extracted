package WWW::Pastebin::PastebinCom::Create;

use Moo;
use WWW::Mechanize;
our $VERSION = '1.003';

use overload q{""} => sub { return shift->paste_uri };

has error => ( is => 'rw', build_arg => undef, );
has paste_uri => ( is => 'rw', build_arg => undef, );
has _mech => (
    is => 'ro',
    build_arg => undef,
    default => sub {
        my $mech = WWW::Mechanize->new(
            timeout     => 30,
            autocheck   => 0,
        );
        $mech->agent_alias('Linux Mozilla');
        return $mech;
    },
);

sub paste {
    my ( $self, %args ) = @_;

    $self->paste_uri(undef);
    $self->error(undef);

    %args = __process_args( %args );
    defined $args{text}
        and length $args{text}
            or return $self->_set_error('Paste text is empty');

    my $mech = $self->_mech;
    $mech->get('http://pastebin.com');
    $mech->success or return $self->_set_mech_error;

    $mech->form_name('myform')
        or return $self->_set_error('Paste form not found');

    $mech->set_fields(
        paste_code          => $args{text},
        paste_format        => $args{format},
        paste_expire_date   => $args{expiry},
        paste_private       => $args{private},
        paste_name          => $args{desc},
    );
    $mech->submit;
    $mech->success or return $self->_set_mech_error;

    my $uri = '' . $mech->uri;
    $uri =~ m{/index\.php}
        and return $self->_set_error(q{Didn't get a valid paste URI});

    $uri =~ m{/warning\.php}
        and return $self->_set_error(q{Reached the paste limit. See } .
            $uri . q{ for details.}
        );

    return $self->paste_uri( $uri );
}

sub __process_args {
    my %args = @_;

    $args{+lc} = delete $args{$_} for keys %args;

    $args{desc} = substr($args{desc}, 0, 57) . '...'
        if defined $args{desc}
            and length $args{desc} > 60;

    my $valid_formats = __get_valid_formats();
    $args{format} = $valid_formats->{ lc($args{format} || '') };
    $args{format} = $valid_formats->{none}
        unless defined $args{format};

    my $valid_expiry = __get_valid_expiry();
    $args{expiry} = $valid_expiry->{ lc($args{expiry} || '') };
    $args{expiry} = $valid_expiry->{m}
        unless defined $args{expiry};

    $args{private} = 1
        unless defined $args{private}
            and $args{private} eq '0';

    return %args;
}

sub _set_mech_error {
    my ( $self, $mech ) = @_;
    $self->error(
        'Network error: ' . $mech->res->code . ' ' . $mech->res->status_line
    );
    return;
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub __get_valid_expiry {
    return {
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
        m       => '1M',
        m1      => '1M',
        eventually      => '1M',

        # Never
        n       => 'N',
        never   => 'N',
    };
}

sub __get_valid_formats {
    my %formats = (
                   'None' => '1',
                   'Bash' => '8',
                      'C' => '9',
                     'C#' => '14',
                    'C++' => '13',
                    'CSS' => '16',
                   'HTML' => '25',
                 'HTML 5' => '196',
                   'Java' => '27',
             'JavaScript' => '28',
                    'Lua' => '30',
                   'None' => '1',
            'Objective C' => '35',
                   'Perl' => '40',
                    'PHP' => '41',
                 'Python' => '42',
                  'Rails' => '67',
                    '4CS' => '142',
'6502 ACME Cross Assembler' => '143',
    '6502 Kick Assembler' => '144',
       '6502 TASM/64TASS' => '145',
                   'ABAP' => '73',
           'ActionScript' => '2',
         'ActionScript 3' => '74',
                    'Ada' => '3',
               'ALGOL 68' => '147',
             'Apache Log' => '4',
            'AppleScript' => '5',
            'APT Sources' => '75',
                    'ARM' => '217',
             'ASM (NASM)' => '6',
                    'ASP' => '7',
              'Asymptote' => '218',
               'autoconf' => '148',
             'Autohotkey' => '149',
                 'AutoIt' => '54',
               'Avisynth' => '76',
                    'Awk' => '150',
             'BASCOM AVR' => '198',
                   'Bash' => '8',
               'Basic4GL' => '77',
                 'BibTeX' => '78',
            'Blitz Basic' => '55',
                    'BNF' => '56',
                    'BOO' => '80',
              'BrainFuck' => '79',
                      'C' => '9',
             'C for Macs' => '10',
'C Intermediate Language' => '82',
                     'C#' => '14',
                    'C++' => '13',
'C++ (with QT extensions)' => '154',
          'C: Loadrunner' => '199',
                'CAD DCL' => '11',
               'CAD Lisp' => '12',
                   'CFDG' => '81',
             'ChaiScript' => '152',
                'Clojure' => '153',
                'Clone C' => '99',
              'Clone C++' => '100',
                  'CMake' => '83',
                  'COBOL' => '84',
           'CoffeeScript' => '200',
             'ColdFusion' => '15',
                    'CSS' => '16',
               'Cuesheet' => '151',
                      'D' => '17',
                    'DCL' => '219',
                'DCPU-16' => '220',
                    'DCS' => '85',
                 'Delphi' => '18',
 'Delphi Prism (Oxygene)' => '177',
                   'Diff' => '19',
                    'DIV' => '86',
                    'DOS' => '20',
                    'DOT' => '87',
                      'E' => '155',
             'ECMAScript' => '156',
                 'Eiffel' => '21',
                  'Email' => '88',
                    'EPC' => '201',
                 'Erlang' => '57',
                     'F#' => '158',
                 'Falcon' => '202',
            'FO Language' => '89',
            'Formula One' => '157',
                'Fortran' => '22',
              'FreeBasic' => '23',
             'FreeSWITCH' => '206',
                 'GAMBAS' => '159',
             'Game Maker' => '24',
                    'GDB' => '160',
                 'Genero' => '58',
                  'Genie' => '161',
                'GetText' => '90',
                     'Go' => '162',
                 'Groovy' => '59',
                'GwBasic' => '163',
                'Haskell' => '60',
                   'Haxe' => '221',
                 'HicEst' => '164',
               'HQ9 Plus' => '93',
                   'HTML' => '25',
                 'HTML 5' => '196',
                   'Icon' => '165',
                    'IDL' => '94',
               'INI file' => '26',
            'Inno Script' => '61',
               'INTERCAL' => '95',
                     'IO' => '96',
                      'J' => '166',
                   'Java' => '27',
                 'Java 5' => '97',
             'JavaScript' => '28',
                 'jQuery' => '167',
    );

    $formats{+lc} = delete $formats{$_} for keys %formats;

    return \%formats;
}

q|
Q: Whats the object-oriented way to become wealthy?

A: Inheritance
|;

__END__

=encoding utf8

=head1 NAME

WWW::Pastebin::PastebinCom::Create - paste on www.pastebin.com without API keys

=head1 WARNING!!!

B<IMPORANT. Please read.>

You kinda, sorta, maybe shouldn't really use this module. Use
L<WWW::Pastebin::PastebinCom::API> instead. Pastebin.com switched to a
key-based API (which is what C<::API> version implements),
and using this, keyless, module lets you paste only 10 pastes per day.

The limit is higher with the L<WWW::Pastebin::PastebinCom::API>
module, so check it out.

This module primarily exists for use with L<App::Nopaste>.

=head1 SYNOPSIS

    use WWW::Pastebin::PastebinCom::Create;

    my $bin = WWW::Pastebin::PastebinCom::Create->new;

    # all options as defaults
    my $paste_uri = $bin->paste( text => 'Some text to paste' )
        or die $bin->error;

    # all options as custom (module's defaults are shown)
    my $paste_uri = $bin->paste(
        text    => 'Some text to paste',
        format  => 'none', # no syntax highlights
        expiry  => 'm',    # expire after a month
        private => 1,      # make the paste unlisted
        desc    => '',     # no "title/name" for the paste
    ) or die $bin->error;

    # object's ->paste_uri() method is overloaded to string interpolation:
    print "Your paste uri is $bin\n";

=head1 DESCRIPTION

This module provides the means to paste on L<www.pastebin.com> pastebin,
without the need for L<API keys|http://pastebin.com/api>. See
the WARNING!!! section above.

=head1 METHODS

=head2 C<new>

    my $bin = WWW::Pastebin::PastebinCom::Create->new;

Creates and returns a brand new L<WWW::Pastebin::PastebinCom::Create>
object. Does not take any arguments.

=head2 C<paste>

    my $paste_uri = $bin->paste( text => 'Some text to paste' )
        or die $bin->error;

    $bin->paste(
        text    => 'Some text to paste',
        format  => 'perl', # perl syntax highlights
        expiry  => 'asap', # expire in 10 minutes
        private => 1,      # make the paste unlisted
        desc    => 'Some title',  # "title/name" for the paste
    ) or die $bin->error;

Pastes to the pastebin. B<On succcess> returns the link to the newly-created
paste (see also the overloaded C<< ->paste_uri >> method below).
B<On failure> returns C<undef> or an empty list, depending
on the context, and the human-readable error message will be available
via the C<< ->error >> method. B<Takes> arguments as key/value pairs.
Argument C<text> is mandatory, the rest are optional. Possible arguments
are as follows:

=head3 C<text>

    $bin->paste(
        text    => 'Some text to paste',
    ) or die $bin->error;

B<Mandatory>. Takes a string as a value that contains the text to paste.

=head3 C<private>

    $bin->paste(
        text    => 'Some text to paste',
        private => 1,      # make the paste unlisted
    ) or die $bin->error;

B<Optional>. This really should be named C<unlisted>, but for compatibility
with old code is still named C<private>.
B<Takes> true or value as a value. If set to a true value,
the paste will be C<unlisted> (i.e. people will be able to access
them if they have a link, but the paste will not be announced on the
pastebin.com home page), otherwise the paste will be public and listed on
the home page. To make private pastes, you need to be logged in;
use L<WWW::Pastebin::PastebinCom::API> if you need that feature.
B<Defaults to:> C<1> (make pastes unlisted).

=head3 C<desc>

    $bin->paste(
        text    => 'Some text to paste',
        desc    => '',     # no "title/name" for the paste
    ) or die $bin->error;

B<Optional>. B<Takes> a string as a value that specifies the
title/name for the paste. If this string is longer than 60 characters,
it will be truncated and C<...> will be appended to the end of it.
B<By default> is not specified.

=head3 C<expiry>

    $bin->paste(
        text    => 'Some text to paste',
        expiry  => 'm',    # expire after a month
    ) or die $bin->error;

B<Optional>. B<Takes> an expiry code as a value that specifies when the
paste should expire. B<Defaults to:> C<m> (expire after a month). Valid
expiry codes are as follows (there are multiple possible codes
for each duration; they are equivalent):

    # Expire after 10 Minutes
    10m
    m10
    asap

    # Expire after 1 Hour
    h
    1h

    # Expire after 1 Day
    d
    1d
    soon

    # Expire after 1 Week
    w
    1w
    awhile

    # Expire after 2 weeks
    2w
    w2

    # Expire after 1 Month
    1m
    m
    m1
    eventually

    # Never expire
    n
    never

=head3 C<format>

    $bin->paste(
        text    => 'Some text to paste',
        format  => 'C++ (with QT extensions)',
    ) or die $bin->error;

B<Optional>. B<Takes> a format code as a value that specifies the
paste text format (what syntax highlights to use). B<Defaults to:>
C<none> (no syntax highlights). Possible values are as follows;
they are case-insensitive:

    None
    Bash
    C
    C#
    C++
    CSS
    HTML
    HTML 5
    Java
    JavaScript
    Lua
    None
    Objective C
    Perl
    PHP
    Python
    Rails
    4CS
    6502 ACME Cross Assembler
    6502 Kick Assembler
    6502 TASM/64TASS
    ABAP
    ActionScript
    ActionScript 3
    Ada
    ALGOL 68
    Apache Log
    AppleScript
    APT Sources
    ARM
    ASM (NASM)
    ASP
    Asymptote
    autoconf
    Autohotkey
    AutoIt
    Avisynth
    Awk
    BASCOM AVR
    Bash
    Basic4GL
    BibTeX
    Blitz Basic
    BNF
    BOO
    BrainFuck
    C
    C for Macs
    C Intermediate Language
    C#
    C++
    C++ (with QT extensions)
    C: Loadrunner
    CAD DCL
    CAD Lisp
    CFDG
    ChaiScript
    Clojure
    Clone C
    Clone C++
    CMake
    COBOL
    CoffeeScript
    ColdFusion
    CSS
    Cuesheet
    D
    DCL
    DCPU-16
    DCS
    Delphi
    Delphi Prism (Oxygene)
    Diff
    DIV
    DOS
    DOT
    E
    ECMAScript
    Eiffel
    Email
    EPC
    Erlang
    F#
    Falcon
    FO Language
    Formula One
    Fortran
    FreeBasic
    FreeSWITCH
    GAMBAS
    Game Maker
    GDB
    Genero
    Genie
    GetText
    Go
    Groovy
    GwBasic
    Haskell
    Haxe
    HicEst
    HQ9 Plus
    HTML
    HTML 5
    Icon
    IDL
    INI file
    Inno Script
    INTERCAL
    IO
    J
    Java
    Java 5
    JavaScript
    jQuery

=head2 C<error>

    $bin->paste( text => 'Some text to paste' )
        or die $bin->error;

If an error occurs during pasting, the C<< ->paste >> method will return
an C<undef> or an empty list, depending on the context, and the
human-readable error message will be available via the C<< ->error >>
method.

=head2 C<paste_uri>

    $bin->paste( text => 'Some text to paste' )
        or die $bin->error;

    print "Your paste is at " . $bin->paste_uri . "\n";
    print "Your paste is at $bin\n";

B<Takes> no arguments. Will return
the link to the newly-created paste, after a successful call to
C<< ->paste >>. This method is overloaded for string interpolation,
meaning you can simply interpolate the C<WWW::Pastebin::PastebinCom::Create>
object in a string to insert the link to the paste.

=head1 NOTE ON VERSION 0.004 AND EARLIER

At version 0.004, this module was taken out the back and shot in the face,
as the www.pastebin.com update completely broke it. As some code
still relied on it, it was resurrected and forced to work, but
large bits of module's API have changed. If for whatever reason you
need the old, B<non-working>, implementation, you
can still access it on backpan and can install it using:

    cpan http://backpan.perl.org/authors/id/Z/ZO/ZOFFIX/WWW-Pastebin-PastebinCom-Create-0.004.tar.gz

=head1 SEE ALSO

L<WWW::Pastebin::PastebinCom::API>, L<App::Nopaste>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-pastebincom-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-PastebinCom-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::PastebinCom::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-PastebinCom-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-PastebinCom-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-PastebinCom-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-PastebinCom-Create/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Zoffix Znet.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

