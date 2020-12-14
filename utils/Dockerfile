FROM scratch
ARG TARGETPLATFORM
ARG BUILDPLATFORM

COPY lkl.json /
COPY lkl-offload.json /
COPY ./imgs /imgs
COPY ./$TARGETPLATFORM/bin /bin
COPY ./$TARGETPLATFORM/sbin /sbin
