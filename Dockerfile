FROM registry.aliyuncs.com/pkyit/java:jdk17

ARG MAVEN_VERSION=3.9.6
ARG GRADLE_VERSION=8.7

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
    MAVEN_HOME=/opt/maven \
    MAVEN_LOCAL_REPO=/tmp/artifacts/m2 \
    MAVEN_ARGS="" \
    MAVEN_ARGS_APPEND="" \
    MAVEN_OPTS="" \
    MAVEN_S2I_GOALS="clean package" \
    MAVEN_S2I_ARTIFACT_DIRS="target" \
    MAVEN_CLEAR_REPO="false" \
    MAVEN_MIRROR_URL="https://maven.aliyun.com/repository/public" \
    MAVEN_MIRROR_OF="central" \
    GRADLE_HOME=/opt/gradle \
    GRADLE_USER_HOME=/tmp/artifacts/.gradle \
    GRADLE_ARGS="" \
    GRADLE_S2I_TASKS="clean build" \
    S2I_SOURCE_DIR=/tmp/src \
    S2I_ARTIFACTS_DIR=/tmp/artifacts \
    S2I_TARGET_DEPLOYMENTS_DIR=/deployments \
    S2I_DELETE_SOURCE="true" \
    S2I_ENABLE_INCREMENTAL_BUILDS="true" \
    JAVA_APP_DIR=/deployments \
    JAVA_OPTS="" \
    JAVA_OPTS_APPEND="" \
    JAVA_APP_JAR="" \
    JAVA_MAIN_CLASS="" \
    JAVA_ARGS="" \
    JAVA_MAX_MEM_RATIO="80" \
    JAVA_INIT_MEM_RATIO="" \
    JAVA_DIAGNOSTICS="" \
    JAVA_DEBUG="" \
    JAVA_DEBUG_PORT="5005" \
    JAVA_DEBUG_SUSPEND="n" \
    GC_MIN_HEAP_FREE_RATIO="10" \
    GC_MAX_HEAP_FREE_RATIO="20" \
    GC_TIME_RATIO="4" \
    GC_ADAPTIVE_SIZE_POLICY_WEIGHT="90" \
    GC_CONTAINER_OPTIONS="" \
    DEPLOYMENTS_DIR=/deployments \
    HOME=/home/s2i \
    PATH=/opt/maven/bin:/opt/gradle/bin:$PATH

# ---- Install system dependencies ----
RUN apk add --no-cache bash curl git findutils coreutils procps net-tools

# ---- Download Maven from Aliyun mirror (reliable in China) ----
RUN echo "=== Installing Maven ${MAVEN_VERSION} ===" \
    && curl -fsSL -o /tmp/maven.tar.gz \
       "https://mirrors.aliyun.com/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    || curl -fsSL -o /tmp/maven.tar.gz \
       "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    && tar xzf /tmp/maven.tar.gz -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm -f /tmp/maven.tar.gz

# ---- Download Gradle from Tencent mirror (reliable in China) ----
RUN echo "=== Installing Gradle ${GRADLE_VERSION} ===" \
    && curl -fsSL -o /tmp/gradle.zip \
       "https://mirrors.cloud.tencent.com/gradle/gradle-${GRADLE_VERSION}-bin.zip" \
    || curl -fsSL -o /tmp/gradle.zip \
       "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    && unzip -qo /tmp/gradle.zip -d /opt \
    && mv /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    && rm -f /tmp/gradle.zip \
    && mkdir -p /opt/gradle/init.d

# ---- Verify installations ----
RUN mvn --version && gradle --version && echo "=== Build tools installed ==="

# ---- Gradle Aliyun mirror init script ----
COPY s2i/aliyun-mirror.gradle /opt/gradle/init.d/aliyun-mirror.gradle

# ---- Create directories ----
RUN mkdir -p /deployments /tmp/src /tmp/artifacts /home/s2i \
    && chmod -R g+rwX /deployments /tmp/src /tmp/artifacts /home/s2i

# ---- Add s2i user for OpenShift compatibility ----
RUN adduser -D -u 1001 -h /home/s2i -s /bin/bash s2i 2>/dev/null || true \
    && addgroup s2i root 2>/dev/null || true \
    && echo "s2i:x:1001:0:S2I User:/home/s2i:/bin/bash" >> /etc/passwd

# ---- Copy S2I scripts ----
COPY s2i/bin/ /usr/libexec/s2i/
RUN chmod -R a+rx /usr/libexec/s2i/ \
    && chown -R 1001:0 /deployments /home/s2i /tmp/artifacts \
    && chmod -R g+rwX /deployments /home/s2i /tmp/artifacts

# ---- S2I Labels ----
LABEL io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.openshift.s2i.destination="/tmp" \
      io.openshift.tags="builder,java,java17" \
      io.k8s.description="Platform for building and running Java 17 applications (Maven/Gradle)" \
      io.k8s.display-name="Java 17 S2I Builder" \
      io.openshift.expose-services="" \
      maintainer="pkyit"

USER 1001
WORKDIR /deployments
CMD ["/usr/libexec/s2i/usage"]
