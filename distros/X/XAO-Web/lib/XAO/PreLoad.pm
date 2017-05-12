=head1 NAME

XAO::PreLoad - helps apache pre-load most popular XAO modules

=head1 SYNOPSIS

In the main httpd.conf, B<not in virtual host section>:

 PerlModule XAO::PreLoad

=head1 DESCRIPTION

The module does not provide any useful functionality at this point, it
simply pre-loads most of XAO modules.

The idea of pre-loading is to let mod_perl compile modules before any
childs are forked off therefore letting all childs reduce startup time
and reduce memory usage (because most of the pre-compiled code stays
shared in forked childs).

=cut

###############################################################################
package XAO::PreLoad;
use strict;
#
use XAO::Base;
use XAO::Cache;
use XAO::Errors;
use XAO::Objects;
use XAO::Projects;
use XAO::SimpleHash;
use XAO::Utils;
#
use XAO::Web;
use XAO::Templates;
use XAO::PageSupport;
#
use XAO::DO::Web::Action;
use XAO::DO::Web::CgiParam;
use XAO::DO::Web::Clipboard;
use XAO::DO::Web::Condition;
use XAO::DO::Web::Config;
use XAO::DO::Web::Cookie;
use XAO::DO::Web::Date;
use XAO::DO::Web::Debug;
use XAO::DO::Web::Default;
use XAO::DO::Web::FilloutForm;
use XAO::DO::Web::Footer;
use XAO::DO::Web::FS;
use XAO::DO::Web::Header;
use XAO::DO::Web::IdentifyAgent;
use XAO::DO::Web::IdentifyUser;
use XAO::DO::Web::Mailer;
use XAO::DO::Web::MenuBuilder;
use XAO::DO::Web::MultiPageNav;
use XAO::DO::Web::Page;
use XAO::DO::Web::Redirect;
use XAO::DO::Web::Search;
use XAO::DO::Web::SetArg;
use XAO::DO::Web::Styler;
use XAO::DO::Web::TextTable;
use XAO::DO::Web::URL;
use XAO::DO::Web::Utility;
#
use XAO::DO::FS::Glue;
use XAO::DO::FS::Hash;
use XAO::DO::FS::List;

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: PreLoad.pm,v 2.1 2005/01/14 01:39:56 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<Apache::XAO>,
L<Apache>,
L<XAO::Web>.
