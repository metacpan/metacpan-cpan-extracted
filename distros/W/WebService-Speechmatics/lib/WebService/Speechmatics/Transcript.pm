package WebService::Speechmatics::Transcript;
$WebService::Speechmatics::Transcript::VERSION = '0.02';
use 5.010;
use Moo 1.006;

has job      => (is => 'ro');
has speakers => (is => 'ro');
has words    => (is => 'ro');

1;


=head1 NAME

WebService::Speechmatics::Transcript - data object that holds details of a transcription

=head1 SYNOPSIS

=head1 DESCRIPTION

