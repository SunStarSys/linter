FROM ubuntu:latest
USER root
ENV TZ=America/NewYork
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/ubuntu
RUN apt-get update -qq && apt-get upgrade -y -qq && apt-get install -y -qq locales curl ca-certificates net-tools zip make unzip zsh subversion git software-properties-common jq zlib1g-dev libsqlite3-dev python3-pip yamllint pylint tidy clang-tidy apache2-dev libapr1-dev libaprutil1-dev libapache2-mod-perl2 libapache2-mod-apreq2 libapache2-request-perl libsvn-perl git-svn lzop pdfgrep ansible-lint lacheck rustc cargo libbsd-dev libgsl-dev libx11-dev uuid-dev libpng-dev
WORKDIR /tmp
ENV SHELLCHECK_VERSION=v0.10.0
RUN curl -L https://github.com/koalaman/shellcheck/releases/download/$SHELLCHECK_VERSION/shellcheck-$SHELLCHECK_VERSION.linux.x86_64.tar.xz | tar -xJf - && mv shellcheck-$SHELLCHECK_VERSION/shellcheck /usr/local/bin
RUN curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
ENV SHFMT_VERSION=v3.10.0
RUN curl -L https://github.com/mvdan/sh/releases/download/$SHFMT_VERSION/shfmt_${SHFMT_VERSION}_linux_amd64 -o /usr/local/bin/shfmt && chmod +x /usr/local/bin/shfmt
RUN pip3 install -U setuptools parsy docopt pytest-tap --break-system-packages && git clone https://github.com/joesuf4/jinjalint /tmp/jinjalint && (cd /tmp/jinjalint && python3 setup.py install && sed -i -e "s/findall[\\(]'/findall(r'/g" -e "s/split[\\(]'/split(r'/g" /usr/local/lib/python3.12/dist-packages/docopt.py)
#RUN adduser ubuntu && mkdir -p /home/ubuntu && chown ubuntu:ubuntu /home/ubuntu
ENV ASDF_VERSION=v0.16.4
RUN curl -L https://github.com/asdf-vm/asdf/releases/download/$ASDF_VERSION/asdf-$ASDF_VERSION-linux-amd64.tar.gz | tar -xzf - && mv asdf /usr/local/bin && chmod +x /usr/local/bin/asdf
USER ubuntu
ENV ASDF_DATA_DIR="$HOME/.asdf"
ENV NODE_VERSION=23.7.0
ENV PATH="$HOME/bin:$ASDF_DATA_DIR/shims:$(asdf where nodejs)/bin:/usr/local/bin:$PATH:$HOME/.dotnet/tools"
RUN bash -c 'mkdir -p ~ubuntu/bin; echo -e "#!/bin/bash\nexec /usr/bin/curl -k \$@" > ~/bin/curl; chmod +x ~/bin/curl; for pkg in dotnet-core golangci-lint; do asdf plugin add $pkg; v=$(asdf list all $pkg | tail -n 2 | head -n 1); asdf install $pkg $v; echo $pkg $v >>~/.tool-versions; done; asdf plugin add nodejs && asdf install nodejs $NODE_VERSION && echo nodejs $NODE_VERSION >>~/.tool-versions'
RUN bash -c 'dotnet tool install -g dotnet-format --version "7.*" --add-source https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json'
USER root
RUN cpan -f install Test2::Harness
#RUN cpan -f install sealed Algorithm::Diff LCS::BV LCS::XS B::Lint IO::Select URI Term::ReadKey Perl::Critic YAML::XS HTML::Escape Cpanel::JSON::XS URI::Escape Digest::SHA1 FreezeThaw Dotiac::DTL::Addon::markup Time::timegm
RUN pip3 install flake8 black ruff pandas cffi --break-system-packages
USER ubuntu
RUN bash -c 'npm config set strict-ssl false && npm install -g eslint typescript navigator jsdom jquery @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-node stylelint stylelint-config-standard postcss-lit postcss-scss postcss-markdown postcss-html postcss-js remark remark-cli remark-lint-maximum-line-length remark-lint-ordered-list-marker-value remark-message-control remark-preset-lint-consistent remark-lint-list-item-indent remark-validate-links remark-preset-lint-recommended remark-preset-lint-markdown-style-guide'
USER root
ENV NODE_PATH=node_modules:$HOME/.asdf/installs/nodejs/$NODE_VERSION/lib/node_modules
ENV TERM=xterm-256color
ENV LANG=en_US.UTF-8
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV HADOLINT_VERSION=v2.10.0
RUN curl -L https://github.com/hadolint/hadolint/releases/download/$HADOLINT_VERSION/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && chmod 0755 /usr/local/bin/hadolint
RUN mkdir /src && chown ubuntu:ubuntu /src
#RUN apt-get install -y -qq texlive-full
RUN chmod -R a+rx /usr/local/lib/python*/dist-packages
USER ubuntu
ENV USER=ubuntu
RUN git config --global --add safe.directory /src
WORKDIR /src
ENTRYPOINT bash -c "grep '[)]\$' linter.rc | awk '{print \$1}' | cut -d')' -f1 |  xargs -P\$(nproc) -d'\n' -i bash -c 'git diff --name-only \$(git show-branch --merge-base \$BASE)~1 | LINTER={} bash linter.sh'"
