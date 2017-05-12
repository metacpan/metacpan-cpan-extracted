# NAME

WWW::Jugem::API - It's jugem uranai API

# SYNOPSIS

    use WWW::Jugem::API;

    my $jugem = WWW::Jugem::API->new(date => '2014/09/09');
    my $response = $jugem->fetch('双子座');
    print $response->{content} #=> '不利な状況でも、強気な姿勢を崩さないことがポイント。今日の仕事では、あなたらしく素晴らしい結果が出せそうです。'
    print $response->{color} #=> 'ホワイト'
    print $response->{sign}  #=> '双子座'
    pritn $response->{jog} # 3  <1~5> #仕事運

# DESCRIPTION

    WWW::Jugem::API is API by given URL <http://jugemkey.jp/api/waf/api.ph>

# LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sue7ga <sue77ga@gmail.com>
