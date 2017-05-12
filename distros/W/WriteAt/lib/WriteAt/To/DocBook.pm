#===============================================================================
#
#  DESCRIPTION:  DocBook
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package WriteAt::To::DocBook;
use strict;
use warnings;
use Perl6::Pod::Utl;
use WriteAt::To;
use base ( 'Perl6::Pod::To::DocBook', 'WriteAt::To' );
use utf8;
our $VERSION = '0.01';

sub start_write {
    my $self = shift;
    my %tags = @_;
    my $w    = $self->writer;
    my $dtd  = '';
    for (
        '/usr/local/share/xml/docbook/4.5/docbookx.dtd',
        '/usr/share/xml/docbook/schema/dtd/4.5/docbookx.dtd'
      )
    {
        if ( -e $_ ) {
            $dtd = $_;
            last;
        }
    }
    die "Can't find docbookx.dtd file" unless $dtd;
    my $lang = $self->{lang} || 'en';
    $w->raw(<<"H");
<?xml version='1.0' encoding="UTF-8"?>
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.3CR1//EN"
        "file://${dtd}" []>
<book lang="$lang">
H
    $w->raw('<bookinfo>');
    for (qw/ TITLE SUBTITLE AUTHOR CHANGES DESCRIPTION /) {
      my $n = $tags{$_} || die "Cant find block =$_";

       #make Document element
       $self->visit($n);
    }
    $w->raw('</bookinfo>');
}

sub block_DESCRIPTION {
    my ( $self, $n ) = @_;
    my $w = $self->w;
    $w->raw('<abstract>');
    $self->visit_childs($n);
    $w->raw('</abstract>');
}

sub block_TITLE {
    my ( $self, $n ) = @_;
    my $w = $self->w;
    $w->raw('<title>');
    $self->visit_childs($n);
    $w->raw('</title>');
}

sub block_SUBTITLE {
    my ( $self, $n ) = @_;
    my $w = $self->w;
    $w->raw('<subtitle>');
    $self->visit_childs($n);
    $w->raw('</subtitle>');
}

no strict;
# alias for CHAPTER
sub block_ГЛАВА {
    $self = shift;
    return $self->block_CHAPTER(@_)
}
use strict;


sub block_CHAPTER {
    my ( $self, $node ) = @_;
    #close any section
    $self->switch_head_level(0, 'no_start_next');
    $self->w->raw('</chapter>') if $self->{IN_CHAPTER};
    $self->w->raw('<chapter>') &&  $self->{IN_CHAPTER}++;
    $self->w->raw('<title>')->print($node->childs->[0]->childs->[0])
    ->raw('</title>');
}

sub end_write {
    my $self = shift;
    $self->SUPER::end_write();
    $self->w->raw('</chapter>') if $self->{IN_CHAPTER};
    $self->w->raw('</book>');
}
1;



