# NAME

WWW::256locksMaker - Perl Interface of 256locks maker (http://maker-256locks.herokuapp.com/)

# SYNOPSIS

    use WWW::256locksMaker;
    my $nigolox = WWW::256locksMaker->make('yourname');
    printf("image_url:%s tweet_link:%s\n", $nigolox->image_url, $nigolox->tweet_link);
    

    ### image method returns Imager object.
    $nigolox->image->write(file => '/path/to/somefile.png');

# DESCRIPTION

WWW::256locksMaker is a perl interface of 256locks maker.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
