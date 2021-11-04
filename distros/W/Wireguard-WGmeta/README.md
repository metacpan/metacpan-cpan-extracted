![](https://img.shields.io/cpan/v/Wireguard-WGmeta)

# wg-meta

An approach to add metadata to the main wireguard config, written in Perl.

## Highlights

- Compatible with your existing setup (no configuration changes needed).
- A CLI interface with abilities to _set_, _enable_, _disable_, _apply_, _add_ and _remove_ wireguard config nodes.
- A fancy _show_ output which combines metadata, running-config and static-configs.
- Modular structure: The whole parser is independent of the CLI module - and can be used as a standalone library.
- The config parser/writer and as well as the `wg show dump` parser are independent too. For more info, please refer to
  their respective POD.
- Concurrent Access support is built-in.
- No external dependencies, runs on plain Perl (>=v5.22)!

## Installation

Probably the easiest way is through
cpan: [https://metacpan.org/release/Wireguard-WGmeta](https://metacpan.org/release/Wireguard-WGmeta)

### Build from source

```shell
perl Makefile.PL
make test
make install
```

### Using `.deb` package

```shell
sudo dpkg -i wg-meta_X.X.X.deb
```

## Environment variables

- `WIREGUARD_HOME`: Directory containing the Wireguard configuration -> Make sure the path ends with a `/`. Defaults
  to `/etc/wireguard/`.
- `IS_TESTING`: When defined, it has the following effects:
    - `Commands::Set|Enable|Disable` omits the header of the generated configuration files.
    - Line of code is shown for warnings and errors.
- `WG_NO_COLOR`: If defined, the show command does not prettify the output with colors.
- `WGmeta_NO_WG`: If defined, no wireguard commands are run

## Usage

Intended to use as command wrapper for the `wg show` and `wg set` commands. Support for `wg-quick`is enabled by default.

Please note that non-meta attributes have to be specified in the `wg set` _syntax_, which means _AllowedIPs_ becomes
allowed-ips and so on.

```bash
sudo wg-meta show wg0

# output
interface: wg0
  private-key: WG_0_PEER_B_PRIVATE_KEY
  public-key: wg0d845RRItYcmcEW3i+dqatmja18F2P9ujy+lAtsBM=
  listen-port: 51888
  fwmark: off

peer: IPv6_only1
  public-key: WG_0_PEER_A_PUBLIC_KEY
  preshared-key: PEER_A-PEER_B-PRESHARED_KEY
  allowed-ips: fdc9:281f:04d7:9ee9::1/128
  endpoint: 147.86.207.49:10400
  latest-handshake: >month ago
  transfer-rx: 0.26 MiB
  transfer-tx: 1.36 MiB
  persistent-keepalive: off


# Access using peer (note the '+' before 'name' -> we add a previously unseen attribute)
sudo wg-meta set wg0 peer WG_0_PEER_A_PUBLIC_KEY +name Fancy_meta_name

# Access using alias
sudo wg-meta set wg0 IPv6_only1 +description "Some Desc"

# Lets check our newly set attributes
sudo wg-meta show wg0 name description

# output
interface: wg0
  name: (none)
  description: (none)

peer: IPv6_only1
  name: Fancy_meta_name
  description: Some Desc

# Disable peer
sudo wg-meta disable wg0 IPv6_only1

# Enable peer
sudo wg-meta enable wg0 WG_0_PEER_A_PUBLIC_KEY

# Apply config
sudo wg-meta apply wg0

# Add new peer
# Note: To automatically set the DNS and endpoint address, make sure you add #+DNSHost and #+FQDN to your hosts interface config
wg-meta addpeer wg0 10.60.0.10 alias tobi_laptop

[Interface]
Address = 10.60.0.10
ListenPort = 44544
PrivateKey = PEER_PRIVATE_KEY
DNS = 10.20.0.1
#+Alias = tobi_laptop

[Peer]
PublicKey = HOST_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = your.fqdn.con:51888
PersistentKeepalive = 25

```


## Migrating from `0.2.x`

With the introduction of version `0.3.x`, the way custom attributes work has slightly changed:

- There is no "in-config" name for custom attributes anymore, they are written down as initially defined.
- All predefined custom attributes like `name` and `description` have been removed (an exception is the `alias` attribute). To use
your own custom attributes, register them using `WGmeta::Wrapper::Config->new([..], $custom_attributes)` or when using the CLI interface, by prefixing them with `+`. 
  As a consequence `WGmeta::Wrapper::Config->add_peer()` has no `name` parameter anymore, set additional attributes by calling `WGmeta::Wrapper::Config->set()`
  

## Under the hood

The main advantage is that this tool is not dependent on any other storage, metadata is stored inside the corresponding
`wgXX.conf` file (Metadata is prefixed with `#+`):

```text
[Interface]
Address = 10.0.0.7/24
ListenPort = 51888
PrivateKey = WG_0_PEER_B_PRIVATE_KEY

[Peer]
#+Alias = IPv6_only1
#+name = Fancy_meta_name
#+description = Some Desc
PublicKey = WG_0_PEER_A_PUBLIC_KEY
AllowedIPs = fdc9:281f:04d7:9ee9::1/128
Endpoint = wg.example.com
```

Initial development of this project is sponsored by [OETIKER+PARTNER AG](https://oetiker.ch)

