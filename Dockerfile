# Based on Frank Carey's pull request
# https://github.com/deepmind/lab/pull/24

FROM l.gcr.io/google/bazel:latest

# Temporarily shut up warnings.
ENV DISPLAY :0
ENV TERM xterm

# Basic Dependencies
RUN apt-get update && apt-get install -y \
    curl \
    zip \
    unzip \
    software-properties-common \
    python-software-properties && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Dependencies for vnc setup.
RUN apt-get update && apt-get install -y \
    xvfb \
    fluxbox \
    x11vnc && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install deepmind-lab dependencies
RUN apt-get update && apt-get install -y \
    lua5.1 \
    liblua5.1-0-dev \
    libffi-dev \
    gettext \
    freeglut3-dev \
    libsdl2-dev \
    libosmesa6-dev \
    python-dev \
    python-numpy \
    realpath \
    build-essential && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*


# Set the default X11 Display.
ENV DISPLAY :1
ENV VNC_PASSWORD=password
ENV XVFB_RESOLUTION=800x600x16

# Set up deepmind-lab folder and copy in the code.
ENV lab_dir /lab
RUN mkdir /$lab_dir
COPY . /$lab_dir
WORKDIR $lab_dir

# Run an actual (headless) build since this should make subsequent builds much faster.
RUN bazel build -c opt //:deepmind_lab.so --define headless=osmesa && \ 
    bazel test -c opt //python/tests:python_module_test

# This port is the default for connecting to VNC display :1
EXPOSE 5901

# Copy VNC script that handles restarts and make it executable.
COPY ./.docker/startup.sh /opt/
RUN chmod u+x /opt/startup.sh

# Finally, start VNC using our script.
ENTRYPOINT ["/opt/startup.sh"]
