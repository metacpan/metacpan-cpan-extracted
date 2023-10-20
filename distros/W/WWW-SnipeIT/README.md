# NAME

WWW::SnipeIT - API Access to Snipe-IT

# SYNOPSIS

    use WWW::SnipeIT;

    my $snipeIT = SnipeIT->new( endpoint => 'http://<mysnipeip>/api/v1/', accessToken => 'mylongapikey');

    my $snipe = $snipeIT->snipe();
    my $result = $snipe->{'hardware'}->getHardwareIDByAssetTag(123);
    say $result;


    # More Examples
    my $updateBody = '{"name":"Fruit Computer","notes":"Apple Computer"}';
    my $searchBody = '{"name":"name","element":"text","field_values":"3Com"}';
    my $assetTag = 123;
    my $hardwareID = 321;
    my $user = "Scott";
    my $fieldName = "";
    my $fieldValue = "3Com";
    my $assetName = "3Com";
    my $searchString = "ChromeBook";
    my $categoryID = 3;
    my $serialNumber = "abc1234";

    warn Dumper($snipe->{'hardware'}->getHardwareIDByAssetTag($assetTag));
    warn Dumper($snipe->{'hardware'}->getHardwareByAssetTag($assetTag));
    warn Dumper($snipe->{'hardware'}->getAssetTagByHardwareID($hardwareID));
    warn Dumper($snipe->{'hardware'}->updateAssetByHardwareID($hardwareID, $updateBody));
    warn Dumper($snipe->{'hardware'}->updateAssetByAssetTag($assetTag, $updateBody));
    warn Dumper($snipe->{'hardware'}->getHardwareByCustomField($fieldName, $user));
    warn Dumper($snipe->{'hardware'}->getHardwareBySerialNumber($serialNumber));


    warn Dumper($snipe->{'hardware'}->getHistoryByHardwareID($hardwareID));
    warn Dumper($snipe->{'hardware'}->getHistoryByAssetTag($assetTag));
    warn Dumper($snipe->{'hardware'}->searchHardware($searchString));

    warn Dumper($snipe->{'hardware'}->getHardwareByCategory($categoryID));

# DESCRIPTION

WWW::SnipeIT is a perl module for accessing the API. It doesnt have all the api features just enough for what I needed.

# AUTHOR

Scott <scotth@cpan.org>

# COPYRIGHT

Copyright 2022- Scott

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
