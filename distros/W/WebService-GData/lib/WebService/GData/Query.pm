package WebService::GData::Query;
use WebService::GData;
use base 'WebService::GData';

use WebService::GData::Error;
use WebService::GData::Constants qw(:all);

#specify default parameters

our $VERSION = 0.0205;

*disable = *WebService::GData::disable;

sub __init {
    my $this = shift;

    $this->{_query} = {
        'v'         => GDATA_MINIMUM_VERSION,
        alt         => JSON,
        prettyprint => FALSE,
        strict      => TRUE,
    };
    return $this;
}


sub set_from_query_string {
	my ($this,$uri) = @_;
	my (undef,$query_string) = split(/\?/,$uri);
	
	my @elements = split(/&/,$query_string);
	
	foreach my $element (@elements){
		my ($param,$val)= split(/=/,$element);
	   $this->_set_query($param,$val);
	}
}


sub install_sub {
    my $subname = shift;
    my $field   = $subname;
    $field =~ s/_/-/g;
    return sub {
        my ( $this, $val ) = @_;

        if ( my $code = $this->can( '_' . $field . '_is_valid' ) ) {

            my $res = &$code($val);
            if ($res) {
                return $this->_set_query( $field, $val );
            }
            else {
                die new WebService::GData::Error( 'invalid_parameter_type',
                    $subname . '() did not get a proper value.' );
            }
        }
        return $this->_set_query( $field, $val );

      }
}

sub install {
    my $parameters = shift;
    my $package    = caller;
    WebService::GData::install_in_package( $parameters, \&install_sub,
        $package );
}

install(
    [
        'strict',        'fields', 'v',           'alt',
        'prettyprint',   'author', 'updated_min', 'updated_max',
        'published_min', 'published_max'
    ]
);

#move this else where...

sub _is_date_format {
    my $val = shift;
    return $val
      if ( $val =~
        m/[0-9]{4}-[0-9]{2}-[0-9]{3}T[0-9]{2}:[0-9]{2}:[0-9]{2}-[0-9]{2}:00/ );
}

sub _is_boolean {
    my $val = shift;
    return $val if ( $val eq FALSE || $val eq TRUE );
}

sub _v_is_valid {
    my $val = shift;
    return $val if ( $val >= GDATA_MINIMUM_VERSION );
}

sub _published_max_is_valid {
    return _is_date_format( shift() );
}

sub _published_min_is_valid {
    return _is_date_format( shift() );
}

sub _updated_max_is_valid {
    return _is_date_format( shift() );
}

sub _updated_min_is_valid {
    return _is_date_format( shift() );
}

sub _prettyprint_is_valid {
    return _is_boolean( shift() );
}

sub _strict_is_valid {
    return _is_boolean( shift() );
}

sub start_index {
    my ( $this, $start ) = @_;
    return $this->_set_query( 'start-index', ( int($start) < 1 ) ? 1 : $start );
}

sub max_results {
    my ( $this, $max ) = @_;
    return $this->_set_query( 'max-results', ( int($max) < 1 ) ? 1 : $max );
}

sub limit {
    my ( $this, $max, $offset ) = @_;
    $this->start_index($offset);
    return $this->max_results($max);
}

sub q {
    my ( $this, $search ) = @_;
    $search =~ s/\s+AND\s+/ /g;
    return $this->_set_query( 'q', $search );
}

sub category {
    my ( $this, $category ) = @_;
    $category =~ s/\s+OR\s+/|/g;
    $category =~ s/\s+AND\s+/,/g;
    $category =~ s/\s{1}/,/g;
    return $this->_set_query( 'category', $category );
}

sub _set_query {
    my ( $this, $key, $val ) = @_;
    $this->{_query}->{$key} = $val;
    return $this;
}

sub get {
    my ( $this, $key ) = @_;
    return $this->{_query}->{$key};
}

sub to_query_string {
    my $this  = shift;
    my @query = ();
    while ( my ( $field, $value ) = each %{ $this->{_query} } ) {
        push @query, $field . '=' . _urlencode($value) if ( defined $value );
        push @query, $field if ( !defined $value );
    }
    return '?' . join '&', @query;
}

sub _urlencode {
    my ($string) = shift;
    $string =~ s/(\W)/"%" . unpack("H2", $1)/ge;
    return $string;
}

