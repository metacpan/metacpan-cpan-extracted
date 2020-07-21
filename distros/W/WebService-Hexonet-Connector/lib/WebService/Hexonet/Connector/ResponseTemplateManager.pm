package WebService::Hexonet::Connector::ResponseTemplateManager;

use 5.030;
use strict;
use warnings;
use WebService::Hexonet::Connector::ResponseTemplate;
use WebService::Hexonet::Connector::ResponseParser;

use version 0.9917; our $VERSION = version->declare('v2.10.0');

my $instance = undef;


sub getInstance {
    if ( !defined $instance ) {
        my $self = { templates => {} };
        $instance = bless $self, shift;
        $instance->addTemplate( '404',          $instance->generateTemplate( '421', 'Page not found' ) );
        $instance->addTemplate( '500',          $instance->generateTemplate( '500', 'Internal server error' ) );
        $instance->addTemplate( 'empty',        $instance->generateTemplate( '423', 'Empty API response. Probably unreachable API end point {CONNECTION_URL}' ) );
        $instance->addTemplate( 'error',        $instance->generateTemplate( '421', 'Command failed due to server error. Client should try again' ) );
        $instance->addTemplate( 'expired',      $instance->generateTemplate( '530', 'SESSION NOT FOUND' ) );
        $instance->addTemplate( 'httperror',    $instance->generateTemplate( '421', 'Command failed due to HTTP communication error' ) );
        $instance->addTemplate( 'invalid',      $instance->generateTemplate( '423', 'Invalid API response. Contact Support' ) );
        $instance->addTemplate( 'unauthorized', $instance->generateTemplate( '530', 'Unauthorized' ) );
    }
    return $instance;
}


sub generateTemplate {
    my ( $self, $code, $description ) = @_;
    return "[RESPONSE]\r\nCODE=${code}\r\nDESCRIPTION=${description}\r\nEOF\r\n";
}


sub addTemplate {
    my ( $self, $id, $plain ) = @_;
    $self->{templates}->{$id} = $plain;
    return $instance;
}


sub getTemplate {
    my ( $self, $id ) = @_;
    my $plain;
    if ( $self->hasTemplate($id) ) {
        $plain = $self->{templates}->{$id};
    } else {
        $plain = $self->generateTemplate( '500', 'Response Template not found' );
    }
    return WebService::Hexonet::Connector::ResponseTemplate->new($plain);
}


sub getTemplates {
    my $self = shift;
    my $tmp  = {};
    my $tpls = $self->{templates};
    foreach my $key ( keys %{$tpls} ) {
        $tmp->{$key} = WebService::Hexonet::Connector::ResponseTemplate->new( $tpls->{$key} );
    }
    return $tmp;
}


sub hasTemplate {
    my ( $self, $id ) = @_;
    return defined $self->{templates}->{$id};
}


sub isTemplateMatchHash {
    my ( $self, $tpl2, $id ) = @_;
    my $tpl = $self->getTemplate($id);
    my $h   = $tpl->getHash();
    return ( $h->{CODE} eq $tpl2->{CODE} ) && ( $h->{DESCRIPTION} eq $tpl2->{DESCRIPTION} );
}


sub isTemplateMatchPlain {
    my ( $self, $plain, $id ) = @_;
    my $h = WebService::Hexonet::Connector::ResponseParser::parse($plain);
    return $self->isTemplateMatchHash( $h, $id );
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::ResponseTemplateManager - Library to manage response templates.

=head1 SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::APIClient module as described below.
To be used in the way:

    # get (singleton) instance of this class
    $rtm = WebService::Hexonet::Connector::ResponseTemplateManager->getIstance();

    # add a template
    $rtm->addTemplate('mytemplate ID', "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n");

	# get a template (instance of ResponseTemplate)
	$rtm->getTemplate('mytemplate ID');

etc. See the documented methods for deeper information.

=head1 DESCRIPTION

This library can be used to manage hardcoded API responses (for any reason).
In general useful for automated tests where you need to work with hardcoded API responses.
Also used by L<WebService::Hexonet::Connector::APIClient|WebService::Hexonet::Connector::APIClient> module for standard error cases.


=head2 Methods

=over

=item C<getInstance>

Returns the singleton instance of L<WebService::Hexonet::Connector::ResponseTemplateManager|WebService::Hexonet::Connector::ResponseTemplateManager>.

=item C<generateTemplate( $code, $description )>

Returns a plain-text API response for the specified response Code $code
and the specified response description $description as string.
To be used in case you need custom API responses to cover specific cases
in your implementation e.g. error cases of the HTTP communication.
Returns the current L<WebService::Hexonet::Connector::ResponseTemplateManager|WebService::Hexonet::Connector::ResponseTemplateManager> instance in use for method chaining.

=item C<addTemplate( $id, $plain)>

Add a response to the template container.
Specify the template id by $id and the plain-text response by $plain.
Returns the current L<WebService::Hexonet::Connector::ResponseTemplateManager|WebService::Hexonet::Connector::ResponseTemplateManager> instance in use for method chaining.

=item C<getTemplate( $id )>

Get a response template from template container.
Returns an instance of L<WebService::Hexonet::Connector::ResponseTemplate|WebService::Hexonet::Connector::ResponseTemplate>.
If not found, an error will be returned also as such an instance.

=item C<getTemplates>

Get all available response templates in hash notation.
Where the hash key represents the template id and where the hash value is an
instance of L<WebService::Hexonet::Connector::ResponseTemplate|WebService::Hexonet::Connector::ResponseTemplate>.
Returns a hash.

=item C<hasTemplate( $id )>

Checks if the template container contains a template with the specified template id $id.
Returns boolean 0 or 1.

=item C<isTemplateMatchHash( $hash, $id )>

Checks if the given API response in hash format specified by $hash matches the specified
response template $id in response code and response description.
It doesn't compare PROPERTY data!
Returns boolean 0 or 1.

=item C<isTemplateMatchPlain( $plain, $id )>

Checks if the given API response in plain-text format specified by $plain matches the specified
response template $id in response code and response description.
It doesn't compare PROPERTY data!
Internally this method parses that plain-text response into hash format and uses method
isTemplateMatchHash to perform the check.
Returns boolean 0 or 1.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
