use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=>1 }
use XML::Mini;
use XML::Mini::Document;
use XML::Mini::Element;
use XML::Mini::Node;
use XML::Mini::TreeComponent;
use XML::Mini::Element::CData;
use XML::Mini::Element::Comment;
use XML::Mini::Element::DocType;
use XML::Mini::Element::Entity;

require XML::Mini;
require XML::Mini::Document;
require XML::Mini::Element;
require XML::Mini::Node;
require XML::Mini::TreeComponent;
require XML::Mini::Element::CData;
require XML::Mini::Element::Comment;
require XML::Mini::Element::DocType;
require XML::Mini::Element::Entity;

ok(1);