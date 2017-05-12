# A handful of utility bits shared across test suites.
# $Id: util.pl 21 2006-09-25 01:48:00Z  $

sub api_key
{
    (my $keyfile = __FILE__) =~ s|/(.*?)$|/|;
    $keyfile .= 'testing.key';
    open my $fh, "< $keyfile" or die "Cannot open $keyfile: $!, stopped";

    chomp(my $key = <$fh>);
    $key;
}

sub can_connect_isbndb
{
    require Socket;

    return (Socket::inet_aton('isbndb.com')) ? 1 : 0;
}

1;
