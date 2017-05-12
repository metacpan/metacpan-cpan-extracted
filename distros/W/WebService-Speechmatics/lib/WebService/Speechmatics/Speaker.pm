package WebService::Speechmatics::Speaker;
$WebService::Speechmatics::Speaker::VERSION = '0.02';
use 5.010;
use Moo 1.006;

has duration   => (is => 'ro');
has confidence => (is => 'ro');
has name       => (is => 'ro');
has time       => (is => 'ro');

1;


=head1 NAME

WebService::Speechmatics::Speaker - data object that holds details of a speaker in a transcript

=head1 SYNOPSIS

=head1 DESCRIPTION

