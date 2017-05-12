#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Image - Manages Images

=head1 DESCRIPTION

Manage the images.

=head1 SYNOPSIS

 my @images = Images->list;

=cut

package WebService::ProfitBricks::Image;

use strict;
use warnings;

use WebService::ProfitBricks::Class;
use base qw(WebService::ProfitBricks);

attrs qw/imageId 
        imageName 
        imageType
        writeable
        cpuHotpluggable
        memoryHotpluggable
        region
        osType/;

does find => { through => "imageName" };
does list => { through => "getAllImages" };

has_many server => "WebService::ProfitBricks::Server" => {
   through => sub {
      my ($self) = @_;
      map { $_ = { serverId => $_ } } $self->serverIds;
   },
};

"Mirror Mirror on the wall";
