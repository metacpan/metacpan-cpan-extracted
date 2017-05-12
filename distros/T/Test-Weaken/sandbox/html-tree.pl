#!/usr/bin/perl -w
use strict;
use Test::Weaken;

# new HTML::Element doesn't need delete, -noweak asks for old behaviour
use HTML::TreeBuilder '-noweak';

# uncomment this to run the ### lines
use Smart::Comments;

my $tw = Test::Weaken::leaks
  ({ constructor => sub {
       ### constructor ...
       my $tree = HTML::TreeBuilder->new_from_content
         ('
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html lang="en">
<head>
<title>A Web Page</title>
</head>
<body>
Blah
</body>
</html>
');
       # ### $tree
       return $tree;
     },
     destructor_method => 'delete',
   });
### $tw

