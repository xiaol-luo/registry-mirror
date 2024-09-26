# 自建 Docker 镜像加速&缓存服务

> 利用 Registry 的 [镜像代理与缓存](https://docs.docker.com/registry/recipes/mirror/) 功能加速&缓存镜像，同时支持 dockerhub、gcr.io、quay.io、nvcr.io、registry.k8s.io 等多个仓库，保持原有仓库的镜像tag不变，且一次拉取之后打包整个仓库目录可离线使用，

## 1. 安装docker

```sh
git clone https://github.com/brighill/registry-mirror.git
cd registry-mirror
./get-docker.sh --mirror Aliyun
```

## 2. 生成证书

```sh
./gencert.sh
```

## 3. 启动服务端(本地环境或海外vps二选一)

### 本地环境

*从镜像源或者内部镜像仓库拉取镜像（以m.daocloud.io为例）*

```sh
docker pull m.daocloud.io/docker.io/library/registry:2.8.3
docker pull m.daocloud.io/docker.io/library/nginx:alpine
docker tag m.daocloud.io/docker.io/library/registry:2.8.3 registry:2.8.3 
docker tag m.daocloud.io/docker.io/library/nginx:alpine nginx:alpine
```

*设置代理（代理服务器需要允许局域网访问，且ip不能指定为127.0.0.1）*

```sh
# 例1: socks5 代理 ip 192.168.1.1  端口 1080
export PROXY=socks5://192.168.1.1:1080

# 例2: http 代理ip 192.168.1.1 端口 1080
export PROXY=http://192.168.1.1:1080
```

*启动服务*

```sh
docker compose up -d
```

### 海外 vps

```sh
docker compose up -d
```

## 4. 配置客户端
### 劫持域名解析

*以自建仓库ip为192.168.1.1为例，修改/etc/hosts 添加以下内容*  

```sh
192.168.1.1 gcr.io quay.io docker.io registry-1.docker.io nvcr.io registry.k8s.io custom.local my.io
```

### 信任证书

*以下命令假设已经把第二步生成的 cert/ca.crt 上传到当前目录下的 **cert/ca.crt***

```sh
# macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain cert/ca.crt
```

```sh
# Debian/Ubuntu
sudo apt install ca-certificates
sudo cp cert/ca.crt /usr/local/share/ca-certificates/ca.crt
sudo update-ca-certificates
```

```sh
# CentOS/Fedora/RHEL
sudo yum install ca-certificates
sudo update-ca-trust force-enable
sudo cp cert/ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

### 如果想支持push自己的image到my.io，需要修改docker配置文件
vim /etc/docker/daemon.json
```
{
	"registry-mirrors": ["https://my.io"],
	"insecure-registries": ["my.io"]
}
```

### 重启docker

```sh
systemctl daemon-reload
systemctl restart docker
```

### 测试

```sh
# Docker Hub
docker pull alpine
# registry.k8s.io
docker pull registry.k8s.io/pause:3.9
# quay.io
docker pull quay.io/coreos/etcd:v3.4.33
# gcr.io
docker pull gcr.io/google-containers/pause:3.2
# ghcr.io
docker pull ghcr.io/coder/coder:v2.13.0
# nvcr.io
docker pull nvcr.io/nvidia/k8s/cuda-sample:devicequery
```

### 测试my.io
```sh
docker pull hello-world
docker tag hello-world my.io/hello
docker push my.io/hello
curl -k  https://my.io/v2/_catalog
docker rmi my.io/hello
docker pull my.io/hello
```

### 如何删除my.io中的镜像
- [有文章提到](https://github.com/burnettk/delete-docker-registry-image)
- [文章2，看简易版部分](https://blog.csdn.net/u014756339/article/details/121289329)
    - curl -k  https://127.0.0.1/v2/_catalog
    - 删掉想删掉的镜像
    - （推荐）去 registry-mirror/data/docker/registry/v2/repositories 找到镜像并删除
    - 或者
    - （不推荐）docker exec custom  rm -rf /var/lib/registry/docker/registry/v2/repositories/hello1
    - （貌似不做也行) docker exec custom  /bin/registry garbage-collect /etc/docker/registry/config.yml
    - curl -k  https://127.0.0.1/v2/_catalog

```


```