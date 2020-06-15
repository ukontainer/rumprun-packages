FROM alpine:3.9 as data-src

RUN apk update \
        && apk add bind \
        && apk add bind-tools \
        && apk add bind-dnssec-tools \
        && rm -rf /var/cache/apk/* \
        && chown -R named:named /var/bind \
        && chmod -R u+rwx /var/bind

FROM scratch
COPY lkl.json /
COPY lkl-offload.json /

COPY --from=data-src /var/bind/ /var/bind/
ADD https://www.internic.net/domain/named.cache /var/bind/named.ca
COPY ./bin /bin
ADD ./etc  /etc

ENV LKL_USE_9PFS=1
