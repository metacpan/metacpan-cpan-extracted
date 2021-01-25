# NAME

WebService::Hexonet::Connector::ResponseTemplateManager - Library to manage response templates.

# SYNOPSIS

This module is internally used by the WebService::Hexonet::Connector::APIClient module as described below.
To be used in the way:

    # get (singleton) instance of this class
    $rtm = WebService::Hexonet::Connector::ResponseTemplateManager->getIstance();

    # add a template
    $rtm->addTemplate('mytemplate ID', "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n");

        # get a template (instance of ResponseTemplate)
        $rtm->getTemplate('mytemplate ID');

etc. See the documented methods for deeper information.

# DESCRIPTION

This library can be used to manage hardcoded API responses (for any reason).
In general useful for automated tests where you need to work with hardcoded API responses.
Also used by [WebService::Hexonet::Connector::APIClient](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AAPIClient) module for standard error cases.

## Methods

- `getInstance`

    Returns the singleton instance of [WebService::Hexonet::Connector::ResponseTemplateManager](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplateManager).

- `generateTemplate( $code, $description )`

    Returns a plain-text API response for the specified response Code $code
    and the specified response description $description as string.
    To be used in case you need custom API responses to cover specific cases
    in your implementation e.g. error cases of the HTTP communication.
    Returns the current [WebService::Hexonet::Connector::ResponseTemplateManager](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplateManager) instance in use for method chaining.

- `addTemplate( $id, $plain)`

    Add a response to the template container.
    Specify the template id by $id and the plain-text response by $plain.
    Returns the current [WebService::Hexonet::Connector::ResponseTemplateManager](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplateManager) instance in use for method chaining.

- `getTemplate( $id )`

    Get a response template from template container.
    Returns an instance of [WebService::Hexonet::Connector::ResponseTemplate](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplate).
    If not found, an error will be returned also as such an instance.

- `getTemplates`

    Get all available response templates in hash notation.
    Where the hash key represents the template id and where the hash value is an
    instance of [WebService::Hexonet::Connector::ResponseTemplate](https://metacpan.org/pod/WebService%3A%3AHexonet%3A%3AConnector%3A%3AResponseTemplate).
    Returns a hash.

- `hasTemplate( $id )`

    Checks if the template container contains a template with the specified template id $id.
    Returns boolean 0 or 1.

- `isTemplateMatchHash( $hash, $id )`

    Checks if the given API response in hash format specified by $hash matches the specified
    response template $id in response code and response description.
    It doesn't compare PROPERTY data!
    Returns boolean 0 or 1.

- `isTemplateMatchPlain( $plain, $id )`

    Checks if the given API response in plain-text format specified by $plain matches the specified
    response template $id in response code and response description.
    It doesn't compare PROPERTY data!
    Internally this method parses that plain-text response into hash format and uses method
    isTemplateMatchHash to perform the check.
    Returns boolean 0 or 1.

# LICENSE AND COPYRIGHT

This program is licensed under the [MIT License](https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE).

# AUTHOR

[HEXONET GmbH](https://www.hexonet.net)
