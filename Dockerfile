FROM andremmfaria/linux-dind-build-image:latest
LABEL MAINTAINER="Andre Faria<andremarcalfaria@gmail.com>"

ENV ASPNETCORE_URLS=http://+:80 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    DOTNET_22_SDK_VERSION=2.2.204 \
    DOTNET_21_SDK_VERSION=2.1.604 \
    DOTNET_USE_POLLING_FILE_WATCHER=true \ 
    NUGET_XMLDOC_MODE=skip \
    NODEJS_VERSION=8.14.0-r0 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Add proper repositories to package managers
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/main" >> /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/main" >> /etc/apk/repositories

# Update system and install requirements
RUN apk update && \
    apk add --no-cache \
    curl \
    nodejs=$NODEJS_VERSION \
    nodejs-npm=$NODEJS_VERSION \
    ca-certificates \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.0 \
    libstdc++ \
    lttng-ust \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs

# Fix corporate downloads
RUN npm config set unsafe-perm true

RUN apk add --no-cache --virtual .build-deps openssl && \
    curl https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_21_SDK_VERSION/dotnet-sdk-$DOTNET_21_SDK_VERSION-linux-musl-x64.tar.gz -o dotnet.tar.gz -# && \
    dotnet_sha512='98ea20e31c8509a83c212eb42fca28f2fb1327f7fbff5fe4cf70038f4d84a9203ed1fb185b3cb40f3f7fb9ad3837296ed4441054070f1c6d2a7998ecf98446a1' && \
    echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - && \
    mkdir -p /usr/share/dotnet21 && \
    tar -C /usr/share/dotnet21 -xzf dotnet.tar.gz && \
    ln -s /usr/share/dotnet21/dotnet /usr/bin/dotnet21 && \
    rm dotnet.tar.gz && \
    apk del .build-deps

RUN curl https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_22_SDK_VERSION/dotnet-sdk-$DOTNET_22_SDK_VERSION-linux-musl-x64.tar.gz -o dotnet.tar.gz -# && \
	  dotnet_sha512='025e2b52cb3b082583ae7071d414db3725989ba7c16b28fb9e5ddf0427f713f0e8b152aadd87137c1e6e2dc64403a7c7b697ec992f00507f5dbf17f1f4f4eb71' && \
    echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - && \
    mkdir -p /usr/share/dotnet22 && \
    tar -C /usr/share/dotnet22 -xzf dotnet.tar.gz && \
    ln -s /usr/share/dotnet22/dotnet /usr/bin/dotnet22 && \
    mkdir -p /root/.nuget/NuGet && \
    rm dotnet.tar.gz

COPY nuget.config /root/.nuget/NuGet/NuGet.Config

# Trigger first run experience by running arbitrary cmd to populate local package cache
RUN ln -s /usr/share/dotnet22/dotnet /usr/bin/dotnet && \
    dotnet22 help && \
    dotnet21 help
