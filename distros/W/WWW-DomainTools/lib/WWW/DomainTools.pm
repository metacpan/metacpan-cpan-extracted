package WWW::DomainTools;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use XML::Simple ();
use URI::Escape;
use WWW::DomainTools::SearchEngine;
use WWW::DomainTools::NameSpinner;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = "0.11";
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw (search_engine name_spinner);
    %EXPORT_TAGS = ();
}

use constant DEFAULT_URL    => "http://engine.whoisapi.com/api.xml";
use constant DEFAULT_FORMAT => "hash";

our @VALID_TLDS = qw/ com net org info biz us /;

=head1 NAME

WWW::DomainTools - DomainTools.com XML API interface 

=head1 SYNOPSIS

 use WWW::DomainTools qw(search_engine name_spinner);

 my $repsonse = search_engine(
 	q => 'example.com',
	ext => 'COM|NET|ORG|INFO'
        key => '12345',
        partner => 'yourname',
        customer_ip => '1.2.3.4'
 );

 # OO
 my $obj = WWW::DomainTools::SearchEngine->new(
        key => '12345',
        partner => 'yourname',
        customer_ip => '1.2.3.4'
 );
 my $response = $obj->request(
 	q => 'example.com',
	ext => 'COM|NET|ORG|INFO'
 );


 # Custom LWP user agent
 my $ua = LWP::UserAgent->new;
 $ua->env_proxy(true);

 my $obj = WWW::DomainTools::SearchEngine->new(
        key => '12345',
        partner => 'yourname',
        customer_ip => '1.2.3.4',
        lwp_ua => $ua
 );
 my $response = $obj->request(
 	q => 'example.com',
	ext => 'COM|NET|ORG|INFO'
 );

 

=head1 DESCRIPTION

This module allows you to use the name spinner and whois search available
on domaintools.com.

These methods are available as both class and object methods.  Nothing is 
exported by default.

=head1 EXPORTS

None by default.

Allowed:

 - search_engine
 - name_spinner

=head1 METHODS

=cut

sub new {
    my ( $class, %parameters ) = @_;

    croak "new() can't be invoked on an object"
        if ref($class);

    my $self = bless( {}, $class );

    $self->{_ua}         = $parameters{lwp_ua} || LWP::UserAgent->new;
    $self->{_xml}        = XML::Simple->new;
    $self->{_format}     = $parameters{format} || DEFAULT_FORMAT;
    $self->{_ua_timeout} = $parameters{timeout} || 10;
    $self->{_url}        = $parameters{url} || DEFAULT_URL;

    %{ $self->{default_params} } = ();

    # sub clases should implement this. Usually to set default_params fields
    $self->_init();

    ## the universally recognized parameters can be passed in without using the
    # 'params' hash as a convenience
    foreach my $field (qw{ appname version partner key customer_ip }) {
        if ( defined $parameters{$field} ) {
            ${ $self->{default_params} }{$field} = $parameters{$field};
        }
    }

    return $self;

}

=over 4

=item search_engine ( url parameters hash )

The keys and values expected are documented on the Domain Tools website. In 
addition the "search engine" specific parameters, you need to pass the
required parameters as documented in the L<WWW::DomainTools::SearchEngine> new()
method.

If the request is successful, the return value is either a hash reference or 
a string depending on the value of the 'format' parameter to the constructor.

See the documentation for the new() method for more detailed information
about 'format' and other standard parameters.

If the HTTP request fails, this method will die.

=back

=cut

sub search_engine {
	my $api = WWW::DomainTools::SearchEngine->new(@_);
	return $api->request();
}

=over 4

=item name_spinner ( url parameters hash )

The keys and values expected are documented on the Domain Tools website. In 
addition the "name spinner" specific parameters, you need to pass the
required parameters as documented in the L<WWW::DomainTools::NameSpinner> new()
method.

If the request is successful, the return value is either a hash reference or 
a string depending on the value of the 'format' parameter to the constructor.

See the documentation for the new() method for more detailed information
about 'format' and other standard parameters.

If the HTTP request fails, this method will die.

=back

=cut

sub name_spinner {
	my $api = WWW::DomainTools::NameSpinner->new(@_);
	return $api->request();
}

sub request {
    my ( $self, %params ) = @_;

    if ( $self->{_ua_timeout} > 0 ) {
        $self->{_ua}->timeout( $self->{_ua_timeout} );
    }

    my %parameters = ( %{ $self->{default_params} }, %params );

    my $req = HTTP::Request->new(
        GET => sprintf( "%s?%s",
            $self->{_url}, $self->_generate_query_string( \%parameters ) )
    );
    my $res = $self->{_ua}->request($req);
    if ( $res->is_success ) {
        if ( $self->{_format} eq 'hash' ) {
            return $self->_xml_string_to_hash( \$res->content );
        }
        elsif ( $self->{_format} eq 'xml' ) {
            return $res->content;
        }
    }
    else {
        die $res->status_line;
    }

    return;

}

sub _generate_query_string {
    my ( $self, $parameters ) = @_;

    return join "&",
        map { sprintf( "%s=%s", $_, uri_escape( $parameters->{$_} ) ) }
        keys %$parameters;

}

sub _init {
    my ($self) = @_;

    #this should be implemented in the subclasses

    return;
}

sub _xml_string_to_hash {
    my ( $self, $xml_string_ref ) = @_;

    return $self->{_xml}->XMLin($$xml_string_ref);
}

sub _tld_list_to_ext_param {
    my ( $self, @tlds ) = @_;

    return join( '|', ( map { uc($_) } @tlds ) );
}

sub _res_status_lookup {
    my ( $self, $status_line, $extensions ) = @_;

    my @status_items = split //, $status_line;
    my @extensions = map { lc($_) } split /\|/, $extensions;

    my %mapping;
    @mapping{@extensions} = @status_items;

    return \%mapping;
}

1;
__END__

=head1 SEE ALSO

L<WWW::DomainTools::SearchEngine>
L<WWW::DomainTools::NameSpinner>

=head1 BUGS

Please report bugs using the CPAN Request Tracker at L<http://rt.cpan.org/>

=head1 AUTHOR

David Bartle <captindave@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

I am not affiliated with Domain Tools or Name Intelligence.  The use of
their API's are governed by their own terms of service:

http://www.domaintools.com/members/tos.html

The full text of the license can be found in the
LICENSE file included with this module.

=cut
