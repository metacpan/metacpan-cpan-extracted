# perl5lib.pm is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package perl5lib;
# no warnings; 
# no strict;

$VERSION = 1.02;

# I assume that split()ing '' returns an empty list.  Should really
# require() the version of Perl where this became true but I cannot
# remember when it happened so I say 5.6.1 to be safe.

require 5.6.1;

use Config;
use lib map { /(.*)/ } split /$Config{path_sep}/ => $ENV{PERL5LIB};

1;
__END__

=head1 NAME

B<perl5lib> - Honour PERL5LIB even in taint mode.

=head1 SYNOPSIS
    
    #!/usr/bin/perl -T
    use perl5lib;
    use My::Other::Module; # In directory listed in PERL5LIB

=head1 DESCRIPTION

Perl's taint mode was originally intended for setuid scripts.  In that
situation it would be unsafe for Perl to populate C<@INC> from
C<$ENV{PERL5LIB}>.  The explicit B<-T> flag is now often used in CGI
scripts and suchlike.  In such situations it often makes sense to
consider C<$ENV{PERL5LIB}> as untainted.

This module uses the L<lib|lib> module to simulate the effect of non-taint
mode Perl's default handling of C<$ENV{PERL5LIB}>.

As a side effect any directories in C<$ENV{PERL5LIB}> are brought to
the front of C<@INC>.  Occasionally this may be useful if one needs an
explict C<use lib> for a project but one still wants development
versions in one's personal module directory to override.

=head1 CAVEATS

The programmer is responsible for deciding if it really is safe to
consider C<$ENV{PERL5LIB}> to be untainted in the enviroment where the
script is to be used.  For example, using this module in a setuid
script would be a big mistake.

For this reason, this module should not be used by other modules, only
directly by scripts.

=head1 AUTHOR

Brian McCauley E<lt>nobull@cpan.orgE<gt>.
