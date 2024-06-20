ARG NODE_BASE
ARG RUBY_BUILDER_BASE
ARG RUBY_RUNNER_BASE

#
# Node.js 関連のツールのコピー元イメージ
#

FROM $NODE_BASE as node

#
# 開発用の依存パッケージのインストールプロセスを動作させるための中間イメージ
#

FROM $RUBY_BUILDER_BASE as ruby_dev

ARG YARN_PATH

WORKDIR /workspace
ENV BUNDLE_APP_CONFIG=/workspace/.bundle

#
# PostgreSQL 用の pg gem をインストールするために必要な（ヘッダを含む）開発用のパッケージを追加
#
RUN apt-get update && apt-get install -y -q --no-install-recommends libpq-dev

#
# asset をコンパイルする Vite で利用する Node.js と関連ツールをコピー
#
RUN mkdir -p /opt
COPY --from=node /usr/local/bin/node /usr/local/bin
COPY --from=node $YARN_PATH /opt/yarn

#
# 必要な言語runtimeのパッケージをインストール
#
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
COPY package.json package.json

# for install phase
ENV NODE_ENV=development

RUN BUNDLE_APP_CONFIG=$PWD/.bundle && \
    bundle config set --local path vendor && \
    bundle config set --local without development:test && \
    bundle install && \
    ln -s /opt/yarn/bin/yarn /usr/local/bin && \
    yarn install

#
# インストール済みのパッケージを退避
#
RUN mkdir -p /packages && \
    cp -r .bundle /packages/.bundle && \
    cp -r vendor /packages/vendor && \
    cp -r node_modules /packages/node_modules

#
# 実際にアプリケーションのコンパイルを行うイメージ
# （JSのトランスパイラが動けばよいのでCコンパイラなどのないものでよい）
#

FROM $RUBY_RUNNER_BASE
ARG POSTGRESQL_VERSION

WORKDIR /workspace
ENV BUNDLE_APP_CONFIG=/workspace/.bundle

#
# （gem はインストール済みのファイルを再利用するので）
# 開発ではなく動作に必要なパッケージだけ追加
#
RUN apt-get update && apt-get install -y -q --no-install-recommends postgresql-client-$POSTGRESQL_VERSION libpq5

#
# 開発用のイメージから必要なファイルをコピー
#
RUN mkdir -p /opt
COPY --from=node /usr/local/bin/node /usr/local/bin
COPY --from=node $YARN_PATH /opt/yarn
COPY --from=ruby_dev /packages/node_modules /packages/node_modules
COPY --from=ruby_dev /packages/vendor /packages/vendor
COPY --from=ruby_dev /packages/.bundle /packages/.bundle

# for build phase
ENV MODE=production
ENV VITE_RUBY_MODE=production
ENV NODE_ENV=production

#
# 実際のコンパイル時には退避済みのパッケージをコピーして始める
#
CMD cp -fr /packages/.bundle . && \
    cp -fr /packages/vendor . && \
    cp -fr /packages/node_modules .

ENTRYPOINT ["bash", "-c"]
