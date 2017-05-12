package WebService::Speechmatics::Word;
$WebService::Speechmatics::Word::VERSION = '0.02';
use 5.010;
use Moo 1.006;

has duration   => (is => 'ro');
has confidence => (is => 'ro');
has name       => (is => 'ro');
has time       => (is => 'ro');

1;


=head1 NAME

WebService::Speechmatics::Word - data object that holds details of a word in a transcript

=head1 SYNOPSIS

=head1 DESCRIPTION

