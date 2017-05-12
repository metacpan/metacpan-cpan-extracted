package WWW::GoDaddy::REST::Shell::ListCommand;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw(run_list smry_list help_list alias_list)],
    groups  => { default => [qw(run_list smry_list help_list alias_list)] }
};
use Text::Wrap qw(wrap);

sub run_list {
    my ($self) = @_;

    my $schemas = $self->client->schemas();

    my @queryable     = sort map { $_->id } grep { $_->is_queryable } @{$schemas};
    my @not_queryable = sort map { $_->id } grep { !$_->is_queryable } @{$schemas};

    local $Text::Wrap::columns = $self->termsize->{cols};

    my $output = '';

    my $tab = '  ';

    $output .= wrap( '', '', "Schemas that you can query:\n\n" );
    $output .= wrap( $tab, $tab, join " ", @queryable );

    $output .= wrap( '', '', "\n\nOther:\n\n" );
    $output .= wrap( $tab, $tab, join " ", @not_queryable );
    $output .= "\n";

    $self->page($output);

    return 1;
}

sub smry_list {
    return "list the available schema";
}

sub help_list {
    return <<HELP
List all the available data types that are available to work with.

Usage:
  list
HELP
}

sub alias_list {
    return ('ls');
}

1;

=head1 AUTHOR

David Bartle, C<< <davidb@mediatemple.net> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Go Daddy Operating Company, LLC

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

=cut
