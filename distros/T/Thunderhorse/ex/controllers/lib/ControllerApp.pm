package ControllerApp;

use v5.40;
use Mooish::Base;

extends 'Thunderhorse::App';

sub build ($self)
{
	$self->load_controller('Clock');
	$self->load_module('Template');
}

