FROM nvidia/cuda:11.2.0-cudnn8-devel-ubuntu18.04

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up locales properly
RUN apt-get -qq update && \
    apt-get -qq install --yes --no-install-recommends locales > /dev/null && \
    apt-get -qq purge && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Use bash as default shell, rather than sh
ENV SHELL /bin/bash

# Set up user
ENV USER spleeter
ENV HOME /home/${USER}
ENV UID=$(id -u)
ENV GID=$(id -g)

RUN groupadd \
        --gid ${UID} \
        ${USER} && \
    useradd \
        --comment "Default user" \
        --create-home \
        --gid ${GID} \
        --no-log-init \
        --shell /bin/bash \
        --uid ${UID} \
        ${USER}

# Install all dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ffmpeg \
    git \
    libasound2-dev \
    libmagic-dev \
    libopenmpi-dev \
    libsndfile-dev \
    libsox-dev \
    libsox-fmt-all \
    openmpi-bin \
    rsync \
    software-properties-common \
    sox \
    ssh \
    wget \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get -y install python3.7 python3.7-gdbm python3-distutils \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3.7 get-pip.py \
    && ln -s /usr/local/cuda-11.2/targets/x86_64-linux/lib/libcudart.so.11.0 /usr/lib/x86_64-linux-gnu/libcudart.so.11.0 \
##################################
# mdx-net-submission requirements#
##################################
WORKDIR $HOME
    & curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.11.0-Linux-x86_64.sh -O ~/miniconda.sh \
    && bash ~/miniconda.sh -b -p $HOME/miniconda \
    && git clone -b leaderboard_B https://github.com/kuielab/mdx-net-submission.git \
    && cd mdx-net-submission

SHELL ["/bin/bash", "-c"]
WORKDIR $HOME/mdx-net-submission/
RUN source ~/miniconda/bin/activate && conda init \
&&  source ~/.bashrc \ && conda info \
&& conda env create -f environment.yml -n mdx-submit \
&& conda activate mdx-submit \
&& pip3 install -r requirements.txt \
&& python3 download_demucs.py
&& python3 ./utility/verify_or_download_data.py

#############################
# Spleeter-Web  requirements#
#############################
RUN mkdir -p /webapp/media /webapp/staticfiles

WORKDIR $HOME/webapp/
COPY requirements.txt $HOME/webapp/
RUN pip3 install torch==1.8.1+cu111 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install --upgrade pip -r requirements.txt

COPY . .

# Copy over entrypoint script
COPY api-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/api-entrypoint.sh && ln -s /usr/local/bin/api-entrypoint.sh /

ENTRYPOINT ["api-entrypoint.sh"]
