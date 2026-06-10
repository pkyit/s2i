FROM registry.cn-hangzhou.aliyuncs.com/pkyit/s2i:java17 AS builder

USER root
COPY . /tmp/src/
RUN /usr/libexec/s2i/assemble

# ---- Lean Runtime Stage: JDK only, no Maven/Gradle ----
FROM registry.aliyuncs.com/pkyit/java:jdk17

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
    JAVA_APP_DIR=/deployments \
    DEPLOYMENTS_DIR=/deployments \
    JAVA_MAX_MEM_RATIO="80" \
    JAVA_OPTS="" \
    JAVA_OPTS_APPEND="" \
    JAVA_APP_JAR="" \
    JAVA_MAIN_CLASS="" \
    JAVA_ARGS="" \
    JAVA_DEBUG="" \
    JAVA_DEBUG_PORT="5005" \
    JAVA_DIAGNOSTICS="" \
    GC_CONTAINER_OPTIONS=""

RUN mkdir -p /deployments /home/s2i \
    && chmod -R g+rwX /deployments /home/s2i \
    && adduser -D -u 1001 -h /home/s2i -s /bin/bash s2i 2>/dev/null || true \
    && addgroup s2i root 2>/dev/null || true \
    && echo "s2i:x:1001:0:S2I User:/home/s2i:/bin/bash" >> /etc/passwd

COPY --from=builder /deployments/ /deployments/
COPY --from=builder /usr/libexec/s2i/run /usr/libexec/s2i/run
COPY --from=builder /usr/libexec/s2i/usage /usr/libexec/s2i/usage
COPY --from=builder /usr/libexec/s2i/usage.txt /usr/libexec/s2i/usage.txt

RUN chmod +x /usr/libexec/s2i/* \
    && chown -R 1001:0 /deployments /home/s2i \
    && chmod -R g+rwX /deployments /home/s2i

USER 1001
WORKDIR /deployments
CMD ["/usr/libexec/s2i/run"]
