#!/usr/bin/env perl

use strictures;
use Modern::Perl;
use WebService::GoogleAPI::Client;
use Data::Dumper;
################################  SOME GENERIC HELPER UTILITY SUBS   ###################


=head2 C<check_api_endpoint_and_user_scopes>

describes the api-endpoing including parameters and whether
the Client user has access scopes.

=cut
sub check_api_endpoint_and_user_scopes ## TODO - Doesn't actually do waht it says here yet
{
    my ( $client, $api_endpoint  ) = @_;
  say '-' x 40;
  my $has_scope = $client->has_scope_to_access_api_endpoint( $api_endpoint );
    my $api_spec = $client->get_api_discovery_for_api_id( $api_endpoint  ); ## only for base url
    my $base_url = $api_spec->{baseUrl};
    # print pp $api_spec;exit;
    
    my $api_method_details = $client->extract_method_discovery_detail_from_api_spec( $api_endpoint );
    #print pp $api_method_details;exit;

    ## Construct summary textual display for the endpoint
    $api_method_details->{scopes} = [] unless defined $api_method_details->{scopes}; ## dummy if none
    my $scopes_txt = join("\n", @{$api_method_details->{scopes}} );
    $api_method_details->{parameterOrder} = [] unless defined $api_method_details->{parameterOrder}; ## dummy if none
    my $param_order_txt = join(",", @{$api_method_details->{parameterOrder}} );

    ## parameters 
    my $parameters_txt = '';
    if ( $client->{debug} == 0 )
    {     ## SHORT VERSION - just the names
      $parameters_txt = join("\n", sort keys %{$api_method_details->{parameters}} );
    }
    else  ## LONG VERSION - name, description, location, type
    {
        foreach my $param ( sort keys %{$api_method_details->{parameters}}  )
        {
            $parameters_txt .= "  $param\n";
            #say Dumper $api_method_details->{parameters}{$param}; exit;
            my $text_table = Text::Table->new();
            foreach my $field (qw/description type  location required/) 
            {
                if (defined $api_method_details->{parameters}{$param}{$field} )
                {
                    $text_table->add( '     ', $field, "'$api_method_details->{parameters}{$param}{$field}'"  ) ;
                }
            }
            $parameters_txt .= $text_table . "\n";
        }
    }

    foreach my $expected_field ( qw/id description httpMethod path / )
    {
        if ( not defined $api_method_details->{$expected_field} )
        {
            print Dumper  $api_method_details;

            croak("missing $expected_field");
            $api_method_details->{$expected_field} = '';
        }
    }

    print qq{
# $api_method_details->{description} - ( $api_method_details->{id} )

METHOD: $api_method_details->{httpMethod}
PATH: $base_url$api_method_details->{path}
REQUIRED PARAMETER ORDER: $param_order_txt


## SCOPES
$scopes_txt    

## PARAMETERS
$parameters_txt
    
    };
    print "User has scope = " . ('NO', 'YES')[$has_scope] . "\n";
  say '-' x 40;
}
################################################################



################################################################
sub display_api_summary_and_return_versioned_api_string
{
    my ( $client, $api_name, $version  ) = @_;
    $api_name =~ s/\..*$//smg;
    if ($api_name =~ /^([^:]*):(.*)$/xsm )
    {
        $api_name = $1;
        $version  = $2;
    }
    #say "api $api_name version $version";

    my $new_hash = {}; ## index by 'api:version' ( id )
    my $preferred_api_name = ''; ## this is set to the preferred version if described 
    my $text_table = Text::Table->new();

    foreach my $api ( @{ %{$client->discover_all()}{items} } )
    {
        # convert JSON::PP::Boolean to true|false strings
        if ( defined $api->{preferred} )
        {
            $api->{preferred}  = "$api->{preferred}";
            $api->{preferred}  = $api->{preferred} eq '0' ? 'no' : 'YES';
            
            if ( $preferred_api_name eq '' && $api->{preferred} eq 'YES' )
            {
                if (  $api->{id} =~ /$api_name/mx )
                {
                    $preferred_api_name = $api->{id} ;
                    $new_hash->{ $api_name } = $api;
                }
            }
        }
        #$new_hash->{ $api->{name} } = $api unless defined $new_hash->{ $api->{name} };
        $new_hash->{ $api->{id} } = $api;
        if (  $api->{name} =~ /$api_name/xm  )
        {
            foreach my $field (qw/title version preferred id  description discoveryRestUrl documentationLink name/)
            {
                #say qq{$field = $api->{$field}};
                $text_table->add( $field, $api->{$field}  );
            }
            $text_table->add(' ',' ');
        }
    }

    
    say "## Google $new_hash->{$api_name}{title} ( $api_name ) SUMMARY\n\n";
    say $text_table;
    
    if ( defined $version)
    {
        $api_name = "$api_name:$version";
    }
    else 
    {
        $api_name = $preferred_api_name;
    }
    say Dumper $new_hash->{$api_name}  if $client->{debug}; 
    
    return $api_name;
}

1;