package WebService::Hexonet::Connector::Util;

use strict;
use warnings;
use utf8;
use base 'Exporter';
use Time::Local;
use MIME::Base64;

our $VERSION = '1.11';

our @EXPORT    = qw();
our @EXPORT_OK = qw(sqltime timesql);

sub timesql {
    my $sqltime = shift;
    return undef
      if !defined $sqltime || $sqltime !~ /(\d\d+)-(\d+)-(\d+)/;
    my $year = $1;
    my $mon  = $2;
    my $mday = $3;
    my $rest = $';
    my $hour = "0";
    my $min  = "0";
    my $sec  = "0";
    my $diff = 0;

    if ( $rest =~ /(\d+):(\d+):(\d+)/ ) {
        $rest = $';
        $hour = $1;
        $min  = $2;
        $sec  = $3;
        if ( $rest =~ /\+(\d\d?)/ ) {
            $diff -= $1 * 3600;
        }
        if ( $rest =~ /\-(\d\d?)/ ) {
            $diff += $1 * 3600;
        }
    }
    $mon--;
    $year -= 1900;
    my $value = eval { timegm( $sec, $min, $hour, $mday, $mon, $year ) };
    if ( !defined $value ) {
        if ( ( $mon == 1 ) && ( $mday == 29 ) ) {
            $value = eval { timegm( $sec, $min, $hour, 1, 2, $year ) };
        }
    }
    $value += $diff;
    return $value;
}

sub sqltime {
    my $time = shift;
    $time = time()
      if !defined $time;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      gmtime($time);
    $mon++;
    $year += 1900;
    $mday = "0" . int($mday) if $mday < 10;
    $mon  = "0" . int($mon)  if $mon < 10;
    $hour = "0" . int($hour) if $hour < 10;
    $min  = "0" . int($min)  if $min < 10;
    $sec  = "0" . int($sec)  if $sec < 10;
    return "$year-$mon-$mday $hour:$min:$sec";
}

sub url_encode {
    my $s = shift;
    return undef
      unless defined $s;
    utf8::encode($s) if utf8::is_utf8($s);
    $s =~ s/([^A-Za-z0-9\-\._~])/sprintf("%%%02X", ord($1))/seg;
    return $s;
}

sub url_decode {
    my $s = shift;
    return ( LIST { undef } SCALAR { undef } )
      unless defined $s;

    #	$s =~ s/\+/ /og;
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $s;
}

sub base64_decode {
    my $s = shift;
    return ( LIST { undef } SCALAR { undef } )
      unless defined $s;
    return decode_base64($s);
}

sub base64_encode {
    my $s = shift;
    return ( LIST { undef } SCALAR { undef } )
      unless defined $s;
    utf8::encode($s) if utf8::is_utf8($s);
    return encode_base64( $s, "" );
}

sub command_encode {
    return scalar _command_encode(@_);
}

sub _command_encode {
    my $in = shift;

    if ( ( ref $in ) eq "HASH" ) {
        my @lines = ();
        foreach my $k ( keys %$in ) {
            my @values = _command_encode( $in->{$k} );
            foreach my $v (@values) {
                push @lines, uc($k) . $v;
            }
        }
        return join "\n", @lines unless wantarray;
        return @lines;
    }
    elsif ( ( ref $in ) eq "ARRAY" ) {
        my $i     = 0;
        my @lines = ();
        foreach my $v (@$in) {
            my @values = _command_encode($v);
            foreach my $v (@values) {
                push @lines, "$i$v";
            }
            $i++;
        }
        return join "\n", @lines unless wantarray;
        return @lines;
    }
    elsif ( !ref $in ) {
        my $out = $in;
        utf8::encode($out) if utf8::is_utf8($out);
        if (wantarray) {
            $out =~ s/\s/ /og;
            return ("=$out");
        }
        return $out;
    }
    else {
        die "Unsupported Class: " . ( ref $in );
    }
}

sub response_to_hash {
    my $response = shift;

    my %hash = ( PROPERTY => {} );

    return \%hash if !defined $response;

    foreach ( split /\n/, $response ) {
        if (/^([^\=]*[^\t\= ])[\t ]*=[\t ]*/) {
            my $attr  = $1;
            my $value = $';
            $value =~ s/[\t ]*$//;
            if ( $attr =~ /^property\[([^\]]*)\]/i ) {
                my $prop = uc $1;
                $prop =~ s/\s//og;
                if ( exists $hash{"PROPERTY"}->{$prop} ) {
                    push @{ $hash{"PROPERTY"}->{$prop} }, $value;
                }
                else {
                    $hash{"PROPERTY"}->{$prop} = [$value];
                }
            }
            else {
                $hash{ uc $attr } = $value;
            }
        }
    }
    return \%hash;

}

