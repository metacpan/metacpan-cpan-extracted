package WWW::StatsMix::Params;

$WWW::StatsMix::Params::VERSION = '0.07';

=head1 NAME

WWW::StatsMix::Params - Placeholder for parameters for WWW::StatsMix

=head1 VERSION

Version 0.07

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(validate $FIELDS);

our $SHARING   = { public => 1, none => 1 };
our $Sharing   = sub { check_sharing($_[0])     };
our $XmlOrJson = sub { check_format($_[0])      };
our $ZeroOrOne = sub { check_zero_or_one($_[0]) };

sub check_format {
    my ($str) = @_;

    die "ERROR: Invalid data found [$str]"
        unless (defined($str) || ($str =~ m(^\bjson\b|\bxml\b$)i))
}

sub check_sharing {
    my ($str) = @_;

    die "ERROR: Invalid data type 'sharing' found [$str]"
        unless (defined $str && exists $SHARING->{$str});
};

sub check_zero_or_one {
    my ($str) = @_;

    die "ERROR: Expected data is 0 or 1 but found [$str]"
        unless (defined $str && $str =~ /^[0|1]$/);
};

sub check_num {
    my ($num) = @_;

    die "ERROR: Invalid NUM data type [$num]"
        unless (defined $num && $num =~ /^\d+$/);
};

sub check_str {
    my ($str) = @_;

    die "ERROR: Invalid STR data type [$str]"
        if (defined $str && $str =~ /^\d+$/);
};

sub check_date {
    my ($str) = @_;

    if ($str =~ m!^((?:19|20)\d\d)\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$!) {
        # At this point, $1 holds the year, $2 the month and $3 the day of the date entered
        if ($3 == 31 and ($2 == 4 or $2 == 6 or $2 == 9 or $2 == 11)) {
            # 31st of a month with 30 days
            die "ERROR: Invalid data of type 'date' found [$str]"
        } elsif ($3 >= 30 and $2 == 2) {
            # February 30th or 31st
            die "ERROR: Invalid data of type 'date' found [$str]"
        } elsif ($2 == 2 and $3 == 29 and not ($1 % 4 == 0 and ($1 % 100 != 0 or $1 % 400 == 0))) {
            # February 29th outside a leap year
            die "ERROR: Invalid data of type 'date' found [$str]"
        } else {
            return 1; # Valid date
        }
    } else {
        # Not a date
        die "ERROR: Invalid data of type 'date' found [$str]"
    }
}

sub check_url {
    my ($str) = @_;

    die "ERROR: Invalid data type 'url' found [$str]"
        unless (defined $str
                && $str =~ /^(http(?:s)?\:\/\/[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,6}(?:\/?|(?:\/[\w\-]+)*)(?:\/?|\/\w+\.[a-zA-Z]{2,4}(?:\?[\w]+\=[\w\-]+)?)?(?:\&[\w]+\=[\w\-]+)*)$/);
};

sub check_value {
    my ($str) = @_;

    die "ERROR: Invalid data type 'value' found [$str]."
        unless (defined $str && $str =~ /^\d{0,11}\.?\d{0,2}$/);
}

sub check_hash_ref {
    my ($str) = @_;

    return (defined $str && (ref($str) eq 'HASH'));
}

our $FIELDS = {
    'id'               => { check => sub { check_num(@_)         }, type => 'd' },
    'ref_id'           => { check => sub { check_str(@_)         }, type => 's' },
    'profile_id'       => { check => sub { check_num(@_)         }, type => 'd' },
    'metric_id'        => { check => sub { check_num(@_)         }, type => 'd' },
    'limit'            => { check => sub { check_num(@_)         }, type => 'd' },
    'value'            => { check => sub { check_value(@_)       }, type => 'd' },
    'name'             => { check => sub { check_str(@_)         }, type => 's' },
    'sharing'          => { check => sub { check_sharing(@_)     }, type => 's' },
    'include_in_email' => { check => sub { check_zero_or_one(@_) }, type => 'd' },
    'format'           => { check => sub { check_format(@_)      }, type => 's' },
    'url'              => { check => sub { check_url(@_)         }, type => 's' },
    'meta'             => { check => sub { check_hash_ref(@_)    }, type => 's' },
    'generated_at'     => { check => sub { check_date(@_)        }, type => 's' },
    'start_date'       => { check => sub { check_date(@_)        }, type => 's' },
    'end_date'         => { check => sub { check_date(@_)        }, type => 's' },
};

sub validate {
    my ($fields, $values) = @_;

    die "ERROR: Missing params list." unless (defined $values);

    die "ERROR: Parameters have to be hash ref" unless (ref($values) eq 'HASH');

    my $keys = [];
    foreach my $row (@$fields) {
        my $field    = $row->{key};
        my $required = $row->{required};
        push @$keys, $field;

        die "ERROR: Received invalid param: $field"
            unless (exists $FIELDS->{$field});

        die "ERROR: Missing mandatory param: $field"
            if ($required && !exists $values->{$field});

        die "ERROR: Received undefined mandatory param: $field"
            if ($required && !defined $values->{$field});

	$FIELDS->{$field}->{check}->($values->{$field})
            if defined $values->{$field};
    }

    foreach my $value (keys %$values) {
        die "ERROR: Invalid key found in params." unless (grep /\b$value\b/, @$keys);
        die "ERROR: Received undefined param: $value" unless (defined $values->{$value});
        $FIELDS->{$value}->{check}->($values->{$value});
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/WWW-StatsMix>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-statsmix at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StatsMix>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::StatsMix::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-StatsMix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-StatsMix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-StatsMix>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-StatsMix/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

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

1; # End of WWW::StatsMix::Params
