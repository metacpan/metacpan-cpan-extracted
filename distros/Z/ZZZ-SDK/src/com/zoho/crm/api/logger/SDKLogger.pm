package Log;
use JSON;
sub new
{
  my ($class, $level, $file_path) = @_;
  my $self={
    'level' => $level,
    'file_path' => $file_path
  };
  bless $self, $class;
  return $self;
}

sub get_instance(){
  my ($level,$file_path) = @_;
  return Log->new($level,$file_path);
}

sub get_level(){
  my $self=shift;
  return $self->{level};
}

sub get_file_path(){
  my $self=shift;
  return $self->{file_path};
}

package Levels;
sub INFO{
  return "info";
}
sub DEBUG{
  return "debug";
}

sub WARNING{
  return "warning";
}

sub CRITICAL{
  return "critical";
}

sub ERROR{
  return "error";
}
sub ALERT{
  return "alert";
}
sub EMERGENCY{
  return "emergency";
}

package SDKLogger;
use Log::Handler;
sub initialize{
  my ($logger) = @_;
  my $log = Log::Handler->create_logger("SDKLogger");
  $log->add(
      file => {
          timeformat => "%H:%M:%S",
          filename => $logger->get_file_path(),
          minlevel=> "emergency",
          maxlevel => $logger->get_level(),
          debug_trace => 1,
          debug_mode => 1,
          message_layout => "%D %T SDKLogger %L %p %s %m "

        }
  );
}

=head1 NAME

com::zoho::crm::api::logger::SDKLogger - This class to initialize the SDK logger.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<initialize>

Creates an User SDKLogger instance with the specified Logger class instance.

Param log_instance : A Logger class instance.

=back

=cut
1;
