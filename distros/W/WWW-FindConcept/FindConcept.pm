# $Id: FindConcept.pm,v 1.7 2004/01/06 07:40:30 cvspub Exp $
package WWW::FindConcept;

use strict;

use WWW::FindConcept::Sources;
use WWW::Mechanize;
use Data::Dumper;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(find_concept update_concept delete_concept dump_cache remove_cache);
our @EXPORT_FAIL = qw(extract get_concept);

our $VERSION = '0.03';

our $cachepath = $ENV{HOME}."/.find-concept";

sub extract {
    my ($pattern, $text, $concept) = @_;
#    print $pattern.$/;
    while($text =~ /$pattern/g){
	$concept->{$1} = 1;
    }
}

sub get_concept {
    die unless caller eq __PACKAGE__;
    my ($url, $template) = @{shift()};
    my ($query) = shift;
    my ($concept) = shift;
    $url =~ s/\Q{%query%}\E/$query/o;

    my $a = WWW::Mechanize->new(
				env_proxy => 1,
				timeout => 10,
				);
    $a->agent_alias( 'Windows IE 6' );
    $a->get( $url );
    if($a->success){
	extract($template, $a->content, $concept);
#	print $template.$/;
#	print Dumper $concept;
    }
}

use DB_File;
use Storable qw(freeze thaw);

sub delete_concept($) {
    tie my %cache, 'DB_File', $cachepath, O_CREAT | O_RDWR, 0644, $DB_BTREE
	or die "cannot open $cachepath";
    delete $cache{$_[0]};
    untie %cache;
}

sub find_concept($) {
    my $query = shift;
    my %concept;
    tie my %cache, 'DB_File', $cachepath, O_CREAT | O_RDWR, 0644, $DB_BTREE
	or die "cannot open $cachepath";

    if($cache{$query}){
	%concept = %{ thaw($cache{$query}) };
    }
    else{
	foreach my $src ( keys %WWW::FindConcept::Sources::source ){
#	    next if $WWW::FindConcept::Sources::source{$src}->[-1] eq 'to_skip';
	    get_concept($WWW::FindConcept::Sources::source{$src}, $query, \%concept);
	}
	$cache{$query} = freeze \%concept;
    }
    untie %cache;

    keys %concept;
}

sub dump_cache(){
    tie my %cache, 'DB_File', $cachepath, O_CREAT | O_RDWR, 0644, $DB_BTREE
	or die "cannot open $cachepath";
    my @c = keys %cache;
    untie %cache;
    return @c;
}

sub update_concept($) {
    delete_concept($_[0]);
    find_concept($_[0]);
}

sub remove_cache {
    unlink $cachepath;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WWW::FindConcept - Finding terms of related concepts

=head1 SYNOPSIS

  use WWW::FindConcept;

  $WWW::FindConcept::cachepath = '~/.find-concept'; # The default value

  @concepts = find_concept('Perl');

  delete_concept('Perl');

  @concepts = update_concept('Perl');

  dump_cache();

  remove_cache();

=head1 DESCRIPTION

This module is aimed at retrieving terms of related concepts frequently being fed into search engines. You can use it to expand the vocabulary when doing search on web or other conceivable things.


=head2 EXPORT

I<find_concept()> is auto-exported and it returns a list of the related terms. The list is also saved in cache $WWW::FindConcept::cachepath.

I<delete_concept()> deletes a concept in cache.

I<update_concept()> sends out query and updates the cache each time.

I<dump_cache()> outputs the queries in cache.

I<remove_cache()> unlinks the cache file.  



=head1 SEE ALSO

L<find-concept.pl>

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
