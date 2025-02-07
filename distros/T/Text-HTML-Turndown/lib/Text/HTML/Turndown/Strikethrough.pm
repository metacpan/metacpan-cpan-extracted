package Text::HTML::Turndown::Strikethrough 0.02;
use 5.020;
use experimental 'signatures';
use stable 'postderef';
use List::MoreUtils 'all';

our %RULES = (
    strikethrough => {

        filter => ['del', 's', 'strike'],
        replacement => sub( $content, $node, $options, $context ) {
          return '~~' . $content . '~~'
        }
    }
);

sub install ($class, $target) {
    for my $key (keys %RULES) {
        $target->addRule($key, $RULES{$key})
    }
}

1;
