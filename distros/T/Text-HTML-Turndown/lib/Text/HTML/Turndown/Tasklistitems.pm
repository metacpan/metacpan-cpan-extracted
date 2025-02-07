package Text::HTML::Turndown::Tasklistitems 0.02;
use 5.020;
use experimental 'signatures';
use stable 'postderef';
use List::MoreUtils 'all';

our %RULES = (
    taskListItems => {
        filter => sub ($rule, $node, $options) {
            return lc $node->getAttribute('type') eq 'checkbox'
                   && uc $node->parentNode->nodeName eq 'LI'
        },
        replacement => sub( $content, $node, $options, $context ) {
            return ($node->getAttribute('checked') ? '[x]' : '[ ]') . ' '
        }
    },
);

sub install ($class, $target) {
    for my $key (keys %RULES) {
        $target->addRule($key, $RULES{$key})
    }
}

1;