sub __to_string {
    return shift()->to_query_string();
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Query - implements the core query parameters available in the google data API v2.

=head1 SYNOPSIS

    use WebService::GData::Query;
    use WebService::GData::Constants qw(:format :query :general);

    my $query = new WebService::GData::Query();

    $query->to_query_string();# by default:?alt=json&v=2&prettyprint=false&strict=true

    #?alt=jsonc&v=2&prettyprint=false&strict=true&start-index=1&max-results=10
    $query->alt('jsonc')->limit(10,1)->to_query_string();

    print $query->get('alt');#jsonc

    $query->v(1);#throw an error as only 2 is ok.
    $query->prettyprint(1);#throw an error as only 'true' or 'false' is possible.

    #use constants where you can 

    $query->prettyprint(TRUE);

    $query->alt('json-c');#this is wrong

    $query->alt(JSONC);#ok!


=head1 DESCRIPTION

I<inherits from L<WebService::GData>>.

Google data API supports searching different services via a common set of parameters.
Unfortunately, some services only handles a subset of this "core" parameters...
You should read the service Query documentation to know exactly the available parameters.
This package also implements some helpers functions to shorten up a little the parameter settings.

In order to avoid to send uncorrect parameter values, the package checks for their validity
and will throw a L<WebService::GData::Error> object containing 'invalid_parameter_type' as the C<code> and the name of the function as the C<content>.
Checking the data before sending a request will avoid unnecessary network transactions and
reduce the risk of reaching quota limitations in use for the service you are querying.

L<WebService::GData::Constants> contains predefined value that you can use to set the parameters.
Using the constants can avoid typo errors or unnecessary code change when an update is available with a new value.


=head2 CONSTRUCTOR

=head3 new

=over

Creates a basic query instance.
The following parameters are set by default:

=over 4

=item C<alt         = WebService::GData::Constants::JSON>

=item C<v           = WebService::GData::Constants::GDATA_MINIMUM_VERSION>

=item C<prettyprint = WebService::GData::Constants::FALSE>

=item C<strict      = WebService::GData::Constants::TRUE>

=back


B<Parameters>

=over 4

=item C<none>

=back

B<Returns> 

=over 4

=item C<WebService::GData::Query>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->to_query_string();# by default:?alt=json&v=2&prettyprint=false&strict=true

=back

=head2 GENERAL METHODS


=head3 get

=over

Returns the parameter specified.

The function uses the underscore nomenclature where the parameters use the hyphen nomenclature.
You should change all the underscore to hyphen when accessing the value.

B<Parameters>

=over 4

=item C<parameter_name:Scalar>

=back

I<Return> 

=over 4

=item C<parameter_value::Scalar>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->get('alt');#json

    $query->get('published_min');#does not work...

    $query->get('published-min');#ok!

=back

=head3 to_query_string

=over

Concatene each parameter/value pair into a  query string.
This function is also called in a string overload context. "$instance" is the same as $instance->to_query_string();

B<Parameters>

=over 4

=item C<none>

=back

B<Returns> 

=over 4 

=item C<query_string:Scalar>

=back


Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->to_query_string();#?alt=json&v=2&prettyprint=false&strict=true
    "$query";                 #?alt=json&v=2&prettyprint=false&strict=true
    print $query;             #?alt=json&v=2&prettyprint=false&strict=true

=back


=head2 PARAMETER METHODS

All the methods that set a parameter return the instance so that you can chain the function calls.

Example:

    $query->alt(JSONC)->limit(10,1)->strict(TRUE)->prettyprint(FALSE)->to_query_string();


The following setters are available:

=head3 strict

=over

If set to true (default),  setting a parameter not supported by a service will fail the request.

B<Parameters>

=over 4

=item C<true_or_false:Scalar> - The value can be L<WebService::Gdata::Constants>::TRUE or L<WebService::Gdata::Constants>::FALSE

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

B<Throws> 

=over 4

=item C<WebService::GData::Error>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->strict('true');

    $query->strict(TRUE);#better

    $query->strict('hello');#die


=back


=head3 fields

=over

Allows you to query partial data. 
This is a Google data experimental feature as of this version.

B<Parameters>

=over 4

=item C<partial_query:Scalar>

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back


Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->fields('id,entry(author)');#only get the id and the author in the entry tag

B<See Also>

The reference for the partial queries:

L<http://code.google.com/intl/en/apis/gdata/docs/2.0/reference.html#PartialResponse>

=back

=head3 v

=over

Set the google Data API version number. Default to WebService::GData::Constants::GDATA_MINIMUM_VERSION. 
You shoud not set this unless you know what you do.

=back

=head3 alt

=over

Specify the response format used. Default to WebService::GData::Constants::JSON.
You shoud not set this unless you know what you do.

=back


=head3 prettyprint

=over

If set to true (default false),the result from the service will contain indentation. 

B<Parameters>

=over 4

=item C<true_or_false:Scalar> (Default: L<WebService::Gdata::Constants>::FALSE)

The value can be L<WebService::Gdata::Constants>::TRUE or L<WebService::Gdata::Constants>::FALSE

=back

B<Returns>

=over 4

=item C<WebService::GData::Query>

=back

B<Throws> 

=over 4

=item C<WebService::GData::Error>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->prettyprint('true');

    $query->prettyprint(TRUE);#better

    $query->prettyprint('hello');#die

=back

=head3 author

=over

Specify the author of the contents you want to retrieve.
Each service derives the meaning for their own feed.

B<Parameters>

=over 4

=item C<author_name:Scalar> 

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->author('GoogleDeveloper');

=back

=head3 updated_min

=over

Retrieve the contents which update date is a minimum equal to the one specified (inclusive).
Note that you should retrieve the value as 'updated-min' when used with L<WebService::GData::Query>::get().

B<Parameters>

=over 4

=item C<date:Scalar> - Format:2005-08-09T10:57:00-08:00

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

B<Throws> 

=over 4

=item C<WebService::GData::Error>

=back

=back

=head3 updated_max 

=over

Retrieve the contents which update date is at maximum equal to the one specified (exclusive).
Note that you should retrieve the value as 'updated-max' when used with L<WebService::GData::Query>::get().

B<Parameters>

=over 4

=item C<date:Scalar> - Format:2005-08-09T10:57:00-08:00

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

B<Throws> 

=over 4

=item C<WebService::GData::Error>

=back

=back

=head3 published_min 

=over

Retrieve the contents which publish date is a minimum equal to the one specified (inclusive).
Note that you should retrieve the value as 'published-min' when used with L<WebService::GData::Query>::get().

B<Parameters>

=over 4

=item C<date:Scalar> - Format:2005-08-09T10:57:00-08:00

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

B<Throws> 

=over 4

=item C<WebService::GData::Error>

=back

=back

=head3 published_max 

=over

Retrieve the contents which publish date is a maximum equal to the one specified (exclusive).
Note that you should retrieve the value as 'published-max' when used with L<WebService::GData::Query>::get().

B<Parameters>

=over 4

=item C<date:Scalar> - Format:2005-08-09T10:57:00-08:00

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

B<Throws> 

=over 4

=item C<WebService::GData::Error>

=back

=back

=head3 start_index 

=over

Retrieve the contents starting from a certain result. Start from 1.
Setting 0 will revert to 1.
Note that you should retrieve the value as 'start-index' when used with L<WebService::GData::Query>::get().

B<Parameters>

=over 4

=item C<index_number:Int> - Setting the number to 0 or anything but an integer will coerce it to 1.

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

=back

=head3 max_results 

=over

Retrieve the contents up to a certain amount of entry (Most of the services set it to 25 by default).

Note that you should retrieve the value as 'max-results' when used with L<WebService::GData::Query>::get().

B<Parameters>

=over 4

=item C<index_number:Int> - Setting the number to 0 or anything but an integer will coerce it to 1.

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

=back

=head3 limit

=over

An extension that allows you to set start_index and max_results in one method call:
get('limit') will return undef.
Follow the same coercicion logic of start_index and max_results.

B<Parameters>

=over 4

=item C<max_results:Int> - The number of result you want to get back

=item C<start_index:Int> - The offset from where to start

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->limit(10,5);
    #equivalent to
    $query->max_results(10)->start_index(5);	

=back

=head3 q

=over

Insensitive freewords search where:

=over 4

=item * words in quotation means exact match:"word1 word2"

=item * words separated by a space means AND:word1 word2

=item * words prefixed with an hyphen means NOT(containing):-word1

=back

B<Parameters>

=over 4

=item C<search:Scalar>

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

Example:

    use WebService::GData::Query;

    
    my $query = new WebService::GData::Query();

    $query->q('"exact phrase" snowbaord sports -ski');

=back


=head3 category

=over

Allow to narrow down the result to specifics categories.

=over

=item * words separated by a comma(,) means AND:word1,word2

=item * words separated by a pipe(|) means OR:word1|word2

=item * words prefixed by an hyphen(-) are disgarded:-word1

=back

B<Parameters>

=over 4

=item C<category:Scalar>

=back

B<Returns> 

=over 4 

=item C<WebService::GData::Query>

=back

Example:

    use WebService::GData::Query;

    my $query = new WebService::GData::Query();

    $query->category('-Shows,Entertainment|Sports');

=back

=head1  SEE ALSO

Documentation of the parameters:

L<http://code.google.com/intl/en/apis/gdata/docs/2.0/reference.html#Queries>


=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
