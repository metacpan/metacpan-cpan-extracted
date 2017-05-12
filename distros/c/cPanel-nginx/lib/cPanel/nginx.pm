package cPanel::nginx;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
				getXMLAPIResponse
				getAuthHash	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

use LWP::UserAgent;
use HTTP::Request;

sub getAuthHash
{
# Функция возвращает Hash для доступа к API cPanel
# Hash предварительно должен быть сгенерирован в WHM

        open HASHFILE, "</root/.accesshash" || die "Can't get accesshash\n";
        my $hash = "";
        while (<HASHFILE>)
        {
                $hash .= $_;
        }
        close HASHFILE;
        $hash =~ s/\n//g;
        my $auth = "WHM root:" . $hash;
        return $auth;
}

sub getXMLAPIResponse
{
# Первым аргументом функция принимает имя функции API
# Во втором аргументе функции должен быть передан хэш аргументов

        my ($function, %args) = @_;
	return 0 if (!$function =~ m/[a-z]+/);
        my $url = "https://127.0.0.1:2087/xml-api/$function";
        my $args = "";
        if (%args)
        {
                foreach my $name (keys %args)
                {
                        $args .= "$name=$args{$name}&";
                }
                $url .= "?$args";
        }
        my $ua = LWP::UserAgent->new;
        my $request = HTTP::Request->new( GET => $url );
        $request->header( Authorization => getAuthHash());
        my $response = $ua->request($request);
        return $response->content;
}


1;
__END__

=head1 NAME

cPanel::nginx - Perl extension for integration cPanel and webserver NGINX <http://nginx.org/en/>

=head1 SYNOPSIS

  use cPanel::nginx;
  my $authHash = getAuthHash();
  my $cPanelXMLAPIResponse = getXMLAPIResponse('listips');
  my %opt = (domain => 'domain.com', Line => '9');
  my $cPanelXMLAPIResponse1 = getXMLAPIResponse('getzonerecord', %opt);

=head1 DESCRIPTION

cPanel haven't the integration methods with popular webserver NGINX.
The functions of this module helps you automatic create and delete NGINX vhost files, add addon domain or subdomain, delete them and etc, according to cPanel events.

=head1 SEE ALSO

cPanel documentation - <http://etwiki.cpanel.net/twiki/bin/view/AllDocumentation/WebHome>
NGINX documentation - <http://nginx.org/en/>

=head1 AUTHOR

Aleksey Vaganov, <avaganov@idivision.ru>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Aleksey Vaganov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
