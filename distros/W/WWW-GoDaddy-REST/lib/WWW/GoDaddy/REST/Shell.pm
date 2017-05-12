package WWW::GoDaddy::REST::Shell;
use base qw(Term::Shell);

use warnings;
use strict;

use Getopt::Long;
use Config::Any;
use List::Util qw(shuffle first);
use Pod::Usage;

use WWW::GoDaddy::REST;
use WWW::GoDaddy::REST::Shell::DocsCommand;
use WWW::GoDaddy::REST::Shell::GetCommand;
use WWW::GoDaddy::REST::Shell::ListCommand;
use WWW::GoDaddy::REST::Shell::QueryCommand;

eval "use WWW::GoDaddy::REST::Shell::GraphCommand";
if ($@) {
    warn("Install the GraphViz module to enable the 'graph' command");
}

sub init {
    my $self = shift;

    my %options;

    my $res
        = GetOptions( \%options, "url=s", "config=s", "username=s", "password=s", "man", "help" );
    pod2usage(2) if !$res;
    pod2usage(1) if $options{help};
    pod2usage( -verbose => 2 ) if $options{man};

    my $conf_file = $options{config} || '';
    if ( -e $conf_file ) {
        my $config = Config::Any->load_files(
            {   'files'   => [$conf_file],
                'use_ext' => 1
            }
        )->[0];

        foreach (qw/ url username password /) {
            $options{$_} ||= $config->{$conf_file}->{$_};
        }

        # some config files specify the opts like this
        $options{password} ||= $config->{$conf_file}->{basic_password};
        $options{username} ||= $config->{$conf_file}->{basic_username};
    }

    if ( $options{username} or $options{password} ) {
        if ( !$options{password} ) {
            pod2usage("You a username must also be provided");
        }
        if ( !$options{username} ) {
            pod2usage("You a password must also be provided");
        }
    }

    my $client_settings = { 'url' => $options{url} };
    if ( $options{username} && $options{password} ) {
        $client_settings->{'basic_username'} = $options{username};
        $client_settings->{'basic_password'} = $options{password};
    }

    if ( !$options{url} ) {
        pod2usage("The --url must be provided either on the command line or in the config file");
    }

    my $client = eval { return WWW::GoDaddy::REST->new($client_settings) };
    if ($@) {
        pod2usage($@);
    }

    $self->client($client);

    return 1;
}

sub preloop {
    my ($self) = @_;

    my $client = $self->client;

    my $random_schema
        = ( shuffle map { $_->id } grep { $_->is_queryable } @{ $client->schemas } )[0];
    my $url = $client->url;

    print "Tab completion is your friend.\n\n";
    $self->run('list');
    print "\n";
    print "Some sample commands to get you started:\n";
    print " list\n";
    print " man $random_schema\n";
    print " get $random_schema 1234\n";
    print " get $url/schemas\n";

}

sub client {
    my ( $self, $new ) = @_;
    if ($new) {
        $self->{SHELL}->{GDCLIENT} = $new;
    }
    return $self->{SHELL}->{GDCLIENT};
}

sub prompt_str {
    "api> ";
}

sub schema_completion {
    my ( $self, $word, $line, $start ) = @_;
    my @words = $self->line_parsed($line);

    if ( @words > 2 or @words == 2 and $start == length($line) ) {
        return ();
    }

    return grep { index( $_, $word ) == 0 } $self->schema_names();
}

sub schema_names {
    my ($self) = @_;
    return sort map { $_->id } @{ $self->client->schemas };
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

