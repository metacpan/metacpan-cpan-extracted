use Moops -strict;
use Throwable ();
# ABSTRACT: exception class for WebService::Intercom

=pod

=head1 NAME

WebService::Intercom::Exception - represent a exception or error

=head1 SYNOPSIS

  Not useful to create on its own.

=head2 ATTRIBUTES

=over

=item message - the error message

=item stack - stack trace of the error.

=item code - the code of the error if any

=item request_id - the request id of the error if available

=back

=cut

class WebService::Intercom::Exception with ::Throwable {
    use Devel::StackTrace;
        
        my %CarpInternal = ("WebService::Intercom::Exception" => 1,
                            "Throwable" => 1);
        
        has 'code' => (is => 'ro');
        has 'request_id' => (is => 'ro');
        has 'message' => (is => 'ro', isa => 'Maybe[Str]', required => 1);
        has 'stack' => (is => 'ro', default => sub {
                            my ($level, @caller, %ctxt) = 0;
                            while (
                                defined scalar caller($level) and $CarpInternal{scalar caller($level)}
                            ) {
                                $level++;
                            }
                            @ctxt{qw/ package file line /} = caller($level);
        
                            my $stack = undef;
        
                            $stack = "Devel::StackTrace"->new(
                                ignore_package => [ keys %CarpInternal]
                            );
                            return $stack;
                        });
        
        use overload fallback => 1,
            '""' => sub {
                my $e = shift;
                my $msg = "WebService::Intercom::Exception: @{[$e->message]}\n";
                $msg .= "Stack: " . $e->stack . "\n";
                return $msg;
            };
    }

    
1;

