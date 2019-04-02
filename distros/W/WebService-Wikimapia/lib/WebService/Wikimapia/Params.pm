package WebService::Wikimapia::Params;

$WebService::Wikimapia::Params::VERSION   = '0.14';
$WebService::Wikimapia::Params::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WebService::Wikimapia::Params - Placeholder for parameters for WebService::Wikimapia.

=head1 VERSION

Version 0.14

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;
use parent 'Exporter';

our @EXPORT_OK = qw(validate $API_KEY $Language $Disable $Format $Pack $Num $FIELDS);

our $API_KEY = sub { die "[$_[0]" unless check_api_key($_[0]); };
sub check_api_key  { return ($_[0] =~ m/^[A-Z0-9]{8}\-[A-Z0-9]{8}\-[A-Z0-9]{8}\-[A-Z0-9]{8}\-[A-Z0-9]{8}\-[A-Z0-9]{8}\-[A-Z0-9]{8}\-[A-Z0-9]{8}$/i); }

our $DISABLE = { 'location' => 1, 'polygon' => 1 };
our $Disable = sub { die "ERROR: Invalid data type 'disable' found [$_[0]]" unless check_disable($_[0]); };
sub check_disable { return exists $DISABLE->{lc($_[0])}; }

our $FORMAT = { 'xml' => 1, 'json' => 1, 'jsonp' => 1, 'kml'=> 1, 'binary' => 1 };
our $Format = sub { die "ERROR: Invalid data type 'format' found [$_[0]]" unless check_format($_[0]); };
sub check_format { return exists $FORMAT->{lc($_[0])} }

our $PACK = { 'none' => 1, 'gzip' => 1 };
our $Pack = sub { die "ERROR: Invalid data type 'pack' found [$_[0]]" unless check_pack($_[0]); };
sub check_pack { return exists $PACK->{lc($_[0])} }

our $LANGUAGE = {
    'ab' => 1, 'aa' => 1, 'af' => 1, 'ak' => 1, 'sq' => 1, 'am' => 1, 'ar' => 1, 'an' => 1, 'hy' => 1,
    'as' => 1, 'av' => 1, 'ae' => 1, 'ay' => 1, 'az' => 1, 'bm' => 1, 'ba' => 1, 'eu' => 1, 'be' => 1,
    'bn' => 1, 'bh' => 1, 'bi' => 1, 'bs' => 1, 'br' => 1, 'bg' => 1, 'my' => 1, 'ca' => 1, 'ch' => 1,
    'ce' => 1, 'ny' => 1, 'zh' => 1, 'cv' => 1, 'kw' => 1, 'co' => 1, 'cr' => 1, 'hr' => 1, 'cs' => 1,
    'da' => 1, 'dv' => 1, 'nl' => 1, 'dz' => 1, 'en' => 1, 'eo' => 1, 'et' => 1, 'ee' => 1, 'fo' => 1,
    'fj' => 1, 'fi' => 1, 'fr' => 1, 'ff' => 1, 'gl' => 1, 'ka' => 1, 'de' => 1, 'el' => 1, 'gn' => 1,
    'gu' => 1, 'ht' => 1, 'ha' => 1, 'he' => 1, 'hz' => 1, 'hi' => 1, 'ho' => 1, 'hu' => 1, 'ia' => 1,
    'id' => 1, 'ie' => 1, 'ga' => 1, 'ig' => 1, 'ik' => 1, 'io' => 1, 'is' => 1, 'it' => 1, 'iu' => 1,
    'ja' => 1, 'jv' => 1, 'kl' => 1, 'kn' => 1, 'kr' => 1, 'ks' => 1, 'kk' => 1, 'km' => 1, 'ki' => 1,
    'rw' => 1, 'ky' => 1, 'kv' => 1, 'kg' => 1, 'ko' => 1, 'ku' => 1, 'kj' => 1, 'la' => 1, 'lb' => 1,
    'lg' => 1, 'li' => 1, 'ln' => 1, 'lo' => 1, 'lt' => 1, 'lu' => 1, 'lv' => 1, 'gv' => 1, 'mk' => 1,
    'mg' => 1, 'ms' => 1, 'ml' => 1, 'mt' => 1, 'mi' => 1, 'mr' => 1, 'mh' => 1, 'mn' => 1, 'na' => 1,
    'nv' => 1, 'nb' => 1, 'nd' => 1, 'ne' => 1, 'ng' => 1, 'nn' => 1, 'no' => 1, 'ii' => 1, 'nr' => 1,
    'oc' => 1, 'oj' => 1, 'cu' => 1, 'om' => 1, 'or' => 1, 'os' => 1, 'pa' => 1, 'pi' => 1, 'fa' => 1,
    'pl' => 1, 'ps' => 1, 'pt' => 1, 'qu' => 1, 'rm' => 1, 'rn' => 1, 'ro' => 1, 'ru' => 1, 'sa' => 1,
    'sc' => 1, 'sd' => 1, 'se' => 1, 'sm' => 1, 'sg' => 1, 'sr' => 1, 'gd' => 1, 'sn' => 1, 'si' => 1,
    'sk' => 1, 'sl' => 1, 'af' => 1, 'st' => 1, 'es' => 1, 'su' => 1, 'sw' => 1, 'ss' => 1, 'sv' => 1,
    'ta' => 1, 'te' => 1, 'tg' => 1, 'th' => 1, 'ti' => 1, 'bo' => 1, 'tk' => 1, 'tl' => 1, 'tn' => 1,
    'to' => 1, 'tr' => 1, 'ts' => 1, 'tt' => 1, 'tw' => 1, 'ty' => 1, 'ug' => 1, 'uk' => 1, 'ur' => 1,
    'uz' => 1, 've' => 1, 'vi' => 1, 'vo' => 1, 'wa' => 1, 'cy' => 1, 'wo' => 1, 'fy' => 1, 'xh' => 1,
    'yi' => 1, 'yo' => 1, 'za' => 1, 'zu' => 1,
};
our $Language = sub { die "ERROR: Invalid data type 'language' found [$_[0]]" unless check_language($_[0]); };
sub check_language { return exists $LANGUAGE->{lc($_[0])}; }

