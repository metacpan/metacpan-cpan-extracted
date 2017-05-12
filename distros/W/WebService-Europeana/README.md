# NAME

WebService::Europeana - access the API of europeana.eu

# VERSION

This document describes WebService::Europeana version 0.0.2

# SYNOPSIS

    use WebService::Europeana;

    my $Europeana = WebService::Europeana->new(wskey => 'API_KEY');
    my $result = $Europeana->search(query => "Europe", 
                                    reusability=> 'open', 
                                    rows => 3);

    foreach my $item (@{$result->{items}}){
      print $item->{title}->[0]."\n";
    }

# DESCRIPTION

This module is a wrapper around the REST API of Europeana (cf. [http://labs.europeana.eu/api/introduction](http://labs.europeana.eu/api/introduction)). At the moment only a basic search function is implemented.

# CONSTRUCTOR

    $Europeana = WebService::Europeana->new(wskey=>'API_KEY')

- wskey

    API key, can be requested at &lt;http://labs.europeana.eu/api/registration>

# METHODS

## search

for further explanation of the possible parameters please refer to
[http://labs.europeana.eu/api/search](http://labs.europeana.eu/api/search)

- query	

    The search term(s).

- profile	

    Profile parameter controls the format and richness of the response. See the possible values of the profile parameter.

- reusability  

    Filter by copyright status. Possible values are open, restricted or permission.

- rows 

    The number of records to return. Maximum is 100. Defaults to 12. 

- start  

    The item in the search results to start with when using cursor-based pagination. The first item is 1. Defaults to 1. 

- qf

    Facet filtering query. This parameter can be a simple string e.g. `qf=>"TYPE:IMAGE"` or an array reference, e.g. `qf=>["TYPE:IMAGE","LANGUAGE:de"]`

# LOGGING

This module uses the [Log::Any](https://metacpan.org/pod/Log::Any)-Framework. To get logging output use [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter) along with a destination-specific subclass.

For example, to send output to a file via [Log::Any::Adapter::File](https://metacpan.org/pod/Log::Any::Adapter::File), your application could do this:

    use WebService::Europeana
    use Log::Any::Adapter ('File', '/path/to/file.log');

    my $Europeana = WebService::Europeana->new(wskey=>'API_KEY');
       $results = $Europeana->search(query=>'Europe');

# BUGS AND LIMITATIONS

At the moment just a basic subset of the search parameters is implemented.

No bugs have been reported.

Please report any bugs or feature requests to
`bug-www-europeana@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org).

# AUTHOR

Peter Mayr  `<pmayr@cpan.org>`

# LICENCE AND COPYRIGHT

Copyright (c) 2015, Peter Mayr `<pmayr@cpan.org>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
