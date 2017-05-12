package WWW::Mechanize::Frames;

use strict;
use warnings FATAL => 'all';
our $VERSION = '0.03';

use base qw( WWW::Mechanize );
use Clone::PP qw(clone);

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new( %args );
    return $self;
}

sub get_frames {
	my $self = shift;
    my $num = 0;
    my @array;
    my @links = $self->find_all_links( tag_regex => qr/^(iframe|frame)$/ );
    foreach my $link (@links) {
        ++$num;
        my $link = $link->url_abs;
        my $clone = clone($self);
        $clone ->get($link);
        $array[$num-1] = $clone;
    }
return @array;
}

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::Mechanize::Frames - Perl extension for WWW:Mechanize allowing automatic
frames download.

=head1 SYNOPSIS

use WWW::Mechanize::Frames;

$url = 'http://www.site_with_frames.com';
$mech = WWW::Mechanize::Frames->new();

$mech->get($url);

@frames = $mech->get_frames();

print $frames[0]->content;
print $frames[1]->content;

=head1 DESCRIPTION

This is a quick and dirty expansion of WWW::Mechanize adding a function to retrieve
frames and returns an array of mech objects each one storing the info about each frame.


=head2 EXPORT

None by default.



=head1 SEE ALSO

WWW::Mechanize
Clone::PP
LWP::UserAgent

=head1 AUTHOR

Nick Stoianov, E<lt>cpanperl@yahoo.comE<gt>

=head1 ACKNOWLEDGEMENTS

Thanks to: Andy Lester for WWW:Mechanize(it is a great tool),
Matthew Simon Cavalletto for Clone::PP, and everybody from the Perl
community.


=head1 COPYRIGHT

Copyright (C) 2005 by Nick Stoianov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
