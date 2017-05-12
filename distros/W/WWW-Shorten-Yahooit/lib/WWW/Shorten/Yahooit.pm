use strict;
use warnings;
package WWW::Shorten::Yahooit;
{
  $WWW::Shorten::Yahooit::VERSION = '0.004';
}
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );
use WWW::YQL;
use Carp;

# ABSTRACT: Perl interface to y.ahoo.it
# PODNAME: WWW::Shorten::Yahooit



sub makeashorterlink{
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $yql = WWW::YQL->new();

    my $data = $yql->query("insert into yahoo.y.ahoo.it (url) values ('".$url."')");
    if (defined $data->{'query'}->{'results'}->{'error'}){
	die $data->{'query'}->{'results'}->{'error'};
    }else{
	return $data->{'query'}->{'results'}->{'url'};
    }
}

sub makealongerlink{
    my $url = shift or croak 'No URL passed to makeashorterlink';
    my $yql = WWW::YQL->new();
    my $data = $yql->query("select * from yahoo.y.ahoo.it where url='".$url."'");
    if (defined $data->{'query'}->{'results'}->{'error'}){
	die $data->{'query'}->{'results'}->{'error'};
    }else{
	return $data->{'query'}->{'results'}->{'url'};
    }
}
1;

__END__

=pod

=head1 NAME

WWW::Shorten::Yahooit - Perl interface to y.ahoo.it

=head1 VERSION

version 0.004

=head1 SYNOPSIS

use WWW::Shorten::Yahooit;
use WWW::Shorten 'Yahooit';

$short_url = makeashorterlink($long_url);

$long_url  = makealongerlink($short_url);

=head2 DESCRIPTION

This module uses YQL to create shortened URLs using the y.ahoo.it URL
shortening service from Yahoo!

=head1 METHODS

=head2 makeashorterlink

The function makeashorterlink will do an insert on the yahoo.y.ahoo.it
table on the Yahoo! YQL service passing it your long URL and will
return the shorter version.

=head2 makealongerlink

The function makealongerlink will do an select on the yahoo.y.ahoo.it
table on the Yahoo! YQL service passing it your short URL and will
return the longer version.

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
