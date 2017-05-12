package WWW::GoDaddy::REST::Shell::GetCommand;

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [qw(run_get smry_get help_get comp_get)],
    groups  => { default => [qw(run_get smry_get help_get comp_get)] }
};
use WWW::GoDaddy::REST::Shell::Util qw(get_resource_by_schema_or_uri);

sub run_get {
    my $self = shift;

    my $usage = "Usage:\n get [schema] [id]\n get /uri/id\n";
    my $resource = eval { return get_resource_by_schema_or_uri( $self, @_ ); };
    if ($@) {
        if ( UNIVERSAL::isa( $@, 'WWW::GoDaddy::REST::Resource' ) ) {
            $self->page( $@->to_string(1) . "\n" );
        }
        else {
            warn($@);
            warn($usage);
        }
        return 0;
    }

    eval { $self->page( $resource->to_string(1) . "\n" ); };
    if ($@) {
        warn($@);
    }

    return 1;
}

sub smry_get {
    return "load a specific resource"
}

sub help_get {
    return <<HELP
Load a specific resource.  This can be done either by schema and id, or
by specifying a URL path.

Usage:
get [schema] [id]
get [/uri/to/id]

Example:
get user 1
get /user/1
get /users?filter=...
HELP
}

sub comp_get {
    my $self   = shift;
    my $client = $self->client;
    return grep { $client->schema($_)->is_queryable } $self->schema_completion(@_);
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
