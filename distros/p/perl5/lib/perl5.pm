# To do:
# - Turn die to croak (with tests)

use strict; use warnings;
package perl5;
our $VERSION = '0.21';

use version;
use Carp ();

my $requested_perl_version = 0;
my $perl_version = 10;

sub VERSION {
    my ($class, $version) = @_;
    $version = version->parse($version);
    if ($version < 10) {
        my $this_version = do {
            no strict 'refs';
            version->parse(${$class . '::VERSION'});
        };
        if ($version > $this_version) {
            Carp::croak(
                "$class version $version required" .
                "--this is only version $this_version"
            );
        }
    }
    else {
        $requested_perl_version = $version;
    }
}

sub version_check {
    my ($class, $args) = @_;

    if (defined $args->[0]) {
        my $version = $args->[0];
        $version =~ s/^-//;
        if (version::is_lax($version) and version->parse($version) >= 10) {
            $requested_perl_version = version->parse($version);
            shift(@$args);
        }
    }
    if ($requested_perl_version) {
        my $version = $requested_perl_version->numify / 1000 + 5;
        $perl_version = $requested_perl_version;
        $requested_perl_version = 0;
        eval "use $version";
        do { Carp::croak($@) } if $@;
    }
}

sub import {
    return unless @_; # XXX not sure why
    my $class = shift;
    $class->version_check(\@_);
    my $arg = shift;

    if ($class ne 'perl5') {
        (my $usage = $class) =~ s/::/-/;
        die "Don't 'use $class'. Try 'use $usage'";
    }
    die "Too many arguments for 'use perl5...'" if @_;

    my $subclass =
        not(defined($arg)) ? __PACKAGE__ :
        $arg =~ /^-(\w+)$/ ?__PACKAGE__ . "::$1" :
        die "'$arg' is an invalid first argument to 'use perl5...'";
    eval "require $subclass; 1" or die $@;

    @_ = ($subclass);
    goto &{$class->can('importer')};
}

sub importer {
    my $class = shift;
    my @imports = scalar(@_) ? @_ : $class->imports;

    my $caller = caller(0);  # maybe allow 'use perl5-foo package=>Bar'?
    my $important = eval "package $caller; my \$sub = sub { shift->import(\@_) };";

    while (@imports) {
        my $name = shift(@imports);
        my $version = (@imports and version::is_lax($imports[0]))
            ? version->parse(shift(@imports))->numify : '';
        my $arguments = (@imports and ref($imports[0]) eq 'ARRAY')
            ? shift(@imports) : [];

        eval "require $name; 1" or die $@; # could be improved
        $name->VERSION($version) if $version;
        $name->$important(@$arguments);
    }

#    goto &$important;
}

sub imports {
    my $subversion = int($perl_version);
    return (
        'strict',
        'warnings',
        'feature' => [":5.$subversion"],
    );
}

1;
