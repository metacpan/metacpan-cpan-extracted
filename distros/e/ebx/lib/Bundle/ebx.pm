# $File: //depot/ebx/lib/Bundle/ebx.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1895 $ $DateTime: 2001/09/24 18:43:11 $

package Bundle::ebx;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::ebx - Elixir BBS Exchange Suite and prerequisites

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::ebx'>

=head1 CONTENTS

# Below is a bunch of helpful dependency diagrams.

Net::Telnet        # -*

Test::Simple       # -*

OurNet::BBSAgent   #  -----*

Storable           # -*    |

Net::Daemon        # -*    |

RPC::PlServer      #  -----*

Digest::MD5        # ------*

File::Temp         # -*    |

Data::Dumper       # -*    |

Net::NNTP          #  -----*

Date::Parse        # -*    |

Mail::Address      # -*    |

MIME::Tools        #  --*  |

IO::Stringy        #  --*  |

Mail::Box          #    ---*

Term::ReadKey      # ------*

enum               # ------*

OurNet::BBS        #       --*

Class::MethodMaker # -*      |

GnuPG::Interface   #  -------*

Crypt::Rijndael    # --------*

MIME::Base64       # --------*

Compress::Zlib     # --------*

OurNet::BBSApp::Sync  #         --*

=head1 DESCRIPTION

This bundle includes all that's needed to run the Elixir BBS Exchange Suite.

=head1 AUTHORS

Chia-Liang Kao <clkao@clkao.org>,
Autrijus Tang <autrijus@autrijus.org>.

=head1 COPYRIGHT

Copyright 2001 by Chia-Liang Kao <clkao@clkao.org>,
                  Autrijus Tang <autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
