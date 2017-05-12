package Devel::InnerPackage;

use strict;
use base qw(Exporter);
use vars qw($VERSION @EXPORT_OK);

$VERSION = '0.3';
@EXPORT_OK = qw(list_packages);

sub list_packages {
            my $pack = shift; $pack .= "::" unless $pack =~ m!::$!;

            no strict 'refs';
            my @packs;
            my @stuff = grep !/^(main|)::$/, keys %{$pack};
            for my $cand (grep /::$/, @stuff)
            {
                $cand =~ s!::$!!;
                my @children = list_packages($pack.$cand);
    
                push @packs, "$pack$cand" unless $cand =~ /^::/ ||
                    !__PACKAGE__->_loaded($pack.$cand); # or @children;
                push @packs, @children;
            }
            return grep {$_ !~ /::(::ISA::CACHE|SUPER)/} @packs;
}

### XXX this is an inlining of the Class-Inspector->loaded()
### method, but inlined to remove the dependency.
sub _loaded {
       my ($class, $name) = @_;

    no strict 'refs';

       # Handle by far the two most common cases
       # This is very fast and handles 99% of cases.
       return 1 if defined ${"${name}::VERSION"};
       return 1 if defined @{"${name}::ISA"};

       # Are there any symbol table entries other than other namespaces
       foreach ( keys %{"${name}::"} ) {
               next if substr($_, -2, 2) eq '::';
               return 1 if defined &{"${name}::$_"};
       }

       # No functions, and it doesn't have a version, and isn't anything.
       # As an absolute last resort, check for an entry in %INC
       my $filename = join( '/', split /(?:'|::)/, $name ) . '.pm';
       return 1 if defined $INC{$filename};

       '';
}






1;
