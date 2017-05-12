package XTaTIK::Model::Blog;

our $VERSION = '0.005002'; # VERSION

use Mojo::Base -base;

use Text::Markdown 'markdown';
use File::Glob qw/bsd_glob/;
use File::Spec::Functions qw/catfile/;
use File::Slurp::Tiny 'read_file';
use List::UtilsBy qw/sort_by/;
use Encode;

use experimental 'postderef';

has 'blog_root';

sub brief_list {
    my $self = shift;

    my @posts= bsd_glob $self->blog_root . '/*';

    for ( @posts ) {
        s{^${\ $self->blog_root}/}{};
        my ( $date, $title ) = /(\d{4}-\d{2}-\d{2})-(.+)\.md/;
        $title =~ tr/-/ /;
        $_ = {
            date    => $date,
            title   => $title,
            url     => s/.md$//r,
        };
    }

    @posts = reverse sort_by { $_->{date} } @posts;

    return \@posts;
}

sub post {
    my $self = shift;
    my $post = shift;
    my ( $date, $title ) = $post =~ /(\d{4}-\d{2}-\d{2})-(.+)/;
    $title =~ tr/-/ /;

    my $post_src = catfile $self->blog_root, $post =~ s/[^\w-]//rg . '.md';

    return unless -e $post_src;

    my ( $next, $prev, $found_next );
    for ( $self->brief_list->@* ) {
        if ( $_->{url} eq $post ) {
            $found_next = 1;
            next;
        }

        $next = $_ unless $found_next;

        if ( $found_next ) {
            $prev = $_ ;
            last;
        }
    }

    for ( $next, $prev ) {
        defined or next;
        my $post_src = catfile $self->blog_root,
            $_->{url} =~ s/[^\w-]//rg . '.md';
        my $content = decode 'utf8', read_file $post_src;
        my %metas;
        $metas{ $1 } = $2 while $content =~ s/^%\s+(\w+)\s+(.+)$//m;
        $_->{description} = $metas{description};
    }

    my $content = decode 'utf8', read_file $post_src;
    my %metas;
    $metas{ $1 } = $2 while $content =~ s/^%\s+(\w+)\s+(.+)$//m;

    return (
        $title,
        $date,
        \%metas,
        markdown($content),
        $prev,
        $next,
    );
}

1;

__END__