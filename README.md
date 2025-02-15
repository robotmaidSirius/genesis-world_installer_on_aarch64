# genesis-world_installer_on_aarch64

## Overview

* アーキテクチャ"Aarch64"用の[Genesis](https://github.com/Genesis-Embodied-AI/Genesis)のPython whlを作成し、インストールするスクリプトです。
* Aarch64の環境でのインストールが**まだ**できないため、このスクリプトを作成しました。
* NVIDIA Jetsonシリーズで使う事を想定しています。その他の環境でも動作するかもしれませんが確認していません。

## インストール方法

### Python whl

リリースノートを確認してください。

### ソースコードからビルドする場合

ソースコードからビルドする場合は```config.json```で動作を制御できます


```bash
bash install_genesis_on_aarch64.sh
```

#### config.jsonの設定

* 共通設定

| パラメータ         | デフォルト値    | 説明                                           |
| :----------------- | :-------------- | :--------------------------------------------- |
| reinstall          | false           | 再インストールする場合はtrueにする             |
| install_path       | ${HOME}/genesis | Genesisをインストールするディレクトリ          |
| venv_name          | venv_genesis    | 仮想環境の名前                                 |
| pyenv.install      | true            | pyenvをインストールする場合はtrueにする        |
| pyenv.path         | ${HOME}/.pyenv  | pyenvをインストールするディレクトリ            |
| pyenv.write_bashrc | false           | .bashrcにpyenvの設定を書き込む場合はtrueにする |

* パッケージ管理ソフトの設定

| パラメータ        | デフォルト値 | 説明                                                          |
| :---------------- | :----------- | :------------------------------------------------------------ |
| packages.skip.apt | false        | aptでインストールするパッケージをスキップする場合はtrueにする |
| packages.skip.pip | false        | pipでインストールするパッケージをスキップする場合はtrueにする |

* インストールするパッケージのバージョン
  * genesis-worldのバージョンに合わせて設定してください

| パラメータ                 | デフォルト値   | 説明                  |
| :------------------------- | :------------- | :-------------------- |
| packages.version.python    | 3.11.11        | Pythonのバージョン    |
| packages.version.cmake     | 3.31.5         | cmakeのバージョン     |
| packages.version.llvm      | 15.0.5         | LLVMのバージョン      |
| packages.version.CoACD     | 1.0.5          | CoACDのバージョン     |
| packages.version.vtk       | 9.4.1          | VTKのバージョン       |
| packages.version.taichi    | v1.7.3         | Taichiのバージョン    |
| packages.version.libigl    | 2.4.1          | libiglのバージョン    |
| packages.version.PyMeshLab | v2023.12.post2 | PyMeshLabのバージョン |
| packages.version.tetgen    | v0.6.4         | tetgenのバージョン    |
| packages.version.genesis   | v0.2.1         | Genesisのバージョン   |

* ハードウェア毎の個別設定

| パラメータ             | デフォルト値 | 説明                                         |
| :--------------------- | :----------- | :------------------------------------------- |
| soc                    | jetpack5     | 呼び出したいパラメータ```hardware.*```の名前 |
| hardware.*.pytorch     | v2.3.1       | socで指定されたPyTorchのバージョン           |
| hardware.*.torchvision | v0.18.1      | socで指定されたTorchVisionのバージョン       |
| hardware.*.torchaudio  | v2.3.1       | socで指定されたTorchAudioのバージョン        |


### その他

* Raspberry Pi 4B(Ubuntu 22.04)でのコンパイルについて、apt管理しているライブラリでバージョン問題を確認してます。
  * 手動で以下をインストールしてます。
    * libstdc++-11-dev
    * cython3
* メモリは8GB以上を推奨します。それ以下の場合は、スワップ領域を確保してください。
* libiglのビルド時には、メモリが足りない場合があります。その場合は```-j```オプションでビルドするスレッド数を減らしてください。

```bash
bash install_genesis_on_aarch64.sh -j 2
```

### ToDo

* [ ] "genesis-world v0.2.1(tag)"はsetup.pyがないため、mainブランチで実施。v0.2.2以以降からスクリプトのコメントアウトを外せるはず
* [ ] cmakeのインストールは aptで実施している。tarのオプションを検証する
* [ ] LLVM-15のインストールにすごく時間がかかる。apt管理のLLVMで対応できるか検証する
* [ ] pytorchなどのSoC毎のスクリプトの動作確認をする

### Authors and acknowledgment

We extend our heartfelt gratitude to the pioneers who have generously shared their invaluable contributions with us. The hardware, libraries, and tools they have provided have breathed life into our development journey. Each line of code and every innovation has woven a tapestry of brilliance, illuminating our path forward. In this symphony of ingenuity, we find ourselves humbled and inspired. These offerings infuse our project with boundless possibilities. As we create, their work serves as our guiding star, reminding us that collaboration can transform dreams into reality. With deep appreciation, we honor the open-source universe that continues to nurture our journey of discovery and growth.
