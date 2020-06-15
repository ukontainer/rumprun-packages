FROM scratch
COPY lkl.json /
COPY lkl-offload.json /
COPY ./imgs /imgs
COPY ./bin /bin
COPY ./sbin /sbin

# for python specific
COPY usr/ /usr/

ENV PYTHONHOME=/usr
ENV LKL_USE_9PFS=1
# 9pfs rootfs stucks when .pyc are written
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONHASHSEED=1
ENV HOME=/
# without tty, print() would be buffered
ENV PYTHONUNBUFFERED=0
