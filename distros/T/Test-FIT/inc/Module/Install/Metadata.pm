# $File: //depot/cpan/Module-Install/lib/Module/Install/Metadata.pm $ $Author: autrijus $
# $Revision: #16 $ $Change: 1375 $ $DateTime: 2003/03/18 12:29:32 $ vim: expandtab shiftwidth=4

package Module::Install::Metadata;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use strict 'vars';
use vars qw($VERSION);

sub Meta { shift }

my @scalar_keys = qw(name version abstract author license distribution_type);
my @tuple_keys  = qw(build_requires requires recommends bundles);

foreach my $key (@scalar_keys) {
    *$key = sub {
        my $self = shift;
        return $self->{values}{$key} unless @_;
        $self->{values}{$key} = shift;
        return $self;
    };
}

foreach my $key (@tuple_keys) {
    *$key = sub {
        my ($self, $module, $version) = (@_, 0, 0);
        return $self->{values}{$key} unless $module;
        my $rv = [$module, $version];
        push @{$self->{values}{$key}}, $rv;
        return $rv;
    };
}

sub features {
    my $self = shift;
    while (my ($name, $mods) = splice(@_, 0, 2)) {
        push @{$self->{values}{features}}, ($name => [map { ref($_) ? @$_ : $_ } @$mods] );
    }
    return @{$self->{values}{features}};
}

sub _dump {
    my $self = shift;
    my $package = ref($self->_top);
    my $version = $self->_top->VERSION;
    my %values = %{$self->{values}};
    $values{distribution_type} ||= 'module';

    my $dump = '';
    foreach my $key (@scalar_keys) {
        $dump .= "$key: $values{$key}\n" if exists $values{$key};
    }
    foreach my $key (@tuple_keys) {
        next unless exists $values{$key};
        $dump .= "$key:\n";
        $dump .= "  $_->[0]: $_->[1]\n" for @{$values{$key}};
    }

    return($dump . "generated_by: $package version $version\n");
}

sub write {
    my $self = shift;
    return $self unless $self->admin;
    return if -f "META.yml";
    warn "Creating META.yml\n";
    open META, "> META.yml" or die $!;
    print META $self->_dump;
    close META;
    return $self;
}

sub version_from {
    my ($self, $version_from) = @_;
    require ExtUtils::MM_Unix;
    $self->version(ExtUtils::MM_Unix->parse_version($version_from));
}

1;
