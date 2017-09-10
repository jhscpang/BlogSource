---
title: 解决elasticsearch的JestClient查询数据超时问题
date: 2017-09-10 13:51:24
categories: ELK
tags: 
    - ELK
---

## 概述

但是用elasticsearch(简称es)提供的Java API：JestClient访问es里面的数据的时候，可能出现如下问题：

__异常信息__

``` java
java.net.SocketTimeoutException: Read timed out
	at java.net.SocketInputStream.socketRead0(Native Method)
	at java.net.SocketInputStream.read(SocketInputStream.java:152)
	at java.net.SocketInputStream.read(SocketInputStream.java:122)
	at org.apache.http.impl.io.SessionInputBufferImpl.streamRead(SessionInputBufferImpl.java:139)
	at org.apache.http.impl.io.SessionInputBufferImpl.fillBuffer(SessionInputBufferImpl.java:155)
	at org.apache.http.impl.io.SessionInputBufferImpl.readLine(SessionInputBufferImpl.java:284)
	at org.apache.http.impl.conn.DefaultHttpResponseParser.parseHead(DefaultHttpResponseParser.java:140)
	at org.apache.http.impl.conn.DefaultHttpResponseParser.parseHead(DefaultHttpResponseParser.java:57)
	at org.apache.http.impl.io.AbstractMessageParser.parse(AbstractMessageParser.java:261)
	at org.apache.http.impl.DefaultBHttpClientConnection.receiveResponseHeader(DefaultBHttpClientConnection.java:165)
	at org.apache.http.impl.conn.CPoolProxy.receiveResponseHeader(CPoolProxy.java:167)
	at org.apache.http.protocol.HttpRequestExecutor.doReceiveResponse(HttpRequestExecutor.java:272)
	at org.apache.http.protocol.HttpRequestExecutor.execute(HttpRequestExecutor.java:124)
	at org.apache.http.impl.execchain.MainClientExec.execute(MainClientExec.java:271)
	at org.apache.http.impl.execchain.ProtocolExec.execute(ProtocolExec.java:184)
	at org.apache.http.impl.execchain.RetryExec.execute(RetryExec.java:88)
	at org.apache.http.impl.execchain.RedirectExec.execute(RedirectExec.java:110)
	at org.apache.http.impl.client.InternalHttpClient.doExecute(InternalHttpClient.java:184)
	at org.apache.http.impl.client.CloseableHttpClient.execute(CloseableHttpClient.java:82)
	at org.apache.http.impl.client.CloseableHttpClient.execute(CloseableHttpClient.java:107)
	at io.searchbox.client.http.JestHttpClient.executeRequest(JestHttpClient.java:118)
	at io.searchbox.client.http.JestHttpClient.execute(JestHttpClient.java:57)
	at com.edu.bjtu.JestClientUtil.test(JestClientUtil.java:54)
	at com.edu.bjtu.JestClientUtil.main(JestClientUtil.java:63)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:606)
	at com.intellij.rt.execution.application.AppMain.main(AppMain.java:147)
```

## 解决方案

该问题出现的原因是JestCilent默认的超时时间是3s，当使用JestClient访问es集群里面的数据超过3s的时候，就回出现Read time out异常，这跟传输给es的查询query字符串中设置的timeout无关。

那么，解决该问题的方案是在构建JestClient对象的时候，加上readTimeout(20000)设置，将超时时间设置的长一点(这里使用的是20秒，可根据具体业务情况设置成合适的数值)


__关键代码__

```java
public static JestClient getJestClient() {
        JestClientFactory factory = new JestClientFactory();
        factory.setHttpClientConfig(new HttpClientConfig.Builder("http://10.113.130.29:8223/")
                .multiThreaded(true)
                .readTimeout(20000) //默认是3s，加上该设置防止超时
                .build());
        JestClient client = factory.getObject();
        return client;
    }
```

## 完整示例

下面给出完整示例，项目使用的是maven项目结构，项目的reources目录下有一个query.txt文件，里面记录的是发送给es集群查询的query字符串。代码逻辑分如下几步：
  1. 从文件获取query字符串
  2. 构建JestClient对象
  3. 向es集群发起查询

__pom文件__

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>cn.edu.bjtu</groupId>
  <artifactId>testjest</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>jar</packaging>

  <name>testjest</name>
  <url>http://maven.apache.org</url>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.elasticsearch</groupId>
      <artifactId>elasticsearch</artifactId>
      <version>2.4.0</version>
    </dependency>
    <!-- https://mvnrepository.com/artifact/io.searchbox/jest -->
    <dependency>
      <groupId>io.searchbox</groupId>
      <artifactId>jest</artifactId>
      <version>2.4.0</version>
    </dependency>
    <dependency>
      <groupId>com.google.guava</groupId>
      <artifactId>guava</artifactId>
      <version>18.0</version>
    </dependency>
  </dependencies>
</project>

```

__JestClientUtil.java__

```java
package com.edu.bjtu;

import com.google.common.base.Charsets;
import com.google.common.io.Files;
import io.searchbox.client.JestClient;
import io.searchbox.client.JestClientFactory;
import io.searchbox.client.JestResult;
import io.searchbox.client.config.HttpClientConfig;
import io.searchbox.core.Search;
import io.searchbox.params.SearchType;

import java.io.File;
import java.io.IOException;
import java.util.List;

/**
 * Created by pangchao on 2017/9/8.
 */
public class JestClientUtil {

    private static final String INDEX_NAME = "un_prism-baiyi.2017.08";

    public static JestClient getJestClient() {
        JestClientFactory factory = new JestClientFactory();
        factory.setHttpClientConfig(new HttpClientConfig.Builder("http://10.113.130.29:8223/")
                .multiThreaded(true)
                .readTimeout(20000) //默认是3s，加上该设置防止超时
                .build());
        JestClient client = factory.getObject();
        return client;
    }

    public static String getQuery() {
        File newFile = new File("src/main/resources/query.txt");
        List<String> lines = null;
        try {
            lines = Files.readLines(newFile, Charsets.UTF_8);
            for (String line : lines) {
                System.out.println(line);
            }
            return lines.get(0);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }

    public static void test() {
        String query = getQuery();
        Search.Builder searchBuilder = new Search.Builder(query).addIndex(INDEX_NAME).setSearchType(SearchType.COUNT);
        Search search = searchBuilder.build();
        JestClient client = getJestClient();
        try {
            JestResult rs = client.execute(search);
            System.out.println(rs.getJsonString());
            client.shutdownClient();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        test();
    }
}
```