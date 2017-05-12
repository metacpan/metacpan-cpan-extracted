package UkrMoney::API;

use strict;
use warnings;
use LWP::Simple;
use XML::Simple;

our $VERSION = '1.01';


sub new {
	my $class = shift;
	$class = ref ($class) || $class;
	my $self = {};
	return bless $self, $class;
};

sub login{
	my $self   = shift;
	my $param  = shift;
  
	my $xml = XMLin(get("https://api.ukrmoney.com/login/?pc_pwd=".$param->{'password'}."&pc_email=".$param->{'login'}), KeepRoot => 1);
	$self->{'param'}->{'session'} = $xml->{'login'}->{'session'};
	return $xml->{'login'}->{'session'};
}


sub trans{
	my $self   = shift;
	my $param  = shift;
	$param->{'session'} = $self->{'param'}->{'session'} unless $param->{'session'};
	
	my $xml = XMLin(get("https://api.ukrmoney.com/newtrans/?".($param->{'payee_purse'} ? "payee_purse=".$param->{'payee_purse'}."&" : "")."amnt=".$param->{'amount'}."&word=".$param->{'description'}."&pcsl_session_id=".$param->{'session'}."&benef_email=".$param->{'benef_email'}.($param->{'benef_purse'} ? "&benef_purse=".$param->{'benef_purse'} : "")."&mode=".$param->{'mode'}), KeepRoot => 1);
	return $xml->{'status'};
}

sub trans_info{
	my $self   = shift;
	my $param  = shift;
	$param->{'session'} = $self->{'param'}->{'session'} unless $param->{'session'};
    
	my $xml = XMLin(get("https://api.ukrmoney.com/view_trans_info/?trans_id=".$param->{'trans_id'}."&pcsl_session_id=".$param->{'session'}), KeepRoot => 1);
	return $xml;
}

sub trans_list{
	my $self   = shift;
	my $param  = shift;
	$param->{'session'} = $self->{'param'}->{'session'} unless $param->{'session'};
	
	my $xml = XMLin(get("https://api.ukrmoney.com/trans_list/?pcp_purse=".$param->{'purse'}."&offset=".$param->{'offset'}."&limit=".$param->{'limit'}."&pcsl_session_id=".$param->{'session'}), KeepRoot => 1);
	return $xml;
}

sub my_info{
	my $self   = shift;
	my $param  = shift;
	$param->{'session'} = $self->{'param'}->{'session'} unless $param->{'session'};
	
	my $xml = XMLin(get("https://api.ukrmoney.com/account/?pcsl_session_id=".$param->{'session'}), KeepRoot => 1);
	return $xml;
}

sub check_user{
	my $self   = shift;
	my $param  = shift;
	$param->{'session'} = $self->{'param'}->{'session'} unless $param->{'session'};
	
	my $result = $self->trans({'payee_purse'     => $param->{'payee_purse'} ? $param->{'payee_purse'} : "",
				   'amount'          => '0.01',
				   'description'     => 'check for user',
				   'benef_email'     => $param->{'email'},
				   'pcsl_session_id' => $param->{'session'},
				   'mode'            => 'test'});
	return ($result->{'status'} eq 'ok') ? 1 : 0;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ukrmoney::API - Perl extension for UkrMoney.com Payment System

=head1 SYNOPSIS

  use UkrMoney::API;
  my $um = new UkrMoney::API;
  
  #login in.. login fucntion returns your session_id, but this is not needed to remember it,
  #cause UkrMoney::API module remembers it for you, so all operations below go with this session_id param. 
  $um->login({login => 'your@email.com', password => 'yourpassword'});
  
  #making new transaction
  $um->trans({'payee_purse'     => '1',
	      'amount'          => '200',
	      'description'     => 'payment for product id#3274823',
	      'benef_email'     => 'receiver_email',
	      'mode'            => 'test'});
  
  #getting the last 10 transactions on purse #1 on you account:
  my $transactions = $um->trans_list({purse => '1', offset => -10, limit => 10});
  
  #checking the time of last transaction
  my $time = $transactions->[scalar(@{$transactions})-1]->{'transaction'}->{'time'};
  
  

=head1 DESCRIPTION

UkrMoney::API is needed to work with UkrMoney payment system from your scripts
(like automated payments scripts, etc..)

=head2 Main methods

=over 4

=item *

C<$um-E<gt>login({params..})> - Logining to system via automated API, needed params:


=over 8

=item login

I<login> is your email in the system

=item password

I<password> is your password in the system

=back

=item *

C<$um-E<gt>trans({params..});> - making new transaction, params needed:


=over 8

=item payee_purse

I<payee_purse> is the purse-source number

=item benef_email

I<benef_email> is the receiver id(email) in the system

=item benef_purse

I<benef_purse> is the receiver's purse number, if you know it,.. not needed param

=item amount

I<amount> is the sum you want to transfer

=item description

I<description> is the description (comment) of transfer

=item mode

I<mode> if this is set to 'test', than transfer will be made in test mode(just check if this transfer is possible)

=back

=item *

C<$um-E<gt>trans_info({params..});> - Get information about needed transaction, params:


=over 8

=item trans_id

I<trans_id> is the transaction ID you want to check

=back

=item *

C<$um-E<gt>trans_list({params..});> - Logining to system via automated API


=over 8

=item purse

I<purse> is the purse you want to check transactions of

=item offset

I<offset> is the offset in the list of all transactions, can be <0 then offset is counting from the end of list

=item limit

I<limit> is the number of transactions you want to get.

=back

=item *

C<$um-E<gt>my_info();> - Getting info about current user.

=item *

C<$um-E<gt>check_user({params..});> - Checking if the user you want to transfer to exists


=over 8

=item payee_purse

I<payee_purse> is the purse, from what test transaction will be made

=item email

I<email> is the person's email you want to check

=back

=back

=head1 SEE ALSO

UkrMoney Online Payment System site: http://ukrmoney.com

=head1 AUTHOR

Dmitry Nikolayev <dmitry@cpan.org>, http://perl.dp.ua/resume.html

=head1 THANKS

Thanks to UkrMoney.com Support team for their help in creating of this module.

Also, thanks for DotHost Hosting Provider: http://dothost.ru for their Tech. support.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dmitry Nikolayev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut