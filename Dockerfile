FROM ruby:2.5.8

RUN apt-get update && apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget libev-dev ninja-build clang libncurses-dev libtinfo5 && rm -rf /var/lib/apt/lists/*

ENV LANG C.UTF-8
ENV RAILS_ENV production

RUN git clone https://gn.googlesource.com/gn
WORKDIR /gn
RUN sed -i -e "s/-Wl,--icf=all//" build/gen.py && python build/gen.py && ninja -C out

RUN git clone --recursive git://github.com/rubyjs/libv8.git
WORKDIR /gn/libv8
RUN bundle install
RUN bundle exec rake compile; exit 0

RUN wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-aarch64-linux-gnu.tar.xz && \
    tar xf clang+llvm-10.0.0-aarch64-linux-gnu.tar.xz && \
    rm -rf vendor/v8/third_party/llvm-build/Release+Asserts/bin && \
    rm -rf vendor/v8/third_party/llvm-build/Release+Asserts/lib
RUN mv clang+llvm-10.0.0-aarch64-linux-gnu/* vendor/v8/third_party/llvm-build/Release+Asserts && \
    rm -rf clang+llvm-10.0.0-aarch64-linux-gnu.tar.xz clang+llvm-10.0.0-aarch64-linux-gnu
RUN cp /gn/out/gn vendor/v8/buildtools/linux64/ && \
    cp /usr/bin/ninja vendor/depot_tools/ninja
RUN bundle exec rake compile && \
    bundle exec rake binary && \
    gem install /gn/libv8/pkg/libv8-8.4.255.0-aarch64-linux.gem

WORKDIR /app

ADD Gemfile* ./
RUN bundle install --without development test && \
  rm -rf Gemfile* && \
  rm -rf /gn
