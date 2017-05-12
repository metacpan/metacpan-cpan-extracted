package Text::UnAbbrev;

use common::sense;
use charnames q(:full);
use Carp;
use English qw[-no_match_vars];
use File::Find;
use File::Spec::Functions ();
use IO::File;
use Moo;
use File::ShareDir::ProjectDistDir;
use Unicode::CaseFold;

our $VERSION = '0.03'; # VERSION

has dict => ( is => q(rw), default => sub { {}; }, );
has language  => ( is => q(rw) );
has domain    => ( is => q(rw) );
has subdomain => ( is => q(rw) );

sub BUILD {
    my $self = shift;
    my $args = shift;

    my $pkg = __PACKAGE__;
    $pkg =~ s{::}{-}g;
    my $share_dir = dist_dir($pkg);
    my @dict_file;
    find( sub { push @dict_file, $File::Find::name if -e }, $share_dir, );

    while ( my $dict_file = shift @dict_file ) {
        $self->_load_dict($dict_file);
    }

    if ( ref $args eq q(HASH) ) {
        foreach my $method ( keys %{$args} ) {
            if ( __PACKAGE__->can($method) ) {
                my $value = delete $args->{$method};
                $self->$method($value);
            }
            else { croak( sprintf q(method unknown: '%s'), $method ); }
        }
    }

    return 1;
} ## end sub BUILD

sub _load_dict {
    my $self      = shift;
    my $dict_file = shift;

    my ( $language, $domain, $subdomain )
        = ( File::Spec::Functions::splitdir($dict_file) )[ -3, -2, -1 ];

    my $fh = IO::File->new( $dict_file, q(<:utf8) );
    while ( my $line = $fh->getline() ) {
        chomp $line;
        my ( $abbrev, $expansion ) = split m{\t+|\N{SPACE}{2,}}msx, $line;
        $abbrev = $self->_norm_abbrev($abbrev);
        push @{ $self->dict->{$language}{$domain}{$subdomain}{$abbrev} },
            $expansion;
    }
    $fh->close();

    return 1;
} ## end sub _load_dict

sub lookup {
    my $self   = shift;
    my $abbrev = shift;
    my $mode   = shift;

    return unless defined $abbrev;

    my $query = $self->_norm_abbrev($abbrev);
    my @result;
    my @language = $self->language() || keys %{ $self->dict() };
    foreach my $language (@language) {
        my $language_node = $self->dict->{$language};
        my @domain = $self->domain() || keys %{$language_node};
        foreach my $domain (@domain) {
            my $domain_node = $language_node->{$domain};
            my @subdomain = $self->subdomain() || keys %{$domain_node};
            foreach my $subdomain (@subdomain) {
                my $subdomain_node = $domain_node->{$subdomain};
                if ( exists $subdomain_node->{$query} ) {
                    my $origin = {
                        language  => $language,
                        domain    => $domain,
                        subdomain => $subdomain,
                    };
                    push @result,
                        $self->_proc_results( $subdomain_node->{$query},
                        $mode, $origin, );
                }
            }
        } ## end foreach my $domain (@domain)
    } ## end foreach my $language (@language)

    return @result;
} ## end sub lookup

sub _proc_results {
    my $self    = shift;
    my $results = shift;
    my $mode    = shift;
    my $origin  = shift;

    my @result;
    foreach my $result ( @{$results} ) {
        if ( defined $mode && $mode eq q(with_origin) ) {
            push @result, { $result => $origin };
        }
        else {
            push @result, $result;
        }
    }

    return @result;
} ## end sub _proc_results

sub _norm_abbrev {
    my $self   = shift;
    my $abbrev = shift;

    foreach ($abbrev) {
        tr{\N{FULL STOP}}{}d;
        tr{\N{SPACE}}    {}d;
        $_ = fc;
    }

    return $abbrev;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf8

=head1 NAME

Text::UnAbbrev - Expand abbreviations and acronyms.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Text::UnAbbrev;

    my $unabbrev = Text::UnAbbrev->new(
        language  => q(pt_BR),
        domain    => q(Geography),
        subdomain => q(unidade_federativa),
    );

    my @expand = $unabbrev->lookup(q(SP));
    # São Paulo

=head1 DESCRIPTION

B<Text::UnAbbrev> is a "dictionary-like" "domain-oriented" module.

=head1 METHODS

=head2 lookup

Take one or two arguments and returns a array with expansions found in C<dict()>

=head2 dict

A   hashref   with   dictionary.   The   first   three   hashref   levels   are
language,  domain   and   subdomain,  fourth  and   last   hashref   level   is
abbreviation/acronym. Each entry ending in  a arrayref of expansions. Normally,
this   arrayref contains   only one   element, perhaps,  unfortunately, in  the
same subdomain, an abbreviation/acronym can have more then one expansion.

=head2 language

The language  definition.  The  language  definition  adopted  by  this  module
looks like  locale  definitions  (  pt_BR, en_US  ...).  If  boolean-false, all
languages are used in lookup operations.

=head2 domain

The   domain   definition.  If   boolean-false,   all   domains  are   used   in
lookup operations.

=head2 subdomain

The   subdomain  definition.   If  boolean-false,  all  domains   are  used   in
lookup operations.

=head1 EXAMPLES

=head2 Retrieve current valid values for ...

=head3 ... languages:

    my @language = keys %{ $unabbrev->{dict} };

=head3 ... domains:

    my @domain = keys %{ $unabbrev->{dict}{pt_BR} };

=head3 ... subdomains:

    my @subdomain = keys %{ $unabbrev->{dict}{pt_BR}{DateTime} };

=head2 Consulting all dictionaries

=head3 Getting origins

    $unabbrev->$_(undef) foreach qw[language domain subdomain];
    my @lookup = $unabbrev->lookup( q(SP), q(with_origin) );

    # or create a new object
    my $unabbrev2 = Text::UnAbbrev->new();
    my @lookup = $unabbrev2->lookup( q(SP), q(with_origin) );

The output can be:

    [
        [0] {
            'Service Pack' => {
                'domain'    => "technology",
                'language'  => "en_US",
                'subdomain' => "information"
            }
        },
        [1] {
            'São Paulo' => {
                'domain'    => "Geography",
                'language'  => "pt_BR",
                'subdomain' => "unidade_federativa"
            }
        },
        [2] {
            'Santo Padre' => {
                'domain'    => "Grammar",
                'language'  => "pt_BR",
                'subdomain' => "pronome_tratamento"
            }
        }
    ]

=head1 FILES

=head2 F<./share/>

Contains all dictionary data files.

=head1 TODO

=over

=item * Improve documentation

=item * Expand dictionaries

=back

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=head1 SEE ALSO

=over

=item * Lingua::PT::Abbrev

=item * DateTime::Locale::pt_BR

=back

=for stopwords unabbrev subdomain lookup dictionary-like domain-oriented boolean-false subdomains DateTime gmail stopwords

=cut
