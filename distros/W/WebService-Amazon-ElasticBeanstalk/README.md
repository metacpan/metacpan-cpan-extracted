# NAME

WebService::Amazon::ElasticBeanstalk - Basic interface to Amazon ElasticBeanstalk

# VERSION

Version 0.0.7

# SYNOPSIS

This module provides a Perl wrapper around Amazon's 
( [http://aws.amazon.com](http://aws.amazon.com) ) ElasticBeanstalk API.  You will need 
to be an AWS customer with an ID and Secret which has been provided 
access to Elastic Beanstalk.

**Note:** Some parameter validation is purposely lax. The API will 
generally fail when invalid params are passed. The errors may not 
be helpful.

# INTERFACE

## new

Inherited from [WebService::Simple](https://metacpan.org/pod/WebService::Simple), and takes all the same arguments. 
You **must** provide the Amazon required arguments of **id**, and **secret** 
in the param hash:

    my $ebn = WebService::Amazon::ElasticBeanstalk->new( param => { id     => $AWS_ACCESS_KEY_ID,
                                                                    region => 'us-east-1',
                                                                    secret => $AWS_ACCESS_KEY_SECRET } );

- **Parameters**
- id **(required)**

    You can find more information in the AWS docs: 
    [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/CommonParameters.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/CommonParameters.html)

- region _(optional)_ - defaults to us-east-1

    You can find available regions at: 
    [http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk\_region](http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk_region)

- secret **(required)**

    You can find more information in the AWS docs: 
    [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/CommonParameters.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/CommonParameters.html)

## CheckDNSAvailability( CNAMEPrefix => 'the-thing-to-check' )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_CheckDNSAvailability.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_CheckDNSAvailability.html)

- **Parameters**
- CNAMEPrefix **(required scalar)**

    The prefix used when this CNAME is reserved.

- **Returns: result from API call**

## CreateApplication( )

    Unimplimented (for now)

## CreateApplicationVersion( )

    Unimplimented (for now)

## CreateConfigurationTemplate( )

    Unimplimented (for now)

## CreateEnvironment( )

    Unimplimented (for now)

## CreateStorageLocation( )

    Unimplimented (for now)

## DeleteApplication( )

    Unimplimented (for now)

## DeleteApplicationVersion( )

    Unimplimented (for now)

## DeleteConfigurationTemplate( )

    Unimplimented (for now)

## DeleteEnvironmentConfiguration( )

    Unimplimented (for now)

## DescribeApplicationVersions( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeApplicationVersions.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeApplicationVersions.html)

- **Parameters**
- ApplicationName _(optional scalar)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include ones that are associated with the specified application.

- VersionLabels _(optional array)_

    If specified, AWS Elastic Beanstalk restricts the returned versions to only include those with the specified names.

- **Returns: result from API call**

## DescribeApplications( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeApplications.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeApplications.html)

- **Parameters**
- ApplicationNames _(optional array)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.

- **Returns: result from API call**

## DescribeConfigurationOptions( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeConfigurationOptions.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeConfigurationOptions.html)

- **Parameters**
- ApplicationName _(optional string)_

    The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.

- EnvironmentName _(optional string)_

    The name of the environment whose configuration options you want to describe.

- Options _(optional array)_

    If specified, restricts the descriptions to only the specified options.

- SolutionStackName _(optional string)_

    The name of the solution stack whose configuration options you want to describe.

- TemplateName _(optional string)_

    The name of the configuration template whose configuration options you want to describe.

- **Returns: result from API call**

## DescribeConfigurationSettings( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeConfigurationSettings.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeConfigurationSettings.html)

- **Parameters**
- ApplicationName **(required string)**

    The application for the environment or configuration template.

- EnvironmentName I(optional string)

    The name of the environment to describe.

    Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an InvalidParameterCombination error. If you do not specify either, AWS Elastic Beanstalk returns MissingRequiredParameter error.

- TemplateName I(optional string)

    The name of the configuration template to describe.

    Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an InvalidParameterCombination error. If you do not specify either, AWS Elastic Beanstalk returns a MissingRequiredParameter error.

- **Returns: result from API call**

## DescribeEnvironmentResources( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeApplications.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeApplications.html)

- **Parameters**
- ApplicationNames _(optional array)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.

- **Returns: result from API call**

## DescribeEnvironments( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeEnvironments.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeEnvironments.html)

- **Parameters**
- ApplicationName _(optional string)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.

- EnvironmentIds _(optional array)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.

- EnvironmentNames _(optional array)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.

- IncludeDeleted _(optional boolean)_

    Indicates whether to include deleted environments:

    true: Environments that have been deleted after IncludedDeletedBackTo are displayed.
    false: Do not include deleted environments.

- IncludedDeletedBackTo _(optional date)_

    If specified when IncludeDeleted is set to true, then environments deleted after this date are displayed.

- VersionLabel _(optional string)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.

- **Returns: result from API call**

## DescribeEvents( )

Returns list of event descriptions matching criteria up to the last 6 weeks.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_DescribeEvents.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_DescribeEvents.html)

- **Parameters**
- ApplicationNames _(optional array)_

    If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.

- **Returns: result from API call**

## ListAvailableSolutionStacks( )

Returns a list of the available solution stack names.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_ListAvailableSolutionStacks.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_ListAvailableSolutionStacks.html)

- **Parameters**

    **none**

- **Returns: result from API call**

## RebuildEnvironment( )

    Unimplimented (for now)

## RequestEnvironmentInfo( )

    Unimplimented (for now)

## RestartAppServer( )

    Unimplimented (for now)

## RetrieveEnvironmentInfo( )

Retrieves the compiled information from a RequestEnvironmentInfo request.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_RetrieveEnvironmentInfo.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_RetrieveEnvironmentInfo.html)

