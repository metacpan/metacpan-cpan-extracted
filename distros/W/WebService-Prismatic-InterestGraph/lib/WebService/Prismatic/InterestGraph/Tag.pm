package WebService::Prismatic::InterestGraph::Tag;
$WebService::Prismatic::InterestGraph::Tag::VERSION = '0.04';
use 5.006;
use Moo;
use JSON qw(decode_json);

has id    => (is => 'ro');
has topic => (is => 'ro');
has score => (is => 'ro');

1;

=head1 NAME

WebService::Prismatic::InterestGraph::Tag - represents one topic tag returned by the InterestGraph calls

=head1 SYNOPSIS

 use WebService::Prismatic::InterestGraph::Tag;
 my $tag = WebService::Prismatic::InterestGraph::Tag->new(
               id    => 30489,
               topic => 'Pattern Recognition',
               score => 0.5737522648935313,
           );

=head1 DESCRIPTION

This module is a class for data objects that are returned by the C<tag_url> and C<tag_text>
methods in the L<WebService::Prismatic::InterestGraph> module.


