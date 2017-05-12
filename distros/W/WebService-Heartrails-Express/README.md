# NAME

WebService::Heartrails::Express - API client for Heartrails Express API

# SYNOPSIS

    use WebService::Heartrails::Express;

    my $express = new WebService::Heartrails::Express();
      
    # Get line names by area
     
    my $area_only = $express->line({area => '関東'});
    
    # Get line names by prefecture
     
    my $pref_only = $express->line({prefecture => '神奈川県'});

    # Get line names by area and prefecture 
    my $pref_and_area = $express->line({area => '関東',prefecture => '千葉県'});

    # Get station information by line
      
     my $lineonly = $express->station({line => 'JR山手線'});
    
    # Get station information by name

    my $nameonly = $express->station({name => '新宿'});

    # Get station information by name and line
    
    my $name_and_line = $express->station({line => 'JR山手線',name => '新宿'});

    # Get near station information by latitude and longtitude

    my $near = $express->near({x => '135.0',y => '35.0'});



# DESCRIPTION

WebService::Heartrails::Express is the API client for Heartrails express API.

Please refer [http://express.heartrails.com/api.html](http://express.heartrails.com/api.html),[http://nlftp.mlit.go.jp/ksj/other/yakkan.html](http://nlftp.mlit.go.jp/ksj/other/yakkan.html),[http://www.heartrails.com/company/terms.html](http://www.heartrails.com/company/terms.html),[http://www.heartrails.com/company/disclaimer.html](http://www.heartrails.com/company/disclaimer.html)
if you want to get imformation about Heartrails Express API.



# LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sue7ga <sue77ga@gmail.com>
