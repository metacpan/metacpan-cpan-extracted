#
# File: Messaging.msg
# Date: 05-Aug-2014
# By  : Kevin L. Esteb
#
# These are the messages for XAS messaging modules.
#

[messages]
collector_send         = %s: sent packet to logstash
collector_down         = %s: the logstash connection is down
collector_up           = %s: the logstash connection is up
collector_connected    = %s: connected to %s on %s
collector_unknownmsg   = %s: unknown protocol type: %s
collector_subscribed   = %s: subscribed to %s
collector_receipts     = %s: received a receipt %s
collector_unsubscribed = %s: unsubscribed from %s
collector_errors       = %s: received an error %s, message: %s, reason: %s
collector_unknowntype  = %s: unknown packet type: %s
collector_received     = %s: received message %s, type: "%s" from %s
collector_processed    = %s: processed %s items from: %s; time: %s
collector_pausing      = %s: pausing queue %s
collector_resuming     = %s: resuming queue %s
collector_notype       = %s: no message type defined
collector_waiting      = %s: waiting on connection for: %s
