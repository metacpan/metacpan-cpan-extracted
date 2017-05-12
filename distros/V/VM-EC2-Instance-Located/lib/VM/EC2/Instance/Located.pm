package VM::EC2::Instance::Located;
$VM::EC2::Instance::Located::VERSION = '0.13';
# ABSTRACT: A quick check to determine if the currently running code is running on a AWS EC2 instance.

use strict;
use warnings;
use Net::DNS;

=head1 NAME

VM::EC2::Instance::Located - determine if code is executing on an EC2 instance

=head1 SYNOPSIS

  my $result = VM::EC2::Instance::Located::at_ec2();
  if($result) {
    print "Running at EC2\n";
  } else {
    print "Not running at EC2\n";
  }

=head1 DESCRIPTION

Provides a function that determines if code is executing on an EC2
instance.

Currently implemented by resolving instnace-data.ec2.internal.  It
will succeed on an ec2 instance and fail otherwise.

=cut

=head1 METHODS 

=cut 

=head2 at_ec2

Determines if the code is running at EC2.

The answer is cached because typically the result does not change
unless you're able to move processes between an EC2 instance an a non
EC2 instance.

Returns a boolean value answering the question.

=cut

my $target_hostname = 'instance-data.ec2.internal';

my $known_answer;

sub at_ec2 {
    return $known_answer if defined($known_answer);

    my $res   = Net::DNS::Resolver->new;
    my $reply = $res->search($target_hostname);
    
    if ($reply) {
        return $known_answer = 1;
    }
    
    return $known_answer = 0;
}

1;



