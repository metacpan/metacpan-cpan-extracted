# INSTALLATION INSTRUCTIONS

```bash
perl Makefile.PL
make
make test
sudo make install
make clean
```

## REQUIREMENTS

* Acrux (libacrux-perl)
* Acrux::DBI (libacrux-dbi-perl)

## INSTALLATION ON RHEL 9 (ROCKY LINUX 9.x)

1. Install the abalama repository

```bash
sudo dnf clean all
sudo crb enable
sudo dnf install epel-release
sudo dnf install https://dist.suffit.org/repo/rhel9/abalama-release-1.03-2.el9.noarch.rpm
```

2. Install project

```bash
sudo dnf install perl-WWW-Suffit-Model
```

# INSTALLATION ON UBUNTU 24.x

```bash
sudo add-apt-repository ppa:abalama/v1.00
sudo apt update
sudo apt install libwww-suffit-model-perl
```
