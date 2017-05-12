# pyyaml/lib/yaml/error.py

package YAML::Perl::Error;
use strict;
# use warnings;

use Error();
$Error::Debug = 1;

package YAML::Perl::Mark;
use YAML::Perl::Base -base;

field 'name';
field 'index';
field 'line';
field 'column';
field 'buffer';
field 'pointer';

sub get_snippet {
    my $self = shift;
    my $indent = @_ ? shift : 4;
    my $max_length = @_ ? shift : 75;
    if (not defined $self->buffer) {
        return;
    }
    my $head = '';
    my $start = $self->pointer;
    while (
        $start > 0 and
        substr($self->buffer, $start - 1, 1) !~ /[\0\r\n\x85\x{2028}\x{2029}]/
    ) {
        $start--;
        if ($self->pointer - $start) {
            $head = ' ... ';
            $start += 5;
            last;
        }
    }
    my $tail = '';
    my $end = $self->pointer;
    while (
        $end < length($self->buffer) and
        substr($self->buffer, $start - 1, 1) !~ /[\0\r\n\x85\x{2028}\x{2029}]/
    ) {
        my $end += 1;
        if ($end - $self->pointer > $max_length / 2 - 1) {
            $tail = ' ... ';
            $end -= 5;
            last;
        }
    }
    my $snippet = substr($self->buffer, $start, $end - $start);
    return
        ' ' x $indent . $head . $snippet . $tail . "\n" .
        ' ' x ($indent + $self->pointer - $start + length($head)) . '^';
}

use overload '""' => sub {
    my $self = shift;
    my $snippet = $self->get_snippet();
    my $where = sprintf
        'in "%s", line %d, column %d',
        $self->name, $self->line + 1, $self-> column + 1;
    if (defined $snippet) {
        $where += ":\n$snippet";
    }
    return $where;
};


package YAML::Perl::Error;
use YAML::Perl::Base -base;
use base 'Error::Simple';

*new = \&Error::Simple::new;

# sub throw {
#     my $self = shift;
#     local $Error::Depth = $Error::Depth + 1;
# 
#     # if we are not rethrow-ing then create the object to throw
#     $self = $self->new(@_) unless ref($self);
#     
#     die $Error::THROWN = $self;
# }

package YAML::Perl::Error::Marked;
use YAML::Perl::Error -base;

field 'context';
field 'context_mark';
field 'problem';
field 'problem_mark';
field 'note';

use overload '""' => sub {
    my $self = shift;
    my $lines = [];
    if (defined $self->context) {
        push @$lines, $self->context;
    }
    if (
        $self->context_mark and (
            not($self->problem) or
            not($self->problem_mark) or
            $self->context_mark->name ne $self->problem_mark->name or
            $self->context_mark->line != $self->problem_mark->line or
            $self->context_mark->column != $self->problem_mark->column
        )
    ) {
        push @$lines, $self->context_mark . "";
    }
    if ($self->problem) {
        push @$lines, $self->problem;
    }
    if ($self->problem_mark) {
        push @$lines, $self->problem_mark . "";
    }
    if ($self->note) {
        push @$lines, $self->note;
    }
    return join "\n", @$lines;
};

1;
