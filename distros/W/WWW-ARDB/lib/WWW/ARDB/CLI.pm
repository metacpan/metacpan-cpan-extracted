package WWW::ARDB::CLI;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Command-line interface for WWW::ARDB

use Moo;
use MooX::Cmd;
use WWW::ARDB;
use JSON::MaybeXS qw( encode_json );
use Getopt::Long qw(:config pass_through);

our $VERSION = '0.001';

has debug => (
    is      => 'ro',
    default => sub { $ENV{WWW_ARDB_DEBUG} // 0 },
);

has no_cache => (
    is      => 'ro',
    default => sub { $ENV{WWW_ARDB_NO_CACHE} // 0 },
);

has json => (
    is      => 'ro',
    default => sub { $ENV{WWW_ARDB_JSON} // 0 },
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    my ($debug, $no_cache, $json);
    GetOptions(
        'debug|d'  => \$debug,
        'no-cache' => \$no_cache,
        'json|j'   => \$json,
    );

    my $result = $class->$orig(@args);
    $result->{debug}    = $debug    if $debug;
    $result->{no_cache} = $no_cache if $no_cache;
    $result->{json}     = $json     if $json;

    return $result;
};

has api => (
    is      => 'lazy',
    builder => '_build_api',
);

sub _build_api {
    my $self = shift;
    return WWW::ARDB->new(
        debug     => $self->debug,
        use_cache => !$self->no_cache,
    );
}

sub execute {
    my ($self, $args, $chain) = @_;

    if (!@$chain || @$chain == 1) {
        print "ardb - ARC Raiders Database CLI\n\n";
        print "Usage: ardb <command> [options]\n\n";
        print "Commands:\n";
        print "  items     List all items\n";
        print "  item      Show item details\n";
        print "  quests    List all quests\n";
        print "  quest     Show quest details\n";
        print "  enemies   List all ARC enemies\n";
        print "  enemy     Show ARC enemy details\n";
        print "\nGlobal Options:\n";
        print "  -d, --debug     Enable debug output\n";
        print "  -j, --json      Output as JSON\n";
        print "  --no-cache      Disable caching\n";
        print "\nExamples:\n";
        print "  ardb items --search guitar\n";
        print "  ardb item acoustic_guitar\n";
        print "  ardb enemies\n";
        print "  ardb enemy wasp --json\n";
        print "\nData provided by ardb.app\n";
    }
}

sub output_json {
    my ($self, $data) = @_;
    print encode_json($data) . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI - Command-line interface for WWW::ARDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::ARDB::CLI;
    WWW::ARDB::CLI->new_with_cmd;

=head1 DESCRIPTION

Main CLI class for the ARC Raiders Database API client. Uses L<MooX::Cmd>
for subcommand handling.

=head1 NAME

WWW::ARDB::CLI - Command-line interface for WWW::ARDB

=head1 ATTRIBUTES

=head2 debug

Enable debug output. Use C<--debug> or C<-d> flag, or set via
C<WWW_ARDB_DEBUG> environment variable.

=head2 no_cache

Disable response caching. Use C<--no-cache> flag, or set via
C<WWW_ARDB_NO_CACHE> environment variable.

=head2 json

Output results as JSON. Use C<--json> or C<-j> flag, or set via
C<WWW_ARDB_JSON> environment variable.

=head2 api

L<WWW::ARDB> instance.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-ardb>

  git clone https://github.com/Getty/p5-www-ardb.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
