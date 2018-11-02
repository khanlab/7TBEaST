FROM khanlab/neuroglia-core-minc:latest
MAINTAINER <alik@robarts.ca>


RUN mkdir -p /src
COPY . /src

RUN wget -qO- https://www.dropbox.com/s/lm0pcjmv54ajwcm/icbm152_model_09c.tar.gz | tar xvz -C /src
RUN wget -qO- https://www.dropbox.com/s/rdtbx2csg1ywo47/test_library.tar.gz | tar xvz -C /src

ENTRYPOINT ["/src/BEAST"]
