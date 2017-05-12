package WebSource::Logger;
use strict;

=head1 NAME

WebSource::Logger : WebSource logging module

=head1 DESCRIPTION

Configurable logging module

=head1 SYNOPSIS

  use WebSource::Logger(level => $loglevel);
  my $logger->log($level,$message);

=head1 METHODS

=over 1

=item $logger = WebSource::Logger->new( level => $loglevel )

Create a new logging object

=cut

sub new {
  my $class = shift;
  my %params = @_;
  $params{level} or $params{level} = 3;
  $params{date} or $params{date} = 0;
  return bless \%params, $class;
}

=item $logger->log($level,$message);

Log $message if the current log level is superior or equal to $level

=cut

sub log {
  my $self = shift;
  my $level = shift;
  $level <= $self->{level} and 
    print STDERR ($self->{date} ? scalar(localtime) . " : " : ""), @_,"\n";
}


=item $logger->will_log($level);

Check if a message logged at level C<$level> will be logged or not.
This is typically to prevent processing in preperation for loggin data.

=cut

sub will_log {
	my ($self,$level) = @_;
	return ($level <= $self->{level});
}

=head1 SEE ALSO

WebSource

=cut

1;
