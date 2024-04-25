ARG BUILD_FROM
FROM $BUILD_FROM as build
COPY run.sh run.sh
RUN chmod +x run.sh
ENTRYPOINT ["sh", "run.sh"]
