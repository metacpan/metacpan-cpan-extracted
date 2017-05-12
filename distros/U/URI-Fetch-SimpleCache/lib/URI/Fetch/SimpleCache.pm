package URI::Fetch::SimpleCache;

use strict;
use warnings;
use base qw(URI::Fetch);
use Cache::FileCache;

our $VERSION = '0.02';
our $CACHE_ROOT = $ENV{'HOME'};
our $DEFAULT_EXPIRES;

sub fetch {
    my $class = shift;
    my($uri,%params) = @_;

    if ( ! $params{Cache} ) {
        if ( $params{'Cache_root'} ) {
            $CACHE_ROOT = delete $params{'Cache_root'};
        }
        if ( $params{'Cache_default_expires'} ) {
            $DEFAULT_EXPIRES = delete $params{'Cache_default_expires'};
        }
        $params{Cache} = Cache::FileCache->new({
            'cache_root'      => $CACHE_ROOT,
            'default_expires' => $DEFAULT_EXPIRES,
        });
    }

    $class->SUPER::fetch( ( $uri,%params ) );
}

1;
__END__

=head1 NAME

URI::Fetch::SimpleCache - URI::Fetch extension with local cache

=head1 VERSION

This documentation refers to URI::Fetch::SimpleCache version 0.02

=head1 SYNOPSIS

    #! /usr/bin/perl
    
    use strict;
    use warnings;
    use URI::Fetch::SimpleCache;
    
    my $res = URI::Fetch::SimpleCache->fetch(
        'http://search.cpan.org/uploads.rdf',
        Cache_root => '/tmp/.cache',
        Cache_default_expires => '60 sec',
    ) or die URI::Fetch::SimpleCache->errstr;
    
    print $res->content;

=head1 DESCRIPTION

URI::Fetch::SimpleCache is a URI::Fetch extention.
Local cache files are implemented by Cache::FileCache.

=head1 METHOD

=head2 fetch

This fetch method makes object of Cache::FileCache when there isn't Cache parameter.
And, URI::Fetch::fetch is executed. 
B<$ENV{'HOME'}> is used when there is no Cache parameter.

=head1 DEPENDENCIES

L<URI::Fetch>, L<Cache::FileCache>

=head1 SEE ALSO

L<URI::Fetch>, L<Cache::FileCache>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut

