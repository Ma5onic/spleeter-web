FROM nvidia/cuda:11.2.0-cudnn8-devel-ubuntu18.04

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR $HOME
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
& curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
&& wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.11.0-Linux-x86_64.sh -O ~/miniconda.sh \
&& bash ~/miniconda.sh -b -p $HOME/miniconda \
&& git clone -b leaderboard_B https://github.com/kuielab/mdx-net-submission.git

SHELL ["/bin/bash", "-c"]
RUN source ~/miniconda/bin/activate && conda init \
&&  source ~/.bashrc \ && conda info \
&& conda env create -f environment.yml -n mdx-submit \
&& conda activate mdx-submit \
&& pip3 install -r requirements.txt \
&& python3 download_demucs.py

#############################
# Spleeter-Web  requirements#
#############################

RUN mkdir -p /webapp/media /webapp/staticfiles

WORKDIR /webapp
COPY requirements.txt /webapp/
RUN pip3 install torch==1.8.1+cu111 -f https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install --upgrade pip -r requirements.txt

COPY . .

# Copy over entrypoint script
COPY api-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/api-entrypoint.sh && ln -s /usr/local/bin/api-entrypoint.sh /

ENTRYPOINT ["api-entrypoint.sh"]