- **Parameters**
- EnvironmentId _(optional string)_

    The ID of the data's environment.

    If no such environment is found, returns an InvalidParameterValue error.

    Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns MissingRequiredParameter error.

- EnvironmentName _(optional string)_

    The name of the data's environment.

    If no such environment is found, returns an InvalidParameterValue error.

    Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns MissingRequiredParameter error.

    Type: String

    Length constraints: Minimum length of 4. Maximum length of 23.

    Required: No

- InfoType **(required string)**

    The type of information to retrieve.

    Type: String

    Valid Values: tail

    Required: Yes

- **Returns: result from API call**

## SwapEnvironmentCNAMEs( )

    Unimplimented (for now)

## TerminateEnvironment( )

    Unimplimented (for now)

## UpdateApplication( )

    Unimplimented (for now)

## UpdateApplicationVersion( )

    Unimplimented (for now)

## UpdateConfigurationTemplate( )

    Unimplimented (for now)

## UpdateEnvironment( )

    Unimplimented (for now)

## ValidateConfigurationSettings( )

Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.

This action returns a list of messages indicating any errors or warnings associated with the selection of option values.

Refer to [http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API\_ValidateConfigurationSettings.html](http://docs.aws.amazon.com/elasticbeanstalk/latest/APIReference/API_ValidateConfigurationSettings.html)

- **Parameters**
- ApplicationName **(required string)**

    The name of the application that the configuration template or environment belongs to.

- EnvironmentName _(optional string)_

    The name of the environment to validate the settings against.

    Condition: You cannot specify both this and a configuration template name.

- OptionSettings _(required array)_

    A list of the options and desired values to evaluate.

- TemplateName _(optional string)_

    The name of the configuration template to validate the settings against.

    Condition: You cannot specify both this and an environment name.

- **Returns: result from API call**

# AUTHOR

Matthew Cox `<mcox at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-webservice-amazon-elasticbeanstalk at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Amazon-ElasticBeanstalk](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Amazon-ElasticBeanstalk).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Amazon::ElasticBeanstalk

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Amazon-ElasticBeanstalk](http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Amazon-ElasticBeanstalk)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WebService-Amazon-ElasticBeanstalk](http://annocpan.org/dist/WebService-Amazon-ElasticBeanstalk)

- CPAN Ratings

    [http://cpanratings.perl.org/d/WebService-Amazon-ElasticBeanstalk](http://cpanratings.perl.org/d/WebService-Amazon-ElasticBeanstalk)

- Search CPAN

    [http://search.cpan.org/dist/WebService-Amazon-ElasticBeanstalk/](http://search.cpan.org/dist/WebService-Amazon-ElasticBeanstalk/)

# SEE ALSO

perl(1), [WebService::Simple](https://metacpan.org/pod/WebService::Simple), [XML::Simple](https://metacpan.org/pod/XML::Simple), [HTTP::Common::Response](https://metacpan.org/pod/HTTP::Common::Response)

# LICENSE AND COPYRIGHT

Copyright 2015 Matthew Cox.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
