


package WWW::Shopify::Liquid::Filter::Uniq;
use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 1; }
use List::MoreUtils qw(uniq);
sub operate { return [uniq(@{$_[2]})]; }

1;