our $Num = sub { return check_num($_[0]); };
sub check_num {
    my ($num) = @_;

    die "ERROR: Invalid NUM data type [$num]" unless (defined $num && $num =~ /^\d+$/);
}

sub check_str {
    my ($str) = @_;

    die "ERROR: Invalid STR data type [$str]" if (defined $str && $str =~ /^\d+$/);
}

sub check_bbox {
    my ($str) = @_;

    if ((defined $str) && ($str =~ /\,/)) {
        my ($lon_min,$lat_min,$lon_max,$lat_max) = split /\,/,$str,4;
        if (((defined $lon_min) && ($lon_min =~ /\-?\d+\.?\d+$/))
            &&
            ((defined $lat_min) && ($lat_min =~ /\-?\d+\.?\d+$/))
            &&
            ((defined $lon_max) && ($lon_max =~ /\-?\d+\.?\d+$/))
            &&
            ((defined $lat_max) && ($lat_max =~ /\-?\d+\.?\d+$/))) {
            return;
        }
    }

    die "ERROR: Invalid data type 'bbox' [$str]";
}

our $FIELDS = {
    'disable'  => { check => sub { check_location(@_) }, type => 's' },
    'page'     => { check => sub { check_num(@_)      }, type => 'd' },
    'id'       => { check => sub { check_num(@_)      }, type => 'd' },
    'count'    => { check => sub { check_num(@_)      }, type => 'd' },
    'language' => { check => sub { check_language(@_) }, type => 's' },
    'format'   => { check => sub { check_format(@_)   }, type => 's' },
    'pack'     => { check => sub { check_pack(@_)     }, type => 's' },
    'bbox'     => { check => sub { check_bbox(@_)     }, type => 's' },
    'lon_min'  => { check => sub { check_str(@_)      }, type => 's' },
    'lon_max'  => { check => sub { check_str(@_)      }, type => 's' },
    'lat_min'  => { check => sub { check_str(@_)      }, type => 's' },
    'lat_max'  => { check => sub { check_str(@_)      }, type => 's' },
    'x'        => { check => sub { check_num(@_)      }, type => 'd' },
    'y'        => { check => sub { check_num(@_)      }, type => 'd' },
    'z'        => { check => sub { check_num(@_)      }, type => 'd' },
    'lon'      => { check => sub { check_str(@_)      }, type => 's' },
    'lat'      => { check => sub { check_str(@_)      }, type => 's' },
    'q'        => { check => sub { check_str(@_)      }, type => 's' },

};

sub validate {
    my ($fields, $values) = @_;

    die "ERROR: Missing params list." unless (defined $values);

    die "ERROR: Parameters have to be hash ref" unless (ref($values) eq 'HASH');

    foreach my $field (sort keys %{$fields}) {
        die "ERROR: Received invalid param: $field"
            unless (exists $FIELDS->{$field});

        die "ERROR: Missing mandatory param: $field"
            if ($fields->{$field} && !exists $values->{$field});

        die "ERROR: Received undefined mandatory param: $field"
            if ($fields->{$field} && !defined $values->{$field});

	$FIELDS->{$field}->{check}->($values->{$field})
            if defined $values->{$field};
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/WebService-Wikimapia>

=head1 BUGS

Please  report  any  bugs  or feature  requests to C<bug-webservice-wikimapia  at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Wikimapia>.
I will be notified and then you'll automatically be notified of  progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Wikimapia::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Wikimapia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Wikimapia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Wikimapia>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Wikimapia/>

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

1; # End of WebService::Wikimapia::Params
