package WWW::WTF;

use common::sense;

use v5.12;

use Moose;

our $VERSION = 0.5;

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

WWW::WTF WebTestFramework - automated tests for your website

=head1 SYNOPSIS

    yath test examples/ --jobs=4 :: --base_url=https://www.<DOMAIN>

=head1 DESCRIPTION

WWW::WTF is a toolkit for writing automated tests on web-content. WWW::WTF supports different types of user-agents (browsers) to let you navigate through a website's content and query certain data.

=head1 CONTRIBUTORS

christophhalbi

mreitinger

=head1 COPYRIGHT

Atikon EDV & Marketing GmbH 2020

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
