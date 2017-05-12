package Weightbot::API;
{
  $Weightbot::API::VERSION = '1.1.0';
}

# ABSTRACT: get Weightbot iPhone app data from weightbot.com

use warnings;
use strict;

use Carp;
use WWW::Mechanize;
use Class::Date qw(date);
use File::Slurp;


sub new {
    my ($class, $self) = @_;

    croak 'No email specified, stopped' unless $self->{email};
    croak 'No password specified, stopped' unless $self->{password};

    $self->{site} ||= 'https://weightbot.com';

    bless($self, $class);
    return $self;
}


sub raw_data {
    my ($self) = @_;

    $self->_get_data_if_needed;

    return $self->{raw_data};
}


sub data {
    my ($self) = @_;

    $self->_get_data_if_needed;

    unless ($self->{data}) {
        my $result;

        my $n = 1;
        my $prev_date;

        local $Class::Date::DATE_FORMAT="%Y-%m-%d";

        foreach my $line (split '\n', $self->{raw_data}) {
            next if $line =~ /^date, kilograms, pounds$/;
            my ($d, $k, $p) = split /\s*,\s*/, $line;

            $d = date($d);

            if ($prev_date) {
                if ($d < $prev_date) {
                    croak "Date '$d' is earlier than '$prev_date', stopped";
                }

                my $expected_date = $prev_date + '1D';
                while ("$d" ne "$expected_date") {
                    push @$result, {
                        date => "$expected_date",
                        kg => '',
                        lb => '',
                        n => $n,
                    };
                    $expected_date += '1D';
                    $n++;
                }

            }

            push @$result, {
                date => "$d",
                kg => $k,
                lb => $p,
                n => $n,
            };
            $prev_date = $d;
            $n++;
        }
        $self->{data} = $result;
    }

    return $self->{data};
}


sub _get_data_if_needed {
    my ($self) = @_;

    my $cache_filename;

    if ($self->{use_cache_file}) {
        $cache_filename
            = defined($self->{cache_file})
            ? $self->{cache_file}
            : '/tmp/weightbot.data';

        if (-e $cache_filename) {
            $self->{raw_data} = read_file($cache_filename);
        }
    }

    unless ($self->{raw_data}) {
        my $mech = WWW::Mechanize->new(
            agent => "Weightbot::API/$Weightbot::API::VERSION",
        );

        $mech->get( $self->{site} . '/account/login');

        $mech->submit_form(
            form_number => 1,
            fields      => {
                email     => $self->{email},
                password  => $self->{password},
            }
        );

        $mech->submit_form(
            form_number => 1,
        );

        if ($mech->content !~ /^date, kilograms, pounds\n/) {
            croak "Recieved incorrect data, stopped"
        }

        $self->{raw_data} = $mech->content;
    }

    if ($self->{use_cache_file}) {
        write_file($cache_filename, $self->{raw_data});
    }
}


1;

__END__

=pod

=head1 NAME

Weightbot::API - get Weightbot iPhone app data from weightbot.com

=head1 VERSION

version 1.1.0

=head1 SYNOPSIS

There is a great iPhone weight tracking app
http://tapbots.com/software/weightbot/. It backups its data to the site
https://weightbot.com/ where everyone using that app can login and
download the file with the records.

This module gets that data and shows it as a pretty data structure.

    use Weightbot::API;
    use Data::Dumper;

    my $wi = Weightbot::API->new({
        email    => 'user@example.com',
        password => '******',
    });

    say $wi->raw_data;
    say Dumper $wi->data;

The object does not send requests to site until data needs to be
retrieved. The first invocation of either data() or raw_data() methods will
get data from the site and it will be stored in the object, so you can
use raw_data() and data() many times without unnecessary requests to the site.

Site https://weightbot.com/ does not have real API, this module behaves as a
browser.

=head2 NOTES

Weightbot::API version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

While debugging your programme that uses this module it is not a great idea to
send requests to weightbot.com on every test run. This module can cache data
to file. The module will read data from the cache file if the file exists or
will download data and save it to the file if there is no cache file.

To use this feature you should create Weightbot::API object with:

    my $wi = Weightbot::API->new({
        email    => 'user@example.com',
        password => '******',
        use_cache_file => 1,
        cache_file     => '/storage/weightbot.raw',     # optional
    });

The default value for 'cache_file' is '/tmp/weightbot.data'.

So when you debug your programme you can specify 'use_cache_file'. Then on
first run the data will be downloaded from weightbot.com and saved to file and
all other runs will use data from the file without asking weightbot.com.

=head1 SUBROUTINES/METHODS

=head2 new

Creates new object. It has to get parameters 'email' and 'password'.
Optionally you can specify 'site' with some custom site url (default is
'https://weightbot.com'). The other optional thing is to specify 'raw_data'.

    my $wi = Weightbot::API->new({
        email    => 'user@example.com',
        password => '******',
    });

=head2 raw_data

Returns the weight records in the format as they are stored on the site.
Here is an example:

    date, kilograms, pounds
    2008-12-04, 80.9, 178.4
    2008-12-05, 82.6, 182.1
    2008-12-06, 81.9, 180.6
    2008-12-08, 82.6, 182.1

Any subsequent call to this method will not result in actual data retrieval as
the data is cached within the object.

=head2 data

Returns the weight data in a structure. In that data some dates can be
skipped. In this structure all the dates are present, but if there is no
weight for that date the empty sting is used.

An example for the data show in raw_data() method:

    $VAR1 = [
              {
                'n' => 1,
                'date' => '2008-12-04',
                'kg' => '80.9',
                'lb' => '178.4'
              },
              {
                'n' => 2,
                'date' => '2008-12-05',
                'kg' => '82.6',
                'lb' => '182.1'
              },
              {
                'n' => 3,
                'date' => '2008-12-06',
                'kg' => '81.9',
                'lb' => '180.6'
              },
              {
                'n' => 4,
                'date' => '2008-12-07',
                'kg' => '',
                'lb' => ''
              },
              {
                'n' => 5,
                'date' => '2008-12-08',
                'kg' => '82.6',
                'lb' => '182.1'
              }
            ];

Any subsequent call to this method will not result in actual data retrieval as
the data is cached within the object.

=begin comment _get_data_if_needed

This is a private method that is executed in raw_data() and data(). It checks
if the object already has the data from the site. If not the site is asked
for the data, witch is stored in the object.


=end comment

=head1 CONTRIBUTORS

Evgeniy Kosov C<< <evgeniy@kosov.su> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-weightbot-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Weightbot-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
You can also submit a bug or a feature request on GitHub.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub http://github.com/bessarabov/Weightbot-API

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
