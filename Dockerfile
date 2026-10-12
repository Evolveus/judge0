FROM judge0/compilers:1.4.0 AS production

ENV JUDGE0_HOMEPAGE="https://judge0.com"
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0"
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER

ENV PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH"
ENV GEM_HOME="/opt/.gem/"

# Debian Buster reached end-of-life, so its apt repositories were moved from
# deb.debian.org / security.debian.org to archive.debian.org. Point apt there
# (and skip Valid-Until checks on the archived, expired Release files).
RUN printf 'deb http://archive.debian.org/debian buster main\ndeb http://archive.debian.org/debian-security buster/updates main\n' > /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq-dev \
      sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

# Python packages exposed to Python (3.8.1) submissions (language id 71).
# Manage the list in requirements.txt; rebuild the image to apply changes.
ENV JUDGE0_PYTHON3="/usr/local/python-3.8.1/bin/python3"
COPY requirements.txt /tmp/requirements.txt
RUN $JUDGE0_PYTHON3 -m pip install --no-cache-dir --upgrade pip && \
    $JUDGE0_PYTHON3 -m pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt && \
    printf 'import os\nos.environ.setdefault("OPENBLAS_NUM_THREADS", "1")\nos.environ.setdefault("OMP_NUM_THREADS", "1")\nos.environ.setdefault("MPLBACKEND", "Agg")\n' \
      > "$($JUDGE0_PYTHON3 -c 'import site; print(site.getsitepackages()[0])')/sitecustomize.py"

EXPOSE 2358

WORKDIR /api

COPY Gemfile* ./
RUN RAILS_ENV=production bundle

COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

COPY . .

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

RUN useradd -u 1000 -m -r judge0 && \
    echo "judge0 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chown judge0: /api/tmp/

USER judge0

ENV JUDGE0_VERSION="1.13.1"
LABEL version=$JUDGE0_VERSION


FROM production AS development

CMD ["sleep", "infinity"]
