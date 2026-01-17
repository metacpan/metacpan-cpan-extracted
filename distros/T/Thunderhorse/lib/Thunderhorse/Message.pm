package Thunderhorse::Message;
$Thunderhorse::Message::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard, -role;

use Devel::StrictMode;

has param 'context' => (
	(STRICT ? (isa => InstanceOf ['Thunderhorse::Context']) : ()),
	weak_ref => 1,
);

sub update ($self, $scope, $receive, $send)
{
	...;
}

