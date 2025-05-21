## Dify 1.0 Plugin Downloading and Repackaging


### Prerequisites

Operating System: Linux amd64

Requires Python version is 3.11 or higher

#### Clone
```shell
git clone https://github.com/junjiem/dify-plugin-repackaging.git
```



### Description

#### From the Dify Marketplace downloading and repackaging

![market](images/market.png)

##### Example

![market-example](images/market-example.png)

```shell
./plugin_repackaging.sh market langgenius agent 0.0.9
```

![langgenius-agent](images/langgenius-agent.png)



#### From the Github downloading and repackaging

![github](images/github.png)

##### Example

![github-example](images/github-example.png)

```shell
./plugin_repackaging.sh github junjiem/dify-plugin-agent-mcp_sse 0.0.1 agent-mcp_see.difypkg
```

![junjiem-mcp_sse](images/junjiem-mcp_sse.png)



#### Local Dify package repackaging

![local](images/local.png)

##### Example

```shell
./plugin_repackaging.sh local ./db_query.difypkg
```

![db_query](images/db_query.png)

## Offline Plugin Repackaging with Docker

This method uses Docker and Docker Compose to provide a stable Ubuntu 24.04 environment for repackaging plugins. It processes all `.difypkg` files found in a specified input directory and places the offline versions in an output directory.

### Prerequisites for Docker Repackaging

- Docker installed (see [Docker installation guide](https://docs.docker.com/engine/install/))
- Docker Compose installed (see [Docker Compose installation guide](https://docs.docker.com/compose/install/))

### How to Use Docker Repackaging

1.  **Prepare Directories:**
    In the root of this project, create two directories if they don't already exist:
    - `difypkg`: This is where you will place your original `.difypkg` plugin files that you want to convert to offline packages.
    - `offline_difypkg`: This is where the script will save the repackaged offline plugins.

2.  **Place Your Plugins:**
    Copy the `.difypkg` files you want to process into the `./difypkg` directory.

3.  **Build and Run:**
    Open your terminal in the root of this project and run the following commands:

    ```shell
    # Build the Docker image (only needed the first time or if you change Dockerfile/scripts)
    docker-compose build

    # Run the repackaging process
    docker-compose up
    ```

4.  **Retrieve Offline Plugins:**
    Once the process is complete (you'll see "All plugins processed." in the terminal output), you will find your repackaged `*-offline.difypkg` files in the `./offline_difypkg` directory.

    You can then stop the Docker Compose process (usually with `Ctrl+C` in the terminal where `docker-compose up` is running). If you run `docker-compose up -d` in the future for detached mode, you would use `docker-compose down` to stop and remove the containers.

This process leverages the `entrypoint.sh` script to automatically find and convert all plugins in the `difypkg` directory.

### Update Dify platform env  Dify平台放开限制

- your .env configuration file: Change `FORCE_VERIFYING_SIGNATURE` to `false` , the Dify platform will allow the installation of all plugins that are not listed in the Dify Marketplace.

- your .env configuration file: Change `PLUGIN_MAX_PACKAGE_SIZE` to `524288000` , and the Dify platform will allow the installation of plug-ins within 500M.

- your .env configuration file: Change `NGINX_CLIENT_MAX_BODY_SIZE` to `500M` , and the Nginx client will allow uploading content up to 500M in size.



- 在 .env 配置文件将 `FORCE_VERIFYING_SIGNATURE` 改为 `false` ，Dify 平台将允许安装所有未在 Dify Marketplace 上架（审核）的插件。

- 在 .env 配置文件将 `PLUGIN_MAX_PACKAGE_SIZE` 增大为 `524288000`，Dify 平台将允许安装 500M 大小以内的插件。

- 在 .env 配置文件将 `NGINX_CLIENT_MAX_BODY_SIZE` 增大为 `500M`，Nginx客户端将允许上传 500M 大小以内的内容。




### Installing Plugins via Local 通过本地安装插件

Visit the Dify platform's plugin management page, choose Local Package File to complete installation.

访问 Dify 平台的插件管理页，选择通过本地插件完成安装。

![install_plugin_via_local](./images/install_plugin_via_local.png)

