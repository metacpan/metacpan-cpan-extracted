package WebService::GData::YouTube::Query;
use WebService::GData::Query;
use base 'WebService::GData::Query';
our $VERSION  = 0.01_02;


WebService::GData::Query::disable([qw(updated_min updated_max published_min published_max)]);

WebService::GData::Query::install([qw(key uploader format time restriction orderby lr location_radius location inline lang fmt)]);

	sub safe_search {
		my ($this,$val)=@_;
		return $this->_set_query('safeSearch',$val);
	}

	sub location_plottable {
		my ($this,$location)=@_;
		return $this->_set_query('location',$location.'!');	
	}

	#need to better handle the caption...
	sub caption {
		my ($this,$val)=@_;
		return $this->_set_query('caption',$val);
	}

"The earth is blue like an orange.";

__END__

=pod

=head1 NAME

WebService::GData::YouTube::Query - implements the core query parameters available in YouTube Service API v2.

=head1 SYNOPSIS

    use WebService::GData::YouTube::Query;
	use WebService::GData::Constants qw(:all);

    #create an object that only has read access
    my $query = new WebService::GData::YouTube::Query();

    $query->safe_search('none')->orderby('rating')->caption('true')->time('today');



=head1 DESCRIPTION

inherits from L<WebService::GData::Query>.

YouTube service supports additional parameters.

In order to avoid to send uncorrect parameter values, the package checks for their validity

and will throw a L<WebService::GData::Error> object containing 'invalid_parameter_type' as the C<code> and the name of the function as the C<content>.

Checking the data before hands, will avoid unnecessary network transactions and

reduce the risk of reaching quota limitations in use for the service you are querying.

L<WebService::GData::Constants> and L<WebService::GData::YouTube::Constants> contains predefined value that you can use to set the parameters.

Using the constants can avoid typo errors or unnecessary code change when an update is available with a new value.


=head2 CONSTRUCTOR

=head3 new

=over

Creates a basic query instance.

The following parameters are set by default:

=over

=item C<alt= WebService::GData::Constants::JSON>

=item C<v= WebService::GData::Constants::GDATA_MINIMUM_VERSION>

=item C<prettyprint= WebService::GData::Constants::FALSE>

=item C<strict= WebService::GData::Constants::TRUE>

=back


I<Parameters>:

=over

=item C<none>

=back

I<Return>:C<WebService::GData::YouTube::Query>

=back

Example:

	use WebService::GData::YouTube::Query;

    #create an object that only has read access
	my $query = new WebService::GData::YouTube::Query();

	$query->to_query_string();# by default:?alt=json&v=2&prettyprint=false&strict=true

=back

=head2 INHERITED METHODS

All the following methods are inherited from L<WebService::GData::Query>.

=head3 get

=head3 to_query_string

=head3 strict

=head3 fields

=head3 v

=head3 alt

=head3 prettyprint

=head3 author

=head3 start_index 

=head3 max_results 

=head3 limit

=head3 q

=head3 category

=head2 API METHODS

These methods represents YouTube related parameters

=head3 key 

=head2 SEARCH METHODS

=head3 caption

=head3 uploader 

=head3 format 

=head3 time 

=head3 restriction 

=head3 orderby 

=head3 lr 

=head3 inline 

=head3 lang 

=head3 fmt

=head3 safe_search

=head3 location

=head3 location_radius 

=head3 location_plottable


=head2 DISABLED METHODS

The following methods are inherited but not available to the YouTube Service.

Calling these methods will just return the instance and will not set them.

=head3 updated_min

=head3 updated_max 

=head3 published_min 

=head3 published_max 



=head1  SEE ALSO

Documentation of the parameters:

L<http://code.google.com/intl/en/apis/youtube/2.0/reference.html#Query_parameter_definitions>

=head1  CONFIGURATION AND ENVIRONMENT

none


=head1  DEPENDENCIES

none

=head1  INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut