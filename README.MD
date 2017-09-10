## 介绍

该项目是技术博客的源码文件夹，发布时会将public文件夹下面的文件进行发布

## 部署说明

该项目部署步骤如下：
  1. 将源码项目clone到本地：git clone git@github.com:jhscpang/BlogSource.git
  2. 在当前目录下创建存储部署文件的文件夹： mkdir deploy
  3. 将部署项目clone到deploy目录下： cd deploy && git clone git@github.com:jhscpang/jhscpang.github.io.git

## 日常使用说明

经过上部分的部署说明部署成功以后，日常写博客的步骤如下：
  1. 在根目录创建新文章： hexo n "article name"
  2. 编写博客
  3. 在本地部署看效果：hexo s
  4. 部署到远程服务器：sh deploy.sh