sub response_to_list_hash {
    my $response = shift;

    my $list = {
        CODE        => $response->{CODE},
        DESCRIPTION => $response->{DESCRIPTION},
        RUNTIME     => $response->{RUNTIME},
        QUEUETIME   => $response->{QUEUETIME},
        ITEMS       => []
    };

    my $count = 0;

    if ( exists $response->{PROPERTY} ) {
        my $columns = undef;
        if ( exists $response->{PROPERTY}{COLUMN} ) {
            $columns = { map { $_ => 1 } @{ $response->{PROPERTY}{COLUMN} } };
            $list->{COLUMNS} = $response->{PROPERTY}{COLUMN};
        }
        else {
            $list->{COLUMNS} = [];
        }
        foreach my $property ( keys %{ $response->{PROPERTY} } ) {
            if ( $property =~ /^(COLUMN)$/i ) {
            }
            elsif ( $property =~ /^(FIRST|LAST|COUNT|LIMIT|TOTAL)$/i ) {
                $list->{$property} = $response->{PROPERTY}{$property}[0];
            }
            else {
                next if $columns && !$columns->{$property};
                push @{ $list->{COLUMNS} }, $property;
                my $index = 0;
                foreach my $value ( @{ $response->{PROPERTY}{$property} } ) {
                    $list->{ITEMS}[$index]{$property} = $value;
                    $index++;
                }
                $count = $index if $index > $count;
            }
        }
    }

    $list->{FIRST} = 0              unless defined $list->{FIRST};
    $list->{COUNT} = $count         unless defined $list->{COUNT};
    $list->{TOTAL} = $list->{COUNT} unless defined $list->{TOTAL};
    $list->{LAST} = $list->{FIRST} + $list->{COUNT} - 1
      unless defined $list->{LAST};
    $list->{LIMIT} = $list->{COUNT} || 1 unless defined $list->{LIMIT};

    $list->{LIMIT} = $list->{COUNT} if $list->{COUNT} > $list->{LIMIT};

    if ( ( exists $list->{FIRST} ) && ( $list->{LIMIT} ) ) {
        $list->{PAGE} = int( $list->{FIRST} / $list->{LIMIT} ) + 1;
        if ( $list->{PAGE} > 1 ) {
            $list->{PREVPAGE}      = $list->{PAGE} - 1;
            $list->{PREVPAGEFIRST} = ( $list->{PREVPAGE} - 1 ) * $list->{LIMIT};
        }
        $list->{NEXTPAGE}      = $list->{PAGE} + 1;
        $list->{NEXTPAGEFIRST} = ( $list->{NEXTPAGE} - 1 ) * $list->{LIMIT};
    }

    if ( ( exists $list->{TOTAL} ) && ( $list->{LIMIT} ) ) {
        $list->{PAGES} =
          int( ( $list->{TOTAL} + $list->{LIMIT} - 1 ) / $list->{LIMIT} );
        $list->{LASTPAGEFIRST} = ( $list->{PAGES} - 1 ) * $list->{LIMIT};
        if (   ( exists $list->{NEXTPAGE} )
            && ( $list->{NEXTPAGE} > $list->{PAGES} ) )
        {
            delete $list->{NEXTPAGE};
            delete $list->{NEXTPAGEFIRST};
        }
    }

    return $list;
}

1;

__END__

=head1 NAME

WebService::Hexonet::Connector::Util - utility package providing useful helper methods.

=head1 DESCRIPTION

This package represents a bundle of helper methods to are used by the WebService::Hexonet::Connector
module and its submodules. Further more it provides methods that are useful when dealing
with Backend API responses and showing outputs.

=head1 METHODS WebService::Hexonet::Connector::Util

=over 4

=item C<timesql(sqldatetime)>

Convert the SQL datetime to Unix-Timestamp

=item C<sqltime(timestamp)>

Convert the Unix-Timestamp to a SQL datetime If no timestamp given, returns the current datetime

=item C<url_encode(string)>

URL-encodes string This function is convenient when encoding a string to be used in a query part of a URL

=item C<url_decode(string)>

Decodes URL-encoded string Decodes any %## encoding in the given string.

=item C<base64_encode(string)>

Encodes data with MIME base64 This encoding is designed to make binary data survive transport through transport layers that are not 8-bit clean, such as mail bodies.

=item C<base64_decode(string)>

Decodes data encoded with MIME base64

=item C<command_encode(command)>

Encode the command array in a command-string

=item C<response_to_hash(response)>

Convert the response string as a hash

=item C<response_to_list_hash(response)>

Convert the response string as a list hash

=back

=head1 AUTHOR

Hexonet GmbH

L<https://www.hexonet.net>

=head1 LICENSE

MIT

=cut
