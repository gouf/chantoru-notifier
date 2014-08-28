chantoru-notifier
=================

[![Code Climate](https://codeclimate.com/github/gouf/chantoru-notifier/badges/gpa.svg)](https://codeclimate.com/github/gouf/chantoru-notifier)

[nasne](http://www.jp.playstation.com/nasne/) と連携するするサービス、[CHAN-TORU](https://tv.so-net.ne.jp/chan-toru/) から、録画済みリストを取得し、メールでお知らせするツールです。

---

起動にあたって必要な環境変数がいくつかあります。

* Amazon Web Services SDK で利用する```AWS_ACCESS_KEY_ID```, ```AWS_SECRET_ACCESS_KEY```
* Amazon SES で設定した送信元メールアドレス : ```CHANTORU_FROM```
* CHAN-TORU にログインするためのID/PASSWORD : ```CHANTORU_ID```, ```CHANTORU_PASS```

もっともシンプルな起動方法は```nohup``` を使った起動方法になるでしょう。

```
nohup ruby chantoru_notifier.rb >/dev/null 2>&1
```

その他に、Docker によるコンテナ化を利用する方法もあります。

```
docker build -t chantoru .
docker run -it -e -d chantoru
docker run -it -d -e CHANTORU_ID=mail@com -e CHANTORU_PASS=passwd -e AWS_ACCESS_KEY_ID=access_key -e AWS_SECRET_ACCESS_KEY=secret_access_key -e CHANTORU_FROM=from@address.com chantoru
```
