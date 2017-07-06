package WWW::Google::PageSpeedOnline::Params;

$WWW::Google::PageSpeedOnline::Params::VERSION   = '0.24';
$WWW::Google::PageSpeedOnline::Params::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::PageSpeedOnline::Params - Placeholder for parameters for L<WWW::Google::PageSpeedOnline>.

=head1 VERSION

Version 0.24

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(validate $FIELDS);

my $STRATEGIES = { desktop => 1, mobile => 1 };

my $RULES = {
    'AVOIDCSSIMPORT'                        => 1, 'INLINESMALLJAVASCRIPT'  => 1, 'SPECIFYCHARSETEARLY'                => 1,
    'SPECIFYACACHEVALIDATOR'                => 1, 'SPECIFYIMAGEDIMENSIONS' => 1, 'MAKELANDINGPAGEREDIRECTSCACHEABLE'  => 1,
    'MINIMIZEREQUESTSIZE'                   => 1, 'PREFERASYNCRESOURCES'   => 1, 'MINIFYCSS'                          => 1,
    'SERVERESOURCESFROMACONSISTENTURL'      => 1, 'MINIFYHTML'             => 1, 'OPTIMIZETHEORDEROFSTYLESANDSCRIPTS' => 1,
    'PUTCSSINTHEDOCUMENTHEAD'               => 1, 'MINIMIZEREDIRECTS'      => 1, 'INLINESMALLCSS'                     => 1,
    'MINIFYJAVASCRIPT'                      => 1, 'DEFERPARSINGJAVASCRIPT' => 1, 'SPECIFYAVARYACCEPTENCODINGHEADER'   => 1,
    'LEVERAGEBROWSERCACHING'                => 1, 'OPTIMIZEIMAGES'         => 1, 'SPRITEIMAGES'                       => 1,
    'REMOVEQUERYSTRINGSFROMSTATICRESOURCES' => 1, 'SERVESCALEDIMAGES'      => 1, 'AVOIDBADREQUESTS'                   => 1,
    'USEANAPPLICATIONCACHE'                 => 1,
};

my $LOCALES = {
    'ar'    => 'Arabic',                'bg'    => 'Bulgarian', 'ca'    => 'Catalan',    'zh_TW' => 'Traditional Chinese (Taiwan)',
    'zh_CN' => 'Simplified Chinese',    'fr'    => 'Croatian',  'cs'    => 'Czech',      'da'    => 'Danish',
    'nl'    => 'Dutch',                 'en_US' => 'English',   'en_GB' => 'English UK', 'fil'   => 'Filipino',
    'fi'    => 'Finnish',               'fr'    => 'French',    'de'    => 'German',     'el'    => 'Greek',
    'lw'    => 'Hebrew',                'hi'    => 'Hindi',     'hu'    => 'Hungarian',  'id'    => 'Indonesian',
    'it'    => 'Italian',               'ja'    => 'Japanese',  'ko'    => 'Korean',     'lv'    => 'Latvian',
    'lt'    => 'Lithuanian',            'no'    => 'Norwegian', 'pl'    => 'Polish',     'pr_BR' => 'Portuguese (Brazilian)',
    'pt_PT' => 'Portuguese (Portugal)', 'ro'    => 'Romanian',  'ru'    => 'Russian',    'sr'    => 'Serbian',
    'sk'    => 'Slovakian',             'sl'    => 'Slovenian', 'es'    => 'Spanish',    'sv'    => 'Swedish',
    'th'    => 'Thai',                  'tr'    => 'Turkish',   'uk'    => 'Ukrainian',  'vi'    => 'Vietnamese',
};

sub check_strategy {
    my ($str) = @_;

    die "ERROR: Invalid data type 'strategy' found [$str]"
        unless exists $STRATEGIES->{lc($str)};
}

sub check_locale {
    my ($str) = @_;

    die "ERROR: Invalid data type 'locale' found [$str]"
        unless exists $LOCALES->{$str};
}

sub check_url {
    my ($str) = @_;

    die "ERROR: Invalid data type 'url' [$str]" unless (defined $str && $str =~ /^(http(?:s)?\:\/\/[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,6}(?:\/?|(?:\/[\w\-]+)*)(?:\/?|\/\w+\.[a-zA-Z]{2,4}(?:\?[\w]+\=[\w\-]+)?)?(?:\&[\w]+\=[\w\-]+)*)$/);
};

sub check_rule {
    my ($rules) = @_;

    return unless defined $rules;
    die "ERROR: 'Rules' should be passed in as arrayref" unless (ref($rules) eq 'ARRAY');

    foreach my $rule (@$rules) {
        die "ERROR: Invalid 'rule' found [$rule]" unless (exists $RULES->{uc($rule)});
    }
}

our $FIELDS = {
    'strategy' => { check => sub { check_strategy(@_) }, type => 's' },
    'locale'   => { check => sub { check_locale(@_)   }, type => 's' },
    'url'      => { check => sub { check_url(@_)      }, type => 's' },
    'rule'     => { check => sub { check_rule(@_)     }, type => 's' },
};

sub validate {
    my ($fields, $params) = @_;

    die "ERROR: Missing params list." unless (defined $params);

    die "ERROR: Parameters have to be hash ref" unless (ref($params) eq 'HASH');

    foreach my $key (keys %{$params}) {
        die "ERROR: Received invalid param: $key"
            unless (exists $FIELDS->{$key});
    }

    foreach my $key (keys %{$fields}) {
        die "ERROR: Received invalid param: $key"
            unless (exists $FIELDS->{$key});

        die "ERROR: Missing mandatory param: $key"
            if ($fields->{$key} && !exists $params->{$key});

        die "ERROR: Received undefined mandatory param: $key"
            if ($fields->{$key} && !defined $params->{$key});

	$FIELDS->{$key}->{check}->($params->{$key})
            if defined $params->{$key};
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-PageSpeedOnline>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-google-pagespeedonline at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-PageSpeedOnline>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::PageSpeedOnline::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-PageSpeedOnline>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-PageSpeedOnline>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-PageSpeedOnline>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-PageSpeedOnline/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::PageSpeedOnline::Params
