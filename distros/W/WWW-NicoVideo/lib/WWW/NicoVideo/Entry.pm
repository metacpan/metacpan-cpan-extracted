# -*- mode: perl; coding: utf-8 -*-

package WWW::NicoVideo::Entry;
use utf8;
use strict;
use warnings;
use base qw[Class::Accessor];

__PACKAGE__->mk_accessors(qw[id
			     comment
			     desc
			     imgHeight
			     imgUrl
			     imgWidth
			     length
			     lengthStr
			     numViews
			     numViewsStr
			     numPlayed
			     numPlayedStr
			     title
			     url
			    ]);

"Ritsuko";
