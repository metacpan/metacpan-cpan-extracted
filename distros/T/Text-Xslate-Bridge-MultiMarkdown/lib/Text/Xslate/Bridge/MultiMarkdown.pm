package Text::Xslate::Bridge::MultiMarkdown;
{
  $Text::Xslate::Bridge::MultiMarkdown::VERSION = '0.002';
}
use strict;
use warnings;
use parent qw(Text::Xslate::Bridge);

use Text::MultiMarkdown;

# ABSTRACT: MultiMarkdown 'filter' for Text::Xslate

sub markdown {
    my ( $text, %markdown_options ) = @_;
    my $m = Text::MultiMarkdown->new( %markdown_options );
    return $m->markdown($text);
}

my %scalar_methods = ( markdown => \&markdown );

__PACKAGE__->bridge( function => \%scalar_methods );


1;

__END__
=pod

=head1 NAME

Text::Xslate::Bridge::MultiMarkdown - MultiMarkdown 'filter' for Text::Xslate

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Text::Xslate::Bridge::MultiMarkdown;
     
    my $xslate = Text::Xslate->new(
        module => [ 'Text::Xslate::Bridge::MultiMarkdown' ],
    );

    print $xslate->render_string('<: markdown( "# H1 Heading" ) :>');

    print $xslate->render_string('<: markdown( "# H1 Heading", heading_ids => 0 ) :>');

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

