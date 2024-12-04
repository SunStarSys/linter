FROM ubuntu:latest
USER root
ENV TZ=America/NewYork
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/ubuntu
RUN apt-get update -qq && apt-get upgrade -y -qq && apt-get install -y -qq locales curl ca-certificates net-tools zip make unzip zsh subversion git software-properties-common jq zlib1g-dev libsqlite3-dev python3-pip yamllint pylint tidy clang-tidy apache2-dev libapr1-dev libaprutil1-dev libapache2-mod-perl2 libapache2-mod-apreq2 libapache2-request-perl libsvn-perl git-svn lzop pdfgrep ansible-lint lacheck rustc cargo libgsl-dev
WORKDIR /tmp
ENV SHELLCHECK_VERSION=v0.9.0
RUN curl -L https://github.com/koalaman/shellcheck/releases/download/$SHELLCHECK_VERSION/shellcheck-$SHELLCHECK_VERSION.linux.x86_64.tar.xz | tar -xJf - && mv shellcheck-$SHELLCHECK_VERSION/shellcheck /usr/local/bin
RUN curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
ENV SHFMT_VERSION=v3.7.0
RUN curl -L https://github.com/mvdan/sh/releases/download/$SHFMT_VERSION/shfmt_${SHFMT_VERSION}_linux_amd64 -o /usr/local/bin/shfmt && chmod +x /usr/local/bin/shfmt
RUN pip3 install -U setuptools parsy --break-system-packages && git clone https://github.com/joesuf4/jinjalint /tmp/jinjalint && (cd /tmp/jinjalint && python3 setup.py install)
#RUN adduser ubuntu && mkdir -p /home/ubuntu && chown ubuntu:ubuntu /home/ubuntu
USER ubuntu
RUN git clone https://github.com/asdf-vm/asdf.git /home/ubuntu/.asdf
ENV PATH="$HOME/bin:$PATH:$HOME/.dotnet/tools"
ENV NODE_VERSION=22.4.1
RUN bash -c '. ~/.asdf/asdf.sh; mkdir -p ~ubuntu/bin; echo -e "#!/bin/bash\nexec /usr/bin/curl -k \$@" > ~/bin/curl; chmod +x ~/bin/curl; for pkg in dotnet-core golangci-lint; do asdf plugin-add $pkg; v="$(asdf list-all $pkg | tail -n 1)"; asdf install $pkg $v; echo $pkg $v >>~/.tool-versions; done; asdf plugin-add nodejs && asdf install nodejs $NODE_VERSION && echo nodejs $NODE_VERSION >>~/.tool-versions'
RUN bash -c '. ~/.asdf/asdf.sh; . ~/.asdf/plugins/dotnet-core/set-dotnet-home.bash; dotnet tool install -g dotnet-format --version "7.*" --add-source https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json'
USER root
RUN pip3 install flake8 black ruff --break-system-packages
#RUN cpan -f install sealed Algorithm::Diff LCS::BV LCS::XS B::Lint IO::Select URI Term::ReadKey Perl::Critic YAML::XS HTML::Escape Cpanel::JSON::XS URI::Escape Digest::SHA1 FreezeThaw Dotiac::DTL::Addon::markup Time::timegm
USER ubuntu
RUN bash -c '. ~/.asdf/asdf.sh; npm config set strict-ssl false && npm install -g eslint typescript navigator jsdom jquery @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-node stylelint stylelint-config-standard postcss-lit postcss-scss postcss-markdown postcss-html postcss-js remark remark-cli remark-preset-lint-consistent remark-lint-list-item-indent remark-validate-links remark-preset-lint-recommended remark-preset-lint-markdown-style-guide'
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
ENTRYPOINT bash -c "grep '[)]\$' linter.rc | awk '{print \$1}' | cut -d')' -f1 |  xargs -P\$(nproc) -d'\n' -i bash -c '. ~/.asdf/asdf.sh; git diff --name-only \$(git show-branch --merge-base HEAD)~1 | LINTER={} bash linter.sh'"
