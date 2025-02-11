# スワップ領域の拡張方法

## 現在のスワップ領域の確認

```bash
free -h
```

## 手段

### 方法1

Jetsonならば、```jtop```のMEMの項目でGUI操作で拡張できます。

### 方法2

自身でswapfileを追加する方法は下記になります。

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
```

テキストエディタ```sudo vi /etc/fstab```を開き、以下の行を追加する。

```text
/swapfile none swap defaults 0 0
```

上記を終えたら再起動する
