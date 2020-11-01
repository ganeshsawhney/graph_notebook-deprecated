#!/bin/bash
##### Ininition Enviroment #####
yum install -y wget curl tar gzip which
cd ~
wget https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh -O ~/Anaconda3-2019.07-Linux-x86_64.sh
mkdir ~/.conda/
echo "yes" | bash Anaconda3-2019.07-Linux-x86_64.sh -b -p ~/anaconda3

echo "export PATH=/root/anaconda3/bin:$PATH" >> ~/.bashrc

if [ `curl -s 169.254.169.254/latest/meta-data/services/partition/` == 'aws-cn' ];
    then
        pipargs=' -i https://pypi.tuna.tsinghua.edu.cn/simple '
elif [ `curl -s 169.254.169.254/latest/meta-data/services/partition/` == 'aws' ];
    then
        pipargs=''
else
    echo "Unable to determine region！";
    pipargs=''
fi
tar -zxvf ~/graph_notebook.tar.gz

##### Install NodeJs #####
curl --silent --location https://rpm.nodesource.com/setup_12.x | bash -
yum install -y nodejs
npm install -g opencollective

##### Copy To Home Directory #####
source ~/.bashrc
echo "y" | conda create -n JupyterSystemEnv python=3.7
source activate JupyterSystemEnv
cd ~/graph_notebook || exit
echo "copying to relevant directories from $(pwd)"

echo "copying jupyter custom css and js"
mkdir -p ~/.jupyter/custom/
cp -r ~/graph_notebook/src/graph_notebook/jupyter_profile/jupyter/custom/* ~/.jupyter/custom/
cat src/graph_notebook/jupyter_profile/jupyter_notebook_config.py >> ~/.jupyter/jupyter_notebook_config.py
##### Intalling Python & Js Dependencies #####
echo "intalling python dependencies..."
pip install $pipargs notebook==5.7.10
pip install $pipargs jupyterlab
cp -r src/graph_notebook/static_resources/* `python -c 'import site; print(site.getsitepackages()[0])'`/notebook/static

pip install -r ~/graph_notebook/requirements.txt
pip install $pipargs  ~/graph_notebook
pip install $pipargs --upgrade tornado==4.5.1
pip install $pipargs --upgrade jupyter_contrib_nbextensions

echo "install js dependencies"
PATH=/root/anaconda3/envs/JupyterSystemEnv/bin/:$PATH
pushd . || exit
cd `python -c 'import site; print(site.getsitepackages()[0])'`/graph_notebook/widgets || exit
npm ci
npm run build:all
popd || exit

pushd .

##### Initializing Notebook Extensions #####
echo "copying nbextensions..."
cd ~/graph_notebook/src/graph_notebook/nbextensions || exit
jupyter nbextension install neptune_menu --sys-prefix
jupyter nbextension enable neptune_menu/main

jupyter nbextension install sparql_syntax --sys-prefix
jupyter nbextension enable sparql_syntax/main

jupyter nbextension install gremlin_syntax --sys-prefix
jupyter nbextension enable gremlin_syntax/main
popd || exit

python -m ipykernel install --sys-prefix --name python3 --display-name "Python 3"

jupyter nbextension install --py --sys-prefix graph_notebook.widgets
jupyter nbextension enable  --py --sys-prefix graph_notebook.widgets

chmod u+rwx ~/graph_notebook

mkdir -p ~/SageMaker/Neptune
cp -r ~/graph_notebook/src/graph_notebook/notebook/* ~/SageMaker/Neptune
chmod -R a+rw ~/SageMaker/Neptune/*
source ~/anaconda3/bin/deactivate
