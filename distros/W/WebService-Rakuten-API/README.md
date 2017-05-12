# NAME

WebService::Rakuten::API - It's a Rakuten WebService API.

# SYNOPSIS

    use WebService::Rakuten::API;

    my $rakuten = WebService::Rakuten::API->new(
         appid => __YOURAPI__
    );
     
    my $items = $rakuten->ichiba({keyword => '遊戯王',format => 'json'});

    print $items->{Items}->[0]->{Item}->{itemName};  

# DESCRIPTION

WebService::Rakuten::API is API that is descripting RakutenWebServiceAPI.

# LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sue7ga <sue77ga@gmail.com>
