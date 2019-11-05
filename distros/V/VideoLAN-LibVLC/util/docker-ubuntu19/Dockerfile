FROM ubuntu:disco

RUN apt-get update
RUN apt install -y \
    cpanminus \
    make \
    git \
    runit \
    strace \
    vlc \
    libvlc-dev \
    libdist-zilla-perl \
    libdist-zilla-plugin-git-perl \
    libdist-zilla-plugin-ourpkgversion-perl \
    libdist-zilla-plugin-makemaker-awesome-perl \
    libdist-zilla-plugin-podweaver-perl \
    libextutils-pkgconfig-perl \
    libextutils-depends-perl \
    liblog-any-adapter-tap-perl \
    libtest-pod-perl \
 && apt-get clean

RUN cpanm \
    Exporter::Extensible
