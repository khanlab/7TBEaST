FROM khanlab/neuroglia-core-minc:latest
MAINTAINER <alik@robarts.ca>


RUN mkdir -p /src
COPY . /src

ENTRYPOINT ["/src/BEAST"]
