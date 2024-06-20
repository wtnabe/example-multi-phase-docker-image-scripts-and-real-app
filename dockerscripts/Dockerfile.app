ARG RUNNER

#
# 事前に用意しておいたアプリケーション実行用のベースイメージ
# ここにアプリケーションコードをコピーし、退避済みのパッケージを所定の場所に置いたら完成
#

FROM $RUNNER as runner

WORKDIR /workspace

COPY . .

RUN cp /packages/* /workspace && \
    cp /packages/.bundle /workspace/.bundle && \
    rm /packages/*

#
# multi-stage build で複数の image を作るために準備済みの image を改めて FROM に置いて as で命名
# これ以降は実質 Procfile
#

FROM runner as web

CMD RACK_ENV=production bundle exec rackup -o 0.0.0.0 -p $PORT

FROM runner as cli

CMD RACK_ENV=production bundle exec ruby scripts/hello
