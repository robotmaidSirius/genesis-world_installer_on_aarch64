# genesis-world_installer_on_aarch64

[WARNING]
 * 作成中です。内容が不完全です。
   * 呼び出しているスクリプト単体でテスト中。インストール手順記載のスクリプトではまだ動かしてない。
   * genesis-worldのインストールは成功
   * VTKのインストールが出来てない
   * venvの環境でpytorchのインストールが出来てない。CPU版をインストールしている

```bash
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```


## Overview

* アーキテクチャ"Aarch64"で動作する[Genesis](https://github.com/Genesis-Embodied-AI/Genesis)のインストールするためのスクリプトです
* 使用しているライブラリでJetsonで使えるようにIssueが立っているため、通常のインストール手順でインスール可能になる可能性があります。

```bash
# 通常のインストール手順
python3 -m pip install --upgrade pip
pip install genesis-world
```

この手順は、それまでの暫定対応です。


## 対象バージョン

* 主な対象はNVIDIA Jetsonシリーズです。
確認したバージョンを下記に記載してます。

### Jetson Orin NX(Jetpack 5.1.1)

| ソフトウェア  | バージョン       | Notes                                           |
| ------------- | ---------------- | ----------------------------------------------- |
| genesis-world | 2.0.1            |                                                 |
| OS            |                  |                                                 |
| Ubuntu        | 20.04.6 LTS      |                                                 |
| ビルド環境    |                  |                                                 |
| python(pyenv) | 3.11.11          |                                                 |
| cmake         | 3.31.5           |                                                 |
| llvm          | 15.0.5           | apt管理では対象外のため、ビルドしなおしてます。 |
| clang         | 15.0.5           | apt管理では対象外のため、ビルドしなおしてます。 |
| libstdc++     | libstdc++-10-dev |                                                 |
| 関連ソフト    |                  |                                                 |
| taichi        | v1.7.3           |                                                 |
| tetgen        | v0.6.5           |                                                 |
| libigl        | 2.4.1            |                                                 |
| PyMeshLab     | v2023.12.post2   |                                                 |
| CoACD         | 1.0.1            |                                                 |

| ハードウェア   | バージョン    | Notes |
| -------------- | ------------- | ----- |
| Jetson Orin NX | Jetpack 5.1.1 |       |


## インストール方法

```bash
# ビルド時にメモリが足りずにこける現象を確認してます。ビルド時のJOBS数を制限してます。
export MAX_JOBS=4

bash install_genesis_on_aarch64.sh
```

### 手順

1. cmakeを最新に更新する
2. Python仮想環境を作成する
   1. pyenvでpython3.11をインストールする
   2. venvで仮想環境を作成する
3. llvmとclangをビルドする
4. apt管理のソフトをインストールする
5. pip管理のライブラリをインストールする
6. pythonのライブラリをビルド＆インストールする
   1. taichiをビルド＆インストールする
7. Genesisをインストールする


### その他

* メモリは8GB以上を推奨します。それ以下の場合は、スワップ領域を確保してください。
* libiglのビルド時には、メモリが足りない場合があります。
   * 対策１： ビルド時間がかかるが、```export MAX_JOBS=2```など値を減らし動作させるコア数を減らす
   * 対策２： スワップ領域を増やす。（非推奨：１コアだけで数GB使っている事があるため）
* ```taichi```は「./build.py」を実施してないが、このスクリプトでインストールするソフトが必要かもしれません

### Authors and acknowledgment

We extend our heartfelt gratitude to the pioneers who have generously shared their invaluable contributions with us. The hardware, libraries, and tools they have provided have breathed life into our development journey. Each line of code and every innovation has woven a tapestry of brilliance, illuminating our path forward. In this symphony of ingenuity, we find ourselves humbled and inspired. These offerings infuse our project with boundless possibilities. As we create, their work serves as our guiding star, reminding us that collaboration can transform dreams into reality. With deep appreciation, we honor the open-source universe that continues to nurture our journey of discovery and growth.
